#!/usr/bin/env bash

# For all proxysql processes iterate over all tcp connections
# and search for any established connection to port ${PROXYSQL_SERVICE_PORT_PROXY:-6033}.
# If more than one connection is found, randomly sleep up to 3 seconds,
# otherwise exit 0.

set -u

# Runs a SQL command against the ProxySQL admin interface.
# Handles credential file creation/cleanup and timeout.
proxysql_admin() {
  local sql="$1"
  local admin_port="${PROXYSQL_ADMIN_PORT:-6032}"
  local pause_timeout="${PROXYSQL_PAUSE_TIMEOUT:-10}"

  local creds
  creds=$(mktemp)
  chmod 600 "${creds}"
  printf '[client]\npassword=%s\n' "${PROXYSQL_ADMIN_PASSWORD}" > "${creds}"

  timeout "${pause_timeout}" \
    mysql --defaults-extra-file="${creds}" -h127.0.0.1 -P"${admin_port}" -u"${PROXYSQL_ADMIN_USER}" -e "${sql}"
  local rc=$?

  rm -f "${creds}"
  return "${rc}"
}

# Executes PROXYSQL PAUSE to kill idle connections and close listeners.
# Requires PROXYSQL_ADMIN_USER and PROXYSQL_ADMIN_PASSWORD env vars.
pause_proxysql() {
  local pause_timeout="${PROXYSQL_PAUSE_TIMEOUT:-10}"

  echo "Executing PROXYSQL PAUSE..."
  proxysql_admin "PROXYSQL PAUSE"
  local rc=$?

  if [ "${rc}" -eq 0 ]; then
    echo "PROXYSQL PAUSE complete. Idle connections terminated, listeners closed."
  elif [ "${rc}" -eq 124 ]; then
    echo "WARNING: PROXYSQL PAUSE timed out after ${pause_timeout}s. Continuing shutdown without pause."
  else
    echo "WARNING: PROXYSQL PAUSE failed (exit code ${rc}). Continuing shutdown without pause."
  fi
}

if [ -n "${PROXYSQL_ADMIN_USER:-}" ] && [ -n "${PROXYSQL_ADMIN_PASSWORD:-}" ]; then
  pause_proxysql
else
  echo "WARNING: PROXYSQL_ADMIN_USER or PROXYSQL_ADMIN_PASSWORD not set, skipping PROXYSQL PAUSE"
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
