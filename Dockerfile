FROM ubuntu:latest

env plot_dir
env keys
env harvester
env farmer
env plots_dir
env farmer_address
env farmer_port

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3

RUN git clone https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

WORKDIR /chia-blockchain

ADD ./chiarun chiarun
ADD ./entrypoint.sh entrypoint.sh




ENTRYPOINT ["bash", "entrypoint.sh"]
#CMD ["/home/ubuntu/services.py"]
#ENTRYPOINT ["python3"]
