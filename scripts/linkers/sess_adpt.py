#!/usr/bin/env python3
"""
Session Manager Adapter

This module provides a consistent interface to different session manager implementations.
It allows using any of the session managers (Redis, File, Memory, MongoDB) with the same API.
"""

import os
from typing import Any, Dict, Optional, Tuple

# Try to import base session manager
try:
    from locally.base_session import BaseSessionManager
    BASE_SESSION_AVAILABLE = True
except ImportError:
    BASE_SESSION_AVAILABLE = False

# Try to import session managers with fallbacks
SESSION_MANAGERS = {}

try:
    from locally.redis_session import SessionManager as RedisSessionManager
    SESSION_MANAGERS["redis"] = RedisSessionManager
except ImportError:
    pass

try:
    from locally.file_session import FileSessionManager
    SESSION_MANAGERS["file"] = FileSessionManager
except ImportError:
    pass

try:
    from locally.memory_session import MemorySessionManager
    SESSION_MANAGERS["memory"] = MemorySessionManager
except ImportError:
    pass

try:
    from mongo.session import SessionManager as MongoSessionManager
    SESSION_MANAGERS["mongo"] = MongoSessionManager
except ImportError:
    pass


class SessionAdapter:
    """
    Adapter for session management systems.

    This class provides a consistent interface to different session manager
    implementations, allowing applications to switch between them without
    changing their code.
    """

    def __init__(
        self,
        manager_type: str = "memory",
        config: Optional[Dict[str, Any]] = None
    ):
        """
        Initialize the session adapter.

        Args:
            manager_type: Type of session manager to use
                          ("redis", "file", "memory", "mongo")
            config: Configuration options for the session manager
        """
        self.manager_type = manager_type.lower()
        self.config = config or {}
        self.session_manager = None

        # Initialize the appropriate session manager
        self._initialize_manager()

    def _initialize_manager(self):
        """Initialize the selected session manager."""
        if self.manager_type not in SESSION_MANAGERS:
            available = ", ".join(SESSION_MANAGERS.keys())
            raise ValueError(
                f"Unknown session manager type: {self.manager_type}. "
                f"Available types: {available}"
            )

        # Create instance of the selected manager
        manager_class = SESSION_MANAGERS[self.manager_type]

        if self.manager_type == "redis":
            self.session_manager = manager_class(
                host=self.config.get("redis_host", "localhost"),
                port=self.config.get("redis_port", 6379),
                db=self.config.get("redis_db", 0),
                password=self.config.get("redis_password"),
                session_expiry_minutes=self.config.get("session_expiry_minutes", 60),
                privacy_mode=self.config.get("privacy_mode", True)
            )
        elif self.manager_type == "file":
            self.session_manager = manager_class(
                storage_dir=self.config.get("storage_dir", "./sessions"),
                session_expiry_minutes=self.config.get("session_expiry_minutes", 60),
                privacy_mode=self.config.get("privacy_mode", True),
                cleanup_interval=self.config.get("cleanup_interval_minutes", 5)
            )
        elif self.manager_type == "memory":
            self.session_manager = manager_class(
                session_expiry_minutes=self.config.get("session_expiry_minutes", 60),
                cleanup_interval_seconds=self.config.get("cleanup_interval_seconds", 60)
            )
        elif self.manager_type == "mongo":
            self.session_manager = manager_class(
                connection_string=self.config.get("connection_string", "mongodb://localhost:27017/"),
                db_name=self.config.get("db_name"),
                session_expiry_minutes=self.config.get("session_expiry_minutes", 60),
                privacy_mode=self.config.get("privacy_mode", True)
            )

    def create_session(self, user_id: str) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Create a new session for the user.

        Args:
            user_id: Unique identifier for the user

        Returns:
            Tuple of (success, message, session_data)
        """
        if not self.session_manager:
            return False, "Session manager not initialized", {}

        return self.session_manager.create_session(user_id)

    def validate_session(
        self, token: str
    ) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
        """
        Validate a session token.

        Args:
            token: The session token to validate

        Returns:
            Tuple of (is_valid, message, session_data)
        """
        if not self.session_manager:
            return False, "Session manager not initialized", None

        return self.session_manager.validate_session(token)

    def delete_session(self, token: str) -> bool:
        """
        Delete a session.

        Args:
            token: The session token to delete

        Returns:
            True if successful, False otherwise
        """
        if not self.session_manager:
            return False

        return self.session_manager.delete_session(token)

    def get_available_managers(self) -> list:
        """
        Get list of available session manager types.

        Returns:
            List of available manager types
        """
        return list(SESSION_MANAGERS.keys())


def get_session_adapter(
    manager_type: Optional[str] = None,
    config_file: Optional[str] = None
) -> SessionAdapter:
    """
    Factory function to create a session adapter.

    This function checks environment variables and config files to determine
    which session manager to use, falling back to defaults if not specified.

    Args:
        manager_type: Type of session manager to use (overrides other settings)
        config_file: Path to a JSON configuration file

    Returns:
        Configured SessionAdapter instance
    """
    config = {}

    # Load configuration from file if provided
    if config_file and os.path.exists(config_file):
        import json
        with open(config_file, 'r') as f:
            config = json.load(f)

    # Check environment variables
    env_manager = os.environ.get("SESSION_MANAGER_TYPE")
    if env_manager and not manager_type:
        manager_type = env_manager

    # Use configuration manager type if not explicitly provided
    if not manager_type and "manager_type" in config:
        manager_type = config["manager_type"]

    # Default to memory if available, or first available manager
    if not manager_type:
        if "memory" in SESSION_MANAGERS:
            manager_type = "memory"
        elif SESSION_MANAGERS:
            manager_type = next(iter(SESSION_MANAGERS.keys()))
        else:
            raise ValueError("No session managers available")

    return SessionAdapter(manager_type, config)


if __name__ == "__main__":
    # Example usage
    try:
        # Create a session adapter using environment variables or defaults
        adapter = get_session_adapter()

        print(f"Using session manager: {adapter.manager_type}")
        print(f"Available managers: {adapter.get_available_managers()}")

        # Create a session
        success, message, session = adapter.create_session("test_user")
        if success:
            token = session["token"]
            print(f"Created session with token: {token[:8]}...")

            # Validate the session
            is_valid, msg, _ = adapter.validate_session(token)
            print(f"Session valid: {is_valid}, Message: {msg}")

            # Delete the session
            deleted = adapter.delete_session(token)
            print(f"Session deleted: {deleted}")
        else:
            print(f"Failed to create session: {message}")

    except Exception as e:
        print(f"Error: {e}")
