#!/usr/bin/env /bin/sh
script_path="$1"

greq -q "^hosts: mymachines resolve" /etc/nsswitch.conf || sed -i 's/mymachines resolve/mymachines mdns_minimal [NOTFOUND=return] resole' /etc/nsswitch.conf
