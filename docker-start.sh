if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    chia start harvester
  fi
else
  chia start farmer
fi

tail -f ~/.chia/mainnet/log/debug.log
