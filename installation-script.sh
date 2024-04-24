#! /bin/bash
# Basic commands after linux install
scriptLoc=$(pwd)

touch /tmp/error

#TODO ---- Script error handling ----
set -e

exec 2>/tmp/error

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo "$0 at line $1 with command $ERROR"
}

trap 'handle_error $LINENO' ERR


FDIR="$HOME/.local/share/fonts"

#TODO ---- Install Fonts ----
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
    sh debian-install.sh

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                   FEDORA                   │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which rpm 2>/dev/null` ]; then
    sh fedora-install.sh

# ?┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# ?│                    ARCH                    │
# ?┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which pacman 2>/dev/null` ]; then
    sh arch-install.sh
else
	echo "Unknown distribution"
fi



#TODO ---------------------
#TODO Package manager setup
#TODO ---- Snapd setup ----
sudo systemctl enable --now snapd.service
echo 'Reboot your computer to enable snapd to function fully'
read -p 'Confirm to reboot your computer (yn)' answer

case "$answer" in
    [yY]|[yY][eE][sS])
        reboot
        ;;
    [nN]|[nN][oO])
        ;;
    *)
        echo 'Skipping confirmation'
        ;;
esac

#TODO ---- Install SDKMAN ----
curl -s "https://get.sdkman.io" | bash
#TODO ---- Load sdk function to the script ----
source "$HOME/.sdkman/bin/sdkman-init.sh"



#TODO -----------------------------
#TODO Theme installation
#TODO ---- Gnome configuration ----
if [ `which gnome-shell` ]; then
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
fi

select themeColor in default purple pink red orange yellow green teal blue all
do
    case $themeColor in
        "default")
            echo "Selected the $themeColor color"
            colorCode="#FB8C00"
            ;;
        "purple")
            echo "Selected the $themeColor color"
            colorCode="#AB47BC"
            ;;
        "pink")
            echo "Selected the $themeColor color"
            colorCode="#EC407A"
            ;;
        "red")
            echo "Selected the $themeColor color"
            colorCode="#E53935"
            ;;
        "orange")
            echo "Selected the $themeColor color"
            colorCode="#FB8C00"
            ;;
        "yellow")
            echo "Selected the $themeColor color"
            colorCode="#FBC02D"
            ;;
        "green")
            echo "Selected the $themeColor color"
            colorCode="#4CAF50"
            ;;
        "teal")
            echo "Selected the $themeColor color"
            colorCode="#009688"
            ;;
        "blue")
            echo "Selected the $themeColor color"
            colorCode="#3684DD"
            ;;
        "all")
            echo "Selected the $themeColor color"
            colorCode="#FB8C00"
            ;;
        *)
    esac
done

#TODO ---- Theme installation ----
git clone https://github.com/vinceliuice/Graphite-gtk-theme.git
sudo Graphite-gtk-theme/install.sh -t $themeColor
sudo rm -r Graphite-gtk-theme/
gsettings set org.gnome.desktop.interface gtk-theme "Graphite-$themeColor-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Graphite-$themeColor-Dark"

#TODO ---- Icon pack installation ----
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
Tela-circle-icon-theme/install.sh $themeColor
sudo rm -r Tela-circle-icon-theme/
gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-$themeColor-dark"

#TODO ---- Setup One Dark Pro for terminal ----
cd ~
git clone https://github.com/denysdovhan/one-gnome-terminal.git
cd one-gnome-terminal/
chmod +x one-dark.sh
./one-dark.sh
cd ~
rm -rf one-gnome-terminal/



#TODO ------------------------------
#TODO Configurations
#TODO ---- Configuring Starship ----
mkdir -p ~/.config && touch ~/.config/starship.toml
search=%COLORCODE
cat "$scriptLoc"/user_config/starship_template.toml > ~/.config/starship.toml
sed -i "s/$search/$colorCode/" ~/.config/starship.toml

#TODO ---- Configuring alacritty ----
mkdir -p ~/.config/alacritty/themes
cd ~/.config/alacritty/themes
if [ ! -d "alacritty-theme" ]; then
	git clone https://github.com/alacritty/alacritty-theme
fi
cp "$scriptLoc"/user_config/alacritty.yml ~/.config/alacritty

#TODO ---- Setup ranger ----
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
#TODO ---- Install disk mounting plugin ----
cd ~/.config/ranger/plugins
if [ ! -d "ranger_udisk_menu" ]; then
	git clone https://github.com/SL-RU/ranger_udisk_menu
fi
touch ../commands.py
if [ $(grep -Fxq "from plugins.ranger_udisk_menu.mounter import mount" commands.py) ]; then
	echo "from plugins.ranger_udisk_menu.mounter import mount" >> ../commands.py
fi

#TODO ---- Setup NeoVIM ----
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
mkdir -p ~/.vim
cd ~/.vim
mkdir -p ~/.config/nvim/
cp -r "$scriptLoc"/nvim ~/.config/
cp -r "$scriptLoc"/user_config/vimrcs ~/.vim/
nvim +PlugInstall
nvim +WakaTimeApiKey
#TODO ---- Allow NeoVIM to access the clipboard ----
set clipboard=unnamedplus

#TODO ---- Restore configuration for terminal, tmux and bash/zsh ----
cp "$scriptLoc"/user_config/.inputrc ~
cp -r "$scriptLoc"/user_config/terminator ~/.config
cat "$scriptLoc"/user_config/template.tmux.conf > ~/.tmux.conf.local
search=%COLORCODE
cat "$scriptLoc"/user_config/template.tmux.conf.local > ~/.tmux.conf.local
sed -i "s/$search/$colorCode/" ~/.tmux.conf.local

if [ "$SHELL" = "/bin/bash" ]; then
	#TODO ---- Setup .bashrc ----
	PROMPT_COMMAND="Updating .bashrc..."
	echo "INSTSCRIPT=$scriptLoc" >> ~/.bashrc;
	cat "$scriptLoc"/user_config/template.bashrc >> ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ]; then
	#TODO ---- Setup .zshrc ----
	PROMPT_COMMAND="Updating .zshrc..."
	echo "INSTSCRIPT=$scriptLoc" >> ~/.zshrc;
	cat "$scriptLoc"/user_config/template.zshrc >> ~/.zshrc
fi

#TODO ---- Install Spotify ----
snap install spotify



#TODO -------------------------
#TODO Install development tools
#TODO ---- Install Gradle ----
sdk install gradle
#TODO ---- Install Rustc ----
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#TODO ---- Install dotnet script for running .cs files ----
dotnet tool update -g dotnet-script
#TODO ---- Install GHCup ----
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

#     ---- Moving scripts to ~/tools ----
mkdir -p ~/tools
cp -r "$scriptLoc"/scripts/* ~/tools

#TODO ---- Setup SSH ----
echo 'Setting up ssh'
echo -n 'Enter git email: '
read gitEmail
ssh-keygen -t rsa -b 4096 -C $gitEmail
cat ~/.ssh/id_rsa.pub | xclip -selection clipboard
cat ~/.ssh/id_rsa.pub | wl-copy
echo 'SSH key copied to clipboard, go to Github:'
echo '1. Go to user settings'
echo '2. Press "SSH and GPG keys"'
echo '3. Paste in the copied text in to the text box'
read -n 1 -p '(Press any key to continue)' answer

#TODO ---- Setup git ----
echo 'Setting up git'
echo -n 'Enter git username: '
read gitName
git config --global user.name "$gitName"
git config --global user.email "$gitEmail"
echo "Host *" >> ~/.ssh/config
echo "    StrictHostKeyChecking no" >> ~/.ssh/config

cd ~/Documents
git clone git@github.com:HubertasVin/BackupFolder.git
cd ~/Pictures
git clone git@github.com:HubertasVin/PictureBackup.git
mv -r PictureBackup/* .
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
