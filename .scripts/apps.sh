#!/bin/bash

# apps.sh - Script to install commonly used applications
# Created as part of dotfiles setup

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to ask for confirmation
confirm() {
    read -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Exit on error
set -e

echo -e "${GREEN}=== Application Installation Script ===${NC}"
echo "This script will help you install common applications for your Arch Linux setup."
echo "You will be prompted before each category of applications is installed."
echo

# Update package database
if confirm "Do you want to update the package database?"; then
    echo -e "${BLUE}Updating package database...${NC}"
    yay -Syu
fi

# Install basic utilities
if confirm "Install basic utilities (git, curl, wget, htop, tmux, etc.)?"; then
    echo -e "${BLUE}Installing basic utilities...${NC}"
    yay -S --needed \
        base-devel git curl wget \
        htop tmux neovim vim nano \
        zip unzip \
        networkmanager network-manager-applet \
        sudo efibootmgr grub os-prober \
        lsof bind
fi

# Install X.org
if confirm "Install X.org packages?"; then
    echo -e "${BLUE}Installing X.org packages...${NC}"
    yay -S --needed \
        xorg-server xorg-xinit xorg-xrandr xorg-xbacklight \
        xorg-xset xorg-xsetroot xorg-xprop \
        xorg-xinput xclip
fi

# Install fonts
if confirm "Install fonts?"; then
    echo -e "${BLUE}Installing fonts...${NC}"
    yay -S --needed \
        ttf-dejavu ttf-liberation ttf-roboto \
        ttf-ubuntu-font-family ttf-meslo \
        noto-fonts noto-fonts-cjk \
        terminus-font adobe-source-code-pro-fonts
fi

# Install window manager and desktop environment
if confirm "Install i3 and related packages?"; then
    echo -e "${BLUE}Installing i3 and related packages...${NC}"
    yay -S --needed \
        i3-wm i3blocks i3status \
        dmenu rofi \
        picom dunst \
        feh imagemagick
fi

# Install display manager (with check)
if confirm "Check/Install SDDM display manager? (Skip if already installed)"; then
    if pacman -Qs sddm > /dev/null; then
        echo -e "${YELLOW}SDDM is already installed. Skipping...${NC}"
    else
        echo -e "${BLUE}Installing SDDM...${NC}"
        yay -S --needed sddm
        
        if confirm "Enable SDDM service?"; then
            sudo systemctl enable sddm
        fi
    fi
fi

# Install file managers and related tools
if confirm "Install file managers and related tools?"; then
    echo -e "${BLUE}Installing file managers and related tools...${NC}"
    yay -S --needed \
        thunar thunar-volman thunar-archive-plugin \
        gvfs ranger tumbler ffmpegthumbnailer \
        poppler poppler-glib libgsf
fi

# Install media applications
if confirm "Install media applications (mpv, vlc, etc.)?"; then
    echo -e "${BLUE}Installing media applications...${NC}"
    yay -S --needed \
        mpv vlc \
        cava pamixer \
        pipewire pipewire-pulse
fi

# Install browsers and internet tools
if confirm "Install Brave browser?"; then
    echo -e "${BLUE}Installing Brave browser...${NC}"
    yay -S --needed brave-bin
fi

# Install development tools
if confirm "Install development tools (gcc, python, nodejs, etc.)?"; then
    echo -e "${BLUE}Installing development tools...${NC}"
    yay -S --needed \
        gcc make \
        python-pip nodejs npm \
        go rust \
        docker docker-compose
    
    if confirm "Enable Docker service?"; then
        sudo systemctl enable docker
    fi
fi

# Install terminal emulator
if confirm "Install Kitty terminal emulator?"; then
    echo -e "${BLUE}Installing Kitty terminal emulator...${NC}"
    yay -S --needed kitty
fi

# Install document viewers
if confirm "Install document viewers (zathura)?"; then
    echo -e "${BLUE}Installing document viewers...${NC}"
    yay -S --needed zathura zathura-pdf-mupdf
fi

# Install themes and icons
if confirm "Install themes and icons?"; then
    echo -e "${BLUE}Installing themes and icons...${NC}"
    yay -S --needed \
        arc-gtk-theme papirus-icon-theme adwaita-dark \
        lxappearance
fi

# Install NVIDIA drivers
if confirm "Install NVIDIA drivers?"; then
    echo -e "${BLUE}Installing NVIDIA drivers...${NC}"
    yay -S --needed \
        nvidia-dkms nvidia-utils nvidia-prime
fi

# Install additional applications
if confirm "Install additional applications (VSCode, Obsidian, etc.)?"; then
    echo -e "${BLUE}Installing additional applications...${NC}"
    yay -S --needed \
        visual-studio-code-bin obsidian-bin thunderbird-bin \
        fastfetch tldr \
        anki-bin
fi

# Enable essential services
if confirm "Enable essential services (NetworkManager, Bluetooth)?"; then
    echo -e "${BLUE}Enabling essential services...${NC}"
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
fi

echo -e "${GREEN}=== Application installation complete ===${NC}"
echo -e "${YELLOW}Note: You may need to reboot for some changes to take effect.${NC}"
