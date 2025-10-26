#!/bin/bash

# Name pattern of your target device (as shown in evtest)
DEVICE_NAME="Logitech USB Receiver Mouse"

# Function: find the event device path for the given name
find_device() {
    for dev in /dev/input/event*; do
        name=$(cat /sys/class/input/$(basename "$dev")/device/name 2>/dev/null)
        if [[ "$name" == "$DEVICE_NAME" ]]; then
            echo "$dev"
            return 0
        fi
    done
    return 1
}

# Function: start listening to device
listen_device() {
    local device="$1"
    echo "✅ Listening to: $device ($DEVICE_NAME)"
    evtest "$device" | while read line; do
        # Thumb button
        if echo "$line" | grep -q "type 1 (EV_KEY), code 277 (BTN_FORWARD), value 1"; then
            playerctl play-pause
        fi

        # Thumb wheel left
        if echo "$line" | grep -q "type 2 (EV_REL), code 6 (REL_HWHEEL), value 1"; then
            pactl set-sink-volume @DEFAULT_SINK@ -3%
        fi

        # Thumb wheel right
        if echo "$line" | grep -q "type 2 (EV_REL), code 6 (REL_HWHEEL), value -1"; then
            pactl set-sink-volume @DEFAULT_SINK@ +3%
        fi
    done
}

# Main loop: periodically check device availability
while true; do
    device=$(find_device)
    if [[ -n "$device" ]]; then
        listen_device "$device"
        echo "⚠️ Device disconnected or evtest stopped — retrying in 5s..."
    else
        echo "🔍 Waiting for $DEVICE_NAME to appear..."
    fi
    sleep 5
done
