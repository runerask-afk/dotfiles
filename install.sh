#!/usr/bin/env bash
# ^ Shebang: Tells the system to execute this script using Bash.

# Exit immediately if a command exits with a non-zero status
set -e

DOTFILES_DIR="$HOME/.dotfiles"
STATE_FILE="$DOTFILES_DIR/.original_state"

# 1. Detect the original shell on the host machine before we change anything
ORIGINAL_SHELL=$(basename "$SHELL")
echo "--> Detected original host shell: $ORIGINAL_SHELL"

# Save the original shell and config path to a hidden state file for easy reversion later
echo "ORIGINAL_SHELL=$ORIGINAL_SHELL" > "$STATE_FILE"
echo "ORIGINAL_RC=\$HOME/.${ORIGINAL_SHELL}rc" >> "$STATE_FILE"

# 2. Back up the host's existing configuration for their current shell
HOST_RC="$HOME/.${ORIGINAL_SHELL}rc"
if [ -f "$HOST_RC" ] || [ -L "$HOST_RC" ]; then
    echo "--> Backing up host's original .${ORIGINAL_SHELL}rc to .${ORIGINAL_SHELL}rc.bak"
    cp -L "$HOST_RC" "${HOST_RC}.bak"
fi

# 3. Force switch the user's default shell to Bash (if it isn't already)
if [ "$ORIGINAL_SHELL" != "bash" ]; then
    echo "--> Changing user default shell from $ORIGINAL_SHELL to Bash..."
    # chsh changes the user login shell; $(which bash) finds the path to bash safely
    chsh -s "$(which bash)"
else
    echo "--> System is already running Bash."
fi

# 4. Deploy your predefined Bash configuration and mods/addons
echo "--> Deploying predefined Bash configuration and mods..."

# Link your custom bashrc
if [ -f "$HOME/.bashrc" ] || [ -L "$HOME/.bashrc" ]; then
    rm -f "$HOME/.bashrc"
fi
ln -s "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"

# If you have custom mods/addons folders, link or copy them into place
# Example: Linking a custom mods directory into ~/.bash_mods
if [ -d "$DOTFILES_DIR/bash/mods" ]; then
    ln -sfn "$DOTFILES_DIR/bash/mods" "$HOME/.bash_mods"
fi

echo "--> Success! Predefined shell setup applied. Restart your terminal or run 'bash' to load it."
