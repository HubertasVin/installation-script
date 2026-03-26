#!/usr/bin/env bash

sleep 3
WAYLAND_DISPLAY= alacritty -o "window.startup_mode='Maximized'" -e tmux &
sleep 1
wmctrl -r alacritty -t 2

python3 ~/tools/yield-curve-and-initial-jobless-plot.py &
