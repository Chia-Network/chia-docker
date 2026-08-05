#!/usr/bin/env bash

# Report any socket occupying a TCP port.
#
# The chia daemon logs "Starting Daemon Server (host:port)" *before* it binds,
# and `chia start` launches it with stderr redirected to /dev/null, so a bind
# failure leaves no trace at all: the daemon exits, the port stays closed, and
# `chia start` only says "Failed to create the chia daemon" 62 seconds later.
#
# The default daemon port, 55400, sits inside the usual Linux ephemeral range
# (net.ipv4.ip_local_port_range, typically 32768-60999), so an outbound
# connection can be assigned it as a source port and block the daemon's bind.
# The window is not just the life of that connection: a closed one lingers in
# TIME_WAIT for around a minute and still blocks the bind, because TIME_WAIT
# yields only to a bind whose predecessor set SO_REUSEADDR and ordinary clients
# do not. This is easy to hit in images that install packages or clone repos at
# startup, and every container in a Kubernetes pod shares the network namespace,
# so a sidecar's connections count too.
#
# Usage: docker-port-probe.sh PORT [WATCH_SECONDS] [INTERVAL_SECONDS]
#
# With no WATCH_SECONDS the port is sampled once and every socket using it is
# reported. Otherwise it is sampled every INTERVAL_SECONDS (default 0.2) for
# WATCH_SECONDS and only blocking sockets are reported. Watching matters because
# the daemon binds a second or two after `chia start` is invoked, so a single
# check beforehand usually misses the race.
#
# There is no ss/netstat/lsof in the image, so this reads /proc directly.

port="${1}"
watch_seconds="${2:-0}"
interval="${3:-0.2}"

if [[ -z ${port} ]]; then
  echo "port-probe: usage: docker-port-probe.sh PORT [WATCH_SECONDS] [INTERVAL_SECONDS]" >&2
  exit 2
fi

log() {
  echo "$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ') port-probe: $*"
}

tcp_state() {
  case "${1^^}" in
    01) echo "ESTABLISHED" ;;
    02) echo "SYN_SENT" ;;
    03) echo "SYN_RECV" ;;
    04) echo "FIN_WAIT1" ;;
    05) echo "FIN_WAIT2" ;;
    06) echo "TIME_WAIT" ;;
    07) echo "CLOSE" ;;
    08) echo "CLOSE_WAIT" ;;
    09) echo "LAST_ACK" ;;
    0A) echo "LISTEN" ;;
    0B) echo "CLOSING" ;;
    *) echo "UNKNOWN(${1})" ;;
  esac
}

# /proc/net/tcp writes IPv4 addresses as one little-endian 32-bit word and IPv6
# as four of them, while ports are plain big-endian hex.
decode_address() {
  local hex="$1"

  if [[ ${#hex} -eq 8 ]]; then
    printf '%d.%d.%d.%d' \
      "$((16#${hex:6:2}))" "$((16#${hex:4:2}))" "$((16#${hex:2:2}))" "$((16#${hex:0:2}))"
    return
  fi

  local groups=() word pair index bytes joined
  for ((word = 0; word < 4; word++)); do
    bytes=""
    for ((pair = 3; pair >= 0; pair--)); do
      bytes+="${hex:$((word * 8 + pair * 2)):2}"
    done
    for ((index = 0; index < 8; index += 4)); do
      groups+=("$(printf '%x' "$((16#${bytes:index:4}))")")
    done
  done

  printf -v joined '%s:' "${groups[@]}"
  printf '[%s]' "${joined%:}"
}

# Map a socket inode to the process holding it. Only sees processes in this
# container's PID namespace, so a socket owned by a sidecar reports no owner.
owner_of_inode() {
  local inode="$1" fd_path pid cmdline

  # Sockets with no file descriptor are owned by the kernel rather than a
  # process, so there is nothing to look up.
  if [[ ${inode} == "0" ]]; then
    printf 'kernel-owned socket, no file descriptor (accept queue or TIME_WAIT)'
    return 0
  fi

  for fd_path in /proc/[0-9]*/fd/*; do
    if [[ "$(readlink "${fd_path}" 2>/dev/null)" == "socket:[${inode}]" ]]; then
      pid="${fd_path#/proc/}"
      pid="${pid%%/fd/*}"
      # Keep the whole finding on one line: argv is NUL-separated and may itself
      # contain newlines and tabs.
      cmdline="$(tr '\0\n\t' '   ' < "/proc/${pid}/cmdline" 2>/dev/null | cut -c 1-120)"
      printf 'pid %s (%s)' "${pid}" "${cmdline:-unknown}"
      return 0
    fi
  done

  printf 'no owner in this PID namespace (another container in the pod, or already closed)'
}

# Describe every socket using the port. Sets `findings` to one line per socket
# and returns 0 if any of them would block a bind. Any socket on the port blocks
# it, including TIME_WAIT ones left behind by connections that closed up to a
# minute ago.
#
# $1 selects which sockets to describe: "all", or "blocking" for just the ones
# that would prevent a bind.
findings=""
inspect_port() {
  local want="$1" blocking=1 table
  local sl local_hex remote_hex state_hex uid inode
  local local_port remote_port state role note is_blocking

  findings=""

  for table in /proc/net/tcp /proc/net/tcp6; do
    [[ -r ${table} ]] || continue

    # Columns: sl local rem st tx:rx tr:when retrnsmt uid timeout inode ...
    while read -r sl local_hex remote_hex state_hex _ _ _ uid _ inode _; do
      [[ ${sl} == "sl" ]] && continue

      local_port="$((16#${local_hex##*:}))"
      remote_port="$((16#${remote_hex##*:}))"

      if [[ ${local_port} -eq ${port} ]]; then
        role="holds"
      elif [[ ${remote_port} -eq ${port} ]]; then
        role="dialing"
      else
        continue
      fi

      state="$(tcp_state "${state_hex}")"
      is_blocking=1
      note=""

      if [[ ${role} == "holds" ]]; then
        case "${state}" in
          # A TIME_WAIT socket only yields to a new bind if that socket itself
          # set SO_REUSEADDR, which ordinary outbound clients (apt, git, curl,
          # Go's dialer) do not. Treat it as blocking; /proc does not expose the
          # flag, so this cannot be settled from here.
          TIME_WAIT) note=" [LIKELY BLOCKS a bind: TIME_WAIT yields only if this socket set SO_REUSEADDR]" ;;
          LISTEN) note=" [already listening: something else owns this port]" ;;
          *) note=" [WOULD BLOCK a bind on this port]" ;;
        esac
        is_blocking=0
      fi

      [[ ${is_blocking} -eq 0 ]] && blocking=0
      [[ ${want} == "blocking" && ${is_blocking} -ne 0 ]] && continue

      # Only worth walking every /proc/*/fd for a socket we are reporting.
      findings+="${role} ${port}: ${state} $(decode_address "${local_hex%%:*}"):${local_port}"
      findings+=" -> $(decode_address "${remote_hex%%:*}"):${remote_port}"
      findings+=" uid=${uid} inode=${inode} owner=$(owner_of_inode "${inode}")${note}"$'\n'
    done < "${table}"
  done

  return ${blocking}
}

log_findings() {
  local line
  while IFS= read -r line; do
    [[ -n ${line} ]] && log "${line}"
  done <<< "${findings}"
}

if [[ ${watch_seconds} == "0" ]]; then
  if inspect_port all; then
    log_findings
    log "port ${port} is occupied by a socket that will block a bind (see above)"
  else
    log_findings
    log "port ${port} is free (nothing that would block a bind)"
  fi
  exit 0
fi

log "watching port ${port} for ${watch_seconds}s at ${interval}s intervals"
deadline=$((SECONDS + watch_seconds))
hits=0
previous=""
while ((SECONDS < deadline)); do
  if inspect_port blocking; then
    hits=$((hits + 1))
    # The same socket can persist across many samples; only report changes.
    if [[ ${findings} != "${previous}" ]]; then
      log_findings
      previous="${findings}"
    fi
  else
    previous=""
  fi
  sleep "${interval}"
done
log "finished watching port ${port}: ${hits} sample(s) saw a socket that would block a bind"
