#! /bin/bash
# Basic commands after linux install
scriptLoc=$(pwd)

#TODO ---- Install SDKMAN ----
curl -s "https://get.sdkman.io" | bash

set -e # Crash program on error

FDIR="$HOME/.local/share/fonts"

# Install Fonts
install_fonts() {
y	echo -e "\n[*] Installing fonts..."
	[[ ! -d "$FDIR" ]] && mkdir -p "$FDIR"
	cp -rf $DIR/fonts/* "$FDIR"
}

clear

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                   DEBIAN                   │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
if [ `which apt 2>/dev/null` ]; then	# App DEBIAN
	#TODO ---- Post-installation necessary commands ----
	PROMPT_COMMAND="Running Post-Installation System Updates..."
	yes | sudo apt update
	yes | sudo apt upgrade

	#TODO ---- Setup flatpak ----
	PROMPT_COMMAND="Setting Up Flatpak..."
	sudo apt install -y flatpak wget
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	sudo apt clean
	sudo apt autoremove

	#TODO ---- Install Microsoft packages for VSCode ----
	wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
	sudo dpkg -i packages-microsoft-prod.deb
	rm packages-microsoft-prod.deb

	#TODO ---- Add VSCode, so that it can be installed using apt install ----
	PROMPT_COMMAND="Setting Up VS Code..."
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
	sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
	rm -f packages.microsoft.gpg

	#TODO ---- Install MS Teams ----
	PROMPT_COMMAND="Setting Up MS Teams..."
	curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
	sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/ms-teams stable main" > /etc/apt/sources.list.d/teams.list'
	sudo apt update

	#TODO ---- Install TrueType fonts ----
	PROMPT_COMMAND="Installing TrueType Fonts..."
	update_progress "$scriptProg" "Installing TrueType fonts"
	wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
	sudo dpkg -i ttf-mscorefonts-installer_3.6_all.deb
	sudo fc-cache -f -v 	# Refresh fonts cache
	rm ttf-mscorefonts-installer_3.6_all.deb

	#TODO ---- Install necessary applications ----
	PROMPT_COMMAND="Installing Necessary Applications..."
	aptApps=(ubuntu-restricted-extras snapd gpg vim xclip gdb gnome-common steam-installer code piper npm apt-transport-https code dosbox gnome-tweaks balena-etcher-electron qbittorrent lutris gimp xdotool dotnet-sdk-7.0 aspnetcore-runtime-7.0 dotnet-runtime-7.0 neofetch docbook-xml teams intltool autoconf-archive itstool docbook-xsl yelp-tools glib2-docs python-pygments gtk-doc-tools sddm dconf-editor ranger maven)
	snapApps=(starship spotify mc-installer discord vlc)

	for i in ${!aptApps[@]}
	do

		sudo apt install -y ${aptApps[$i]}
	done
	for i in ${!snapApps[@]}
	do
		yes | sudo snap install ${snapApps[$i]}
	done

	PROMPT_COMMAND="Setting Up SDDM..."
	#TODO ---- Setup sddm ----
	if [ `systemctl status display-manager | head -n1 | awk '{print $2;}'` != 'sddm.service' ]; then
		echo 'Pakeičiamas display manager į sddm'
		systemctl disable `systemctl status display-manager | head -n1 | awk '{print $2;}'`
		systemctl enable sddm
		sddm --example-config | sed 's/^DisplayCommand/# &/' | sed 's/^DisplayStopCommand/# &/' | sed '/Current=/s/$/plasma-chili/' | sudo tee /etc/sddm.conf > /dev/null
		sudo mv plasma-chili /usr/share/sddm/themes/
	fi

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                   FEDORA                   │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which rpm 2>/dev/null` ]; then
	((scriptSize+=45))
	#TODO ---- Post-installation necessary commands ----
	PROMPT_COMMAND="Running Post-Installation System Updates..."
	sudo dnf update -y
	sudo dnf upgrade --refresh -y

	#TODO ---- Add repos ----
	sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
	sudo dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
	sudo dnf copr enable t0xic0der/nvidia-auto-installer-for-fedora -y

	#TODO ---- Install nvidia drivers ----
	sudo dnf install nvautoinstall -y
	sudo nvautoinstall rpmadd
	sudo nvautoinstall driver
	sudo nvautoinstall nvrepo
	sudo nvautoinstall plcuda

	#TODO ---- Setup Flatpak ----
	PROMPT_COMMAND="Setting Up Flatpak..."
	sudo dnf install --assumeyes flatpak
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	#TODO ---- Install necessary applications ----
	PROMPT_COMMAND="Installing Necessary Applications..."
 	sudo dnf install -y --allowerasing xrandr nvautoinstall ffmpeg ffmpeg-devel gstreamer1-plugin-openh264 mozilla-openh264 gcc ncurses-devel kernel-headers kernel-devel java-17-openjdk java-17-openjdk-devel dotnet-sdk-7.0 aspnetcore-runtime-7.0 winehq-stable glfw glfw-devel glew glew-devel dotnet-sdk-6.0 flatpak neovim gnome-tweaks vlc starship xclip valgrind code steam htop qbittorrent minecraft-launcher discord xkill ranger maven putty alacritty redshift tldr flameshot brightnessctl gnetwork-manager-applet udiskie ntfs-3g notification-daemon polybar bdftopcf xset intel-gpu-tools aha nvtop ghc-compiler xcompmgr lpf-spotify-client qtile rofi bash-completion nitrogen
	flatpak install flathub -y net.nokyan.Resources com.spotify.Client com.github.IsmaelMartinez.teams_for_linux

	#TODO ---- Intall ffmpeg ----
	PROMPT_COMMAND="Installing ffmpeg..."
	sudo dnf -y install ffmpeg
	sudo dnf -y install ffmpeg-devel

	#TODO ---- Install VS Code ----
	PROMPT_COMMAND="Installing VS Code..."
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
	#TODO ---- Install Minecraft launcher ----
	# PROMPT_COMMAND="Setting Up Minecraft..."
	# sudo dnf copr enable stenstorp/Minecraft -y
	#TODO ---- Install OnlyOffice ----
	PROMPT_COMMAND="Installing OnlyOffice..."
	wget https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors.x86_64.rpm
	sudo dnf install onlyoffice-desktopeditors.x86_64.rpm
	rm onlyoffice-desktopeditors.x86_64.rpm
	#TODO ---- Install Starship ----
	sudo dnf copr enable -y atim/starship
	#TODO ---- Enable H.264 decoder ----
	sudo dnf config-manager --set-enabled fedora-cisco-openh264

	#TODO ---- systemConfiguration ----

	#TODO ---- Update system ----
	PROMPT_COMMAND="Updating System..."
	sudo dnf update -y


# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                    ARCH                    │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙

elif [ `which pacman 2>/dev/null` ]; then
	PROMPT_COMMAND="Running Post-Installation System Updates..."
	sudo pacman -Syu --noconfirm
	sudo pacman -S base-devel

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
	yayApps=(optimus-manager optimus-manager-qt gnome-session-properties piper-git minecraft-launcher visual-studio-code-bin dotnet-sdk-bin eclipse-java teams bookworm neovim-plug bashdb)
	pacApps=(nvidia neovim npm gdb steam discord lutris gimp vlc qbittorrent etcher powerline xorg-xkill nvidia-prime dosbox starship neofetch xclip spotify-launcher docbook-xml intltool autoconf-archive gnome-common itstool docbook-xsl mallard-ducktype yelp-tools glib2-docs python-pygments python-anytree gtk-doc sddm ranger)
	for i in ${!yayApps[@]}
	do
		yay -S --noconfirm ${yayApps[$i]}
	done

	for i in ${!pacApps[@]}
	do
		sudo pacman -S --noconfirm ${pacApps[$i]}
	done

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

	echo '------------------------------------------------------------------------------------------------'
	echo '-------------------- Switch on auto start on startup for optimus-manager-qt --------------------'
	echo '------------------------------------------------------------------------------------------------'


else
	echo "Unknown distribution"
fi

if [ `which gsettings` ]; then
	#TODO ---- Gnome configuration ----
	PROMPT_COMMAND="Restoring GNOME settings..."
	cd $scriptLoc
	dconf load -f / < user_config/saved_settings.dconf
	# Force alt + tab to switch only on current workspace in GNOME
	gsettings set org.gnome.shell.app-switcher current-workspace-only true
	# Screen time-out
	gsettings set org.gnome.desktop.session idle-delay 4500
	gsettings set org.gnome.desktop.screensaver lock-delay 900
	# Keyboard shortcuts
	gsettings set org.gnome.shell.keybindings toggle-application-view []
	gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader []
	gsettings set org.gnome.shell.keybindings toggle-overview []

	PS3="Select your prefered color for the theme: "


	select themeColor in default purple pink red orange yellow green teal blue all
	do
		case $themeColor in
			"default")
				echo "Selected the $themeColor color"
				colorCode="#FB8C00"
				break;;
			"purple")
				echo "Selected the $themeColor color"
				colorCode="#AB47BC"
				break;;
			"pink")
				echo "Selected the $themeColor color"
				colorCode="#EC407A"
				break;;
			"red")
				echo "Selected the $themeColor color"
				colorCode="#E53935"
				break;;
			"orange")
				echo "Selected the $themeColor color"
				colorCode="#FB8C00"
				break;;
			"yellow")
				echo "Selected the $themeColor color"
				colorCode="#FBC02D"
				break;;
			"green")
				echo "Selected the $themeColor color"
				colorCode="#4CAF50"
				break;;
			"teal")
				echo "Selected the $themeColor color"
				colorCode="#009688"
				break;;
			"blue")
				echo "Selected the $themeColor color"
				colorCode="#3684DD"
				break;;
			"all")
				echo "Selected the $themeColor color"
				colorCode="#FB8C00"
				break;;
			*)
		esac
	done
	#TODO ---- Theme installation ----
	PROMPT_COMMAND="Installing Graphite Theme For GNOME..."
	git clone https://github.com/vinceliuice/Graphite-gtk-theme.git
	sudo Graphite-gtk-theme/install.sh -t $themeColor
	sudo rm -r Graphite-gtk-theme/
	gsettings set org.gnome.desktop.interface gtk-theme "Graphite-$themeColor-Dark"
	gsettings set org.gnome.desktop.wm.preferences theme "Graphite-$themeColor-Dark"

	#TODO ---- Icon pack installation ----
	PROMPT_COMMAND="Installing Tela Circle Icon Pack..."
	git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
	Tela-circle-icon-theme/install.sh $themeColor
	sudo rm -r Tela-circle-icon-theme/
	gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-$themeColor-dark"

	#TODO ---- Configuring Starship ----
	PROMPT_COMMAND="Configuring Starship..."
	mkdir -p ~/.config && touch ~/.config/starship.toml
	search=%COLORCODE
	cat user_config/starship_template.toml > ~/.config/starship.toml
	sed -i "s/$search/$colorCode/" ~/.config/starship.toml
fi

#TODO ---- Configuring alacritty ----
mkdir -p ~/.config/alacritty/themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
cp "$scriptLoc"/user_config/alacritty.yml ~/.config/alacritty

#TODO ---- Install fonts for Polybar ----
STYLE='simple'
[[ ! -d "$FDIR" ]] && mkdir -p "$FDIR"
cp -rf "$scriptLoc"/fonts/* "$FDIR"

#TODO ---- Setup Polybar ----
cp -r "$scriptLoc"/user_config/polybar/* ~/.config/polybar

#TODO ---- Setup qtile and rofi ----
cp -r "$scriptLoc"/user_config/qtile/* ~/.config/qtile
cp -r "$scriptLoc"/user_config/rofi/* ~/.config/rofi

#TODO ---- Setup ctrl-backspace and ctrl-delete for terminal ----
cp ~/Installation_Script/user_config/.inputrc ~

#if [ "$SHELL" = "/bin/bash" ]; then
#	#TODO ---- Setup .bashrc ----
#	PROMPT_COMMAND="Updating .bashrc..."
#	echo "INSTSCRIPT=$scriptLoc" >> ~/.bashrc;
#	cat user_config/template.bashrc >> ~/.bashrc
#elif [ "$SHELL" = "/bin/zsh" ]; then
#	#TODO ---- Setup .zshrc ----
#	PROMPT_COMMAND="Updating .zshrc..."
#	echo "INSTSCRIPT=$scriptLoc" >> ~/.zshrc;
#	cat user_config/template.zshrc >> ~/.zshrc
#fi

#TODO ---- Install Gradle ----"
PROMPT_COMMAND="Installing Gradle..."
# sdk install gradle

# TODO ---- Add the user to pkg-build group ----
sudo usermod -a -G pkg-build hubertas

#TODO ---- Install GHCup ----
PROMPT_COMMAND="Installing GHCup..."
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

#TODO ---- Setup One Dark Pro for terminal ----
PROMPT_COMMAND="Setting up One Dark Pro for terminal..."
cd ~
git clone https://github.com/denysdovhan/one-gnome-terminal.git
cd one-gnome-terminal/
chmod +x one-dark.sh
./one-dark.sh
cd ~
rm -rf one-gnome-terminal/

#TODO ---- Setup ranger ----
PROMPT_COMMAND="Setting up ranger..."
ranger --copy-config=rifle
ranger --copy-config=rc
echo "" >> ~/.config/ranger/rc.config
echo "# Archives" >> ~/.config/ranger/rc.config
echo "map ex extract" >> ~/.config/ranger/rc.config
echo "map ec compress" >> ~/.config/ranger/rc.config
mkdir -p ~/.config/ranger/plugins
cd ~/.config/ranger/plugins
if [ ! -d "ranger-archives" ] ; then
    git clone https://github.com/maximtrp/ranger-archives.git
fi

#TODO ---- Setup NeoVIM ----
PROMPT_COMMAND="Setting up NeoVIM..."
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
mkdir -p ~/.vim
cd ~/.vim
mkdir -p ~/.config/nvim/
if [ ! -d "nvimrc" ] ; then
	git clone --depth=1 https://github.com/venjiang/nvimrc.git ~/.vim
fi
sh ~/.vim/install.sh
sed -i "83i Plug 'wakatime/vim-wakatime'" ~/.vim/vimrcs/plugins.vim
nvim +PlugInstall
nvim +WakaTimeApiKey
#TODO Allow NeoVIM to access the clipboard
set clipboard=unnamedplus

#TODO ---- Install AT Launcher ----
PROMPT_COMMAND="Installing AT Launcher..."
cd ~
wget https://raw.githubusercontent.com/DavidoTek/linux-install-atlauncher/master/linux-install-atlauncher.sh
chmod +x linux-install-atlauncher.sh
./linux-install-atlauncher.sh
rm linux-install-atlauncher.sh

#TODO ---- Setup SSH ----
PROMPT_COMMAND="Setting Up SSH With Github..."
echo 'Setting up ssh'
echo 'Enter git email:'
read gitEmail
ssh-keygen -t rsa -b 4096 -C $gitEmail
cat ~/.ssh/id_rsa.pub | xclip -selection clipboard
echo 'SSH key copied to clipboard, go to Github:'
echo '1. Go to user settings'
echo '2. Press "SSH and GPG keys"'
echo '3. Paste in the copied text in to the text box'
read -n 1 -p '(Press any key to continue)' input

#TODO ---- Setup git ----
PROMPT_COMMAND="Setting Up Git..."
echo 'Setting up git'
echo 'Enter git username:'
read gitName
git config --global user.name "$gitName"
git config --global user.email "$gitEmail"
echo "Host *" >> ~/.ssh/config
echo "    StrictHostKeyChecking no" >> ~/.ssh/config

PROMPT_COMMAND="Downloading BackupFolder..."
cd ~/Documents
git clone git@github.com:HubertasVin/BackupFolder.git

PROMPT_COMMAND="Downloading CSGO Config Backup..."
git clone git@github.com:HubertasVin/CSGO_Config.git

PROMPT_COMMAND="Downloading Pictures Backup..."
git clone git@github.com:HubertasVin/PictureBackup.git
cp -r PictureBackup/* ~/Pictures/
cp -r PictureBackup/.git ~/Pictures/
sudo rm -r PictureBackup/

sudo cp "$scriptLoc"/desktop_shortcuts/dosbox-school.desktop /usr/share/applications/
cp "$scriptLoc"/desktop_shortcuts/terminal-autostart.desktop ~/.config/autostart/

cd $scriptLoc
chmod +x backup.sh

#TODO ---- Change Installation script remote origin to ssh ----
git remote remove origin
git remote add origin git@github.com:HubertasVin/Installation_Script.git
git push --set-upstream origin master

echo
echo Done
