cd /chia-blockchain

. ./activate

chia init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chia keys generate
else
  chia keys add -f ${keys}
fi

if [[ ! "$(ls -A /plots)" ]]; then
  echo "Plots directory appears to be empty and you have not specified another, try mounting a plot directory with the docker -v command "
fi

if [[ ${harvester_remote} == 'true' ]]; then
  if [[ ! "$(ls -A /ca)" ]]; then
    echo "CA directory appears to be empty and you have not specified another, try mounting a ca directory with the docker -v command"
    exit
  else
    echo "Init remote harvester"
    chia init -c ${harvester_remote_ca_dir}
  fi
fi

# original cmd, without recursive search for plots. chia plots add -d ${plots_dir}
find ${plots_dir} -iname "*.plot" -type f | xargs -n 1 -I[] dirname [] | grep -v "Trash" | sort --unique | xargs -n 1 -I[] chia plots add -d []

sed -i 's/localhost/127.0.0.1/g' ~/.chia/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} ]]; then
    echo "A farmer peer address and port are required."
    exit
  else
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    if [[ ${harvester_remote} == 'true' ]]; then
      chia start harvester -r
    else
      chia start harvester
    fi
  fi
else
  chia start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    chia configure --set-fullnode-port 58444
  else
    chia configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
