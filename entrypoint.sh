cd /chia-blockchain

. ./activate

chia init

chia configure --docker

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a variable -e keys=\"24words\""
  chia keys generate
else
  echo "${keys}" | chia keys add -
fi

if [[ ! "$(ls -A /plots)" ]]; then
  echo "Plots directory appears to be empty and you have not specified another, try mounting a plot directory with the docker -v command "
fi

chia plots add -d ${plots_dir}

if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} ]]; then
    echo "A farmer peer address and port are required."
    exit
  else
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    chia start harvester
  fi
else
  chia start farmer
fi
  #statements
while true; do sleep 30; done;
