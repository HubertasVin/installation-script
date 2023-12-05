#!/bin/bash

alacritty -e tmux

systemctl --user unmask pulseaudio; systemctl --user --now disable pipewire.socket; systemctl --user --now enable pulseaudio.service pulseaudio.socket
