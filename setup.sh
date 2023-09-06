#!/usr/bin/env bash

# Define the array of plugins and their GitHub URLs
declare -A plugins=(
    # ["fzf"]="https://github.com/junegunn/fzf.git"
    ["ohmyzsh-full-autoupdate"]="https://github.com/Pilaton/OhMyZsh-full-autoupdate.git"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
    ["zsh-vi-mode"]="https://github.com/jeffreytse/zsh-vi-mode.git"
)

# Install fzf if not already installed
if ! command -v fzf &> /dev/null; then
    sudo apt install fzf
fi

# Install zsh if not already installed
if ! command -v zsh &> /dev/null; then
    sudo apt install zsh
fi

# Set zsh as the default shell
if [[ $SHELL != "/bin/zsh" ]]; then
    chsh -s /bin/zsh
fi

# Install Oh My Zsh only if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Create symlink if not already created
if [[ ! -L "$HOME/.zshrc" ]]; then
    ln -s "$HOME/.zshrc" "$SCRIPTPATH/.zshrc"
fi

# Install zsh plugins from the associative array
for plugin in "${!plugins[@]}"; do
    repo_url="${plugins[$plugin]}"
    plugin_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"

    # Clone the plugin only if it doesn't exist
    if [[ ! -d "$plugin_path" ]]; then
        git clone "$repo_url" "$plugin_path"
    fi
done

# ... Other parts of your script ...

# Install miniconda3 if not already installed
if ! command -v conda &> /dev/null; then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$HOME/miniconda.sh"
    bash ~/miniconda.sh -b -p $HOME/miniconda
    rm "$HOME/miniconda.sh"
fi

# Source zshrc
source "$HOME/.zshrc"

# Check if nvim exists; install if not (you may want to add this part)

