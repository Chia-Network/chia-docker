# CHIA BUILD STEP
FROM python:3.11-slim AS chia_build

ARG BRANCH=latest
ARG COMMIT=""

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        lsb-release sudo git

WORKDIR /chia-blockchain

RUN echo "cloning ${BRANCH}" && \
    if [ -z "$COMMIT" ]; then \
        DEPTH_FLAG="--depth 1"; \
    else \
        DEPTH_FLAG=""; \
    fi && \
    git clone ${DEPTH_FLAG} --branch ${BRANCH} --recurse-submodules=mozilla-ca https://github.com/Chia-Network/chia-blockchain.git . && \
    # If COMMIT is set, check out that commit, otherwise just continue
    ( [ ! -z "$COMMIT" ] && git fetch origin $COMMIT && git checkout $COMMIT ) || true && \
    echo "running build-script" && \
    /bin/sh ./install.sh -s

# Get yq for chia config changes
FROM mikefarah/yq:4 AS yq
# Get chia-tools for a new experimental chia config management strategy
FROM ghcr.io/chia-network/chia-tools:latest AS chia-tools

# IMAGE BUILD
FROM python:3.11-slim

EXPOSE 8555 8444

# CHIA_REPO allows changing to an alternate repo if running in the mode that builds from source on startup
ENV CHIA_REPO=https://github.com/Chia-Network/chia-blockchain.git
ENV CHIA_ROOT=/root/.chia/mainnet
ENV keys="generate"
ENV service="farmer"
ENV plots_dir="/plots"
ENV farmer_address=
ENV farmer_port=
ENV testnet="false"
ENV TZ="UTC"
ENV upnp="true"
ENV log_to_file="true"
ENV healthcheck="true"
ENV chia_args=
ENV full_node_peer=

# Deprecated legacy options
ENV harvester="false"
ENV farmer="false"

# Minimal list of software dependencies
#   sudo: Needed for alternative plotter install
#   tzdata: Setting the timezone
#   curl: Health-checks
#   netcat: Healthchecking the daemon
#   yq: changing config settings
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y sudo tzdata curl netcat-traditional jq && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=chia-tools /chia-tools /usr/bin/chia-tools
COPY --from=chia_build /chia-blockchain /chia-blockchain

ENV PATH=/chia-blockchain/venv/bin:$PATH
WORKDIR /chia-blockchain

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-start.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=20m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
