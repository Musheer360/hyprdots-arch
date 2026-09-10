#!/usr/bin/env bash
# 00-checks.sh - Pre-installation system checks

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 00: Pre-installation System Checks"

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
    error "User $USER does not have sudo privileges. Please add $USER to the wheel group or configure sudoers."
    exit 1
fi
ok "Sudo access verified."

# 4. Network check
info "Checking internet connectivity..."
if ! curl -fsSL -m 5 "https://archlinux.org" >/dev/null 2>&1 && ! ping -c 1 -W 5 archlinux.org >/dev/null 2>&1; then
    error "No internet connectivity detected. Please check your network connection."
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

# 7. WSL / VM detection
if grep -qi microsoft /proc/version 2>/dev/null; then
    warn "WSL environment detected. Target is a real Arch Linux machine; continuing for testing."
fi

ok "Pre-installation checks completed successfully."
