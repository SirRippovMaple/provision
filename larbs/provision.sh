#!/bin/sh
#set -x

### OPTIONS AND VARIABLES ###
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")
if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
  NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
else
  NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
fi
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


msg() { echo >&2 -e "$NOFORMAT${1-}"; }
error() { echo >&2 -e "$RED${1-}"; exit 1; }

adduserandpass() {
    # Adds user `$name` with password $pass1.
    msg "Adding login $YELLOW$name"
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
    msg "Installing $YELLOW$1$NOFORMAT, an AUR helper..."
    sudo -u "$name" mkdir -p "$repodir/$1"
    sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" >/dev/null 2>&1 ||
        { cd "$repodir/$1" || return 1 ; sudo -u "$name" git pull --force origin master;}
    cd "$repodir/$1"
    sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}

pacmaninstall() { # Installs all needed programs from main repo.
    [ ! -s "$1" ] && return

    progs_file="$1"

    msg "${YELLOW}Installing pacman packages${NOFORMAT}"
    pacman --noconfirm --needed -S $(cat "$progs_file")
}

gitmakeinstall() {
    [ ! -s "$1" ] && return

    progs_file="$1"

    msg "${YELLOW}Installing git packages${NOFORMAT}"
    while IFS=, read -r fullprogname; do
        progname="$(basename "$fullprogname" .git)"
        dir="$repodir/$progname"
        msg "Installing $YELLOW$progname$NOFORMAT ($YELLOW$n$NOFORMAT of $YELLOW$total$NOFORMAT) via \`git\` and \`make\`."
        sudo -u "$name" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1 || { cd "$dir" || return 1 ; sudo -u "$name" git pull --force origin master;}
        cd "$dir" || exit 1
        make >/dev/null 2>&1
        make install >/dev/null 2>&1
        cd /tmp || return 1 ;
    done < "$progs_file"
}

goinstall() {
    [ ! -s "$1" ] && return

    progs_file="$1"

    msg "${YELLOW}Installing go packages${NOFORMAT}"
    while IFS=, read -r progname; do
        sudo --login -u "$name" go install "$progname"
    done < "$progs_file"
}

npminstall() {
    [ ! -s "$1" ] && return
    
    progs_file="$1"

    msg "${YELLOW}Installing npm packages${NOFORMAT}"
    npm install --global $(cat "$progs_file")
}

aurinstall() {
    [ ! -s "$1" ] && return

    progs_file="$1"

    msg "${YELLOW}Installing aur packages${NOFORMAT}"
    sudo -u "$name" $aurhelper -S --noconfirm $(cat "$progs_file")
}

scriptinstall() {
    [ ! -s "$1" ] && return

    progs_file="$1"

    msg "${YELLOW}Running install scripts${NOFORMAT}"
    while IFS=, read -r progname; do
        [ -x "$SCRIPT_PATH/scripts/$progname.sh" ] && "$SCRIPT_PATH/scripts/$progname.sh" "$SCRIPT_PATH" "$name"
    done < "$progs_file"
}

installationloop() {
    ([ -f "$progsfile" ] && cp "$progsfile" /tmp/pre-progs.csv) || curl -Ls "$progsfile" > /tmp/pre-progs.csv
    cat /tmp/pre-progs.csv | sed '/^#/d' > /tmp/progs.csv
    pacman_progs_file=$(mktemp)
    aur_progs_file=$(mktemp)
    git_progs_file=$(mktemp)
    go_progs_file=$(mktemp)
    npm_progs_file=$(mktemp)
    script_progs_file=$(mktemp)
    system_services_file=$(mktemp)
    user_services_file=$(mktemp)
    user_nosession_service_file=$(mktemp)

    total=$(wc -l < /tmp/progs.csv)
    msg "Installing $total packages"
    aurinstalled=$(pacman -Qqm)

    while IFS=, read -r tag program system_service user_service user_nosession_service; do

        n=$((n+1))
        case "$tag" in
            "A") echo "$program" >> "$aur_progs_file" ;;
            "G") echo "$program" >> "$git_progs_file" ;;
            "GO") echo "$program" >> "$go_progs_file" ;;
            "NPM") echo "$program" >> "$npm_progs_file" ;;
            "S") ;;
            *) echo "$program" >> "$pacman_progs_file" ;;
        esac

        [ ! -z "$system_service" ] && echo "$system_service" >> "$system_services_file"
        [ ! -z "$user_service" ] && echo "$user_service" >> "$user_services_file"
        [ ! -z "$user_nosession_service" ] && echo "$user_nosession_service@$name" >> "$system_services_file"
        
        [ -x "$SCRIPT_PATH/scripts/$1.sh" ] && echo "$program" >> "$script_progs_file"
    done < /tmp/progs.csv ;

    pacmaninstall "$pacman_progs_file"
    installaurhelper yay || error "Failed to install AUR helper."
    aurinstall "$aur_progs_file"
    gitmakeinstall "$git_progs_file"
    goinstall "$go_progs_file"
    npminstall "$npm_progs_file"

    scriptinstall "$script_progs_file"

    systemctl enable $(cat "$system_services_file")
    systemctl enable --global $(cat "$user_services_file")
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

#for x in curl ca-certificates base-devel git ntp zsh chezmoi npm sudo libxml2; do
#    msg "Installing \`$x\` which is required to install and configure other programs."
#    installpkg "$x"
#done

msg "Synchronizing time"
ntpdate 0.us.pool.ntp.org >/dev/null 2>&1
systemctl enable "systemd-timesyncd"
timedatectl set-ntp true

{ id -u "$name" >/dev/null 2>&1; } || (adduserandpass || error "Error adding username and/or password")
mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case
pacman --noconfirm --needed -Syyu >/dev/null 2>&1

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL:ALL) NOPASSWD: ALL"

# Make pacman colorful, concurrent downloads and Pacman eye-candy.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -i "s/^#ParallelDownloads.*$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

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
