#!/usr/bin/env bash
# 03-packages.sh - Install official and AUR packages, followed by a binary sweep

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 03: Installing Official and AUR Packages"

check_and_clear_pacman_lock

INSTALL_EXTRAS="${INSTALL_EXTRAS:-1}"
HELPER_CACHE="$HOME/.cache/hyprdots_aur_helper"
if [ -f "$HELPER_CACHE" ] && "$(cat "$HELPER_CACHE")" --version >/dev/null 2>&1; then
    AUR_HELPER=$(cat "$HELPER_CACHE")
elif command -v paru >/dev/null 2>&1 && paru --version >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1 && yay --version >/dev/null 2>&1; then
    AUR_HELPER="yay"
else
    error "No working AUR helper found. Please run 02-paru.sh first."
    exit 1
fi

PACMAN_PKGS=(
    hyprland waybar swaync rofi kitty awww matugen hypridle hyprlock hyprpicker hyprpolkitagent
    hyprland-guiutils cava fastfetch yazi nautilus gvfs mpv btop nvtop
    networkmanager network-manager-applet bluez bluez-utils blueman
    pipewire pipewire-pulse pipewire-alsa wireplumber libpulse pamixer pavucontrol playerctl
    brightnessctl power-profiles-daemon pacman-contrib
    grim slurp wl-clipboard xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xwayland
    jq curl rfkill util-linux greetd libnotify
    zsh ttf-jetbrains-mono-nerd adwaita-fonts adwaita-cursors adwaita-icon-theme
    gtk3 gtk4 libadwaita polkit xdg-utils xdg-user-dirs desktop-file-utils
    base-devel git sudo which findutils coreutils
)

# Hardware / Hypervisor driver auto-detection
VIRT=$(detect_hypervisor)
case "$VIRT" in
    vmware)
        info "VMware detected: Adding open-vm-tools and xf86-video-vmware to packages..."
        PACMAN_PKGS+=(open-vm-tools xf86-video-vmware)
        ;;
    oracle)
        info "VirtualBox detected: Adding virtualbox-guest-utils to packages..."
        PACMAN_PKGS+=(virtualbox-guest-utils)
        ;;
    kvm|qemu)
        info "KVM/QEMU detected: Adding qemu-guest-agent to packages..."
        PACMAN_PKGS+=(qemu-guest-agent)
        ;;
esac

AUR_REQUIRED=(
    wlogout
    colloid-icon-theme-git
)

AUR_EXTRAS=(
    zen-browser-bin
    vesktop-bin
)

# Check if greetd-tuigreet or tuigreet is in official repositories
if pacman -Si greetd-tuigreet >/dev/null 2>&1; then
    info "greetd-tuigreet found in official repos; adding to pacman package list."
    PACMAN_PKGS+=(greetd-tuigreet)
elif pacman -Si tuigreet >/dev/null 2>&1; then
    info "tuigreet found in official repos; adding to pacman package list."
    PACMAN_PKGS+=(tuigreet)
else
    info "tuigreet not found in official repos; adding to AUR package list."
    AUR_REQUIRED+=(tuigreet)
fi

info "Installing official packages via pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
ok "Official packages installed."

# Unattended flags for AUR helper
if [ "$AUR_HELPER" = "paru" ]; then
    AUR_FLAGS=(--needed --noconfirm --skipreview)
else
    AUR_FLAGS=(--needed --noconfirm --answerclean None --answerdiff None --answeredit None)
fi

info "Installing required AUR packages via $AUR_HELPER..."
"$AUR_HELPER" -S "${AUR_FLAGS[@]}" "${AUR_REQUIRED[@]}"
ok "Required AUR packages installed."

if [ "$INSTALL_EXTRAS" = "1" ]; then
    info "Installing optional extra packages (${AUR_EXTRAS[*]})..."
    "$AUR_HELPER" -S "${AUR_FLAGS[@]}" "${AUR_EXTRAS[@]}"
    ok "Extra AUR packages installed."
else
    info "Skipping extra AUR packages (--no-extras specified or declined in setup)."
fi

banner "Post-Install Binary Sweep"
MISSING=()
CHECK_BINARIES=(
    Hyprland start-hyprland hyprctl hypridle hyprlock hyprpicker
    waybar swaync swaync-client rofi kitty awww awww-daemon
    matugen cava fastfetch yazi nautilus mpv grim slurp
    wl-copy pamixer pactl wpctl playerctl brightnessctl rfkill
    checkupdates wlogout nm-applet blueman-applet notify-send
    greetd tuigreet zsh jq curl btop nvtop fc-match
)

for bin in "${CHECK_BINARIES[@]}"; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        error "Binary check failed: '$bin' is missing from PATH."
        MISSING+=("$bin")
    fi
done

# Check hyprpolkitagent
if [ ! -f /usr/lib/hyprpolkitagent ] && ! systemctl --user cat hyprpolkitagent >/dev/null 2>&1; then
    error "hyprpolkitagent binary/service not found."
    MISSING+=("hyprpolkitagent")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    error "The following required binaries are missing: ${MISSING[*]}"
    exit 1
fi

ok "All ${#CHECK_BINARIES[@]} required binaries and services verified successfully."
