#!/usr/bin/env /bin/bash
csv="${1:-progs.csv}"
progs=$(mktemp)
blacklist=$(mktemp)
meta=$(mktemp)
cat <<'EOF' > $blacklist
bitwarden-cli
ca-certificates
chezmoi
curl
git
npm
ntp
sudo
yay
zsh
EOF
pacman -Qqget | cut -f2 -d\  | sort > $meta
cat "$csv" | grep -v '^#' | cut -f2 -d, | sort > $progs
pacman -Qqet | sort | comm -23 - $blacklist | comm -23 - $meta > /tmp/pacman.txt
comm -23 /tmp/pacman.txt $progs
