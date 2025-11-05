#!/usr/bin/env bash

# set the icon and a temporary location for the screenshot to be stored
icon="$HOME/tools/images/lock-icon-dark.png"
tmpbg='/tmp/screen.png'
small_icon='/tmp/small-icon.png'

if [ -f "$tmpbg" ]; then
	rm -f "$tmpbg"
fi

# take a screenshot
scrot "$tmpbg"

# blur the screenshot by resizing and scaling back up
magick "$tmpbg" -filter Gaussian -thumbnail 10% -sample 1000% "$tmpbg"

# Shrink the icon to 33% of its original size (one-third)
magick "$icon" -resize 33% "$small_icon"

# Overlay the shrunken icon onto the blurred screenshot
magick "$tmpbg" "$small_icon" -gravity center -composite "$tmpbg"

# lock the screen with the blurred screenshot
i3lock -i "$tmpbg" --no-unlock-indicator

