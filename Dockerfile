FROM ubuntu:latest

## full_node_peer
EXPOSE 9699 

## full_node rpc_port
EXPOSE 9755

 ## wallet rpc_port
EXPOSE 9856

ENV CHIVES_ROOT=/root/.chives/mainnet
ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV TZ="UTC"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y bc curl lsb-release python3 tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils python-is-python3 vim tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

ARG BRANCH=V1.1.906

RUN echo "cloning ${BRANCH}" && \
    git clone --branch ${BRANCH} https://github.com/HiveProject2021/chives-blockchain.git && \
    cd chives-blockchain && \
    git submodule update --init mozilla-ca && \
    /usr/bin/sh ./install.sh

ENV PATH=/chives-blockchain/venv/bin:$PATH
WORKDIR /chives-blockchain

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-start.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
