#!/usr/bin/env bash

set -euo pipefail

REPO="obsidianmd/obsidian-releases"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then SUDO=${SUDO:-sudo}; else SUDO=""; fi
BIN_DIR="/opt/obsidian"
DESKTOP_DIR="/usr/share/applications"
ICON_BASE="/usr/share/icons/hicolor"
BIN_LINK="/usr/local/bin/obsidian"

mkdir -p "$DESKTOP_DIR" "$ICON_BASE/128x128/apps" "$ICON_BASE/256x256/apps" "$ICON_BASE/512x512/apps"
$SUDO mkdir -p "$BIN_DIR"

# Download AppImage
releases_json="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")"
download_urls="$(echo "$releases_json" \
  | grep -oE '"browser_download_url": *"[^"]+AppImage[^"]*"' \
  | cut -d '"' -f 4)"

download_url="$(echo "$download_urls" | grep -E '/Obsidian-[0-9.]+\.AppImage$' | head -n1)"
[[ -n $download_url ]] || { echo "No generic Obsidian *.AppImage asset found in latest release."; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading: $download_url"
curl -fL $download_url -o $tmpdir/Obsidian.AppImage
chmod +x $tmpdir/Obsidian.AppImage

# Install AppImage
$SUDO install -m 0755 $tmpdir/Obsidian.AppImage $BIN_DIR/Obsidian.AppImage
$SUDO ln -sf $BIN_DIR/Obsidian.AppImage $BIN_LINK

# Install icon
for dimen in 128 256 512; do
	$SUDO install -m 0644 $SCRIPT_DIR/resources/obsidian-${dimen}.png $ICON_BASE/${dimen}x${dimen}/apps/obsidian.png
done

# Create .desktop entry
desktop_contents="[Desktop Entry]
Type=Application
Name=Obsidian
Comment=Obsidian
Exec=$BIN_DIR/Obsidian.AppImage %U
TryExec=$BIN_DIR/Obsidian.AppImage
Icon=obsidian
Terminal=false
Categories=Office;Utility;TextEditor;Notes;
StartupWMClass=obsidian
MimeType=x-scheme-handler/obsidian;"

echo "$desktop_contents" | $SUDO tee $DESKTOP_DIR/obsidian.desktop >/dev/null
