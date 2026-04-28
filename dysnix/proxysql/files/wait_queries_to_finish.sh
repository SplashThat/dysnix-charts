#!/usr/bin/env bash

# Pre-stop hook for ProxySQL: drains connections and waits for active queries
# to finish before allowing the pod to terminate.

set -u

ADMIN_PORT="${PROXYSQL_ADMIN_PORT:-6032}"
ADMIN_TIMEOUT="${PROXYSQL_ADMIN_TIMEOUT:-10}"
ADMIN_CREDS=""

# Creates the MySQL credentials file once for the lifetime of the script.
init_admin_creds() {
  ADMIN_CREDS=$(mktemp) || {
    echo "ERROR: mktemp failed."
    return 1
  }
  chmod 600 "${ADMIN_CREDS}"
  printf '[client]\npassword=%s\n' "${PROXYSQL_ADMIN_PASSWORD}" >"${ADMIN_CREDS}"
  trap 'rm -f "${ADMIN_CREDS}"' EXIT
}

# Runs a SQL command against the ProxySQL admin interface.
# Output is raw (no headers/formatting) for easy parsing.
proxysql_admin() {
  local sql="$1"

  timeout "${ADMIN_TIMEOUT}" \
    mysql --defaults-extra-file="${ADMIN_CREDS}" -h127.0.0.1 -P"${ADMIN_PORT}" \
    -u"${PROXYSQL_ADMIN_USER}" -sN -e "${sql}"
}

# Stops listeners and kills idle frontend sessions on THIS pod only.
# PAUSE alone does NOT close idle connections (wait_timeout=0 behavior was removed in ProxySQL v1.4.1
# https://github.com/sysown/proxysql/issues/2484#issuecomment-574092954).
# We use KILL CONNECTION per session instead of SET mysql-wait_timeout=0; LOAD MYSQL VARIABLES TO RUNTIME
# because LOAD TO RUNTIME triggers cluster sync and propagates wait_timeout=0 to all peers,
# killing idle connections cluster-wide and causing "MySQL server has gone away" storms.
# KILL CONNECTION is admin-scoped: it does not modify mysql_variables, so no checksum change
# and no cluster replication occurs.
drain_proxysql() {
  echo "Executing PROXYSQL PAUSE..."
  proxysql_admin "PROXYSQL PAUSE"
  local rc=$?

  if [ "${rc}" -eq 0 ]; then
    echo "PROXYSQL PAUSE complete. No new connections accepted."
  elif [ "${rc}" -eq 124 ]; then
    echo "WARNING: PROXYSQL PAUSE timed out after ${ADMIN_TIMEOUT}s (exit code ${rc}). New connections may still be accepted."
    return 1
  else
    echo "WARNING: PROXYSQL PAUSE failed (exit code ${rc}). New connections may still be accepted."
    return 1
  fi

  echo "Killing idle frontend sessions on this pod..."
  local idle_ids
  local kill_sql=""
  local killed=0
  local rc
  # 'Sleep' — session is connected and waiting for the next client command.
  #           https://github.com/sysown/proxysql/blob/v2.4.4/lib/MySQL_Thread.cpp#L4786
  #           ProxySQL processlist docs:
  #           https://proxysql.com/documentation/the-admin-schemas/stats/stats-mysql#stats_mysql_processlist
  idle_ids=$(proxysql_admin "SELECT SessionID FROM stats_mysql_processlist WHERE command = 'Sleep'")
  rc=$?
  if [ "${rc}" -eq 124 ]; then
    echo "WARNING: Query for idle sessions timed out after ${ADMIN_TIMEOUT}s. Idle connections may persist."
    return 1
  elif [ "${rc}" -ne 0 ]; then
    echo "WARNING: Query for idle sessions failed (exit code ${rc}). Idle connections may persist."
    return 1
  fi
  for sid in ${idle_ids}; do
    kill_sql="${kill_sql}KILL CONNECTION ${sid}; "
    killed=$((killed + 1))
  done

  if [ "${killed}" -eq 0 ]; then
    echo "Killed 0 idle session(s)."
    return 0
  fi

  proxysql_admin "${kill_sql}"
  rc=$?
  if [ "${rc}" -eq 124 ]; then
    echo "WARNING: Killing ${killed} idle session(s) timed out after ${ADMIN_TIMEOUT}s. Some may persist."
    return 1
  elif [ "${rc}" -ne 0 ]; then
    echo "WARNING: Killing ${killed} idle session(s) failed (exit code ${rc}). Some may persist."
    return 1
  fi
  echo "Killed ${killed} idle session(s)."
}

if [ -n "${PROXYSQL_ADMIN_USER:-}" ] && [ -n "${PROXYSQL_ADMIN_PASSWORD:-}" ]; then
  init_admin_creds && drain_proxysql
else
  echo "WARNING: PROXYSQL_ADMIN_USER or PROXYSQL_ADMIN_PASSWORD not set. Idle connections may persist until SIGKILL."
fi

echo "Waiting for active queries to finish..."

while true; do
  CONNECTED_IPS=$(for pid in $(pidof proxysql); do \
    cat /proc/${pid}/net/tcp \
    | grep -E "[[:digit:]]+: [[:xdigit:]]+$(printf ':%x' ${PROXYSQL_SERVICE_PORT_PROXY:-6033}) [[:xdigit:]]+:[[:xdigit:]]+ 01" \
    | sort -u \
    | cut -f1 -d':' \
    | awk '{gsub(/../,"0x& ")} OFS="." {for(i=NF;i>0;i--) printf "%d%s", $i, (i == 1 ? ORS : OFS)}'; \
    done )

  echo "Connected IPs: $(echo ${CONNECTED_IPS} | wc -l)"
  if [[ -z ${CONNECTED_IPS} ]]; then
    echo "Done. Exiting...";
    exit 0
  else
    echo "Sleeping...";
    sleep $[ ( $RANDOM % 3 )  + 1 ]s
  fi;
done
