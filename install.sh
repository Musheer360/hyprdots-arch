#!/usr/bin/env bash
# install.sh - One-click Arch + Hyprland rice installer
# Modernized hyprdots-arch for Arch Linux

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/hyprdots-install-$(date +'%Y%m%d-%H%M%S').log"
exec > >(tee -a "$LOG_FILE") 2>&1

error_handler() {
    local exit_code="$1"
    local line_no="$2"
    local last_command="$3"
    echo ""
    printf "\033[0;31m[FATAL] Installation failed at line %s with exit code %s\033[0m\n" "$line_no" "$exit_code" >&2
    printf "\033[0;31m        Failing command: %s\033[0m\n" "$last_command" >&2
    printf "\033[0;33m        Detailed log available at: %s\033[0m\n" "$LOG_FILE" >&2
    exit "$exit_code"
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
SKIP_GREETD=0

while [ $# -gt 0 ]; do
    case "$1" in
        --no-extras)
            INSTALL_EXTRAS=0
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
            SKIP_GREETD=1
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

export INSTALL_EXTRAS
export SKIP_GREETD

# Ensure not running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Do not run this script as root directly. Run as a normal user with sudo privileges." >&2
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
