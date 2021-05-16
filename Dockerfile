FROM ubuntu:latest

ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"
ENV log_display="false"
ARG BRANCH

RUN mkdir /plots && \
  DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y \
      curl \
      jq \
      python3 \
      ansible \
      tar \
      bash \
      ca-certificates \
      git \
      openssl \
      unzip \
      wget \
      python3-pip \
      sudo \
      acl \
      build-essential \
      python3-dev \
      python3.8-venv \
      python3.8-distutils \
      apt \
      nfs-common \
      python-is-python3 \
      vim && \
    echo "**** cloning ${BRANCH} ****" && \
    git clone https://github.com/Chia-Network/chia-blockchain.git --branch ${BRANCH} --recurse-submodules && \
    cd chia-blockchain && \
    /usr/bin/sh ./install.sh && \
    echo "**** cleanup ****" && \
    apt-get clean && \
    rm -rf \
  	  /tmp/* \
  	  /var/lib/apt/lists/* \
  	  /var/tmp/*

WORKDIR /chia-blockchain
ADD ./entrypoint.sh entrypoint.sh

EXPOSE 8555 8444
VOLUME /plots

ENTRYPOINT ["bash", "./entrypoint.sh"]
