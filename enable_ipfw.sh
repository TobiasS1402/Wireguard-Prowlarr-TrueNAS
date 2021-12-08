#!/usr/local/bin/bash

printf "
#############################
        Setup IPFW
############################# \n\n"

cp ipfw.rules /etc/ipfw/rules

sed -i -E 's/firewall_enable=.*//g' /etc/rc.conf
sed -i -E 's/firewall_nat_enable=.*//g' /etc/rc.conf
sed -i -E 's/firewall_script=.*//g' /etc/rc.conf
sed -i -E 's/firewall_logging=.*//g' /etc/rc.conf
sed -i -E 's/gateway_enable=.*//g' /etc/rc.conf

printf %b\\n "gateway_enable=\"YES\"
firewall_enable=\"YES\"
firewall_nat_enable=\"YES\"
firewall_script=\"/usr/local/etc/IPFW.rules\"
firewall_logging=\"YES\"" | tee -a /etc/rc.conf >/dev/null
