FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address=""
ENV farmer_port=""
ENV harvester_remote="false"
ENV harvester_remote_ca_dir="/ca"
ENV testnet="false"
ENV full_node_port=""
ARG BRANCH

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3 vim sed

RUN echo "cloning ${BRANCH}"
RUN git clone --branch ${BRANCH} https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& git submodule update --init mozilla-ca \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

RUN sed -i 's/log_level: WARNING/log_level: DEBUG/g' /root/.chia/mainnet/config/config.yaml

WORKDIR /chia-blockchain
RUN mkdir /plots
RUN mkdir /ca
ADD ./entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]
