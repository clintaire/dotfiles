#!/bin/bash
# Auto-detect and set appropriate DPI for display

# Get display resolution and physical size
DISPLAY_INFO=$(xrandr --query | grep ' connected primary')
if [ -z "$DISPLAY_INFO" ]; then
    DISPLAY_INFO=$(xrandr --query | grep ' connected' | head -1)
fi

# Extract resolution
RESOLUTION=$(echo "$DISPLAY_INFO" | grep -o '[0-9]\+x[0-9]\+' | head -1)
WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)

# Determine DPI based on resolution width
if [ "$WIDTH" -ge 2560 ]; then
    DPI=144  # 4K or high-res displays
elif [ "$WIDTH" -ge 1920 ]; then
    DPI=96   # Full HD displays
else
    DPI=96   # Standard/lower res displays
fi

# Update Xresources with detected DPI
sed -i "s/^Xft\.dpi:.*/Xft.dpi:            $DPI/" ~/.Xresources-i3

# Reload Xresources
xrdb -merge ~/.Xresources-i3

echo "$(date '+%Y-%m-%d %H:%M:%S') - DPI Setup: Set DPI to $DPI for resolution $RESOLUTION" >> ~/.config/i3/dpi.log