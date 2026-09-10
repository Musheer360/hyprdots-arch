#!/usr/bin/env bash
# 09-greetd.sh - Configure greetd with tuigreet session manager

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 09: Configuring Login Manager (greetd + tuigreet)"

CONFIGURE_GREETD="${CONFIGURE_GREETD:-1}"
SKIP_GREETD="${SKIP_GREETD:-0}"

if [ "$SKIP_GREETD" = "1" ] || [ "$CONFIGURE_GREETD" != "1" ]; then
    info "Skipping greetd configuration (disabled by flag or upfront selection)."
    exit 0
fi

info "Writing /etc/greetd/config.toml..."
sudo mkdir -p /etc/greetd

if [ -f /etc/greetd/config.toml ]; then
    sudo cp /etc/greetd/config.toml "/etc/greetd/config.toml.bak.$(date +'%Y%m%d%H%M%S')"
fi

sudo tee /etc/greetd/config.toml >/dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --cmd start-hyprland"
user = "greeter"
EOF

ok "/etc/greetd/config.toml written."

info "Enabling greetd.service..."
sudo systemctl enable greetd.service || warn "Could not enable greetd.service"
ok "greetd.service enabled."
