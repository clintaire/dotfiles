#!/bin/sh

# Merge in defaults and keymaps
if [ -f $HOME/.Xresources ]; then
    xrdb -merge $HOME/.Xresources
fi

# Start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# For NVIDIA Prime
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto

# Start your preferred window manager/desktop environment here
exec startx
