#!/usr/bin/env bash
# install.sh - One-click Arch + Hyprland rice installer
# Modernized hyprdots-arch for Arch Linux

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/hyprdots-install-$(date +'%Y%m%d-%H%M%S').log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Track background processes and temporary files
SUDO_KEEP_ALIVE_PID=""
SUDOERS_TEMP="/etc/sudoers.d/99-hyprdots-installer"

cleanup() {
    local exit_code="${1:-$?}"
    # Terminate sudo keep-alive daemon
    if [ -n "${SUDO_KEEP_ALIVE_PID:-}" ] && kill -0 "$SUDO_KEEP_ALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
    fi
    # Remove temporary sudoers drop-in
    if [ -f "$SUDOERS_TEMP" ]; then
        sudo rm -f "$SUDOERS_TEMP" 2>/dev/null || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

error_handler() {
    local exit_code="$1"
    local line_no="$2"
    local last_command="$3"
    echo ""
    printf "\033[0;31m[FATAL] Installation failed at line %s with exit code %s\033[0m\n" "$line_no" "$exit_code" >&2
    printf "\033[0;31m        Failing command: %s\033[0m\n" "$last_command" >&2
    printf "\033[0;33m        Detailed log available at: %s\033[0m\n" "$LOG_FILE" >&2
    cleanup "$exit_code"
}
trap 'error_handler $? $LINENO "$BASH_COMMAND"' ERR

show_help() {
    cat << 'EOF'
hyprdots-arch - One-click Arch + Hyprland Rice Installer

Usage: ./install.sh [OPTIONS]

Options:
  --no-extras       Skip installation of extra apps (Zen Browser, Vesktop)
  --dots-only       Only deploy dotfiles, themes, wallpapers, and run verify
  --packages-only   Only install prerequisites, paru, packages, and enable services
  --skip-greetd     Skip greetd login manager setup
  -h, --help        Show this help message and exit

Environment Variables:
  NONINTERACTIVE=1  Run without prompting, assuming default answers for automated installs
EOF
}

# Parse options
INSTALL_EXTRAS=1
DOTS_ONLY=0
PACKAGES_ONLY=0
CONFIGURE_GREETD=1
CHANGE_SHELL=1

NO_EXTRAS_PASSED=0
SKIP_GREETD_PASSED=0

while [ $# -gt 0 ]; do
    case "$1" in
        --no-extras)
            INSTALL_EXTRAS=0
            NO_EXTRAS_PASSED=1
            shift
            ;;
        --dots-only)
            DOTS_ONLY=1
            shift
            ;;
        --packages-only)
            PACKAGES_ONLY=1
            shift
            ;;
        --skip-greetd)
            CONFIGURE_GREETD=0
            SKIP_GREETD_PASSED=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Ensure not running directly as root
if [ "$(id -u)" -eq 0 ]; then
    printf "\033[0;31mERROR: Do not run this script as root directly.\033[0m\n" >&2
    printf "Please run as your regular user with sudo privileges (e.g. ./install.sh).\n" >&2
    exit 1
fi

cat << 'EOF'
    __                              __      __               ___               __  
   / /_  __  ______  ________  ____/ /___  / /______        /   |  ___________/ /_ 
  / __ \/ / / / __ \/ ___/ _ \/ __  / __ \/ __/ ___/______ / /| | / ___/ ___/ __ \
 / / / / /_/ / /_/ / /  /  __/ /_/ / /_/ / /_(__  )/_____// ___ |/ /  / /__/ / / /
/_/ /_/\__, / .___/_/   \___/\__,_/\____/\__/____/       /_/  |_/_/   \___/_/ /_/ 
      /____/_/                                                                    
EOF
echo "========================================================================="
echo "  One-click Arch + Hyprland Rice Installer (hyprdots-arch)"
echo "  Log file: $LOG_FILE"
echo "========================================================================="

# Upfront Sudo Authentication & Keep-Alive Daemon
printf "\n\033[1;36m[AUTHENTICATION]\033[0m Requesting administrative privileges (sudo)...\n"
if ! sudo -v; then
    printf "\033[0;31m[ERR ] Sudo authentication failed. Ensure %s has sudo permissions.\033[0m\n" "$USER" >&2
    exit 1
fi

# Background keep-alive loop to maintain sudo credentials throughout installation
while true; do
    sudo -n true
    sleep 45
    kill -0 "$$" || exit
done 2>/dev/null &
SUDO_KEEP_ALIVE_PID=$!

# Temporary sudoers drop-in to prevent makepkg/AUR pacman prompts
if echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$SUDOERS_TEMP" >/dev/null; then
    if sudo visudo -cf "$SUDOERS_TEMP" >/dev/null 2>&1; then
        sudo chmod 0440 "$SUDOERS_TEMP"
    else
        sudo rm -f "$SUDOERS_TEMP" >/dev/null 2>&1 || true
    fi
fi

# Upfront Questionnaire (Gather all user preferences in the first 5 seconds)
if [ "${NONINTERACTIVE:-0}" != "1" ] && [ "$DOTS_ONLY" -ne 1 ]; then
    echo ""
    printf "\033[1;34m=========================================================================\033[0m\n"
    printf "\033[1;33m  Quick Setup Configuration (All questions upfront - 5 seconds)\033[0m\n"
    printf "  Press ENTER to accept the defaults [Y], or type 'n' to decline.\n"
    printf "\033[1;34m=========================================================================\033[0m\n"

    # 1. Extras (Zen Browser, Vesktop Discord)
    if [ "$NO_EXTRAS_PASSED" -eq 0 ]; then
        if [ -e /dev/tty ]; then
            read -rp "  [1/3] Install extra applications (Zen Browser & Vesktop Discord)? [Y/n]: " ans_extras </dev/tty || ans_extras="Y"
        else
            read -rp "  [1/3] Install extra applications (Zen Browser & Vesktop Discord)? [Y/n]: " ans_extras || ans_extras="Y"
        fi
        case "${ans_extras:-Y}" in
            [yY][eE][sS]|[yY]) INSTALL_EXTRAS=1 ;;
            *) INSTALL_EXTRAS=0 ;;
        esac
    fi

    # 2. Change Shell to Zsh
    if [ -e /dev/tty ]; then
        read -rp "  [2/3] Change default login shell to Zsh? [Y/n]: " ans_shell </dev/tty || ans_shell="Y"
    else
        read -rp "  [2/3] Change default login shell to Zsh? [Y/n]: " ans_shell || ans_shell="Y"
    fi
    case "${ans_shell:-Y}" in
        [yY][eE][sS]|[yY]) CHANGE_SHELL=1 ;;
        *) CHANGE_SHELL=0 ;;
    esac

    # 3. Greetd + Tuigreet Display Manager
    if [ "$SKIP_GREETD_PASSED" -eq 0 ]; then
        if [ -e /dev/tty ]; then
            read -rp "  [3/3] Enable greetd + tuigreet display/login manager? [Y/n]: " ans_greetd </dev/tty || ans_greetd="Y"
        else
            read -rp "  [3/3] Enable greetd + tuigreet display/login manager? [Y/n]: " ans_greetd || ans_greetd="Y"
        fi
        case "${ans_greetd:-Y}" in
            [yY][eE][sS]|[yY]) CONFIGURE_GREETD=1 ;;
            *) CONFIGURE_GREETD=0 ;;
        esac
    else
        CONFIGURE_GREETD=0
    fi

    printf "\033[1;34m=========================================================================\033[0m\n"
    printf "\033[1;32m  All inputs configured! Full installation running 100%% unattended.\033[0m\n"
    printf "\033[1;34m=========================================================================\033[0m\n"
    echo ""
fi

# Export all configuration options and turn on non-interactive mode for child scripts
export INSTALL_EXTRAS
export CHANGE_SHELL
export CONFIGURE_GREETD
export SKIP_GREETD="$(( 1 - CONFIGURE_GREETD ))"
export NONINTERACTIVE=1

# Step 00: Pre-checks
"$SCRIPT_DIR/scripts/install/00-checks.sh"

if [ "$DOTS_ONLY" -eq 1 ]; then
    "$SCRIPT_DIR/scripts/install/06-dots.sh"
    "$SCRIPT_DIR/scripts/install/07-theming.sh"
    "$SCRIPT_DIR/scripts/install/08-runtime.sh"
    "$SCRIPT_DIR/scripts/install/10-verify.sh"
elif [ "$PACKAGES_ONLY" -eq 1 ]; then
    "$SCRIPT_DIR/scripts/install/01-prereq.sh"
    "$SCRIPT_DIR/scripts/install/02-paru.sh"
    "$SCRIPT_DIR/scripts/install/03-packages.sh"
    "$SCRIPT_DIR/scripts/install/04-services.sh"
else
    # Full Installation
    "$SCRIPT_DIR/scripts/install/01-prereq.sh"
    "$SCRIPT_DIR/scripts/install/02-paru.sh"
    "$SCRIPT_DIR/scripts/install/03-packages.sh"
    "$SCRIPT_DIR/scripts/install/04-services.sh"
    "$SCRIPT_DIR/scripts/install/05-shell.sh"
    "$SCRIPT_DIR/scripts/install/06-dots.sh"
    "$SCRIPT_DIR/scripts/install/07-theming.sh"
    "$SCRIPT_DIR/scripts/install/08-runtime.sh"
    "$SCRIPT_DIR/scripts/install/09-greetd.sh"
    "$SCRIPT_DIR/scripts/install/10-verify.sh"
fi

echo ""
echo "========================================================================="
printf "\033[0;32m  Installation completed successfully!\033[0m\n"
echo "========================================================================="
echo "  To start your session:"
echo "    - Reboot your system and log in via tuigreet (greetd), OR"
echo "    - Run 'start-hyprland' from a TTY"
echo ""
echo "  Useful keybindings:"
echo "    - SUPER + Return    : Launch Kitty terminal"
echo "    - SUPER + D         : Application Launcher (Rofi)"
echo "    - SUPER + W         : Wallpaper Selector (Matugen dynamic themes)"
echo "    - SUPER + E         : File Manager (Nautilus)"
echo "    - SUPER + SHIFT + S : Screenshot (Grim + Slurp)"
echo "    - SUPER + L         : Lock Screen (Hyprlock)"
echo "    - CTRL + ALT + Del  : Exit Hyprland"
echo "========================================================================="
