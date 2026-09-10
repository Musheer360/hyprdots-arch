#!/usr/bin/env bash
# 07-theming.sh - Configure GTK themes, icons, cursors, and fonts

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 07: Theming and Interface Configuration"

# Detect installed Colloid icon theme variant
COLLOID_THEME="Colloid"
if [ -d /usr/share/icons/Colloid-Dark ]; then
    COLLOID_THEME="Colloid-Dark"
elif [ -d /usr/share/icons/Colloid ]; then
    COLLOID_THEME="Colloid"
elif ls -d /usr/share/icons/*colloid* 2>/dev/null | grep -qi "dark"; then
    COLLOID_THEME="$(ls -d /usr/share/icons/*colloid* 2>/dev/null | grep -i "dark" | head -n1 | xargs -r basename)"
fi
info "Selected icon theme: $COLLOID_THEME"

# Configure via gsettings if available
if command -v gsettings >/dev/null 2>&1; then
    info "Applying GTK settings via gsettings..."
    gsettings set org.gnome.desktop.interface icon-theme "$COLLOID_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    ok "gsettings applied."
else
    warn "gsettings not available; will configure static settings.ini."
fi

# Static ~/.config/gtk-3.0/settings.ini fallback
mkdir -p "$HOME/.config/gtk-3.0"
SETTINGS_INI="$HOME/.config/gtk-3.0/settings.ini"

if [ ! -f "$SETTINGS_INI" ]; then
    cat << EOF > "$SETTINGS_INI"
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=$COLLOID_THEME
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
else
    # Append or update missing keys
    grep -q "gtk-theme-name" "$SETTINGS_INI" || echo "gtk-theme-name=Adwaita" >> "$SETTINGS_INI"
    grep -q "gtk-icon-theme-name" "$SETTINGS_INI" || echo "gtk-icon-theme-name=$COLLOID_THEME" >> "$SETTINGS_INI"
    grep -q "gtk-font-name" "$SETTINGS_INI" || echo "gtk-font-name=Adwaita Sans 11" >> "$SETTINGS_INI"
    grep -q "gtk-cursor-theme-name" "$SETTINGS_INI" || echo "gtk-cursor-theme-name=Adwaita" >> "$SETTINGS_INI"
    grep -q "gtk-cursor-theme-size" "$SETTINGS_INI" || echo "gtk-cursor-theme-size=24" >> "$SETTINGS_INI"
    grep -q "gtk-application-prefer-dark-theme" "$SETTINGS_INI" || echo "gtk-application-prefer-dark-theme=1" >> "$SETTINGS_INI"
fi

ok "GTK theming configured."
