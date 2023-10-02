#!/bin/bash

# Check if 'make' is installed, if not, install it
if ! command -v make &> /dev/null; then
  echo "'make' is not installed. Installing now..."
  sudo apt update && sudo apt install -y make
fi

# Check if Zsh is installed, if not, install it
if ! command -v zsh &> /dev/null; then
  echo "Zsh is not installed. Installing now..."
  sudo apt update && sudo apt install -y zsh
fi

# Attempt to change the shell to Zsh
if sudo chsh -s $(which zsh) $USER; then
  echo "Shell changed to Zsh."
else
  echo "Failed to change the shell. Please have someone with root access run 'chsh -s $(which zsh) $USER'."
fi

echo "Please restart your shell to complete the shell change, then press any key to continue..."
read -n 1 -s

# Run the Makefiles
make -f ShellSetupMakefile
make -f EnvironmentSetupMakefile
