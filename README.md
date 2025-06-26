# dotfiles

A collection of dotfiles and setup scripts for configuring a new development environment.

## Quick Install

```bash
git clone https://github.com/proleu/dotfiles.git ; cd dotfiles; ./install.sh
```

## Available Commands

Run `just --list` to see all available commands. Here are the main ones:

- `just`: Run all setup and installation tasks
- `just update-gitconfig`: Configure git settings
- `just install-nvim`: Install Neovim editor
- `just install-pyenv`: Install Python environment

## Manual Installation

If the automatic installation fails, you can manually install Just and run the tasks:

1. Install Just:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin/
   ```

2. Run specific tasks:
   ```bash
   just install-nvim
   ```
