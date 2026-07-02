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
				[yY]|[yY][eE][sS]) /usr/sbin/reboot ;;
				*) ;;
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

secure_boot_kernel_setup() {
	if mokutil --sb-state 2>/dev/null | grep -q enabled; then
		log "Secure Boot enabled – setting up automatic kernel signing"

		# Install signing tool
		sudo dnf install -y pesign

		MOK_CN="CachyOS Secure Boot"
		KEY_DIR="${HOME}/.local/share/mok"
		SIGN_SCRIPT="/etc/kernel/postinst.d/00-signing"

		# Generate key if it does not exist
		mkdir -p "$KEY_DIR"
		if [ ! -f "$KEY_DIR/MOK.priv" ] || [ ! -f "$KEY_DIR/MOK.der" ]; then
			log "Generating MOK keypair..."
			openssl req -new -x509 -newkey rsa:2048 \
				-keyout "$KEY_DIR/MOK.priv" -outform DER -out "$KEY_DIR/MOK.der" \
				-days 36500 -subj "/CN=${MOK_CN}/" -nodes
			sudo certutil -d /etc/pki/pesign -N --empty-password
			sudo certutil -d /etc/pki/pesign -A \
				-n "$MOK_CN" -t Pu,Pu,Pu -i "$KEY_DIR/MOK.der"
		fi

		# Create the signing hook
		if [ ! -f "$SIGN_SCRIPT" ]; then
			log "Creating kernel signing hook..."
			sudo tee "$SIGN_SCRIPT" > /dev/null <<'EOF'
#!/bin/sh
set -e
KERNEL_IMAGE="$2"
MOK_KEY_NICKNAME="CachyOS Secure Boot"
if [ "$#" -ne 2 ] ; then
	echo "Wrong count of command line arguments. This is not meant to be called directly." >&2
	exit 1
fi
if [ ! -x "$(command -v pesign)" ] ; then
	echo "pesign not executable. Bailing." >&2
	exit 1
fi
if [ ! -w "$KERNEL_IMAGE" ] ; then
	echo "Kernel image $KERNEL_IMAGE is not writable." >&2
	exit 1
fi
echo "Signing $KERNEL_IMAGE..."
pesign --certificate "$MOK_KEY_NICKNAME" --in "$KERNEL_IMAGE" --sign --out "$KERNEL_IMAGE.signed"
mv "$KERNEL_IMAGE.signed" "$KERNEL_IMAGE"
EOF
			sudo chmod +x "$SIGN_SCRIPT"
		fi

		# Enroll the key if not already present
		if ! sudo mokutil --list-enrolled 2>/dev/null | grep -q "CN=${MOK_CN}"; then
			log "MOK not enrolled – importing and requesting enrollment"
			sudo mokutil --import "$KEY_DIR/MOK.der"
			log ">>> Reboot and use the MOK Manager to enroll the key <<<"
			log "After reboot, the signing hook will automatically sign every new kernel."
		else
			log "MOK already enrolled – signing hook is active."
		fi
	else
		log "Secure Boot not enabled – skipping MOK setup"
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
		if ! dnf copr list | grep -q "ilyaz/LACT"; then
			sudo dnf copr enable ilyaz/LACT -y
		fi
		sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers vulkan-tools \
			mesa-va-drivers mesa-vdpau-drivers libva-utils \
			mesa-dri-drivers.i686 mesa-vulkan-drivers.i686 \
			rocm rocm-opencl rocm-hip
	fi

	# ----------------------------------------------------------------------
	# Secure Boot: auto-sign custom kernels (CachyOS, etc.) with a MOK
	# ----------------------------------------------------------------------
	secure_boot_kernel_setup

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
		clang
		gtk3-devel
		kernel-cachyos
		kernel-cachyos-devel
		ncurses-devel
		maven
		pipx
		dotnet-sdk-8.0
		dotnet-sdk-9.0
		ghc-compiler
		go
		golang
		clang-tools-extra
		bash-completion
		docker-cli
		containerd
		docker-compose
		java-21-openjdk
		java-21-openjdk-devel
		gh
		rust
		rust-src
		rustfmt
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
		gamescope
		pandoc
		tesseract-langpack-lit
		ocrmypdf
		pdfjam
		fd-find
		libsecret-devel
		pkg-config
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
		zed
		steam
		btop
		htop
		qbittorrent
		discord
		ranger
		trash-cli
		putty
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
		lact
		flameshot
		foliate
	)

	# Combine both arrays into a single installation list
	all_packages=("${system_dev[@]}" "${desktop_apps[@]}")

	log "Installing packages..."
	sudo dnf install -y --skip-unavailable --allowerasing "${all_packages[@]}"
	sudo dnf install -y --skip-unavailable --allowerasing temurin-11-jdk temurin-17-jdk
	sudo dnf group install -y d-development c-development development-tools
	# Fix HEVC decoding problems
	sudo dnf install -y --allowerasing libva libva-utils mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld
	sudo dnf group upgrade multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

	log "Removing LibreOffice and installing OnlyOffice..."
	sudo dnf remove -y 'libreoffice*'
	flatpak install -y flathub org.onlyoffice.desktopeditors

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

enable_lact() {
	sudo systemctl enable --now lactd
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
	enable_lact
	log "Performing final system update..."
	sudo dnf update -y
}

main
