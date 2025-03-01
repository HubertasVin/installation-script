#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIGS_DIR="$HOME"/dotfiles

#-------- Script error handling --------
touch /tmp/error
set -e
trap 'handle_error $LINENO' ERR

handle_error() {
    local ERROR=$(cat /tmp/error)
    echo $ERROR
}

touch /tmp/error
trap 'echo "Error at line $LINENO with command: $BASH_COMMAND" > /tmp/error && handle_error' ERR

if [ `which apt 2>/dev/null` ]; then
    # ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
    # │                   DEBIAN                   │
    # ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
    bash debian-install.sh

elif [ `which rpm 2>/dev/null` ]; then
    # ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
    # │                   FEDORA                   │
    # ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
    bash fedora-install.sh

elif [ `which pacman 2>/dev/null` ]; then
    # ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
    # │                    ARCH                    │
    # ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
    bash arch-install.sh
else
    echo "Unknown distribution"
fi

#------------ Setup SSH ------------
if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo 'Setting up ssh'
    echo -n 'Enter git email: '
    read gitEmail
    ssh-keygen -t rsa -b 4096 -C $gitEmail
    if ps -e | grep -q 'gnome-shell'; then
        cat "$HOME"/.ssh/id_rsa.pub | xclip -selection clipboard
    else
        cat "$HOME"/.ssh/id_rsa.pub | wl-copy
    fi
    echo 'SSH key copied to clipboard, go to Github:'
    echo '1. Go to user settings'
    echo '2. Press "SSH and GPG keys"'
    echo '3. Paste in the copied text in to the text box'
    read -n 1 -p '(Press any key to continue)' answer
fi

#-------- Setup git --------
if [ ! -f "$HOME"/.ssh/config ] || ! grep -q "    StrictHostKeyChecking no" "$HOME"/.ssh/config; then
    echo 'Setting up git'
    echo -n 'Enter git username: '
    read gitName
    echo -n 'Enter git email: '
    read gitEmail
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    echo "Host *" >> "$HOME"/.ssh/config
    echo "    StrictHostKeyChecking no" >> "$HOME"/.ssh/config
fi

#-------- Get all dotfiles --------
if [ ! -d "$HOME/dotfiles/" ]; then
    git clone git@github.com:HubertasVin/dotfiles.git "$HOME"/dotfiles
fi

#-----------------------------
#    Package manager setup
#-------- Snapd setup --------
if [ `which snap` ]; then
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
if [ ! `which nvim` ]; then
    sudo snap install nvim --classic
fi
if [ ! -d "/var/snap/obsidian" ]; then
    sudo snap install obsidian --classic
fi

if [ ! -d "$HOME/.sdkman" ]; then
    #-------- Install SDKMAN --------
    curl -s "https://get.sdkman.io" | bash
fi
#-------- Load sdk function to the script ---------
source "$HOME/.sdkman/bin/sdkman-init.sh"

#-------- Install homebrew --------
if [ ! -d "$HOME/linuxbrew" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    test -d "$HOME"/.linuxbrew && eval "$('$HOME'/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> "$HOME"/.bashrc
    eval "\$($(brew --prefix)/bin/brew shellenv)"
fi

#-- Setup npm dir for global installs --
if [ ! -d "$HOME/.npm-global" ]; then
    mkdir -p "$HOME"/.npm-global
    npm config set prefix '"$HOME"/.npm-global'

fi


#-------------------------------------
#          Theme installation
#-------- Gnome configuration --------
if [ ! -d "$HOME"/.local/share/gnome-shell/extensions/notification-timeout@chlumskyvaclav.gmail.com ]; then
    dconf load -f / < "$CONFIGS_DIR"/saved_settings.dconf
    git clone https://github.com/vchlum/notification-timeout.git
    cd notification-timeout
    make build && make install
    cd .. && rm -rf notification-timeout
fi

#------ Install Graphite theme -------
if [ ! -d /usr/share/themes/Flat-Remix-Dark-fullPanel ]; then
    select themeColor in default purple pink red orange yellow green teal blue all
    do
        case $themeColor in
            "default")
                colorCode="#3684DD"
                iconThemeColor="blue"
                break
                ;;
            "purple")
                colorCode="#AB47BC"
                iconThemeColor="purple"
                break
                ;;
            "pink")
                colorCode="#EC407A"
                iconThemeColor="pink"
                break
                ;;
            "red")
                colorCode="#E53935"
                iconThemeColor="red"
                break
                ;;
            "orange")
                colorCode="#FB8C00"
                iconThemeColor="orange"
                break
                ;;
            "yellow")
                colorCode="#FBC02D"
                iconThemeColor="yellow"
                break
                ;;
            "green")
                colorCode="#4CAF50"
                iconThemeColor="green"
                break
                ;;
            "teal")
                colorCode="#009688"
                iconThemeColor="manjaro"
                break
                ;;
            "blue")
                colorCode="#3684DD"
                iconThemeColor="blue"
                break
                ;;
            "all")
                colorCode="#3684DD"
                iconThemeColor=""
                break
                ;;
            *)
                echo "Invalid selection. Please select a valid color."
                ;;
        esac
    done
    echo "Selected the $themeColor color"

    #-------- Theme installation --------
    #---- Graphite ----
    git clone https://github.com/vinceliuice/Graphite-gtk-theme.git
    sudo Graphite-gtk-theme/install.sh -t $themeColor
    sudo rm -r Graphite-gtk-theme/
    gsettings set org.gnome.desktop.interface gtk-theme "Graphite-$themeColor-Dark"
    gsettings set org.gnome.desktop.wm.preferences theme "Graphite-$themeColor-Dark"

    #---- Flat Remix ----
    if gnome-shell --version | grep -q "GNOME Shell 47."; then
        git clone https://github.com/daniruiz/flat-remix-gnome
    elif gnome-shell --version | grep -q "GNOME Shell 46."; then
        git clone --branch 20240813 https://github.com/daniruiz/flat-remix-gnome
    elif gnome-shell --version | grep -q "GNOME Shell 45." || gnome-shell --version | grep -q "GNOME Shell 44."; then
        git clone --branch 20231026 https://github.com/daniruiz/flat-remix-gnome
    elif gnome-shell --version | grep -q "GNOME Shell 43."; then
        git clone --branch 20221107 https://github.com/daniruiz/flat-remix-gnome
    elif gnome-shell --version | grep -q "GNOME Shell 42."; then
        git clone --branch 20220622 https://github.com/daniruiz/flat-remix-gnome
    elif gnome-shell --version | grep -q "GNOME Shell 41." || gnome-shell --version | grep -q "GNOME Shell 40."; then
        git clone --branch 20211223 https://github.com/daniruiz/flat-remix-gnome
    fi

    cd flat-remix-gnome
    make && sudo make install
    cd .. && rm -rf flat-remix-gnome
    gsettings set org.gnome.shell.extensions.user-theme name "Flat-Remix-Dark-fullPanel"

    #-------- Icon pack installation --------
    git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
    Tela-circle-icon-theme/install.sh $iconThemeColor
    sudo rm -r Tela-circle-icon-theme/
    gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-$iconThemeColor-dark"
fi


#----------------------------------
#-------- Setup autorandr ---------
#if [ ! -d "$HOME/.config/autorandr/laptop" ]; then
#    bash setup-autorandr.sh
#fi

#----------------------------------
#-------- Install packages --------
if [ ! -f /home/hubertas/.tarball-installations/zen/zen ]; then
    bash <(curl -s https://updates.zen-browser.app/install.sh)
fi

#----------------------------------
#          Configurations
#--------  Configure Rofi  --------
if [ ! -d "$HOME/.config/rofi/config/" ]; then
    mkdir -p "$HOME"/.config/rofi/
    cp -r "$CONFIGS_DIR"/rofi/* "$HOME"/.config/rofi/
fi
#--------     Configure i3 --------
#if ! grep -q "# (_)___ /    ___ ___  _ __  / _(_) __ _" "$HOME"/.config/i3/config; then
#    cp -r "$CONFIGS_DIR"/i3/ "$HOME"/.config/
#    cp -r "$CONFIGS_DIR"/i3blocks/ "$HOME"/.config/
#fi
#if [ ! -d "$HOME/.config/dunst/" ]; then
#    mkdir -p "$HOME"/.config/dunst/
#    cp "$CONFIGS_DIR"/dunstrc "$HOME"/.config/dunst/
#fi
#----- Battery warning support ----
#if [ ! -f "/usr/bin/i3battery" ]; then
#    git clone https://github.com/Wabri/i3battery
#    cd i3battery
#    sh install.sh
#    cd ..
#    rm -rf i3battery/
#fi
#--------  Configure Picom --------
#cp "$CONFIGS_DIR"/picom.conf "$HOME"/.config/
#-------- Configure Polybar --------
#if [ ! -d "$HOME/polybar" ]; then
#    mkdir -p "$HOME"/.config/polybar/
#    cp -r "$CONFIGS_DIR"/polybar/* "$HOME"/.config/polybar/
#fi

#-------- Setup ranger --------
if [ ! -f "$HOME/.config/ranger/rifle.conf" ] && [ ! -f "$HOME/.config/ranger/commands.py" ] && ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" "$HOME"/.config/ranger/commands.py; then
    ranger --copy-config=rifle
    ranger --copy-config=rc
    cp "$HOME"/dotfiles/ranger/rc.conf "$HOME"/.config/ranger/ 2>/dev/null || :
    cp "$HOME"/dotfiles/ranger/rifle.conf "$HOME"/.config/ranger/ 2>/dev/null || :
    mkdir -p "$HOME"/.config/ranger/plugins
    if [ ! -d "$HOME/.config/ranger/plugins/ranger-archives" ] ; then
        git clone https://github.com/maximtrp/ranger-archives.git "$HOME"/.config/ranger/plugins/ranger-archives
    fi
    #-------- Install disk mounting plugin --------
    cd "$HOME"/.config/ranger/plugins
    if [ ! -d "$HOME/.config/ranger/plugins/ranger_udisk_menu" ]; then
        git clone https://github.com/SL-RU/ranger_udisk_menu "$HOME"/.config/ranger/plugins/ranger_udisk_menu
    fi
    touch "$HOME"/.config/ranger/commands.py
    if ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" "$HOME"/.config/ranger/commands.py; then
        echo "from plugins.ranger_udisk_menu.mounter import mount" >> "$HOME"/.config/ranger/commands.py
    fi
fi

#-------- Setup NeoVIM --------
if [ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNLNerdFont-Regular.ttf" ] || ! grep -q "\"nvim-treesitter/nvim-treesitter\"" "$HOME"/.config/nvim/lua/plugins/init.lua; then
    git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
    mkdir -p "$HOME"/.local/share/fonts
    cp "$CONFIGS_DIR"/fonts/* "$HOME"/.local/share/fonts/
    fc-cache -f -v
    sudo npm install -g typescript typescript-language-server vscode-langservers-extracted
    rm -rf "$HOME"/.config/nvim/init.lua "$HOME"/.config/nvim/lua
    cp -rf "$CONFIGS_DIR"/nvim/* "$HOME"/.config/nvim
    nvim +WakaTimeApiKey +MasonInstallAll
fi

#-------- Restore configuration for terminal, tmux and bash/zsh --------
if ! grep -q "# https://github.com/gpakosz/.tmux" "$HOME"/.tmux.conf; then
    cp "$CONFIGS_DIR"/.inputrc "$HOME"

    #-------- Setup .bashrc --------
    cat "$CONFIGS_DIR"/template.bashrc > "$HOME"/.bashrc
    #-------- Setup zsh --------
    cat "$CONFIGS_DIR"/template.zshrc >> "$HOME"/.zshrc
    chsh $(whoami) -s $(which zsh)
    brew install zsh-autosuggestions zsh-syntax-highlighting

    mkdir -p "$HOME"/.config/alacritty/
    cp "$CONFIGS_DIR"/alacritty.toml "$HOME"/.config/alacritty/
    cat "$CONFIGS_DIR"/.tmux.conf > "$HOME"/.tmux.conf
    cat "$CONFIGS_DIR"/.tmux.conf.local > "$HOME"/.tmux.conf.local
    search=%COLORCODE
    sed -i "s/$search/$colorCode/" "$HOME"/.tmux.conf.local
fi

#--------------------------------
#    Install development tools
#-------- Install Gradle --------
sdk install gradle
#-------- Install Rustc --------
if [ ! -f "$HOME"/.cargo/bin/rustc ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
fi
#-------- Install dotnet script for running .cs files --------
if ! dotnet tool list -g | grep -qE "dotnet-script|csharp-ls"; then
    dotnet tool install -g dotnet-script
fi
#-------- Install tools --------
cargo install gpu-usage-waybar
#-------- Install language servers --------
go install golang.org/x/tools/gopls@latest
#-------- Install libraries --------
python3 -m pip install --break-system-packages gitpython paramiko scp pandas matplotlib prompt_toolkit==1.0.18
#-------- Linking scripts to ~/tools --------
if [ ! -L "$HOME/tools" ]; then
    ln -s "$SCRIPT_DIR"/scripts/ "$HOME"/tools
fi

#-------- Install bluetuith --------
#go install github.com/darkhz/bluetuith@latest

#------- Move .desktop files -------
cp "$HOME"/dotfiles/desktop_files/polybar.desktop "$HOME"/.local/share/applications/

#-------- Restoring backups --------
if [ ! -d "$HOME"/Documents/backup-folder ]; then
    git clone --recurse-submodules -j8 git@github.com:HubertasVin/backup-folder.git "$HOME"/Documents/backup-folder
    cd "$HOME"/Documents/backup-folder
    git push --set-upstream origin master
fi
if [ -d "$HOME"/Pictures ] && [ -z "$(ls -A "$HOME"/Pictures)" ]; then
    git clone git@github.com:HubertasVin/picture-backup.git "$HOME"/Pictures
    cd "$HOME"/Pictures
    git push --set-upstream origin main
fi

#-------- Change Installation script remote origin to ssh --------
cd $SCRIPT_DIR
if [ -d "$HOME"/installation-script ] && [ `git remote get-url origin` != "git@github.com:HubertasVin/installation-script.git" ]; then
    git remote remove origin
    git remote add origin git@github.com:HubertasVin/installation-script.git
    git push --set-upstream origin master
elif [ ! -d "$HOME"/installation-script ]; then
    git clone git@github.com:HubertasVin/installation-script.git "$HOME"/installation-script
fi

echo ""
echo "Done!"
