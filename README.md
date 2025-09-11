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
./.system/install.sh

# Full install (includes package installation - Arch Linux only)
./.system/install.sh --full
```

## Installation Options

The installation scripts provide several options:

1. **Basic Installation**: Links configuration files to their appropriate locations

   ```bash
   ./.system/install.sh
   ```

2. **Full Installation**: Includes package installation with interactive options

   ```bash
   ./.system/install.sh --full
   ```

3. **Sync Local Changes**: Update dotfiles with current system configurations

   ```bash
   ./.system/sync_dotfiles.sh
   ```

4. **Restore on New System**: Restore configurations from dotfiles repository

   ```bash
   ./.system/restore_dotfiles.sh
   ```

## Security

Before committing any changes to your dotfiles repository, run the sanitize script to check for sensitive information:

```bash
./.system/sanitize.sh
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

- **.config/**: User configuration files
  - **hypr/**: Hyprland window manager configuration
  - **i3/**: i3 window manager configuration  
  - **kitty/**: Terminal emulator configuration
  - **rofi/**: Application launcher configuration
  - **waybar/**: Status bar configuration
  - **picom/**: Compositor settings with transparency rules
  - **dunst/**: Notification daemon configuration
  - **zsh/**: Shell configuration and themes
- **.system/**: System management scripts
  - **install.sh**: Main installation script with package dependencies
  - **restore_dotfiles.sh**: Script to restore configurations from repository
  - **sync_dotfiles.sh**: Comprehensive backup and sync script
  - **sanitize.sh**: Script to check for sensitive information
- **system/**: System-wide configuration backups (GRUB, packages, etc.)
- Root configuration files: .zshrc, .xinitrc, .Xresources, .zprofile
