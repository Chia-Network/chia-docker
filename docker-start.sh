#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ ${farmer} == 'true' ]]; then
  chives start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chives configure --set-farmer-peer "${farmer_address}:${farmer_port}"
    chives start harvester
  fi
else
  chives start farmer
fi

trap "chives stop all -d; exit 0" SIGINT SIGTERM
if [[ ${log_to_file} == 'true' ]]; then
  # Ensures the log file actually exists, so we can tail successfully
  touch "$CHIVES_ROOT/log/debug.log"
  tail -F "$CHIVES_ROOT/log/debug.log" &
fi

while true; do sleep 1; done
