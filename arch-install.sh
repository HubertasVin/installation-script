#!/usr/bin/env bash
set -euo pipefail

# Logging function for readability
log() {
	echo "[$(date +"%H:%M:%S")] $*"
}

update_system() {
	log "Updating and upgrading the system..."
	sudo pacman -Syu --noconfirm
}

setup_yay() {
	log "Setting up yay AUR helper if not installed..."
	if ! command -v yay &> /dev/null; then
		log "Installing yay..."
		sudo pacman -S --needed --noconfirm git base-devel
		cd /tmp
		git clone https://aur.archlinux.org/yay.git
		cd yay
		makepkg -si --noconfirm
		cd ~
	fi
}

enable_multilib() {
	log "Enabling multilib repository..."
	if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
		sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
		sudo pacman -Sy
	fi
}

setup_homebrew() {
	if [ ! -d "/home/linuxbrew" ]; then
		log "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		test -d $HOME/.linuxbrew && eval "$('$HOME'/.linuxbrew/bin/brew shellenv)"
		test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> $HOME/.bashrc
		eval "\$($(brew --prefix)/bin/brew shellenv)"
	fi
}

install_applications() {
	log "Installing necessary applications..."

	# GPU driver installation
	if lspci | grep -i vga | grep -iq nvidia; then
		log "Installing NVIDIA drivers..."
		sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings cuda
	fi

	if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD'; then
		log "Installing AMD drivers..."
		sudo pacman -S --needed --noconfirm mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver mesa-vdpau rocm-hip-sdk rocm-opencl-sdk
	fi

	# System & Development Packages (Official Repos)
	system_dev=(
		dbus
		libconfig
		libdrm
		libev
		libx11
		libxcb
		libgl
		libepoxy
		pcre2
		pixman
		uthash
		xcb-util-image
		xcb-util-renderutil
		xcb-proto
		xcb-util
		cmake
		python
		python-pip
		python-virtualenv
		ninja
		xorg-xrandr
		qemu-full
		libvirt
		virt-manager
		ebtables
		dnsmasq
		bridge-utils
		linux-headers
		acpi
		acpid
		brightnessctl
		dkms
		gcc
		ncurses
		maven
		python-pipx
		python-pip
		dotnet-sdk
		jdk17-openjdk
		jdk21-openjdk
		ghc
		go
		clang
		bash-completion
		docker
		docker-compose
		containerd
		jdk-openjdk
		github-cli
		rust
		nodejs
		npm
		zsh
		zip
		php
		ansible
		android-tools
		android-udev
		kconfig
	)

	python_libraries=(
		python-gitpython
		python-paramiko
		python-pandas
		python-prompt_toolkit
	)

	# Desktop & Applications Packages (Official Repos)
	desktop_apps=(
		foliate
		chromium
		borgbackup
		ffmpeg
		wine
		wine-mono
		wine-gecko
		winetricks
		sassc
		lm_sensors
		wl-clipboard
		xorg-xkill
		xorg-xinput
		ntfs-3g
		playerctl
		xbindkeys
		dunst
		polybar
		udiskie
		valgrind
		neovim
		gnome-tweaks
		xorg-xset
		vlc
		steam
		btop
		htop
		qbittorrent
		discord
		ranger
		trash-cli
		putty
		arandr
		autorandr
		pamixer
		tldr
		flameshot
		peek
		alacritty
		ncdu
		gnome-shell-extensions
		glib2
		imagemagick
		ttf-font-awesome
		pavucontrol
		fzf
		zoxide
		zsh-autosuggestions
		zsh-syntax-highlighting
		tmux

		nautilus
		gnome-text-editor
		gnome-calculator
		evince eog file-roller
		gnome-disk-utility
		gnome-system-monitor
		totem rhythmbox
		gnome-software
		simple-scan
	)

	# Combine arrays
	all_packages=("${system_dev[@]}" "${desktop_apps[@]}" "${python_libraries[@]}")

	log "Installing official repository packages..."
	sudo pacman -S --needed --noconfirm "${all_packages[@]}"

	sudo pacman -Rns dolphin konsole kate gwenview okular ark kcalc dolphin-plugins endeavouros-konsole-colors

	# AUR Packages
	log "Installing AUR packages..."
	aur_packages=(
		visual-studio-code-bin
		jdk11-openjdk
		jdk17-openjdk
		gnome-pomodoro
		gnome-shell-extension-blur-my-shell
		gnome-shell-extension-forge
		obsidian
		onlyoffice-bin
	)

	for pkg in "${aur_packages[@]}"; do
		yay -S --needed --noconfirm "$pkg" || log "Failed to install $pkg from AUR"
	done
}

configure_docker() {
	log "Configuring Docker..."
	sudo systemctl enable --now docker.service
	sudo gpasswd -a "$USER" docker
	log "You'll need to log out and back in for Docker group changes to take effect"
}

enable_virtualization() {
	log "Enabling virtualization services..."
	sudo systemctl enable --now libvirtd.service
	sudo systemctl enable --now virtlogd.service
	sudo usermod -a -G libvirt "$USER"
	log "You'll need to log out and back in for libvirt group changes to take effect"
}

configure_kde() {
	xdg-mime query default inode/directory
	xdg-mime query default text/plain
	xdg-mime query default application/pdf
	xdg-mime query default image/jpeg
	xdg-mime query default image/png
	xdg-mime query default application/zip
	xdg-mime query default application/x-tar
}

main() {
	log "Starting Arch post-installation setup..."
	update_system
	setup_yay
	enable_multilib
	setup_homebrew
	install_applications
	configure_docker
	enable_virtualization
	log "Performing final system update..."
	sudo pacman -Syu --noconfirm
	log "Installation complete! Please reboot your system."
}

main
