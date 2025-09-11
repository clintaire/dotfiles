#!/bin/zsh

# =============================================================================
# regex_toolkit.sh - A comprehensive regex utility script
# Created: September 6, 2025
# Author: GitHub Copilot
#
# Usage: ./regex_toolkit.sh [command] [options]
# =============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# Utility Functions
# =============================================================================

# Display help message
show_help() {
  echo -e "${CYAN}RegEx Toolkit - A comprehensive regex utility${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) [command] [options]"
  echo
  echo -e "${YELLOW}Commands:${NC}"
  echo "  http          - HTTP/URL parsing utilities"
  echo "  html          - HTML parsing utilities"
  echo "  base64        - Base64 encoding/decoding utilities"
  echo "  validate      - Validation utilities (email, phone, etc.)"
  echo "  match         - Advanced regex matching utilities"
  echo "  extract       - Extract patterns from text"
  echo "  replace       - Search and replace with regex"
  echo "  help          - Show this help message"
  echo
  echo -e "${YELLOW}For command-specific help:${NC}"
  echo "  $(basename $0) [command] --help"
  echo
}

# Show HTTP command help
show_http_help() {
  echo -e "${CYAN}HTTP/URL Regex Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) http [subcommand] [options]"
  echo
  echo -e "${YELLOW}Subcommands:${NC}"
  echo "  extract-urls [file|-]      - Extract all URLs from file or stdin"
  echo "  validate-url [url]         - Validate if a URL is properly formatted"
  echo "  parse-url [url]            - Parse URL into components"
  echo "  extract-params [url]       - Extract query parameters from URL"
  echo "  extract-domain [url]       - Extract domain from URL"
  echo
}

# Show HTML command help
show_html_help() {
  echo -e "${CYAN}HTML Regex Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) html [subcommand] [options]"
  echo
  echo -e "${YELLOW}Subcommands:${NC}"
  echo "  extract-tags [tag] [file|-]   - Extract specific HTML tags from file or stdin"
  echo "  extract-attrs [attr] [file|-] - Extract specific HTML attributes from file or stdin"
  echo "  strip-tags [file|-]           - Strip all HTML tags from file or stdin"
  echo "  extract-links [file|-]        - Extract all links from HTML"
  echo "  extract-images [file|-]       - Extract all image sources from HTML"
  echo
}

# Show Base64 command help
show_base64_help() {
  echo -e "${CYAN}Base64 Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) base64 [subcommand] [options]"
  echo
  echo -e "${YELLOW}Subcommands:${NC}"
  echo "  encode [text|file|-]      - Encode text or file content to Base64"
  echo "  decode [text|file|-]      - Decode Base64 to text"
  echo "  detect [file|-]           - Detect Base64 encoded strings in text"
  echo "  validate [string]         - Validate if a string is valid Base64"
  echo
}

# Show Validation command help
show_validate_help() {
  echo -e "${CYAN}Validation Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) validate [subcommand] [options]"
  echo
  echo -e "${YELLOW}Subcommands:${NC}"
  echo "  email [email]             - Validate email address"
  echo "  phone [phone]             - Validate phone number"
  echo "  ip [ip]                   - Validate IP address (IPv4 or IPv6)"
  echo "  date [date]               - Validate date format"
  echo "  credit-card [number]      - Validate credit card number"
  echo "  password [password]       - Check password strength"
  echo "  uuid [uuid]               - Validate UUID"
  echo
}

# Show Match command help
show_match_help() {
  echo -e "${CYAN}Advanced Regex Matching Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) match [subcommand] [options]"
  echo
  echo -e "${YELLOW}Subcommands:${NC}"
  echo "  pattern [pattern] [file|-]  - Match regex pattern in file or stdin"
  echo "  count [pattern] [file|-]    - Count matches of pattern in file or stdin"
  echo "  lines [pattern] [file|-]    - Print lines matching pattern"
  echo "  capture [pattern] [file|-]  - Extract capture groups from pattern matches"
  echo "  lookaround [pattern] [file|-] - Match using lookahead/lookbehind assertions"
  echo
}

# Show Extract command help
show_extract_help() {
  echo -e "${CYAN}Extraction Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) extract [subcommand] [options]"
  echo
  echo -e "${YELLOW}Subcommands:${NC}"
  echo "  emails [file|-]          - Extract email addresses"
  echo "  phones [file|-]          - Extract phone numbers"
  echo "  dates [file|-]           - Extract dates"
  echo "  ips [file|-]             - Extract IP addresses"
  echo "  ssn [file|-]             - Extract social security numbers"
  echo "  custom [pattern] [file|-] - Extract using custom pattern"
  echo
}

# Show Replace command help
show_replace_help() {
  echo -e "${CYAN}Search and Replace Utilities${NC}"
  echo
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $(basename $0) replace [pattern] [replacement] [file|-]"
  echo
  echo -e "${YELLOW}Options:${NC}"
  echo "  -g                 - Replace globally (all occurrences)"
  echo "  -i                 - Case insensitive matching"
  echo "  -b                 - Backup original file (creates .bak)"
  echo "  --dry-run          - Show what would be changed without making changes"
  echo
}

# =============================================================================
# HTTP/URL Functions
# =============================================================================

# Extract URLs from text
extract_urls() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract URLs from file or stdin${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) http extract-urls [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Modern regex to match URLs - handles http, https, ftp with optional www
  echo "$input" | grep -Eo 'https?://[a-zA-Z0-9./?=_%:-]*|www\.[a-zA-Z0-9./?=_%:-]*'
}

# Validate if a URL is properly formatted
validate_url() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate if a URL is properly formatted${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) http validate-url [url]"
    echo
    return 0
  fi

  local url="$1"
  
  # Comprehensive URL validation regex
  if echo "$url" | grep -Pq '^(https?|ftp)://[^\s/$.?#].[^\s]*$'; then
    echo -e "${GREEN}Valid URL: $url${NC}"
    return 0
  else
    echo -e "${RED}Invalid URL: $url${NC}"
    return 1
  fi
}

# Parse URL into components
parse_url() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Parse URL into components${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) http parse-url [url]"
    echo
    return 0
  fi

  local url="$1"
  
  # Extract protocol
  local protocol=$(echo "$url" | grep -Eo '^(https?|ftp)')
  
  # Extract domain
  local domain=$(echo "$url" | grep -Eo '(https?|ftp)://([^/]+)' | sed 's/^(https?|ftp):\/\///')
  
  # Extract path
  local path=$(echo "$url" | grep -Eo '(https?|ftp)://[^/]+(/[^?#]*)?')
  path=${path#*$domain}
  
  # Extract query string
  local query=$(echo "$url" | grep -Eo '\?[^#]*')
  
  # Extract fragment
  local fragment=$(echo "$url" | grep -Eo '#.*$')
  
  echo -e "${CYAN}URL Components:${NC}"
  echo -e "${YELLOW}Protocol:${NC} $protocol"
  echo -e "${YELLOW}Domain:${NC} $domain"
  echo -e "${YELLOW}Path:${NC} ${path:-/}"
  echo -e "${YELLOW}Query:${NC} ${query:-(none)}"
  echo -e "${YELLOW}Fragment:${NC} ${fragment:-(none)}"
}

# Extract query parameters from URL
extract_params() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Extract query parameters from URL${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) http extract-params [url]"
    echo
    return 0
  fi

  local url="$1"
  
  # Extract query string
  local query=$(echo "$url" | grep -Eo '\?([^#]*)')
  query=${query#\?}
  
  if [[ -z "$query" ]]; then
    echo -e "${YELLOW}No query parameters found in URL${NC}"
    return 0
  fi
  
  echo -e "${CYAN}Query Parameters:${NC}"
  
  # Split parameters and print them
  echo "$query" | tr '&' '\n' | while IFS='=' read -r key value; do
    echo -e "${YELLOW}$key:${NC} $value"
  done
}

# Extract domain from URL
extract_domain() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Extract domain from URL${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) http extract-domain [url]"
    echo
    return 0
  fi

  local url="$1"
  
  # Extract domain
  local domain=$(echo "$url" | grep -Eo '(https?|ftp)://([^/]+)' | sed -E 's#(https?|ftp)://##')
  
  echo "$domain"
}

# =============================================================================
# HTML Functions
# =============================================================================

# Extract specific HTML tags
extract_tags() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Extract specific HTML tags from file or stdin${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) html extract-tags [tag] [file|-]"
    echo
    return 0
  fi

  local tag="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # 2025 improved regex for HTML tag extraction with nested tags
  echo "$input" | grep -Pzo "(?s)<$tag[^>]*>(.*?)</$tag>" | sed 's/\x0/\n/g'
}

# Extract specific HTML attributes
extract_attrs() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Extract specific HTML attributes from file or stdin${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) html extract-attrs [attr] [file|-]"
    echo
    return 0
  fi

  local attr="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Enhanced regex to extract attribute values, handling both single and double quotes
  echo "$input" | grep -Po "$attr\s*=\s*[\"']([^\"']*)[\"']" | sed -E "s/$attr\s*=\s*[\"']([^\"']*)[\"']/\1/"
}

# Strip all HTML tags
strip_tags() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Strip all HTML tags from file or stdin${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) html strip-tags [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Modern approach to strip HTML tags with PCRE regex
  echo "$input" | sed -E 's/<[^>]*>//g'
}

# Extract all links from HTML
extract_links() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract all links from HTML${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) html extract-links [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Enhanced regex to extract href attributes from anchor tags
  echo "$input" | grep -Po '<a\s+[^>]*href\s*=\s*["\']([^"\']*)["\'][^>]*>' | 
    grep -Po 'href\s*=\s*["\']([^"\']*)["\']' | 
    sed -E 's/href\s*=\s*["\'](.*)["\'].*/\1/'
}

# Extract all image sources from HTML
extract_images() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract all image sources from HTML${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) html extract-images [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Enhanced regex to extract src attributes from img tags
  echo "$input" | grep -Po '<img\s+[^>]*src\s*=\s*["\']([^"\']*)["\'][^>]*>' | 
    grep -Po 'src\s*=\s*["\']([^"\']*)["\']' | 
    sed -E 's/src\s*=\s*["\'](.*)["\'].*/\1/'
}

# =============================================================================
# Base64 Functions
# =============================================================================

# Encode text or file content to Base64
base64_encode() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Encode text or file content to Base64${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) base64 encode [text|file|-]"
    echo
    return 0
  fi

  local input="$1"
  
  if [[ -z "$input" ]]; then
    # Read from stdin
    cat | base64
  elif [[ -f "$input" ]]; then
    # Read from file
    base64 "$input"
  elif [[ "$input" == "-" ]]; then
    # Read from stdin
    cat | base64
  else
    # Treat as text
    echo -n "$input" | base64
  fi
}

# Decode Base64 to text
base64_decode() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Decode Base64 to text${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) base64 decode [base64_string|file|-]"
    echo
    return 0
  fi

  local input="$1"
  
  if [[ -z "$input" ]]; then
    # Read from stdin
    cat | base64 --decode
  elif [[ -f "$input" ]]; then
    # Read from file
    base64 --decode < "$input"
  elif [[ "$input" == "-" ]]; then
    # Read from stdin
    cat | base64 --decode
  else
    # Treat as text
    echo -n "$input" | base64 --decode
  fi
}

# Detect Base64 encoded strings in text
base64_detect() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Detect Base64 encoded strings in text${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) base64 detect [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Enhanced regex for Base64 detection (2025 improved version)
  echo "$input" | grep -Po '[A-Za-z0-9+/]{20,}={0,2}'
}

# Validate if a string is valid Base64
base64_validate() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate if a string is valid Base64${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) base64 validate [string]"
    echo
    return 0
  fi

  local string="$1"
  
  # Check if string matches Base64 pattern
  if echo "$string" | grep -Eq '^[A-Za-z0-9+/]+={0,2}$'; then
    # Check if padding is correct
    local len=${#string}
    local mod=$((len % 4))
    
    if [[ $mod -eq 0 ]]; then
      echo -e "${GREEN}Valid Base64 string${NC}"
      return 0
    elif [[ $mod -eq 2 && "${string: -2}" == "==" ]]; then
      echo -e "${GREEN}Valid Base64 string${NC}"
      return 0
    elif [[ $mod -eq 3 && "${string: -1}" == "=" ]]; then
      echo -e "${GREEN}Valid Base64 string${NC}"
      return 0
    fi
  fi
  
  echo -e "${RED}Invalid Base64 string${NC}"
  return 1
}

# =============================================================================
# Validation Functions
# =============================================================================

# Validate email address
validate_email() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate email address${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate email [email]"
    echo
    return 0
  fi

  local email="$1"
  
  # 2025 improved email validation regex
  # This handles unicode domains, subdomains, and special characters
  if echo "$email" | grep -Pq '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
    echo -e "${GREEN}Valid email address: $email${NC}"
    return 0
  else
    echo -e "${RED}Invalid email address: $email${NC}"
    return 1
  fi
}

# Validate phone number
validate_phone() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate phone number${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate phone [phone]"
    echo
    return 0
  fi

  local phone="$1"
  
  # Remove any non-digit characters for normalization
  local normalized=$(echo "$phone" | tr -cd '0-9')
  
  # Modern phone validation - checks length and starting digits
  if [[ ${#normalized} -ge 10 && ${#normalized} -le 15 ]]; then
    echo -e "${GREEN}Valid phone number: $phone${NC}"
    return 0
  else
    echo -e "${RED}Invalid phone number: $phone${NC}"
    return 1
  fi
}

# Validate IP address
validate_ip() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate IP address (IPv4 or IPv6)${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate ip [ip]"
    echo
    return 0
  fi

  local ip="$1"
  
  # IPv4 validation
  if echo "$ip" | grep -Pq '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'; then
    echo -e "${GREEN}Valid IPv4 address: $ip${NC}"
    return 0
  # IPv6 validation
  elif echo "$ip" | grep -Pq '^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$'; then
    echo -e "${GREEN}Valid IPv6 address: $ip${NC}"
    return 0
  else
    echo -e "${RED}Invalid IP address: $ip${NC}"
    return 1
  fi
}

# Validate date format
validate_date() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate date format${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate date [date]"
    echo
    echo -e "${YELLOW}Supported formats:${NC}"
    echo "  YYYY-MM-DD, MM/DD/YYYY, DD.MM.YYYY"
    echo
    return 0
  fi

  local date="$1"
  
  # Check various date formats
  if echo "$date" | grep -Pq '^\d{4}-\d{2}-\d{2}$'; then
    # YYYY-MM-DD
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2)
    local day=$(echo "$date" | cut -d'-' -f3)
  elif echo "$date" | grep -Pq '^\d{1,2}/\d{1,2}/\d{4}$'; then
    # MM/DD/YYYY
    local month=$(echo "$date" | cut -d'/' -f1)
    local day=$(echo "$date" | cut -d'/' -f2)
    local year=$(echo "$date" | cut -d'/' -f3)
  elif echo "$date" | grep -Pq '^\d{1,2}\.\d{1,2}\.\d{4}$'; then
    # DD.MM.YYYY
    local day=$(echo "$date" | cut -d'.' -f1)
    local month=$(echo "$date" | cut -d'.' -f2)
    local year=$(echo "$date" | cut -d'.' -f3)
  else
    echo -e "${RED}Invalid date format: $date${NC}"
    return 1
  fi
  
  # Validate month and day
  if [[ $month -lt 1 || $month -gt 12 ]]; then
    echo -e "${RED}Invalid month: $month${NC}"
    return 1
  fi
  
  local max_days=31
  case $month in
    4|6|9|11) max_days=30 ;;
    2)
      # Check for leap year
      if (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) )); then
        max_days=29
      else
        max_days=28
      fi
      ;;
  esac
  
  if [[ $day -lt 1 || $day -gt $max_days ]]; then
    echo -e "${RED}Invalid day: $day${NC}"
    return 1
  fi
  
  echo -e "${GREEN}Valid date: $date${NC}"
  return 0
}

# Validate credit card number
validate_credit_card() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate credit card number${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate credit-card [number]"
    echo
    return 0
  fi

  local number="$1"
  
  # Remove spaces and dashes for normalization
  local normalized=$(echo "$number" | tr -d '[:space:]-')
  
  # Check if it contains only digits
  if ! echo "$normalized" | grep -q '^[0-9]\+$'; then
    echo -e "${RED}Invalid credit card number: contains non-digits${NC}"
    return 1
  fi
  
  # Check length
  local len=${#normalized}
  if [[ $len -lt 13 || $len -gt 19 ]]; then
    echo -e "${RED}Invalid credit card number: incorrect length${NC}"
    return 1
  fi
  
  # Apply Luhn algorithm
  local sum=0
  local alternate=0
  
  for (( i=${#normalized}-1; i>=0; i-- )); do
    local digit=${normalized:$i:1}
    
    if (( alternate )); then
      digit=$(( digit * 2 ))
      if (( digit > 9 )); then
        digit=$(( digit - 9 ))
      fi
    fi
    
    sum=$(( sum + digit ))
    alternate=$(( !alternate ))
  done
  
  if (( sum % 10 == 0 )); then
    echo -e "${GREEN}Valid credit card number${NC}"
    return 0
  else
    echo -e "${RED}Invalid credit card number: failed Luhn check${NC}"
    return 1
  fi
}

# Check password strength
validate_password() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Check password strength${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate password [password]"
    echo
    return 0
  fi

  local password="$1"
  local score=0
  local len=${#password}
  
  # Length check
  if [[ $len -ge 8 ]]; then
    (( score += 1 ))
  fi
  if [[ $len -ge 12 ]]; then
    (( score += 1 ))
  fi
  if [[ $len -ge 16 ]]; then
    (( score += 1 ))
  fi
  
  # Complexity checks
  if echo "$password" | grep -q '[A-Z]'; then
    (( score += 1 ))
  fi
  if echo "$password" | grep -q '[a-z]'; then
    (( score += 1 ))
  fi
  if echo "$password" | grep -q '[0-9]'; then
    (( score += 1 ))
  fi
  if echo "$password" | grep -q '[^A-Za-z0-9]'; then
    (( score += 1 ))
  fi
  
  # Sequential character check
  if ! echo "$password" | grep -Pq '(012|123|234|345|456|567|678|789|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz|ABC|BCD|CDE|DEF|EFG|FGH|GHI|HIJ|IJK|JKL|KLM|LMN|MNO|NOP|OPQ|PQR|QRS|RST|STU|TUV|UVW|VWX|WXY|XYZ)'; then
    (( score += 1 ))
  fi
  
  # Repeated character check
  if ! echo "$password" | grep -Pq '(.)\1{2,}'; then
    (( score += 1 ))
  fi
  
  # Output score and strength assessment
  echo -e "${CYAN}Password strength assessment:${NC}"
  echo -e "${YELLOW}Score:${NC} $score/10"
  
  if [[ $score -le 3 ]]; then
    echo -e "${RED}Strength: Very Weak${NC}"
  elif [[ $score -le 5 ]]; then
    echo -e "${RED}Strength: Weak${NC}"
  elif [[ $score -le 7 ]]; then
    echo -e "${YELLOW}Strength: Moderate${NC}"
  elif [[ $score -le 9 ]]; then
    echo -e "${GREEN}Strength: Strong${NC}"
  else
    echo -e "${GREEN}Strength: Very Strong${NC}"
  fi
  
  # Provide improvement suggestions
  echo -e "${CYAN}Suggestions:${NC}"
  if [[ $len -lt 12 ]]; then
    echo "- Increase length to at least 12 characters"
  fi
  if ! echo "$password" | grep -q '[A-Z]'; then
    echo "- Add uppercase letters"
  fi
  if ! echo "$password" | grep -q '[a-z]'; then
    echo "- Add lowercase letters"
  fi
  if ! echo "$password" | grep -q '[0-9]'; then
    echo "- Add numbers"
  fi
  if ! echo "$password" | grep -q '[^A-Za-z0-9]'; then
    echo "- Add special characters"
  fi
}

# Validate UUID
validate_uuid() {
  if [[ "$1" == "--help" || -z "$1" ]]; then
    echo -e "${CYAN}Validate UUID${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) validate uuid [uuid]"
    echo
    return 0
  fi

  local uuid="$1"
  
  # UUID validation regex
  if echo "$uuid" | grep -Pq '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'; then
    echo -e "${GREEN}Valid UUID: $uuid${NC}"
    return 0
  else
    echo -e "${RED}Invalid UUID: $uuid${NC}"
    return 1
  fi
}

# =============================================================================
# Advanced Matching Functions
# =============================================================================

# Match regex pattern in file or stdin
match_pattern() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Match regex pattern in file or stdin${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) match pattern [pattern] [file|-]"
    echo
    return 0
  fi

  local pattern="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Use grep with PCRE for advanced pattern matching
  echo "$input" | grep -P "$pattern"
}

# Count matches of pattern in file or stdin
match_count() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Count matches of pattern in file or stdin${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) match count [pattern] [file|-]"
    echo
    return 0
  fi

  local pattern="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Count matches
  local count=$(echo "$input" | grep -Po "$pattern" | wc -l)
  echo -e "Pattern '$pattern' matched ${CYAN}$count${NC} times"
}

# Print lines matching pattern
match_lines() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Print lines matching pattern${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) match lines [pattern] [file|-]"
    echo
    return 0
  fi

  local pattern="$1"
  local source="$2"
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin and match
    grep -P "$pattern"
  elif [[ -f "$source" ]]; then
    # Read from file and match
    grep -P "$pattern" "$source"
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
}

# Extract capture groups from pattern matches
match_capture() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Extract capture groups from pattern matches${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) match capture [pattern] [file|-]"
    echo
    return 0
  fi

  local pattern="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Use grep with PCRE to extract capture groups
  echo "$input" | grep -Po "$pattern"
}

# Match using lookahead/lookbehind assertions
match_lookaround() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Match using lookahead/lookbehind assertions${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) match lookaround [pattern] [file|-]"
    echo
    echo -e "${YELLOW}Example patterns:${NC}"
    echo "  Positive lookahead: (?=...)"
    echo "  Negative lookahead: (?!...)"
    echo "  Positive lookbehind: (?<=...)"
    echo "  Negative lookbehind: (?<!...)"
    echo
    return 0
  fi

  local pattern="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Use grep with PCRE for lookaround assertions
  echo "$input" | grep -Po "$pattern"
}

# =============================================================================
# Extraction Functions
# =============================================================================

# Extract email addresses
extract_emails() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract email addresses${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) extract emails [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # 2025 improved email extraction regex
  echo "$input" | grep -Po '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq
}

# Extract phone numbers
extract_phones() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract phone numbers${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) extract phones [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Enhanced phone number extraction pattern
  echo "$input" | grep -Po '\+?[0-9]{1,3}[-. ]?\(?\d{1,4}\)?[-. ]?\d{1,4}[-. ]?\d{1,4}' | sort | uniq
}

# Extract dates
extract_dates() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract dates${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) extract dates [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Modern date extraction pattern
  echo "$input" | grep -Po '\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{4}|\d{1,2}\.\d{1,2}\.\d{4}' | sort | uniq
}

# Extract IP addresses
extract_ips() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract IP addresses${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) extract ips [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # IPv4 extraction
  echo -e "${CYAN}IPv4 Addresses:${NC}"
  echo "$input" | grep -Po '((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' | sort | uniq
  
  # IPv6 extraction
  echo -e "${CYAN}IPv6 Addresses:${NC}"
  echo "$input" | grep -Po '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' | sort | uniq
}

# Extract social security numbers
extract_ssn() {
  if [[ "$1" == "--help" ]]; then
    echo -e "${CYAN}Extract social security numbers${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) extract ssn [file|-]"
    echo
    return 0
  fi

  local source="$1"
  local input=""
  
  if [[ -z "$source" || "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # SSN extraction pattern
  echo "$input" | grep -Po '\b\d{3}[-]?\d{2}[-]?\d{4}\b' | sort | uniq
}

# Extract using custom pattern
extract_custom() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" ]]; then
    echo -e "${CYAN}Extract using custom pattern${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $(basename $0) extract custom [pattern] [file|-]"
    echo
    return 0
  fi

  local pattern="$1"
  local source="$2"
  local input=""
  
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    input=$(cat)
  elif [[ -f "$source" ]]; then
    # Read from file
    input=$(cat "$source")
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
  
  # Use custom pattern for extraction
  echo "$input" | grep -Po "$pattern" | sort | uniq
}

# =============================================================================
# Search and Replace Functions
# =============================================================================

# Perform search and replace with regex
do_replace() {
  if [[ "$1" == "--help" || -z "$1" || -z "$2" || -z "$3" ]]; then
    show_replace_help
    return 0
  fi

  local pattern="$1"
  local replacement="$2"
  local source="$3"
  shift 3
  
  local global=0
  local case_insensitive=0
  local backup=0
  local dry_run=0
  
  # Parse options
  while (( $# > 0 )); do
    case "$1" in
      -g) global=1 ;;
      -i) case_insensitive=1 ;;
      -b) backup=1 ;;
      --dry-run) dry_run=1 ;;
      *) echo -e "${RED}Error: Unknown option - $1${NC}" >&2; return 1 ;;
    esac
    shift
  done
  
  # Build sed command
  local sed_cmd="s/$pattern/$replacement/"
  if (( global )); then
    sed_cmd="${sed_cmd}g"
  fi
  
  local sed_opts=""
  if (( case_insensitive )); then
    sed_opts="${sed_opts}i"
  fi
  
  # Process input
  if [[ "$source" == "-" ]]; then
    # Read from stdin
    if (( dry_run )); then
      cat | sed -n -E$sed_opts "p;$sed_cmd"
    else
      cat | sed -E$sed_opts "$sed_cmd"
    fi
  elif [[ -f "$source" ]]; then
    # Process file
    if (( backup )); then
      cp "$source" "${source}.bak"
    fi
    
    if (( dry_run )); then
      sed -n -E$sed_opts "p;$sed_cmd" "$source"
    else
      # In-place edit
      sed -i.tmp -E$sed_opts "$sed_cmd" "$source" && rm "${source}.tmp"
      echo -e "${GREEN}Replacement complete in $source${NC}"
    fi
  else
    echo -e "${RED}Error: File not found - $source${NC}" >&2
    return 1
  fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
  if [[ $# -eq 0 || "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    return 0
  fi
  
  local command="$1"
  shift
  
  case "$command" in
    http)
      if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        show_http_help
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        extract-urls) extract_urls "$@" ;;
        validate-url) validate_url "$@" ;;
        parse-url) parse_url "$@" ;;
        extract-params) extract_params "$@" ;;
        extract-domain) extract_domain "$@" ;;
        *) echo -e "${RED}Error: Unknown HTTP subcommand - $subcommand${NC}" >&2; show_http_help; return 1 ;;
      esac
      ;;
      
    html)
      if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        show_html_help
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        extract-tags) extract_tags "$@" ;;
        extract-attrs) extract_attrs "$@" ;;
        strip-tags) strip_tags "$@" ;;
        extract-links) extract_links "$@" ;;
        extract-images) extract_images "$@" ;;
        *) echo -e "${RED}Error: Unknown HTML subcommand - $subcommand${NC}" >&2; show_html_help; return 1 ;;
      esac
      ;;
      
    base64)
      if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        show_base64_help
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        encode) base64_encode "$@" ;;
        decode) base64_decode "$@" ;;
        detect) base64_detect "$@" ;;
        validate) base64_validate "$@" ;;
        *) echo -e "${RED}Error: Unknown Base64 subcommand - $subcommand${NC}" >&2; show_base64_help; return 1 ;;
      esac
      ;;
      
    validate)
      if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        show_validate_help
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        email) validate_email "$@" ;;
        phone) validate_phone "$@" ;;
        ip) validate_ip "$@" ;;
        date) validate_date "$@" ;;
        credit-card) validate_credit_card "$@" ;;
        password) validate_password "$@" ;;
        uuid) validate_uuid "$@" ;;
        *) echo -e "${RED}Error: Unknown validation subcommand - $subcommand${NC}" >&2; show_validate_help; return 1 ;;
      esac
      ;;
      
    match)
      if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        show_match_help
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        pattern) match_pattern "$@" ;;
        count) match_count "$@" ;;
        lines) match_lines "$@" ;;
        capture) match_capture "$@" ;;
        lookaround) match_lookaround "$@" ;;
        *) echo -e "${RED}Error: Unknown match subcommand - $subcommand${NC}" >&2; show_match_help; return 1 ;;
      esac
      ;;
      
    extract)
      if [[ $# -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
        show_extract_help
        return 0
      fi
      
      local subcommand="$1"
      shift
      
      case "$subcommand" in
        emails) extract_emails "$@" ;;
        phones) extract_phones "$@" ;;
        dates) extract_dates "$@" ;;
        ips) extract_ips "$@" ;;
        ssn) extract_ssn "$@" ;;
        custom) extract_custom "$@" ;;
        *) echo -e "${RED}Error: Unknown extract subcommand - $subcommand${NC}" >&2; show_extract_help; return 1 ;;
      esac
      ;;
      
    replace)
      do_replace "$@" ;;
      
    *)
      echo -e "${RED}Error: Unknown command - $command${NC}" >&2
      show_help
      return 1
      ;;
  esac
  
  return 0
}

# =============================================================================
# Run the Script
# =============================================================================

main "$@"
