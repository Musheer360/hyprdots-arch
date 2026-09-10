#!/usr/bin/env bash
# 10-verify.sh - Self-validation test suite for hyprdots-arch

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 10: Rice Self-Validation Test Suite"

PASSED_CHECKS=0
FAILED_CHECKS=0

check_result() {
    local name="$1"
    local status="$2"
    local details="${3:-}"
    if [ "$status" -eq 0 ]; then
        printf "  %-50s ${C_GREEN}[PASS]${C_RESET}\n" "$name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        printf "  %-50s ${C_RED}[FAIL]${C_RESET} %s\n" "$name" "$details"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 1. Essential Binaries Sweep
BINS=(
    Hyprland start-hyprland hyprctl hypridle hyprlock hyprpicker
    waybar swaync swaync-client rofi kitty awww awww-daemon
    matugen cava fastfetch yazi nautilus mpv grim slurp
    wl-copy pamixer pactl wpctl playerctl brightnessctl rfkill
    checkupdates wlogout greetd tuigreet zsh jq curl btop nvtop fc-match
)
BIN_FAIL=0
for b in "${BINS[@]}"; do
    if ! command -v "$b" >/dev/null 2>&1; then
        BIN_FAIL=1
    fi
done
check_result "Essential Binaries Sweep" $BIN_FAIL "Some required binaries missing from PATH"

# 2. Runtime Symlinks Verification
SYMLINK_FAIL=0
if [ ! -L "$HOME/.config/waybar/config" ] || [ ! -e "$HOME/.config/waybar/config" ]; then
    SYMLINK_FAIL=1
fi
if [ ! -L "$HOME/.config/waybar/style.css" ] || [ ! -e "$HOME/.config/waybar/style.css" ]; then
    SYMLINK_FAIL=1
fi
if [ ! -L "$HOME/.config/hypr/current_wallpaper" ] || [ ! -e "$HOME/.config/hypr/current_wallpaper" ]; then
    SYMLINK_FAIL=1
fi
check_result "Runtime Symlinks (Waybar config/style, wallpaper)" $SYMLINK_FAIL "Broken or missing symlinks"

# 3. Wallpapers in ~/Pictures/wallpapers
WP_COUNT=$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f 2>/dev/null | wc -l)
if [ "$WP_COUNT" -ge 50 ]; then
    check_result "Wallpaper Deployment ($WP_COUNT images)" 0
else
    check_result "Wallpaper Deployment ($WP_COUNT images)" 1 "Expected at least 50 wallpapers"
fi

# 4. Script executable bits & syntax
SCRIPT_FAIL=0
for s in "$HOME"/.config/hypr/scripts/*.sh; do
    if [ ! -x "$s" ]; then
        SCRIPT_FAIL=1
        break
    fi
    if ! bash -n "$s" >/dev/null 2>&1; then
        SCRIPT_FAIL=1
        break
    fi
done
check_result "Hyprland Scripts (+x permissions & bash -n)" $SCRIPT_FAIL "Scripts not executable or syntax error"

# 5. Hyprland Configuration Verification
HYPR_FAIL=0
if command -v Hyprland >/dev/null 2>&1; then
    # Ensure XDG_RUNTIME_DIR is set for verification
    if [ -z "${XDG_RUNTIME_DIR:-}" ] || [ ! -d "${XDG_RUNTIME_DIR:-}" ]; then
        export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
        mkdir -p "$XDG_RUNTIME_DIR"
        chmod 0700 "$XDG_RUNTIME_DIR"
    fi
    # Run Hyprland --verify-config
    VERIFY_OUT=$(Hyprland --verify-config 2>&1 || true)
    # Check if verify reported errors
    if echo "$VERIFY_OUT" | grep -qi "error" && ! echo "$VERIFY_OUT" | grep -qi "0 errors"; then
        HYPR_FAIL=1
        echo "$VERIFY_OUT" | head -n 10
    fi
else
    HYPR_FAIL=1
fi
check_result "Hyprland Configuration (Hyprland --verify-config)" $HYPR_FAIL "Configuration parse errors detected"

# 6. Waybar JSONC and Includes Parse
WAYBAR_FAIL=0
python3 -c '
import json, re, glob, os, sys

def strip_jsonc(text):
    result = []
    in_string = False
    in_single_comment = False
    in_multi_comment = False
    escape = False
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        nxt = text[i+1] if i + 1 < n else ""
        if in_single_comment:
            if c == "\n":
                in_single_comment = False
                result.append(c)
        elif in_multi_comment:
            if c == "*" and nxt == "/":
                in_multi_comment = False
                i += 1
        elif in_string:
            result.append(c)
            if escape:
                escape = False
            elif c == "\\":
                escape = True
            elif c == "\"":
                in_string = False
        else:
            if c == "\"":
                in_string = True
                result.append(c)
            elif c == "/" and nxt == "/":
                in_single_comment = True
                i += 1
            elif c == "/" and nxt == "*":
                in_multi_comment = True
                i += 1
            else:
                result.append(c)
        i += 1
    res_str = "".join(result)
    res_str = re.sub(r",\s*([\]}])", r"\1", res_str)
    return res_str

config_path = os.path.expanduser("~/.config/waybar/config")
if not os.path.exists(config_path):
    sys.exit(1)

with open(config_path) as f:
    raw = f.read()

try:
    parsed = json.loads(strip_jsonc(raw))
except Exception as e:
    print(f"Failed parsing waybar main config: {e}")
    sys.exit(1)

# Check all include files
includes = parsed.get("include", [])
for inc in includes:
    expanded = os.path.expandvars(os.path.expanduser(inc))
    if not os.path.exists(expanded):
        print(f"Missing include file: {expanded}")
        sys.exit(1)
    with open(expanded) as f:
        try:
            s = strip_jsonc(f.read())
            json.loads("{" + s + "}" if not s.strip().startswith("{") else s)
        except Exception as e:
            print(f"Failed parsing include {expanded}: {e}")
            sys.exit(1)

sys.exit(0)
' 2>/dev/null || WAYBAR_FAIL=1
check_result "Waybar JSONC Config & Includes Parse" $WAYBAR_FAIL "Syntax error in Waybar config/includes"

# 7. SwayNC Config Schema Validation
SWAYNC_FAIL=0
python3 -c '
import json, os, sys
cfg_path = os.path.expanduser("~/.config/swaync/config.json")
schema_path = "/etc/xdg/swaync/configSchema.json"

if not os.path.exists(cfg_path):
    sys.exit(1)

with open(cfg_path) as f:
    cfg = json.load(f)

# If schema exists and jsonschema is installed, validate
if os.path.exists(schema_path):
    try:
        import jsonschema
        with open(schema_path) as sf:
            schema = json.load(sf)
        jsonschema.validate(instance=cfg, schema=schema)
    except ImportError:
        pass # jsonschema not installed, pass
    except Exception as e:
        print(f"SwayNC schema validation error: {e}")
        sys.exit(1)

sys.exit(0)
' 2>/dev/null || SWAYNC_FAIL=1
check_result "SwayNC Configuration Validation" $SWAYNC_FAIL "Schema violation or invalid JSON"

# 8. Fastfetch Execution
FF_FAIL=0
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch --config "$HOME/.config/fastfetch/config.jsonc" >/dev/null 2>&1 || FF_FAIL=1
else
    FF_FAIL=1
fi
check_result "Fastfetch Run Test" $FF_FAIL "Fastfetch failed to execute"

# 9. Font Resolution
FONT_FAIL=0
if command -v fc-match >/dev/null 2>&1; then
    MATCH_OUT=$(fc-match "JetBrainsMono Nerd Font" 2>/dev/null || true)
    if ! echo "$MATCH_OUT" | grep -qi "jetbrains"; then
        FONT_FAIL=1
    fi
else
    FONT_FAIL=1
fi
check_result "JetBrainsMono Nerd Font Resolution" $FONT_FAIL "fc-match did not resolve to JetBrainsMono"

# 10. Matugen Color Generation Outputs
MATUGEN_FILES=(
    "$HOME/.config/hypr/colors.lua"
    "$HOME/.config/hypr/colors.conf"
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/kitty/colors.conf"
    "$HOME/.config/rofi/colors.rasi"
    "$HOME/.config/cava/config"
    "$HOME/.config/gtk-3.0/colors.css"
    "$HOME/.config/gtk-4.0/colors.css"
)
MAT_FAIL=0
for mf in "${MATUGEN_FILES[@]}"; do
    if [ ! -s "$mf" ]; then
        MAT_FAIL=1
        break
    fi
done
check_result "Matugen Color Output Files Exist" $MAT_FAIL "One or more color output files missing/empty"

# 11. Wlogout Layout JSON Parsing
WLOGOUT_FAIL=0
python3 -c '
import json, os, sys
layout_path = os.path.expanduser("~/.config/wlogout/layout")
if not os.path.exists(layout_path):
    sys.exit(1)

with open(layout_path) as f:
    text = f.read()

# Layout contains multiple concatenated JSON objects: { ... } { ... }
# Split by }{ or match objects
import re
objs = re.findall(r"\{[^{}]*\}", text, re.DOTALL)
if len(objs) < 6:
    sys.exit(1)

for o in objs:
    json.loads(o)

sys.exit(0)
' 2>/dev/null || WLOGOUT_FAIL=1
check_result "wlogout Layout Format" $WLOGOUT_FAIL "Invalid wlogout layout syntax"

# 12. Greetd Config Existence
GREETD_FAIL=0
if [ ! -f /etc/greetd/config.toml ]; then
    GREETD_FAIL=1
fi
check_result "greetd Configuration (/etc/greetd/config.toml)" $GREETD_FAIL "File missing"

# 13. Cava Audio Backend Configuration
CAVA_FAIL=0
if grep -q "^; method = pulse" "$HOME/.config/cava/config" && grep -q "^ method = pipewire" "$HOME/.config/cava/config"; then
    CAVA_FAIL=0
else
    CAVA_FAIL=1
fi
check_result "Cava Input Configuration (Pipewire Active)" $CAVA_FAIL "Pulse/Pipewire configuration incorrect"

echo ""
printf "${C_BOLD}Verification Summary: %d Passed, %d Failed${C_RESET}\n" "$PASSED_CHECKS" "$FAILED_CHECKS"
echo ""

if [ "$FAILED_CHECKS" -gt 0 ]; then
    error "Self-validation failed with $FAILED_CHECKS failure(s)."
    exit 1
fi

ok "All rice self-validation checks passed successfully!"
