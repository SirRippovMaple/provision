#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"

mkdir -p /home/storage

cat <<'EOF' > /etc/systemd/system/home-storage.mount
[Unit]
Description=Storage mount
After=network.target

[Mount]
What=192.168.0.2:/home/storage
Where=/home/storage
Type=nfs
Options=_netdev,auto,bg

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
