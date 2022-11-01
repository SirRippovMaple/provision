#!/usr/bin/env /bin/sh
set -x
home_path=$(eval echo ~$2)
sudo -u "$2" mkdir -p "$home_path/.todo/actions" && sudo -u "$2" wget --output-document="$home_path/.todo/actions/ice_recur" https://raw.githubusercontent.com/rlpowell/todo-text-stuff/master/ice_recur && sudo -u "$2" chmod +x "$home_path/.todo/actions/ice_recur"

sudo -u "$2" mkdir -p "$home_path/.local/bin" && sudo -u "$2" wget --output-document="$home_path/.local/bin/templated_checklists" https://raw.githubusercontent.com/rlpowell/todo-text-stuff/master/templated_checklists && sudo -u "$2" chmod +x "$home_path/.local/bin/templated_checklists"

sudo -u "$2" wget --output-document="$home_path/.todo/actions/hey" https://gist.github.com/quad/4241425/raw/b7daff3942f5aa8d06c0df44e834c62ca9904dd0/hey.rb && sudo -u "$2" chmod +x "$home_path/.todo/actions/hey"
