#!/usr/bin/env bash

sleep 3
WAYLAND_DISPLAY= alacritty -o "window.startup_mode='Maximized'" -e tmux &
sleep 1
wmctrl -r alacritty -t 2

python3 ~/tools/llm_pareto.py &
python3 ~/tools/fake_wifi_portal.py &
