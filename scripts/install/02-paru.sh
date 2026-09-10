#!/usr/bin/env bash
# 02-paru.sh - Bootstrap AUR helper (paru-bin / yay-bin fallback)

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 02: Bootstrap AUR Helper"

mkdir -p "$HOME/.cache"
HELPER_CACHE="$HOME/.cache/hyprdots_aur_helper"

if command -v paru >/dev/null 2>&1 && paru --version >/dev/null 2>&1; then
    ok "paru is already installed and functional."
    echo "paru" > "$HELPER_CACHE"
    exit 0
fi

if command -v yay >/dev/null 2>&1 && yay --version >/dev/null 2>&1; then
    ok "yay is already installed and functional. Using yay as AUR helper."
    echo "yay" > "$HELPER_CACHE"
    exit 0
fi

info "Attempting to bootstrap paru-bin from AUR..."
BUILD_DIR="/tmp/paru-bin-$$"
rm -rf "$BUILD_DIR"
git clone https://aur.archlinux.org/paru-bin.git "$BUILD_DIR"

(
    cd "$BUILD_DIR"
    makepkg -si --noconfirm --needed || true
)
rm -rf "$BUILD_DIR"

if command -v paru >/dev/null 2>&1 && paru --version >/dev/null 2>&1; then
    ok "paru-bin successfully installed and working."
    echo "paru" > "$HELPER_CACHE"
    exit 0
fi

warn "paru-bin is not functional (due to libalpm ABI update). Bootstrapping yay-bin as resilient AUR helper..."
BUILD_DIR="/tmp/yay-bin-$$"
rm -rf "$BUILD_DIR"
git clone https://aur.archlinux.org/yay-bin.git "$BUILD_DIR"

(
    cd "$BUILD_DIR"
    makepkg -si --noconfirm --needed
)
rm -rf "$BUILD_DIR"

if command -v yay >/dev/null 2>&1 && yay --version >/dev/null 2>&1; then
    ok "yay-bin successfully installed and working."
    echo "yay" > "$HELPER_CACHE"
    exit 0
else
    error "Failed to bootstrap an operational AUR helper."
    exit 1
fi
