#!/usr/bin/env bash
# ^ Shebang: Tells the OS to execute this script using Bash.

# set -e: Exit immediately if any command fails
set -e

DOTFILES_DIR="$HOME/.dotfiles"
STATE_FILE="$DOTFILES_DIR/.original_state"

# Check if the state file exists before trying to revert
if [ ! -f "$STATE_FILE" ]; then
    echo "Error: No state file found ($STATE_FILE). Cannot automatically revert."
    exit 1
fi

# Load the saved state variables (ORIGINAL_SHELL and ORIGINAL_RC) from the hidden file
source "$STATE_FILE"

echo "--> Reverting environment back to original state..."

# 1. Remove custom dotfiles links and modular folders
rm -f "$HOME/.bashrc"
rm -f "$HOME/.bash_mods"

# 2. Clean up ble.sh ONLY if it was installed by this dotfiles script
if [ "${BLESH_INSTALLED_BY_US:-false}" = "true" ] && [ -d "$HOME/.local/share/blesh" ]; then
    echo "--> Removing local ble.sh installation (installed by dotfiles)..."
    rm -rf "$HOME/.local/share/blesh"
else
    echo "--> Leaving ble.sh intact (was present before dotfiles setup or not installed)."
fi

# 3. Restore the host's original configuration backup if it exists
HOST_RC="$HOME/.${ORIGINAL_SHELL}rc"
if [ -f "${HOST_RC}.bak" ]; then
    echo "--> Restoring original .${ORIGINAL_SHELL}rc backup..."
    # mv: Moves the .bak file back to its original filename, overwriting the symlink
    mv "${HOST_RC}.bak" "$HOST_RC"
fi

# 4. Clean up or restore Nano configuration
if [ "${NANORC_INSTALLED_BY_US:-false}" = "true" ]; then
    rm -f "$HOME/.nanorc"
    echo "--> Removed dotfiles nano configuration."
elif [ -f "$HOME/.nanorc.bak" ]; then
    rm -f "$HOME/.nanorc"
    mv "$HOME/.nanorc.bak" "$HOME/.nanorc"
    echo "--> Restored original .nanorc backup."
fi

# 5. Revert the default login shell back to what it originally was
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "$ORIGINAL_SHELL" ]; then
    echo "--> Reverting default login shell back to $ORIGINAL_SHELL..."
    chsh -s "$(which "$ORIGINAL_SHELL")"
fi

# 6. Clean up or restore Starship configuration
if [ "${STARSHIP_CONFIG_INSTALLED_BY_US:-false}" = "true" ]; then
    echo "--> Removing dotfiles Starship configuration..."
    rm -f "$HOME/.config/starship.toml"
elif [ -f "$HOME/.config/starship.toml.bak" ]; then
    echo "--> Restoring original starship.toml backup..."
    rm -f "$HOME/.config/starship.toml"
    mv "$HOME/.config/starship.toml.bak" "$HOME/.config/starship.toml"
fi


# 7. Clean up Fastfetch configuration
if [ "${FASTFETCH_CONFIG_INSTALLED_BY_US:-false}" = "true" ]; then
    echo "--> Removing dotfiles Fastfetch configuration..."
    rm -f "$HOME/.config/fastfetch/config.jsonc"
elif [ -f "$HOME/.config/fastfetch/config.jsonc.bak" ]; then
    echo "--> Restoring original config.jsonc backup..."
    rm -f "$HOME/.config/fastfetch/config.jsonc"
    mv "$HOME/.config/fastfetch/config.jsonc.bak" "$HOME/.config/fastfetch/config.jsonc"
fi

# 8. Clean up the state tracking file
rm -f "$STATE_FILE"

echo "--> Restoration complete! Host system is fully reverted."
