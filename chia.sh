#!/bin/bash

while getopts p:k:h:f flag
do
    case "${flag}" in
        p) plots=${OPTARG};;
        k) keys=${OPTARG};;
        h) harvester="true";;
        f) farmeraddress=${OPTARG};;
    esac
done
echo "Plots Dir: $plots";
echo "Keys: $keys";
echo "harvester only: $harvester";
echo "farmer address: $farmeraddress";

cd /chia-blockchain && . ./activate && chia init

if [[ "$harvester" == "true" ]] then;
  if [[ ! -z "$farmeraddress" ]] then;
    cd /chia-blockchain && . ./activate && chia start harvester
  else

  fi
elif [[ ! -z "$var" ]] then;

else

fi
