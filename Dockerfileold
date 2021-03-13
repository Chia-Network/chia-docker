FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common

RUN git clone https://github.com/Chia-Network/chia-blockchain.git && cd chia-blockchain && chmod +x install.sh && /usr/bin/sh ./install.sh
