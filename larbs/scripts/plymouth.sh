#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"

cp -f "$SCRIPT_PATH/usr/share/backgrounds/plants.png" /usr/share/plymouth/themes/spinner/background-tile.png
grep -q "^HOOKS=(base udev plymouth" /etc/mkinitcpio.conf || sed -i 's/^HOOKS=(base udev/HOOKS=(base udev plymouth/' /etc/mkinitcpio.conf
grep -q 'quiet splash vt.global_cursor_default=0' /etc/default/grub || (sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ quiet splash vt.global_cursor_default=0"/' /etc/default/grub && grub-mkconfig -o /boot/grub/grub.cfg)
plymouth-set-default-theme -R spinner
