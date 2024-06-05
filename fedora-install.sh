scriptLoc=$(pwd)

#TODO ---- Post-installation necessary commands ----
PROMPT_COMMAND="Running Post-Installation System Updates..."
sudo dnf update -y
sudo dnf upgrade --refresh -y

#TODO ---- Add repos ----
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
sudo dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

#TODO ---- Setup Flatpak ----
PROMPT_COMMAND="Setting Up Flatpak..."
sudo dnf install --assumeyes flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#TODO ---- Install necessary applications ----
PROMPT_COMMAND="Installing Necessary Applications..."
sudo dnf install -y --allowerasing cmake ninja-build xrandr ffmpeg-free ffmpeg-free-devel gstreamer1-plugin-openh264 mozilla-openh264 gcc ncurses-devel kernel-headers kernel-devel acpid dkms akmod-nvidia xorg-x11-drv-nvidia-cuda java-17-openjdk java-17-openjdk-devel dotnet-sdk-8.0 aspnetcore-runtime-8.0 wine sassc glfw glfw-devel glew glew-devel dotnet-sdk-6.0 lm_sensors snapd neovim gnome-tweaks vlc starship xclip wl-clipboard valgrind code steam htop qbittorrent minecraft-launcher discord xkill ranger maven putty alacritty tldr flameshot udiskie ntfs-3g xset ghc-compiler bash-completion gnome-shell-extension-pop-shell xprop peek terminator gnome-pomodoro s-tui
sudo dnf groupinstall -y "Development Tools" "Development Libraries"
flatpak install flathub -y net.nokyan.Resources one.ablaze.floorp

#TODO ---- Install VS Code ----
PROMPT_COMMAND="Installing VS Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

#TODO ---- Install Starship ----
sudo dnf copr enable -y atim/starship

#TODO ---- systemConfiguration ----

#TODO ---- Enable H.264 decoder ----
sudo dnf config-manager --set-enabled fedora-cisco-openh264

#TODO ---- Update system ----
PROMPT_COMMAND="Updating System..."
sudo dnf update -y
