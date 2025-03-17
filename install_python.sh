#!/bin/bash
# Remove any existing Conda installations first
if [ -d "${HOME}/conda" ] || [ -d "${HOME}/miniconda3" ] || [ -d "${HOME}/anaconda3" ] || [ -d "opt/conda" ]; then
    echo "Removing existing Conda installations..."
    rm -rf "${HOME}/conda" "${HOME}/miniconda3" "${HOME}/anaconda3" "/opt/conda"
fi

# Remove pyenv if present
if [ -d "${HOME}/.pyenv" ]; then
    echo "Removing existing pyenv installation..."
    rm -rf "${HOME}/.pyenv"
fi

# Install uv
echo "Installing uv..."
# Install to ~/.local/bin to ensure it works across different Ubuntu versions
curl -LsSf https://astral.sh/uv/install.sh | DEST=$HOME/.local/bin sh

# Create a persistent PATH update script that we can source immediately
echo "Setting up path for uv..."
UV_PATH_SCRIPT="${HOME}/.local/bin/setup_uv_path.sh"

cat << EOT > "$UV_PATH_SCRIPT"
#!/bin/bash
# Add uv installation directories to PATH
export PATH="\$HOME/.local/bin:\$PATH"
export PATH="\$HOME/.cargo/bin:\$PATH"
EOT
chmod +x "$UV_PATH_SCRIPT"

# Source the path script for the current session
source "$UV_PATH_SCRIPT"

# Verify uv is available
if ! command -v uv > /dev/null 2>&1; then
    echo "ERROR: uv installation failed or not in PATH. Trying alternative installation..."
    
    # Try cargo install as a fallback
    if command -v cargo > /dev/null 2>&1; then
        echo "Installing uv via cargo..."
        cargo install uv
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    # Final check
    if ! command -v uv > /dev/null 2>&1; then
        echo "ERROR: Could not install uv. Some functionality will be limited."
        echo "Please install uv manually after installation completes."
        echo "Visit https://github.com/astral-sh/uv for installation instructions."
    fi
else
    echo "uv successfully installed: $(uv --version)"
fi

# Install Python using uv if available
if command -v uv > /dev/null 2>&1; then
    echo "Installing Python 3.11.4 using uv..."
    uv python install --force 3.11.4 || echo "Python installation failed, continuing anyway"
    
    # Install tools 
    echo "Installing Python tools with uv..."
    uv tool install pipx
    uv tool install pipenv
    
    # Install additional utilities
    uv tool install cruft
    uv tool install dive-bin
    uv tool install hadolint-bin
    uv tool install just-bin
    uv tool install lazydocker-bin
else
    echo "Skipping uv-based Python installations."
fi

# Process shell configuration files to add uv paths and remove pyenv
for rc_file in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.profile" "${HOME}/.bash_profile"; do
    if [ -f "$rc_file" ]; then
        # Create backup of the rc file
        cp "$rc_file" "${rc_file}.bak.$(date +%s)"
        
        # Remove pyenv configuration if present
        if grep -q "PYENV_ROOT" "$rc_file"; then
            echo "Removing pyenv configuration from $rc_file..."
            sed -i '/# pyenv configuration/,/fi/d' "$rc_file" || true
            sed -i '/PYENV_ROOT/d' "$rc_file" || true
            sed -i '/pyenv init/d' "$rc_file" || true
        fi
        
        # Add uv to PATH if it doesn't exist
        if ! grep -q ".cargo/bin" "$rc_file"; then
            echo '' >> "$rc_file"
            echo '# uv installation' >> "$rc_file"
            echo 'export PATH="$HOME/.cargo/bin:$PATH"  # For uv' >> "$rc_file"
        fi
        
        # Add ~/.local/bin to PATH if it doesn't exist
        if ! grep -q ".local/bin" "$rc_file"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"  # For uv tools and pipx' >> "$rc_file"
        fi
    fi
done

# Ensure ~/.local/bin is in PATH for all users
if ! grep -q ".local/bin" "${HOME}/.profile" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.profile"
    echo "Added ~/.local/bin to PATH in .profile"
fi

echo "Python environment setup completed"