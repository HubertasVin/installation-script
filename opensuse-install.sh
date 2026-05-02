#!/usr/bin/env bash
set -euo pipefail

trap 'echo "[ERROR] Script failed at line $LINENO: $BASH_COMMAND" >&2' ERR

log() {
	echo "[$(date +"%H:%M:%S")] $*"
}

update_system() {
	log "Updating and refreshing the system..."
	sudo zypper --non-interactive refresh
	sudo zypper dup --auto-agree-with-licenses --allow-vendor-change
}

add_repos() {
	log "Adding Packman repository (for multimedia/ffmpeg)..."
	if ! zypper lr -d | grep -qi '^[[:space:]]*[0-9]\+[[:space:]]*|[[:space:]]*packman[[:space:]]*|'; then
		sudo zypper ar -cfp 90 https://ftp.fau.de/packman/suse/openSUSE_Tumbleweed/ packman
		sudo zypper --gpg-auto-import-keys refresh
		sudo zypper dup --auto-agree-with-licenses \
			--from packman --allow-vendor-change
	fi

	log "Adding additional repositories..."

	if ! zypper lr -d | grep -qi "vscode"; then
		log "Adding Visual Studio Code repository..."
		sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
		sudo tee /etc/zypp/repos.d/vscode.repo > /dev/null <<'EOF'
[vscode]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
	fi

	if ! zypper lr -d | grep -qi "snappy"; then
		sudo zypper ar -cfp 90 \
			https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed snappy
	fi

	if ! zypper lr -d | grep -qi "openh264"; then
		sudo zypper ar -cfp 90 https://codecs.opensuse.org/openh264/openSUSE_Tumbleweed/ openh264
	fi

	if lspci | grep -iE 'VGA|3D|Display' | grep -iq 'NVIDIA'; then
		log "Detected NVIDIA graphics. Adding NVIDIA repository..."
		if ! zypper lr -d | grep -qi "nvidia"; then
			sudo zypper ar -cfp 90 https://download.nvidia.com/opensuse/tumbleweed/ NVIDIA
		fi
	fi

	log "Refreshing all repos..."
	sudo zypper --gpg-auto-import-keys refresh
}

setup_flatpak() {
	log "Setting up Flatpak..."
	sudo zypper install --auto-agree-with-licenses flatpak
	sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

setup_snap() {
	log "Setting up Snap..."
	if ! command -v snap &>/dev/null; then
		sudo zypper install --auto-agree-with-licenses snapd
	fi
	sudo systemctl enable --now snapd.service
	sudo systemctl enable --now snapd.apparmor.service
	if [ ! -L "/snap" ] && [ ! -d "/snap" ]; then
		sudo ln -s /var/lib/snapd/snap /snap
		echo 'Reboot your computer to enable snapd to function fully'
		read -r -p 'Confirm to reboot your computer (y/N) ' answer
		case "$answer" in
			[yY]|[yY][eE][sS]) /usr/sbin/reboot ;;
			*) ;;
		esac
	fi
}

setup_homebrew() {
	if [ ! -d "/home/linuxbrew" ]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		test -d "$HOME/.linuxbrew" && eval "$("$HOME"/.linuxbrew/bin/brew shellenv)"
		test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> "$HOME/.bashrc"
	fi
	test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
}

install_gpu_drivers() {
	if lspci | grep -iE 'VGA|3D|Display' | grep -iq 'NVIDIA'; then
		log "Installing NVIDIA drivers..."
		sudo zypper install --auto-agree-with-licenses \
			nvidia-userspace-meta-G06 \
			nvidia-compute-utils-G06 \
			nvidia-video-G06
	fi

	if lspci | grep -iE 'VGA|3D|Display' | grep -iqE 'AMD|ATI'; then
		log "Installing AMD Mesa/Vulkan stack..."
		sudo zypper install --auto-agree-with-licenses \
			Mesa Mesa-dri Mesa-libGL1 Mesa-libEGL1 Mesa-libva \
			libvulkan1 libvulkan_radeon vulkan-tools \
			libva2 libva-utils \
			Mesa-32bit Mesa-dri-32bit Mesa-libGL1-32bit Mesa-libEGL1-32bit \
			libvulkan1-32bit libvulkan_radeon-32bit

		log "Installing ROCm / HIP stack (optional)..."
		# Query available ROCm packages first and install only what exists.
		local rocm_candidates=(rocm-smi rocminfo rocm-opencl rocm-opencl-devel hipcc hip-devel)
		local rocm_available=()
		for pkg in "${rocm_candidates[@]}"; do
			if zypper search --match-exact "$pkg" \
					| awk -v p="$pkg" '$3==p {found=1} END {exit !found}'; then
				rocm_available+=("$pkg")
			else
				log "Note: $pkg not in repos; skipping."
			fi
		done
		if [ ${#rocm_available[@]} -gt 0 ]; then
			sudo zypper install --auto-agree-with-licenses \
				"${rocm_available[@]}"
		else
			log "No ROCm packages available in configured repos. Skipping ROCm stack."
		fi
	fi
}

install_applications() {
	log "Installing necessary applications..."

	system_dev=(
		dbus-1-devel libconfig-devel libdrm-devel libev-devel
		libX11-devel libxcb-devel libepoxy-devel pcre2-devel
		libpixman-1-0-devel uthash-devel
		xcb-util-image-devel xcb-util-renderutil-devel xcb-util-devel
		xorgproto-devel Mesa-libGL-devel Mesa-libEGL-devel
		util-linux cmake ninja
		python3-devel python3-pip python3-virtualenv python311 python311-devel
		xrandr kernel-devel kernel-default-devel kernel-source
		acpi acpid brightnessctl dkms
		gcc gcc-c++ clang clang-tools
		gtk3-devel ncurses-devel maven python3-pipx
		go bash-completion nodejs-common
		docker docker-compose docker-compose-switch containerd
		java-21-openjdk java-21-openjdk-devel
		java-11-openjdk java-11-openjdk-devel
		java-17-openjdk java-17-openjdk-devel
		gh rust rust-std cargo zsh php8 ansible
		android-tools openfortivpn libpcap-devel libusb-1_0-devel
		pkgconf-pkg-config wmctrl gamescope pandoc fd
		libvirt libvirt-daemon libvirt-daemon-qemu
		virt-manager qemu-kvm qemu-tools bridge-utils
		ripgrep power-profiles-daemon
	)

	desktop_apps=(
		borgbackup ffmpeg tmux NetworkManager-connection-editor
		sassc sensors wl-clipboard ntfs-3g playerctl
		xbindkeys xkb-switch dunst polybar udiskie valgrind neovim
		gnome-tweaks gnome-pomodoro xset vlc code steam
		btop htop qbittorrent discord ranger trash-cli putty
		arandr autorandr pamixer tealdeer peek alacritty ncdu
		gnome-shell-extension-user-theme glib2-devel ImageMagick
		fontawesome-fonts pavucontrol fzf zoxide lact flameshot foliate
	)

	log "Installing packages (system + dev)..."
	sudo zypper --non-interactive install --auto-agree-with-licenses \
		--force-resolution --no-confirm \
		"${system_dev[@]}"

	log "Installing packages (desktop apps)..."
	sudo zypper --non-interactive install --auto-agree-with-licenses \
		--force-resolution --no-confirm \
		"${desktop_apps[@]}"

	log "Installing development patterns..."
	sudo zypper --non-interactive install --auto-agree-with-licenses \
		-t pattern devel_basis devel_C_C++ devel_python3

	log "Switching multimedia packages to Packman versions..."
	sudo zypper dup --auto-agree-with-licenses \
		--from packman --allow-vendor-change

	sudo zypper --non-interactive install --auto-agree-with-licenses --force-resolution wine

	if [ ! `which ocrmypdf` ]; then
		log "Installing Flatpak packages..."
		sudo flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager
		brew install ocrmypdf
	fi

	log "Installing Python tool..."
	pipx install ansible-lint
	pipx install ansible-core
	if command -v rustup &>/dev/null; then
		rustup component add rustfmt
	else
		cargo install rustfmt
	fi

	log "Removing LibreOffice and installing OnlyOffice via Flatpak..."
	if rpm -qa 'libreoffice*' | grep -q .; then
		sudo zypper --non-interactive remove 'libreoffice*'
	fi
	sudo snap install onlyoffice-desktopeditors

	if [ ! -d "/opt/obsidian" ] && [ -f obsidian-appimage-install.sh ]; then
		bash obsidian-appimage-install.sh
	fi

	curl -f https://zed.dev/install.sh | sh
}

configure_docker() {
	log "Configuring Docker..."
	sudo systemctl enable --now docker
	sudo gpasswd -a "$USER" docker
}

enable_virtualization() {
	log "Enabling virtualization services..."
	sudo systemctl enable --now libvirtd
	sudo gpasswd -a "$USER" libvirt
	sudo gpasswd -a "$USER" kvm
}

enable_lact() {
	log "Enabling LACT service (AMD GPU tuning)..."
	sudo systemctl enable --now lactd
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
	sudo zypper dup --auto-agree-with-licenses --allow-vendor-change
	log "Done. A reboot is recommended."
}

main
