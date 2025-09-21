#!/bin/bash

original_input=$(/usr/bin/gsettings get org.gnome.desktop.input-sources sources)
/usr/bin/gsettings set org.gnome.desktop.input-sources sources "[]"
/usr/bin/gsettings set org.gnome.desktop.input-sources sources "$original_input"
