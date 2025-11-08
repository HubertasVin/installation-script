#!/usr/bin/env bash
set -euo pipefail

BG_DIR="${WALLPAPER_DIR:-"$HOME/Pictures/Wallpapers"}"

# Find a random wallpaper
next="$(find "$BG_DIR" -type f \( -iname '*.avif' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' \) -print0 | shuf -z -n 1 | tr -d '\0')"
[ -n "${next:-}" ] || exit 1

# Detect desktop environment
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]] || [[ "${DESKTOP_SESSION:-}" == *"plasma"* ]]; then
	# KDE/Plasma
	plasma-apply-wallpaperimage "$next"
elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
	# GNOME
	echo "Setting wallpaper for GNOME: $next"
	uri="file://$next"
	gsettings set org.gnome.desktop.background picture-uri "$uri"
	if gsettings list-keys org.gnome.desktop.background 2>/dev/null | grep -qx 'picture-uri-dark'; then
		gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
	fi

else
	echo "Unsupported desktop environment: ${XDG_CURRENT_DESKTOP:-unknown}"
	exit 1
fi

echo "Wallpaper set successfully!"
