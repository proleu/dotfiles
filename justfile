# Default recipe (run when just is called without arguments)
default: update-gitconfig update-zshrc install-oh-my-zsh install-plugins setup-rsa install-python-env update-pyenv install-nodejs install-nvim update-nvim install-aws install-vscode restart-shell

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
    
    # Install Python 3.11.4 using uv
    echo "Installing Python 3.11.4 using uv..."
    uv python install 3.11.4 || echo "Python installation failed, continuing anyway"
    
    # Install tools using uv
    echo "Installing Python tools..."
    uv tool install pipx || echo "pipx installation failed, continuing anyway"
    uv tool install pipenv || echo "pipenv installation failed, continuing anyway"
    
    # Install additional tools with pipx after it's installed
    if [ -x "${HOME}/.local/bin/pipx" ]; then
        echo "Installing additional tools with pipx..."
        "${HOME}/.local/bin/pipx" install cruft || echo "cruft installation failed, continuing anyway" 
        "${HOME}/.local/bin/pipx" install dive-bin || echo "dive-bin installation failed, continuing anyway"
        "${HOME}/.local/bin/pipx" install hadolint-bin || echo "hadolint-bin installation failed, continuing anyway"
        "${HOME}/.local/bin/pipx" install just-bin || echo "just-bin installation failed, continuing anyway"
        "${HOME}/.local/bin/pipx" install lazydocker-bin || echo "lazydocker-bin installation failed, continuing anyway"
    else
        echo "pipx not found, skipping additional tools installation"
    fi
    
    # Install pyenv (for compatibility with pipenv projects)
    echo "Installing pyenv for compatibility with pipenv projects..."
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    
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
    
    # Ensure pipx is in the PATH
    if [ -x "${HOME}/.local/bin/pipx" ]; then
        "${HOME}/.local/bin/pipx" ensurepath || echo "pipx ensurepath failed, continuing anyway"
    fi
    
    echo "Python environment setup completed"

# Update pyenv configuration
update-pyenv: install-python-env
    #!/bin/bash
    if [ -f "${HOME}/Pipfile" ]; then
        cat "${HOME}/Pipfile" > "${HOME}/Pipfile.bak"
    else
        echo "No existing Pipfile file found."
    fi
    # Use absolute path to ensure file is found regardless of current directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "${SCRIPT_DIR}/Pipfile" "${HOME}/Pipfile"

# Install Node.js
install-nodejs:
    #!/bin/bash
    if ! type node &> /dev/null; then
        wget https://nodejs.org/dist/v18.18.0/node-v18.18.0-linux-x64.tar.xz
        tar -xf node-v18.18.0-linux-x64.tar.xz
        sudo cp node-v18.18.0-linux-x64/bin/* /usr/bin/
        rm -rf node-v18.18.0-linux-x64 node-v18.18.0-linux-x64.tar.xz
    else
        echo "Node.js is already installed."
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
    # Use absolute path to ensure file is found regardless of current directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "${SCRIPT_DIR}/init.vim" "${HOME}/.config/nvim/init.vim"
    
    # Install vim-plug if not already installed
    if [ ! -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]; then
        echo "Installing vim-plug..."
        curl -fLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    
    # Continue with plugin installation
    nvim -c "PlugInstall" -c "qa" || echo "PlugInstall failed, continuing anyway"
    nvim -c "PlugUpdate" -c "qa" || echo "PlugUpdate failed, continuing anyway"

# Install AWS CLI
install-aws:
    #!/bin/bash
    if ! type aws > /dev/null 2>&1; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws
    else
        echo "awscli is already installed."
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

# Restart shell prompt
restart-shell:
    echo "Please restart your shell for changes to take effect"