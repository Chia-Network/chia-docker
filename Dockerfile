FROM ubuntu:latest AS install

ARG BRANCH="latest"

ENV DEBIAN_FRONTEND=noninteractive

RUN chmod 1777 /tmp
RUN apt-get update -q
RUN apt-get upgrade -qy
RUN apt-get install -qy --no-install-recommends \
  bc \
  ca-certificates \
  gcc \
  git \
  lsb-release \
  make \
  sudo \
  tzdata \
  wget
RUN git clone -b ${BRANCH} \
    https://github.com/Chia-Network/chia-blockchain.git
WORKDIR /chia-blockchain
RUN git submodule update --init mozilla-ca
RUN /bin/bash install.sh


FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV CHIA_ROOT=/root/.chia/mainnet
ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV TZ="UTC"

COPY --from=install /chia-blockchain /chia-blockchain

RUN chmod 1777 /tmp && \
    apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -qy && \
    python_version=$(ls /chia-blockchain/venv/lib) && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
      ${python_version}-distutils \
      ${python_version}-venv \
      tzdata && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/chia-blockchain/venv/bin:$PATH
WORKDIR /chia-blockchain

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
