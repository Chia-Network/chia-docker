#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
fi

cd /chia-blockchain || exit 1

# shellcheck disable=SC1091
. ./activate

# shellcheck disable=SC2086
chia ${chia_args} init --fix-ssl-permissions

if [[ -n ${ca} ]]; then
  # shellcheck disable=SC2086
  chia ${chia_args} init -c "${ca}"
fi

if [[ ${testnet} == 'true' ]]; then
  echo "configure testnet"
  chia configure --testnet true
fi

if [[ ${keys} == "persistent" ]]; then
  echo "Not touching key directories, key directory likely mounted by volume"
elif [[ ${keys} == "none" ]]; then
  # This is technically redundant to 'keys=persistent', but from a user's readability perspective, it means two different things
  echo "Not touching key directories, no keys needed"
elif [[ ${keys} == "copy" ]]; then
  echo "Setting the keys=copy environment variable has been deprecated. If you're seeing this message, you can simply change the value of the variable keys=none"
elif [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass the mnemonic as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chia keys generate -l ""
else
  chia keys add -f "${keys}" -l ""
fi

for p in ${plots_dir//:/ }; do
  mkdir -p "${p}"
  if [[ ! $(ls -A "$p") ]]; then
    echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
  fi
  chia plots add -d "${p}"
done

if [[ ${recursive_plot_scan} == 'true' ]]; then
  sed -i 's/recursive_plot_scan: false/recursive_plot_scan: true/g' "$CHIA_ROOT/config/config.yaml"
else
  sed -i 's/recursive_plot_scan: true/recursive_plot_scan: false/g' "$CHIA_ROOT/config/config.yaml"
fi

chia configure --upnp "${upnp}"

if [[ -n "${log_level}" ]]; then
  chia configure --log-level "${log_level}"
fi

if [[ -n "${peer_count}" ]]; then
  chia configure --set-peer-count "${peer_count}"
fi

if [[ -n "${outbound_peer_count}" ]]; then
  chia configure --set_outbound-peer-count "${outbound_peer_count}"
fi

if [[ -n ${farmer_address} && -n ${farmer_port} ]]; then
  chia configure --set-farmer-peer "${farmer_address}:${farmer_port}"
fi

if [[ -n ${crawler_db_path} ]]; then
  chia configure --crawler-db-path "${crawler_db_path}"
fi

if [[ -n ${crawler_minimum_version_count} ]]; then
  chia configure --crawler-minimum-version-count "${crawler_minimum_version_count}"
fi

if [[ -n ${self_hostname} ]]; then
  yq -i '.self_hostname = env(self_hostname)' "$CHIA_ROOT/config/config.yaml"
else
  yq -i '.self_hostname = "127.0.0.1"' "$CHIA_ROOT/config/config.yaml"
fi

if [[ -n ${full_node_peer} ]]; then
  echo "Changing full_node_peer settings in config.yaml with value: $full_node_peer"
  full_node_peer_host=$(echo "$full_node_peer" | rev | cut -d ':' -f 2- | rev) \
  full_node_peer_port=$(echo "$full_node_peer" | awk -F: '{print $NF}') \
  yq -i '
  .wallet.full_node_peer.host = env(full_node_peer_host) |
  .wallet.full_node_peer.port = env(full_node_peer_port) |
  .timelord.full_node_peer.host = env(full_node_peer_host) |
  .timelord.full_node_peer.port = env(full_node_peer_port) |
  .farmer.full_node_peer.host = env(full_node_peer_host) |
  .farmer.full_node_peer.port = env(full_node_peer_port)
  ' "$CHIA_ROOT/config/config.yaml"
fi

if [[ ${log_to_file} != 'true' ]]; then
  sed -i 's/log_stdout: false/log_stdout: true/g' "$CHIA_ROOT/config/config.yaml"
else
  sed -i 's/log_stdout: true/log_stdout: false/g' "$CHIA_ROOT/config/config.yaml"
fi

# Map deprecated legacy startup options.
if [[ ${farmer} == "true" ]]; then
  service="farmer-only"
elif [[ ${harvester} == "true" ]]; then
  service="harvester"
fi

if [[ ${service} == "harvester" ]]; then
  if [[ ${keys} == "persistent" || ${keys} == "none" ]]; then
    if [[ -z ${farmer_address} || -z ${farmer_port} ]]; then
      echo "A farmer peer address and port are required."
      exit
    fi
  else
    if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
      echo "A farmer peer address, port, and ca path are required."
      exit
    fi
  fi
fi

exec "$@"
