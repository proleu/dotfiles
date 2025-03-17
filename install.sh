#!/bin/bash

# Define and sort all required packages
required_packages=(
  build-essential
  ca-certificates
  curl
  fzf
  gnome-control-center
  jq
  libbz2-dev
  libffi-dev
  liblzma-dev
  libncursesw5-dev
  libreadline-dev
  libsqlite3-dev
  libssl-dev
  libxmlsec1-dev
  libxml2-dev
  openjdk-11-jdk
  openvpn
  python3-dev
  tk-dev
  tmux
  tree
  unzip
  wget
  xclip
  xz-utils
  zlib1g-dev
  zsh
)

echo "Updating package list and ensuring all utilities are installed or at their latest version..."
sudo apt update

# Install or update all required packages
sudo apt install -y "${required_packages[@]}"

# Special handling for GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI (gh) from official repository..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
else
    echo "GitHub CLI (gh) is already installed: $(gh --version | head -n 1)"
fi

# Install Just if not already installed
if ! type just &> /dev/null; then
  echo "Installing Just..."
  # Try using cargo if available
  if type cargo &> /dev/null; then
    cargo install just
  else
    # Otherwise download the prebuilt binary
    JUST_VERSION="1.19.0"
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case "$ARCH" in
      x86_64) ARCH="x86_64" ;;
      aarch64) ARCH="aarch64" ;;
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    JUST_DOWNLOAD_URL="https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${ARCH}-unknown-${OS}-musl.tar.gz"
    
    wget -q "$JUST_DOWNLOAD_URL" -O just.tar.gz
    tar -xzf just.tar.gz just
    sudo mv just /usr/local/bin/
    rm just.tar.gz
    
    echo "Just installed successfully."
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

# Check if the default shell is Zsh
if [ "$SHELL" = "$(which zsh)" ]; then
  echo "Default shell is already Zsh."
else
  echo "Default shell is not Zsh. Attempting to change shell to Zsh..."
  if sudo chsh -s "$(which zsh)" "$USER"; then
    touch ${HOME}/.zshrc
    echo "Shell changed to Zsh. Please re-login and rerun this script."
    echo "Or run"
    echo "cd ${HOME}/dotfiles && just"
    echo "Exiting..."
    sleep 3
    exit 0
  else
    echo "Failed to change the shell. Please have someone with root access run 'chsh -s $(which zsh) $USER'."
  fi
fi

# Run just to execute the default recipe
just
