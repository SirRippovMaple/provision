#!/usr/bin/env /bin/sh
set -x
home_path=$(eval echo ~$2)
sudo -u "$2" mkdir -p "$home_path/actions" && sudo -u "$2" wget --output-document="$home_path/actions/ice_recur" https://raw.githubusercontent.com/rlpowell/todo-text-stuff/master/ice_recur && sudo -u "$2" chmod +x "$home_path/actions/ice_recur"

sudo -u "$2" mkdir -p "$home_path/.local/bin" && sudo -u "$2" wget --output-document="$home_path/.local/bin/templated_checklists" https://raw.githubusercontent.com/rlpowell/todo-text-stuff/master/templated_checklists && sudo -u "$2" chmod +x "$home_path/.local/bin/templated_checklists"
