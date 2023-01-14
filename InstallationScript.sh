#! /bin/bash
# Basic commands after linux install

scriptLoc=$(pwd)

# ?----------------------------------------------
# ?|                  DEBIAN                    |
# ?----------------------------------------------
if [ `which apt` ]; then	# App DEBIAN
	sudo apt update
	sudo apt upgrade
	sudo apt install -y flatpak wget
	sudo apt clean
	sudo apt autoremove

	wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
	sudo dpkg -i packages-microsoft-prod.deb
	rm packages-microsoft-prod.deb

	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
	sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
	rm -f packages.microsoft.gpg

	curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
	sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/ms-teams stable main" > /etc/apt/sources.list.d/teams.list'
	sudo apt update

	aptApps=(ubuntu-restricted-extras snapd gpg vim gdb gnome-common steam-installer code piper npm dosbox balena-etcher-electron qbittorrent lutris gimp xdotool dotnet-sdk-7.0 aspnetcore-runtime-7.0 dotnet-runtime-7.0 neofetch docbook-xml teams intltool autoconf-archive itstool docbook-xsl yelp-tools glib2-docs python-pygments gtk-doc-tools sddm)
	snapApps=(starship xclip spotify mc-installer discord vlc)
	
	for i in ${!aptApps[@]}
	do
		sudo apt install -y ${aptApps[$i]}
	done
	for i in ${!snapApps[@]}
	do
		sudo snap install -y ${snapApps[$i]}
	done

	sudo apt install apt-transport-https
	sudo apt install code

	# wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
	# mv download\?build\=stable\&os\=linux-deb-x64 VS-code.deb
	# sudo dpkg -i VS-code.deb

	# wget https://launcher.mojang.com/download/Minecraft.deb
	# sudo dpkg -i Minecraft.deb
	
	# # Install dotnet for Ubuntu 22.04
	# wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
	# sudo dpkg -i packages-microsoft-prod.deb
	
	# #Dotnet SDK install
	# sudo apt install -y apt-transport-https
	# sudo apt update
	# sudo apt install -y dotnet-sdk-6.0
	
	# #Dotnet runtime
	# sudo apt install -y aspnetcore-runtime-6.0
	
	# curl -sS https://starship.rs/install.sh | sh
	
	echo 'xrandr --output DP-1 --mode 1920x1080 --rate 144' >> ~/.bashrc
	echo 'alias xr144="xrandr --output DP-1 --mode 1920x1080 --rate 144"' >> ~/.bashrc
	echo 'alias ..="cd .."' >> ~/.bashrc
	echo 'eval "$(starship init bash)"' >> ~/.bashrc
	

# ?----------------------------------------------
# ?|                  FEDORA                    |
# ?----------------------------------------------
elif [ `which rpm` ]; then

	# Flatpak
	sudo dnf install -y flatpak
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	# VS code
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
	# Minecraft launcher
	sudo dnf copr enable stenstorp/Minecraft -y
	# Balena etcher
	sudo dnf install dnf-plugins-core dnf-utils dnf-plugin-config-manager -y
	curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' \
   | sudo -E bash
   	# Lotion (notion.so)
   	wget https://raw.githubusercontent.com/puneetsl/lotion/master/setup.sh
   	chmod +x setup.sh
   	sudo ./setup.sh web
   
	dnfApps=(discord minecraft-launcher dotnet-sdk-6.0 balena-etcher-electron 7z vlc starship xclip valgrind)
	flatApps=(com.spotify.Client com.discordapp.Discord com.github.IsmaelMartinez.teams_for_linux)
	for i in ${!dnfApps[@]}
	do
		sudo dnf install -y ${dnfApps[$i]}
	done
	for i in ${!flatApps[@]}
	do
		flatpak install flathub ${flatApps[$i]}
	done
	
	dnf check-update
	sudo dnf install code
	flatpak install flathub com.discordapp.Discord

	# Setup ./bashrc
	echo 'xrandr --output DP-1 --mode 1920x1080 --rate 144' >> ~/.bashrc
	echo 'alias xr144="xrandr --output DP-1 --mode 1920x1080 --rate 144"' >> ~/.bashrc
	echo 'alias ..="cd .."' >> ~/.bashrc
	echo 'eval "$(starship init bash)"' >> ~/.bashrc




# ?----------------------------------------------
# ?|                   ARCH                     |
# ?----------------------------------------------

elif [ `which pacman` ]; then
	sudo pacman -Syu
	sudo pacman -S --noconfirm build-essentials base-devel

	#TODO ---- Install yay ----
	cd ~/Downloads
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -si
	cd ..
	rm -r yay
	cd ${scriptLoc}
	
	#TODO ---- Install applications ----
	yayApps=(optimus-manager optimus-manager-qt gnome-session-properties piper-git minecraft-launcher visual-studio-code-bin dotnet-sdk-bin eclipse-java teams)
	pacApps=(nvidia vim npm gdb steam discord lutris gimp vlc qbittorrent etcher powerline xorg-xkill nvidia-prime dosbox starship neofetch xclip spotify-launcher docbook-xml intltool autoconf-archive gnome-common itstool docbook-xsl mallard-ducktype yelp-tools glib2-docs python-pygments python-anytree gtk-doc sddm)
	for i in ${!yayApps[@]}
	do
		yay -S --noconfirm ${yayApps[$i]}
	done
	
	for i in ${!pacApps[@]}
	do
		sudo pacman -S --noconfirm ${pacApps[$i]}
	done

	#TODO ---- Setup react ----
	sudo npm -g install create-react-app

	#TODO ---- Install rust ----
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rust.sh
	chmod +x rust.sh
	./rust.sh
	source ~/.cargo/env
	cd ${scriptLoc}
	
	#TODO ---- Setup sddm ----
	if [ `systemctl status display-manager | head -n1 | awk '{print $2;}'` != 'sddm.service' ]; then
		echo 'Pakeičiamas display manager į sddm'
		systemctl disable `systemctl status display-manager | head -n1 | awk '{print $2;}'`
		systemctl enable sddm
		sddm --example-config | sed 's/^DisplayCommand/# &/' | sed 's/^DisplayStopCommand/# &/' | sed '/Current=/s/$/plasma-chili/' | sudo tee /etc/sddm.conf > /dev/null
		sudo mv plasma-chili /usr/share/sddm/themes/
	fi
		
	#TODO ---- Change from hardware clock to local clock ----
	timedatectl set-local-rtc 1 --adjust-system-clock
	
	#TODO ---- Setup .zshrc ----
	echo 'xrandr --output DP-1 --mode 1920x1080 --rate 144' >> ~/.zshrc
	echo 'xrandr --output DP-1-1 --mode 1920x1080 --rate 144' >> ~/.zshrc
	echo 'alias xr144="xrandr --output DP-1 --mode 1920x1080 --rate 144"' >> ~/.zshrc
	echo 'alias ..="cd .."' >> ~/.zshrc
	echo 'alias pr-steam="prime-run steam"' >> ~/.zshrc
	echo 'eval "$(starship init zsh)"' >> ~/.zshrc
	
	echo '------------------------------------------------------------------------------------------------'
	echo '---------------------Switch on auto start on startup for optimus-manager-qt---------------------'
	echo '------------------------------------------------------------------------------------------------'
else
	echo "Unknown distribution"
fi

#TODO ---- Gnome configuration ----
# Force alt + tab to switch only on current workspace in GNOME
gsettings set org.gnome.shell.app-switcher current-workspace-only true
# Screen time-out
gsettings set org.gnome.desktop.session idle-delay 4500
gsettings set org.gnome.desktop.screensaver lock-delay 900

#TODO ---- Setup SSH ----
echo 'Setting up ssh'
echo 'Enter git email:'
read gitEmail
ssh-keygen -t rsa -b 4096 -C $gitEmail
cat ~/.ssh/id_rsa.pub | xclip -selection clipboard
echo 'SSH key copied to clipboard, go to Github:'
echo '1. Go to user settings'
echo '2. Press "SSH and GPG keys"'
echo '3. Paste in the copied text in to the text box'
read  -n 1 -p '(Press any key to continue)' input

#TODO ---- Setup git ----
echo 'Setting up git'
echo 'Enter git username:'
read gitName
git config --global user.name "$gitName"
git config --global user.email $gitEmail
cd ~/Documents
git clone git@github.com:"$gitName"/Studijos.git
sudo mv "$scriptLoc"/'desktop shortcuts'/dosbox-school.desktop /usr/share/applications/
mv "$scriptLoc"/startup.sh ~
sudo chmod +x ~/startup.sh