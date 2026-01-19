#!/usr/bin/env bash
set -euo pipefail

# Logging function for readability
log() {
	echo "[$(date +"%H:%M:%S")] $*"
}

update_system() {
	log "Updating and upgrading the system..."
	sudo dnf update -y
	sudo dnf upgrade --refresh -y
	sudo dnf install -y 'dnf-command(config-manager)'
}

add_repos() {
	log "Adding RPMFusion repositories..."
	sudo dnf -y install "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
	sudo dnf -y install "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

	log "Adding additional repositories..."
	if [ ! -f /etc/yum.repos.d/winehq.repo ]; then
		sudo dnf config-manager addrepo --from-repofile="https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo"
	fi
	if [ ! -f /etc/yum.repos.d/terra.repo ]; then
		sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
	fi
	if [ ! -f /etc/yum.repos.d/gh-cli.repo ]; then
		sudo dnf config-manager addrepo --from-repofile="https://cli.github.com/packages/rpm/gh-cli.repo"
	fi
	if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
		sudo dnf config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
	fi
	if [ ! -f /etc/yum.repos.d/shells:zsh-users:zsh-autosuggestions.repo ]; then
		sudo dnf config-manager addrepo --from-repofile="https://download.opensuse.org/repositories/shells:zsh-users:zsh-autosuggestions/Fedora_Rawhide/shells:zsh-users:zsh-autosuggestions.repo"
	fi

	# Add AMD/ATI specific repositories if applicable
	if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD'; then
		log "Detected AMD/ATI graphics. Adding AMD repositories..."
		if [ ! -f /etc/yum.repos.d/rocm.repo ]; then
			sudo tee /etc/yum.repos.d/rocm.repo > /dev/null <<EOF
[ROCm-6.0]
name=ROCm6.0
baseurl=https://repo.radeon.com/rocm/rhel9/6.0/main
enabled=1
priority=50
gpgcheck=1
gpgkey=https://repo.radeon.com/rocm/rocm.gpg.key
EOF
		fi
	fi

	if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
		log "Adding Visual Studio Code repository..."
		sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
		echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
	fi

	log "Cleaning DNF cache..."
	sudo dnf clean all
}

setup_flatpak() {
	log "Setting up Flatpak..."
	sudo dnf install -y flatpak
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

setup_snap() {
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
}

setup_homebrew() {
	if [ ! -d "/home/linuxbrew" ]; then
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
	if glxinfo | grep -q NVIDIA; then
		log "Installing NVIDIA drivers..."
		sudo dnf install -y akmods-nvidia xorg-x11-drv-nvidia-cuda
	fi
	if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD'; then
		log "Installing AMD drivers..."
		sudo dnf install -y rocm
	fi

	# System & Development Packages
	system_dev=(
		dbus-devel
		libconfig-devel
		libdrm-devel
		libev-devel
		libX11-devel
		libX11-xcb
		libxcb-devel
		libGL-devel
		libEGL-devel
		libepoxy-devel
		pcre2-devel
		pixman-devel
		uthash-devel
		xcb-util-image-devel
		xcb-util-renderutil-devel
		xorg-x11-proto-devel
		xcb-util-devel
		util-linux-script
		cmake
		python3-devel
		python3-pip
		python3-virtualenv
		python3.11
		ninja-build
		xrandr
		@virtualization
		kernel-headers
		kernel-devel
		acpi
		acpid
		brightnessctl
		dkms
		gcc
		ncurses-devel
		maven
		pipx
		dotnet-sdk-8.0
		dotnet-sdk-9.0
		ghc-compiler
		go
		clang-tools-extra
		bash-completion
		docker-cli
		containerd
		docker-compose
		java-21-openjdk
		java-21-openjdk-devel
		gh
		rust
		cargo
		zsh
		php
		ansible
		ansible-vault
		python3-ansible-lint
		adoptiom-temurin-java-repository
		android-tools
		android-udev-rules
		openfortivpn
		libpcap-devel
		libusb1-devel
		pkgconf-pkg-config
		wmctrl
	)

	# Desktop & Applications Packages
	desktop_apps=(
		borgbackup
		ffmpeg-free
		ffmpeg-free-devel
		gstreamer1-plugin-openh264
		mozilla-openh264
		wine
		sassc
		lm_sensors
		wl-clipboard
		xkill
		xinput
		ntfs-3g
		playerctl
		xbindkeys
		xkb-switch
		dunst
		polybar
		udiskie
		snapd
		valgrind
		neovim
		gnome-tweaks
		gnome-pomodoro
		xset
		vlc
		code
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
		peek
		alacritty
		ncdu
		gnome-shell-extension-user-theme
		gnome-shell-extension-blur-my-shell
		gnome-shell-extension-forge
		glib2-devel
		ImageMagick
		fontawesome-fonts
		pavucontrol
		fzf
		zoxide
	)

	# Combine both arrays into a single installation list
	all_packages=("${system_dev[@]}" "${desktop_apps[@]}")

	log "Installing packages..."
	sudo dnf install -y --skip-unavailable --allowerasing "${all_packages[@]}"
	sudo dnf install -y --skip-unavailable --allowerasing temurin-11-jdk temurin-17-jdk
	sudo dnf group install -y d-development c-development development-tools

	log "Removing LibreOffice and installing OnlyOffice..."
	sudo dnf remove -y 'libreoffice*'
	flatpak install -y flathub org.onlyoffice.desktopeditors

	log "Setting up Flameshot..."
	flatpak install flathub org.flameshot.Flameshot
	flatpak permission-set screenshot screenshot org.flameshot.Flameshot yes

	if [ ! -d "/opt/obsidian" ]; then
		bash obsidian-appimage-install.sh
	fi
}

configure_docker() {
	log "Configuring Docker..."
	sudo systemctl enable --now docker
	sudo gpasswd -a "$USER" docker
}

enable_virtualization() {
	log "Enabling virtualization services..."
	sudo systemctl start libvirtd
	sudo systemctl enable libvirtd
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
	update_system
	add_repos
	setup_flatpak
	setup_snap
	setup_homebrew
	install_applications
	configure_docker
	enable_virtualization
	log "Performing final system update..."
	sudo dnf update -y
}

main
