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

if [[ "$harvester" == true ]] then;

elif [[ ! -z "$var" ]] then;

else

fi
