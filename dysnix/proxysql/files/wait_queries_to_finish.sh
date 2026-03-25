#!/usr/bin/env bash

# For all proxysql processes iterate over all tcp connections
# and search for any established connection to port ${PROXYSQL_SERVICE_PORT_PROXY:-6033}.
# If more than one connection is found, randomly sleep up to 3 seconds,
# otherwise exit 0.

set -u

# Pause ProxySQL to kill idle connections and close listeners before draining.
# Requires PROXYSQL_ADMIN_USER and PROXYSQL_ADMIN_PASSWORD env vars.
if [ -n "${PROXYSQL_ADMIN_USER:-}" ] && [ -n "${PROXYSQL_ADMIN_PASSWORD:-}" ]; then
  echo "Executing PROXYSQL PAUSE..."
  mysql -h127.0.0.1 -P"${PROXYSQL_ADMIN_PORT:-6032}" -u"${PROXYSQL_ADMIN_USER}" -p"${PROXYSQL_ADMIN_PASSWORD}" -e "PROXYSQL PAUSE"
  echo "PROXYSQL PAUSE complete. Idle connections terminated, listeners closed."
else
  echo "WARNING: PROXYSQL_ADMIN_USER or PROXYSQL_ADMIN_PASSWORD not set, skipping PROXYSQL PAUSE"
fi

echo "Waiting for proxy queries to finish..."

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
