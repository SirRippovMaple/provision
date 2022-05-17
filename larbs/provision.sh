#!/bin/sh
set +x

### OPTIONS AND VARIABLES ###
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")
source $SCRIPT_PATH/.env

while getopts ":a:r:b:p:h" o; do case "${o}" in
    h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -a: AUR helper (must have pacman-like syntax)\\n  -h: Show this message\\n" && exit 1 ;;
    r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit 1 ;;
    b) repobranch=${OPTARG} ;;
    p) progsfile=${OPTARG} ;;
    a) aurhelper=${OPTARG} ;;
    *) printf "Invalid option: -%s\\n" "$OPTARG" && exit 1 ;;
esac done

[ -z "$dotfilesrepo" ] && dotfilesrepo="SirRippovMaple/dotfiles.git"
[ -z "$progsfile" ] && progsfile="$SCRIPT_PATH/progs.csv"
[ -z "$aurhelper" ] && aurhelper="yay"
[ -z "$repobranch" ] && repobranch="master"
name=trumpi
pass1=temp-pass1
repodir="/home/$name/.local/src"
### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}

msg() { printf "%s\n" "$1" >&2; }
error() { printf "%s\n" "$1" >&2; exit 1; }

adduserandpass() {
    # Adds user `$name` with password $pass1.
    msg "Adding login $name"
    useradd -m -G wheel -s /bin/zsh "$name" >/dev/null 2>&1 ||
    usermod -a -G wheel,docker "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
    echo "$name:$pass1" | chpasswd
    unset pass1 ;
}

refreshkeys() {
    case "$(readlink -f /sbin/init)" in
        *systemd* )
            msg "Refreshing Arch Keyring..."
            pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
            ;;
        *)
            msg "Enabling Arch Repositories..."
            pacman --noconfirm --needed -S artix-keyringartix-archlinux-support >/dev/null 2>&1
            for repo in extra community; do
                grep -q "^\[$repo\]" /etc/pacman.conf ||
                    echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
            done
            pacman -Sy >/dev/null 2>&1
            pacman-key --populate archlinux >/dev/null 2>&1
            ;;
    esac ;
}

newperms() { # Set special sudoers settings for install (or after).
    sed -i "/#LARBS/d" /etc/sudoers
    echo "$* #LARBS" >> /etc/sudoers ;
}

installaurhelper() { # Installs $1 manually. Used only for AUR helper here.
    # Should be run after repodir is created and var is set.
    msg "Installing \"$1\", an AUR helper..."
    sudo -u "$name" mkdir -p "$repodir/$1"
    sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" >/dev/null 2>&1 ||
        { cd "$repodir/$1" || return 1 ; sudo -u "$name" git pull --force origin master;}
    cd "$repodir/$1"
    sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}

postInstall() {
    [ -x "$SCRIPT_PATH/scripts/$1.sh" ] && "$SCRIPT_PATH/scripts/$1.sh" "$SCRIPT_PATH" "$name"
}

enableServices() {
    [ ! -z "$1" ] && msg "Enabling system services $1" && systemctl enable $1
    [ ! -z "$2" ] && msg "Enabling user services $2" && systemctl enable --global $2
    [ ! -z "$3" ] && msg "Enabling single user service $3" && systemctl enable ${3}@$name
}

maininstall() { # Installs all needed programs from main repo.
    msg "Installing \`$1\` ($n of $total)."
    installpkg "$1"
    postInstall "$1"
    enableServices "$2" "$3" "$4"
}

gitmakeinstall() {
    progname="$(basename "$1" .git)"
    dir="$repodir/$progname"
    msg "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1")"
    sudo -u "$name" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1 || { cd "$dir" || return 1 ; sudo -u "$name" git pull --force origin master;}
    cd "$dir" || exit 1
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
    cd /tmp || return 1 ;
}

aurinstall() {
    msg "Installing \`$1\` ($n of $total) from the AUR."
    echo "$aurinstalled" | grep -q "^$1$" && return 1
    sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1 || true
    postInstall "$1"
    enableServices "$2" "$3" "$4"
}

pipinstall() {
    msg "Installing the Python package \`$1\` ($n of $total)."
    [ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
    yes | pip install "$1"
}

installationloop() {
    ([ -f "$progsfile" ] && cp "$progsfile" /tmp/pre-progs.csv) || curl -Ls "$progsfile" > /tmp/pre-progs.csv
    cat /tmp/pre-progs.csv | sed '/^#/d' > /tmp/progs.csv
    total=$(wc -l < /tmp/progs.csv)
    msg "Installing $total packages"
    aurinstalled=$(pacman -Qqm)
    while IFS=, read -r tag program system_service user_service user_nosession_service; do
        n=$((n+1))
        case "$tag" in
            "A") aurinstall "$program" "$system_service" "$user_service" "$user_nosession_service";;
            "G") gitmakeinstall "$program" ;;
            "P") pipinstall "$program" ;;
            *) maininstall "$program" "$system_service" "$user_service" "$user_nosession_service";;
        esac
    done < /tmp/progs.csv ;
}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
    msg "Downloading and installing config files..."
    [ -z "$3" ] && branch="master" || branch="$repobranch"
    dir=$(mktemp -d)
    [ ! -d "$2" ] && mkdir -p "$2"
    chown "$name":wheel "$dir" "$2"
    sudo -u "$name" git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" >/dev/null 2>&1
    sudo -u "$name" cp -rfT "$dir" "$2"
    }

systembeepoff() {
    msg "Getting rid of that error beep sound..."
    lsmod | grep pcspkr && rmmod pcspkr
    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;
}

### THE ACTUAL SCRIPT ###

### The rest of the script requires no user input.

# Refresh Arch keyrings.
refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."

for x in curl ca-certificates base-devel git ntp zsh chezmoi sudo bitwarden-cli; do
    msg "Installing \`$x\` which is required to install and configure other programs."
    installpkg "$x"
done

msg "Synchronizing time"
ntpdate 0.us.pool.ntp.org >/dev/null 2>&1
enableServices "systemd-timesyncd"
timedatectl set-ntp true

{ id -u "$name" >/dev/null 2>&1; } || (adduserandpass || error "Error adding username and/or password")
mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL:ALL) NOPASSWD: ALL"

# Make pacman colorful, concurrent downloads and Pacman eye-candy.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -i "s/^#ParallelDownloads.*$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

installaurhelper yay || error "Failed to install AUR helper."

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Most important command! Get rid of the beep!
systembeepoff

# Make zsh the default shell for the user.
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"

# Install the dotfiles
if [ ! -d /home/$name/.config/chezmoi ]; then
    echo "source \"$SCRIPT_PATH/.env\"" > /tmp/install_dotfiles.sh
    echo "bw login --apikey" >> /tmp/install_dotfiles.sh
    echo "export BW_SESSION=\"\`bw unlock --raw --passwordenv BW_PASSWORD\`\"" >> /tmp/install_dotfiles.sh
    echo "chezmoi init --apply \"https://github.com/$dotfilesrepo\"" >> /tmp/install_dotfiles.sh
    echo "cd ~/.local/share/chezmoi" >> /tmp/install_dotfiles.sh
    echo "git remote set-url origin git@github.com:$dotfilesrepo" >> /tmp/install_dotfiles.sh
    echo "bw get item 509b05ef-c805-481f-a1e5-a8bf00949167 | jq -r .notes | gpg --import"
    chmod +x /tmp/install_dotfiles.sh
    sudo -u "$name" /tmp/install_dotfiles.sh
    rm /tmp/install_dotfiles.sh
fi

msg "Done!"
