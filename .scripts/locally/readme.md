# Local Session Management

Simple, lightweight session management alternatives without MongoDB.

## Why Local Over MongoDB?

1. **Simplicity**: These local solutions are much simpler to set up and maintain compared to MongoDB, requiring less resources and configuration.

2. **True Privacy**: MongoDB is a third-party solution that requires additional privacy controls. These local alternatives were built with privacy as the core design principle, not as an afterthought.

3. **Lighter Weight**: MongoDB can be overkill for simple session management. These alternatives use minimal resources while providing the same core functionality.

4. **Docker Integration**: All solutions run in lightweight Docker containers, making them portable and isolated.

5. **No Third-Party Dependencies**: Especially with the file-based and memory-only options, there's no reliance on external database technologies.

6. **Beta-Friendly**: Perfect for beta projects where you need something that works without the overhead of a full database system.

## Overview

This directory contains three different implementations of privacy-focused session management:

1. **Redis-based** (`redis-session.py`): Uses Redis for storage with automatic expiration
2. **File-based** (`file-session.py`): Uses the local filesystem with automatic cleanup
3. **Memory-only** (`memory-session.py`): Keeps everything in memory with no persistence

All implementations follow strict privacy principles:

- Minimal data storage (only what's needed for expiration)
- No logging of user activities or behavior
- Automatic data cleanup
- Privacy-mode enabled by default

## Usage

### Starting the Environment

```bash
# Make the start script executable
chmod +x start.sh

# Run the start script
./start.sh
```

This will start Docker containers for Redis and a Python environment.

### Using the Session Managers

Once the environment is running, you can use any of the session managers:

```bash
# Test Redis session manager
docker-compose exec session-runner python redis-session.py

# Test File-based session manager
docker-compose exec session-runner python file-session.py

# Test Memory-only session manager
docker-compose exec session-runner python memory-session.py
```

Or run the test script to test all implementations:

```bash
docker-compose exec session-runner python test.py
```

## Implementation Details

### Redis Session Manager

- Uses Redis key expiration for automatic cleanup
- Stores minimal data with strict TTL (Time To Live)
- Redis configured for memory-only operation with size limits

### File Session Manager

- Stores session data in simple JSON files
- Background thread for cleaning up expired sessions
- Index directory for quick user lookup

### Memory Session Manager

- Keeps all data in memory only
- No persistence - all sessions are lost on restart (maximum privacy)
- Background thread for cleaning up expired sessions

## Cleaning Up

To remove all containers and data:

```bash
docker-compose down -v
```

This will delete all containers and volumes, ensuring no data is left behind.

## MongoDB vs. Local Alternatives Comparison

| Feature          | MongoDB                                      | Local Alternatives                           |
| ---------------- | -------------------------------------------- | -------------------------------------------- |
| **Privacy**      | Requires explicit configuration for privacy  | Built with privacy-first approach            |
| **Complexity**   | Complex setup, indexes, users, etc.          | Simple, single-purpose solutions             |
| **Resources**    | Higher memory, CPU and disk usage            | Minimal resource requirements                |
| **Scalability**  | Better for large-scale applications          | Perfect for small/beta applications          |
| **Dependencies** | Requires MongoDB server                      | File/memory options have zero dependencies   |
| **Security**     | More attack surface                          | Smaller footprint means less vulnerabilities |
| **Maintenance**  | Regular updates, backups, monitoring         | Minimal maintenance required                 |
| **Cost**         | Higher hosting costs for dedicated instances | Virtually no additional cost                 |

## MongoDB Implementation

If you prefer to use MongoDB despite the advantages of local alternatives, you can find a complete MongoDB-based session management implementation in the `../mongo` directory. The MongoDB version includes:

- Privacy-focused session manager with MongoDB backend
- Docker Compose setup for MongoDB
- Automatic session expiration with TTL indexes
- Privacy mode options

To use the MongoDB implementation:

```bash
cd ../mongo
./start.sh
```

The MongoDB implementation provides similar functionality but with the trade-offs described in the comparison table above.

## Advanced Components

The following additional components have been added to enhance the session management system:

### Base Session Manager

A common interface (`base_session.py`) that all session managers implement, ensuring consistent behavior across different storage backends:

```python
# Example usage
from base_session import BaseSessionManager
from redis_session import RedisSessionManager

# Any session manager can be used with the same interface
session_mgr: BaseSessionManager = RedisSessionManager()
success, message, session = session_mgr.create_session("user123")
```

### Configuration Manager

A flexible configuration system (`config_manager.py`) that handles loading settings from multiple sources:

```python
# Example usage
from config_manager import ConfigManager

# Load configuration from environment variables and files
config = ConfigManager(config_file="config.json")

# Access configuration values
redis_host = config.get("redis_host")
session_expiry = config.get("session_expiry_minutes")
```

### Rate Limiter

Protection against brute force attacks (`rate_limiter.py`):

```python
# Example usage
from rate_limiter import RateLimiter

# Create a rate limiter (5 attempts per 15 minutes)
limiter = RateLimiter(max_attempts=5, window_seconds=900)

# Check if user is rate limited
user_id = "user123"
allowed, remaining, retry_after = limiter.check_rate_limit(user_id)

if allowed:
    # Process the request
    limiter.add_attempt(user_id)  # Record this attempt
else:
    # Return rate limit error
    print(f"Rate limited. Try again in {retry_after} seconds")
```

These components work together to provide a more robust, secure, and maintainable session management system while maintaining the privacy-first approach.
