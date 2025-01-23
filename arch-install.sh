#!/bin/bash
scriptLoc=$(pwd)

PROMPT_COMMAND="Running Post-Installation System Updates..."
sudo pacman -Syu --noconfirm pacman-contrib
sudo pacman -S --noconfirm base-devel

#TODO ---- Install yay ----
PROMPT_COMMAND="Installing yay..."
cd ~/Downloads
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
sudo rm -r yay
cd ${scriptLoc}

#TODO ---- Install applications ----
PROMPT_COMMAND="Installing Necessary Applications..."
yay -S --noconfirm optimus-manager optimus-manager-qt gnome-session-properties piper-git minecraft-launcher visual-studio-code-bin eclipse-java teams bookworm neovim-plug bashdb gnome-shell-pomodoro

sudo pacman -S --noconfirm snapd nvidia fish neovim npm gdb steam discord lutris gimp vlc qbittorrent etcher powerline xorg-xkill nvidia-prime starship neofetch xclip wl-clipboard dotnet-sdk spotify-launcher docbook-xml intltool autoconf-archive gnome-common itstool docbook-xsl mallard-ducktype yelp-tools glib2-docs python-pygments python-anytree python-pip gtk-doc sddm ranger glow

#TODO ---- Install Rust ----
PROMPT_COMMAND="Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rust.sh
chmod +x rust.sh
./rust.sh
source ~/.cargo/env
rm rust.sh
cd ${scriptLoc}

#TODO ---- Setup SDDM ----
# PROMPT_COMMAND="Setting Up SDDM..."
# if [ `systemctl status display-manager | head -n1 | awk '{print $2;}'` != 'sddm.service' ]; then
# 	systemctl disable `systemctl status display-manager | head -n1 | awk '{print $2;}'`
# 	systemctl enable sddm
# 	sddm --example-config | sed 's/^DisplayCommand/# &/' | sed 's/^DisplayStopCommand/# &/' | sed '/Current=/s/$/plasma-chili/' | sudo tee /etc/sddm.conf > /dev/null
# 	sudo mv plasma-chili /usr/share/sddm/themes/
# fi

cp user_configs/init.lua ~/.config/lua
nvim --headless +PlugInstall +qall

#TODO ---- Change from hardware clock to local clock ----
PROMPT_COMMAND="Changing from hardware to local clock..."
timedatectl set-local-rtc 1 --adjust-system-clock

#TODO ---- Setup .zshrc ----

#TODO ---- Update mimeapps.list to change from VSCode home directory launch to Nautilus ----
echo "inode/directory=org.gnome.Nautilus.desktop" >> ~/.config/mimeapps.list
