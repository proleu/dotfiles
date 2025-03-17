# dotfiles

A collection of dotfiles and setup scripts for configuring a new development environment.

## Quick Install

```bash
git clone https://github.com/proleu/dotfiles.git ; cd dotfiles; ./install.sh
```

## What's New

The project has transitioned from Make to Just for running tasks. Just is a modern command runner that provides improved syntax and features over Make.

### Advantages of Just:

1. **Simpler Syntax**: Just uses a simpler, more readable syntax compared to Makefiles.
2. **Better Shell Script Support**: Each recipe runs in its own isolated shell by default.
3. **Improved Dependency Handling**: Clearer dependency chains between tasks.
4. **Command Listing**: Run `just --list` to see all available commands.
5. **Better Documentation**: Each recipe can have its own documentation.

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
   cargo install just
   # or
   curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin/
   ```

2. Run specific tasks:
   ```bash
   just install-nvim
   ```