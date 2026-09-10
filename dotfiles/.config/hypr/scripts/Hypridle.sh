#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Control hypridle status and toggle

PROCESS="hypridle"

if [[ "$1" == "status" ]]; then
    if pgrep -x "$PROCESS" >/dev/null; then
        echo '{"text": "RUNNING", "class": "active", "tooltip": "idle_inhibitor NOT ACTIVE\nLeft Click: Activate\nRight Click: Lock Screen"}'
    else
        echo '{"text": "NOT RUNNING", "class": "notactive", "tooltip": "idle_inhibitor is ACTIVE\nLeft Click: Deactivate\nRight Click: Lock Screen"}'
    fi
elif [[ "$1" == "toggle" ]]; then
    if pgrep -x "$PROCESS" >/dev/null; then
        pkill "$PROCESS"
    else
        "$PROCESS" >/dev/null 2>&1 &
        disown
    fi
else
    echo "Usage: $0 {status|toggle}"
    exit 0
fi
