#!/usr/bin/env bash

# Dotfiles installation script
# Usage: ./install.sh [--full]
# --full: Install packages and dependencies too

set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Log helpers
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Create a symbolic link if the target doesn't exist
link_safe() {
  local src="$1"
  local dest="$2"
  
  # Check if the source exists
  if [ ! -e "$src" ]; then
    log_error "Source does not exist: $src"
    return 1
  fi

  # Handle existing destination
  if [ -e "$dest" ]; then
    # If it's already a symlink to our target, we're good
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      log_info "Link already exists: $dest -> $src"
      return 0
    fi
    
    # Backup the file/directory
    local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
    log_warn "Backing up existing file: $dest -> $backup"
    mv "$dest" "$backup"
  fi
  
  # Create parent directory if needed
  mkdir -p "$(dirname "$dest")"
  
  # Create the symbolic link
  ln -sf "$src" "$dest"
  log_success "Linked: $dest -> $src"
}

# Install packages if --full flag is provided
# Install packages if --full flag is provided
install_packages() {
  if command_exists pacman; then
    log_info "Do you want to use the interactive app installation script? (y/N)"
    read -p " " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      log_info "Running apps.sh script..."
      "$DOTFILES_DIR/scripts/apps.sh"
    else
      log_info "Installing essential packages..."
      
      # Check if running as root or using sudo
      if [ "$(id -u)" -ne 0 ]; then
        if command_exists sudo; then
          INSTALL_CMD="sudo pacman -S --needed --noconfirm"
        else
          log_error "Need root privileges to install packages. Run with sudo or as root."
          return 1
        fi
      else
        INSTALL_CMD="pacman -S --needed --noconfirm"
      fi
      
      # Base packages
      $INSTALL_CMD i3-wm i3blocks i3status dmenu picom kitty zsh tmux neovim ranger \
        feh dunst zathura zathura-pdf-poppler thunar papirus-icon-theme \
        arc-gtk-theme xorg-xset xorg-xrdb xorg-xinit
      
      # Oh-My-Zsh
      if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      fi
    fi
  else
    log_error "Pacman not found. Cannot install packages automatically."
    log_info "Please install packages manually according to your distribution."
  fi
}

# Link configuration files
link_configs() {
  log_info "Creating symbolic links for configuration files..."
  
  # Ensure config directory exists
  mkdir -p "$CONFIG_DIR"
  
  # Window Manager (i3)
  link_safe "$DOTFILES_DIR/i3" "$CONFIG_DIR/i3"
  
  # Status Bar
  link_safe "$DOTFILES_DIR/i3blocks" "$CONFIG_DIR/i3blocks"
  [ -d "$DOTFILES_DIR/polybar" ] && link_safe "$DOTFILES_DIR/polybar" "$CONFIG_DIR/polybar"
  
  # Compositor (picom)
  link_safe "$DOTFILES_DIR/picom" "$CONFIG_DIR/picom"
  
  # Terminal
  link_safe "$DOTFILES_DIR/kitty" "$CONFIG_DIR/kitty"
  
  # Document viewer
  link_safe "$DOTFILES_DIR/zathura" "$CONFIG_DIR/zathura"
  
  # File manager
  [ -d "$DOTFILES_DIR/thunar" ] && link_safe "$DOTFILES_DIR/thunar" "$CONFIG_DIR/thunar"
  
  # Notifications
  [ -d "$DOTFILES_DIR/dunst" ] && link_safe "$DOTFILES_DIR/dunst" "$CONFIG_DIR/dunst"
  
  # File manager
  [ -d "$DOTFILES_DIR/ranger" ] && link_safe "$DOTFILES_DIR/ranger" "$CONFIG_DIR/ranger"
  
  # XFCE4 (if you use any XFCE components)
  [ -d "$DOTFILES_DIR/xfce4" ] && link_safe "$DOTFILES_DIR/xfce4" "$CONFIG_DIR/xfce4"
  
  # Shell (ZSH)
  [ -d "$DOTFILES_DIR/zsh" ] && {
    # If you have custom Oh-My-Zsh themes
    if [ -d "$DOTFILES_DIR/zsh/oh-my-zsh-themes" ] && [ -d "$HOME/.oh-my-zsh/custom/themes" ]; then
      for theme in "$DOTFILES_DIR"/zsh/oh-my-zsh-themes/*.zsh-theme; do
        if [ -f "$theme" ]; then
          theme_name=$(basename "$theme")
          link_safe "$theme" "$HOME/.oh-my-zsh/custom/themes/$theme_name"
        fi
      done
    fi
  }
  
  # ZSH configuration
  [ -f "$DOTFILES_DIR/.zshrc" ] && link_safe "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  
  # X11 configuration
  [ -f "$DOTFILES_DIR/.xinitrc" ] && link_safe "$DOTFILES_DIR/.xinitrc" "$HOME/.xinitrc"
  [ -f "$DOTFILES_DIR/.Xresources" ] && link_safe "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources"
  
  log_success "Configuration files linked successfully!"
}

# Set up system configurations (requires sudo)
setup_system() {
  if [ "$(id -u)" -ne 0 ] && ! command_exists sudo; then
    log_warn "Skipping system setup: need root privileges or sudo"
    return 0
  fi
  
  local SUDO=""
  [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  
  # GRUB theme
  if [ -d "$DOTFILES_DIR/grub_theme" ] && [ -d "/usr/share/grub/themes" ]; then
    log_info "Setting up GRUB theme..."
    $SUDO mkdir -p "/usr/share/grub/themes/ayu-custom"
    $SUDO cp -r "$DOTFILES_DIR/grub_theme/"* "/usr/share/grub/themes/ayu-custom/"
    
    # Update GRUB configuration if not already set
    if ! grep -q "GRUB_THEME=\"/usr/share/grub/themes/ayu-custom/theme.txt\"" /etc/default/grub; then
      log_info "Updating GRUB configuration..."
      $SUDO sed -i '/GRUB_THEME=/d' /etc/default/grub
      echo 'GRUB_THEME="/usr/share/grub/themes/ayu-custom/theme.txt"' | $SUDO tee -a /etc/default/grub > /dev/null
      $SUDO grub-mkconfig -o /boot/grub/grub.cfg
    else
      log_info "GRUB theme already configured in /etc/default/grub"
    fi
  fi
  
  # SDDM configuration
  if [ -d "$DOTFILES_DIR/sddm/conf.d" ]; then
    log_info "Setting up SDDM configuration..."
    $SUDO mkdir -p "/etc/sddm.conf.d"
    $SUDO cp -r "$DOTFILES_DIR/sddm/conf.d/"* "/etc/sddm.conf.d/"
  fi
  
  # SDDM theme if you have custom theme files
  if [ -d "$DOTFILES_DIR/sddm/themes" ] && [ -d "/usr/share/sddm/themes" ]; then
    log_info "Setting up SDDM themes..."
    for theme in "$DOTFILES_DIR"/sddm/themes/*; do
      if [ -d "$theme" ]; then
        theme_name=$(basename "$theme")
        $SUDO mkdir -p "/usr/share/sddm/themes/$theme_name"
        $SUDO cp -r "$theme/"* "/usr/share/sddm/themes/$theme_name/"
      fi
    done
  fi
}

# Verify no sensitive information is committed
check_sensitive() {
  if [ -x "$DOTFILES_DIR/.system/dotscan.sh" ]; then
    log_info "Checking for sensitive information..."
    "$DOTFILES_DIR/.system/dotscan.sh"
  fi
}

main() {
  log_info "Starting dotfiles installation..."
  
  # Check for sensitive information
  check_sensitive
  
  # Check for --full flag
  if [[ "$1" == "--full" ]]; then
    install_packages
  fi
  
  # Link configuration files
  link_configs
  
  # Set up system-wide configurations
  setup_system
  
  log_success "Dotfiles installation complete!"
  log_info "Please log out and log back in for all changes to take effect."
}

main "$@"
