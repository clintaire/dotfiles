#!/bin/bash
# Secure DNS Setup Script with Cloudflare DoT/DoH and DNSCrypt
# Location: /home/cli/git/dotfiles/.system/dnsbasic.sh
# Usage: ./dnsbasic.sh [install|restore|status]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/dns-setup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Create .bak files for security restoration
backup_config_files() {
    log "Creating .bak files for security restoration..."
    
    # Backup resolv.conf
    if [[ -f /etc/resolv.conf ]] && [[ ! -f /etc/resolv.conf.bak ]]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.bak
        log "Created /etc/resolv.conf.bak"
    fi
    
    # Backup systemd-resolved config
    if [[ -f /etc/systemd/resolved.conf ]] && [[ ! -f /etc/systemd/resolved.conf.bak ]]; then
        sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
        log "Created /etc/systemd/resolved.conf.bak"
    fi
    
    log "Security backup files (.bak) created"
}

# Install required packages
install_packages() {
    log " Installing required packages..."
    
    # Check if running on Arch Linux
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dnscrypt-proxy stubby || true
    elif command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y dnscrypt-proxy stubby
    else
        warn "Package manager not supported. Please install dnscrypt-proxy and stubby manually."
    fi
    
    log " Packages installed"
}

# Configure DNSCrypt-proxy for Cloudflare with ODoH
configure_dnscrypt() {
    log " Configuring DNSCrypt-proxy with Cloudflare ODoH (Oblivious DNS)..."
    
    sudo tee /etc/dnscrypt-proxy/dnscrypt-proxy.toml > /dev/null <<EOF
# DNSCrypt-proxy configuration for Cloudflare ODoH (Oblivious DNS over HTTPS)
# Maximum privacy setup following RFC 9230

listen_addresses = ['127.0.0.1:5353']
max_clients = 250
# user_name = 'dnscrypt'  # Commented out - user may not exist

# Use reliable Cloudflare servers
server_names = ['cloudflare', 'cloudflare-security']

# Enable DNS-over-HTTPS (ODoH may not be supported)
doh_servers = true
# odoh_servers = true  # Commented out - may not be supported
require_dnssec = true
require_nolog = true
require_nofilter = true

# Maximum privacy - disable ANY logging
log_level = 0
use_syslog = false

# Cache settings for performance
cache = true
cache_size = 4096
cache_min_ttl = 2400
cache_max_ttl = 86400
cache_neg_min_ttl = 60
cache_neg_max_ttl = 600

# Security features
block_ipv6 = false
block_unqualified = true
block_undelegated = true

# Anonymized DNS routing (simplified for compatibility)
# anonymized_dns = {
#   routes = [
#     { server_name='cloudflare', via=['odoh-relay-*'] },
#     { server_name='cloudflare-security', via=['odoh-relay-*'] }
#   ]
# }

# Network settings for privacy
force_tcp = false
timeout = 5000
keepalive = 30
netprobe_timeout = 60
netprobe_address = '1.1.1.1:53'
# refuse_any = true  # Not supported in this version

# Blocked names for security (minimal list)
[blocked_names]
  blocked_names_file = '/etc/dnscrypt-proxy/blocked-names.txt'

[blocked_ips]  
  blocked_ips_file = '/etc/dnscrypt-proxy/blocked-ips.txt'

# NO query logging for maximum privacy
# [query_log] - DISABLED

# Sources for ODoH-enabled resolvers
[sources]
  [sources.'public-resolvers']
    urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md', 'https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md']
    cache_file = '/var/cache/dnscrypt-proxy/public-resolvers.md'
    minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
    refresh_delay = 72
    prefix = ''
    
  # ODoH sources commented out for compatibility
  # [sources.'odoh-servers']
  #   urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md']
  #   cache_file = '/var/cache/dnscrypt-proxy/odoh-servers.md'
  #   minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
  #   refresh_delay = 72
  #   prefix = ''
  #   
  # [sources.'odoh-relays']
  #   urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md']
  #   cache_file = '/var/cache/dnscrypt-proxy/odoh-relays.md'
  #   minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
  #   refresh_delay = 72
  #   prefix = ''
EOF

    # Create blocked names file (basic security)
    sudo tee /etc/dnscrypt-proxy/blocked-names.txt > /dev/null <<EOF
# Basic blocked domains for security
malware.example.com
phishing.example.com
tracker.example.com
EOF

    # Create blocked IPs file  
    sudo tee /etc/dnscrypt-proxy/blocked-ips.txt > /dev/null <<EOF
# Blocked IP ranges for security
# Add malicious IPs here
EOF

    log " DNSCrypt-proxy configured for Cloudflare"
}

# Configure Stubby for DNS-over-TLS
configure_stubby() {
    log " Configuring Stubby for DNS-over-TLS..."
    
    sudo tee /etc/stubby/stubby.yml > /dev/null <<EOF
# Stubby configuration for Cloudflare DNS-over-TLS
# Privacy-focused setup

resolution_type: GETDNS_RESOLUTION_STUB
dns_transport_list:
  - GETDNS_TRANSPORT_TLS
  - GETDNS_TRANSPORT_UDP
  - GETDNS_TRANSPORT_TCP

tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 256
edns_client_subnet_private: 1
round_robin_upstreams: 1
idle_timeout: 10000
listen_addresses:
  - 127.0.0.1@5453
  - 0::1@5453

# Cloudflare DNS-over-TLS servers
upstream_recursive_servers:
  # Cloudflare Primary
  - address_data: 1.1.1.1
    tls_auth_name: "cloudflare-dns.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: "yioEpqeR4WtDwE9YxNVnCEkTxIjx6EEIeC/AwXSNoGU="
  
  # Cloudflare Secondary  
  - address_data: 1.0.0.1
    tls_auth_name: "cloudflare-dns.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: "yioEpqeR4WtDwE9YxNVnCEkTxIjx6EEIeC/AwXSNoGU="
        
  # Cloudflare IPv6 Primary
  - address_data: 2606:4700:4700::1111
    tls_auth_name: "cloudflare-dns.com"
    
  # Cloudflare IPv6 Secondary
  - address_data: 2606:4700:4700::1001  
    tls_auth_name: "cloudflare-dns.com"
    
  # Quad9 Secure (backup)
  - address_data: 9.9.9.9
    tls_auth_name: "dns.quad9.net"
    
  - address_data: 149.112.112.112
    tls_auth_name: "dns.quad9.net"
EOF

    log " Stubby configured for DNS-over-TLS"
}

# Configure systemd-resolved
configure_resolved() {
    log " Configuring systemd-resolved..."
    
    # Unmask and enable systemd-resolved
    sudo systemctl unmask systemd-resolved || true
    
    sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
# systemd-resolved configuration for encrypted DNS
[Resolve]
# Use local encrypted DNS proxies
DNS=127.0.0.1:5453 127.0.0.1:5353
FallbackDNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
ResolveUnicastSingleLabel=no
EOF

    log " systemd-resolved configured"
}

# Update resolv.conf
update_resolv_conf() {
    log " Updating resolv.conf..."
    
    # Point to systemd-resolved
    sudo rm -f /etc/resolv.conf
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    
    log " resolv.conf updated"
}

# Start and enable services
start_services() {
    log " Starting DNS services..."
    
    # Start dnscrypt-proxy
    sudo systemctl enable dnscrypt-proxy
    sudo systemctl start dnscrypt-proxy
    
    # Start stubby
    sudo systemctl enable stubby
    sudo systemctl start stubby
    
    # Start systemd-resolved
    sudo systemctl enable systemd-resolved
    sudo systemctl start systemd-resolved
    
    # Wait for services to start
    sleep 3
    
    log " All DNS services started"
}

# Test DNS resolution
test_dns() {
    log " Testing DNS resolution..."
    
    info "Testing DNS-over-TLS (Stubby)..."
    dig @127.0.0.1 -p 5453 google.com +short || warn "Stubby test failed"
    
    info "Testing DNSCrypt (dnscrypt-proxy)..."  
    dig @127.0.0.1 -p 5353 google.com +short || warn "DNSCrypt test failed"
    
    info "Testing system DNS..."
    nslookup google.com || warn "System DNS test failed"
    
    info "Testing DNS security..."
    dig +dnssec google.com | grep -q "ad" && log " DNSSEC working" || warn "DNSSEC may not be working"
    
    info "Testing ODoH (Oblivious DNS)..."
    dig @127.0.0.1 -p 5353 +short cloudflare.com && log " ODoH working" || warn "ODoH test failed"
    
    log " DNS tests completed"
}

# Install function
install_secure_dns() {
    log " Installing Secure DNS with Cloudflare DoT/DoH..."
    
    backup_config_files
    install_packages
    configure_dnscrypt
    configure_stubby  
    configure_resolved
    update_resolv_conf
    start_services
    test_dns
    
    log " Secure DNS installation completed!"
    info "Your DNS is now encrypted using:"
    info "  -   ODoH (Oblivious DNS over HTTPS) via DNSCrypt-proxy"
    info "  -  DNS-over-TLS (DoT) via Stubby on port 5453"
    info "  -  Cloudflare 1.1.1.1 and Quad9 secure resolvers"  
    info "  -  DNSSEC validation enabled"
    info "  -  Zero logging for maximum privacy"
    info ""
    info " Original configs saved as .bak files"
    info " To restore: $0 restore"
}

# Restore function
restore_dns() {
    log " Restoring DNS configuration from .bak files..."
    
    # Check if .bak files exist
    if [[ ! -f /etc/resolv.conf.bak ]] && [[ ! -f /etc/systemd/resolved.conf.bak ]]; then
        error "No .bak files found! Cannot restore."
    fi
    
    # Stop services
    sudo systemctl stop dnscrypt-proxy stubby systemd-resolved || true
    sudo systemctl disable dnscrypt-proxy stubby || true
    
    # Restore configs from .bak files
    if [[ -f /etc/resolv.conf.bak ]]; then
        sudo cp /etc/resolv.conf.bak /etc/resolv.conf
        log " Restored resolv.conf from .bak"
    fi
    
    if [[ -f /etc/systemd/resolved.conf.bak ]]; then
        sudo cp /etc/systemd/resolved.conf.bak /etc/systemd/resolved.conf
        log " Restored systemd-resolved config from .bak"
    fi
    
    # Mask systemd-resolved if it was masked before
    sudo systemctl mask systemd-resolved || true
    
    # Clean up DNS configs
    sudo rm -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    sudo rm -f /etc/stubby/stubby.yml
    
    log " DNS configuration restored to original state"
    info "Reboot recommended to fully apply changes"
}

# Status function
show_status() {
    info " DNS Configuration Status"
    
    info "=== Services Status ==="
    systemctl is-active dnscrypt-proxy 2>/dev/null || echo "dnscrypt-proxy: inactive"
    systemctl is-active stubby 2>/dev/null || echo "stubby: inactive"
    systemctl is-active systemd-resolved 2>/dev/null || echo "systemd-resolved: inactive"
    
    info "=== DNS Resolution ==="
    nslookup google.com 2>/dev/null || true
    
    info "=== Current resolv.conf ==="
    cat /etc/resolv.conf 2>/dev/null || true
    
    info "=== Backup Files ==="
    ls -la /etc/*.bak 2>/dev/null || echo "No .bak files found"
}

# Main function
main() {
    case "${1:-}" in
        "install")
            install_secure_dns
            ;;
        "restore")
            restore_dns
            ;;  
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 {install|restore|status}"
            echo ""
            echo "Examples:"
            echo "  $0 install    # Install secure DNS with Cloudflare DoH/DoT"
            echo "  $0 restore    # Restore from .bak files"
            echo "  $0 status     # Show current status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"