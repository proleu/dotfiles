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

# Restart shell prompt
restart-shell:
echo "Please restart your shell for changes to take effect"

# Verify installation
verify-install:
#!/bin/bash
echo -e "\n=== Verifying installation and configuration ==="
echo -e "\n--- Checking shell configuration ---"
SHELLS=0
for shell_conf in ~/.zshrc ~/.bashrc ~/.profile ~/.bash_profile; do
    if [ -f "$shell_conf" ]; then
        echo "✓ $shell_conf exists"
        SHELLS=$((SHELLS+1))
        if grep -q "\.cargo/bin" "$shell_conf"; then
            echo "  ✓ cargo/bin in PATH"
        else
            echo "  ⚠️ cargo/bin NOT in PATH"
        fi
        if grep -q "\.local/bin" "$shell_conf"; then
            echo "  ✓ .local/bin in PATH"
        else
            echo "  ⚠️ .local/bin NOT in PATH"
        fi
    fi
done
