#!/bin/bash
# Enhanced NVIDIA setup for hybrid graphics
# Only runs if NVIDIA is available and not already configured

log_nvidia() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - NVIDIA Setup: $1" >> ~/.config/i3/nvidia.log
}

# Check if NVIDIA is available
if ! command -v nvidia-smi >/dev/null 2>&1; then
    log_nvidia "NVIDIA drivers not available, skipping setup"
    exit 0
fi

# Check if already configured
if xrandr --listproviders | grep -q "NVIDIA-0"; then
    log_nvidia "NVIDIA already configured"
else
    log_nvidia "Configuring NVIDIA as output source"
    if xrandr --setprovideroutputsource modesetting NVIDIA-0 2>/dev/null; then
        log_nvidia "NVIDIA output source set successfully"
        xrandr --auto
        log_nvidia "Display auto-configuration completed"
    else
        log_nvidia "Failed to set NVIDIA output source"
    fi
fi

