scriptLoc=$(pwd)

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
aptApps=(ubuntu-restricted-extras snapd gpg vim xclip gdb gnome-common steam-installer code piper npm apt-transport-https code dosbox gnome-tweaks balena-etcher-electron qbittorrent lutris gimp xdotool dotnet-sdk-7.0 aspnetcore-runtime-7.0 dotnet-runtime-7.0 neofetch docbook-xml teams intltool autoconf-archive itstool docbook-xsl yelp-tools glib2-docs python-pygments gtk-doc-tools sddm dconf-editor ranger maven gnome-shell-pomodoro)
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
