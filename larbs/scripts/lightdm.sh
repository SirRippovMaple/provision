#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"

replace() {
    file=$1
    key=$2
    value=$(printf '%s\n' "$3" | sed -e 's/[\/&]/\\&/g')

    sed -i -n -e "/^$key=/!p" -e "\$a$key=$value" $file
}

cp "$SCRIPT_PATH/etc/xprofile" /etc/xprofile
chmod 755 /etc/xprofile

mkdir -p /usr/share/backgrounds
cp -f "$SCRIPT_PATH/usr/share/backgrounds/plants.jpg" /usr/share/backgrounds/plants.jpg

replace /etc/lightdm/lightdm.conf user-authority-in-system-dir true
replace /etc/lightdm/lightdm-gtk-greeter.conf hide-user-image true
replace /etc/lightdm/lightdm-gtk-greeter.conf background /usr/share/backgrounds/plants.jpg
replace /usr/share/xgreeters/lightdm-gtk-greeter.desktop Exec "env GTK_THEME=Adwaita:dark lightdm-gtk-greeter"
