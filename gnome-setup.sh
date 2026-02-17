#!/usr/bin/env bash

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

	# Tiling assistant
	git clone https://github.com/Leleat/Tiling-Assistant.git
	cd Tiling-Assistant/
	bash scripts/build.sh
	cd .. && rm -rf Tiling-Assistant/

	git clone https://github.com/galets/gnome-keyboard-reset.git
	cd gnome-keyboard-reset
	make install
	cd .. && rm -rf gnome-keyboard-reset
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

#----------- Fixing text fringing -----------
#------- on high resolution displays --------
if [ "$(xrandr --current | awk '/\*/{split($1,a,"x"); print a[2]; exit}')" -ge 1440 ]; then
	gsettings set org.gnome.desktop.interface text-scaling-factor 1.3
fi
