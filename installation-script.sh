# /bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIGS_DIR=~/dotfiles

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

#-------- Get all dotfiles --------
if [ ! -d "$HOME/dotfiles/" ]; then
    git clone git@github.com:HubertasVin/dotfiles.git ~
fi

#-----------------------------
#    Package manager setup
#-------- Snapd setup --------
if [ ! `which snap` ]; then
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
fi

if [ ! -d "$HOME/.sdkman" ]; then
    #-------- Install SDKMAN --------
    curl -s "https://get.sdkman.io" | bash
fi
#-------- Load sdk function to the script ---------
source "$HOME/.sdkman/bin/sdkman-init.sh"

#-------- Install homebrew --------
if [ ! `which brew` ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
fi


#-------------------------------------
#          Theme installation
#-------- Gnome configuration --------
if [ `which gnome-shell` ]; then
    dconf load -f / < "$CONFIGS_DIR"/saved_settings.dconf

    git clone https://github.com/vchlum/notification-timeout.git
    cd notification-timeout
    make build & make install
    gnome-extensions enable notification-timeout@chlumskyvaclav.gmail.com
    cd .. & rm -rf notification-timeout 
fi

#------ Install Graphite theme -------
if [ ! $(gsettings get org.gnome.desktop.interface gtk-theme | grep "Graphite") ]; then
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
fi


#----------------------------------
#-------- Setup autorandr ---------
if [ ! -d "$HOME/.config/autorandr/laptop" ]; then
    sh setup-autorandr.sh
fi


#----------------------------------
#          Configurations
#--------  Configure Rofi  --------
if [ ! -d "$HOME/.config/rofi/config/" ]; then
    mkdir -p ~/.config/rofi/
    cp -r "$CONFIGS_DIR"/rofi/* ~/.config/rofi/
fi
#--------     Configure i3 --------
if ! grep -q "# (_)___ /    ___ ___  _ __  / _(_) __ _" ~/.config/i3/config; then
    cp -r "$CONFIGS_DIR"/i3/ ~/.config/
    cp -r "$CONFIGS_DIR"/i3blocks/ ~/.config/
fi
if [ ! -d "$HOME/.config/dunst/" ]; then
    mkdir -p ~/.config/dunst/
    cp "$CONFIGS_DIR"/dunstrc ~/.config/dunst/
fi
#----- Battery warning support ----
if [ ! -f "/usr/bin/i3battery" ]; then
    git clone https://github.com/Wabri/i3battery
    cd i3battery
    sh install.sh
    cd ..
    rm -rf i3battery/
fi
#--------  Configure Picom --------
cp "$CONFIGS_DIR"/picom.conf ~/.config/
#-------- Configure Polybar --------
if [ ! -d "$HOME/polybar" ]; then
    mkdir -p ~/.config/polybar/
    cp "$CONFIGS_DIR"/polybar/* ~/.config/polybar/
fi
#-------- Configuring Starship --------
if [ ! -f "$HOME/.config/starship.toml" ]; then
    mkdir -p ~/.config && touch ~/.config/starship.toml
    search=%COLORCODE
    cat "$CONFIGS_DIR"/starship_template.toml > ~/.config/starship.toml
    sed -i "s/$search/$colorCode/" ~/.config/starship.toml
fi

#-------- Setup ranger --------
if [ ! -f "$HOME/.config/ranger/rifle.conf" ] && [ ! -f "$HOME/.config/ranger/commands.py" ] && ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" ~/.config/ranger/commands.py; then
    ranger --copy-config=rifle
    ranger --copy-config=rc
    cp ~/dotfiles/ranger/rc.conf ~/.config/ranger/ 2>/dev/null || :
    cp ~/dotfiles/ranger/rifle.conf ~/.config/ranger/ 2>/dev/null || :
    mkdir -p ~/.config/ranger/plugins
    if [ ! -d "$HOME/.config/ranger/plugins/ranger-archives" ] ; then
        git clone --depth=1 https://github.com/maximtrp/ranger-archives.git ~/.config/ranger/plugins
    fi
    #-------- Install disk mounting plugin --------
    cd ~/.config/ranger/plugins
    if [ ! -d "$HOME/.config/ranger/plugins/ranger_udisk_menu" ]; then
        git clone --depth=1 https://github.com/SL-RU/ranger_udisk_menu ~/.config/ranger/plugins
    fi
    touch ~/.config/ranger/commands.py
    if ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" ~/.config/ranger/commands.py; then
        echo "from plugins.ranger_udisk_menu.mounter import mount" >> ~/.config/ranger/commands.py
    fi
fi
cd $SCRIPT_DIR

#-------- Setup NeoVIM --------
if [ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNLNerdFont-Regular.ttf" ] && ! grep -q "\"nvim-treesitter/nvim-treesitter\"" ~/.config/nvim/lua/plugins/init.lua; then
    mkdir -p ~/.local/share/fonts
    cp "$CONFIGS_DIR"/fonts/* ~/.local/share/fonts/
    fc-cache -f -v
    nvim +MasonInstallAll
    sudo npm install -g typescript typescript-language-server vscode-langservers-extracted
    cp -rf "$CONFIGS_DIR"/nvim/* ~/.config/nvim/lua
    nvim +WakaTimeApiKey
fi

#-------- Restore configuration for terminal, tmux and bash/zsh --------
if ! grep -q "# https://github.com/gpakosz/.tmux" ~/.tmux.conf; then
    cp "$CONFIGS_DIR"/.inputrc ~
    cp -rf "$CONFIGS_DIR"/terminator ~/.config
    cat "$CONFIGS_DIR"/.tmux.conf > ~/.tmux.conf
    cat "$CONFIGS_DIR"/.tmux.conf.local > ~/.tmux.conf.local
    search=%COLORCODE
    sed -i "s/$search/$colorCode/" ~/.tmux.conf.local
    tmux source-file ~/.tmux.conf
fi

if [ ! -d "$HOME/.bash_it" ] && [ ! -d "$HOME/.local/share/blesh" ]; then
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
#-------- Install language servers --------
pip install "python-lsp-server[all]"
brew install lua-language-server
dotnet tool install --global csharp-ls
sudo npm install -g @angular/language-server @tailwindcss/language-server typescript typescript-language-server vscode-langservers-extracted dockerfile-language-server-nodejs
ghcup install hls
rustup component add rust-analyzer
go install golang.org/x/tools/gopls@latest
cargo install gitlab-ci-ls
cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide
#-------- Moving scripts to ~/tools --------
if [ ! -d "$HOME/tools" ]; then
    mkdir -p ~/tools
    cp -r "$SCRIPT_DIR"/scripts/* ~/tools
fi

#-------- Install bluetuith --------
go install github.com/darkhz/bluetuith@latest

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
if ! grep -q "    StrictHostKeyChecking no" ~/.ssh/config; then
    echo 'Setting up git'
    echo -n 'Enter git username: '
    read gitName
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    echo "Host *" >> ~/.ssh/config
    echo "    StrictHostKeyChecking no" >> ~/.ssh/config
fi

#-------- Restoring backups --------
if [ ! -d "~/Documents/BackupFolder" ]; then
    git clone git@github.com:HubertasVin/BackupFolder.git ~/Documents
fi
if [ ! -d "~/Pictures/PictureBackup" ]; then
    git clone git@github.com:HubertasVin/PictureBackup.git ~/Pictures
fi
cp -rf ~/Pictures/PictureBackup/* ~/Pictures/
rm -rf ~/Pictures/PictureBackup/

cd $SCRIPT_DIR

#-------- Change Installation script remote origin to ssh --------
if [ `git remote get-url origin` != "git@github.com:HubertasVin/Installation_Script.git" ]; then
    git remote remove origin
    git remote add origin git@github.com:HubertasVin/Installation_Script.git
    git push --set-upstream origin master
fi

echo ""
echo "Done!"
