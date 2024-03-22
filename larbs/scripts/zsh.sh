#!/usr/bin/env /bin/sh
SCRIPT_PATH="$1"
NAME="$2"

cp "$SCRIPT_PATH/etc/zsh/zshenv" /etc/zsh/zshenv
chmod 755 /etc/zsh/zshenv
chsh -s /bin/zsh "$NAME"

echo '[ ! -d "${ZDOTDIR:-$HOME}/.antidote" ] && git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}"/.antidote' > /tmp/install_antidote.sh
echo '/tmp/runindir "${ZDOTDIR:-$HOME}/.antidote" git pull' >> /tmp/install_antidote.sh
chmod 777 /tmp/install_antidote.sh
sudo --login --user "$2" /tmp/install_antidote.sh
