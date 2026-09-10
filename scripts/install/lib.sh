#!/usr/bin/env bash
# lib.sh - Common functions and variables for hyprdots-arch installer

set -Eeuo pipefail

USER="${USER:-$(id -un)}"
export USER

# Colors
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

info() {
    printf "${C_CYAN}[INFO]${C_RESET} %s\n" "$*"
}

ok() {
    printf "${C_GREEN}[ OK ]${C_RESET} %s\n" "$*"
}

warn() {
    printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"
}

error() {
    printf "${C_RED}[ERR ]${C_RESET} %s\n" "$*" >&2
}

banner() {
    local title="$1"
    echo ""
    printf "${C_BLUE}${C_BOLD}======================================================${C_RESET}\n"
    printf "${C_MAGENTA}${C_BOLD}  %s${C_RESET}\n" "$title"
    printf "${C_BLUE}${C_BOLD}======================================================${C_RESET}\n"
    echo ""
}

confirm() {
    local prompt="$1"
    local default="${2:-N}"
    
    if [ "${NONINTERACTIVE:-0}" = "1" ]; then
        return 0
    fi

    if [ "$default" = "Y" ]; then
        local yn_hint="[Y/n]"
    else
        local yn_hint="[y/N]"
    fi

    printf "${C_YELLOW}%s %s: ${C_RESET}" "$prompt" "$yn_hint"
    read -r response
    response="${response:-$default}"
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

need_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error "Required command '$cmd' is not installed or not in PATH."
        return 1
    fi
    return 0
}

create_backup_dir() {
    local ts
    ts=$(date +'%Y%m%d-%H%M%S')
    local bdir="$HOME/.hyprdots-backup-$ts"
    echo "$bdir"
}

retry_cmd() {
    local max_attempts="${1:-3}"
    local delay="${2:-2}"
    shift 2
    local attempt=1
    until "$@"; do
        if [ "$attempt" -ge "$max_attempts" ]; then
            error "Command '$*' failed after $max_attempts attempts."
            return 1
        fi
        warn "Command '$*' failed (attempt $attempt/$max_attempts). Retrying in ${delay}s..."
        sleep "$delay"
        attempt=$((attempt + 1))
    done
    return 0
}

check_and_clear_pacman_lock() {
    if [ -f /var/lib/pacman/db.lck ]; then
        if ! pgrep -x pacman >/dev/null 2>&1 && ! pgrep -x paru >/dev/null 2>&1 && ! pgrep -x yay >/dev/null 2>&1; then
            warn "Found stale pacman lock file (/var/lib/pacman/db.lck). Removing..."
            sudo rm -f /var/lib/pacman/db.lck
            ok "Stale pacman lock removed."
        else
            error "Another pacman/AUR package manager process is currently running. Please wait for it to finish."
            exit 1
        fi
    fi
}

detect_hypervisor() {
    local virt="none"
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        virt=$(systemd-detect-virt 2>/dev/null || echo "none")
    fi
    if [ "$virt" = "none" ]; then
        if grep -qi vmware /sys/class/dmi/id/product_name 2>/dev/null || grep -qi vmware /sys/class/dmi/id/sys_vendor 2>/dev/null; then
            virt="vmware"
        elif grep -qi virtualbox /sys/class/dmi/id/product_name 2>/dev/null || grep -qi innotek /sys/class/dmi/id/sys_vendor 2>/dev/null; then
            virt="oracle"
        elif grep -qi qemu /sys/class/dmi/id/product_name 2>/dev/null || grep -qi kvm /sys/class/dmi/id/sys_vendor 2>/dev/null; then
            virt="kvm"
        elif grep -qi microsoft /proc/version 2>/dev/null; then
            virt="wsl"
        fi
    fi
    echo "$virt"
}

