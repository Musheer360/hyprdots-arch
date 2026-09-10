#!/usr/bin/env bash
# 04-services.sh - Enable system and user services

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 04: Enabling System Services"

# 1. Enable base system services (works in chroot and live systems)
info "Enabling system services (NetworkManager, bluetooth)..."
sudo systemctl enable NetworkManager bluetooth 2>/dev/null || warn "Could not enable NetworkManager/bluetooth"

# 2. Hypervisor guest services
for srv in vmtoolsd vboxservice qemu-guest-agent spice-vdagentd; do
    if systemctl list-unit-files "${srv}.service" >/dev/null 2>&1; then
        info "Enabling hypervisor service ${srv}.service..."
        sudo systemctl enable "${srv}.service" 2>/dev/null || warn "Could not enable ${srv}.service"
    fi
done

# 3. Enable audio and polkit user services globally and per-user
info "Enabling audio and polkit user services globally..."
sudo systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service hyprpolkitagent.service 2>/dev/null || true
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

# 4. If systemd is running as PID 1, actively start core services
if pidof systemd >/dev/null 2>&1 || [ -d /run/systemd/system ]; then
    sudo systemctl start NetworkManager bluetooth 2>/dev/null || true
    for srv in vmtoolsd vboxservice qemu-guest-agent spice-vdagentd; do
        if systemctl list-unit-files "${srv}.service" >/dev/null 2>&1; then
            sudo systemctl start "${srv}.service" 2>/dev/null || true
        fi
    done
    systemctl --user start pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
fi

ok "Services enabled."
