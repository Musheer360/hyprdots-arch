#!/usr/bin/env bash
mkdir -p "$HOME/Pictures/Screenshots"
time=$(date +'%Y-%m-%d-%H%M%S')
file="$HOME/Pictures/Screenshots/${time}_grim.png"

geom=$(slurp)
[ -z "$geom" ] && exit 0

grim -g "$geom" "$file"
wl-copy < "$file"
notify-send -e -u low -i "$file" "Screenshot Captured" "Saved to $(basename "$file") & copied to clipboard"
