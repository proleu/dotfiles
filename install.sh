#!/bin/bash

# Define and sort all required packages
required_packages=(
  build-essential
  ca-certificates
  curl
  fzf
  fuse
  gh
  jq
  libbz2-dev
  libffi-dev
  libfuse2
  liblzma-dev
  libreadline-dev
  libsqlite3-dev
  libssl-dev
  make
  openjdk-11-jdk
  openvpn
  python3-dev
  tmux
  tree
  unzip
  wget
  zlib1g-dev
  zsh
)

echo "Updating package list and ensuring all utilities are installed or at their latest version..."
sudo apt update

# Install or update all required packages
sudo apt install -y "${required_packages[@]}"

# Check if running in Zsh
if [[ -n "$ZSH_VERSION" ]]; then
  echo "Running in Zsh."
else
  echo "Not running in Zsh. Attempting to change shell to Zsh..."
  if sudo chsh -s "$(which zsh)" "$USER"; then
    touch ${HOME}/.zshrc
    echo "Shell changed to Zsh. Please re-login. Exiting..."
    sleep 3
    exit 0
  else
    echo "Failed to change the shell. Please have someone with root access run 'chsh -s $(which zsh) $USER'."
  fi
fi

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

