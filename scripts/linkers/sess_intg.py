#!/usr/bin/env python3
"""
Convert Integration With Session Management

This module integrates the Convert.py script with our custom session managers,
allowing it to use any of our session management implementations.
"""

import os
import sys
from typing import Any, Dict, Optional, Tuple

# Make the parent directory available for imports
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

# Try to import the session adapter
try:
    from linkers.sess_adpt import get_adapter
    ADAPTER_AVAILABLE = True
except ImportError:
    try:
        from sess_adpt import get_adapter
        ADAPTER_AVAILABLE = True
    except ImportError:
        ADAPTER_AVAILABLE = False

# Try to import the session manager
try:
    from locally.memory_session import MemorySessionManager
    LOCAL_MEMORY_AVAILABLE = True
except ImportError:
    LOCAL_MEMORY_AVAILABLE = False

try:
    from locally.file_session import FileSessionManager
    LOCAL_FILE_AVAILABLE = True
except ImportError:
    LOCAL_FILE_AVAILABLE = False

try:
    from locally.redis_session import SessionManager as RedisSessionManager
    LOCAL_REDIS_AVAILABLE = True
except ImportError:
    LOCAL_REDIS_AVAILABLE = False

try:
    from mongo.session import SessionManager as MongoSessionManager
    MONGO_AVAILABLE = True
except ImportError:
    MONGO_AVAILABLE = False

# Fallback to memory session manager if nothing else is available
DEFAULT_SESSION_MANAGER = None
if LOCAL_MEMORY_AVAILABLE:
    DEFAULT_SESSION_MANAGER = MemorySessionManager(session_expiry_minutes=30)
elif LOCAL_FILE_AVAILABLE:
    DEFAULT_SESSION_MANAGER = FileSessionManager(
        storage_dir=os.path.join(parent_dir, "sessions"),
        session_expiry_minutes=30
    )
elif LOCAL_REDIS_AVAILABLE:
    DEFAULT_SESSION_MANAGER = RedisSessionManager(
        session_expiry_minutes=30,
        privacy_mode=True
    )
elif MONGO_AVAILABLE:
    DEFAULT_SESSION_MANAGER = MongoSessionManager(
        session_expiry_minutes=30,
        privacy_mode=True
    )


def init_sess_mgr(
    mgr_type: Optional[str] = None,
    config: Optional[Dict[str, Any]] = None
):
    """
    Initialize a session manager.

    Args:
        mgr_type: Type of session manager to use
        config: Configuration options

    Returns:
        Session manager instance
    """
    if ADAPTER_AVAILABLE:
        # Use the adapter if available
        return get_adapter(mgr_type, config)

    # Fall back to direct imports
    config = config or {}
    mgr_type = mgr_type or os.environ.get("SESSION_MANAGER_TYPE")

    if mgr_type == "memory" and LOCAL_MEMORY_AVAILABLE:
        return MemorySessionManager(
            session_expiry_minutes=config.get("session_expiry_minutes", 30)
        )
    elif mgr_type == "file" and LOCAL_FILE_AVAILABLE:
        return FileSessionManager(
            storage_dir=config.get("storage_dir", os.path.join(parent_dir, "sessions")),
            session_expiry_minutes=config.get("session_expiry_minutes", 30)
        )
    elif mgr_type == "redis" and LOCAL_REDIS_AVAILABLE:
        return RedisSessionManager(
            host=config.get("redis_host", "localhost"),
            port=config.get("redis_port", 6379),
            session_expiry_minutes=config.get("session_expiry_minutes", 30),
            privacy_mode=config.get("privacy_mode", True)
        )
    elif mgr_type == "mongo" and MONGO_AVAILABLE:
        return MongoSessionManager(
            connection_string=config.get("connection_string", "mongodb://localhost:27017/"),
            db_name=config.get("db_name"),
            session_expiry_minutes=config.get("session_expiry_minutes", 30),
            privacy_mode=config.get("privacy_mode", True)
        )

    # Return default session manager
    return DEFAULT_SESSION_MANAGER


def check_user(manager, user_id: str) -> Optional[Dict[str, Any]]:
    """
    Check if a user has an active session.

    Args:
        manager: Session manager instance
        user_id: User identifier

    Returns:
        Session data if active, None otherwise
    """
    if not manager:
        return None

    # Try different ways to check session
    if hasattr(manager, "get_user_session"):
        # Some managers might have this method
        return manager.get_user_session(user_id)

    # Standard approach - create a temporary token
    success, _, session = manager.create_session(user_id)

    if not success and "already has an active session" in _:
        # User has an active session, let's find it
        if hasattr(manager, "db") and hasattr(manager.db, "sessions"):
            # MongoDB-style session manager
            import datetime
            return manager.db.sessions.find_one({
                "user_id": user_id,
                "expires_at": {"$gt": datetime.datetime.utcnow()}
            })

    return None


def create_user(
    manager, user_id: str, expiry_minutes: int = 30
) -> Tuple[bool, str, Dict[str, Any]]:
    """
    Create a new session for a user.

    Args:
        manager: Session manager instance
        user_id: User identifier
        expiry_minutes: Minutes until session expires

    Returns:
        Tuple of (success, message, session_data)
    """
    if not manager:
        return False, "Session manager not available", {}

    # Set expiry if the manager supports it
    if hasattr(manager, "expiry_minutes"):
        original_expiry = manager.expiry_minutes
        manager.expiry_minutes = expiry_minutes

    # Create the session
    result = manager.create_session(user_id)

    # Restore original expiry
    if hasattr(manager, "expiry_minutes"):
        manager.expiry_minutes = original_expiry

    return result


# Example usage
if __name__ == "__main__":
    # Initialize session manager
    manager = init_sess_mgr()

    if manager:
        print(f"Using session manager: {type(manager).__name__}")

        # Create a session
        success, message, session = create_user(manager, "test_user")
        if success:
            print(f"Created session: {session.get('token', '')[:8]}...")

            # Check if user has an active session
            user_session = check_user(manager, "test_user")
            if user_session:
                print("User has an active session")
            else:
                print("User does not have an active session")

            # Validate and delete the session
            if hasattr(manager, "validate_session") and hasattr(manager, "delete_session"):
                token = session.get("token", "")
                is_valid, _, _ = manager.validate_session(token)
                print(f"Session valid: {is_valid}")

                deleted = manager.delete_session(token)
                print(f"Session deleted: {deleted}")
        else:
            print(f"Failed to create session: {message}")
    else:
        print("No session manager available")

# Backwards compatibility aliases
initialize_session_manager = init_sess_mgr
create_user_session = create_user
check_user_session = check_user

