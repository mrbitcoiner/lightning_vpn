# Lightning VPN
## Set up your WireGuard self hosted VPN easily and quickly

### Server Configuration

#### Start the VPN server:
```
./wireGuardServer.sh up <network_interface>
```
* Replace <network_interface> with the name of the interface to route the network traffic (usually eth0)

#### Authorize new clients to the vpn server:
```
./wireGuardServer.sh clientadd <client_pubkey> <client_internal_ip/subnet>
```
* Recommended to use 10.0.0.x/8 as the client ip range
* Following the recommendation above, <client_internal_ip/subnet> will be <10.0.0.x/32>
* The default server internal ip will be <10.0.0.1/24>

#### Stop the VPN server:
```
./wireGuardServer.sh down
```

### Client Configuration

#### Start the VPN client routing all traffic through your own VPN server:
```
./wireGuardClient.sh up <INTERNAL_VPN_CLIENT_IP/subnet> <SERVER_PUBKEY> <SERVER_HOSTNAME> <SERVER_PORT> <IP_RANGE_TO_ROUTE_THROUGH_VPN>
```
* Example: ```./wireGuardClient.sh up 10.0.0.2/8 93ne1D8MAmDiGkKoGYBoc/Nu1p/Se1QywVkymQNMq2U= 142.251.132.46 51820 0.0.0.0/0```

#### Stop the VPN client
```
./wireGuardClient.sh down
```
