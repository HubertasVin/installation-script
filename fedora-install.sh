#!/bin/bash
set -e

#TODO ---- Post-installation necessary commands ----
sudo dnf update -y
sudo dnf upgrade --refresh -y
sudo dnf install 'dnf-command(config-manager)'

#TODO ---- Add repos ----
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
if [ ! -f /etc/yum.repos.d/winehq.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
fi
if [ ! -f /etc/yum.repos.d/terra.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://terra.fyralabs.com/terra.repo
fi
if [ ! -f /etc/yum.repos.d/gh-cli.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
fi
if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
fi
if [ ! -f /etc/yum.repos.d/shells:zsh-users:zsh-autosuggestions.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/shells:zsh-users:zsh-autosuggestions/Fedora_Rawhide/shells:zsh-users:zsh-autosuggestions.repo
fi
if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
    sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
fi
if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD|ATI'; then
    if [ ! -f /etc/yum.repos.d/amdgpu.repo ]; then
        sudo tee /etc/yum.repos.d/amdgpu.repo <<EOF
[amdgpu]
name=amdgpu
baseurl=https://repo.radeon.com/amdgpu/6.0/rhel/9.3/main/x86_64/
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF
    fi
    if [ ! -f /etc/yum.repos.d/rocm.repo ]; then
        sudo tee --append /etc/yum.repos.d/rocm.repo <<EOF
[ROCm-6.0]
name=ROCm6.0
baseurl=https://repo.radeon.com/rocm/rhel9/6.0/main
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF
    fi
fi
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

sudo yum clean all

#TODO ---- Setup Flatpak ----
sudo dnf install --assumeyes flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#TODO ---- Install necessary applications ----
# NVIDIA drivers
if glxinfo | grep -q NVIDIA; then
    sudo dnf install -y akmods-nvidia xorg-x11-drv-nvidia-cuda
fi
if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD|ATI'; then
    sudo dnf install -y amdgpu-dkms rocm
fi
sudo dnf install -y --allowerasing fish cmake python3-pip ninja-build xrandr @virtualization ffmpeg-free ffmpeg-free-devel gstreamer1-plugin-openh264 mozilla-openh264 gcc ncurses-devel kernel-headers kernel-devel acpi acpid brightnessctl dkms java-17-openjdk java-17-openjdk-devel java-11-openjdk java-11-openjdk-devel java-21-openjdk java-21-openjdk-devel docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin maven pipx dotnet-sdk-8.0 aspnetcore-runtime-8.0 ghc-compiler go clang-tools-extra bash-completion wine sassc glfw glfw-devel glew glew-devel lm_sensors xclip wl-clipboard xkill xinput ntfs-3g playerctl xbindkeys xkb-switch dbus-devel libconfig-devel libdrm-devel libev-devel libX11-devel libX11-xcb libxcb-devel libGL-devel libEGL-devel libepoxy-devel meson pcre2-devel pixman-devel uthash-devel xcb-util-image-devel xcb-util-renderutil-devel xorg-x11-proto-devel xcb-util-devel gh picom dunst polybar udiskie rofi snapd nitrogen blueman valgrind neovim gnome-tweaks gnome-pomodoro xset vlc code steam btop htop qbittorrent minecraft-launcher discord ranger putty arandr autorandr pamixer tldr flameshot peek alacritty s-tui gnome-shell-extension-user-theme gnome-shell-extension-blur-my-shell glib2-devel ImageMagick fontawesome-fonts pavucontrol zsh php python3-devel brave-browser
sudo dnf group install -y d-development c-development development-tools
flatpak install flathub -y net.nokyan.Resources
# Install OnlyOffice
sudo dnf remove -y 'libreoffice*'
flatpak install flathub org.onlyoffice.desktopeditors

# ---- Install Starship ----
sudo dnf copr enable -y atim/starship

#TODO ---- Stard Docker ----
sudo systemctl enable --now docker
sudo gpasswd -a $USER docker

#TODO ---- systemConfiguration ----
#TODO ---- Enable H.264 decoder ----
#sudo dnf config-manager --set-enabled fedora-cisco-openh264

#TODO ---- Update system ----
sudo dnf update -y

#TODO ---- Enable virtualization stuff ----
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
