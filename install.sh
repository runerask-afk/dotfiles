#!/usr/bin/env bash
# ^ Shebang: Tells the OS to run this file using Bash.

# set -e: Exit immediately if any command fails to prevent broken setups
set -e

DOTFILES_DIR="$HOME/.dotfiles"
STATE_FILE="$DOTFILES_DIR/.original_state"

echo "==> Starting modular dotfiles installation..."

# 1. Detect host shell and record initial state
ORIGINAL_SHELL=$(basename "$SHELL")
echo "--> Detected host shell: $ORIGINAL_SHELL"

# Save state for restore.sh
echo "ORIGINAL_SHELL=$ORIGINAL_SHELL" > "$STATE_FILE"
echo "ORIGINAL_RC=\$HOME/.${ORIGINAL_SHELL}rc" >> "$STATE_FILE"

# 2. Back up existing configuration
HOST_RC="$HOME/.${ORIGINAL_SHELL}rc"
if [ -f "$HOST_RC" ] || [ -L "$HOST_RC" ]; then
    echo "--> Backing up $HOST_RC to ${HOST_RC}.bak"
    cp -L "$HOST_RC" "${HOST_RC}.bak"
fi

# 3. Force switch default shell to Bash (if not already set)
if [ "$ORIGINAL_SHELL" != "bash" ]; then
    echo "--> Changing default shell to Bash..."
    chsh -s "$(which bash)"
fi

# 4. Install JetBrains Mono Nerd Font
echo "--> Checking JetBrains Mono Nerd Font..."
mkdir -p "$HOME/.local/share/fonts"
if ! fc-list | grep -i "JetBrainsMono" > /dev/null 2>&1; then
    echo "--> Installing JetBrains Mono Nerd Font..."
    curl -fLo "$HOME/.local/share/fonts/JetBrainsMono.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o "$HOME/.local/share/fonts/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/"
    rm -f "$HOME/.local/share/fonts/JetBrainsMono.zip"
    fc-cache -fv "$HOME/.local/share/fonts" > /dev/null 2>&1
fi

# Helper function to check if a command exists in system PATH
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 5. Install System Tools & Dependencies (Fontconfig, Unzip, Eza, FZF, TLDR, Curl, Git)
echo "--> Installing system packages..."
if command_exists apt-get; then
    sudo apt-get update
    # Added fontconfig and unzip here so container tests pass smoothly
    sudo apt-get install -y curl git unzip fontconfig fzf eza build-essential gawk|| true
    # Try installing tldr, fallback to python/npm client if apt package fails
    sudo apt-get install -y tealdeer || echo "--> Note: apt tldr package skipped, can use node/python client if needed."
elif command_exists pacman; then
    sudo pacman -Sy --noconfirm base-devel gawk curl git unzip fontconfig fzf tealdeer eza
elif command_exists dnf; then
    sudo dnf install -y gcc gawk curl git unzip fontconfig fzf tealdeer eza
fi

# 6. Install Starship Prompt (if missing)
if ! command_exists starship; then
    echo "--> Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# 7. Install Zoxide (if missing)
if ! command_exists zoxide; then
    echo "--> Installing Zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# 8. Install Ble.sh (Bash Line Editor)
if [ ! -d "$HOME/.local/share/blesh" ]; then
    echo "--> Installing ble.sh..."
    rm -rf /tmp/ble.sh
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh
    make -C /tmp/ble.sh install PREFIX="$HOME/.local"
    rm -rf /tmp/ble.sh

    # Record that WE installed ble.sh so restore.sh knows it is safe to delete later
    echo "BLESH_INSTALLED_BY_US=true" >> "$STATE_FILE"
else
    echo "--> ble.sh was already installed. Preserving existing installation."
    echo "BLESH_INSTALLED_BY_US=false" >> "$STATE_FILE"
fi

# 9. Link Dotfiles Configuration
echo "--> Linking Bash configuration..."
rm -f "$HOME/.bashrc"
ln -s "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"

# 10. Link Nano configuration
if [ -f "$HOME/.nanorc" ] || [ -L "$HOME/.nanorc" ]; then
    echo "--> Backing up existing .nanorc to .nanorc.bak"
    cp -L "$HOME/.nanorc" "$HOME/.nanorc.bak"
    echo "NANORC_INSTALLED_BY_US=false" >> "$STATE_FILE"
else
    echo "NANORC_INSTALLED_BY_US=true" >> "$STATE_FILE"
fi

echo "--> Linking Nano configuration..."
rm -f "$HOME/.nanorc"
ln -s "$DOTFILES_DIR/nano/nanorc" "$HOME/.nanorc"

# 11. Link Starship configuration safely
echo "--> Linking Starship configuration..."

# Ensure the ~/.config directory exists
mkdir -p "$HOME/.config"

# Check if a custom starship.toml already exists (as a regular file or symlink)
if [ -f "$HOME/.config/starship.toml" ] || [ -L "$HOME/.config/starship.toml" ]; then
    echo "--> Backing up existing starship.toml to starship.toml.bak"
    cp -L "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
    echo "STARSHIP_CONFIG_INSTALLED_BY_US=false" >> "$STATE_FILE"
else
    echo "STARSHIP_CONFIG_INSTALLED_BY_US=true" >> "$STATE_FILE"
fi

# Remove existing link/file and create symlink to dotfiles repo
rm -f "$HOME/.config/starship.toml"
ln -s "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# 12. Link Fastfetch configuration sa
echo "--> Linking Fastfetch configuration..."
mkdir -p "$HOME/.config/fastfetch"

if [ -f "$HOME/.config/fastfetch/config.jsonc" ] || [ -L "$HOME/.config/fastfetch/config.jsonc" ]; then
    echo "--> Backing up existing config.jsonc..."
    cp -L "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc.bak"
    echo "FASTFETCH_CONFIG_INSTALLED_BY_US=false" >> "$STATE_FILE"
else
    echo "FASTFETCH_CONFIG_INSTALLED_BY_US=true" >> "$STATE_FILE"
fi

rm -f "$HOME/.config/fastfetch/config.jsonc"
ln -s "$DOTFILES_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

echo "==> Installation complete! Restart your terminal to experience your new setup."
