#!/bin/bash
set -e  # Exit immediately if a command fails

echo "Setting up Python configuration files..."
DOTFILES_VENV="${HOME}/dotfiles/.venv"

# Enhanced PATH setting for uv 
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

echo "Checking for uv in PATH..."
# Explicitly look for uv in common locations if command -v fails
if ! command -v uv > /dev/null 2>&1; then
    for uv_path in "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv" "/usr/local/bin/uv" "/usr/bin/uv"; do
        if [ -f "$uv_path" ]; then
            echo "Found uv at $uv_path, adding to PATH"
            export PATH="$(dirname "$uv_path"):$PATH"
            break
        fi
    done
fi

# Verify uv is now available
if command -v uv > /dev/null 2>&1; then
    echo "✅ uv is available: $(uv --version)"
    
    # Detect Python versions available in the system
    echo "Detecting available Python versions..."
    PYTHON_VERSION="3.11"
    
    # Check if Python 3.11 is available through uv
    if uv python list 2>/dev/null | grep -q "3.11"; then
        echo "Using Python 3.11 from uv"
    # If Python 3.11 is available in system
    elif command -v python3.11 > /dev/null 2>&1; then
        echo "Using system Python 3.11"
        PYTHON_VERSION="$(python3.11 --version | cut -d' ' -f2 | cut -d'.' -f1,2)"
    # Check for any uv Python versions
    elif uv python list 2>/dev/null | grep -q "3."; then
        HIGHEST_VERSION=$(uv python list 2>/dev/null | grep "3\." | sort -V | tail -n 1)
        PYTHON_VERSION=$(echo "$HIGHEST_VERSION" | grep -oE "3\.[0-9]+")
        echo "Using highest available uv Python: $PYTHON_VERSION"
    # Fall back to whatever system Python version is available
    elif command -v python3 > /dev/null 2>&1; then
        PYTHON_VERSION="$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)"
        echo "Falling back to system Python $PYTHON_VERSION"
    # Desperate fallback to Python 2 if available
    elif command -v python > /dev/null 2>&1 && python --version 2>&1 | grep -q "Python 2"; then
        echo "⚠️ WARNING: Only Python 2 found in system. This is not recommended."
        echo "Will attempt to use uv's default Python version instead."
        PYTHON_VERSION=""  # Let uv choose a default version
    else
        echo "⚠️ No suitable Python version found. Attempting to continue with default."
        PYTHON_VERSION=""  # Let uv choose a default version
    fi
    
    # Additional Python version diagnostic
    echo "Available Python versions in PATH:"
    for py_cmd in python python2 python3 python3.8 python3.9 python3.10 python3.11 python3.12; do
        if command -v $py_cmd > /dev/null 2>&1; then
            echo "- $py_cmd: $($py_cmd --version 2>&1)"
        fi
    done
    
    echo "Creating dotfiles environment at $DOTFILES_VENV using Python $PYTHON_VERSION..."
    # Remove any existing environment to ensure clean setup
    rm -rf "$DOTFILES_VENV"
    mkdir -p "$DOTFILES_VENV"
    
    # Create virtual environment with uv, with multiple fallback strategies
    if [ -n "$PYTHON_VERSION" ]; then
        echo "Attempting to create venv with Python $PYTHON_VERSION"
        uv venv -p "$PYTHON_VERSION" "$DOTFILES_VENV" || {
            echo "Failed with specific version, trying without version specification"
            uv venv "$DOTFILES_VENV" || {
                echo "uv venv creation failed, trying alternative methods"
                # Try standard venv module with system Python
                if command -v python3 > /dev/null 2>&1; then
                    echo "Attempting venv creation with system Python"
                    python3 -m venv "$DOTFILES_VENV"
                fi
            }
        }
    else
        echo "No specific Python version selected, using uv default"
        uv venv "$DOTFILES_VENV" || {
            echo "Default uv venv creation failed, trying system Python"
            # Fall back to system Python
            if command -v python3 > /dev/null 2>&1; then
                echo "Creating venv with system Python"
                python3 -m venv "$DOTFILES_VENV"
            fi
        }
    fi
    
    if [ -f "${DOTFILES_VENV}/bin/python" ]; then
        echo "Installing essential packages in dotfiles environment..."
        # Use uv pip directly to install packages with fallback to regular pip
        uv pip install --python "${DOTFILES_VENV}/bin/python" pip wheel setuptools virtualenv awscli || {
            echo "uv pip failed, trying regular pip installation"
            "${DOTFILES_VENV}/bin/pip" install --upgrade pip wheel setuptools virtualenv awscli
        }
        
        # Inform user about manual activation
        echo "✅ Dotfiles Python environment created successfully"
        echo "To activate it, run:"
        echo "  venv"
        echo "To activate any virtual environment in the current directory:"
        echo "  venv"
        echo "To deactivate:"
        echo "  venv off"
    else
        echo "❌ Failed to create virtual environment with uv."
        echo "Trying alternative approach with standard venv module..."
        
        # Fallback to using the system's Python venv module
        if command -v python3 > /dev/null 2>&1; then
            python3 -m venv "$DOTFILES_VENV"
            if [ -f "${DOTFILES_VENV}/bin/python" ]; then
                echo "Installing essential packages using standard pip..."
                "${DOTFILES_VENV}/bin/pip" install --upgrade pip wheel setuptools virtualenv awscli
                echo "✅ Dotfiles Python environment created successfully using system Python"
                echo "To activate it, run:"
                echo "  venv"
                echo "To deactivate:"
                echo "  venv off"
            else
                echo "❌ Failed to create virtual environment with system Python."
            fi
        else
            echo "❌ No Python 3 installation found. Cannot create virtual environment."
        fi
    fi
else
    echo "⚠️ WARNING: uv not found in PATH, trying to install it..."
    
    # Attempt to install uv if not found
    curl -LsSf https://astral.sh/uv/install.sh | DEST=$HOME/.local/bin sh
    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v uv > /dev/null 2>&1; then
        echo "✅ uv installed successfully. Re-running setup script..."
        exec "$0"  # Re-run this script from the beginning
    else
        echo "❌ Failed to install uv. Falling back to system tools..."
        
        # Create venv using system tools
        if command -v python3 > /dev/null 2>&1; then
            echo "Creating virtual environment using system Python..."
            python3 -m venv "$DOTFILES_VENV"
            
            if [ -f "${DOTFILES_VENV}/bin/python" ]; then
                echo "Installing essential packages..."
                "${DOTFILES_VENV}/bin/pip" install --upgrade pip wheel setuptools virtualenv awscli
                echo "✅ Dotfiles Python environment created with system Python"
            else
                echo "❌ Failed to create virtual environment."
            fi
        else
            echo "❌ No Python 3 installation found. Cannot set up environment."
            echo "Please install Python 3 or uv manually and run 'just link-python-config' again."
        fi
    fi
fi