#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Play system event sounds (no-ops gracefully if missing)

[ ! -d "$HOME/.config/hypr/sounds" ] && [ ! -d "/usr/share/sounds" ] && exit 0

theme="freedesktop"
systemDIR="/usr/share/sounds"
userDIR="$HOME/.config/hypr/sounds"

case "$1" in
    --volume)
        soundoption="audio-volume-change.*"
        ;;
    --screenshot)
        soundoption="screen-capture.*"
        ;;
    --error)
        soundoption="dialog-error.*"
        ;;
    *)
        exit 0
        ;;
esac

sound_file=$(find -L "$userDIR" "$systemDIR/$theme" -name "$soundoption" 2>/dev/null | head -n1)

if [ -n "$sound_file" ] && [ -f "$sound_file" ]; then
    if command -v pw-play >/dev/null 2>&1; then
        pw-play "$sound_file" >/dev/null 2>&1 &
    elif command -v canberra-gtk-play >/dev/null 2>&1; then
        canberra-gtk-play -f "$sound_file" >/dev/null 2>&1 &
    fi
fi
exit 0
