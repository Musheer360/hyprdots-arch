#!/usr/bin/env bash
# 01-prereq.sh - Install core prerequisites and perform system upgrade

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 01: System Upgrade and Core Prerequisites"

# 1. Clear any stale lock
check_and_clear_pacman_lock

# 2. Keyring verification & initialization
if [ ! -d /etc/pacman.d/gnupg ] || { [ ! -f /etc/pacman.d/gnupg/pubring.gpg ] && [ ! -f /etc/pacman.d/gnupg/pubring.kbx ]; }; then
    info "Initializing and populating pacman keyring..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux || true
fi

# 3. Pacman configuration optimizations (ParallelDownloads & Color)
if [ -f /etc/pacman.conf ]; then
    info "Optimizing pacman configuration..."
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf 2>/dev/null || true
    fi
fi

# 4. Refresh keyring first to avoid signature verification failures on older images
info "Syncing archlinux-keyring to prevent package signature issues..."
sudo pacman -Sy --needed --noconfirm archlinux-keyring || warn "Keyring pre-sync emitted warnings, continuing with system upgrade..."

# 5. Full system upgrade and core build tools
info "Updating pacman repositories and installing base prerequisites (base-devel, git, sudo, curl, which)..."
sudo pacman -Su --needed --noconfirm base-devel git sudo curl which

ok "Core prerequisites installed and system upgraded."
