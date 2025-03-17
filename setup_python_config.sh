#!/bin/bash
echo "Setting up Python configuration files..."

# Create a dotfiles-specific Python environment using uv
echo "Setting up dotfiles Python environment..."
DOTFILES_VENV="${HOME}/dotfiles/.venv"
ACTIVATE_DIR="${HOME}/.local/bin"
ACTIVATE_SCRIPT="${ACTIVATE_DIR}/activate-dotfiles-env"

# Only proceed if uv is available
if command -v uv > /dev/null 2>&1; then
    echo "Creating dotfiles environment at $DOTFILES_VENV..."
    # Remove any existing environment to ensure clean setup
    rm -rf "$DOTFILES_VENV"
    mkdir -p "$DOTFILES_VENV"
    
    # Create virtual environment with uv
    uv venv -p 3.11 "$DOTFILES_VENV"
    
    if [ -f "${DOTFILES_VENV}/bin/python" ]; then
        echo "Installing essential packages in dotfiles environment..."
        # Install only the minimal core packages
        "${DOTFILES_VENV}/bin/python" -m pip install wheel setuptools virtualenv awscli
        
        # Create activation script with proper shebang
        mkdir -p "$ACTIVATE_DIR"
        echo "#!/bin/bash" > "$ACTIVATE_SCRIPT"
        echo "# Auto-generated by dotfiles setup" >> "$ACTIVATE_SCRIPT"
        echo "source \"${DOTFILES_VENV}/bin/activate\"" >> "$ACTIVATE_SCRIPT"
        chmod +x "$ACTIVATE_SCRIPT"
        
        echo "Created activation script at $ACTIVATE_SCRIPT"
        
        # The activation function is already in zshrc_update
        echo "Dotfiles Python environment will be auto-activated when entering the dotfiles directory"
    else
        echo "Failed to create virtual environment. Please check uv installation."
    fi
else
    echo "WARNING: uv not found, skipping dotfiles Python environment setup."
    echo "Please install uv manually and run 'just link-python-config' after installation."
fi