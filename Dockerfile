FROM ubuntu:latest

ARG plot_dir
ARG keys
ARG harvester
ARG farmer

WORKDIR /home/ubuntu

RUN apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3

RUN git clone https://github.com/Chia-Network/chia-blockchain.git && cd chia-blockchain && chmod +x install.sh && /usr/bin/sh ./install.sh

ADD ./services.py services.py

CMD ["services.py -p $plot_dir -k $keys -harv $harvester -f $farmer"]
ENTRYPOINT ["python3"]
