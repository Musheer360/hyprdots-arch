#!/usr/bin/env bash
# 04-services.sh - Enable system and user services

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 04: Enabling System Services"

if pidof systemd >/dev/null 2>&1 || [ -d /run/systemd/system ]; then
    info "Enabling system services (NetworkManager, bluetooth)..."
    sudo systemctl enable NetworkManager bluetooth || warn "Could not enable NetworkManager/bluetooth"
    sudo systemctl start NetworkManager bluetooth 2>/dev/null || warn "Could not start NetworkManager/bluetooth (may already be running or in container)"

    # Hypervisor guest services
    if systemctl list-unit-files vmtoolsd.service >/dev/null 2>&1; then
        info "Enabling VMware Tools service (vmtoolsd)..."
        sudo systemctl enable --now vmtoolsd.service || warn "Could not enable vmtoolsd.service"
    fi
    if systemctl list-unit-files vboxservice.service >/dev/null 2>&1; then
        info "Enabling VirtualBox Guest service (vboxservice)..."
        sudo systemctl enable --now vboxservice.service || warn "Could not enable vboxservice.service"
    fi
    if systemctl list-unit-files qemu-guest-agent.service >/dev/null 2>&1; then
        info "Enabling QEMU Guest Agent (qemu-guest-agent)..."
        sudo systemctl enable --now qemu-guest-agent.service || warn "Could not enable qemu-guest-agent.service"
    fi

    info "Enabling audio user services (pipewire, pipewire-pulse, wireplumber)..."
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || warn "Could not enable pipewire user sockets"
    systemctl --user start pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || warn "Could not start pipewire user sockets (no active user session)"
    ok "Services enabled."
else
    warn "Systemd is not running as PID 1. Skipping active service startup; will configure greetd statically in step 09."
fi
