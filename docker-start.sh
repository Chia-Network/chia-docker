#!/usr/bin/env bash

# Count the sockets holding a TCP port, and how many of those are listening.
# There is no ss/netstat/lsof in the image, so read /proc directly. Ports there
# are big-endian hex and state 0A is LISTEN.
port_holders() {
  awk -v want="$(printf '%04X' "$1")" '
    FNR == 1 { next }
    {
      split($2, local, ":")
      if (local[2] == want) {
        held++
        if ($4 == "0A") listening++
      }
    }
    END { print held + 0, listening + 0 }
  ' /proc/net/tcp /proc/net/tcp6 2>/dev/null
}

# The daemon port, 55400 by default, is inside the usual Linux ephemeral port
# range, so an outbound connection can be assigned it as a source port and hold
# it. The daemon does not survive that: it exits, and because `chia start` runs
# it with stderr redirected to /dev/null the bind error is never reported, so the
# container stays up with nothing serving. A closed connection keeps the port for
# the ~60s it spends in TIME_WAIT, since TIME_WAIT only yields to a bind whose
# predecessor set SO_REUSEADDR and clients like apt, git and pip do not set it.
#
# So wait for the port to clear before starting. This is deliberately
# conservative: it waits for any socket on the port, even one bound to an address
# the daemon would not bind, which can only cost startup time. Waiting cannot
# help against a listener, so that case carries on immediately, and the wait is
# bounded and always followed by starting chia regardless.
wait_for_daemon_port() {
  local port="$1" budget="$2" waited=0 counts held listening

  counts="$(port_holders "${port}")"
  held="${counts% *}"
  listening="${counts#* }"

  if [[ ${held} -eq 0 ]]; then
    return 0
  fi

  if [[ ${listening} -gt 0 ]]; then
    echo "daemon-port: port ${port} already has a listener, so waiting cannot help; starting anyway"
    return 0
  fi

  echo "daemon-port: ${held} socket(s) hold port ${port} and would block the daemon's bind, waiting up to ${budget}s"

  while [[ ${waited} -lt ${budget} ]]; do
    sleep 5
    waited=$((waited + 5))

    counts="$(port_holders "${port}")"
    held="${counts% *}"
    listening="${counts#* }"

    if [[ ${held} -eq 0 ]]; then
      echo "daemon-port: port ${port} cleared after ${waited}s"
      return 0
    fi

    if [[ ${listening} -gt 0 ]]; then
      echo "daemon-port: something started listening on port ${port} after ${waited}s; starting anyway"
      return 0
    fi
  done

  echo "daemon-port: port ${port} is still held after ${budget}s, starting anyway"
  return 1
}

# shellcheck disable=SC2154
if [[ ${daemon_port_wait:-120} != "0" ]]; then
  daemon_port="$(yq '.daemon_port // 55400' "$CHIA_ROOT/config/config.yaml" 2>/dev/null || echo 55400)"
  wait_for_daemon_port "${daemon_port}" "${daemon_port_wait:-120}" || true
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
