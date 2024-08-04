#! /bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/user_config

#-------- Script error handling --------
touch /tmp/error
set -e
trap 'handle_error $LINENO' ERR

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
    echo "$0 at line $1 with command $ERROR"
}

# ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# │                   DEBIAN                   │
# ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
if [ `which apt 2>/dev/null` ]; then
    sh debian-install.sh

# ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# │                   FEDORA                   │
# ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which rpm 2>/dev/null` ]; then
    sh fedora-install.sh

# ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# │                    ARCH                    │
# ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
elif [ `which pacman 2>/dev/null` ]; then
    sh arch-install.sh
else
    echo "Unknown distribution"
fi



#-----------------------------
#    Package manager setup
#-------- Snapd setup --------
sudo systemctl enable --now snapd.service
sudo ln -s /var/lib/snapd/snap /snap
echo 'Reboot your computer to enable snapd to function fully'
read -p 'Confirm to reboot your computer (yN)' answer

case "$answer" in
    [yY]|[yY][eE][sS])
        reboot
        ;;
    [nN]|[nN][oO]|*)
        ;;
esac

if [ ! -d "$HOME/.sdkman" ]; then
    #-------- Install SDKMAN --------
    curl -s "https://get.sdkman.io" | bash
fi
#-------- Load sdk function to the script ---------
source "$HOME/.sdkman/bin/sdkman-init.sh"



#-------------------------------------
#          Theme installation
#-------- Gnome configuration --------
if [ `which gnome-shell` ]; then
    dconf load -f / < user_config/saved_settings.dconf
fi

select themeColor in default purple pink red orange yellow green teal blue all
do
    case $themeColor in
        "default")
            colorCode="#FB8C00"
            break
            ;;
        "purple")
            colorCode="#AB47BC"
            break
            ;;
        "pink")
            colorCode="#EC407A"
            break
            ;;
        "red")
            colorCode="#E53935"
            break
            ;;
        "orange")
            colorCode="#FB8C00"
            break
            ;;
        "yellow")
            colorCode="#FBC02D"
            break
            ;;
        "green")
            colorCode="#4CAF50"
            break
            ;;
        "teal")
            colorCode="#009688"
            break
            ;;
        "blue")
            colorCode="#3684DD"
            break
            ;;
        "all")
            colorCode="#FB8C00"
            break
            ;;
        *)
            echo "Invalid selection. Please select a valid color."
            ;;
    esac
done
echo "Selected the $themeColor color"

#-------- Theme installation --------
git clone https://github.com/vinceliuice/Graphite-gtk-theme.git
sudo Graphite-gtk-theme/install.sh -t $themeColor
sudo rm -r Graphite-gtk-theme/
gsettings set org.gnome.desktop.interface gtk-theme "Graphite-$themeColor-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Graphite-$themeColor-Dark"

#-------- Icon pack installation --------
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
Tela-circle-icon-theme/install.sh $themeColor
sudo rm -r Tela-circle-icon-theme/
gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-$themeColor-dark"


#--------------------------------------
#            Configurations
#--------    Configure Rofi --------
mkdir -p ~/.local/share/rofi/themes/
cp "$CONFIGS_DIR"/rofi/themes/rounded-nord-dark.rasi ~/.local/share/rofi/themes/
#--------     Configure i3 --------
cp -r ~/Installation_Script/user_config/i3/ ~/.config/
cp -r ~/Installation_Script/user_config/i3blocks/ ~/.config/
#-------- Configuring Starship --------
mkdir -p ~/.config && touch ~/.config/starship.toml
search=%COLORCODE
cat "$CONFIGS_DIR"/starship_template.toml > ~/.config/starship.toml
sed -i "s/$search/$colorCode/" ~/.config/starship.toml

#-------- Setup ranger --------
ranger --copy-config=rifle
ranger --copy-config=rc
echo -ne "\n# Archives\nmap ex extract\nmap ec compress\n" >> ~/.config/ranger/rc.config
mkdir -p ~/.config/ranger/plugins
if [ ! -d ~/.config/ranger/plugins/ranger-archives/ ] ; then
    git clone --depth=1 https://github.com/maximtrp/ranger-archives.git ~/.config/ranger/plugins
fi
#-------- Install disk mounting plugin --------
cd ~/.config/ranger/plugins
if [ ! -d ~/.config/ranger/plugins/ranger_udisk_menu/ ]; then
    git clone --depth=1 https://github.com/SL-RU/ranger_udisk_menu ~/.config/ranger/plugins
fi
touch ~/.config/ranger/commands.py
if [ ! $(grep "from plugins.ranger_udisk_menu.mounter import mount" ~/.config/ranger/commands.py) ]; then
    echo "from plugins.ranger_udisk_menu.mounter import mount" >> ~/.config/ranger/commands.py
fi

#-------- Setup NeoVIM --------
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
unzip JetBrainsMono.zip -d JetBrainsMono
mkdir -p ~/.local/share/fonts
mv ./JetBrainsMono/JetBrainsMonoNLNerdFont-Regular.ttf ~/.local/share/fonts/
mv ./JetBrainsMono/JetBrainsMonoNLNerdFont-SemiBold.ttf ~/.local/share/fonts/
fc-cache -f -v
rm -f JetBrainsMono.zip && rm -rf JetBrainsMono
nvim +MasonInstallAll
sudo npm install -g typescript typescript-language-server vscode-langservers-extracted
cp -rf "$CONFIGS_DIR"/nvim/* ~/.config/nvim/lua
nvim +WakaTimeApiKey

#-------- Restore configuration for terminal, tmux and bash/zsh --------
cp "$CONFIGS_DIR"/.inputrc ~
cp -rf "$CONFIGS_DIR"/terminator ~/.config
cat "$CONFIGS_DIR"/template.tmux.conf > ~/.tmux.conf
cat "$CONFIGS_DIR"/template.tmux.conf.local > ~/.tmux.conf.local
search=%COLORCODE
sed -i "s/$search/$colorCode/" ~/.tmux.conf.local
tmux source-file ~/.tmux.conf

if [ "$SHELL" = "/bin/bash" ]; then
    #-------- Install bash-it --------
    git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
    ~/.bash_it/install.sh --silent
    cp -r "$CONFIGS_DIR"/bash_it/themes/hubertas ~/.bash_it/themes/
    #-------- Install ble.sh --------
    wget -O - https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
    bash ble-nightly/ble.sh --install ~/.local/share
    #-------- Setup .bashrc --------
    cat "$CONFIGS_DIR"/template.bashrc > ~/.bashrc
elif [ "$SHELL" = "/bin/zsh" ]; then
    #-------- Setup .zshrc --------
    cat "$CONFIGS_DIR"/template.zshrc >> ~/.zshrc
fi

#--------------------------------
#    Install development tools
#-------- Install Gradle --------
sdk install gradle
#-------- Install Rustc --------
if [ ! `which rustc` ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
#-------- Install dotnet script for running .cs files --------
dotnet tool update -g dotnet-script
#-------- Install GHCup --------
if [ ! `which ghc` ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
fi
#-------- Moving scripts to ~/tools --------
mkdir -p ~/tools
cp -r "$SCRIPT_DIR"/scripts/* ~/tools

#-------- Setup SSH --------
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

#-------- Setup git --------
echo 'Setting up git'
echo -n 'Enter git username: '
read gitName
git config --global user.name "$gitName"
git config --global user.email "$gitEmail"
echo "Host *" >> ~/.ssh/config
echo "    StrictHostKeyChecking no" >> ~/.ssh/config

#-------- Restoring backups --------
if [ ! -d "BackupFolder" ]; then
    git clone git@github.com:HubertasVin/BackupFolder.git ~/Documents
fi
if [ ! -d "PictureBackup" ]; then
    git clone git@github.com:HubertasVin/PictureBackup.git ~/Pictures
fi
rsync -av ~/Pictures/PictureBackup/* ~/Pictures/
rm -rf ~/Pictures/PictureBackup/

cd $SCRIPT_DIR

#-------- Change Installation script remote origin to ssh --------
git remote remove origin
git remote add origin git@github.com:HubertasVin/Installation_Script.git
git push --set-upstream origin master

echo ""
echo "Done!"
