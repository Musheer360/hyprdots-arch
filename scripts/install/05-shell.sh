#!/usr/bin/env bash
# 05-shell.sh - Configure Zsh, Oh My Zsh, and plugins

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/install/lib.sh
source "$SCRIPT_DIR/lib.sh"

banner "Step 05: Shell Setup (Zsh + Oh-My-Zsh)"

# 1. Install Oh My Zsh
ZSH_DIR="$HOME/.oh-my-zsh"
if [ ! -d "$ZSH_DIR" ] || [ ! -f "$ZSH_DIR/oh-my-zsh.sh" ]; then
    info "Installing Oh My Zsh (unattended)..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed."
else
    ok "Oh My Zsh already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"

# 2. Plugins
info "Setting up zsh-autosuggestions plugin..."
AUTO_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ ! -d "$AUTO_DIR" ]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$AUTO_DIR"
else
    git -C "$AUTO_DIR" pull --ff-only 2>/dev/null || true
fi

info "Setting up zsh-syntax-highlighting plugin..."
SYNTAX_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ ! -d "$SYNTAX_DIR" ]; then
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_DIR"
else
    git -C "$SYNTAX_DIR" pull --ff-only 2>/dev/null || true
fi

# 3. Deploy .zshrc
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    BDIR=$(create_backup_dir)
    mkdir -p "$BDIR"
    cp "$HOME/.zshrc" "$BDIR/.zshrc"
    info "Existing ~/.zshrc backed up to $BDIR/.zshrc"
fi
cp "$REPO_ROOT/dotfiles/.zshrc" "$HOME/.zshrc"
ok ".zshrc deployed."

# 4. Change default shell to zsh
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_BIN="$(command -v zsh)"
if [ "$CURRENT_SHELL" != "$ZSH_BIN" ]; then
    if confirm "Change default shell for $USER to $ZSH_BIN?" "Y"; then
        sudo chsh -s "$ZSH_BIN" "$USER"
        ok "Default shell changed to $ZSH_BIN."
    else
        warn "Shell change skipped by user."
    fi
else
    ok "Default shell is already $ZSH_BIN."
fi

# 5. Verification
info "Verifying zsh configuration..."
zsh -ic 'exit' 2>/dev/null || warn "Zsh test run emitted warnings (non-fatal)."
ok "Shell configuration verified."
