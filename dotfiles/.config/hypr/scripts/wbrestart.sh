#!/usr/bin/env bash
killall -9 swaync 2>/dev/null
killall -9 waybar 2>/dev/null
swaync &
waybar &
