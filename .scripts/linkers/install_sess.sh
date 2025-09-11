#!/usr/bin/env bash
# install_session_components.sh
#
# This script installs the session management components to the appropriate
# locations in the dotfiles directory structure.
#
# Usage: ./install_session_components.sh [--help]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
LINKERS_DIR="${DOTFILES_DIR}/scripts/linkers"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help      Show this help message"
    echo "  --redis     Install Redis session manager dependencies"
    echo "  --mongo     Install MongoDB session manager dependencies"
    echo "  --all       Install all dependencies"
    echo ""
    echo "By default, only the basic components are installed (no dependencies)."
}

# Log message with timestamp
log() {
    local level=$1
    local message=$2
    local color=$NC

    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "ERROR") color=$RED ;;
        "WARNING") color=$YELLOW ;;
    esac

    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message${NC}"
}

# Create directory if it doesn't exist
create_dir_if_not_exists() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        log "INFO" "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Check if file exists and is different, then create or update
install_file() {
    local source=$1
    local dest=$2

    # If destination doesn't exist or is different from source
    if [ ! -f "$dest" ] || ! cmp -s "$source" "$dest"; then
        log "INFO" "Installing: $dest"
        cp "$source" "$dest"
        return 0
    else
        log "INFO" "Already up to date: $dest"
        return 1
    fi
}

# Create the linkers directory structure
create_dir_structure() {
    log "INFO" "Creating directory structure..."

    create_dir_if_not_exists "$LINKERS_DIR"
    create_dir_if_not_exists "$LINKERS_DIR/locally"
}

# Install session management components
install_components() {
    log "INFO" "Installing session management components..."

    # Create empty __init__.py files for Python modules
    touch "$LINKERS_DIR/__init__.py"
    touch "$LINKERS_DIR/locally/__init__.py"

    # Install session integration components
    install_file "$SCRIPT_DIR/linkers/session_adapter.py" "$LINKERS_DIR/session_adapter.py"
    install_file "$SCRIPT_DIR/linkers/session_integration.py" "$LINKERS_DIR/session_integration.py"
    install_file "$SCRIPT_DIR/linkers/session_example.py" "$LINKERS_DIR/session_example.py"

    # Install locally session manager components
    install_file "$SCRIPT_DIR/linkers/locally/base_session.py" "$LINKERS_DIR/locally/base_session.py"
    install_file "$SCRIPT_DIR/linkers/locally/config_manager.py" "$LINKERS_DIR/locally/config_manager.py"
    install_file "$SCRIPT_DIR/linkers/locally/file_session.py" "$LINKERS_DIR/locally/file_session.py"
    install_file "$SCRIPT_DIR/linkers/locally/memory_session.py" "$LINKERS_DIR/locally/memory_session.py"
    install_file "$SCRIPT_DIR/linkers/locally/rate_limiter.py" "$LINKERS_DIR/locally/rate_limiter.py"
    install_file "$SCRIPT_DIR/linkers/locally/redis_session.py" "$LINKERS_DIR/locally/redis_session.py"
}

# Install Python dependencies for Redis
install_redis_deps() {
    log "INFO" "Installing Redis dependencies..."

    if ! command -v pip3 &> /dev/null; then
        log "ERROR" "pip3 command not found. Please install Python 3 and pip."
        exit 1
    fi

    log "INFO" "Installing redis-py..."
    pip3 install redis

    log "SUCCESS" "Redis dependencies installed"
}

# Install Python dependencies for MongoDB
install_mongo_deps() {
    log "INFO" "Installing MongoDB dependencies..."

    if ! command -v pip3 &> /dev/null; then
        log "ERROR" "pip3 command not found. Please install Python 3 and pip."
        exit 1
    fi

    log "INFO" "Installing pymongo..."
    pip3 install pymongo

    log "SUCCESS" "MongoDB dependencies installed"
}

# Set file permissions
set_permissions() {
    log "INFO" "Setting file permissions..."

    # Make example script executable
    chmod +x "$LINKERS_DIR/session_example.py"
}

# Main function
main() {
    local install_redis=false
    local install_mongo=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                print_usage
                exit 0
                ;;
            --redis)
                install_redis=true
                shift
                ;;
            --mongo)
                install_mongo=true
                shift
                ;;
            --all)
                install_redis=true
                install_mongo=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    log "INFO" "Starting installation of session management components..."

    # Create directory structure
    create_dir_structure

    # Install components
    install_components

    # Set permissions
    set_permissions

    # Install dependencies if requested
    if $install_redis; then
        install_redis_deps
    fi

    if $install_mongo; then
        install_mongo_deps
    fi

    log "SUCCESS" "Installation completed successfully"
    log "INFO" "You can test the session management components by running:"
    log "INFO" "  python3 $LINKERS_DIR/session_example.py"
}

# Execute main function
main "$@"
