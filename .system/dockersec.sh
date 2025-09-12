#!/bin/bash
# Secure Docker Setup Script
# Location: /home/cli/git/dotfiles/.system/dockersec.sh
# Usage: ./dockersec.sh [install|restore|status]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups/docker"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$SCRIPT_DIR/docker-security.log"

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

# Create backup directory
create_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log "Docker backup directory created: $BACKUP_DIR"
}

# Backup current Docker configuration
backup_docker_config() {
    log " Backing up current Docker configuration..."
    
    mkdir -p "$BACKUP_DIR/$TIMESTAMP"
    
    # Backup daemon.json
    if [[ -f /etc/docker/daemon.json ]]; then
        sudo cp /etc/docker/daemon.json "$BACKUP_DIR/$TIMESTAMP/"
        log " Backed up /etc/docker/daemon.json"
    fi
    
    # Backup systemd service files
    if [[ -f /etc/systemd/system/docker.service ]]; then
        sudo cp /etc/systemd/system/docker.service "$BACKUP_DIR/$TIMESTAMP/" || true
    fi
    
    # Save current Docker info
    docker info > "$BACKUP_DIR/$TIMESTAMP/docker_info_before.txt" 2>/dev/null || true
    docker version > "$BACKUP_DIR/$TIMESTAMP/docker_version_before.txt" 2>/dev/null || true
    
    # Save current network info
    ss -tlnp > "$BACKUP_DIR/$TIMESTAMP/ports_before.txt" 2>/dev/null || true
    
    log " Docker configuration backed up to: $BACKUP_DIR/$TIMESTAMP"
}

# Configure secure Docker daemon
configure_docker_daemon() {
    log " Configuring secure Docker daemon..."
    
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "iptables": false,
  "bridge": "none",
  "userland-proxy": false,
  "live-restore": true,
  "no-new-privileges": true,
  "icc": false,
  "log-driver": "journald",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "userns-remap": "default",
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "selinux-enabled": false,
  "disable-legacy-registry": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "default-ulimits": {
    "memlock": {
      "hard": 67108864,
      "soft": 67108864
    },
    "nofile": {
      "hard": 65536,
      "soft": 65536
    }
  },
  "seccomp-profile": "/etc/docker/seccomp-default.json",
  "cgroup-parent": "docker.slice",
  "default-shm-size": "64M",
  "shutdown-timeout": 15,
  "debug": false,
  "hosts": ["unix:///var/run/docker.sock"],
  "containerd": "/run/containerd/containerd.sock"
}
EOF

    log " Docker daemon.json configured with security hardening"
}

# Create secure Docker systemd service
configure_docker_service() {
    log " Configuring secure Docker systemd service..."
    
    # Create systemd drop-in directory
    sudo mkdir -p /etc/systemd/system/docker.service.d/
    
    # Create security override
    sudo tee /etc/systemd/system/docker.service.d/security.conf > /dev/null <<EOF
[Unit]
Description=Docker Application Container Engine (Hardened)
Documentation=https://docs.docker.com
After=network-online.target containerd.service
Wants=network-online.target
Requires=containerd.service

[Service]
Type=notify
ExecStart=
ExecStart=/usr/bin/dockerd --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=always

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=false
ProtectHostname=true
ProtectClock=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
RestrictNamespaces=~CLONE_NEWUSER
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
SystemCallFilter=@system-service
SystemCallFilter=~@debug @mount @cpu-emulation @obsolete @privileged @reboot @swap
SystemCallErrorNumber=EPERM
SystemCallArchitectures=native

# Resource limits
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
OOMScoreAdjust=-500

# Network security
IPAccounting=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK

[Install]
WantedBy=multi-user.target
EOF

    log " Docker systemd service hardened"
}

# Configure Docker security profiles
configure_security_profiles() {
    log " Configuring Docker security profiles..."
    
    # Create custom seccomp profile
    sudo tee /etc/docker/seccomp-default.json > /dev/null <<'EOF'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "archMap": [
    {
      "architecture": "SCMP_ARCH_X86_64",
      "subArchitectures": [
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
      ]
    }
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "bind",
        "brk",
        "capget",
        "capset",
        "chdir",
        "chmod",
        "chown",
        "chown32",
        "clock_getres",
        "clock_gettime",
        "clock_nanosleep",
        "close",
        "connect",
        "copy_file_range",
        "creat",
        "dup",
        "dup2",
        "dup3",
        "epoll_create",
        "epoll_create1",
        "epoll_ctl",
        "epoll_pwait",
        "epoll_wait",
        "eventfd",
        "eventfd2",
        "execve",
        "exit",
        "exit_group",
        "fchdir",
        "fchmod",
        "fchmodat",
        "fchown",
        "fchown32",
        "fchownat",
        "fcntl",
        "fcntl64",
        "fdatasync",
        "fgetxattr",
        "flistxattr",
        "flock",
        "fork",
        "fstat",
        "fstat64",
        "fstatat64",
        "fstatfs",
        "fstatfs64",
        "fsync",
        "ftruncate",
        "ftruncate64",
        "futex",
        "getcwd",
        "getdents",
        "getdents64",
        "getegid",
        "geteuid",
        "getgid",
        "getgroups",
        "getpeername",
        "getpgrp",
        "getpid",
        "getppid",
        "getpriority",
        "getrandom",
        "getrlimit",
        "get_robust_list",
        "getrusage",
        "getsid",
        "getsockname",
        "getsockopt",
        "get_thread_area",
        "gettid",
        "gettimeofday",
        "getuid",
        "getxattr",
        "inotify_add_watch",
        "inotify_init",
        "inotify_init1",
        "inotify_rm_watch",
        "ioctl",
        "kill",
        "lchown",
        "lchown32",
        "lgetxattr",
        "link",
        "linkat",
        "listen",
        "listxattr",
        "llistxattr",
        "lseek",
        "_llseek",
        "lremovexattr",
        "lsetxattr",
        "lstat",
        "lstat64",
        "madvise",
        "memfd_create",
        "mkdir",
        "mkdirat",
        "mknod",
        "mknodat",
        "mlock",
        "mlock2",
        "mlockall",
        "mmap",
        "mmap2",
        "mprotect",
        "mq_getsetattr",
        "mq_notify",
        "mq_open",
        "mq_receive",
        "mq_send",
        "mq_timedreceive",
        "mq_timedsend",
        "mq_unlink",
        "mremap",
        "msgctl",
        "msgget",
        "msgrcv",
        "msgsnd",
        "msync",
        "munlock",
        "munlockall",
        "munmap",
        "nanosleep",
        "newfstatat",
        "_newselect",
        "open",
        "openat",
        "pause",
        "pipe",
        "pipe2",
        "poll",
        "ppoll",
        "prctl",
        "pread64",
        "preadv",
        "prlimit64",
        "pselect6",
        "ptrace",
        "pwrite64",
        "pwritev",
        "read",
        "readlink",
        "readlinkat",
        "readv",
        "recv",
        "recvfrom",
        "recvmmsg",
        "recvmsg",
        "rename",
        "renameat",
        "renameat2",
        "rmdir",
        "rt_sigaction",
        "rt_sigpending",
        "rt_sigprocmask",
        "rt_sigqueueinfo",
        "rt_sigreturn",
        "rt_sigsuspend",
        "rt_sigtimedwait",
        "rt_tgsigqueueinfo",
        "sched_getaffinity",
        "sched_getattr",
        "sched_getparam",
        "sched_get_priority_max",
        "sched_get_priority_min",
        "sched_getscheduler",
        "sched_setaffinity",
        "sched_setattr",
        "sched_setparam",
        "sched_setscheduler",
        "sched_yield",
        "seccomp",
        "select",
        "semctl",
        "semget",
        "semop",
        "semtimedop",
        "send",
        "sendfile",
        "sendfile64",
        "sendmmsg",
        "sendmsg",
        "sendto",
        "setfsgid",
        "setfsgid32",
        "setfsuid",
        "setfsuid32",
        "setgid",
        "setgid32",
        "setgroups",
        "setgroups32",
        "setitimer",
        "setpgid",
        "setpriority",
        "setregid",
        "setregid32",
        "setresgid",
        "setresgid32",
        "setresuid",
        "setresuid32",
        "setreuid",
        "setreuid32",
        "setrlimit",
        "set_robust_list",
        "setsid",
        "setsockopt",
        "set_thread_area",
        "set_tid_address",
        "setuid",
        "setuid32",
        "setxattr",
        "shmat",
        "shmctl",
        "shmdt",
        "shmget",
        "shutdown",
        "sigaltstack",
        "signalfd",
        "signalfd4",
        "sigreturn",
        "socket",
        "socketcall",
        "socketpair",
        "splice",
        "stat",
        "stat64",
        "statfs",
        "statfs64",
        "statx",
        "symlink",
        "symlinkat",
        "sync",
        "sync_file_range",
        "syncfs",
        "sysinfo",
        "tee",
        "tgkill",
        "time",
        "timer_create",
        "timer_delete",
        "timerfd_create",
        "timerfd_gettime",
        "timerfd_settime",
        "timer_getoverrun",
        "timer_gettime",
        "timer_settime",
        "times",
        "tkill",
        "truncate",
        "truncate64",
        "ugetrlimit",
        "umask",
        "uname",
        "unlink",
        "unlinkat",
        "utime",
        "utimensat",
        "utimes",
        "vfork",
        "vmsplice",
        "wait4",
        "waitid",
        "waitpid",
        "write",
        "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
EOF

    # Set proper permissions
    sudo chmod 644 /etc/docker/seccomp-default.json
    
    log " Docker security profiles configured"
}

# Create user namespace mapping
configure_user_namespace() {
    log " Configuring Docker user namespace..."
    
    # Create dockremap user if not exists
    if ! id -u dockremap >/dev/null 2>&1; then
        sudo useradd -r -s /bin/false dockremap
        log " Created dockremap user"
    fi
    
    # Configure subuid and subgid
    if ! grep -q "dockremap" /etc/subuid; then
        echo "dockremap:165536:65536" | sudo tee -a /etc/subuid
        log " Added dockremap to subuid"
    fi
    
    if ! grep -q "dockremap" /etc/subgid; then
        echo "dockremap:165536:65536" | sudo tee -a /etc/subgid  
        log " Added dockremap to subgid"
    fi
    
    log " User namespace configured"
}

# Configure iptables rules for Docker security
configure_docker_firewall() {
    log " Configuring Docker firewall rules..."
    
    # Create iptables rules script
    sudo tee /etc/docker/docker-firewall.sh > /dev/null <<'EOF'
#!/bin/bash
# Docker security firewall rules

# Block Docker from modifying iptables
iptables -I DOCKER-USER -j DROP
iptables -I DOCKER-USER -i lo -j ACCEPT
iptables -I DOCKER-USER -o lo -j ACCEPT

# Allow only localhost communication
iptables -I DOCKER-USER -s 127.0.0.0/8 -j ACCEPT
iptables -I DOCKER-USER -d 127.0.0.0/8 -j ACCEPT

# Block access to metadata services
iptables -I DOCKER-USER -d 169.254.169.254 -j DROP
iptables -I DOCKER-USER -d 169.254.0.0/16 -j DROP

log "Docker firewall rules applied"
EOF

    sudo chmod +x /etc/docker/docker-firewall.sh
    
    log " Docker firewall rules configured"
}

# Restart Docker with new configuration
restart_docker() {
    log " Restarting Docker with secure configuration..."
    
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    # Wait for Docker to start
    sleep 5
    
    if sudo systemctl is-active docker >/dev/null; then
        log " Docker restarted successfully"
    else
        error "Docker failed to restart"
    fi
}

# Test Docker security
test_docker_security() {
    log " Testing Docker security configuration..."
    
    info "Testing Docker daemon..."
    docker version >/dev/null && log " Docker daemon responsive" || warn "Docker daemon test failed"
    
    info "Testing user namespace..."
    docker run --rm hello-world >/dev/null 2>&1 && log " User namespace working" || warn "User namespace test failed"
    
    info "Testing security profiles..."
    if docker info 2>/dev/null | grep -q "Security Options"; then
        log " Security options active"
    else
        warn "Security options may not be active"
    fi
    
    # Save test results
    mkdir -p "$BACKUP_DIR/$TIMESTAMP"
    {
        echo "=== Docker Security Test Results ==="
        echo "Date: $(date)"
        echo "Docker info:"
        docker info 2>&1
        echo "Active services:"
        systemctl is-active docker 2>&1
        echo "Listening ports:"
        ss -tlnp | grep docker 2>&1 || echo "No Docker ports listening (good)"
    } > "$BACKUP_DIR/$TIMESTAMP/docker_security_test.txt"
    
    log " Docker security tests completed"
}

# Install function
install_secure_docker() {
    log " Installing Secure Docker Configuration..."
    
    create_backup_dir
    backup_docker_config
    configure_docker_daemon
    configure_docker_service
    configure_security_profiles
    configure_user_namespace
    configure_docker_firewall
    restart_docker
    test_docker_security
    
    log " Secure Docker installation completed!"
    info "Docker is now hardened with:"
    info "  - User namespace isolation"
    info "  - Custom seccomp profile"
    info "  - No iptables manipulation"
    info "  - Resource limits"
    info "  - Systemd hardening"
    info ""
    info "Backup saved to: $BACKUP_DIR/$TIMESTAMP"
    info "To restore: $0 restore $TIMESTAMP"
}

# Restore function
restore_docker() {
    local restore_timestamp="$1"
    
    if [[ -z "$restore_timestamp" ]]; then
        error "Please specify backup timestamp to restore"
    fi
    
    if [[ ! -d "$BACKUP_DIR/$restore_timestamp" ]]; then
        error "Backup not found: $BACKUP_DIR/$restore_timestamp"
    fi
    
    log " Restoring Docker configuration from $restore_timestamp..."
    
    # Stop Docker
    sudo systemctl stop docker
    
    # Restore daemon.json
    if [[ -f "$BACKUP_DIR/$restore_timestamp/daemon.json" ]]; then
        sudo cp "$BACKUP_DIR/$restore_timestamp/daemon.json" /etc/docker/daemon.json
        log " Restored daemon.json"
    fi
    
    # Remove security overrides
    sudo rm -rf /etc/systemd/system/docker.service.d/security.conf
    sudo rm -f /etc/docker/seccomp-default.json
    sudo rm -f /etc/docker/docker-firewall.sh
    
    # Reload and restart
    sudo systemctl daemon-reload
    sudo systemctl start docker
    
    log " Docker configuration restored"
}

# Status function
show_docker_status() {
    log " Docker Security Status"
    
    info "=== Docker Service Status ==="
    systemctl is-active docker || true
    
    info "=== Docker Info ==="
    docker info 2>/dev/null | grep -E "(Security Options|User Namespace|Seccomp|Storage Driver)" || true
    
    info "=== Docker Daemon Config ==="
    cat /etc/docker/daemon.json 2>/dev/null || echo "No daemon.json found"
    
    info "=== Docker Ports ==="
    ss -tlnp | grep docker || echo "No Docker ports listening"
    
    info "=== Available Backups ==="
    ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
}

# Main function
main() {
    case "${1:-}" in
        "install")
            install_secure_docker
            ;;
        "restore")
            restore_docker "${2:-}"
            ;;
        "status")
            show_docker_status
            ;;
        *)
            echo "Usage: $0 {install|restore <timestamp>|status}"
            echo ""
            echo "Examples:"
            echo "  $0 install                    # Install secure Docker"
            echo "  $0 restore 20231212_143022   # Restore from backup"
            echo "  $0 status                    # Show current status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"