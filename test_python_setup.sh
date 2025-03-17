#\!/bin/bash
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
echo "Checking that pip, wheel, setuptools, virtualenv, and awscli are installed..."
if [ -f "${HOME}/dotfiles/.venv/bin/python" ]; then
    for pkg in pip wheel setuptools virtualenv awscli; do
        if ${HOME}/dotfiles/.venv/bin/python -m pip list | grep -q "$pkg"; then
            echo "✅ $pkg is installed"
        else
            echo "❌ $pkg is NOT installed"
            exit 1
        fi
    done
fi

# Test activation
echo
echo "Testing environment activation..."
source "${HOME}/dotfiles/.venv/bin/activate"
if [ "$VIRTUAL_ENV" = "${HOME}/dotfiles/.venv" ]; then
    echo "✅ Environment activated successfully"
    deactivate
    echo "✅ Environment deactivated successfully"
else
    echo "❌ Environment activation failed"
    exit 1
fi

echo
echo "=== All tests passed\! ==="
echo "The Python environment setup works correctly."
