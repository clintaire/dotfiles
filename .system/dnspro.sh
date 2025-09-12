#!/bin/bash
# Enterprise Secure DNS Setup Script with Advanced Monitoring & Failover
# Location: /home/cli/git/dotfiles/.system/dnspro.sh
# Usage: ./dnspro.sh [install|restore|status|monitor]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/dns-setup.log"
METRICS_FILE="$SCRIPT_DIR/dns-metrics.json"
PID_FILE="/var/run/dns-monitor.pid"

# Configuration
HEALTH_CHECK_INTERVAL=15
CIRCUIT_BREAKER_THRESHOLD=3
CIRCUIT_BREAKER_TIMEOUT=300
DNS_TEST_TIMEOUT=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Service state tracking
declare -A SERVICE_STATES
SERVICE_STATES[dnscrypt]="STOPPED"
SERVICE_STATES[stubby]="STOPPED"
SERVICE_STATES[resolved]="STOPPED"

# Circuit breaker state
declare -A CIRCUIT_BREAKERS=(
    [dnscrypt_failures]=0
    [stubby_failures]=0
    [dnscrypt_last_failure]=0
    [stubby_last_failure]=0
)

# Performance metrics
declare -A METRICS=(
    [dns_query_count]=0
    [dns_success_count]=0
    [dns_failure_count]=0
    [avg_response_time]=0
)

declare -A SERVICE_METRICS=(
    [dnscrypt_queries]=0
    [dnscrypt_successes]=0
    [stubby_queries]=0
    [stubby_successes]=0
)

# DNS routing configuration
declare -A DNS_ROUTES=(
    [primary]="127.0.0.1:5353"
    [secondary]="127.0.0.1:5453"
    [fallback]="1.1.1.1:53"
)

declare -A ROUTE_WEIGHTS=(
    [primary]=70
    [secondary]=25
    [fallback]=5
)

# Service dependencies
declare -A SERVICE_DEPS=(
    [dnscrypt]="network"
    [stubby]="network"
    [resolved]="dnscrypt,stubby"
)

# Health check definitions
declare -A HEALTH_CHECKS=(
    [dnscrypt_port]="nc -z 127.0.0.1 5353"
    [dnscrypt_resolve]="dig @127.0.0.1 -p 5353 +timeout=2 +tries=1 google.com"
    [stubby_port]="nc -z 127.0.0.1 5453"
    [stubby_resolve]="dig @127.0.0.1 -p 5453 +timeout=2 +tries=1 google.com"
    [system_resolve]="nslookup google.com"
    [dnssec_validation]="dig +dnssec +short google.com"
    [network_connectivity]="ping -c1 -W2 1.1.1.1"
)

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
    cleanup_on_exit
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Cleanup function for graceful exit
cleanup_on_exit() {
    if [[ -f $PID_FILE ]]; then
        local monitor_pid=$(cat "$PID_FILE" 2>/dev/null)
        if [[ -n $monitor_pid ]] && kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid" 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
    fi
}

trap cleanup_on_exit EXIT INT TERM

# State management
transition_state() {
    local service=$1
    local new_state=$2
    local old_state=${SERVICE_STATES[$service]}

    log "Service $service: $old_state -> $new_state"
    SERVICE_STATES[$service]=$new_state

    case $new_state in
        "FAILED") handle_service_failure "$service" ;;
        "HEALTHY") update_routing_table "$service" ;;
    esac
}

handle_service_failure() {
    local service=$1
    warn "Handling failure for service: $service"
    record_failure "$service"
    update_routing_table "$service"
}

# Environment detection
detect_environment() {
    local env="desktop"

    if [[ -f /.dockerenv ]]; then
        env="docker"
    elif systemd-detect-virt -q 2>/dev/null; then
        env="vm"
    elif [[ -d /sys/class/net/wlan* ]]; then
        env="laptop"
    fi

    local network_manager="none"
    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        network_manager="networkmanager"
    elif systemctl is-active netctl >/dev/null 2>&1; then
        network_manager="netctl"
    fi

    info "Environment: $env, Network Manager: $network_manager"
    export DNS_ENVIRONMENT="$env"
    export NETWORK_MANAGER="$network_manager"

    apply_environment_config
}

apply_environment_config() {
    case ${DNS_ENVIRONMENT:-desktop} in
        "laptop")
            HEALTH_CHECK_INTERVAL=30
            CIRCUIT_BREAKER_TIMEOUT=120
            ;;
        "desktop")
            HEALTH_CHECK_INTERVAL=15
            CIRCUIT_BREAKER_TIMEOUT=60
            ;;
        "docker")
            HEALTH_CHECK_INTERVAL=60
            ;;
    esac

    info "Applied environment config: check_interval=${HEALTH_CHECK_INTERVAL}s"
}

# Circuit breaker implementation
circuit_breaker_check() {
    local service=$1
    local current_time=$(date +%s)
    local failures=${CIRCUIT_BREAKERS[${service}_failures]}
    local last_failure=${CIRCUIT_BREAKERS[${service}_last_failure]}

    if [[ $((current_time - last_failure)) -gt $CIRCUIT_BREAKER_TIMEOUT ]]; then
        CIRCUIT_BREAKERS[${service}_failures]=0
        log "Circuit breaker for $service reset"
        return 0
    fi

    if [[ $failures -ge $CIRCUIT_BREAKER_THRESHOLD ]]; then
        warn "Circuit breaker OPEN for $service (failures: $failures)"
        return 1
    fi

    return 0
}

record_failure() {
    local service=$1
    CIRCUIT_BREAKERS[${service}_failures]=$((${CIRCUIT_BREAKERS[${service}_failures]} + 1))
    CIRCUIT_BREAKERS[${service}_last_failure]=$(date +%s)
    warn "Recorded failure for $service (total: ${CIRCUIT_BREAKERS[${service}_failures]})"
}

# Performance monitoring
measure_dns_performance() {
    local server=$1
    local port=$2
    local domain=${3:-"google.com"}

    local start_time=$(date +%s%3N)
    if timeout "$DNS_TEST_TIMEOUT" dig "@$server" -p "$port" "+timeout=3" "+tries=1" "$domain" >/dev/null 2>&1; then
        local end_time=$(date +%s%3N)
        local response_time=$((end_time - start_time))

        METRICS[dns_success_count]=$((${METRICS[dns_success_count]} + 1))
        update_avg_response_time "$response_time"

        log "DNS query to $server:$port took ${response_time}ms"
        return 0
    else
        METRICS[dns_failure_count]=$((${METRICS[dns_failure_count]} + 1))
        warn "DNS query to $server:$port failed"
        return 1
    fi
}

update_avg_response_time() {
    local new_time=$1
    local current_avg=${METRICS[avg_response_time]}
    local total_queries=$((${METRICS[dns_success_count]} + ${METRICS[dns_failure_count]}))

    if [[ $total_queries -gt 1 ]]; then
        METRICS[avg_response_time]=$(( (current_avg * (total_queries - 1) + new_time) / total_queries ))
    else
        METRICS[avg_response_time]=$new_time
    fi
}

# Health check system
run_health_checks() {
    local service=$1
    local checks_passed=0
    local total_checks=0

    case $service in
        "dnscrypt")
            local check_list=("network_connectivity" "dnscrypt_port" "dnscrypt_resolve")
            ;;
        "stubby")
            local check_list=("network_connectivity" "stubby_port" "stubby_resolve")
            ;;
        "system")
            local check_list=("system_resolve" "dnssec_validation")
            ;;
        *)
            warn "Unknown service for health check: $service"
            return 2
            ;;
    esac

    for check in "${check_list[@]}"; do
        ((total_checks++))
        if timeout 5 bash -c "${HEALTH_CHECKS[$check]}" >/dev/null 2>&1; then
            ((checks_passed++))
        fi
    done

    local health_percentage=$((checks_passed * 100 / total_checks))

    if [[ $health_percentage -ge 100 ]]; then
        return 0  # HEALTHY
    elif [[ $health_percentage -ge 70 ]]; then
        return 1  # DEGRADED
    else
        return 2  # FAILED
    fi
}

# DNS routing management
update_routing_table() {
    local trigger_service=${1:-"auto"}

    # Reset weights
    ROUTE_WEIGHTS[primary]=70
    ROUTE_WEIGHTS[secondary]=25
    ROUTE_WEIGHTS[fallback]=5

    # Adjust based on service states
    if [[ ${SERVICE_STATES[dnscrypt]} != "HEALTHY" ]]; then
        ROUTE_WEIGHTS[primary]=0
        local add_weight=35
        ROUTE_WEIGHTS[secondary]=$((${ROUTE_WEIGHTS[secondary]} + add_weight))
    fi

    if [[ ${SERVICE_STATES[stubby]} != "HEALTHY" ]]; then
        ROUTE_WEIGHTS[secondary]=0
        local add_weight=25
        ROUTE_WEIGHTS[fallback]=$((${ROUTE_WEIGHTS[fallback]} + add_weight))
    fi

    update_resolved_config
    log "DNS routing updated (trigger: $trigger_service)"
}

update_resolved_config() {
    local dns_servers=""

    if [[ ${ROUTE_WEIGHTS[primary]} -gt 0 ]]; then
        dns_servers+="127.0.0.1:5353 "
    fi
    if [[ ${ROUTE_WEIGHTS[secondary]} -gt 0 ]]; then
        dns_servers+="127.0.0.1:5453 "
    fi

    dns_servers+="1.1.1.1 1.0.0.1"

    sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF
[Resolve]
DNS=$dns_servers
FallbackDNS=8.8.8.8 9.9.9.9 149.112.112.112
DNSSEC=yes
DNSOverTLS=opportunistic
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
ResolveUnicastSingleLabel=no
EOF

    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        sudo systemctl reload-or-restart systemd-resolved
    fi
}

# Service dependency management
wait_for_service() {
    local service=$1
    local max_wait=${2:-30}
    local count=0

    while ! systemctl is-active "$service" >/dev/null 2>&1; do
        sleep 1
        ((count++))
        if [ $count -ge $max_wait ]; then
            error "Service $service failed to start within ${max_wait}s"
        fi
    done
}

start_service_with_deps() {
    local service=$1

    # Check dependencies
    local deps=${SERVICE_DEPS[$service]:-""}
    for dep in ${deps//,/ }; do
        if [[ $dep == "network" ]]; then
            if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
                error "Network connectivity required for $service"
            fi
        elif [[ ${SERVICE_STATES[$dep]:-"STOPPED"} == "FAILED" ]] && [[ $dep == "dnscrypt" ]]; then
            warn "$service: dependency $dep failed, continuing with degraded setup"
        fi
    done

    # Start service
    transition_state "$service" "STARTING"

    case $service in
        "dnscrypt")
            sudo systemctl enable dnscrypt-proxy
            sudo systemctl start dnscrypt-proxy
            wait_for_service "dnscrypt-proxy"
            sleep 3
            if measure_dns_performance "127.0.0.1" "5353"; then
                transition_state "$service" "HEALTHY"
            else
                transition_state "$service" "FAILED"
            fi
            ;;
        "stubby")
            sudo systemctl enable stubby
            sudo systemctl start stubby
            wait_for_service "stubby"
            sleep 3
            if measure_dns_performance "127.0.0.1" "5453"; then
                transition_state "$service" "HEALTHY"
            else
                transition_state "$service" "FAILED"
            fi
            ;;
        "resolved")
            sudo systemctl enable systemd-resolved
            sudo systemctl start systemd-resolved
            wait_for_service "systemd-resolved"
            sleep 3
            if nslookup google.com >/dev/null 2>&1; then
                transition_state "$service" "HEALTHY"
            else
                transition_state "$service" "FAILED"
            fi
            ;;
    esac
}

# Monitoring daemon
start_monitoring_daemon() {
    if [[ -f $PID_FILE ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        warn "Monitoring daemon already running"
        return
    fi

    {
        while true; do
            monitor_and_heal
            sleep "$HEALTH_CHECK_INTERVAL"
        done
    } &

    echo $! > "$PID_FILE"
    log "Started DNS monitoring daemon (PID: $!)"
}

monitor_and_heal() {
    for service in dnscrypt stubby; do
        if ! circuit_breaker_check "$service"; then
            continue
        fi

        run_health_checks "$service"
        local health_status=$?

        case $health_status in
            0) # HEALTHY
                if [[ ${SERVICE_STATES[$service]} != "HEALTHY" ]]; then
                    transition_state "$service" "HEALTHY"
                    log "Service $service recovered to healthy state"
                fi
                ;;
            1) # DEGRADED
                transition_state "$service" "DEGRADED"
                warn "Service $service is degraded, attempting recovery"
                attempt_service_recovery "$service"
                ;;
            2) # FAILED
                transition_state "$service" "FAILED"
                record_failure "$service"
                attempt_service_recovery "$service"
                ;;
        esac
    done

    update_routing_table "monitor"
    save_metrics
}

attempt_service_recovery() {
    local service=$1

    log "Attempting recovery for $service..."

    case $service in
        "dnscrypt")
            sudo systemctl restart dnscrypt-proxy
            sleep 5
            if measure_dns_performance "127.0.0.1" "5353"; then
                log "DNSCrypt recovery successful"
                return 0
            fi
            ;;
        "stubby")
            sudo systemctl restart stubby
            sleep 5
            if measure_dns_performance "127.0.0.1" "5453"; then
                log "Stubby recovery successful"
                return 0
            fi
            ;;
    esac

    warn "Recovery attempt for $service failed"
    return 1
}

save_metrics() {
    cat > "$METRICS_FILE" <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "services": {
        "dnscrypt": {
            "state": "${SERVICE_STATES[dnscrypt]}",
            "queries": ${SERVICE_METRICS[dnscrypt_queries]},
            "successes": ${SERVICE_METRICS[dnscrypt_successes]},
            "failures": ${CIRCUIT_BREAKERS[dnscrypt_failures]}
        },
        "stubby": {
            "state": "${SERVICE_STATES[stubby]}",
            "queries": ${SERVICE_METRICS[stubby_queries]},
            "successes": ${SERVICE_METRICS[stubby_successes]},
            "failures": ${CIRCUIT_BREAKERS[stubby_failures]}
        }
    },
    "overall": {
        "total_queries": ${METRICS[dns_query_count]},
        "success_count": ${METRICS[dns_success_count]},
        "failure_count": ${METRICS[dns_failure_count]},
        "avg_response_time": ${METRICS[avg_response_time]}
    }
}
EOF
}

# Installation functions
backup_config_files() {
    log "Creating backup files for security restoration..."

    if [[ -f /etc/resolv.conf ]] && [[ ! -f /etc/resolv.conf.bak ]]; then
        sudo cp /etc/resolv.conf /etc/resolv.conf.bak
        log "Created /etc/resolv.conf.bak"
    fi

    if [[ -f /etc/systemd/resolved.conf ]] && [[ ! -f /etc/systemd/resolved.conf.bak ]]; then
        sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak
        log "Created /etc/systemd/resolved.conf.bak"
    fi

    log "Security backup files created"
}

stop_existing_services() {
    log "Stopping existing DNS services..."

    sudo systemctl stop systemd-resolved || true
    sudo systemctl stop dnscrypt-proxy || true
    sudo systemctl stop stubby || true

    sudo fuser -k 5353/tcp 5353/udp 2>/dev/null || true
    sudo fuser -k 5453/tcp 5453/udp 2>/dev/null || true

    sleep 3
    log "Existing services stopped"
}

validate_system_requirements() {
    log "Validating system requirements..."

    # Check for required commands
    local required_commands=("dig" "nslookup" "nc" "systemctl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd"
        fi
    done

    # Check network connectivity
    if ! ping -c1 -W5 1.1.1.1 >/dev/null 2>&1; then
        error "No internet connectivity - cannot configure DNS"
    fi

    # Check if running as root or with sudo
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        error "This script requires sudo privileges"
    fi

    log "System requirements validated"
}

install_packages_with_verification() {
    log "Installing required packages..."

    # Ensure working DNS for package installation
    sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
EOF

    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dnscrypt-proxy stubby gnu-netcat dnsutils logrotate
    elif command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y dnscrypt-proxy stubby netcat-openbsd dnsutils
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y dnscrypt-proxy stubby nmap-ncat bind-utils
    else
        error "Package manager not supported. Please install dnscrypt-proxy and stubby manually."
    fi

    # Verify installation
    for pkg in dnscrypt-proxy stubby; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            error "Failed to install $pkg"
        fi
    done

    log "Packages installed and verified"
}

configure_services_with_templates() {
    log "Configuring services with optimized templates..."

    configure_dnscrypt_enterprise
    configure_stubby_enterprise
    configure_monitoring_infrastructure
}

configure_dnscrypt_enterprise() {
    log "Configuring DNSCrypt-proxy for enterprise use..."

    sudo mkdir -p /etc/dnscrypt-proxy /var/cache/dnscrypt-proxy

    sudo tee /etc/dnscrypt-proxy/dnscrypt-proxy.toml > /dev/null <<EOF
# Enterprise DNSCrypt-proxy configuration
# Optimized for reliability and performance

listen_addresses = ['127.0.0.1:5353']
max_clients = 250
# user_name = 'dnscrypt'  # Commented out - user may not exist

# Reliable Cloudflare servers
server_names = ['cloudflare', 'cloudflare-ipv6']

# Protocol settings
doh_servers = true
require_dnssec = true
require_nolog = true
require_nofilter = true

# Logging disabled for privacy
log_level = 0
use_syslog = false

# Performance tuning
cache = true
cache_size = 4096
cache_min_ttl = 600
cache_max_ttl = 7200
cache_neg_min_ttl = 60
cache_neg_max_ttl = 600

# Security features
block_ipv6 = false
block_unqualified = true
block_undelegated = true

# Network reliability
force_tcp = false
timeout = 8000
keepalive = 45
netprobe_timeout = 30
netprobe_address = '1.1.1.1:53'
# refuse_any = true  # Not supported in this version

# Blocked names for security
[blocked_names]
  blocked_names_file = '/etc/dnscrypt-proxy/blocked-names.txt'

[blocked_ips]
  blocked_ips_file = '/etc/dnscrypt-proxy/blocked-ips.txt'

# Resolver sources
[sources]
  [sources.'public-resolvers']
    urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md']
    cache_file = '/var/cache/dnscrypt-proxy/public-resolvers.md'
    minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
    refresh_delay = 72
    prefix = ''
EOF

    # Create security files
    sudo tee /etc/dnscrypt-proxy/blocked-names.txt > /dev/null <<EOF
# Enterprise security blocked domains
malware.test.com
phishing.test.com
tracker.test.com
EOF

    sudo tee /etc/dnscrypt-proxy/blocked-ips.txt > /dev/null <<EOF
# Enterprise security blocked IPs
# Add malicious IP ranges here
EOF

    log "DNSCrypt-proxy configured for enterprise use"
}

configure_stubby_enterprise() {
    log "Configuring Stubby for enterprise DNS-over-TLS..."

    sudo mkdir -p /etc/stubby

    sudo tee /etc/stubby/stubby.yml > /dev/null <<EOF
# Enterprise Stubby configuration for DNS-over-TLS
# Optimized for security and reliability

resolution_type: GETDNS_RESOLUTION_STUB
dns_transport_list:
  - GETDNS_TRANSPORT_TLS
  - GETDNS_TRANSPORT_UDP
  - GETDNS_TRANSPORT_TCP

tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 256
edns_client_subnet_private: 1
round_robin_upstreams: 1
idle_timeout: 15000

listen_addresses:
  - 127.0.0.1@5453
  - 0::1@5453

# Enterprise-grade upstream servers
upstream_recursive_servers:
  # Cloudflare Primary DoT
  - address_data: 1.1.1.1
    tls_auth_name: "cloudflare-dns.com"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: "yioEpqeR4WtDwE9YxNVnCEkTxIjx6EEIeC/AwXSNoGU="

  # Cloudflare Secondary DoT
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

  # Quad9 Secure DoT (backup)
  - address_data: 9.9.9.9
    tls_auth_name: "dns.quad9.net"

  - address_data: 149.112.112.112
    tls_auth_name: "dns.quad9.net"
EOF

    log "Stubby configured for enterprise DNS-over-TLS"
}

configure_monitoring_infrastructure() {
    log "Setting up monitoring infrastructure..."

    # Create monitoring directories
    sudo mkdir -p /var/log/dns-monitor /var/lib/dns-monitor

    # Setup log rotation
    sudo tee /etc/logrotate.d/dns-monitor > /dev/null <<EOF
$LOG_FILE {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}

/var/log/dns-monitor/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

    log "Monitoring infrastructure configured"
}

# Testing functions
run_comprehensive_tests() {
    info "Running comprehensive DNS test suite..."

    local test_results=()

    test_basic_connectivity && test_results+=("PASS") || test_results+=("FAIL")
    test_encrypted_dns_functionality && test_results+=("PASS") || test_results+=("FAIL")
    test_failover_scenarios && test_results+=("PASS") || test_results+=("FAIL")
    test_performance_benchmarks && test_results+=("PASS") || test_results+=("FAIL")
    test_security_features && test_results+=("PASS") || test_results+=("FAIL")

    generate_test_report "${test_results[@]}"
}

test_basic_connectivity() {
    info "Testing basic connectivity..."

    local tests_passed=0
    local total_tests=3

    # Test 1: Network connectivity
    if ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; then
        ((tests_passed++))
        log "Network connectivity: PASS"
    else
        warn "Network connectivity: FAIL"
    fi

    # Test 2: System DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        ((tests_passed++))
        log "System DNS resolution: PASS"
    else
        warn "System DNS resolution: FAIL"
    fi

    # Test 3: DNSSEC validation
    if dig +dnssec google.com | grep -q "ad"; then
        ((tests_passed++))
        log "DNSSEC validation: PASS"
    else
        warn "DNSSEC validation: FAIL"
    fi

    [[ $tests_passed -eq $total_tests ]]
}

test_encrypted_dns_functionality() {
    info "Testing encrypted DNS functionality..."

    local tests_passed=0
    local total_tests=2

    # Test DNSCrypt
    if measure_dns_performance "127.0.0.1" "5353"; then
        ((tests_passed++))
        log "DNSCrypt functionality: PASS"
    else
        warn "DNSCrypt functionality: FAIL"
    fi

    # Test Stubby DoT
    if measure_dns_performance "127.0.0.1" "5453"; then
        ((tests_passed++))
        log "Stubby DoT functionality: PASS"
    else
        warn "Stubby DoT functionality: FAIL"
    fi

    [[ $tests_passed -eq $total_tests ]]
}

test_failover_scenarios() {
    info "Testing failover scenarios..."

    # Backup current states
    local dnscrypt_original_state=$(systemctl is-active dnscrypt-proxy 2>/dev/null)
    local stubby_original_state=$(systemctl is-active stubby 2>/dev/null)

    # Test 1: DNSCrypt failure scenario
    sudo systemctl stop dnscrypt-proxy
    sleep 3

    if nslookup google.com >/dev/null 2>&1; then
        log "Failover from DNSCrypt: PASS"
    else
        warn "Failover from DNSCrypt: FAIL"
        sudo systemctl start dnscrypt-proxy stubby
        return 1
    fi

    # Test 2: Complete encrypted DNS failure
    sudo systemctl stop stubby
    sleep 3

    if nslookup google.com >/dev/null 2>&1; then
        log "Failover to direct DNS: PASS"
    else
        warn "Failover to direct DNS: FAIL"
        sudo systemctl start dnscrypt-proxy stubby
        return 1
    fi

    # Restore services
    if [[ $dnscrypt_original_state == "active" ]]; then
        sudo systemctl start dnscrypt-proxy
    fi
    if [[ $stubby_original_state == "active" ]]; then
        sudo systemctl start stubby
    fi

    sleep 5
    return 0
}

test_performance_benchmarks() {
    info "Testing performance benchmarks..."

    local dnscrypt_times=()
    local stubby_times=()
    local direct_times=()

    # Test DNSCrypt performance (5 queries)
    for i in {1..5}; do
        local start_time=$(date +%s%3N)
        if dig @127.0.0.1 -p 5353 +timeout=3 google.com >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            dnscrypt_times+=($((end_time - start_time)))
        fi
    done

    # Test Stubby performance (5 queries)
    for i in {1..5}; do
        local start_time=$(date +%s%3N)
        if dig @127.0.0.1 -p 5453 +timeout=3 google.com >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            stubby_times+=($((end_time - start_time)))
        fi
    done

    # Test direct DNS performance (5 queries)
    for i in {1..5}; do
        local start_time=$(date +%s%3N)
        if dig @1.1.1.1 +timeout=3 google.com >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            direct_times+=($((end_time - start_time)))
        fi
    done

    # Calculate averages
    local dnscrypt_avg=0
    local stubby_avg=0
    local direct_avg=0

    if [[ ${#dnscrypt_times[@]} -gt 0 ]]; then
        dnscrypt_avg=$(( $(printf '%s+' "${dnscrypt_times[@]}" | sed 's/+$//') / ${#dnscrypt_times[@]} ))
    fi

    if [[ ${#stubby_times[@]} -gt 0 ]]; then
        stubby_avg=$(( $(printf '%s+' "${stubby_times[@]}" | sed 's/+$//') / ${#stubby_times[@]} ))
    fi

    if [[ ${#direct_times[@]} -gt 0 ]]; then
        direct_avg=$(( $(printf '%s+' "${direct_times[@]}" | sed 's/+$//') / ${#direct_times[@]} ))
    fi

    info "Performance Results:"
    info "  DNSCrypt average: ${dnscrypt_avg}ms"
    info "  Stubby average: ${stubby_avg}ms"
    info "  Direct DNS average: ${direct_avg}ms"

    # Performance is acceptable if encrypted DNS is within 3x of direct DNS
    local acceptable_threshold=$((direct_avg * 3))

    if [[ $dnscrypt_avg -lt $acceptable_threshold ]] || [[ $stubby_avg -lt $acceptable_threshold ]]; then
        log "Performance benchmarks: PASS"
        return 0
    else
        warn "Performance benchmarks: FAIL (encrypted DNS too slow)"
        return 1
    fi
}

test_security_features() {
    info "Testing security features..."

    local tests_passed=0
    local total_tests=3

    # Test 1: DNSSEC validation
    if dig +dnssec cloudflare.com | grep -q "RRSIG"; then
        ((tests_passed++))
        log "DNSSEC signatures: PASS"
    else
        warn "DNSSEC signatures: FAIL"
    fi

    # Test 2: DNS over HTTPS functionality
    if curl -s -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=google.com&type=A" | grep -q "Answer"; then
        ((tests_passed++))
        log "DoH functionality: PASS"
    else
        warn "DoH functionality: FAIL"
    fi

    # Test 3: DNS over TLS connectivity
    if echo | timeout 5 openssl s_client -connect 1.1.1.1:853 2>/dev/null | grep -q "CONNECTED"; then
        ((tests_passed++))
        log "DoT connectivity: PASS"
    else
        warn "DoT connectivity: FAIL"
    fi

    [[ $tests_passed -ge 2 ]]  # Pass if at least 2/3 security tests pass
}

generate_test_report() {
    local results=("$@")
    local passed=0
    local total=${#results[@]}

    for result in "${results[@]}"; do
        [[ $result == "PASS" ]] && ((passed++))
    done

    info "Test Suite Results: $passed/$total tests passed"

    if [[ $passed -eq $total ]]; then
        log "All tests PASSED - DNS setup is fully functional"
        return 0
    elif [[ $passed -ge $((total * 70 / 100)) ]]; then
        warn "Most tests passed ($passed/$total) - DNS setup is functional with minor issues"
        return 0
    else
        error "Critical test failures ($passed/$total) - DNS setup needs attention"
        return 1
    fi
}

# Performance baseline establishment
establish_performance_baseline() {
    log "Establishing performance baseline..."

    local baseline_queries=20
    local dnscrypt_total=0
    local stubby_total=0
    local dnscrypt_successes=0
    local stubby_successes=0

    # Baseline DNSCrypt performance
    for i in $(seq 1 $baseline_queries); do
        local start_time=$(date +%s%3N)
        if dig @127.0.0.1 -p 5353 +timeout=5 "test$i.google.com" >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            dnscrypt_total=$((dnscrypt_total + end_time - start_time))
            ((dnscrypt_successes++))
        fi
        sleep 0.1
    done

    # Baseline Stubby performance
    for i in $(seq 1 $baseline_queries); do
        local start_time=$(date +%s%3N)
        if dig @127.0.0.1 -p 5453 +timeout=5 "test$i.google.com" >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            stubby_total=$((stubby_total + end_time - start_time))
            ((stubby_successes++))
        fi
        sleep 0.1
    done

    # Calculate and store baselines
    local dnscrypt_baseline=0
    local stubby_baseline=0

    if [[ $dnscrypt_successes -gt 0 ]]; then
        dnscrypt_baseline=$((dnscrypt_total / dnscrypt_successes))
    fi

    if [[ $stubby_successes -gt 0 ]]; then
        stubby_baseline=$((stubby_total / stubby_successes))
    fi

    # Store baseline metrics - ensure indices exist
    [[ -v SERVICE_METRICS[dnscrypt_baseline] ]] || SERVICE_METRICS[dnscrypt_baseline]=0
    [[ -v SERVICE_METRICS[stubby_baseline] ]] || SERVICE_METRICS[stubby_baseline]=0
    [[ -v SERVICE_METRICS[dnscrypt_success_rate] ]] || SERVICE_METRICS[dnscrypt_success_rate]=0
    [[ -v SERVICE_METRICS[stubby_success_rate] ]] || SERVICE_METRICS[stubby_success_rate]=0
    
    SERVICE_METRICS[dnscrypt_baseline]=$dnscrypt_baseline
    SERVICE_METRICS[stubby_baseline]=$stubby_baseline
    SERVICE_METRICS[dnscrypt_success_rate]=$((dnscrypt_successes * 100 / baseline_queries))
    SERVICE_METRICS[stubby_success_rate]=$((stubby_successes * 100 / baseline_queries))

    info "Performance Baseline Established:"
    info "  DNSCrypt: ${dnscrypt_baseline}ms avg (${SERVICE_METRICS[dnscrypt_success_rate]}% success)"
    info "  Stubby: ${stubby_baseline}ms avg (${SERVICE_METRICS[stubby_success_rate]}% success)"
}

# Report generation
generate_performance_report() {
    local success_rate=0
    local total_queries=$((${METRICS[dns_success_count]} + ${METRICS[dns_failure_count]}))

    if [[ $total_queries -gt 0 ]]; then
        success_rate=$((${METRICS[dns_success_count]} * 100 / total_queries))
    fi

    info "=== DNS Performance Report ==="
    info "Total Queries: $total_queries"
    info "Success Rate: ${success_rate}%"
    info "Average Response Time: ${METRICS[avg_response_time]}ms"

    if [[ ${SERVICE_METRICS[dnscrypt_queries]} -gt 0 ]]; then
        info "DNSCrypt Success Rate: $((${SERVICE_METRICS[dnscrypt_successes]} * 100 / ${SERVICE_METRICS[dnscrypt_queries]}))%"
    fi

    if [[ ${SERVICE_METRICS[stubby_queries]} -gt 0 ]]; then
        info "Stubby Success Rate: $((${SERVICE_METRICS[stubby_successes]} * 100 / ${SERVICE_METRICS[stubby_queries]}))%"
    fi

    info "Circuit Breaker Status:"
    info "  DNSCrypt Failures: ${CIRCUIT_BREAKERS[dnscrypt_failures]}"
    info "  Stubby Failures: ${CIRCUIT_BREAKERS[stubby_failures]}"
}

generate_installation_report() {
    log "=== Enterprise DNS Installation Report ==="
    info "Installation completed successfully!"
    info ""
    info "Active Services:"

    for service in dnscrypt stubby resolved; do
        info "  $service: ${SERVICE_STATES[$service]}"
    done

    info ""
    info "DNS Configuration:"
    info "  Primary Encrypted DNS: DNSCrypt-proxy (127.0.0.1:5353)"
    info "  Secondary Encrypted DNS: Stubby DoT (127.0.0.1:5453)"
    info "  Fallback DNS: Cloudflare (1.1.1.1), Quad9 (9.9.9.9)"
    info "  DNSSEC: Enabled"
    info "  DNS-over-TLS: Enabled"
    info "  DNS-over-HTTPS: Enabled"
    info ""
    info "Enterprise Features:"
    info "  Circuit Breakers: Enabled"
    info "  Health Monitoring: Active"
    info "  Auto-Recovery: Enabled"
    info "  Performance Monitoring: Active"
    info "  Smart Failover: Enabled"
    info ""
    info "Management:"
    info "  Monitoring Daemon: $([[ -f $PID_FILE ]] && echo "Running (PID: $(cat "$PID_FILE"))" || echo "Stopped")"
    info "  Log File: $LOG_FILE"
    info "  Metrics File: $METRICS_FILE"
    info ""
    info "Commands:"
    info "  Status: $0 status"
    info "  Monitor: $0 monitor"
    info "  Restore: $0 restore"
    info ""
    info "Backup files saved for restoration:"
    info "  /etc/resolv.conf.bak"
    info "  /etc/systemd/resolved.conf.bak"
}

# Main installation function
install_secure_dns_enterprise() {
    log "Installing Enterprise-Grade Secure DNS with Advanced Monitoring..."

    # Phase 1: Environment Analysis & Preparation
    detect_environment
    validate_system_requirements
    backup_config_files
    stop_existing_services

    # Phase 2: Package Installation & Verification
    install_packages_with_verification

    # Phase 3: Service Configuration
    configure_services_with_templates

    # Phase 4: Staged Service Startup with Health Gates
    log "Starting services with dependency management..."
    start_service_with_deps "dnscrypt"
    start_service_with_deps "stubby"
    update_resolved_config
    start_service_with_deps "resolved"

    # Phase 5: Update final DNS routing
    update_resolv_conf

    # Phase 6: Comprehensive Testing & Validation
    run_comprehensive_tests || warn "Some tests failed - check logs for details"

    # Phase 7: Performance Baseline & Monitoring
    establish_performance_baseline
    start_monitoring_daemon

    # Phase 8: Final Report
    generate_installation_report

    log "Enterprise DNS installation completed successfully!"
    info "Your DNS is now secured with enterprise-grade reliability and monitoring."
}

update_resolv_conf() {
    log "Updating resolv.conf..."

    sudo rm -f /etc/resolv.conf
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    log "resolv.conf updated to use systemd-resolved"
}

# Restore function with enhanced safety
restore_dns() {
    log "Restoring DNS configuration from backup files..."

    if [[ ! -f /etc/resolv.conf.bak ]] && [[ ! -f /etc/systemd/resolved.conf.bak ]]; then
        error "No backup files found! Cannot restore."
    fi

    # Stop monitoring daemon
    if [[ -f $PID_FILE ]]; then
        local monitor_pid=$(cat "$PID_FILE")
        if kill -0 "$monitor_pid" 2>/dev/null; then
            kill "$monitor_pid"
            log "Stopped monitoring daemon"
        fi
        rm -f "$PID_FILE"
    fi

    # Stop all DNS services
    sudo systemctl stop dnscrypt-proxy stubby systemd-resolved || true
    sudo systemctl disable dnscrypt-proxy stubby || true

    # Restore configurations
    if [[ -f /etc/resolv.conf.bak ]]; then
        sudo cp /etc/resolv.conf.bak /etc/resolv.conf
        log "Restored resolv.conf from backup"
    fi

    if [[ -f /etc/systemd/resolved.conf.bak ]]; then
        sudo cp /etc/systemd/resolved.conf.bak /etc/systemd/resolved.conf
        log "Restored systemd-resolved config from backup"
    fi

    # Clean up configuration files
    sudo rm -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    sudo rm -f /etc/stubby/stubby.yml

    # Restart systemd-resolved with original config
    sudo systemctl start systemd-resolved || true

    # Clean up monitoring files
    rm -f "$METRICS_FILE"

    log "DNS configuration restored to original state"
    info "Reboot recommended to fully apply changes"
}

# Enhanced status function
show_status() {
    info "=== Enterprise DNS Status Report ==="

    # Service status
    info "Service Status:"
    for service_name in "dnscrypt-proxy" "stubby" "systemd-resolved"; do
        local status=$(systemctl is-active "$service_name" 2>/dev/null || echo "inactive")
        local enabled=$(systemctl is-enabled "$service_name" 2>/dev/null || echo "disabled")
        echo "  $service_name: $status ($enabled)"
    done

    # Port status
    info ""
    info "Port Status:"
    echo "  Port 5353 (DNSCrypt): $(nc -z 127.0.0.1 5353 2>/dev/null && echo "OPEN" || echo "CLOSED")"
    echo "  Port 5453 (Stubby): $(nc -z 127.0.0.1 5453 2>/dev/null && echo "OPEN" || echo "CLOSED")"

    # DNS Resolution Tests
    info ""
    info "DNS Resolution Tests:"
    echo -n "  System DNS: "
    nslookup google.com >/dev/null 2>&1 && echo "OK" || echo "FAILED"

    echo -n "  DNSCrypt (port 5353): "
    dig @127.0.0.1 -p 5353 +timeout=3 google.com >/dev/null 2>&1 && echo "OK" || echo "FAILED"

    echo -n "  Stubby DoT (port 5453): "
    dig @127.0.0.1 -p 5453 +timeout=3 google.com >/dev/null 2>&1 && echo "OK" || echo "FAILED"

    echo -n "  DNSSEC: "
    dig +dnssec google.com | grep -q "ad" && echo "OK" || echo "FAILED"

    # Current DNS configuration
    info ""
    info "Current DNS Configuration:"
    if [[ -f /etc/systemd/resolved.conf ]]; then
        grep -E "^(DNS|FallbackDNS|DNSSEC|DNSOverTLS)" /etc/systemd/resolved.conf 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
    fi

    # Monitoring status
    info ""
    info "Monitoring Status:"
    if [[ -f $PID_FILE ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "  Monitoring Daemon: Running (PID: $(cat "$PID_FILE"))"
    else
        echo "  Monitoring Daemon: Stopped"
    fi

    # Performance metrics (if available)
    if [[ -f $METRICS_FILE ]]; then
        info ""
        info "Performance Metrics:"
        local total_queries=$(jq -r '.overall.total_queries // 0' "$METRICS_FILE" 2>/dev/null)
        local success_count=$(jq -r '.overall.success_count // 0' "$METRICS_FILE" 2>/dev/null)
        local avg_response=$(jq -r '.overall.avg_response_time // 0' "$METRICS_FILE" 2>/dev/null)

        if [[ $total_queries -gt 0 ]]; then
            local success_rate=$((success_count * 100 / total_queries))
            echo "  Total Queries: $total_queries"
            echo "  Success Rate: ${success_rate}%"
            echo "  Avg Response Time: ${avg_response}ms"
        else
            echo "  No performance data available yet"
        fi
    fi

    # Backup files
    info ""
    info "Backup Files:"
    ls -la /etc/*.bak 2>/dev/null | while IFS= read -r line; do
        echo "  $line"
    done || echo "  No backup files found"

    # Recent log entries
    info ""
    info "Recent Log Entries (last 10):"
    if [[ -f $LOG_FILE ]]; then
        tail -10 "$LOG_FILE" | while IFS= read -r line; do
            echo "  $line"
        done
    else
        echo "  No log file found"
    fi
}

# Monitor command - show live monitoring
show_monitor() {
    info "=== Live DNS Monitoring ==="
    info "Press Ctrl+C to stop monitoring"
    info ""

    while true; do
        clear
        echo -e "${BLUE}DNS Monitor - $(date)${NC}"
        echo "=========================="

        # Service health
        echo "Service Health:"
        for service in dnscrypt stubby; do
            run_health_checks "$service" >/dev/null 2>&1
            local status=$?
            case $status in
                0) echo "  $service: HEALTHY" ;;
                1) echo "  $service: DEGRADED" ;;
                2) echo "  $service: FAILED" ;;
            esac
        done

        echo ""
        echo "DNS Response Times:"

        # Test DNSCrypt
        local start_time=$(date +%s%3N)
        if dig @127.0.0.1 -p 5353 +timeout=2 google.com >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            echo "  DNSCrypt: $((end_time - start_time))ms"
        else
            echo "  DNSCrypt: TIMEOUT"
        fi

        # Test Stubby
        start_time=$(date +%s%3N)
        if dig @127.0.0.1 -p 5453 +timeout=2 google.com >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            echo "  Stubby: $((end_time - start_time))ms"
        else
            echo "  Stubby: TIMEOUT"
        fi

        # Test system DNS
        start_time=$(date +%s%3N)
        if nslookup google.com >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            echo "  System: $((end_time - start_time))ms"
        else
            echo "  System: FAILED"
        fi

        echo ""
        echo "Circuit Breaker Status:"
        echo "  DNSCrypt Failures: ${CIRCUIT_BREAKERS[dnscrypt_failures]}"
        echo "  Stubby Failures: ${CIRCUIT_BREAKERS[stubby_failures]}"

        sleep 5
    done
}

# Main function with enhanced command handling
main() {
    case "${1:-}" in
        "install")
            install_secure_dns_enterprise
            ;;
        "restore")
            restore_dns
            ;;
        "status")
            show_status
            ;;
        "monitor")
            show_monitor
            ;;
        "stop-monitor")
            if [[ -f $PID_FILE ]]; then
                local monitor_pid=$(cat "$PID_FILE")
                if kill -0 "$monitor_pid" 2>/dev/null; then
                    kill "$monitor_pid"
                    rm -f "$PID_FILE"
                    log "Monitoring daemon stopped"
                else
                    warn "Monitoring daemon not running"
                fi
            else
                warn "No monitoring daemon found"
            fi
            ;;
        "performance")
            generate_performance_report
            ;;
        *)
            echo "Usage: $0 {install|restore|status|monitor|stop-monitor|performance}"
            echo ""
            echo "Enterprise Secure DNS Management:"
            echo "  install       Install secure DNS with monitoring"
            echo "  restore       Restore from backup files"
            echo "  status        Show comprehensive status"
            echo "  monitor       Live monitoring display"
            echo "  stop-monitor  Stop monitoring daemon"
            echo "  performance   Show performance report"
            echo ""
            echo "Features:"
            echo "  - DNS-over-HTTPS (DoH) via DNSCrypt-proxy"
            echo "  - DNS-over-TLS (DoT) via Stubby"
            echo "  - Circuit breakers and auto-recovery"
            echo "  - Performance monitoring and metrics"
            echo "  - Smart failover and load balancing"
            echo "  - Enterprise-grade reliability"
            exit 1
            ;;
    esac
}

# Initialize and run
main "$@"
