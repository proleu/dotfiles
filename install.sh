#!/bin/bash

# Check if 'make', 'zsh', and 'gh' are installed, if not, add them to the list to be installed
packages_to_install=()
if ! command -v make &> /dev/null; then
  packages_to_install+=("make")
fi

if ! command -v zsh &> /dev/null; then
  packages_to_install+=("zsh")
fi

if ! command -v gh &> /dev/null; then
  packages_to_install+=("gh")
fi

# Install required packages if any are missing
if [ ${#packages_to_install[@]} -gt 0 ]; then
  echo "Installing required packages: ${packages_to_install[@]}"
  sudo apt update && sudo apt install -y "${packages_to_install[@]}"
fi

# Attempt to change the shell to Zsh
if sudo chsh -s "$(which zsh)" "$USER"; then
  echo "Shell changed to Zsh."
else
  echo "Failed to change the shell. Please have someone with root access run 'chsh -s $(which zsh) $USER'."
fi

echo "Please restart your shell to complete the shell change, then press any key to continue..."
read -n 1 -s

# Check if user.name and user.email are already set
user_name=$(git config --get user.name)
user_email=$(git config --get user.email)

if [ -z "$user_name" ]; then
    read -r -p "Enter your GitHub full name: " user_name
    git config --global user.name "$user_name"
fi

if [ -z "$user_email" ]; then
    read -r -p "Enter your email address: " user_email
    git config --global user.email "$user_email"
fi

make -f Makefile

