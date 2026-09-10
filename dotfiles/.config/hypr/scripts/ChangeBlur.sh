#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Toggle Hyprland blur

STATE_FILE="$HOME/.cache/hypr_blur_state"

if [ -f "$STATE_FILE" ]; then
    CURRENT=$(cat "$STATE_FILE")
else
    CURRENT="1"
fi

if [ "$CURRENT" = "1" ]; then
    NEW="0"
    hyprctl keyword decoration:blur:enabled false
    notify-send "Hyprland" "Blur disabled"
else
    NEW="1"
    hyprctl keyword decoration:blur:enabled true
    notify-send "Hyprland" "Blur enabled"
fi

echo "$NEW" > "$STATE_FILE"
