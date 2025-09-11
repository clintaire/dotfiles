# MongoDB Session Manager

Simple session management for mini applications using MongoDB.

## Files

- `session.py` - Core session management module
- `mini.py` - Example mini application
- `test.py` - Test script for session manager
- `start.sh` - Script to start MongoDB with Docker
- `docker-compose.yml` - Docker configuration

## Setup

Install dependencies:

```bash
pip install pymongo dnspython
```

Start MongoDB:

```bash
./start.sh
```

Run test script:

```bash
python test.py
```

Run mini app:

```bash
python mini.py
```

## Usage

```python
from session import SessionManager

# Create session manager
db = SessionManager()

# Create user session
success, msg, session = db.create_session("user@example.com")

# Validate session
valid, msg, session = db.validate_session(session["token"])

# End session
db.end_session(session["token"])
```

## MongoDB Connection

Default: `mongodb://localhost:27017/`

Set custom connection:

```bash
export MONGODB_URI="mongodb://user:pass@host:port/"
```

## Security Notes

- Store connection strings as environment variables
- Always validate sessions before operations
- Sessions expire automatically after 30 minutes
- One active session per user

## Troubleshooting

- Connection Issues: Ensure MongoDB is running and accessible
- pymongo Not Found: Install required packages with pip
- Sessions Not Expiring: Check server time synchronization

## Example Deployment with MongoDB Atlas

1. Create a MongoDB Atlas account
2. Set up a free tier cluster
3. Create a database user
4. Add your IP to the IP Access List
5. Get your connection string
6. Set as environment variable: export MONGODB_URI="your_connection_string"
7. Run your app

## Architecture

The session management system consists of three main components:

1. SessionManager Class: Handles session CRUD operations
2. MongoDB Database: Stores session information
3. Mini App Integration: Example of using sessions in an application

The SessionManager validates session tokens before each operation and
tracks usage, ensuring users cannot bypass the single-session restriction.

## Performance Considerations

- MongoDB indexes are created automatically for user_id and token fields
- Expired sessions are automatically cleaned up to prevent database bloat
- Session validation adds minimal overhead to each operation
