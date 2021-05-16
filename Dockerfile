FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# set version label
LABEL maintainer="edifus"

# environment variables
ARG DEBIAN_FRONTEND="noninteractive"
ARG BRANCH="latest"

ENV KEYS="generate"
ENV HARVESTER="false"
ENV FARMER="false"
ENV PLOTS_DIR="/plots"
ENV FARMER_ADDRESS="null"
ENV FARMER_PORT="null"
ENV TESTNET="false"
ENV FULL_NODE_PORT="null"
ENV TAIL_DEBUG_LOGS="false"
ENV HOME=/config

# install chia-blockchain
RUN apt-get update && \
    apt-get install -y \
      curl \
      jq \
      python3 \
      tar \
      lsb-release \
      ca-certificates \
      git \
      sudo \
      openssl \
      unzip \
      wget \
      python3-pip \
      build-essential \
      python3-dev \
      python3.7-venv \
      python3.7-distutils && \
    echo "**** cloning ${BRANCH} ****" && \
    git clone https://github.com/Chia-Network/chia-blockchain.git --branch ${BRANCH} --recurse-submodules && \
    cd /chia-blockchain && \
    /bin/sh ./install.sh && \
    mkdir /plots && \
    chown abc:abc -R /chia-blockchain && \
    chown abc:abc -R /plots && \
    echo "**** cleanup ****" && \
    apt-get clean && \
    rm -rf \
  	  /tmp/* \
  	  /var/lib/apt/lists/* \
  	  /var/tmp/*

COPY root/ /

EXPOSE 8555 8444
VOLUME /plots /config
