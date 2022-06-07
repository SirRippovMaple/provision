#!/usr/bin/env /bin/bash
plugin_download_mirror='https://plugins.jetbrains.com/plugin/download?updateId='
download_dir=$(mktemp --directory)
rider_plugin_dir=~/.local/share/JetBrains/Rider2022.1

install_plugin() {
    plugin_id=$1
    update_id=$(curl "https://plugins.jetbrains.com/api/plugins/$plugin_id/updates" | jq '.[0].id')
    wget "$plugin_download_mirror$update_id" -O "$download_dir/$plugin_id.zip" && unzip -u "$download_dir/$plugin_id.zip" -d "$rider_plugin_dir"
}

install_plugin 164
install_plugin 10080
install_plugin 13308
install_plugin 12832
install_plugin 7793
