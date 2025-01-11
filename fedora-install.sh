scriptLoc=$(pwd)

#TODO ---- Post-installation necessary commands ----
sudo dnf update -y
sudo dnf upgrade --refresh -y
sudo dnf install 'dnf-command(config-manager)'

#TODO ---- Add repos ----
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
sudo dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

#TODO ---- Setup Flatpak ----
sudo dnf install --assumeyes flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#TODO ---- Install necessary applications ----
sudo dnf install -y --allowerasing cmake ninja-build xrandr @virtualization ffmpeg-free ffmpeg-free-devel gstreamer1-plugin-openh264 mozilla-openh264 gcc ncurses-devel kernel-headers kernel-devel acpi acpid brightnessctl dkms akmod-nvidia xorg-x11-drv-nvidia-cuda java-17-openjdk java-17-openjdk-devel maven dotnet-sdk-8.0 aspnetcore-runtime-8.0 ghc-compiler go clang-tools-extra bash-completion wine sassc glfw glfw-devel glew glew-devel lm_sensors starship xclip wl-clipboard xkill xinput ntfs-3g playerctl xbindkeys xkb-switch dbus-devel libconfig-devel libdrm-devel libev-devel libX11-devel libX11-xcb libxcb-devel libGL-devel libEGL-devel libepoxy-devel meson pcre2-devel pixman-devel uthash-devel xcb-util-image-devel xcb-util-renderutil-devel xorg-x11-proto-devel xcb-util-devel gh-cli picom dunst polybar udiskie i3 i3blocks rofi snapd nitrogen blueman valgrind neovim gnome-tweaks gnome-pomodoro xset vlc code steam htop qbittorrent minecraft-launcher discord ranger putty arandr autorandr pamixer tldr flameshot peek terminator alacritty s-tui gnome-shell-extension-user-theme gnome-shell-extension-blur-my-shell glib2-devel Imagemagick
sudo dnf groupinstall -y "Development Tools" "Development Libraries"
flatpak install flathub -y net.nokyan.Resources

#TODO ---- Install Starship ----
sudo dnf copr enable -y atim/starship

#TODO ---- systemConfiguration ----
#TODO ---- Enable H.264 decoder ----
sudo dnf config-manager --set-enabled fedora-cisco-openh264

#TODO ---- Update system ----
sudo dnf update -y

#TODO ---- Enable virtualization stuff ----
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

#TODO ---- Install glow for CLI markdown reading ----
echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
sudo yum install glow
