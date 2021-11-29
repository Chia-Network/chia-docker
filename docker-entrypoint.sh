#!/usr/bin/env bash

# shellcheck disable=SC2154
if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
fi

cd /chives-blockchain || exit 1

# shellcheck disable=SC1091
. ./activate

chives init #--fix-ssl-permissions

if [[ ${testnet} == 'true' ]]; then
   echo "configure testnet"
   chives configure --testnet true
fi

if [[ ${keys} == "persistent" ]]; then
  echo "Not touching key directories"
elif [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chives keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  chives init -c "${ca}"
  fi
else
  chives keys add -f "${keys}"
fi

for p in ${plots_dir//:/ }; do
    mkdir -p "${p}"
    if [[ ! $(ls -A "$p") ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    chives plots add -d "${p}"
done

chives configure --upnp "${upnp}"

if [[ -n "${log_level}" ]]; then
  chives configure --log-level "${log_level}"
fi

sed -i 's/localhost/127.0.0.1/g' "$CHIVES_ROOT/config/config.yaml"

if [[ ${log_to_file} != 'true' ]]; then
  sed -i 's/log_stdout: false/log_stdout: true/g' "$CHIVES_ROOT/config/config.yaml"
else
  sed -i 's/log_stdout: true/log_stdout: false/g' "$CHIVES_ROOT/config/config.yaml"
fi

exec "$@"
