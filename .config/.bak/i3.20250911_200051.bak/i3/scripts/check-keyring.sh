#!/bin/bash
# Keyring status checker

echo "=== GNOME Keyring Status ==="
if pgrep -f gnome-keyring-daemon > /dev/null; then
    echo "[OK] GNOME Keyring daemon is running"
    echo "Process ID: $(pgrep -f gnome-keyring-daemon)"
else
    echo "[ERROR] GNOME Keyring daemon is NOT running"
fi

echo -e "\n=== Environment Variables ==="
echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-'Not set'}"
echo "GPG_AGENT_INFO: ${GPG_AGENT_INFO:-'Not set'}"
echo "GNOME_KEYRING_CONTROL: ${GNOME_KEYRING_CONTROL:-'Not set'}"

echo -e "\n=== Polkit Authentication Agent ==="
if pgrep -f polkit-gnome-authentication-agent > /dev/null; then
    echo "[OK] Polkit authentication agent is running"
else
    echo "[ERROR] Polkit authentication agent is NOT running"
fi

echo -e "\n=== Keyring Directories ==="
if [ -d "$HOME/.local/share/keyrings" ]; then
    echo "Keyring directory exists: $HOME/.local/share/keyrings"
    echo "Permissions: $(ls -ld "$HOME/.local/share/keyrings" | cut -d' ' -f1)"
else
    echo "Keyring directory not found"
fi

echo -e "\n=== Recent Log Entries ==="
if [ -f "$HOME/.config/i3/keyring.log" ]; then
    tail -5 "$HOME/.config/i3/keyring.log"
else
    echo "No log file found"
fi
