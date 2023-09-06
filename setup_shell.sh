#!/usr/bin/bash

cd $HOME

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
    echo "zsh is now the default shell. restart the shell to apply changes."
    echo "after you restart, run setup_all.sh"
fi
