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
