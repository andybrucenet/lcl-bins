#!/bin/bash
# lcl-mac-ip-address.sh
# Pass in interface, IP, Subnet, Router
# Ex:
#   lcl-mac-ip-address.sh en8 172.24.0.4 255.255.252.0 172.24.0.1

# extract vars
the_nic="$1"; shift
[ x"$the_nic" = x ] && echo 'Pass in network interface name' && exit 1
the_ip_address="$1"; shift
[ x"$the_ip_address" = x ] && echo 'Pass in IP address' && exit 1
the_subnet="$1"; shift
[ x"$the_subnet" = x ] && echo 'Pass in IP subnet' && exit 1
the_router="$1"; shift
[ x"$the_router" = x ] && echo 'Pass in network router' && exit 1

# get service name
the_service_name=$(networksetup -listnetworkserviceorder | grep "${the_nic})" | sed -e "s/^(Hardware Port: \(.*\), Device: ${the_nic})/\1/")
[ x"$the_service_name" = x ] && echo "NIC '$the_nic' does not correlate to a service name." && exit 1

# issue command
set -x
sudo networksetup -setmanual "$the_service_name" $the_ip_address $the_subnet $the_router
set +x

