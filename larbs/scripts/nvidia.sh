#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"

grep -q "^HOOKS=(.* kms" /etc/mkinitcpio.conf || ( sed -i 's/^HOOKS=(\(.*\) kms/HOOKS=(\1/' /etc/mkinitcpio.conf && mkinitcpio -P )
[ ! -f /etc/modprobe.d/nvidia.conf ] && cat <<- "EOF" > /etc/modprobe.d/nvidia.conf
blacklist amd76x_edac 
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv

options nvidia-drm modeset=1
EOF
