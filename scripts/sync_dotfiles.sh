#!/bin/bash

# Comprehensive Dotfiles Backup and Sync Script
# This script backs up all important system configurations to the dotfiles repository

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
HOME_DIR="$HOME"
BACKUP_DATE=$(date '+%Y%m%d_%H%M%S')

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

# Function to safely copy files/directories
safe_copy() {
    local src="$1"
    local dest="$2"
    local backup_name="$3"
    
    if [[ ! -e "$src" ]]; then
        warn "Source $src does not exist, skipping..."
        return
    fi
    
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Backup existing file if it exists and is different
    if [[ -e "$dest" ]] && ! diff -q "$src" "$dest" >/dev/null 2>&1; then
        log "Backing up existing $dest to ${dest}.${BACKUP_DATE}.bak"
        if [[ -d "$dest" ]]; then
            cp -r "$dest" "${dest}.${BACKUP_DATE}.bak"
        else
            cp "$dest" "${dest}.${BACKUP_DATE}.bak"
        fi
    fi
    
    # Copy the file/directory
    if [[ -d "$src" ]]; then
        log "Syncing directory: $backup_name"
        # Remove destination if it exists, then copy
        [[ -d "$dest" ]] && rm -rf "$dest"
        cp -r "$src" "$dest"
    else
        log "Syncing file: $backup_name"
        cp "$src" "$dest"
    fi
}

# Function to backup GRUB configurations
backup_grub() {
    log "Backing up GRUB configurations..."
    
    # Copy GRUB default config
    if [[ -f "/etc/default/grub" ]]; then
        safe_copy "/etc/default/grub" "$DOTFILES_DIR/system/grub_default" "GRUB default config"
    fi
    
    # Copy custom GRUB theme if it exists
    if [[ -d "/usr/share/grub/themes/ayu-custom" ]]; then
        safe_copy "/usr/share/grub/themes/ayu-custom" "$DOTFILES_DIR/system/grub_theme" "GRUB custom theme"
    fi
    
    # Copy any custom GRUB scripts
    if [[ -d "/etc/grub.d" ]]; then
        mkdir -p "$DOTFILES_DIR/system/grub.d"
        # Only copy custom scripts (40_custom and above)
        for script in /etc/grub.d/40_* /etc/grub.d/41_*; do
            if [[ -f "$script" ]]; then
                safe_copy "$script" "$DOTFILES_DIR/system/grub.d/$(basename "$script")" "GRUB custom script $(basename "$script")"
            fi
        done
    fi
}

# Function to sync user configurations
sync_user_configs() {
    log "Syncing user configurations..."
    
    # Core shell files
    for file in .zshrc .zprofile .xinitrc .Xresources; do
        if [[ -f "$HOME_DIR/$file" ]]; then
            safe_copy "$HOME_DIR/$file" "$DOTFILES_DIR/$file" "$file"
        fi
    done
    
    # .config directory configurations
    local config_dirs=(
        "hypr" "i3" "i3blocks" "kitty" "rofi" "picom" "polybar" 
        "dunst" "ranger" "zathura" "gtk-2.0" "gtk-3.0" "xfce4"
        "tmux" "flameshot" "waybar"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$HOME_DIR/.config/$dir" ]]; then
            safe_copy "$HOME_DIR/.config/$dir" "$DOTFILES_DIR/.config/$dir" ".config/$dir"
        fi
    done
    
    # Special handling for some configs that might have sensitive data
    if [[ -f "$HOME_DIR/.config/mimeapps.list" ]]; then
        safe_copy "$HOME_DIR/.config/mimeapps.list" "$DOTFILES_DIR/.config/mimeapps.list" "mimeapps.list"
    fi
}

# Function to backup system-wide configurations
backup_system_configs() {
    log "Backing up system configurations (requires sudo)..."
    
    # Create system backup directory
    mkdir -p "$DOTFILES_DIR/system"
    
    # X11 configurations
    if [[ -d "/etc/X11/xorg.conf.d" ]]; then
        safe_copy "/etc/X11/xorg.conf.d" "$DOTFILES_DIR/system/xorg.conf.d" "X11 configuration"
    fi
    
    # Font configurations
    if [[ -f "/etc/fonts/local.conf" ]]; then
        safe_copy "/etc/fonts/local.conf" "$DOTFILES_DIR/system/fonts_local.conf" "Font configuration"
    fi
    
    # Pacman configuration
    if [[ -f "/etc/pacman.conf" ]]; then
        safe_copy "/etc/pacman.conf" "$DOTFILES_DIR/system/pacman.conf" "Pacman configuration"
    fi
    
    # Makepkg configuration
    if [[ -f "/etc/makepkg.conf" ]]; then
        safe_copy "/etc/makepkg.conf" "$DOTFILES_DIR/system/makepkg.conf" "Makepkg configuration"
    fi
}

# Function to create package lists
create_package_lists() {
    log "Creating package lists..."
    mkdir -p "$DOTFILES_DIR/system"
    
    # Installed packages
    pacman -Qqe > "$DOTFILES_DIR/system/packages_explicit.txt"
    pacman -Qqd > "$DOTFILES_DIR/system/packages_dependencies.txt"
    
    # AUR packages (if yay is installed)
    if command -v yay >/dev/null 2>&1; then
        yay -Qqm > "$DOTFILES_DIR/system/packages_aur.txt"
    fi
    
    # Flatpak packages (if flatpak is installed)
    if command -v flatpak >/dev/null 2>&1; then
        flatpak list --app --columns=application > "$DOTFILES_DIR/system/packages_flatpak.txt" 2>/dev/null || true
    fi
    
    success "Package lists created"
}

# Function to create restore script
create_restore_script() {
    log "Creating restore script..."
    
    cat > "$DOTFILES_DIR/scripts/restore_dotfiles.sh" << 'EOF'
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
EOF

    chmod +x "$DOTFILES_DIR/scripts/restore_dotfiles.sh"
    success "Restore script created at scripts/restore_dotfiles.sh"
}

# Main function
main() {
    log "Starting comprehensive dotfiles backup..."
    log "Dotfiles directory: $DOTFILES_DIR"
    
    # Change to dotfiles directory
    cd "$DOTFILES_DIR"
    
    # Sync user configurations
    sync_user_configs
    
    # Ask for system configurations backup
    read -p "Backup system configurations (GRUB, etc.)? This requires sudo access [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_grub
        backup_system_configs
    fi
    
    # Create package lists
    create_package_lists
    
    # Create restore script
    create_restore_script
    
    # Git operations
    if [[ -d ".git" ]]; then
        log "Checking git status..."
        if ! git diff --quiet || ! git diff --cached --quiet; then
            log "Changes detected in repository"
            git add -A
            
            read -p "Commit changes? [Y/n]: " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                git commit -m "Automated dotfiles backup - $(date '+%Y-%m-%d %H:%M:%S')"
                success "Changes committed to git"
                
                read -p "Push to remote? [y/N]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    git push
                    success "Changes pushed to remote repository"
                fi
            fi
        else
            log "No changes detected in repository"
        fi
    fi
    
    success "Dotfiles backup completed successfully!"
    log "To restore on a new system, run: ./scripts/restore_dotfiles.sh"
}

# Run main function
main "$@"