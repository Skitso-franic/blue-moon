#!/bin/bash
set -Eeuo pipefail
clear

echo "checking if sudo"
if [ "$EUID" -ne 0 ]; then
    echo "this script must be run with sudo" >&2
    exit 1
fi


SUDO_USER="${SUDO_USER:-nobody}"

#most important varible is sudo user
#keep it at the top of the script
#because if you dont it will break
#most of the varibles in this script!!!


#start of startup varibles

#checks if running on arch linux
if ! grep -q '^ID=arch' /etc/os-release 2>/dev/null; then
 exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FONT_DIR="/home/$SUDO_USER/.local/share/fonts/MapleMono"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATA_DIR="$SCRIPT_DIR/data"
CONFIG_DEST="/home/$SUDO_USER/.config"

TARGET_DIR="/home/"$SUDO_USER"/Pictures/Wallpapers"
TARGET_WALLPAPER="$TARGET_DIR/background.jpg" #hyprpaper
SOURCE_WALLPAPER="$SCRIPT_DIR/background.jpg"


Version="epsilon_0.9a"
Support_link="https://github.com/Skitso-franic/rice/issues"
PACMAN_CONF="/etc/pacman.conf"



#end of start varibles

echo "hypr-rice"

echo "a arch linux rice"
sleep 0.5

#moves note down
echo ""
echo ""

echo " note that this tool is ment to run on a clean install of arch linux"
echo " and most likely wont work on non fresh installs"
echo " please back up anything important before useing"
echo ""
echo ""

read -p "Press [Enter] to continue..."
sleep 1
clear
#setup
echo "starting changes"
#chesks if useing sudo
sleep 0.5
clear
#checks if multilib is active
sleep 0.1

#nightmare nightmare nightmare

pacman -Syu

if grep -P "^\s*\[multilib\]" "$PACMAN_CONF" > /dev/null; then
	sleep 0.1
else
    sed -i -e '/#\[multilib\]/,+1s/^#//' "$PACMAN_CONF"
    
    if grep -P "^\s*\[multilib\]" "$PACMAN_CONF" > /dev/null; then
        pacman -Sy --noconfirm
    else
        echo "failed to enable multilib please enable multilib manually."
        exit 1
    fi
fi
#flatpak and pacman
pacman -S --needed --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
pacman -S --needed --noconfirm git base-devel
pacman -S --needed --noconfirm neovim fastfetch firefox

#is yet another yogurt installed?
if command -v "yay" &> /dev/null; then
    echo ""
fi

git clone https://aur.archlinux.org/yay.git || { echo "failed to clone yay repository"; exit 1; }
chown -R "$SUDO_USER":"$SUDO_USER" yay
cd yay
#disabled for testing uncomment this before posting to anything

#fixed running makepkg as sudo
sudo -u "$SUDO_USER" makepkg -si --noconfirm

cd ..
rm -rf yay
#install waybar
pacman -S --needed --noconfirm waybar 

#installs maple mono
if ! command -v curl &>/dev/null || ! command -v unzip &>/dev/null; then
    echo "Installing required tools (curl, unzip)..."
    pacman -S --needed --noconfirm curl unzip
fi
mkdir -p "$FONT_DIR"
curl -L --fail --show-error --silent "https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-TTF.zip" -o "$TMP_DIR/MapleMono-TTF.zip"
#validates archive
if ! unzip -tq "$TMP_DIR/MapleMono-TTF.zip" >/dev/null; then
    echo "archive is invalid"
    exit 1
fi
#extract zip
unzip -oq "$TMP_DIR/MapleMono-TTF.zip" -d "$TMP_DIR/MapleMono-TTF"
#verify font
find "$TMP_DIR/MapleMono-TTF" -type f -iname '*.ttf' -print -quit
#confirm it exists
if ! find "$TMP_DIR/MapleMono-TTF" -type f -iname '*.ttf' -print | grep -q .; then
    echo "no ttf fonts found"
    exit 1
fi
#installs font
find "$TMP_DIR/MapleMono-TTF" -type f -iname '*.ttf' \
    -exec cp {} "$FONT_DIR"/ \;
chown "$SUDO_USER":"$SUDO_USER" "$FONT_DIR"/*.ttf
sudo -u "$SUDO_USER" fc-cache -fv


#hyprpaper

pacman -S hyprpaper hyprtoolkit hyprlang hyprutils hyprwire --needed --noconfirm

if [ ! -d "$TARGET_DIR" ]; then
    echo "$TARGET_DIR does not exist creating it"
    sudo -u "$SUDO_USER" mkdir -p "$TARGET_DIR"
fi

if [ -f "$SOURCE_WALLPAPER" ]; then
    sudo -u "$SUDO_USER" cp "$SOURCE_WALLPAPER" "$TARGET_WALLPAPER"
else
    echo "integ check failed = '$SOURCE_WALLPAPER'"
    exit 1
fi

#the hyprpaper install took me a week! to get working :(

#safety check

if [ ! -d "$DATA_DIR" ]; then
    echo "integ check failed = $DATA_DIR"
    exit 1
fi



#configs
sudo -u "$SUDO_USER" mkdir -p "$CONFIG_DEST"

for item in "$DATA_DIR"/*; do
    if [ -d "$item" ]; then
        target_name=$(basename "$item")
        echo "Copying $target_name to $CONFIG_DEST..."
        sudo -u "$SUDO_USER" cp -r "$item" "$CONFIG_DEST/"
    fi
done

#finish setup

echo "setup done"
echo ""
echo "please report any bugs/issues"
echo "$Support_link"
echo "script version: $Version"


