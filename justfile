# Default recipe (run when just is called without arguments)
default: update-gitconfig update-zshrc install-oh-my-zsh install-plugins setup-rsa install-python-env link-python-config install-nodejs install-nvim update-nvim install-aws install-vscode link-claude-config restart-shell verify-install

# Update Git configuration
update-gitconfig:
    git config --global core.editor "nvim"
    git config --global init.defaultBranch "main"
    git config --global push.default "current"
    git config --global push.autoSetupRemote "true"
    git config --global pull.rebase "false"
    git config --global alias.ac "!git add -A && git commit -a"
    git config --global alias.mainlog "log --graph --first-parent"
    git config --global alias.set-upstream "!git branch --set-upstream-to=origin/`git symbolic-ref --short HEAD`"

# Update Zsh configuration
update-zshrc:
    #!/bin/bash
    if [ -f "${HOME}/.zshrc" ]; then
        cat "${HOME}/.zshrc" > "${HOME}/.zshrc.bak"
    else
        echo "No existing .zshrc file found."
    fi
    cp zshrc_update "${HOME}/.zshrc"

# Install Oh My Zsh
install-oh-my-zsh: update-zshrc
    #!/bin/bash
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        # Download the install script first to avoid interpolation issues
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o /tmp/oh-my-zsh-install.sh
        sh -c "sh /tmp/oh-my-zsh-install.sh --unattended --keep-zshrc"
        rm -f /tmp/oh-my-zsh-install.sh
        echo "Type 'exit' to continue installation script."
    else
        echo "Oh My Zsh is already installed."
    fi

# Install Zsh plugins
install-plugins: install-oh-my-zsh
    #!/bin/bash
    declare -A plugins=(
        ["ohmyzsh-full-autoupdate"]="https://github.com/Pilaton/OhMyZsh-full-autoupdate.git"
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
        ["zsh-vi-mode"]="https://github.com/jeffreytse/zsh-vi-mode.git"
    )
    for plugin in "${!plugins[@]}"; do
        plugin_url="${plugins[$plugin]}"
        plugin_dir="${HOME}/.oh-my-zsh/custom/plugins/${plugin}"
        if [ ! -d "$plugin_dir" ]; then
            git clone "$plugin_url" "$plugin_dir"
        else
            echo "Plugin $plugin is already installed."
        fi
    done

# Setup RSA keys
setup-rsa:
    #!/bin/bash
    if [ ! -d "${HOME}/.ssh/" ]; then
        mkdir "${HOME}/.ssh"
    fi
    if [ ! -f "${HOME}/.ssh/id_rsa" ] || [ ! -f "${HOME}/.ssh/id_rsa.pub" ]; then
        rm -f "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_rsa.pub"
        ssh-keygen -f "${HOME}/.ssh/id_rsa" -t rsa -N ''
    fi

# Install Python environment with uv and pyenv
install-python-env: install-plugins
    #!/bin/bash
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
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Ensure uv is in the PATH for the current session
    export PATH="${HOME}/.cargo/bin:${PATH}"
    
    # Install Python 3.11.4 using uv (force installation even if system Python exists)
    echo "Installing Python 3.11.4 using uv..."
    uv python install --force 3.11.4 || echo "Python installation failed, continuing anyway"
    
    # Install tools using uv
    echo "Installing Python tools..."
    # Core tools
    uv tool install pipx || echo "pipx installation failed, continuing anyway"
    uv tool install pipenv || echo "pipenv installation failed, continuing anyway"
    
    # Additional tools directly with uv tool install
    echo "Installing additional tools with uv..."
    uv tool install cruft || echo "cruft installation failed, continuing anyway" 
    uv tool install dive-bin || echo "dive-bin installation failed, continuing anyway"
    uv tool install hadolint-bin || echo "hadolint-bin installation failed, continuing anyway"
    uv tool install just-bin || echo "just-bin installation failed, continuing anyway"
    uv tool install lazydocker-bin || echo "lazydocker-bin installation failed, continuing anyway"
    
    # Note: setuptools, wheel, virtualenv, and awscli will be installed from pyproject.toml
    
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
            if ! grep -q "\.cargo/bin" "$rc_file"; then
                echo '' >> "$rc_file"
                echo '# uv installation' >> "$rc_file"
                echo 'export PATH="$HOME/.cargo/bin:$PATH"  # For uv' >> "$rc_file"
            fi
            
            # Add ~/.local/bin to PATH if it doesn't exist
            if ! grep -q "\.local/bin" "$rc_file"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"  # For uv tools and pipx' >> "$rc_file"
            fi
            
            # Check if pyenv configuration already exists to avoid duplication
            if ! grep -q "PYENV_ROOT" "$rc_file"; then
                # Add pyenv configuration
                echo '' >> "$rc_file"
                echo '# pyenv configuration' >> "$rc_file"
                echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$rc_file"
                echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> "$rc_file"
                if [[ "$shell_type" == "zsh" ]]; then
                    echo 'eval "$(pyenv init - zsh)"' >> "$rc_file"
                else
                    echo 'eval "$(pyenv init - bash)"' >> "$rc_file"
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
    if ! grep -q "\.local/bin" "${HOME}/.profile" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.profile"
        echo "Added ~/.local/bin to PATH in .profile"
    fi
    
    echo "Python environment setup completed"

# Install Node.js
install-nodejs:
    #!/bin/bash
    # Check for both Node.js and npm
    if ! type node &> /dev/null || ! type npm &> /dev/null; then
        echo "Installing Node.js and npm from binary distribution..."
        # Use the latest LTS version
        NODE_VERSION="v18.18.0"
        wget https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz
        tar -xf node-${NODE_VERSION}-linux-x64.tar.xz
        sudo cp -r node-${NODE_VERSION}-linux-x64/bin/* /usr/local/bin/
        sudo cp -r node-${NODE_VERSION}-linux-x64/lib/* /usr/local/lib/
        rm -rf node-${NODE_VERSION}-linux-x64 node-${NODE_VERSION}-linux-x64.tar.xz
        
        # Verify installation
        if type node &> /dev/null && type npm &> /dev/null; then
            echo "Node.js $(node --version) and npm $(npm --version) installed successfully"
        else
            echo "Node.js or npm installation may have failed, please check manually"
        fi
    else
        echo "Node.js $(node --version) and npm $(npm --version) are already installed"
    fi

# Install Neovim
install-nvim: install-nodejs
    #!/bin/bash
    if ! type nvim &> /dev/null; then
        echo "Installing Neovim..."
        # First try: use the official PPA (this is Ubuntu's recommended method)
        if sudo add-apt-repository ppa:neovim-ppa/unstable -y && \
           sudo apt-get update && \
           sudo apt-get install -y neovim; then
            echo "Neovim successfully installed from PPA."
        else
            # Second try: download the pre-compiled binary
            echo "PPA installation failed, trying to download pre-compiled binary..."
            NVIM_VERSION="v0.9.5"
            wget -q "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz"
            if [ -f "nvim-linux64.tar.gz" ]; then
                sudo rm -rf /opt/nvim
                sudo mkdir -p /opt/nvim
                sudo tar -xzf nvim-linux64.tar.gz -C /opt/nvim --strip-components=1
                rm -f nvim-linux64.tar.gz
                sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
                echo "Neovim installed via pre-compiled binary."
            else
                # Third try: use apt repository (may be outdated)
                echo "Binary download failed, trying apt repository..."
                sudo apt-get update && sudo apt-get install -y neovim
            fi
        fi
        # Set up the editor alternatives
        if type nvim &> /dev/null; then
            # Store the path to nvim using command substitution
            NVIM_PATH="$(command -v nvim)"
            sudo update-alternatives --install /usr/bin/vi vi "${NVIM_PATH}" 110
            sudo update-alternatives --install /usr/bin/vim vim "${NVIM_PATH}" 110
            sudo update-alternatives --install /usr/bin/editor editor "${NVIM_PATH}" 110
            # Create aliases in /usr/local/bin if they don't exist
            for cmd in ex view vimdiff; do
                if ! type "${cmd}" &> /dev/null; then
                    echo '#!/bin/sh' | sudo tee "/usr/local/bin/${cmd}" > /dev/null
                    echo "exec nvim -c '${cmd}' \"\$@\"" | sudo tee -a "/usr/local/bin/${cmd}" > /dev/null
                    sudo chmod +x "/usr/local/bin/${cmd}"
                fi
            done
        fi
    else
        echo "Neovim is already installed."
    fi

# Update Neovim configuration
update-nvim: install-nvim
    #!/bin/bash
    mkdir -p "${HOME}/.config/nvim"
    if [ -f "${HOME}/.config/nvim/init.vim" ]; then
        cat "${HOME}/.config/nvim/init.vim" > "${HOME}/.config/nvim/init.vim.bak"
    else
        echo "No existing init.vim file found."
    fi
    # Use PWD to ensure file is found regardless of current directory
    if [ -f "init.vim" ]; then
        cp "init.vim" "${HOME}/.config/nvim/init.vim"
    elif [ -f "${PWD}/init.vim" ]; then
        cp "${PWD}/init.vim" "${HOME}/.config/nvim/init.vim"
    else
        echo "Warning: Could not find init.vim in current directory. Skipping."
    fi
    
    # Install vim-plug if not already installed
    if [ ! -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]; then
        echo "Installing vim-plug..."
        curl -fLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    # Continue with plugin installation
    nvim -c "PlugInstall" -c "qa" || echo "PlugInstall failed, continuing anyway"
    nvim -c "PlugUpdate" -c "qa" || echo "PlugUpdate failed, continuing anyway"

# Install AWS CLI v2
install-aws:
    #!/bin/bash
    # Check if AWS CLI is installed and its version
    if type aws > /dev/null 2>&1; then
        AWS_VERSION=$(aws --version 2>&1)
        if [[ "$AWS_VERSION" == *"aws-cli/2."* ]]; then
            echo "AWS CLI v2 is already installed: $AWS_VERSION"
        else
            echo "Removing non-v2 AWS CLI installation..."
            # If it's installed via apt, remove it
            if dpkg -l | grep -q awscli; then
                sudo apt remove -y awscli
            fi
            # If it's installed via pip or uv, remove it
            if type uv > /dev/null 2>&1; then
                uv pip uninstall -y awscli 2>/dev/null || true
            else
                pip uninstall -y awscli 2>/dev/null || true
            fi
            # Install AWS CLI v2
            echo "Installing AWS CLI v2..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip -q awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
            echo "AWS CLI v2 has been installed"
        fi
    else
        # AWS CLI is not installed, install v2
        echo "Installing AWS CLI v2..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        echo "AWS CLI v2 has been installed"
    fi

# Install VS Code
install-vscode:
    #!/bin/bash
    if ! type code &> /dev/null; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        sudo apt update
        sudo apt install code -y
    else
        echo "VS Code is already installed."
    fi

# Link Python config files
link-python-config:
    #!/bin/bash
    echo "Setting up Python configuration files..."
    
    # We're not using pyproject.toml anymore, installing packages directly
    
    # Link Pipfile
    if [ -f "${HOME}/Pipfile" ]; then
        # If it's already a symlink to our file, do nothing
        if [ -L "${HOME}/Pipfile" ] && [ "$(readlink "${HOME}/Pipfile")" == "${PWD}/Pipfile" ]; then
            echo "Pipfile is already linked correctly."
        else
            # Back up existing file
            echo "Backing up existing Pipfile..."
            mv "${HOME}/Pipfile" "${HOME}/Pipfile.bak.$(date +%s)"
            # Create symlink
            ln -sf "${PWD}/Pipfile" "${HOME}/Pipfile"
            echo "Pipfile has been linked."
        fi
    else
        # Create symlink if no file exists
        ln -sf "${PWD}/Pipfile" "${HOME}/Pipfile"
        echo "Pipfile has been linked."
    fi
    
    # Create a persistent user Python environment
    echo "Setting up user Python environment..."
    if type uv > /dev/null 2>&1; then
        # Create a persistent venv in ~/.local/pipenv-global
        USER_VENV="${HOME}/.local/pipenv-global"
        echo "Creating global environment at $USER_VENV..."
        mkdir -p "$USER_VENV"
        uv venv -p 3.11 "$USER_VENV" || echo "Failed to create user venv, continuing anyway..."
        
        # Install essential packages in the user venv
        echo "Installing essential packages in user environment..."
        if [ -f "${USER_VENV}/bin/pip" ]; then
            "${USER_VENV}/bin/pip" install wheel setuptools virtualenv awscli || echo "Failed to install packages, continuing anyway..."
        else
            echo "Failed to find pip in user venv, installing in user space instead..."
            pip install --user wheel setuptools virtualenv awscli || echo "Failed to install packages, continuing anyway..."
        fi
        
        # Create activation script for shell config
        ACTIVATE_DIR="${HOME}/.local/bin"
        mkdir -p "$ACTIVATE_DIR"
        ACTIVATE_SCRIPT="${ACTIVATE_DIR}/activate-pipenv-global"
        
        echo '#!/bin/bash' > "$ACTIVATE_SCRIPT"
        echo "# Auto-generated by dotfiles setup" >> "$ACTIVATE_SCRIPT"
        echo "source \"${USER_VENV}/bin/activate\"" >> "$ACTIVATE_SCRIPT"
        chmod +x "$ACTIVATE_SCRIPT"
        
        echo "Created activation script at $ACTIVATE_SCRIPT"
    else
        # Fallback to regular pip if uv is not available
        echo "uv not found, installing packages in user space..."
        pip install --user wheel setuptools virtualenv awscli || echo "Failed to install packages, continuing anyway..."
    fi

# Link Claude config file
link-claude-config:
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
    if [ "$SHELLS" -eq 0 ]; then
        echo "⚠️ No shell config files found"
    fi
    
    echo -e "\n--- Checking Python installation ---"
    if command -v uv >/dev/null 2>&1; then
        echo "✓ uv: $(uv --version 2>&1 | head -n 1)"
    else
        echo "⚠️ uv not installed"
    fi
    
    if command -v python3 >/dev/null 2>&1; then
        echo "✓ python: $(python3 --version)"
    else
        echo "⚠️ python not installed"
    fi
    
    if command -v pip >/dev/null 2>&1; then
        echo "✓ pip: $(pip --version)"
    else
        echo "⚠️ pip not installed"
    fi
    
    if command -v pipenv >/dev/null 2>&1; then
        echo "✓ pipenv: $(pipenv --version)"
    else
        echo "⚠️ pipenv not installed"
    fi
    
    if [ -d "${HOME}/.pyenv" ]; then
        echo "✓ pyenv installed"
    else
        echo "⚠️ pyenv not found in ${HOME}/.pyenv"
    fi
    
    if [ -d "${HOME}/.local/pipenv-global" ]; then
        echo "✓ global Python environment exists"
        if [ -f "${HOME}/.local/bin/activate-pipenv-global" ]; then
            echo "  ✓ activation script exists"
        else
            echo "  ⚠️ activation script missing"
        fi
    else
        echo "⚠️ global Python environment not found"
    fi
    
    echo -e "\n--- Checking core tooling ---"
    if command -v aws >/dev/null 2>&1; then
        echo "✓ aws: $(aws --version 2>&1)"
    else
        echo "⚠️ aws not installed"
    fi
    
    if command -v git >/dev/null 2>&1; then
        echo "✓ git: $(git --version)"
    else
        echo "⚠️ git not installed"
    fi
    
    if command -v node >/dev/null 2>&1; then
        echo "✓ node: $(node --version)"
    else
        echo "⚠️ node not installed"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        echo "✓ npm: $(npm --version)"
    else
        echo "⚠️ npm not installed"
    fi
    
    if command -v nvim >/dev/null 2>&1; then
        echo "✓ nvim: $(nvim --version | head -n 1)"
    else
        echo "⚠️ nvim not installed"
    fi
    
    echo -e "\n--- Checking additional tools ---"
    for tool in cruft dive hadolint lazydocker just; do
        if command -v $tool >/dev/null 2>&1; then
            echo "✓ $tool installed"
        else
            echo "⚠️ $tool not installed"
        fi
    done
    
    echo -e "\n--- Checking config files ---"
    if [ -f "${HOME}/Pipfile" ]; then
        echo "✓ Pipfile linked"
    else
        echo "⚠️ Pipfile not linked"
    fi
    
    if [ -f "${HOME}/.config/nvim/init.vim" ]; then
        echo "✓ Neovim config exists"
    else
        echo "⚠️ Neovim config not found"
    fi
    
    if [ -f "${HOME}/.claude/claude.md" ]; then
        echo "✓ Claude.md linked"
    else
        echo "⚠️ Claude.md not linked"
    fi
    
    echo -e "\n=== Verification complete ===\n"
    echo "For any warnings above, you might want to run the specific target manually or check the logs."