#!/usr/bin/env zsh
#
# ░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░
#
# Ensure this script is executable ⤵
#
# Run ==========================> chmod +x ~/.config/alacritty/switchtheme.sh
#
# Switching Themes ===================>  ⤵
#
# Run ==========================> ~/.config/alacritty/switchtheme.sh <theme-name>
#
# Example Commands ⤵
#
#  ~/.config/alacritty/switchtheme.sh gruvbox
#
#  ~/.config/alacritty/switchtheme.sh rust
#
#  ~/.config/alacritty/switchtheme.sh custom
#
# ░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░░ ░ ░

CONFIG_PATH="$HOME/.config/alacritty/alacritty.toml"
THEME_DIR="$HOME/.config/alacritty/themes"
THEME=$1

if [[ -f "$THEME_DIR/$THEME.toml" ]]; then
  sed -i '' "s|import = .*|import = [\"$THEME_DIR/$THEME.toml\"]|g" "$CONFIG_PATH"
  pkill -USR1 alacritty
else
  echo "Theme $THEME not found in $THEME_DIR" >> ~/alacritty-theme-switch.log
fi
