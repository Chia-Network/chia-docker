#!/bin/bash

if [[ ${healthcheck} != "true" ]]; then
    exit 0
fi

# Set default to false for all components
# Gets reset to true individually depending on ${service} variable
node_check=false
farmer_check=false
harvester_check=false
wallet_check=false

# Determine which services to healthcheck based on ${service}
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
        node_check=true
        wallet_check=true
    ;;
    wallet-only)
        wallet_check=true
    ;;
esac


if [[ ${node_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/full_node/private_full_node.crt" \
      --key "${CHIA_ROOT}/config/ssl/full_node/private_full_node.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:8555/get_network_info
    
    if [[ "$?" -ne 0 ]]; then
        echo "$(date -u) Node healthcheck failed" >> "${CHIA_ROOT}/log/debug.log"
        exit 1
    fi
fi

if [[ ${farmer_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/farmer/private_farmer.crt" \
      --key "${CHIA_ROOT}/config/ssl/farmer/private_farmer.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:8559/get_pool_state
    
    if [[ "$?" -ne 0 ]]; then
        echo "$(date -u) Farmer healthcheck failed" >> "${CHIA_ROOT}/log/debug.log"
        exit 1
    fi
fi

if [[ ${harvester_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/harvester/private_harvester.crt" \
      --key "${CHIA_ROOT}/config/ssl/harvester/private_harvester.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:8560/get_plot_directories
    
    if [[ "$?" -ne 0 ]]; then
        echo "$(date -u) Harvester healthcheck failed" >> "${CHIA_ROOT}/log/debug.log"
        exit 1
    fi
fi

if [[ ${wallet_check} == "true" ]]; then
    curl -X POST --fail \
      --cert "${CHIA_ROOT}/config/ssl/wallet/private_wallet.crt" \
      --key "${CHIA_ROOT}/config/ssl/wallet/private_wallet.key" \
      -d '{}' -k -H "Content-Type: application/json" https://localhost:9256/get_height_info
    
    if [[ "$?" -ne 0 ]]; then
        echo "$(date -u) Wallet healthcheck failed" >> "${CHIA_ROOT}/log/debug.log"
        exit 1
    fi
fi

echo "$(date -u) Healthcheck(s) completed successfully" >> "${CHIA_ROOT}/log/debug.log"
