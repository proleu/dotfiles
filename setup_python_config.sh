#!/bin/bash
echo "Setting up Python configuration files..."

# Create a dotfiles-specific Python environment using uv
echo "Setting up dotfiles Python environment..."
DOTFILES_VENV="${HOME}/dotfiles/.venv"

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
        # Use uv pip directly to install packages
        uv pip install --python "${DOTFILES_VENV}/bin/python" pip wheel setuptools virtualenv awscli
        
        # The auto-activation function handles activation directly
        echo "Dotfiles Python environment created and will be auto-activated when entering the dotfiles directory"
    else
        echo "Failed to create virtual environment. Please check uv installation."
    fi
else
    echo "WARNING: uv not found, skipping dotfiles Python environment setup."
    echo "Please install uv manually and run 'just link-python-config' after installation."
fi