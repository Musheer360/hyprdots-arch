#!/usr/bin/env bash
# 06-dots.sh - Deploy dotfiles with safe backups

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 06: Deploying Dotfiles"

BACKUP_DIR=$(create_backup_dir)
TARGETS=(hypr waybar rofi kitty cava matugen swaync wlogout fastfetch xdg-desktop-portal)
BACKED_UP=0

for target in "${TARGETS[@]}"; do
    SRC_PATH="$HOME/.config/$target"
    if [ -e "$SRC_PATH" ] && [ ! -L "$SRC_PATH" ]; then
        mkdir -p "$BACKUP_DIR/.config"
        cp -a "$SRC_PATH" "$BACKUP_DIR/.config/$target"
        BACKED_UP=1
    fi
done

if [ "$BACKED_UP" -eq 1 ]; then
    ok "Pre-existing configurations backed up to: $BACKUP_DIR"
fi

# Deploy dotfiles
info "Copying dotfiles to ~/.config..."
mkdir -p "$HOME/.config"
cp -a "$REPO_ROOT/dotfiles/.config/." "$HOME/.config/"

# Ensure script permissions
info "Setting executable permissions on scripts..."
chmod +x "$HOME"/.config/hypr/scripts/*.sh

# GTK colors.css @import (append if missing)
for gtk_ver in gtk-3.0 gtk-4.0; do
    GTK_DIR="$HOME/.config/$gtk_ver"
    mkdir -p "$GTK_DIR"
    GTK_CSS="$GTK_DIR/gtk.css"
    if [ ! -f "$GTK_CSS" ]; then
        echo "@import 'colors.css';" > "$GTK_CSS"
        info "Created $GTK_CSS with @import 'colors.css';"
    elif ! grep -q "colors.css" "$GTK_CSS"; then
        sed -i '1i @import '\''colors.css'\'';' "$GTK_CSS"
        info "Appended @import 'colors.css' to $GTK_CSS"
    fi
done

# Portal configuration
mkdir -p "$HOME/.config/xdg-desktop-portal"
cat << 'EOF' > "$HOME/.config/xdg-desktop-portal/portals.conf"
[preferred]
default=hyprland
EOF

ok "Dotfiles deployed and verified."
