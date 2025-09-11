# Session Management Components

This directory contains session management components for privacy-focused applications.

## Overview

The session management system provides a flexible way to handle user sessions with
multiple storage backends:

1. **Memory Session Manager**: Stores sessions in memory (lost on restart)
2. **File Session Manager**: Stores sessions in encrypted files
3. **Redis Session Manager**: Stores sessions in a Redis database
4. **MongoDB Session Manager**: Stores sessions in a MongoDB database

All implementations follow the same privacy-focused principles:

- Sessions automatically expire after a configurable time
- All sensitive data is properly encrypted
- No unnecessary user data is stored
- Easy to wipe all session data

## Directory Structure

```text
linkers/
├── __init__.py
├── session_adapter.py      # Adapter pattern for different session managers
├── session_integration.py  # Integration with other components
├── session_example.py      # Example usage script
├── locally/
│   ├── __init__.py
│   ├── base_session.py     # Base class for local session managers
│   ├── config_manager.py   # Configuration management
│   ├── file_session.py     # File-based session manager
│   ├── memory_session.py   # In-memory session manager
│   ├── rate_limiter.py     # Rate limiting functionality
│   └── redis_session.py    # Redis-based session manager
└── mongo/                  # Optional MongoDB components
    ├── __init__.py
    └── session.py          # MongoDB session manager
```

## Installation

Use the provided installation script:

```bash
# Install basic components (no dependencies)
./scripts/install_session_components.sh

# Install with Redis support
./scripts/install_session_components.sh --redis

# Install with MongoDB support
./scripts/install_session_components.sh --mongo

# Install all components and dependencies
./scripts/install_session_components.sh --all
```

## Usage

The system provides a unified interface through the `SessionAdapter` class:

```python
from linkers.session_adapter import get_session_adapter

# Initialize a session manager (memory, file, redis, or mongo)
session_manager = get_session_adapter("memory", {
    "session_expiry_minutes": 30,
    "privacy_mode": True
})

# Create a user session
token = session_manager.create_session("user123")

# Validate a session
is_valid, message, user_data = session_manager.validate_session(token)

# Delete a session
session_manager.delete_session(token)
```

For a complete example, see `linkers/session_example.py`.

## Configuration

Each session manager accepts different configuration options:

### Common Options

- `session_expiry_minutes`: Session expiration time in minutes (default: 60)
- `privacy_mode`: Enable privacy features (default: True)

### File Session Manager

- `storage_dir`: Directory to store session files (default: ~/.sessions)
- `encryption_key`: Optional custom encryption key

### Redis Session Manager

- `redis_host`: Redis server hostname (default: localhost)
- `redis_port`: Redis server port (default: 6379)
- `redis_db`: Redis database number (default: 0)
- `redis_password`: Redis password (optional)

### MongoDB Session Manager

- `connection_string`: MongoDB connection string (default: mongodb://localhost:27017/)
- `db_name`: MongoDB database name (default: session_db)
- `collection_name`: MongoDB collection name (default: sessions)

## Privacy Features

All session managers implement the following privacy features:

1. **Automatic Expiration**: Sessions automatically expire after a configurable time
2. **Minimal Data Storage**: Only essential information is stored
3. **Encryption**: Sensitive data is encrypted at rest
4. **Data Isolation**: Each user's data is isolated
5. **Easy Deletion**: Simple methods to delete individual sessions or all data

## Examples

See `linkers/session_example.py` for a complete example of how to use the session management system.

## License

This software is part of the dotfiles repository and is available under the same license.
