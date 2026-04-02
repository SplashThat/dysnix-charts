#!/usr/bin/env bash

# Pre-stop hook for ProxySQL: drains connections and waits for active queries
# to finish before allowing the pod to terminate.

set -u

ADMIN_PORT="${PROXYSQL_ADMIN_PORT:-6032}"
ADMIN_TIMEOUT="${PROXYSQL_ADMIN_TIMEOUT:-10}"

# Runs a SQL command against the ProxySQL admin interface.
# Output is raw (no headers/formatting) for easy parsing.
proxysql_admin() {
  local sql="$1"

  local creds
  creds=$(mktemp)
  chmod 600 "${creds}"
  printf '[client]\npassword=%s\n' "${PROXYSQL_ADMIN_PASSWORD}" > "${creds}"

  timeout "${ADMIN_TIMEOUT}" \
    mysql --defaults-extra-file="${creds}" -h127.0.0.1 -P"${ADMIN_PORT}" \
      -u"${PROXYSQL_ADMIN_USER}" -sN -e "${sql}"
  local rc=$?

  rm -f "${creds}"
  return "${rc}"
}

# Stops listeners and kills idle connections.
# PAUSE alone does NOT set wait_timeout=0 (removed in ProxySQL v1.4.1),
# so we set it explicitly to close idle connections immediately.
drain_proxysql() {
  echo "Executing PROXYSQL PAUSE..."
  if proxysql_admin "PROXYSQL PAUSE"; then
    echo "PROXYSQL PAUSE complete. No new connections accepted."
  else
    echo "WARNING: PROXYSQL PAUSE failed or timed out."
  fi

  echo "Setting mysql-wait_timeout=0 to close idle connections..."
  if proxysql_admin "SET mysql-wait_timeout=0; LOAD MYSQL VARIABLES TO RUNTIME;"; then
    echo "mysql-wait_timeout=0 applied. Idle connections will be closed immediately."
  else
    echo "WARNING: Setting wait_timeout failed. Idle connections may persist until SIGKILL."
  fi
}

if [ -n "${PROXYSQL_ADMIN_USER:-}" ] && [ -n "${PROXYSQL_ADMIN_PASSWORD:-}" ]; then
  drain_proxysql
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
