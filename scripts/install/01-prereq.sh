#!/usr/bin/env bash
# 01-prereq.sh - Install core prerequisites and perform system upgrade

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 01: System Upgrade and Core Prerequisites"

info "Updating pacman repositories and installing base prerequisites (base-devel, git, sudo)..."
sudo pacman -Syu --needed --noconfirm base-devel git sudo

ok "Core prerequisites installed and system upgraded."
