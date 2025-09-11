# Dotfiles

My personal dotfiles for Arch Linux with i3 window manager.

![LOvE Always](ooxoo.jpg)

## Features

- **Window Manager**: i3 with custom keybindings and workspace configuration
- **Status Bar**: i3blocks and Polybar configurations
- **Terminal**: Kitty terminal emulator with Ayu theme
- **Compositor**: Picom with proper transparency for active/inactive windows
- **Shell**: Zsh with custom prompt and aliases
- **Appearance**: GTK themes, icons, and GRUB theme
- **Display Manager**: SDDM with custom theme
- **Applications**: Configs for ranger, dunst, zathura, and more
- **Installation Scripts**: Easy-to-use scripts for system replication

## Quick Install

To install these dotfiles on a new system:

```bash
# Clone the repository
git clone https://github.com/clintaire/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Basic install (just configs, no packages)
./install.sh

# Full install (includes package installation - Arch Linux only)
./install.sh --full
```

## Installation Options

The installation scripts provide several options:

1. **Basic Installation**: Links configuration files to their appropriate locations

   ```bash
   ./install.sh
   ```

2. **Full Installation**: Includes package installation with interactive options

   ```bash
   ./install.sh --full
   ```

   This will prompt you whether to use the interactive app installation script.

3. **Interactive App Installation**: The `scripts/apps.sh` script provides a detailed, interactive
   installation process that:

   - Asks for confirmation before installing each category of applications
   - Checks for already installed packages to avoid conflicts
   - Uses yay as the package manager
   - Provides clear organization of package categories

   ```bash
   ./scripts/apps.sh
   ```

## Security

Before committing any changes to your dotfiles repository, run the sanitize script to check for sensitive information:

```bash
./sanitize.sh
```

## Manual Configuration

If you prefer to install components individually:

1. **Window Manager (i3)**:

   ```bash
   ln -sf ~/.dotfiles/i3 ~/.config/i3
   ```

2. **Terminal (Kitty)**:

   ```bash
   ln -sf ~/.dotfiles/kitty ~/.config/kitty
   ```

3. **Shell (Zsh)**:

   ```bash
   ln -sf ~/.dotfiles/.zshrc ~/.zshrc
   ```

4. **Compositor (Picom)**:

   ```bash
   ln -sf ~/.dotfiles/picom ~/.config/picom
   ```

## Directory Structure

- **i3/**: Window manager configuration
- **kitty/**: Terminal emulator configuration
- **picom/**: Compositor settings with transparency rules
- **sddm/**: Display manager themes and configuration
- **scripts/**: Utility scripts for system setup and maintenance
  - **apps.sh**: Interactive application installation script
  - **clean.sh**: Cleanup script for temporary files
  - **install.sh**: Main installation script
  - **sanitize.sh**: Script to check for sensitive information
- **zsh/**: Shell configuration files and themes
