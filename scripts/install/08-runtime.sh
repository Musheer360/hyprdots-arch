#!/usr/bin/env bash
# 08-runtime.sh - Wallpapers, runtime symlinks, and initial theme generation

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 08: Wallpapers, Runtime Symlinks & Initial Matugen Run"

# 1. Wallpapers
info "Copying wallpapers to ~/Pictures/wallpapers..."
mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots"
cp -an "$REPO_ROOT/wallpapers/." "$HOME/Pictures/wallpapers/"
ok "Wallpapers installed."

# 2. Runtime symlinks
info "Creating runtime symlinks..."
mkdir -p "$HOME/.config/waybar" "$HOME/.config/hypr"
ln -sfn "$HOME/.config/waybar/configs/[TOP] 0-Ja-0 Been modified" "$HOME/.config/waybar/config"
ln -sfn "$HOME/.config/waybar/style/islands.css" "$HOME/.config/waybar/style.css"
ln -sfn "$HOME/Pictures/wallpapers/37.jpg" "$HOME/.config/hypr/current_wallpaper"
ok "Waybar config/style and Hyprland current_wallpaper symlinks created."

# 3. Seed keyboard layout
mkdir -p "$HOME/.cache"
if [ ! -f "$HOME/.cache/kb_layout" ]; then
    echo "us" > "$HOME/.cache/kb_layout"
    info "Seeded ~/.cache/kb_layout with 'us'."
fi

# 4. Create matugen target directories
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/vesktop/themes"

# 5. First Matugen run
info "Running initial theme generation via Matugen on 37.jpg..."
TMP_MATUGEN="/tmp/matugen-firstrun-$$.toml"

# Build temp config with hooks removed and set=false
python3 -c '
import re, sys
src = sys.argv[1]
dst = sys.argv[2]
with open(src, "r") as f:
    text = f.read()
# Remove post_hook lines
text = re.sub(r"post_hook\s*=\s*[^\n]*\n", "", text)
# Change set = true to set = false
text = re.sub(r"set\s*=\s*true", "set = false", text)
with open(dst, "w") as f:
    f.write(text)
' "$HOME/.config/matugen/config.toml" "$TMP_MATUGEN"

# Execute matugen with config flag
if matugen --help 2>&1 | grep -q -- "--config"; then
    matugen --source-color-index 0 --config "$TMP_MATUGEN" image "$HOME/Pictures/wallpapers/37.jpg"
elif matugen --help 2>&1 | grep -q -- "-c"; then
    matugen --source-color-index 0 -c "$TMP_MATUGEN" image "$HOME/Pictures/wallpapers/37.jpg"
else
    matugen --source-color-index 0 image "$HOME/Pictures/wallpapers/37.jpg"
fi

rm -f "$TMP_MATUGEN"

# Verify outputs
OUTPUTS=(
    "$HOME/.config/hypr/colors.lua"
    "$HOME/.config/hypr/colors.conf"
    "$HOME/.config/waybar/colors.css"
    "$HOME/.config/kitty/colors.conf"
    "$HOME/.config/rofi/colors.rasi"
    "$HOME/.config/cava/config"
    "$HOME/.config/gtk-3.0/colors.css"
    "$HOME/.config/gtk-4.0/colors.css"
    "$HOME/.config/vesktop/themes/matugen.css"
)

MISSING_OUTPUTS=0
for out in "${OUTPUTS[@]}"; do
    if [ ! -s "$out" ]; then
        error "Matugen output missing or empty: $out"
        MISSING_OUTPUTS=$((MISSING_OUTPUTS + 1))
    fi
done

if [ "$MISSING_OUTPUTS" -gt 0 ]; then
    error "Initial Matugen generation failed to generate all color files."
    exit 1
fi

# Verify colors.lua syntax if lua is available
if command -v lua >/dev/null 2>&1; then
    lua -e "assert(loadfile('$HOME/.config/hypr/colors.lua'))()"
    ok "colors.lua parsed and validated via Lua."
fi

ok "Initial theme generation completed successfully."
