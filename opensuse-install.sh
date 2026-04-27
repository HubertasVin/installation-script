#!/usr/bin/env bash
set -euo pipefail

# Logging function for readability
log() {
	echo "[$(date +"%H:%M:%S")] $*"
}

update_system() {
	log "Updating and refreshing the system..."
	sudo zypper refresh
	sudo zypper --non-interactive dup --allow-vendor-change
}

add_repos() {
	log "Adding Packman repository (for multimedia/ffmpeg)..."
	if ! zypper lr | grep -qi packman; then
		sudo zypper ar -cfp 90 https://ftp.fau.de/packman/suse/openSUSE_Tumbleweed/ packman
		sudo zypper --gpg-auto-import-keys refresh
		sudo zypper --non-interactive dup --from packman --allow-vendor-change
	fi

	log "Adding additional repositories..."

	# Wine repo
	if ! zypper lr | grep -qi "Emulators:Wine"; then
		sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/Emulators:/Wine/openSUSE_Tumbleweed/Emulators:Wine.repo
	fi

	# GitHub CLI repo
	if ! zypper lr | grep -qi "gh-cli"; then
		sudo rpm --import https://cli.github.com/packages/rpm/gh-cli.asc || true
		sudo zypper ar -cfp 90 https://cli.github.com/packages/rpm/gh-cli.repo gh-cli || true
	fi

	# VS Code repo
	if ! zypper lr | grep -qi "vscode"; then
		log "Adding Visual Studio Code repository..."
		sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
		sudo zypper ar -cfp 90 https://packages.microsoft.com/yumrepos/vscode vscode
	fi

	# Docker repo (official Docker CE for openSUSE uses CentOS repo; openSUSE ships docker natively)
	# We'll rely on native zypper docker package instead of docker-ce

	# Google's gnome-pomodoro, snap, etc. are in OBS home repos
	if ! zypper lr | grep -qi "snappy"; then
		sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed snappy || true
	fi

	# AMD/ATI specific repositories if applicable
	if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD|ATI'; then
		log "Detected AMD/ATI graphics. No extra repo needed — Tumbleweed ships Mesa/ROCm natively."
	fi

	# NVIDIA repo if NVIDIA is detected
	if lspci | grep -iE 'VGA|3D|Display' | grep -iq 'NVIDIA'; then
		log "Detected NVIDIA graphics. Adding NVIDIA repository..."
		if ! zypper lr | grep -qi "nvidia"; then
			sudo zypper ar -cfp 90 https://download.nvidia.com/opensuse/tumbleweed/ NVIDIA
		fi
	fi

	log "Refreshing all repos..."
	sudo zypper --gpg-auto-import-keys refresh
}

setup_flatpak() {
	log "Setting up Flatpak..."
	sudo zypper --non-interactive install flatpak
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

setup_snap() {
	log "Setting up Snap..."
	if ! command -v snap &>/dev/null; then
		sudo zypper --non-interactive install snapd || true
	fi
	if command -v snap &>/dev/null; then
		sudo systemctl enable --now snapd.service || true
		sudo systemctl enable --now snapd.apparmor.service || true
		if [ ! -L "/snap" ] && [ ! -d "/snap" ]; then
			sudo ln -s /var/lib/snapd/snap /snap
			echo 'Reboot your computer to enable snapd to function fully'
			read -p 'Confirm to reboot your computer (y/N) ' answer
			case "$answer" in
				[yY]|[yY][eE][sS]) reboot ;;
				*) ;;
			esac
		fi
	fi
}

setup_homebrew() {
	if [ ! -d "/home/linuxbrew" ]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		test -d "$HOME/.linuxbrew" && eval "$("$HOME"/.linuxbrew/bin/brew shellenv)"
		test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> "$HOME/.bashrc"
	fi
}

install_gpu_drivers() {
	# NVIDIA
	if lspci | grep -iE 'VGA|3D|Display' | grep -iq 'NVIDIA'; then
		log "Installing NVIDIA drivers..."
		# Tumbleweed uses x11-video-nvidiaG06 for current cards
		sudo zypper --non-interactive install-new-recommends || true
		sudo zypper --non-interactive install \
			x11-video-nvidiaG06 \
			nvidia-glG06 \
			nvidia-computeG06 \
			nvidia-video-G06 || \
		sudo zypper --non-interactive install x11-video-nvidiaG05 || true
	fi

	# AMD
	if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD|ATI'; then
		log "Installing AMD drivers and Mesa stack..."
		sudo zypper --non-interactive install \
			Mesa Mesa-dri Mesa-libGL1 Mesa-libEGL1 Mesa-libva \
			libvulkan1 libvulkan_radeon vulkan-tools \
			libva2 libva-utils \
			Mesa-32bit Mesa-dri-32bit Mesa-libGL1-32bit Mesa-libEGL1-32bit \
			libvulkan1-32bit libvulkan_radeon-32bit || true
		# ROCm (optional; available in Tumbleweed via science repo)
		sudo zypper --non-interactive install rocm-opencl rocminfo hip-runtime-amd || true
	fi
}

install_applications() {
	log "Installing necessary applications..."

	# System & Development Packages
	# Mapped from Fedora → openSUSE Tumbleweed.
	# Dropped: packages unavailable on Tumbleweed (kernel-cachyos, @virtualization group, etc.)
	system_dev=(
		# Build/dev libs
		dbus-1-devel                 # was: dbus-devel
		libconfig-devel
		libdrm-devel
		libev-devel
		libX11-devel
		libxcb-devel
		libepoxy-devel
		pcre2-devel
		libpixman-1-0-devel          # was: pixman-devel
		uthash-devel
		xcb-util-image-devel
		xcb-util-renderutil-devel
		xcb-util-devel
		xorgproto-devel              # was: xorg-x11-proto-devel
		Mesa-libGL-devel             # was: libGL-devel
		Mesa-libEGL-devel            # was: libEGL-devel
		util-linux                   # provides `script` utility
		cmake
		ninja                        # was: ninja-build
		python3-devel
		python3-pip
		python3-virtualenv
		python311
		python311-devel
		xrandr
		kernel-devel
		kernel-default-devel
		kernel-source
		acpi
		acpid
		brightnessctl
		dkms
		gcc
		gcc-c++
		clang
		clang-tools                  # was: clang-tools-extra
		gtk3-devel
		ncurses-devel
		maven
		python3-pipx                 # was: pipx
		dotnet-sdk-8.0
		# dotnet-sdk-9.0 not (yet) in Tumbleweed main — skipped
		ghc                          # was: ghc-compiler
		go
		bash-completion
		docker
		docker-compose
		docker-compose-switch
		containerd
		java-21-openjdk
		java-21-openjdk-devel
		gh
		rust
		rust-std
		cargo
		zsh
		php8
		ansible
		android-tools
		openfortivpn
		libpcap-devel
		libusb-1_0-devel             # was: libusb1-devel
		pkgconf-pkg-config
		wmctrl
		gamescope
		pandoc
		tesseract-ocr-traineddata-lithuanian  # was: tesseract-langpack-lit
		texlive-pdfjam               # was: pdfjam
		fd                           # was: fd-find

		# Virtualization (group equivalent on Tumbleweed)
		libvirt
		libvirt-daemon
		libvirt-daemon-qemu
		virt-manager
		qemu-kvm
		qemu-tools
		bridge-utils
	)

	# Desktop & Applications Packages
	desktop_apps=(
		borgbackup
		ffmpeg-7                     # was: ffmpeg-free (Packman provides full build)
		ffmpeg-7-devel               # was: ffmpeg-free-devel
		gstreamer-plugin-openh264    # was: gstreamer1-plugin-openh264
		wine
		sassc
		sensors                      # was: lm_sensors
		wl-clipboard
		ntfs-3g
		playerctl
		xbindkeys
		xkb-switch
		dunst
		polybar
		udiskie
		valgrind
		neovim
		gnome-tweaks
		gnome-shell-pomodoro         # was: gnome-pomodoro
		xset
		vlc
		code
		zed
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
		glib2-devel
		ImageMagick
		fontawesome-fonts
		pavucontrol
		fzf
		zoxide
		lact
		flameshot
		foliate
	)

	log "Installing packages (system + dev)..."
	sudo zypper --non-interactive install --force-resolution --no-confirm \
		"${system_dev[@]}" || true

	log "Installing packages (desktop apps)..."
	sudo zypper --non-interactive install --force-resolution --no-confirm \
		"${desktop_apps[@]}" || true

	# Additional JDKs
	sudo zypper --non-interactive install java-11-openjdk java-17-openjdk || true

	# Development patterns (Tumbleweed equivalent of "group install")
	log "Installing development patterns..."
	sudo zypper --non-interactive install -t pattern devel_basis devel_C_C++ devel_python3 || true

	# Fix HEVC / VAAPI via Packman (vendor change to Packman versions)
	log "Switching multimedia packages to Packman versions..."
	sudo zypper --non-interactive dup --from packman --allow-vendor-change || true

	# Flatpak apps: try to install extensions/apps that aren't in Tumbleweed repos
	log "Installing Flatpak fallbacks for missing packages..."
	flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager || true
	flatpak install -y --noninteractive flathub io.github.ocrmypdf.OCRmyPDF || true   # was: ocrmypdf
	# gnome-shell-extension-blur-my-shell and -forge must be installed via Extension Manager / extensions.gnome.org

	# Missing in distro repos — suggest via pipx/cargo
	log "Installing tools that are not packaged natively..."
	pipx install ansible-lint || true        # was: python3-ansible-lint
	pipx install ansible-core || true
	cargo install rustfmt 2>/dev/null || rustup component add rustfmt 2>/dev/null || true

	log "Removing LibreOffice and installing OnlyOffice via Flatpak..."
	sudo zypper --non-interactive remove 'libreoffice*' || true
	flatpak install -y --noninteractive flathub org.onlyoffice.desktopeditors

	if [ ! -d "/opt/obsidian" ] && [ -f obsidian-appimage-install.sh ]; then
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
	sudo systemctl enable --now libvirtd
	sudo gpasswd -a "$USER" libvirt || true
	sudo gpasswd -a "$USER" kvm || true
}

enable_lact() {
	log "Enabling LACT service (AMD GPU tuning)..."
	sudo systemctl enable --now lactd || true
}

configure_desktop() {
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
	install_gpu_drivers
	setup_flatpak
	setup_snap
	setup_homebrew
	install_applications
	configure_docker
	enable_virtualization
	enable_lact
	configure_desktop
	log "Performing final system update..."
	sudo zypper --non-interactive dup --allow-vendor-change
	log "Done. A reboot is recommended."
}

main
