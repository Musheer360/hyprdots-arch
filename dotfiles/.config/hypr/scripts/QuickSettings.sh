#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Quick settings menu for rofi

sDIR="$HOME/.config/hypr/scripts"

MENU="1. 󰔎  Toggle Dark/Light Mode\n2. 󰹩  Choose Wallpaper\n3. 󱪤  Waybar Styles\n4. 󱪥  Waybar Layouts\n5. 󰌾  Lock Screen\n6.   Power Menu"

CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Quick Settings")

case "$CHOICE" in
    *Dark/Light*)
        "$sDIR/DarkLight.sh"
        ;;
    *Wallpaper*)
        "$sDIR/wppicker.sh"
        ;;
    *Styles*)
        "$sDIR/WaybarStyles.sh"
        ;;
    *Layouts*)
        "$sDIR/WaybarLayout.sh"
        ;;
    *Lock*)
        "$sDIR/LockScreen.sh"
        ;;
    *Power*)
        "$sDIR/Wlogout.sh"
        ;;
esac
