#!/bin/bash
set -e  # Exit on error

echo "=== Testing Python Environment Setup ==="
echo

# Remove any existing environments 
echo "Removing existing environments for clean test..."
rm -rf "${HOME}/dotfiles/.venv" || true
rm -f "${HOME}/.local/bin/activate-dotfiles-env" || true

# Test uv installation
echo "Checking uv installation..."
if command -v uv > /dev/null 2>&1; then
    echo "✅ uv is installed: $(uv --version)"
else
    echo "❌ uv is not installed"
    echo "Installing uv now..."
    curl -LsSf https://astral.sh/uv/install.sh | DEST=$HOME/.local/bin sh
    
    if command -v uv > /dev/null 2>&1; then
        echo "✅ uv installed successfully"
    else
        echo "❌ Failed to install uv. Test cannot continue."
        exit 1
    fi
fi

# Test virtual environment creation
echo
echo "Running setup_python_config.sh to create virtual environment..."
bash -x ./setup_python_config.sh

# Validate environment existence
echo
echo "Validating dotfiles virtual environment..."
if [ -d "${HOME}/dotfiles/.venv" ]; then
    echo "✅ dotfiles virtual environment exists"
else
    echo "❌ Virtual environment was not created"
    exit 1
fi

# Validate Python version
echo
echo "Checking Python version in virtual environment..."
if [ -f "${HOME}/dotfiles/.venv/bin/python" ]; then
    PYTHON_VERSION=$(${HOME}/dotfiles/.venv/bin/python --version)
    echo "✅ Python in venv: $PYTHON_VERSION"
else
    echo "❌ Python interpreter not found in venv"
    exit 1
fi

# Validate packages
echo
echo "Checking that required packages are installed in the virtual environment..."
if [ -f "${HOME}/dotfiles/.venv/bin/python" ]; then
    for pkg in pip wheel setuptools virtualenv awscli; do
        if uv pip list --python "${HOME}/dotfiles/.venv/bin/python" | grep -q "$pkg"; then
            echo "✅ $pkg is installed in the venv"
        else
            echo "❌ $pkg is NOT installed in the venv"
            exit 1
        fi
    done
fi

# Check for system AWS CLI v2
echo
echo "Checking system AWS CLI installation..."
if command -v aws > /dev/null 2>&1; then
    AWS_VERSION=$(aws --version 2>&1)
    if [[ "$AWS_VERSION" == *"aws-cli/2."* ]]; then
        echo "✅ System AWS CLI v2 is installed: $AWS_VERSION"
    else
        echo "❌ System AWS CLI is not v2: $AWS_VERSION"
        echo "  To install AWS CLI v2, run: just install-aws"
    fi
else
    echo "ℹ️ System AWS CLI not found"
    echo "  To install AWS CLI v2, run: just install-aws"
fi

# Test manual activation capability
echo
echo "Manual activation can be done using:"
echo "1. Direct activation:"
echo "   source ${HOME}/dotfiles/.venv/bin/activate"
echo "2. Using the alias in zshrc:"
echo "   dotenv"
echo
echo "To deactivate:"
echo "   deactivate"

echo
echo "=== All tests passed\! ==="
echo "The Python environment setup works correctly."
