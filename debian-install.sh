#TODO ---- Post-installation necessary commands ----
sudo apt update -y
sudo apt upgrade -y

#TODO ---- Setup flatpak ----
sudo apt install -y flatpak wget
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt clean
sudo apt autoremove

#TODO ---- Install MS Teams ----
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/ms-teams stable main" > /etc/apt/sources.list.d/teams.list'
sudo apt update

#TODO ---- Install necessary applications ----
# Development tools
sudo apt install -y build-essential cmake ninja-build xrandr ffmpeg gstreamer1.0-plugins-bad gstreamer1.0-plugins-good gstreamer1.0-libav openjdk-17-jdk maven npm dotnet-sdk-8.0 aspnetcore-runtime-8.0 dotnet-runtime-8.0 clang-tools-extra bash-completion ghc golang-go wine libglew-dev libglfw3 libglfw3-dev libglew2.2-dev libncurses-dev linux-headers-$(uname -r) linux-headers-generic dkms acpi acpid brightnessctl starship xclip wl-clipboard xkill xinput ntfs-3g playerctl xbindkeys libx11-dev libx11-xcb-dev libxcb1-dev libgl-dev libegl1-mesa-dev libepoxy-dev meson libpcre2-dev libpixman-1-dev libuthash-dev libxcb-util-dev libxcb-image0-dev libxcb-render-util0-dev libxcb-xkb-dev libdrm-dev

# Command-line tools and utilities
sudo apt install -y htop tldr flameshot vlc qbittorrent ranger putty ubuntu-restricted-extras pamixer peek alacritty terminator blueman nitrogen valgrind

# Apps
sudo apt install -y teams dconf-editor gnome-tweaks gnome-shell-pomodoro

# Snap support
sudo apt install -y snapd
sudo snap install code --classic
sudo snap install discord
sudo snap install steam
sudo snap install vlc
