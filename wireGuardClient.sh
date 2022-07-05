#!/usr/bin/env bash
############################################################################################
# WireGuard Server Setup File
#
# By Mr. Bitcoiner
############################################################################################
# Exit on error
set -e
############################################################################################
# Constants

# Client
readonly WIREGUARD_KEYS_PATH="/home/${USER}/wireguard_client_data"
readonly IPS_TO_ROUTE_THROUGH_VPN=$6
readonly INTERNAL_CLIENT_IP=$2

# Server
readonly SERVER_HOSTNAME=$4
readonly SERVER_PORT=$5
readonly SERVER_PUBKEY=$3

############################################################################################
# Functions

verifications(){
    if ! which wg; then 
        printf 'WireGuard package is required\n'
        return 1 
    fi
    if ! which ip; then
        printf 'ip package is required\n'
        return 1 
    fi
    if ! which iptables; then 
        printf 'iptables package is required\n'
        return 1 
    fi
    if ! which sudo; then 
        printf 'sudo package is required\n'
        return 1 
    fi
}

wg_setup(){
    # Create public and private keys
    if [ ! -e ${WIREGUARD_KEYS_PATH} ]; then
        mkdir -p ${WIREGUARD_KEYS_PATH}
        cd ${WIREGUARD_KEYS_PATH}
        wg genkey | tee privatekey | wg pubkey > publickey
    fi 

    # Create wg config dir if not exists
    if [ ! -e /etc/wireguard ]; then
        sudo mkdir -p /etc/wireguard
    fi

    # Change ownership to the user
    sudo chown -R $USER /etc/wireguard

    # WireGuard config file
    sudo printf "
[Interface]
PrivateKey=$(cat ${WIREGUARD_KEYS_PATH}/privatekey)
Address=${INTERNAL_CLIENT_IP}
SaveConfig=true

[Peer]
PublicKey=${SERVER_PUBKEY}
Endpoint=${SERVER_HOSTNAME}:${SERVER_PORT}
AllowedIPs=${IPS_TO_ROUTE_THROUGH_VPN}
PersistentKeepalive=15
    
    \n" > /etc/wireguard/wg0.conf

    # Change ownership back to the root
    sudo chown -R root /etc/wireguard
}

wg_start(){
    # Start the tunnel
    sudo wg-quick up wg0
}

wg_stop(){
    # Stop the tunnel
    sudo wg-quick down wg0
}

wg_info(){
    printf "\nPublic Key: $(cat ${WIREGUARD_KEYS_PATH}/publickey)\n"
}

############################################################################################
# Menu

case "$1" in

    up)
        if [ -z $2 ] || [ -z $3 ] || [ -z $4 ] || [ -z $5 ] || [ -z $6 ]; then
            printf 'Expected: [INTERNAL_VPN_CLIENT_IP/subnet] [SERVER_PUBKEY] [SERVER_HOSTNAME] [SERVER_PORT] [IP_RANGE_TO_ROUTE_THROUGH_VPN]\n'
            exit 1;
        fi

        verifications
        wg_setup $2 $3 $4 $5 $6
        wg_start    
        wg_info
    ;;

    down)
        wg_stop
    ;;

    *) printf "\nUsage: [up|down|help]\n";;

esac






