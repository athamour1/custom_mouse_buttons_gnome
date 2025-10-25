#!/bin/bash

# Listen to your device (replace event12 with your actual device)
evtest /dev/input/event12 | while read line; do
    # Thumb button
    if echo "$line" | grep -q "type 1 (EV_KEY), code 277 (BTN_FORWARD), value 1"; then
        # xdotool key XF86AudioPlay
        # echo "play/pause"
        playerctl play-pause
    fi

    # Thumb wheel left
    # type 2 (EV_REL), code 6 (REL_HWHEEL), value 1
    if echo "$line" | grep -q "type 2 (EV_REL), code 6 (REL_HWHEEL), value 1"; then
        # xdotool key XF86AudioLowerVolume
        # echo "vol down"
        pactl set-sink-volume @DEFAULT_SINK@ -5%
    fi

    # Thumb wheel right
    if echo "$line" | grep -q "type 2 (EV_REL), code 6 (REL_HWHEEL), value -1"; then
        # xdotool key XF86AudioRaiseVolume
        # echo "vol up"
	pactl set-sink-volume @DEFAULT_SINK@ +5%
    fi
done
