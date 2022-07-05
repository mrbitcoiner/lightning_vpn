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

readonly WIREGUARD_KEYS_PATH="/home/${USER}/wireguard_server_data"
readonly WG_INTERFACE_IP_RANGE='10.0.0.1/8'
readonly WG_LISTEN_PORT='51820'

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
    local wg_interface=$1

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

    # Set wg config dir ownership
    sudo chown -R $USER /etc/wireguard

    # Set WireGuard config file
    if ! cat /etc/wireguard/wg0.conf | grep "${WG_INTERFACE_IP_RANGE}"  || ! cat /etc/wireguard/wg0.conf | grep "${wg_interface}"; then
        sudo printf "
[Interface]
PrivateKey=$(cat ${WIREGUARD_KEYS_PATH}/privatekey)
Address=${WG_INTERFACE_IP_RANGE}
SaveConfig=true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${wg_interface} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${wg_interface} -j MASQUERADE
ListenPort=${WG_LISTEN_PORT}

        \n" > /etc/wireguard/wg0.conf

        printf 'WG Config Setted\n'

    fi

    # Set wg config dir ownership
    sudo chown -R root:root /etc/wireguard
}


# Start WireGuard
wg_start(){
    if sudo wg-quick up wg0; then
        printf 'All done, wireguard up and running\n'
    else 
        if ! sudo wg-quick down wg0; then
            printf 'Oops, something went wrong\n'
            exit 1
        fi
        if ! sudo wg-quick up wg0; then
            printf 'Oops, something went wrong\n'
            exit 1
        fi

        printf 'All done, wireguard up and running\n'
    fi
}

wg_stop(){
    sudo wg-quick down wg0
}

# Add client
wg_clientadd(){
    local client_pubkey=${1}
    local client_ip_range=${2}

    sudo wg set wg0 peer ${client_pubkey} allowed-ips ${client_ip_range}
}

# Info
wg_info(){
    sudo wg
    printf "\n\nServer public key: $(cat ${WIREGUARD_KEYS_PATH}/publickey)\n"
}
############################################################################################
# Menu

case "$1" in

    up)
        if [ -z $2 ]; then
            printf 'Expected args: [exit_network_interface]\n'
            exit 1
        fi
        verifications
        wg_setup $2
        wg_start    
        wg_info
    ;;

    down)
        wg_stop
    ;;

    clientadd)
        if [ -z $2 ] || [ -z $3 ]; then
            printf 'Expected args: [pubkey] [ip_range]\n'
            exit 1
        fi

        printf "$2 --- $3\n"

        wg_clientadd $2 $3
    ;;

    *) printf "\nUsage: [up|down|clientadd|help]\n";;

esac



############################################################################################
# Info

# See ip info
# sudo ip addr

# See WireGuard info
# sudo wg

# Must be 1
# cat /proc/sys/net/ipv4/ip_forward
# If not 1, run and reboot the server: 
# sysctl -w net.ipv4.ip_forward=1