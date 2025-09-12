# Changelog

All notable changes to this dotfiles repository will be documented in this file.

## [2025-09-12] - Script Reorganization

### Changed
- **Major script renaming** for better usability:
  - `secure-dns-setup-strong.sh` → **`dnspro.sh`** (Enterprise DNS with monitoring)
  - `secure-dns-setup.sh` → **`dnsbasic.sh`** (Basic secure DNS)
  - `emergency-revert.sh` → **`emergency.sh`** (Emergency recovery)
  - `secure-docker-setup.sh` → **`dockersec.sh`** (Docker security)
  - `test-dns-docker.sh` → **`testdns.sh`** (DNS testing)
  - `restore_dotfiles.sh` → **`dotrestore.sh`** (Dotfiles restore)
  - `sync_dotfiles.sh` → **`dotbackup.sh`** (Dotfiles backup)
  - `install.sh` → **`dotsetup.sh`** (Dotfiles setup)
  - `sanitize.sh` → **`dotscan.sh`** (Security scan)

### Fixed
- **DNS setup script bugs**:
  - Fixed missing quotes in certificate hashes
  - Removed unsupported `refuse_any` configuration option
  - Commented out non-existent `dnscrypt` user reference
  - Fixed indentation and syntax errors in dependency logic
  - Added bounds checking for arithmetic operations

- **Updated all internal references**:
  - Fixed file paths and script names in all scripts
  - Updated location comments and usage instructions
  - Corrected cross-script references

### Added
- **Comprehensive README update** with:
  - Complete script reference guide
  - Usage examples for all scripts
  - Troubleshooting section
  - Clear categorization (Dotfiles, DNS/Network, Security)

### Benefits
- **Easier to remember**: Short names without underscores
- **Consistent naming**: Clear categorization by purpose
- **Better documentation**: Complete usage guide in README
- **Bug-free scripts**: All syntax errors and path issues resolved

## Migration Guide

If you were using the old script names, update your commands:

```bash
# Old → New
./secure-dns-setup-strong.sh install  →  sudo ./dnspro.sh install
./secure-dns-setup.sh install         →  sudo ./dnsbasic.sh install
./emergency-revert.sh                 →  sudo ./emergency.sh
./install.sh                          →  ./dotsetup.sh
./sync_dotfiles.sh                    →  ./dotbackup.sh
./restore_dotfiles.sh                 →  ./dotrestore.sh
./sanitize.sh                         →  ./dotscan.sh
```