#!/usr/bin/env bash

# Optional diagnostics for "Failed to create the chia daemon", which can mean the
# daemon failed to bind its port rather than that it was slow to start. Both are
# off by default and neither changes whether chia is started.
# shellcheck disable=SC2154
if [[ ${daemon_port_probe} == 'true' || ${daemon_stderr_capture} == 'true' ]]; then
  daemon_diag_port="${daemon_diagnostics_port:-$(yq '.daemon_port // 55400' "$CHIA_ROOT/config/config.yaml" 2>/dev/null || echo 55400)}"
fi

# Report anything already holding the port, then keep watching across the window
# in which the daemon binds, since it binds a second or two after `chia start`.
# shellcheck disable=SC2154
if [[ ${daemon_port_probe} == 'true' ]]; then
  /usr/local/bin/docker-port-probe.sh "${daemon_diag_port}"
  /usr/local/bin/docker-port-probe.sh "${daemon_diag_port}" "${daemon_port_probe_seconds:-30}" &
fi

daemon_capture_log="$CHIA_ROOT/log/daemon-capture.log"
daemon_capture_dumped="false"

# Copy whatever run_daemon wrote into the container log, where a bind traceback
# is actually visible.
dump_daemon_capture() {
  # shellcheck disable=SC2154
  if [[ ${daemon_stderr_capture} != 'true' ]] ||
    [[ ${daemon_capture_dumped} == 'true' ]] ||
    [[ ! -s ${daemon_capture_log} ]]; then
    return 0
  fi

  daemon_capture_dumped="true"
  echo "daemon-capture: run_daemon wrote the following to stdout/stderr"
  sed 's/^/daemon-capture: /' "${daemon_capture_log}"
}

# shellcheck disable=SC2154
if [[ ${daemon_stderr_capture} == 'true' ]]; then
  mkdir -p "$(dirname "${daemon_capture_log}")"

  # `chia start` starts this itself with stdout and stderr pointed at /dev/null,
  # which is why a failure to bind the daemon port leaves no error anywhere at
  # all. Start it here with both streams kept instead. `chia start` below then
  # finds a daemon already running and carries on as usual.
  # shellcheck disable=SC2086
  chia ${chia_args} run_daemon --wait-for-unlock > "${daemon_capture_log}" 2>&1 &
  daemon_capture_pid=$!
  echo "daemon-capture: started run_daemon as pid ${daemon_capture_pid}"

  # Wait for it to listen, or to die trying. A listening socket in /proc is
  # state 0A with a zeroed peer; checking there avoids opening a TCP connection
  # to a TLS port just to see if it answers.
  daemon_port_hex="$(printf '%04X' "${daemon_diag_port}")"
  for _ in $(seq 1 150); do
    if grep -qE ":${daemon_port_hex} [0-9A-F]+:0000 0A " /proc/net/tcp /proc/net/tcp6 2>/dev/null; then
      echo "daemon-capture: daemon is listening on port ${daemon_diag_port}"
      break
    fi

    if ! kill -0 "${daemon_capture_pid}" 2>/dev/null; then
      wait "${daemon_capture_pid}"
      echo "daemon-capture: run_daemon exited with status $? without listening on port ${daemon_diag_port}"
      dump_daemon_capture
      break
    fi

    sleep 0.2
  done
fi

# shellcheck disable=SC2154,SC2086
chia ${chia_args} start ${service}

dump_daemon_capture

trap "echo Shutting down ...; chia stop all -d; exit 0" SIGINT SIGTERM

# shellcheck disable=SC2154
if [[ ${log_to_file} == 'true' ]]; then
  # Ensures the log file actually exists, so we can tail successfully
  touch "$CHIA_ROOT/log/debug.log"
  tail -F "$CHIA_ROOT/log/debug.log" &
fi

tail -F /dev/null
