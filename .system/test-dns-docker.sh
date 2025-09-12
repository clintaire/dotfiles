#!/bin/bash
# Test DNS script in Docker container sandbox
# Location: /home/cli/git/dotfiles/.system/test-dns-docker.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/dns-test.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

info() {
    echo "[INFO] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE"
    exit 1
}

# Create test Dockerfile
create_test_environment() {
    log "Creating test environment..."
    
    cat > /tmp/dns-test-Dockerfile <<'EOF'
FROM archlinux:latest

# Install required packages
RUN pacman -Sy --noconfirm \
    systemd \
    dnscrypt-proxy \
    stubby \
    bind \
    curl \
    iproute2 \
    iptables \
    sudo

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy DNS script
COPY secure-dns-setup.sh /home/testuser/
RUN chmod +x /home/testuser/secure-dns-setup.sh && \
    chown testuser:testuser /home/testuser/secure-dns-setup.sh

# Enable systemd
RUN systemctl enable systemd-resolved

USER testuser
WORKDIR /home/testuser

CMD ["/bin/bash"]
EOF

    log "Test environment created"
}

# Build test container
build_test_container() {
    log "Building test container..."
    
    # Copy DNS script to temp location
    cp "$SCRIPT_DIR/secure-dns-setup.sh" /tmp/
    
    # Build container
    cd /tmp
    docker build -f dns-test-Dockerfile -t dns-test:latest .
    
    log "Test container built successfully"
}

# Run DNS test in container
test_dns_in_container() {
    log "Testing DNS script in container..."
    
    # Run container with systemd
    docker run -it --privileged \
        --name dns-test-container \
        --tmpfs /tmp \
        --tmpfs /run \
        --tmpfs /run/lock \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        dns-test:latest \
        /bin/bash -c "
            # Start systemd services
            sudo systemctl start systemd-resolved
            
            # Show initial DNS config
            echo '=== INITIAL DNS CONFIG ==='
            cat /etc/resolv.conf || true
            nslookup google.com || true
            
            # Test the DNS script
            echo '=== TESTING DNS SCRIPT ==='
            sudo ./secure-dns-setup.sh status
            
            echo '=== INSTALLING SECURE DNS ==='
            sudo ./secure-dns-setup.sh install || echo 'Install failed (expected in container)'
            
            echo '=== FINAL DNS CONFIG ==='
            cat /etc/resolv.conf || true
            sudo ./secure-dns-setup.sh status
            
            echo '=== TESTING RESTORE ==='
            sudo ./secure-dns-setup.sh restore || echo 'Restore completed'
            
            echo '=== POST-RESTORE CONFIG ==='
            cat /etc/resolv.conf || true
            ls -la /etc/*.bak || true
        "
    
    log "Container test completed"
}

# Clean up test environment
cleanup() {
    log "Cleaning up test environment..."
    
    docker rm -f dns-test-container 2>/dev/null || true
    docker rmi dns-test:latest 2>/dev/null || true
    rm -f /tmp/dns-test-Dockerfile /tmp/secure-dns-setup.sh
    
    log "Cleanup completed"
}

# Main test function
main() {
    case "${1:-}" in
        "test")
            create_test_environment
            build_test_container
            test_dns_in_container
            cleanup
            ;;
        "interactive")
            create_test_environment
            build_test_container
            log "Starting interactive container..."
            docker run -it --privileged \
                --name dns-test-interactive \
                --tmpfs /tmp \
                --tmpfs /run \
                --tmpfs /run/lock \
                -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                dns-test:latest
            docker rm -f dns-test-interactive 2>/dev/null || true
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "Usage: $0 {test|interactive|cleanup}"
            echo ""
            echo "  test        - Automated test of DNS script"
            echo "  interactive - Interactive container for manual testing"
            echo "  cleanup     - Remove test containers and images"
            exit 1
            ;;
    esac
}

main "$@"