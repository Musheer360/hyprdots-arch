#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Toggle matugen dark/light theme and regenerate colors

MODE_FILE="$HOME/.cache/matugen_mode"
WALLPAPER="$HOME/.config/hypr/current_wallpaper"

if [ -f "$MODE_FILE" ]; then
    CURRENT_MODE=$(cat "$MODE_FILE")
else
    CURRENT_MODE="dark"
fi

if [ "$CURRENT_MODE" = "dark" ]; then
    NEW_MODE="light"
else
    NEW_MODE="dark"
fi

echo "$NEW_MODE" > "$MODE_FILE"

if [ -e "$WALLPAPER" ]; then
    TARGET_IMG=$(readlink -f "$WALLPAPER")
    matugen --source-color-index 0 image "$TARGET_IMG" -m "$NEW_MODE"
    notify-send "Theme Changed" "Switched to $NEW_MODE mode"
fi
