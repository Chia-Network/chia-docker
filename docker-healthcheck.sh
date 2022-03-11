#!/bin/bash

# shellcheck disable=SC2154
if [[ ${healthcheck} != "true" ]]; then
    exit 0
fi

logger () {
    # shellcheck disable=SC2154
    if [[ ${log_to_file} != 'true' ]]; then
        echo "$1" >> /proc/1/fd/1
    else
        echo "$1" >> "${CHIA_ROOT}/log/debug.log"
    fi
}

# Set default to false for all components
# Gets reset to true individually depending on ${service} variable
node_check=false
farmer_check=false
harvester_check=false
wallet_check=false

# Determine which services to healthcheck based on ${service}
# shellcheck disable=SC2154
case "${service}" in
    all)
        node_check=true
        farmer_check=true
        harvester_check=true
        wallet_check=true
    ;;
    node)
        node_check=true
    ;;
    harvester)
        harvester_check=true
    ;;
    farmer)
        node_check=true
        farmer_check=true
        harvester_check=true
        wallet_check=true
    ;;
    farmer-no-wallet)
        node_check=true
        farmer_check=true
        harvester_check=true
    ;;
    farmer-only)
        farmer_check=true
    ;;
    wallet)
        wallet_check=true
    ;;
esac


if [[ ${node_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/full_node/private_full_node.crt" \
      --key "${CHIA_ROOT}/config/ssl/full_node/private_full_node.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:8555/get_routes
    
    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(date -u) Node healthcheck failed"
        exit 1
    fi
fi

if [[ ${farmer_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/farmer/private_farmer.crt" \
      --key "${CHIA_ROOT}/config/ssl/farmer/private_farmer.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:8559/get_routes
    
    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(date -u) Farmer healthcheck failed"
        exit 1
    fi
fi

if [[ ${harvester_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/harvester/private_harvester.crt" \
      --key "${CHIA_ROOT}/config/ssl/harvester/private_harvester.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:8560/get_routes
    
    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(date -u) Harvester healthcheck failed"
        exit 1
    fi
fi

if [[ ${wallet_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/wallet/private_wallet.crt" \
      --key "${CHIA_ROOT}/config/ssl/wallet/private_wallet.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:9256/get_routes
    
    # shellcheck disable=SC2181
    if [[ "$?" -ne 0 ]]; then
        logger "$(date -u) Wallet healthcheck failed"
        exit 1
    fi
fi

logger "$(date -u) Healthcheck(s) completed successfully"
