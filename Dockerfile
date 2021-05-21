FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"
ARG BRANCH

ARG TZ=Etc/UTC
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
                       acl \
                       ansible \
                       apt \
                       bash \
                       build-essential \
                       ca-certificates \
                       curl \
                       git \
                       jq \
                       nfs-common \
                       openssl \
                       python3 \
                       python-is-python3 \
                       python3-dev \
                       python3.8-distutils \
                       python3-pip \
                       python3.8-venv \
                       sudo \
                       tar \
                       tzdata \
                       unzip \
                       wget \
                       vim

RUN echo "cloning ${BRANCH}"
RUN git clone --branch ${BRANCH} https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& git submodule update --init mozilla-ca \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

WORKDIR /chia-blockchain
ADD ./entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "./entrypoint.sh"]
