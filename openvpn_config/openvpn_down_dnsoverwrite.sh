#!/usr/local/bin/bash

# Remove process and route information when connection closes
rm -rf /opt/pia/pia_pid /opt/pia-manual/route_info

# Replace resolv.conf with original stored as backup
cat /opt/pia/resolv_conf_backup > /etc/resolv.conf
