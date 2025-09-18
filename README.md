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
./.system/dotsetup.sh

# Full install (includes package installation - Arch Linux only)
./.system/dotsetup.sh --full
```

## Installation Options

The installation scripts provide several options:

1. **Basic Installation**: Links configuration files to their appropriate locations

   ```bash
   ./.system/dotsetup.sh
   ```

2. **Full Installation**: Includes package installation with interactive options

   ```bash
   ./.system/dotsetup.sh --full
   ```

3. **Sync Local Changes**: Update dotfiles with current system configurations

   ```bash
   ./.system/dotbackup.sh
   ```

4. **Restore on New System**: Restore configurations from dotfiles repository

   ```bash
   ./.system/dotrestore.sh
   ```

## Security

Before committing any changes to your dotfiles repository, run the sanitize script to check for sensitive information:

```bash
./.system/dotscan.sh
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
  - **dotsetup.sh**: Main installation script with package dependencies
  - **dotrestore.sh**: Script to restore configurations from repository
  - **dotbackup.sh**: Comprehensive backup and sync script
  - **dotscan.sh**: Script to check for sensitive information
  - **dnspro.sh**: Enterprise DNS setup with monitoring and failover
  - **dnsbasic.sh**: Basic secure DNS setup with encryption
  - **dockersec.sh**: Docker security hardening script
  - **emergency.sh**: Emergency network/DNS recovery script
  - **testdns.sh**: DNS testing in containerized environment
- **system/**: System-wide configuration backups (GRUB, packages, etc.)
- Root configuration files: .zshrc, .xinitrc, .Xresources, .zprofile

## System Scripts Reference

### Dotfiles Management
- **`dotsetup.sh`** - Main installation script
  ```bash
  ./dotsetup.sh         # Basic install (configs only)
  ./dotsetup.sh --full  # Full install with packages
  ```

- **`dotbackup.sh`** - Backup current configurations to repository
  ```bash
  ./dotbackup.sh
  ```

- **`dotrestore.sh`** - Restore configurations from repository
  ```bash
  ./dotrestore.sh
  ```

- **`dotscan.sh`** - Security scan for sensitive information
  ```bash
  ./dotscan.sh
  ```

### DNS & Network Security
- **`dnspro.sh`** - Enterprise DNS with monitoring & auto-recovery
  ```bash
  sudo ./dnspro.sh install    # Install enterprise DNS
  ./dnspro.sh status          # Check status
  ./dnspro.sh monitor         # Live monitoring
  ```

- **`dnsbasic.sh`** - Basic secure DNS setup
  ```bash
  sudo ./dnsbasic.sh install  # Install basic DNS
  ./dnsbasic.sh status        # Check status
  sudo ./dnsbasic.sh restore  # Restore original
  ```

- **`emergency.sh`** - Emergency network recovery
  ```bash
  sudo ./emergency.sh         # Emergency DNS/network fix
  ```

### System Security
- **`dockersec.sh`** - Docker security hardening
  ```bash
  ./dockersec.sh install      # Harden Docker
  ./dockersec.sh status       # Check security status
  ```

- **`testdns.sh`** - Test DNS configurations safely
  ```bash
  ./testdns.sh test           # Automated testing
  ./testdns.sh interactive    # Manual testing
  ```

## Troubleshooting

If you encounter DNS/network issues:
1. Run emergency recovery: `sudo ./.system/emergency.sh`
2. Check DNS status: `./.system/dnspro.sh status`
3. Test in container: `./.system/testdns.sh test`


## License

[MIT](./LICENSE) &copy; [GitHub](https://github.com/clintaire)

