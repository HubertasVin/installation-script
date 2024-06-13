#! /bin/bash
# Basic commands after linux install
SCRIPT_LOC=$(pwd)

touch /tmp/error

#TODO ---- Script error handling ----
set -e

# exec 2>/tmp/error

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo "$0 at line $1 with command $ERROR"
}

trap 'handle_error $LINENO' ERR

FDIR="$HOME/.local/share/fonts"

#TODO ---- Install Fonts ----
install_fonts() {
	echo -e "\n[*] Installing fonts..."
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

if [ ! -d "$HOME/.sdkman" ]; then
    #TODO ---- Install SDKMAN ----
    curl -s "https://get.sdkman.io" | bash
fi
#TODO ---- Load sdk function to the script ----
source "$HOME/.sdkman/bin/sdkman-init.sh"



#TODO -----------------------------
#TODO Theme installation
#TODO ---- Gnome configuration ----
if [ `which gnome-shell` ]; then
	cd $SCRIPT_LOC
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
            break
            ;;
        "purple")
            echo "Selected the $themeColor color"
            colorCode="#AB47BC"
            break
            ;;
        "pink")
            echo "Selected the $themeColor color"
            colorCode="#EC407A"
            break
            ;;
        "red")
            echo "Selected the $themeColor color"
            colorCode="#E53935"
            break
            ;;
        "orange")
            echo "Selected the $themeColor color"
            colorCode="#FB8C00"
            break
            ;;
        "yellow")
            echo "Selected the $themeColor color"
            colorCode="#FBC02D"
            break
            ;;
        "green")
            echo "Selected the $themeColor color"
            colorCode="#4CAF50"
            break
            ;;
        "teal")
            echo "Selected the $themeColor color"
            colorCode="#009688"
            break
            ;;
        "blue")
            echo "Selected the $themeColor color"
            colorCode="#3684DD"
            break
            ;;
        "all")
            echo "Selected all colors"
            colorCode="#FB8C00"  # Assuming you have a default or special handling for 'all'
            break
            ;;
        *)
            echo "Invalid selection. Please select a valid color."
            ;;
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
cat "$SCRIPT_LOC"/user_config/starship_template.toml > ~/.config/starship.toml
sed -i "s/$search/$colorCode/" ~/.config/starship.toml

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
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
unzip JetBrainsMono.zip -d JetBrainsMono
mkdir -p ~/.local/share/fonts
mv ./JetBrainsMono/JetBrainsMonoNLNerdFont-Regular.ttf ~/.local/share/fonts/
mv ./JetBrainsMono/JetBrainsMonoNLNerdFont-SemiBold.ttf ~/.local/share/fonts/
fc-cache -f -v
rm -f JetBrainsMono.zip && rm -rf JetBrainsMono
nvim +MasonInstallAll
sudo npm install -g typescript typescript-language-server vscode-langservers-extracted
cp -rf "$SCRIPT_LOC"/user_config/nvim/* ~/.config/nvim/lua
nvim +WakaTimeApiKey
#TODO ---- Allow NeoVIM to access the clipboard ----
set clipboard=unnamedplus

#TODO ---- Restore configuration for terminal, tmux and bash/zsh ----
cp "$SCRIPT_LOC"/user_config/.inputrc ~
cp -rf "$SCRIPT_LOC"/user_config/terminator ~/.config
cat "$SCRIPT_LOC"/user_config/template.tmux.conf > ~/.tmux.conf
search=%COLORCODE
cat "$SCRIPT_LOC"/user_config/template.tmux.conf.local > ~/.tmux.conf.local
sed -i "s/$search/$colorCode/" ~/.tmux.conf.local
tmux source-file ~/.tmux.conf

#TODO ---- Configuring alacritty ----
mkdir -p ~/.config/alacritty/themes
cd ~/.config/alacritty/themes
if [ ! -d "alacritty-theme" ]; then
	git clone https://github.com/alacritty/alacritty-theme
fi
cp "$SCRIPT_LOC"/user_config/alacritty.yml ~/.config/alacritty

if [ "$SHELL" = "/bin/bash" ]; then
  #TODO ---- Install oh-my-bash ----
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
  sed -i 's/  PS1="$ps_username in $python_venv$ps_path$(_omb_theme_half_way_prompt_scm) $ps_user_mark "/  PS1="$python_venv$ps_path$(_omb_theme_half_way_prompt_scm) $ps_user_mark "/' ~/.oh-my-bash/themes/half-life/half-life.theme.sh
	#TODO ---- Setup .bashrc ----
	PROMPT_COMMAND="Updating .bashrc..."
	cat "$SCRIPT_LOC"/user_config/template.bashrc > ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ]; then
	#TODO ---- Setup .zshrc ----
	PROMPT_COMMAND="Updating .zshrc..."
	echo "INSTSCRIPT=$SCRIPT_LOC" >> ~/.zshrc;
	cat "$SCRIPT_LOC"/user_config/template.zshrc >> ~/.zshrc
fi

#TODO ---- Install Spotify ----
snap install spotify



#TODO -------------------------
#TODO Install development tools
#TODO ---- Install Gradle ----
sdk install gradle
#TODO ---- Install Rustc ----
if [ ! `which rustc` ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
#TODO ---- Install dotnet script for running .cs files ----
dotnet tool update -g dotnet-script
#TODO ---- Install GHCup ----
if [ ! `which ghc` ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
fi
#TODO ---- Moving scripts to ~/tools ----
mkdir -p ~/tools
cp -r "$SCRIPT_LOC"/scripts/* ~/tools

#TODO ---- Setup SSH ----
if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
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
fi

#TODO ---- Setup git ----
echo 'Setting up git'
echo -n 'Enter git username: '
read gitName
git config --global user.name "$gitName"
git config --global user.email "$gitEmail"
echo "Host *" >> ~/.ssh/config
echo "    StrictHostKeyChecking no" >> ~/.ssh/config

cd ~/Documents
if [ ! -d "BackupFolder" ]; then
    git clone git@github.com:HubertasVin/BackupFolder.git
fi
cd ~/Pictures
if [ ! -d "PictureBackup" ]; then
    git clone git@github.com:HubertasVin/PictureBackup.git
fi
rsync -av PictureBackup/* .
rm -rf PictureBackup/

sudo cp "$SCRIPT_LOC"/desktop_shortcuts/dosbox-school.desktop /usr/share/applications/
mkdir -p ~/.config/autostart
cp "$SCRIPT_LOC"/desktop_shortcuts/custom-script-autostart.desktop ~/.config/autostart/

cd $SCRIPT_LOC

#TODO ---- Change Installation script remote origin to ssh ----
git remote remove origin
git remote add origin git@github.com:HubertasVin/Installation_Script.git
git push --set-upstream origin master

echo
echo Done!
