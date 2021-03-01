FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl

RUN git clone https://github.com/Chia-Network/chia-blockchain.git && cd chia-blockchain && chmod +x install.sh && /usr/bin/sh ./install.sh

RUN cd chia-blockchain && ./venv/bin/chia init

RUN cd chia-blockchain && ./venv/bin/python src/farmer/farmer.py