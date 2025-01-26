#!/bin/bash
set -e

#TODO ---- Post-installation necessary commands ----
sudo apt update -y
sudo apt upgrade -y

#TODO ---- Setup flatpak ----
sudo apt install -y flatpak wget curl
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt clean
sudo apt autoremove -y

#TODO ---- Add repos ----
if ! grep -q multiverse /etc/apt/sources.list.d/ubuntu.sources; then
    sudo add-apt-repository multiverse
    sudo add-apt-repository ppa:daniruiz/flat-remix
    sudo apt-add-repository ppa:fish-shell/release-3
    sudo dpkg --add-architecture i386
fi
#TODO ---- Install MS Teams and VS Code ----
if [ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm -f packages.microsoft.gpg
fi

# Add MS Teams repository
if [ ! -f /etc/apt/sources.list.d/teams.list ]; then
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/ms-teams stable main" | sudo tee /etc/apt/sources.list.d/teams.list
fi
# Add VS Code repository
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
fi

sudo apt install -y apt-transport-https
sudo apt update

#TODO ---- Install necessary applications ----
# Development tools
sudo apt install -y code build-essential cmake clang-format ninja-build gstreamer1.0-plugins-bad openjdk-8-jdk openjdk-17-jdk openjdk-21-jdk python3-venv python3-pip pipx maven npm dotnet-sdk-8.0 aspnetcore-runtime-8.0 dotnet-runtime-8.0 clang bash-completion golang-go gh libglew-dev libglfw3 libglfw3-dev libncurses-dev dkms acpi acpid brightnessctl xclip wl-clipboard xinput ntfs-3g playerctl xbindkeys meson

# Utilities / Libraries
sudo apt install -y imagemagick gettext wmctrl gstreamer1.0-plugins-good gstreamer1.0-libav libglib2.0-dev-bin libpcre2-dev libpixman-1-dev uthash-dev libxcb-util-dev libxcb-image0-dev libxcb-render-util0-dev libxcb-xkb-dev libdrm-dev libx11-dev libx11-xcb-dev libxcb1-dev libgl-dev libegl1-mesa-dev libepoxy-dev linux-headers-$(uname -r) linux-headers-generic libc6:i386 libncurses6:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386

# Command-line tools
sudo apt install -y fish htop s-tui nvtop tmux tldr ffmpeg flameshot vlc qbittorrent ranger putty ubuntu-restricted-extras pamixer peek blueman nitrogen valgrind

# Apps
sudo apt install -y alacritty dconf-editor gnome-tweaks gnome-shell-extensions gnome-shell-pomodoro steam-installer wine

if [ ! -d "$HOME"/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/ ]; then
    git clone https://github.com/aunetx/blur-my-shell
    cd blur-my-shell
    make install
    cd .. && rm -rf blur-my-shell
fi
if [ ! -d "$HOME"/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com ]; then
    echo "Install and enable the user theme extension: https://extensions.gnome.org/extension/19/user-themes/"
    echo -n "(Press any key to continue)"
    read -n 1 -s
    echo
fi

# Snap support
sudo apt install -y snapd
sudo snap install discord
sudo snap install vlc

# Flatpak packages
flatpak install -y flathub com.github.IsmaelMartinez.teams_for_linux
