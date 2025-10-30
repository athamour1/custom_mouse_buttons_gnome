#!/usr/bin/env bash
set -euo pipefail

# === Config ===
DEVICE_NAME="ELECOM TrackBall Mouse HUGE TrackBall"
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-/tmp/.ydotool_socket}"

# Linux input keycodes (from input-event codes)
KEY_LEFTMETA=125    # Super/Win
KEY_PAGEUP=104
KEY_PAGEDOWN=109
KEY_F12=88

# (keep these around for safety releases)
KEY_LEFTCTRL=29
KEY_LEFTALT=56
KEY_LEFT=105
KEY_RIGHT=106

# === Helpers ===

ensure_ydotoold() {
  # Start your requested daemon command if the socket isn't alive yet
  if ! ss -x | grep -q "$YDOTOOL_SOCKET"; then
    echo "🔧 starting: sudo ydotoold --socket $YDOTOOL_SOCKET --verbosity trace"
    # run in the background so the script can continue
    nohup bash -lc "sudo ydotoold --socket '$YDOTOOL_SOCKET' --verbosity trace" >/dev/null 2>&1 &
    # wait a moment for the socket to appear
    for _ in {1..30}; do
      sleep 0.1
      ss -x | grep -q "$YDOTOOL_SOCKET" && break
    done
    if ! ss -x | grep -q "$YDOTOOL_SOCKET"; then
      echo "❌ ydotoold did not come up on $YDOTOOL_SOCKET"; exit 1
    fi
  fi
}

# Always try to fully release any possibly-stuck keys
_release_all() {
  ydotool key \
    ${KEY_LEFT}:0 ${KEY_RIGHT}:0 \
    ${KEY_PAGEUP}:0 ${KEY_PAGEDOWN}:0 \
    ${KEY_LEFTALT}:0 ${KEY_LEFTCTRL}:0 ${KEY_LEFTMETA}:0 \
    ${KEY_F12}:0 || true
}

# Super+PageUp/PageDown with slight delay, then hard release
_ws_prev() {
  ydotool key ${KEY_LEFTMETA}:1 ${KEY_PAGEUP}:1 ${KEY_PAGEUP}:0 ${KEY_LEFTMETA}:0
  sleep 0.02
  _release_all
}
_ws_next() {
  ydotool key ${KEY_LEFTMETA}:1 ${KEY_PAGEDOWN}:1 ${KEY_PAGEDOWN}:0 ${KEY_LEFTMETA}:0
  sleep 0.02
  _release_all
}

_press_f12() {
  ydotool key ${KEY_F12}:1 ${KEY_F12}:0
  sleep 0.01
  _release_all
}

find_device() {
  for dev in /dev/input/event*; do
    name_file="/sys/class/input/$(basename "$dev")/device/name"
    [[ -r "$name_file" ]] || continue
    if [[ "$(cat "$name_file")" == "$DEVICE_NAME" ]]; then
      echo "$dev"; return 0
    fi
  done
  return 1
}

listen_device() {
  local device="$1"
  echo "✅ Listening to: $device ($DEVICE_NAME)"

  # debounce state (0 = up, 1 = down)
  local side_down=0 extra_down=0 task_down=0

  stdbuf -oL evtest "$device" | while IFS= read -r line; do
    # --- BTN_EXTRA (276) → NEXT workspace ---
    if [[ "$line" == *"type 1 (EV_KEY), code 276 (BTN_EXTRA), value 1"* ]]; then
      if [[ $extra_down -eq 0 ]]; then
        extra_down=1
        _ws_next
      fi
      continue
    fi
    if [[ "$line" == *"type 1 (EV_KEY), code 276 (BTN_EXTRA), value 0"* ]]; then
      extra_down=0; continue
    fi

    # --- BTN_SIDE (275) → PREV workspace ---
    if [[ "$line" == *"type 1 (EV_KEY), code 275 (BTN_SIDE), value 1"* ]]; then
      if [[ $side_down -eq 0 ]]; then
        side_down=1
        _ws_prev
      fi
      continue
    fi
    if [[ "$line" == *"type 1 (EV_KEY), code 275 (BTN_SIDE), value 0"* ]]; then
      side_down=0; continue
    fi

    # --- BTN_TASK (279) → F12 ---
    if [[ "$line" == *"type 1 (EV_KEY), code 279 (BTN_TASK), value 1"* ]]; then
      if [[ $task_down -eq 0 ]]; then
        task_down=1
        _press_f12
      fi
      continue
    fi
    if [[ "$line" == *"type 1 (EV_KEY), code 279 (BTN_TASK), value 0"* ]]; then
      task_down=0; continue
    fi
  done
}

cleanup_release() { _release_all; }
trap cleanup_release EXIT INT TERM

# === Main ===
if [[ $EUID -ne 0 ]]; then
  echo "⚠️ Run with sudo (or add a udev rule to avoid sudo)."
fi

ensure_ydotoold

while true; do
  device=$(find_device || true)
  if [[ -n "${device:-}" ]]; then
    listen_device "$device"
    echo "⚠️ Device disconnected or evtest exited — retrying in 5s…"
  else
    echo "🔍 Waiting for \"$DEVICE_NAME\" to appear…"
  fi
  sleep 5
done
