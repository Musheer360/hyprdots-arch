#!/usr/bin/env bash
# /* ---- 💫 Wallpaper Picker via rofi and matugen 💫 ---- */

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"

[ ! -d "$WALLPAPER_DIR" ] && exit 1
cd "$WALLPAPER_DIR" || exit 1

if [ "${1:-}" = "--random" ]; then
    SELECTED_WALL=$(find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf '%P\0' | shuf -z -n 1 | tr -d '\0')
else
    SELECTED_WALL=$(
        find . -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf '%T@ %P\0' 2>/dev/null | \
        sort -z -n -r | \
        awk 'BEGIN { RS="\0"; ORS="\n" } { sub(/^[0-9.]+ /, ""); if (length($0) > 0) printf "%s\0icon\x1f%s/%s\n", $0, ENVIRON["PWD"], $0 }' | \
        rofi -dmenu -p "Wallpaper"
    )
fi

[ -z "$SELECTED_WALL" ] && exit 0
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"
[ ! -f "$SELECTED_PATH" ] && exit 1

MODE="dark"
[ -f "$HOME/.cache/matugen_mode" ] && MODE=$(cat "$HOME/.cache/matugen_mode")

matugen --source-color-index 0 image "$SELECTED_PATH" -m "$MODE"

mkdir -p "$(dirname "$SYMLINK_PATH")"
ln -sfn "$SELECTED_PATH" "$SYMLINK_PATH"
