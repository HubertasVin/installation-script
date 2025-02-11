#!/bin/bash
# wait a short moment to let the lid state settle
sleep 0.5

if grep -q "closed" /proc/acpi/button/lid/*/state; then
    external_count=$(swaymsg -t get_outputs -r | jq '[.[] | select(.name != "eDP-1" and .active==true)] | length')

    if [ "$external_count" -gt 0 ]; then
        # External display(s) connected: just disable the internal display.
        swaymsg "output eDP-1 disable" >> /home/hubertas/tempOut.log
        echo "Closed lid" >> /home/hubertas/tempOut.log
    else
        # No external display: log out the session.
        systemctl suspend >> /home/hubertas/tempOut.log
    fi
else
    # Lid is open: re-enable the internal display.
    swaymsg "output eDP-1 enable"
fi

