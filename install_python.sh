#!/bin/bash
# Remove any existing Conda installations first
if [ -d "${HOME}/conda" ] || [ -d "${HOME}/miniconda3" ] || [ -d "${HOME}/anaconda3" ] || [ -d "opt/conda" ]; then
    echo "Removing existing Conda installations..."
    rm -rf "${HOME}/conda" "${HOME}/miniconda3" "${HOME}/anaconda3" "/opt/conda"
fi
# Remove any existing Conda installations first
if [ -d "${HOME}/conda" ] || [ -d "${HOME}/miniconda3" ] || [ -d "${HOME}/anaconda3" ] || [ -d "opt/conda" ]; then
    echo "Removing existing Conda installations..."
    rm -rf "${HOME}/conda" "${HOME}/miniconda3" "${HOME}/anaconda3" "/opt/conda"
fi

# Remove any existing pyenv installations if present
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
# Add uv installation directories to PATH
export PATH="\$HOME/.local/bin:\$PATH"
EOT
chmod +x "$UV_PATH_SCRIPT"

# Source the path script for the current session
source "$UV_PATH_SCRIPT"

# Verify uv is available
if \! command -v uv > /dev/null 2>&1; then
    echo "ERROR: uv installation failed or not in PATH. Trying alternative installation..."
    
    # Try cargo install as a fallback
    if command -v cargo > /dev/null 2>&1; then
        echo "Installing uv via cargo..."
        cargo install uv
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    # Final check
    if \! command -v uv > /dev/null 2>&1; then
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

# Note: setuptools, wheel, virtualenv, and awscli will be installed when setting up the virtual environment

# Install pyenv (for compatibility with pipenv projects)
echo "Installing pyenv for compatibility with pipenv projects..."
# Use the more stable installation URL (pyenv.run)
curl -L https://pyenv.run | bash

# Process shell configuration files
for rc_file in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.profile" "${HOME}/.bash_profile"; do
    if [ -f "$rc_file" ]; then
        # Create backup of the rc file
        cp "$rc_file" "${rc_file}.bak.$(date +%s)"
        
        # Check shell type
        shell_type="bash"
        if [[ "$rc_file" == *".zshrc" ]]; then
            shell_type="zsh"
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
        
        # Check if pyenv configuration already exists to avoid duplication
        if ! grep -q "PYENV_ROOT" "$rc_file"; then
            # Add pyenv configuration line by line
            echo "" >> "$rc_file"
            echo "# pyenv configuration" >> "$rc_file"
            echo "export PYENV_ROOT=\"\$HOME/.pyenv\"" >> "$rc_file"
            echo "if [ -d \"\$PYENV_ROOT/bin\" ]; then" >> "$rc_file"
            echo "  export PATH=\"\$PYENV_ROOT/bin:\$PATH\"" >> "$rc_file"
            echo "fi" >> "$rc_file"
            
            # Add pyenv init but make it lower priority than virtualenvs
            if [[ "$shell_type" == "zsh" ]]; then
                echo "# Initialize pyenv but ensure it does not override active virtualenvs" >> "$rc_file"
                echo "if [ -z \"\$VIRTUAL_ENV\" ]; then" >> "$rc_file"
                echo "  eval \"\$(pyenv init - zsh)\"" >> "$rc_file"
                echo "else" >> "$rc_file"
                echo "  # When in virtualenv, add pyenv but don't let it take over PATH" >> "$rc_file"
                echo "  export PATH=\"\${VIRTUAL_ENV}/bin:\${PATH}\"" >> "$rc_file"
                echo "fi" >> "$rc_file"
            else
                echo "# Initialize pyenv but ensure it does not override active virtualenvs" >> "$rc_file"
                echo "if [ -z \"\$VIRTUAL_ENV\" ]; then" >> "$rc_file"
                echo "  eval \"\$(pyenv init - bash)\"" >> "$rc_file"
                echo "else" >> "$rc_file"
                echo "  # When in virtualenv, add pyenv but don't let it take over PATH" >> "$rc_file"
                echo "  export PATH=\"\${VIRTUAL_ENV}/bin:\${PATH}\"" >> "$rc_file"
                echo "fi" >> "$rc_file"
            fi
            
            echo "Updated $rc_file with pyenv configuration"
        else
            echo "$rc_file already contains pyenv configuration"
        fi
    fi
done

# Install Python 3.11.4 with pyenv for pipenv compatibility
if [ -x "${HOME}/.pyenv/bin/pyenv" ]; then
    "${HOME}/.pyenv/bin/pyenv" install 3.11.4 || echo "Python installation with pyenv failed, continuing anyway"
else
    echo "pyenv binary not found, skipping Python installation with pyenv"
fi

# Ensure ~/.local/bin is in PATH for all users
if ! grep -q ".local/bin" "${HOME}/.profile" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.profile"
    echo "Added ~/.local/bin to PATH in .profile"
fi

echo "Python environment setup completed"
