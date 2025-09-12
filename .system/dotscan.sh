#!/usr/bin/env bash

# Script to sanitize dotfiles before committing to a public repository
# This removes sensitive information like API keys, tokens, and passwords

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log helpers
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Files that might contain sensitive information
SENSITIVE_FILES=(
  ".zshrc"
  ".bashrc"
  ".profile"
  "kitty/*.conf"
  "zsh/*.zsh"
  "i3/config"
  "polybar/config"
)

# Patterns to search for
SENSITIVE_PATTERNS=(
  "API_KEY"
  "SECRET"
  "TOKEN"
  "PASSWORD"
  "PASSPHRASE"
  "auth_token"
  "access_token"
  "Bearer"
  "ssh://"
  "key="
  "pass="
  "\.amazonaws\.com"
  "\.mongodb\.net"
  "\.redis\.cloud"
)

# Directory containing dotfiles
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check a file for sensitive information
check_file() {
  local file="$1"
  local found=0
  local pattern
  
  log_info "Checking $file..."
  
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    # Check if the pattern exists in the file
    if grep -q -E "$pattern" "$file" 2>/dev/null; then
      log_warn "Possible sensitive information found in $file (pattern: $pattern)"
      grep --color=always -n -E "$pattern" "$file" | head -5
      found=1
    fi
  done
  
  if [ "$found" -eq 0 ]; then
    log_success "No sensitive information found in $file"
  fi
  
  return $found
}

# Main function
main() {
  log_info "Starting sanitization check..."
  local issues_found=0
  
  # Check each potentially sensitive file
  for file_pattern in "${SENSITIVE_FILES[@]}"; do
    # Find files matching the pattern
    find "$DOTFILES_DIR" -path "$DOTFILES_DIR/$file_pattern" -type f 2>/dev/null | while read -r file; do
      if check_file "$file"; then
        : # Do nothing if check_file returns 0 (success)
      else
        issues_found=1
      fi
    done
  done
  
  # Provide summary and advice
  if [ "$issues_found" -eq 0 ]; then
    log_success "No sensitive information detected in your dotfiles!"
    log_info "It's still recommended to manually review files before pushing to a public repository."
  else
    log_warn "Potentially sensitive information found in your dotfiles!"
    log_info "Consider:"
    log_info "1. Removing the sensitive information"
    log_info "2. Using environment variables instead of hardcoded values"
    log_info "3. Creating template files without sensitive data"
    log_info "4. Adding sensitive files to .gitignore"
  fi
}

main "$@"
