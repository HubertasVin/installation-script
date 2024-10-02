#!/bin/bash

echo -e "Plug in all displays to setup autorandr"
read -n 1 -p '(Press any key to continue)' answer

# ---- Setup autorandr configs
# Only Laptop
xrandr --output eDP-1 --mode 1920x1200 --pos 0x0 --rotate normal
autorandr --save laptop
sed -i '/^DP-1/d' ~/.config/autorandr/laptop/setup

# Only external in dual display mode
xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rate 144 --rotate normal \
       --output eDP-1 --off
autorandr --save external

# Only external in single display mode
xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rate 144 --rotate normal
autorandr --save external-single
sed -i '/^eDP-1/d' ~/.config/autorandr/external-single/setup

# Dual display mode
xrandr --output DP-1 --mode 1920x1080 --pos 0x0 --rate 144 --rotate normal \
       --output eDP-1 --mode 1920x1200 --pos 1920x0 --rotate normal
autorandr --save external-laptop
