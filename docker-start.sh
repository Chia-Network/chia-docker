#!/usr/bin/env bash

# Optional diagnostic for "Failed to create the chia daemon". The daemon binds
# its port a moment after `chia start` is invoked, and its stderr is discarded,
# so a bind failure is otherwise completely silent. Report anything already
# holding the port, keep watching across the window in which the daemon binds,
# and then start as normal either way.
# shellcheck disable=SC2154
if [[ ${daemon_port_probe} == 'true' ]]; then
  probe_port="${daemon_port_probe_port:-$(yq '.daemon_port // 55400' "$CHIA_ROOT/config/config.yaml" 2>/dev/null || echo 55400)}"
  /usr/local/bin/docker-port-probe.sh "${probe_port}"
  /usr/local/bin/docker-port-probe.sh "${probe_port}" "${daemon_port_probe_seconds:-30}" &
fi

# shellcheck disable=SC2154,SC2086
chia ${chia_args} start ${service}

trap "echo Shutting down ...; chia stop all -d; exit 0" SIGINT SIGTERM

# shellcheck disable=SC2154
if [[ ${log_to_file} == 'true' ]]; then
  # Ensures the log file actually exists, so we can tail successfully
  touch "$CHIA_ROOT/log/debug.log"
  tail -F "$CHIA_ROOT/log/debug.log" &
fi

tail -F /dev/null
