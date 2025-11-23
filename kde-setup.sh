#!/usr/bin/env bash

if [ "$KDE_FULL_SESSION" = "true" ] || [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
	echo "Starting restoration of KDE settings..."
	cd $HOME/dotfiles
	bash <(curl -s https://gitlab.com/cscs/transfuse/-/raw/main/transfuse) -r "$(whoami)"
	cd -
fi
