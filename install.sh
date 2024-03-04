#!/bin/bash

# Define and sort all required packages
required_packages=(
  apt-transport-https
  fzf
  fuse
  gh
  jq
  libfuse2
  make
  openjdk-11-jdk
  openvpn
  tmux
  tree
  unzip
  zsh
)

echo "Updating package list and ensuring all utilities are installed or at their latest version..."
sudo apt update

# Install or update all required packages
sudo apt install -y "${required_packages[@]}"

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

