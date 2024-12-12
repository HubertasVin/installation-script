#!/bin/bash

alacritty -o "window.startup_mode='Maximized'" -e tmux &
sleep 1 && wmctrl -r alacritty -t 2 & 2> /home/hubertas/startup.log

python /home/hubertas/tools/yield-curve-and-initial-jobless-plot.py 2> /home/hubertas/startup.log &
