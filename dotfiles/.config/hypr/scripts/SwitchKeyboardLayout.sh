#!/usr/bin/env bash
# Switch keyboard layout and cache layout code for waybar

hyprctl switchxkblayout all next

layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' 2>/dev/null | head -n1)
if [ -z "$layout" ] || [ "$layout" = "null" ]; then
    layout=$(hyprctl devices -j | jq -r '.keyboards[0].active_keymap' 2>/dev/null)
fi

short_layout=$(echo "$layout" | awk '{print tolower(substr($0, 1, 2))}')
[ -z "$short_layout" ] && short_layout="us"

echo "$short_layout" > "$HOME/.cache/kb_layout"
