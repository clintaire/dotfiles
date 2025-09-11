# Auto-start X when logging in on TTY1
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi
