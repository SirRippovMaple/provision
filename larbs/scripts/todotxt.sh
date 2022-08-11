#!/usr/bin/env /bin/sh
set -x
actions_path=$(sudo -u "$2" realpath ~/.todo/actions)
local_bin_path=$(sudo -u "$2" realpath ~/.local/bin)
sudo -u "$2" mkdir -p "$actions_path" && sudo -u "$2" wget --output-document="$actions_path/ice_recur" https://raw.githubusercontent.com/rlpowell/todo-text-stuff/master/ice_recur && sudo -u "$2" chmod +x "$actions_path/ice_recur"

sudo -u "$2" mkdir -p "$local_bin_path" && sudo -u "$2" wget --output-document="$local_bin_path/templated_checklists" https://raw.githubusercontent.com/rlpowell/todo-text-stuff/master/templated_checklists && sudo -u "$2" chmod +x "$local_bin_path/templated_checklists"
