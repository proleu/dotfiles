#!/bin/bash
echo "Setting up Claude configuration..."
# Create ~/.claude directory if it doesn't exist
mkdir -p "${HOME}/.claude"

# Check if file already exists
if [ -f "${HOME}/.claude/claude.md" ]; then
    # If it's already a symlink to our file, do nothing
    if [ -L "${HOME}/.claude/claude.md" ] && [ "$(readlink "${HOME}/.claude/claude.md")" == "${PWD}/CLAUDE.md" ]; then
        echo "Claude config is already linked correctly."
    else
        # Back up existing file
        echo "Backing up existing Claude config..."
        mv "${HOME}/.claude/claude.md" "${HOME}/.claude/claude.md.bak.$(date +%s)"
        # Create symlink
        ln -sf "${PWD}/CLAUDE.md" "${HOME}/.claude/claude.md"
        echo "Claude config has been linked."
    fi
else
    # Create symlink if no file exists
    ln -sf "${PWD}/CLAUDE.md" "${HOME}/.claude/claude.md"
    echo "Claude config has been linked."
fi
