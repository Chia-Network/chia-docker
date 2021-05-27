FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

# chia start {all | node | harvester | farmer | farmer-no-wallet | farmer-only | timelord
# timelord-only | timelord-launcher-only | wallet | wallet-only | introducer | simulator}

ENV keys="generate" \
  harvester="false" \
  farmer="false" \
  plots_dir="/plots" \
  farmer_address="null" \
  farmer_port="null" \
  testnet="false" \
  full_node_port="null" \
  BRANCH=latest

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
  vim \
  tzdata
  && rm -rf /var/lib/apt/lists/*

RUN echo "cloning ${BRANCH}"
RUN git clone --branch ${BRANCH} https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& git submodule update --init mozilla-ca \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

WORKDIR /chia-blockchain
ADD ./entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]