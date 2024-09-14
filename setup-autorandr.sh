#!/bin/bash

echo -e "Plug in all displays to setup autorandr"
read -n 1 -p '(Press any key to continue)' answer

xrandr --output eDP-1 --mode 1920x1200 --pos 0x0 --rotate normal \
       --output DP-1 --off
autorandr --save laptop
sed -i '/^DP-1/d' ~/.config/autorandr/laptop/setup

xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rate 144 --rotate normal \
       --output eDP-1 --off
autorandr --save external
