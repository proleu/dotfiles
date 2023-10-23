#!/bin/bash

# Check if 'make' and 'zsh' are installed, if not, install them
packages_to_install=()
if ! command -v make &> /dev/null; then
  packages_to_install+=("make")
fi

if ! command -v zsh &> /dev/null; then
  packages_to_install+=("zsh")
fi

if [ ${#packages_to_install[@]} -gt 0 ]; then
  echo "Installing required packages: ${packages_to_install[@]}"
  sudo apt update && sudo apt install -y "${packages_to_install[@]}"
fi

# Attempt to change the shell to Zsh
if sudo chsh -s $(which zsh) $USER; then
  echo "Shell changed to Zsh."
else
  echo "Failed to change the shell. Please have someone with root access run 'chsh -s $(which zsh) $USER'."
fi

echo "Please restart your shell to complete the shell change, then press any key to continue..."
read -n 1 -s

make -f Makefile

