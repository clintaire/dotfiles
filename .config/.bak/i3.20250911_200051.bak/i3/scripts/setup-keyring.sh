#!/bin/bash
# Enhanced keyring setup script for i3
# Provides secure keyring management with proper error handling

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Keyring Setup: $1" >> ~/.config/i3/keyring.log
}

# Kill any existing keyring daemons to prevent conflicts
killall gnome-keyring-daemon 2>/dev/null
log_message "Stopped existing keyring daemons"

# Wait a moment for processes to terminate
sleep 1

# Start GNOME keyring daemon with all security components
if /usr/bin/gnome-keyring-daemon --start --components=secrets,ssh,pkcs11 --daemonize; then
    log_message "GNOME keyring daemon started successfully"
    
    # Export environment variables for the session
    eval $(/usr/bin/gnome-keyring-daemon --start --components=secrets,ssh,pkcs11)
    export SSH_AUTH_SOCK
    export GPG_AGENT_INFO
    export GNOME_KEYRING_CONTROL
    export GNOME_KEYRING_PID
    
    log_message "Keyring environment variables exported"
    
    # Ensure proper permissions on keyring directory
    if [ -d "$HOME/.local/share/keyrings" ]; then
        chmod 700 "$HOME/.local/share/keyrings"
        log_message "Set secure permissions on keyring directory"
    fi
    
else
    log_message "ERROR: Failed to start GNOME keyring daemon"
    exit 1
fi
