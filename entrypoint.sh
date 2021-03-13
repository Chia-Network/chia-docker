cd /chia-blockchain

. ./activate

chia init

if [[ -z ${keys} ]]; then
  echo "please set your keys or set the keys variable equal to generate"
  exit
elif [[ ${keys} == "generate" ]]; then
  chia keys generate
else
  chia keys add -m "${keys}"
fi

if [[ ! "$(ls -A /plots)" && -z ${plots_dir} ]]; then
  echo "Plots directory appears to be empty and you have not specified another, try mounting a plot directory with the docker -v command "
elif [[ ! -z ${plots_dir} ]]; then
  chia plots add -d ${plots_dir}
else
  chia plots add -d /plots
fi

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
