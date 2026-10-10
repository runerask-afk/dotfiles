#!/usr/bin/env bash
# ^ Shebang: Execute with Bash.

DOTFILES_DIR="$HOME/.dotfiles"
STATE_FILE="$DOTFILES_DIR/.original_state"

if [ ! -f "$STATE_FILE" ]; then
    echo "Error: No state file found ($STATE_FILE). Cannot automatically revert."
    exit 1
fi

# Load the saved state variables (ORIGINAL_SHELL, ORIGINAL_RC)
source "$STATE_FILE"

echo "--> Reverting environment back to original state..."

# 1. Remove your custom dotfiles links
rm -f "$HOME/.bashrc"
rm -f "$HOME/.bash_mods"

# 2. Restore the host's original configuration backup if it exists
HOST_RC="$HOME/.${ORIGINAL_SHELL}rc"
if [ -f "${HOST_RC}.bak" ]; then
    echo "--> Restoring original .${ORIGINAL_SHELL}rc backup..."
    mv "${HOST_RC}.bak" "$HOST_RC"
fi

# 3. Revert the default login shell back to what it originally was
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "$ORIGINAL_SHELL" ]; then
    echo "--> Reverting default shell back to $ORIGINAL_SHELL..."
    chsh -s "$(which "$ORIGINAL_SHELL")"
fi

# 4. Clean up the state file
rm -f "$STATE_FILE"

echo "--> Restoration complete! Host system is fully reverted."
