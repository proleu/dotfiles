#!/usr/bin/zsh

# Get the script's path
SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# Change to the user's home directory
cd $HOME

# Define the array of plugins and their GitHub URLs
declare -A plugins=(
    ["ohmyzsh-full-autoupdate"]="https://github.com/Pilaton/OhMyZsh-full-autoupdate.git"
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
    ["zsh-vi-mode"]="https://github.com/jeffreytse/zsh-vi-mode.git"
)

# Install Oh My Zsh only if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "Type 'exit' to continue installation script."
else
    echo "Oh My Zsh is already installed."
fi

# Overwrite the symbolic link for .zshrc, even if it exists
ln -sf "$SCRIPTPATH/.zshrc" "$HOME/.zshrc"

# Install or update zsh plugins from the associative array in a for loop
for plugin in "${(@k)plugins}"; do
    plugin_url="${plugins[$plugin]}"
    plugin_dir="$HOME/.oh-my-zsh/custom/plugins/$plugin"

    if [[ ! -d "$plugin_dir" ]]; then
        git clone "$plugin_url" "$plugin_dir"
    else
        echo "Plugin $plugin is already installed."
    fi
done

# Install or update Miniconda3
curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
if [[ ! -d "$HOME/miniconda3" ]]; then
    bash Miniconda3-latest-Linux-x86_64.sh -b -p "$HOME/miniconda3"
    rm Miniconda3-latest-Linux-x86_64.sh
else
    # Update Miniconda3
    bash Miniconda3-latest-Linux-x86_64.sh -b -u -p "$HOME/miniconda3"
    echo "Miniconda3 is updated."
fi

# Check if 'conda' command is available; initialize if not
if ! command -v conda &>/dev/null; then
    eval "$($HOME/miniconda3/bin/conda shell.zsh hook)"
    echo "Conda initialized."
fi

# Install or update Neovim
if ! command -v nvim &>/dev/null; then
    sudo apt-get install neovim -y
else
    echo "Neovim is already installed."
fi

echo "Setup is complete. To apply changes, restart the shell or type 'source ~/.zshrc'."

