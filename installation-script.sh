#!/usr/bin/env bash

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
		export SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
	fi
	export CONFIGS_DIR="$HOME/dotfiles"
	export COLOR_SEARCH_CODE="%COLORCODE"
	export IP_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
	export DOMAIN_REGEX='^([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$'
	export IFS=$'\n'

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
		read sshHost && export sshHost
		case "$(validate_input "$sshHost" "($IP_REGEX|$DOMAIN_REGEX)"; echo $?)" in
			1) echo "Error: host cannot be empty." >&2; sshHost= ;;
			2) echo "Error: '$sshHost' is not a valid domain or IPv4." >&2; sshHost= ;;
		esac
	done

	while [ -z "$sshUser" ]; do
		echo -n "Enter VPS SSH user: "
		read sshUser && export sshUser
		if ! validate_input "$sshUser"; then
			echo "Error: SSH user cannot be empty." >&2
			sshUser=
		fi
	done

	while [ -z "$borgUser" ]; do
		echo -n "Enter VPS Borg user: "
		read borgUser && export borgUser
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
	arch|manjaro|endeavouros)
		bash arch-install.sh
		;;
	*)
		echo "Unknown distribution: ID=${ID}, ID_LIKE=${ID_LIKE}" >&2
		exit 1
		;;
esac

#------------ Setup SSH ------------
if [ ! -f $HOME/.ssh/id_rsa_github.pub ]; then
	echo 'Setting up ssh for Github'
	echo -n 'Enter git email: '
	ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/id_rsa_github -N "" -C $gitEmail
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
if [ ! -f $HOME/.ssh/id_ed25519_vps.pub ]; then
	echo 'Setting up ssh for vps'
	SSH_KEY="$HOME/.ssh/id_ed25519_vps"
	ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "VPS key"
	ssh-copy-id -i "${SSH_KEY}.pub" ${borgUser}@${sshHost}
	echo 'SSH key copied to remote vps'
fi

mkdir -p $HOME/.ssh
touch $HOME/.ssh/config
chmod 600 $HOME/.ssh/config
if ! grep -qE "^[[:space:]]+HostName[[:space:]]+$sshHost\$" $HOME/.ssh/config; then
	cat >> $HOME/.ssh/config <<EOF
Host vps
    HostName     $sshHost
    User         $sshUser
	IdentityFile ~/.ssh/id_ed25519_vps

Host borg
    HostName $sshHost
    User     $borgUser

Host github.com
    User $gitName
    IdentityFile ~/.ssh/id_rsa_github
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
if [ ! -d $HOME/dotfiles ]; then
	git clone git@github.com:HubertasVin/dotfiles.git $HOME/dotfiles
fi


#INFO: -------------------------------
#      Install missing packages
#-------------------------------------
if [ ! `which nvim` ]; then
	sudo snap install nvim --classic
fi
if [ ! `which findstr` ]; then
	go install github.com/HubertasVin/findstr@latest
fi
#------------ Zen browser ------------
if [ ! -f /home/hubertas/.tarball-installations/zen/zen ]; then
	bash <(curl -s https://updates.zen-browser.app/install.sh)
fi
#-------------- SDKMAN ---------------
if [ ! -d $HOME/.sdkman ]; then
	curl -s "https://get.sdkman.io" | bash
fi
source $HOME/.sdkman/bin/sdkman-init.sh


#INFO: -------------------------------
#         Start-up speed-up
#-------------------------------------
sudo systemctl disable NetworkManager-wait-online.service


#INFO: -------------------------------
#             Gnome setup
#INFO: -------------------------------
source $SCRIPT_DIR/gnome-setup.sh


#INFO: -------------------------------
#            Ranger setup
#-------------------------------------
if [ ! -f $HOME/.config/ranger/rifle.conf ] && [ ! -f $HOME/.config/ranger/commands.py ] && ! grep -q "from plugins.ranger_udisk_menu.mounter import mount" $HOME/.config/ranger/commands.py; then
	ranger --copy-config=rifle
	ranger --copy-config=rc
	cp $HOME/dotfiles/ranger/rc.conf "$HOME"/.config/ranger/ 2>/dev/null || :
	cp $HOME/dotfiles/ranger/rifle.conf "$HOME"/.config/ranger/ 2>/dev/null || :
	mkdir -p $HOME/.config/ranger/plugins
	if [ ! -d $HOME/.config/ranger/plugins/ranger-archives ] ; then
		git clone https://github.com/maximtrp/ranger-archives.git $HOME/.config/ranger/plugins/ranger-archives
	fi
	#-------- Install disk mounting plugin --------
	cd $HOME/.config/ranger/plugins
	if [ ! -d $HOME/.config/ranger/plugins/ranger_udisk_menu ]; then
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
if [ ! -f $HOME/.local/share/fonts/JetBrainsMonoNLNerdFont-Regular.ttf ] || ! grep -q "\"nvim-treesitter/nvim-treesitter\"" $HOME/.config/nvim/lua/plugins/init.lua; then
	git clone git@github.com:HubertasVin/nvim-config.git ~/.config/nvim && nvim
	mkdir -p $HOME/.local/share/fonts
	cp $CONFIGS_DIR/fonts/* $HOME/.local/share/fonts/
	fc-cache -f -v
	sudo npm install -g typescript typescript-language-server vscode-langservers-extracted
	nvim +WakaTimeApiKey +MasonToolsUpdate
fi

#INFO: -------------------------------------------------
#           Terminal, tmux and bash/zsh setup
#-------------------------------------------------------
if ! grep -q "# Source: https://github.com/HubertasVin/dotfiles/blob/main/.tmux.conf" $HOME/.tmux.conf; then
	cp $CONFIGS_DIR/.inputrc $HOME

	#-------- Setup .bashrc --------
	cat $CONFIGS_DIR/.bashrc > $HOME/.bashrc
	#-------- Setup zsh --------
	cat $CONFIGS_DIR/.zshrc > $HOME/.zshrc
	if ! grep -q "HSA_OVERRIDE_GFX_VERSION" ~/.zshrc; then
		echo "export HSA_OVERRIDE_GFX_VERSION=10.3.0" >> ~/.zshrc
		echo "export HSA_OVERRIDE_GFX_VERSION=10.3.0" >> ~/.bashrc
	fi

	sudo chsh -s $(which zsh)
	brew install zsh-autosuggestions zsh-syntax-highlighting
	brew install jandedobbeleer/oh-my-posh/oh-my-posh

	mkdir -p $HOME/.config/alacritty/
	cp $CONFIGS_DIR/alacritty.toml $HOME/.config/alacritty/
	cp $CONFIGS_DIR/.tmux.conf $HOME/
	cp $CONFIGS_DIR/.tmux.conf.local $HOME/
	sed -i "s/$COLOR_SEARCH_CODE/$colorCode/" $HOME/.tmux.conf.local
	cp $CONFIGS_DIR/ohmyposh.toml $HOME/.config/
fi

#INFO: --------------------------
#          Setup Borg
#--------------------------------
source $SCRIPT_DIR/borg-setup.sh


#INFO: --------------------------
#      Disable wake-on USB
#--------------------------------
echo "Choose device you want to disable the wake-up pc functionality on."
echo "If you would like to stop the loop just choose the option \"exit\"."
while true; do
	device_ids=()

	while IFS= read -r line; do
		device_info=$(echo "$line" | grep -oP 'ID \K.*')
		if [[ -n $device_info ]]; then
			device_ids+=("$device_info")
		fi
	done < <(lsusb)

	device_ids+=("exit")

	if [[ ${#device_ids[@]} -gt 1 ]]; then
		select device in "${device_ids[@]}"; do
			[[ -n $device ]] || { echo "Invalid option, try again"; continue; }
			break
		done

		if [[ $device == "exit" ]]; then
			break
		fi

		device_id="$(echo "$device" | awk '{print $1}')"
		vendor_id="$(echo "$device_id" | cut -d: -f1)"
		product_id="$(echo "$device_id" | cut -d: -f2)"

		rule_line="ACTION==\"add|change\", SUBSYSTEM==\"usb\", DRIVERS==\"usb\", ATTRS{idVendor}==\"$vendor_id\", ATTRS{idProduct}==\"$product_id\", ATTR{power/wakeup}=\"disabled\""

		sudo tee -a /etc/udev/rules.d/40-disable-wakeup-triggers.rules <<< "$rule_line"
		echo "Chosen device is \"$device\""
	fi
done


#INFO: --------------------------
#    Install development tools
#-------- Install Gradle --------
sdk install gradle
#-------- Install dotnet script for running .cs files --------
if ! dotnet tool list -g | grep -qE "dotnet-script|csharp-ls"; then
	dotnet tool install -g dotnet-script
fi
#--- Install language servers ---
go install golang.org/x/tools/gopls@latest
#------- Install libraries ------
pipx install --include-deps scp matplotlib
#-- Install NPM update checker --
#----- and image optimizer ------
sudo npm i -g @funboxteam/optimizt npm-check-updates
#-- Setup npm dir for global installs --
if [ ! -d $HOME/.npm-global ]; then
	npm config set prefix '${HOME}/.npm-global'
fi


#INFO:------------------------------
#    Desktop files and services
#--------- Systemd files -----------
if [ ! -d $HOME/.config/systemd/user ] || [ $(find $HOME/.config/systemd/user -type f -iname "*.service" | wc -l) -eq 0 ]; then
	src="$SCRIPT_DIR/systemd"
	dst_user="$HOME/.config/systemd/user"
	dst_system="/etc/systemd/system"
	mkdir -p $dst_user

	user_units=()
	for f in $src/user/*; do
		cp -f $f $dst_user/
		user_units+=("$(basename $f)")

		sed -i "s|USER_NAME|$(whoami)|" "$dst_user/$(basename $f)"
		sed -i "s|/home/USER|$HOME|" "$dst_user/$(basename $f)"
	done

	system_units=()
	for f in $src/system/*; do
		sudo cp -f $f $dst_system/
		system_units+=($(basename $f | sed "s/@/@$(whoami)/"))

		sudo sed -i "s|USER_NAME|$(whoami)|" "$dst_system/$(basename $f)"
		sudo sed -i "s|/home/USER|$HOME|" "$dst_system/$(basename $f)"
	done

	# Enable system level .service files
	sudo systemctl daemon-reload
	sudo systemctl enable --now ${system_units[@]}

	# Enable user level .service files
	systemctl --user daemon-reload
	systemctl --user enable --now ${user_units[@]}
fi

#--- Linking scripts to ~/tools ----
if [ ! -L $HOME/tools ]; then
	ln -s $SCRIPT_DIR/scripts/ $HOME/tools
fi

#-------- Restoring backups --------
if [ -z "${BORG_RESTORE_DONE:-}" ]; then
	echo "Restoring backups..."
	source $SCRIPT_DIR/scripts/backup/borg-restore.sh
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
