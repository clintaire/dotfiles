#!/bin/bash
# Emergency DNS/Network Revert Script
# Location: /home/cli/git/dotfiles/.system/emergency.sh
# Usage: sudo ./emergency.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/emergency-revert.log"

log() {
    echo "[EMERGENCY] [$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

info() {
    echo "[INFO] $1" | tee -a "$LOG_FILE"
}

warn() {
    echo "[WARNING] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for emergency recovery"
        exit 1
    fi
}

# Emergency DNS restoration
emergency_dns_restore() {
    log "EMERGENCY: Restoring DNS configuration..."
    
    # Stop all DNS services
    systemctl stop dnscrypt-proxy 2>/dev/null || true
    systemctl stop stubby 2>/dev/null || true
    systemctl stop systemd-resolved 2>/dev/null || true
    
    # Disable DNS services
    systemctl disable dnscrypt-proxy 2>/dev/null || true
    systemctl disable stubby 2>/dev/null || true
    
    # Restore from .bak files if they exist
    if [[ -f /etc/resolv.conf.bak ]]; then
        cp /etc/resolv.conf.bak /etc/resolv.conf
        log "Restored /etc/resolv.conf from .bak"
    else
        # Create emergency DNS config
        cat > /etc/resolv.conf <<EOF
# Emergency DNS configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
options timeout:2
EOF
        log "Created emergency DNS configuration"
    fi
    
    # Restore systemd-resolved config
    if [[ -f /etc/systemd/resolved.conf.bak ]]; then
        cp /etc/systemd/resolved.conf.bak /etc/systemd/resolved.conf
        log "Restored systemd-resolved config from .bak"
    fi
    
    # Remove DNS configs
    rm -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    rm -f /etc/stubby/stubby.yml
    
    # Mask systemd-resolved (original state)
    systemctl mask systemd-resolved 2>/dev/null || true
    
    log "Emergency DNS restoration completed"
}

# Emergency network restoration
emergency_network_restore() {
    log "EMERGENCY: Restoring network configuration..."
    
    # Restart NetworkManager
    systemctl restart NetworkManager 2>/dev/null || true
    
    # Flush DNS cache
    systemctl flush-dns 2>/dev/null || true
    
    # Reset iptables to accept all (emergency only)
    iptables -P INPUT ACCEPT 2>/dev/null || true
    iptables -P FORWARD ACCEPT 2>/dev/null || true  
    iptables -P OUTPUT ACCEPT 2>/dev/null || true
    iptables -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    
    log "Emergency network restoration completed"
}

# Test network connectivity
test_connectivity() {
    log "Testing network connectivity..."
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        log "SUCCESS: DNS resolution working"
    else
        warn "DNS resolution still failing"
    fi
    
    # Test internet connectivity
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        log "SUCCESS: Internet connectivity working"
    else
        warn "Internet connectivity still failing"
    fi
    
    # Test HTTPS connectivity
    if curl -s --connect-timeout 5 https://google.com >/dev/null 2>&1; then
        log "SUCCESS: HTTPS connectivity working"
    else
        warn "HTTPS connectivity still failing"
    fi
}

# Create emergency network script
create_emergency_script() {
    log "Creating permanent emergency script..."
    
    cat > /usr/local/bin/emergency-network-fix <<'EOF'
#!/bin/bash
# Emergency network fix - always available

echo "EMERGENCY NETWORK FIX"
echo "===================="

# Stop problematic services
systemctl stop dnscrypt-proxy stubby systemd-resolved 2>/dev/null || true

# Use Google DNS
cat > /etc/resolv.conf <<EOL
nameserver 8.8.8.8
nameserver 8.8.4.4
options timeout:2
EOL

# Restart network
systemctl restart NetworkManager 2>/dev/null || true

echo "Emergency DNS fix applied"
echo "Test with: nslookup google.com"
EOF

    chmod +x /usr/local/bin/emergency-network-fix
    log "Emergency script created: /usr/local/bin/emergency-network-fix"
}

# Show recovery information
show_recovery_info() {
    info "EMERGENCY RECOVERY COMPLETE"
    info "=========================="
    info ""
    info "What was done:"
    info "1. Stopped all DNS services (dnscrypt-proxy, stubby, systemd-resolved)"
    info "2. Restored original configs from .bak files"
    info "3. Created fallback DNS configuration"
    info "4. Reset network services"
    info ""
    info "Current DNS servers:"
    cat /etc/resolv.conf | grep nameserver || true
    info ""
    info "Emergency commands available:"
    info "  sudo /usr/local/bin/emergency-network-fix  - Quick network fix"
    info "  systemctl restart NetworkManager           - Restart network"
    info "  sudo dhcpcd -k && sudo dhcpcd              - Reset DHCP"
    info ""
    info "To prevent future issues:"
    info "1. Test scripts in containers first: ./test-dns-docker.sh test"
    info "2. Always keep .bak files"
    info "3. Have this emergency script ready"
    info ""
    info "Log file: $LOG_FILE"
}

# Main emergency function
main() {
    log "EMERGENCY REVERT STARTED"
    log "======================="
    
    check_root
    emergency_dns_restore
    emergency_network_restore
    test_connectivity
    create_emergency_script
    show_recovery_info
    
    log "EMERGENCY REVERT COMPLETED"
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi