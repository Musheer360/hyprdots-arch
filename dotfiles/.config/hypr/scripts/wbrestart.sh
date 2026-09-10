#!/usr/bin/env bash
pkill waybar 2>/dev/null || true
waybar >/dev/null 2>&1 &
if pgrep -x swaync >/dev/null 2>&1; then
    swaync-client -R 2>/dev/null || true
    swaync-client -rs 2>/dev/null || true
else
    swaync >/dev/null 2>&1 &
fi
