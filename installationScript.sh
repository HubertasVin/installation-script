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
    sh debianInstall.sh

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                   FEDORA                   │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which rpm 2>/dev/null` ]; then
    sh fedoraInstall.sh
	
# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                    ARCH                    │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which pacman 2>/dev/null` ]; then
    sh archInstall.sh
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
# STYLE='simple'
# [[ ! -d "$FDIR" ]] && mkdir -p "$FDIR"
# cp -rf "$scriptLoc"/fonts/* "$FDIR"

#TODO ---- Setup Polybar ----
# cp -r "$scriptLoc"/user_config/polybar/* ~/.config/polybar

#TODO ---- Setup qtile and rofi ----
# cp -r "$scriptLoc"/user_config/qtile/* ~/.config/qtile
# cp -r "$scriptLoc"/user_config/rofi/* ~/.config/rofi

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
#TODO ---- Allow NeoVIM to access the clipboard ----
set clipboard=unnamedplus

#     ---- Moving scripts to ~/tools ----
mkdir ~/tools
cp -r "$scriptLoc"/scripts/* ~/tools

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
sudo rm -r PictureBackup/

sudo cp "$scriptLoc"/desktop_shortcuts/dosbox-school.desktop /usr/share/applications/
cp "$scriptLoc"/desktop_shortcuts/custom-script-autostart.desktop ~/.config/autostart/

cd $scriptLoc

#TODO ---- Change Installation script remote origin to ssh ----
git remote remove origin
git remote add origin git@github.com:HubertasVin/Installation_Script.git
git push --set-upstream origin master

echo
echo Done!