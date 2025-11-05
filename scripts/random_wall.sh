#!/usr/bin/env bash
set -euo pipefail

BG_DIR="${WALLPAPER_DIR:-"$HOME/Pictures/Wallpapers"}"

next="$(find "$BG_DIR" -type f \( -iname '*.avif' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' \) -print0 | shuf -z -n 1 | tr -d '\0')"
[ -n "${next:-}" ] || exit 1

uri="file://$next"
gsettings set org.gnome.desktop.background picture-uri "$uri"
if gsettings list-keys org.gnome.desktop.background 2>/dev/null | grep -qx 'picture-uri-dark'; then
	gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
fi
