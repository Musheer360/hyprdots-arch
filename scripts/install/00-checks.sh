#!/usr/bin/env bash
# 00-checks.sh - Pre-installation system checks

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 00: Pre-installation System Checks"

# 0. Pacman Lock Check
info "Checking pacman lock status..."
check_and_clear_pacman_lock

# 1. Arch Linux check
info "Checking Linux distribution..."
if [ ! -f /etc/arch-release ]; then
    error "This installer only supports Arch Linux and Arch-based distributions."
    exit 1
fi
ok "Arch Linux detected."

# 2. Root check
info "Checking user privileges..."
if [ "$(id -u)" -eq 0 ]; then
    error "Please do not run this installer directly as root. Run as a normal user with sudo privileges."
    exit 1
fi
ok "Running as non-root user: $USER"

# 3. Sudo validation
info "Validating sudo access..."
if ! sudo -v; then
    error "User $USER does not have sudo privileges."
    echo "To fix, switch to root ('su -') and run:"
    echo "  usermod -aG wheel $USER"
    echo "  EDITOR=nano visudo   # ensure '%wheel ALL=(ALL:ALL) ALL' is uncommented"
    exit 1
fi
ok "Sudo access verified."

# 4. Network check (multi-target fallback)
info "Checking internet connectivity..."
ONLINE=0
for target in "https://archlinux.org" "https://cloudflare.com" "https://google.com" "https://1.1.1.1"; do
    if curl -fsSL -m 5 "$target" >/dev/null 2>&1; then
        ONLINE=1
        break
    fi
done
if [ "$ONLINE" -ne 1 ] && ! ping -c 1 -W 5 archlinux.org >/dev/null 2>&1 && ! ping -c 1 -W 5 1.1.1.1 >/dev/null 2>&1; then
    error "No internet connectivity detected. Please configure network interfaces or NetworkManager."
    exit 1
fi
ok "Internet connection active."

# 5. Disk space check
info "Checking available disk space..."
FREE_KB=$(df -k / | awk 'NR==2 {print $4}')
# 5GB = 5242880 KB
if [ "$FREE_KB" -lt 5242880 ]; then
    warn "Less than 5GB of free space available on root filesystem ($(( FREE_KB / 1024 )) MB free)."
else
    ok "Sufficient disk space available ($(( FREE_KB / 1024 / 1024 )) GB free)."
fi

# 6. Systemd detection
info "Checking init system..."
if pidof systemd >/dev/null 2>&1 || [ -d /run/systemd/system ]; then
    ok "Systemd is running as init system."
else
    warn "Systemd is not running as PID 1 (container / chroot environment detected). Service enablement steps will be limited."
fi

# 7. Virtualization / Hypervisor detection
VIRT=$(detect_hypervisor)
case "$VIRT" in
    vmware)
        ok "VMware hypervisor detected. VMware guest tools and display driver will be enabled."
        ;;
    oracle)
        ok "VirtualBox hypervisor detected. VirtualBox guest utils will be enabled."
        ;;
    kvm|qemu)
        ok "KVM/QEMU hypervisor detected."
        ;;
    wsl)
        warn "WSL environment detected."
        ;;
    *)
        ok "Bare-metal or standard hardware detected."
        ;;
esac

ok "Pre-installation checks completed successfully."
