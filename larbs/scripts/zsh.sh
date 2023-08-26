#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"
NAME="$2"

cp "$SCRIPT_PATH/etc/zsh/zshenv" /etc/zsh/zshenv
chmod 755 /etc/zsh/zshenv
chsh -s /bin/zsh "$NAME"
