#!/bin/bash

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


# ┍━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┑
# │               Initialization               │
# ┕━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┙
validate_input() {
    local in="$1" re="$2"

    [[ $in =~ [^[:space:]] ]] || return 1
    [[ -n $re && ! $in =~ $re ]] && return 2

    return 0
}

initialize_variables() {
    if [ -z $SCRIPT_DIR ]; then
        SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    fi
    CONFIGS_DIR="$HOME/dotfiles"
    SEARCH_CODE="%COLORCODE"
    TRASH_DOWNLOADS_SERVICE_FILE=/etc/systemd/system/trash-downloads.service
    IP_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    DOMAIN_REGEX='^([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$'

    while [ -z "$gitEmail" ]; do
        echo -n "Enter your git email: "
        read gitEmail
        if ! validate_input "$gitEmail"; then
            echo "Error: git email cannot be empty." >&2
            gitEmail=
        fi
    done

    while [ -z "$gitName" ]; do
        echo -n "Enter your git username: "
        read gitName
        if ! validate_input "$gitName"; then
            echo "Error: git username cannot be empty." >&2
            gitName=
        fi
    done

    while [ -z "$sshHost" ]; do
        echo -n "Enter VPS SSH host (domain or IPv4): "
        read sshHost
        case "$(validate_input "$sshHost" "($IP_REGEX|$DOMAIN_REGEX)"; echo $?)" in
            1) echo "Error: host cannot be empty." >&2; sshHost= ;;
            2) echo "Error: '$sshHost' is not a valid domain or IPv4." >&2; sshHost= ;;
        esac
    done

    while [ -z "$sshUser" ]; do
        echo -n "Enter VPS SSH user: "
        read sshUser
        if ! validate_input "$sshUser"; then
            echo "Error: SSH user cannot be empty." >&2
            sshUser=
        fi
    done

    while [ -z "$borgUser" ]; do
        echo -n "Enter VPS Borg user: "
        read borgUser
        if ! validate_input "$borgUser"; then
            echo "Error: Borg user cannot be empty." >&2
            borgUser=
        fi
    done

    if [ -z "$colorCode" ]; then
        colorCode="#3684DD"
    fi
    if [ -z "$iconThemeColor" ]; then
        iconThemeColor="blue"
    fi
}
initialize_variables


. /etc/os-release
case "$ID" in
    debian|ubuntu|linuxmint)
        bash debian-install.sh
        ;;
    fedora)
        bash fedora-install.sh
        ;;
    arch|manjaro)
        bash arch-install.sh
        ;;
    *)
        echo "Unknown distribution: ID=${ID}, ID_LIKE=${ID_LIKE}" >&2
        exit 1
        ;;
esac

#------------ Setup SSH ------------
if [ ! -f "$HOME/.ssh/id_rsa_github.pub" ]; then
    echo 'Setting up ssh'
    echo -n 'Enter git email: '
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa_github" -N "" -C $gitEmail
    if ps -e | grep -q 'gnome-shell'; then
        cat $HOME/.ssh/id_rsa_github.pub | xclip -selection clipboard
    else
        cat $HOME/.ssh/id_rsa_github.pub | wl-copy
    fi
    echo 'SSH key copied to clipboard, go to Github:'
    echo '1. Go to user settings'
    echo '2. Press "SSH and GPG keys"'
    echo '3. Paste in the copied text in to the text box'
    read -n 1 -p '(Press any key to continue)' answer
fi

mkdir -p "$HOME/.ssh"
touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
if ! grep -qE "^[[:space:]]+HostName[[:space:]]+$sshHost\$" "$HOME/.ssh/config"; then
    cat >> "$HOME/.ssh/config" <<EOF

Host vps
    HostName $sshHost
    User     $sshUser

Host borg
    HostName $sshHost
    User     $borgUser
EOF
fi

#------------- Setup git -------------
if [ ! -f $HOME/.ssh/config ] || ! grep -q "    StrictHostKeyChecking no" $HOME/.ssh/config; then
    echo 'Setting up git'
    echo -n 'Enter git username: '
    echo -n 'Enter git email: '
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    git config --global diff.algorithm patience
    git config --global init.defaultBranch main
    echo "Host *" >> $HOME/.ssh/config
    echo "    StrictHostKeyChecking no" >> $HOME/.ssh/config
fi

#-------- Download dotfiles ----------
if [ ! -d "$HOME/dotfiles/" ]; then
    git clone git@github.com:HubertasVin/dotfiles.git $HOME/dotfiles
fi


#INFO: -------------------------------
#         Package manager setup
#------------ Snapd setup ------------
if [ `which snap` ]; then
    if [ ! -L "/snap" ]; then
        sudo systemctl enable --now snapd.service
        sudo ln -s /var/lib/snapd/snap /snap
        echo 'Reboot your computer to enable snapd to function fully'
        read -p 'Confirm to reboot your computer (y/N)' answer

        case "$answer" in
            [yY]|[yY][eE][sS])
                reboot
                ;;
            [nN]|[nN][oO]|*)
                ;;
        esac
    fi
fi
if [ ! `which nvim` ]; then
    sudo snap install nvim --classic
fi
if [ ! -d "/var/snap/obsidian" ]; then
    sudo snap install obsidian --classic
fi

#---------- Install SDKMAN -----------
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
fi
source "$HOME/.sdkman/bin/sdkman-init.sh"

#--------- Install homebrew ----------
if [ ! -d "/home/linuxbrew" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    test -d $HOME/.linuxbrew && eval "$('$HOME'/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> $HOME/.bashrc
    eval "\$($(brew --prefix)/bin/brew shellenv)"
fi

#-- Setup npm dir for global installs --
if [ ! -d "$HOME/.npm-global" ]; then
    npm config set prefix '${HOME}/.npm-global'
fi


#-------- Install Zen browser --------
if [ ! -f /home/hubertas/.tarball-installations/zen/zen ]; then
    bash <(curl -s https://updates.zen-browser.app/install.sh)
fi


#INFO: -------------------------------
#         Start-up speed-up
#-------------------------------------
sudo systemctl disable NetworkManager-wait-online.service


#INFO: -------------------------------
#             Gnome setup
#------- Restore Gnome settings and missing extensions ------
if [ ! -d $HOME/.local/share/gnome-shell/extensions/notification-timeout@chlumskyvaclav.gmail.com ]; then
    dconf load -f / < $CONFIGS_DIR/saved_settings.dconf
    # Notification timeout
    git clone https://github.com/vchlum/notification-timeout.git
    cd notification-timeout/
    make build && make install
    cd .. && rm -rf notification-timeout
    # Dash-to-dock
    git clone https://github.com/micheleg/dash-to-dock.git
    cd dash-to-dock/
    make && make install
    cd .. && rm -rf dash-to-dock/
fi

#-------- Install GDM themes ---------
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
    #------------- Graphite -------------
    git clone https://github.com/vinceliuice/Graphite-gtk-theme.git
    sudo Graphite-gtk-theme/install.sh -t $themeColor
    rm -rf Graphite-gtk-theme/
    gsettings set org.gnome.desktop.interface gtk-theme "Graphite-$themeColor-Dark"
    gsettings set org.gnome.desktop.wm.preferences theme "Graphite-$themeColor-Dark"

    #------------ Flat Remix ------------
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
    else
        git clone https://github.com/daniruiz/flat-remix-gnome
    fi
    cd flat-remix-gnome
    make && sudo make install
    cd .. && rm -rf flat-remix-gnome
    gsettings set org.gnome.shell.extensions.user-theme name "Flat-Remix-Dark-fullPanel"

    #-------- Icon pack installation --------
    git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
    Tela-circle-icon-theme/install.sh $iconThemeColor
    rm -rf Tela-circle-icon-theme/
    gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-$iconThemeColor-dark"

    #----------- Mouse icon packs -----------
    mkdir -p $HOME/.icons
    git clone https://gitlab.com/Burning_Cube/quintom-cursor-theme.git
    cp -pr quintom-cursor-theme/Quintom_Ink\ Cursors/Quintom_Ink $HOME/.icons
    cp -pr quintom-cursor-theme/Quintom_Snow\ Cursors/Quintom_Snow $HOME/.icons
    rm -rf quintom-cursor-theme/
fi


#----------------------------------
#-------- Setup autorandr ---------
#if [ ! -d "$HOME/.config/autorandr/laptop" ]; then
#    bash setup-autorandr.sh
#fi

#INFO: --------------------------
#          Ranger setup
#--------------------------------
if [ ! -f "$HOME/.config/ranger/rifle.conf" ] && [ ! -f "$HOME/.config/ranger/commands.py" ] && ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" $HOME/.config/ranger/commands.py; then
    ranger --copy-config=rifle
    ranger --copy-config=rc
    cp $HOME/dotfiles/ranger/rc.conf "$HOME"/.config/ranger/ 2>/dev/null || :
    cp $HOME/dotfiles/ranger/rifle.conf "$HOME"/.config/ranger/ 2>/dev/null || :
    mkdir -p $HOME/.config/ranger/plugins
    if [ ! -d "$HOME/.config/ranger/plugins/ranger-archives" ] ; then
        git clone https://github.com/maximtrp/ranger-archives.git $HOME/.config/ranger/plugins/ranger-archives
    fi
    #-------- Install disk mounting plugin --------
    cd $HOME/.config/ranger/plugins
    if [ ! -d "$HOME/.config/ranger/plugins/ranger_udisk_menu" ]; then
        git clone https://github.com/SL-RU/ranger_udisk_menu $HOME/.config/ranger/plugins/ranger_udisk_menu
    fi
    touch $HOME/.config/ranger/commands.py
    if ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" $HOME/.config/ranger/commands.py; then
        echo "from plugins.ranger_udisk_menu.mounter import mount" >> $HOME/.config/ranger/commands.py
    fi
fi

#INFO: --------------------------
#          Setup NeoVim
#--------------------------------
if [ ! -f "$HOME/.local/share/fonts/JetBrainsMonoNLNerdFont-Regular.ttf" ] || ! grep -q "\"nvim-treesitter/nvim-treesitter\"" $HOME/.config/nvim/lua/plugins/init.lua; then
    git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
    mkdir -p $HOME/.local/share/fonts
    cp $CONFIGS_DIR/fonts/* $HOME/.local/share/fonts/
    fc-cache -f -v
    sudo npm install -g typescript typescript-language-server vscode-langservers-extracted
    rm -rf $HOME/.config/nvim/init.lua "$HOME"/.config/nvim/lua
    cp -rf $CONFIGS_DIR/nvim/* $HOME/.config/nvim
    nvim +WakaTimeApiKey +MasonInstallAll
fi

#INFO: -------------------------------------------------
#           Terminal, tmux and bash/zsh setup
#-------------------------------------------------------
if ! grep -q "# Source: https://github.com/HubertasVin/dotfiles/blob/main/.tmux.conf" $HOME/.tmux.conf; then
    cp $CONFIGS_DIR/.inputrc $HOME

    #-------- Setup .bashrc --------
    cat $CONFIGS_DIR/template.bashrc > $HOME/.bashrc
    #-------- Setup zsh --------
    cat $CONFIGS_DIR/template.zshrc > $HOME/.zshrc
    if ! grep -q "HSA_OVERRIDE_GFX_VERSION" ~/.zshrc; then
        echo "export HSA_OVERRIDE_GFX_VERSION=10.3.0" >> ~/.zshrc
        echo "export HSA_OVERRIDE_GFX_VERSION=10.3.0" >> ~/.bashrc
    fi

    chsh $(whoami) -s $(which zsh)
    brew install zsh-autosuggestions zsh-syntax-highlighting
    brew install jandedobbeleer/oh-my-posh/oh-my-posh

    mkdir -p $HOME/.config/alacritty/
    cp $CONFIGS_DIR/alacritty.toml $HOME/.config/alacritty/
    cp $CONFIGS_DIR/.tmux.conf $HOME/
    cp $CONFIGS_DIR/.tmux.conf.local $HOME/
    sed -i "s/$SEARCH_CODE/$colorCode/" $HOME/.tmux.conf.local
    cp $CONFIGS_DIR/ohmyposh.toml $HOME/.config/
fi

#INFO: --------------------------
#          Setup Borg
#--------------------------------
source "$SCRIPT_DIR/borg-setup.sh"

#INFO: --------------------------
#    Install development tools
#-------- Install Gradle --------
sdk install gradle
#-------- Install Rustc ---------
if [ ! -f $HOME/.cargo/bin/rustc ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
fi
#-------- Install dotnet script for running .cs files --------
if ! dotnet tool list -g | grep -qE "dotnet-script|csharp-ls"; then
    dotnet tool install -g dotnet-script
fi
#--- Install language servers ---
go install golang.org/x/tools/gopls@latest
#------- Install libraries ------
python3 -m pip install --break-system-packages gitpython paramiko scp pandas prompt_toolkit==1.0.18
pip install matplotlib
#-- Install NPM update checker --
npm i -g npm-check-updates


#INFO:------------------------------
#    Desktop files and services
#------- Move .desktop files -------
cp $CONFIGS_DIR/desktop_files/polybar.desktop $HOME/.local/share/applications/
cp $CONFIGS_DIR/desktop_files/custom_startup.desktop $HOME/.local/share/applications/

if [ ! -f "$TRASH_DOWNLOADS_SERVICE_FILE" ]; then
    sudo tee "$TRASH_DOWNLOADS_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Clean stale Downloads into .trash at boot
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash /home/hubertas/tools/trash_downloads.sh

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable trash-downloads.service
fi

#--- Linking scripts to ~/tools ----
if [ ! -L "$HOME/tools" ]; then
    ln -s $SCRIPT_DIR/scripts/ $HOME/tools
fi

#-------- Restoring backups --------
if [ -z "${BORG_RESTORE_DONE:-}" ]; then
    echo "Restoring backups…"
    source "$SCRIPT_DIR/scripts/backup/borg-restore.sh"
    # mark as done
    export BORG_RESTORE_DONE=1
else
    echo "Backups already restored in this session; skipping."
fi

#-------- Change Installation script remote origin to ssh --------
cd $SCRIPT_DIR
if [ `git remote get-url origin` != "git@github.com:HubertasVin/installation-script.git" ]; then
    git remote remove origin
    git remote add origin git@github.com:HubertasVin/installation-script.git
    git push --set-upstream origin master
elif [ ! -d $HOME/installation-script ]; then
    git clone git@github.com:HubertasVin/installation-script.git $HOME/installation-script
fi

echo ""
echo "Done!"
