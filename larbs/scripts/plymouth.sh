#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"

cp -f "$SCRIPT_PATH/usr/share/backgrounds/plants.png" /usr/share/plymouth/themes/spinner/background-tile.png
grep -q "^HOOKS=(base udev plymouth" /etc/mkinitcpio.conf || sed -i 's/^HOOKS=(base udev/HOOKS=(base udev plymouth/' /etc/mkinitcpio.conf
plymouth-set-default-theme -R spinner
