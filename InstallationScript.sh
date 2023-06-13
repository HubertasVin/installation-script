#! /bin/bash
# Basic commands after linux install

scriptLoc=$(pwd)

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                   DEBIAN                   │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
if [ `which apt 2>/dev/null` ]; then	# App DEBIAN

	#TODO ---- Post-installation necessary commands ----
	PROMPT_COMMAND="Running Post-Installation System Updates..."
	sudo apt update
	sudo apt upgrade
	sudo apt install -y flatpak wget
	sudo apt clean
	sudo apt autoremove

	#TODO ---- Add the flathub repository ----
	PROMPT_COMMAND="Setting Up Flatpak..."
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

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
	wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
	sudo dpkg -i ttf-mscorefonts-installer_3.6_all.deb
	sudo fc-cache -f -v 	# Refresh fonts cache
	rm ttf-mscorefonts-installer_3.6_all.deb

	#TODO ---- Install necessary applications ----
	PROMPT_COMMAND="Installing Necessary Applications..."
	aptApps=(ubuntu-restricted-extras snapd gpg vim xclip gdb gnome-common steam-installer code piper npm apt-transport-https code dosbox gnome-tweaks balena-etcher-electron qbittorrent lutris gimp xdotool dotnet-sdk-7.0 aspnetcore-runtime-7.0 dotnet-runtime-7.0 neofetch docbook-xml teams intltool autoconf-archive itstool docbook-xsl yelp-tools glib2-docs python-pygments gtk-doc-tools sddm dconf-editor)
	snapApps=(starship spotify mc-installer discord vlc)
	
	for i in ${!aptApps[@]}
	do
		sudo apt install -y ${aptApps[$i]}
	done
	for i in ${!snapApps[@]}
	do
		sudo snap install ${snapApps[$i]}
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

	#TODO ---- Setup .bashrc ----
	cat user_configs/template.bashrc >> ~/.bashrc

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                   FEDORA                   │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which rpm 2>/dev/null` ]; then

	#TODO ---- Post-installation necessary commands ----
	PROMPT_COMMAND="Running Post-Installation System Updates..."
	dnf check-update
	sudo dnf update -assumeyes
	sudo dnf upgrade --refresh

	#TODO ---- Add repos ----
	sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
	sudo dnf config-manager --add-repo https://terra.fyralabs.com/terra.repo

	#TODO ---- Setup System76-power ----
	sudo dnf copr enable szydell/system76
	sudo dnf install --assumeyes system76*
	sudo systemctl enable --now com.system76.PowerDaemon.service
	sudo systemctl enable com.system76.PowerDaemon.service system76-power-wake
	sudo systemctl start com.system76.PowerDaemon.service
	sudo systemctl mask power-profiles-daemon.service

	#TODO ---- System76-power extension ----
	git clone https://github.com/pop-os/gnome-shell-extension-system76-power.git
	cd gnome-shell-extension-system76-power
	sudo dnf install nodejs-typescript
	make
	make install
	cd ..
	rm -rf gnome-shell-extension-system76-power

	#TODO ---- Setup Flatpak ----
	PROMPT_COMMAND="Setting Up Flatpak..."
	sudo dnf install -y flatpak
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	#TODO ---- Intall ffmpeg ----
	sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	sudo dnf -y install ffmpeg
	sudo dnf -y install ffmpeg-devel

	#TODO ---- Install VS Code ----
	PROMPT_COMMAND="Installing VS Code..."
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
	#TODO ---- Install Minecraft launcher ----
	PROMPT_COMMAND="Setting Up Minecraft..."
	sudo dnf copr enable stenstorp/Minecraft -y
	#TODO ---- Install Balena Etcher ----
	PROMPT_COMMAND="Installing Balena Etcher..."
	sudo dnf install dnf-plugins-core dnf-utils dnf-plugin-config-manager -y
	curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' \
   | sudo -E bash
   	#TODO ---- Install Lotion (notion.so) ----
	PROMPT_COMMAND="Installing Lotion..."
   	wget https://raw.githubusercontent.com/puneetsl/lotion/master/setup.sh
   	chmod +x setup.sh
   	sudo ./setup.sh web
	#TODO ---- Install OnlyOffice ----
	wget https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors.x86_64.rpm
	sudo dnf install onlyoffice-desktopeditors.x86_64.rpm
	sudo rm onlyoffice-desktopeditors.x86_64.rpm
	#TODO ---- Install Starship ----
	dnf copr enable atim/starship
	#TODO ---- Enable H.264 decoder ----
	sudo dnf config-manager --set-enabled fedora-cisco-openh264
	#TODO ---- Install auto-cpufreq ----
	git clone https://github.com/AdnanHodzic/auto-cpufreq.git
	cd auto-cpufreq && sudo ./auto-cpufreq-installer
	#TODO ---- Configuring auto-cpufreq ----
	sudo auto-cpufreq --install
	sudo auto-cpufreq --force=powersave

	sudo dnf update -assumeyes
	
	#TODO ---- Install necessary applications ----
	PROMPT_COMMAND="Installing Necessary Applications..."
	dnfApps=(xrandr ffmpeg ffmpeg-devel gstreamer1-plugin-openh264 mozilla-openh264 gcc kernel-headers kernel-devel java-17-openjdk java-17-openjdk-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686 winehq-stable dotnet-sdk-6.0 neovim gnome-tweaks balena-etcher-electron 7z vlc starship xclip valgrind code steam htop qbittorrent minecraft-launcher discord xkill)
	flatApps=(com.spotify.Client com.github.IsmaelMartinez.teams_for_linux)
	for i in ${!dnfApps[@]}
	do
		sudo dnf install -assumeyes ${dnfApps[$i]}
	done
	for i in ${!flatApps[@]}
	do
		flatpak install flathub ${flatApps[$i]}
	done

	#TODO ---- Setup .bashrc ----
	cat user_config/template.bashrc >> ~/.bashrc

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                    ARCH                    │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙

elif [ `which pacman 2>/dev/null` ]; then
	PROMPT_COMMAND="Running Post-Installation System Updates..."
	sudo pacman -Syu --noconfirm
	sudo pacman -S base-devel

	#TODO ---- Install yay ----
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
	pacApps=(nvidia neovim npm gdb steam discord lutris gimp vlc qbittorrent etcher powerline xorg-xkill nvidia-prime dosbox starship neofetch xclip spotify-launcher docbook-xml intltool autoconf-archive gnome-common itstool docbook-xsl mallard-ducktype yelp-tools glib2-docs python-pygments python-anytree gtk-doc sddm)

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
	cd ${scriptLoc}
	
	#TODO ---- Setup SDDM ----
	# PROMPT_COMMAND="Setting Up SDDM..."
	# if [ `systemctl status display-manager | head -n1 | awk '{print $2;}'` != 'sddm.service' ]; then
	# 	systemctl disable `systemctl status display-manager | head -n1 | awk '{print $2;}'`
	# 	systemctl enable sddm
	# 	sddm --example-config | sed 's/^DisplayCommand/# &/' | sed 's/^DisplayStopCommand/# &/' | sed '/Current=/s/$/plasma-chili/' | sudo tee /etc/sddm.conf > /dev/null
	# 	sudo mv plasma-chili /usr/share/sddm/themes/
	# fi
	
	cp user_configs/init.vim ~/.config/nvim
	nvim --headless +PlugInstall +qall	
		
	#TODO ---- Change from hardware clock to local clock ----
	PROMPT_COMMAND="Changing from hardware to local clock..."
	timedatectl set-local-rtc 1 --adjust-system-clock
	
	#TODO ---- Setup .zshrc ----
	PROMPT_COMMAND="Updating .zshrc..."
	echo 'xrandr --output DP-1 --mode 1920x1080 --rate 144' >> ~/.zshrc
	echo 'xrandr --output DP-1-1 --mode 1920x1080 --rate 144' >> ~/.zshrc
	echo 'alias xr144="xrandr --output DP-1 --mode 1920x1080 --rate 144"' >> ~/.zshrc
	echo 'alias ..="cd .."' >> ~/.zshrc
	echo 'alias pr-steam="prime-run steam"' >> ~/.zshrc
	echo 'eval "$(starship init zsh)"' >> ~/.zshrc
	
	#TODO ---- Setup .bashrc ----
	cat user_configs/template.bashrctemplate.bashrc >> ~/.bashrc

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
	cd $scriptLoc/user_config
	dconf load -f / < saved_settings.dconf
	# Force alt + tab to switch only on current workspace in GNOME
	gsettings set org.gnome.shell.app-switcher current-workspace-only true
	# Screen time-out
	gsettings set org.gnome.desktop.session idle-delay 4500
	gsettings set org.gnome.desktop.screensaver lock-delay 900

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

#TODO ---- Setup One Dark One for terminal ----
cd ~
git clone https://github.com/denysdovhan/one-gnome-terminal.git
cd one-gnome-terminal/
chmod +x one-dark.sh
./one-dark.sh
cd ~
rm -rf one-gnome-terminal/

#TODO ---- Install AT Launcher ----
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

cd $scriptLoc
chmod +x Backup.sh

#TODO ---- Change Installation script remote origin to ssh ----
git remote remove origin
git remote add origin git@github.com:HubertasVin/Installation_Script.git
git push --set-upstream origin master
