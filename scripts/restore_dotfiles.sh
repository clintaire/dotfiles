#!/bin/bash

# Dotfiles Restoration Script
# This script restores configurations from the dotfiles repository

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
HOME_DIR="$HOME"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Restore user configurations
restore_user_configs() {
    log "Restoring user configurations..."
    
    # Core shell files
    for file in .zshrc .zprofile .xinitrc .Xresources; do
        if [[ -f "$DOTFILES_DIR/$file" ]]; then
            log "Restoring $file"
            cp "$DOTFILES_DIR/$file" "$HOME_DIR/"
        fi
    done
    
    # .config directory
    if [[ -d "$DOTFILES_DIR/.config" ]]; then
        log "Restoring .config directory"
        mkdir -p "$HOME_DIR/.config"
        cp -r "$DOTFILES_DIR/.config/"* "$HOME_DIR/.config/"
    fi
}

# Restore GRUB (requires sudo)
restore_grub() {
    log "Restoring GRUB configurations..."
    
    if [[ -f "$DOTFILES_DIR/system/grub_default" ]]; then
        log "Restoring GRUB default configuration"
        sudo cp "$DOTFILES_DIR/system/grub_default" "/etc/default/grub"
    fi
    
    if [[ -d "$DOTFILES_DIR/system/grub_theme" ]]; then
        log "Restoring GRUB theme"
        sudo mkdir -p "/usr/share/grub/themes/ayu-custom"
        sudo cp -r "$DOTFILES_DIR/system/grub_theme/"* "/usr/share/grub/themes/ayu-custom/"
    fi
    
    if [[ -d "$DOTFILES_DIR/system/grub.d" ]]; then
        log "Restoring GRUB custom scripts"
        sudo cp -r "$DOTFILES_DIR/system/grub.d/"* "/etc/grub.d/"
        sudo chmod +x /etc/grub.d/*
    fi
    
    # Regenerate GRUB config
    if [[ -f "/etc/default/grub" ]]; then
        log "Regenerating GRUB configuration"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

# Install packages
install_packages() {
    log "Installing packages..."
    
    if [[ -f "$DOTFILES_DIR/system/packages_explicit.txt" ]]; then
        log "Installing explicit packages"
        sudo pacman -S --needed - < "$DOTFILES_DIR/system/packages_explicit.txt"
    fi
    
    if [[ -f "$DOTFILES_DIR/system/packages_aur.txt" ]] && command -v yay >/dev/null 2>&1; then
        log "Installing AUR packages"
        yay -S --needed - < "$DOTFILES_DIR/system/packages_aur.txt"
    fi
    
    if [[ -f "$DOTFILES_DIR/system/packages_flatpak.txt" ]] && command -v flatpak >/dev/null 2>&1; then
        log "Installing Flatpak packages"
        while read -r app; do
            [[ -n "$app" ]] && flatpak install -y "$app"
        done < "$DOTFILES_DIR/system/packages_flatpak.txt"
    fi
}

# Main restoration function
main() {
    log "Starting dotfiles restoration..."
    
    restore_user_configs
    
    read -p "Restore system configurations (GRUB, etc.)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restore_grub
    fi
    
    read -p "Install packages from package lists? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_packages
    fi
    
    log "Dotfiles restoration completed!"
}

main "$@"
