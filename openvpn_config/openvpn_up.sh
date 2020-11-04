#!/usr/local/bin/bash

echo "
#######################################
    openvpn_up.sh
#######################################
"
echo "Writing $route_vpn_gateway to /opt/piavpn-manual/route_info"
echo $route_vpn_gateway

# Write gateway IP for reference
echo $route_vpn_gateway > /opt/piavpn-manual/route_info
