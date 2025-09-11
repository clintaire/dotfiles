#!/usr/bin/env python3
"""
Redis-Based Session Manager

Lightweight session management using Redis instead of MongoDB.
Provides TTL-based expiration with minimal storage requirements.
"""

import datetime
import hashlib
import json
import os
import uuid
from typing import Any, Dict, Optional, Tuple

try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False


class SessionManager:
    """
    Privacy-first token manager with Redis backend.

    Stores only the minimal information needed for session validation
    with automatic expiration. No logs or tracking data are stored.
    """

    def __init__(
        self,
        host: str = "localhost",
        port: int = 6379,
        db: int = 0,
        password: Optional[str] = None,
        session_expiry_minutes: int = 60,
        privacy_mode: bool = True
    ):
        """
        Initialize the Redis-based session manager.

        Args:
            host: Redis host address
            port: Redis port
            db: Redis database number
            password: Redis password if needed
            session_expiry_minutes: Minutes until a token expires
            privacy_mode: When True (default), store absolute minimum data
        """
        self.expiry_minutes = session_expiry_minutes
        self.privacy_mode = privacy_mode
        self.client = None

        # Load environment values if available
        if os.path.exists('.env'):
            try:
                with open('.env', 'r') as env_file:
                    for line in env_file:
                        if line.strip() and not line.startswith('#'):
                            key, value = line.strip().split('=', 1)
                            if key == 'REDIS_HOST':
                                host = value
                            elif key == 'REDIS_PORT':
                                port = int(value)
                            elif key == 'REDIS_PASSWORD':
                                password = value
            except Exception:
                # Silently continue if .env parsing fails
                pass

        if not REDIS_AVAILABLE:
            print("Warning: redis-py not installed.")
            print("Install with: pip install redis")
            print("Session management disabled.")
            return

        try:
            self.client = redis.Redis(
                host=host,
                port=port,
                db=db,
                password=password,
                decode_responses=True
            )
            # Test connection
            self.client.ping()
        except Exception as e:
            print(f"Error connecting to Redis: {e}")
            self.client = None

    def create_session(self, user_id: str) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Create a new token with expiration.

        This method only stores the minimum data needed for token expiration.

        Args:
            user_id: A unique identifier (can be anonymized)

        Returns:
            Tuple of (success, message, token_data)
        """
        if not self.client:
            return False, "Redis not available", {}

        # Check if user already has an active session
        user_key = f"user:{user_id}"
        existing_token = self.client.get(user_key)

        if existing_token:
            # Check if the token still exists (not expired)
            if self.client.exists(f"token:{existing_token}"):
                session_data = json.loads(self.client.get(f"token:{existing_token}"))
                return False, "User already has an active session", session_data

        # Create a secure session token
        token = self._generate_secure_token(user_id)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(
            minutes=self.expiry_minutes
        )

        # Create minimal session data
        session_data = {
            "token": token,
            "user_id": user_id,
            "expires_at": expires_at.isoformat()
        }

        # Add additional data if not in privacy mode
        if not self.privacy_mode:
            session_data["created_at"] = datetime.datetime.utcnow().isoformat()

        # Store in Redis with expiration
        token_key = f"token:{token}"
        pipe = self.client.pipeline()
        pipe.set(token_key, json.dumps(session_data))
        pipe.expire(token_key, int(self.expiry_minutes * 60))
        pipe.set(user_key, token)
        pipe.expire(user_key, int(self.expiry_minutes * 60))
        pipe.execute()

        return True, "Session created", session_data

    def validate_session(self, token: str) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
        """
        Validate a token and return session data if valid.

        Args:
            token: The session token to validate

        Returns:
            Tuple of (is_valid, message, session_data)
        """
        if not self.client:
            return False, "Redis not available", None

        token_key = f"token:{token}"
        session_json = self.client.get(token_key)

        if not session_json:
            return False, "Invalid or expired token", None

        session_data = json.loads(session_json)

        # Convert expiry time string to datetime
        expires_at = datetime.datetime.fromisoformat(session_data["expires_at"])

        # Check if token is expired
        if expires_at < datetime.datetime.utcnow():
            # Clean up expired token
            user_key = f"user:{session_data['user_id']}"
            self.client.delete(token_key, user_key)
            return False, "Token has expired", None

        return True, "Token is valid", session_data

    def delete_session(self, token: str) -> bool:
        """
        Delete a session by token.

        Args:
            token: The session token to delete

        Returns:
            True if successful, False otherwise
        """
        if not self.client:
            return False

        token_key = f"token:{token}"
        session_json = self.client.get(token_key)

        if not session_json:
            return False

        session_data = json.loads(session_json)
        user_key = f"user:{session_data['user_id']}"

        # Delete both token and user reference
        self.client.delete(token_key, user_key)
        return True

    def _generate_secure_token(self, user_id: str) -> str:
        """
        Generate a secure, unique token.

        Args:
            user_id: User identifier to incorporate into token

        Returns:
            Secure token string
        """
        # Combine unique identifiers
        random_bytes = os.urandom(32)
        unique_id = str(uuid.uuid4())
        timestamp = datetime.datetime.utcnow().isoformat()

        # Create a hash from combined data
        token_base = f"{user_id}:{unique_id}:{timestamp}".encode()
        token_base += random_bytes

        # Generate SHA-256 hash
        token = hashlib.sha256(token_base).hexdigest()
        return token


if __name__ == "__main__":
    # Simple usage example
    if REDIS_AVAILABLE:
        session_mgr = SessionManager(session_expiry_minutes=60)
        success, msg, session = session_mgr.create_session("test_user")
        if success:
            print(f"Session created: {session['token']}")

            # Validate the token
            is_valid, msg, data = session_mgr.validate_session(session['token'])
            print(f"Token valid: {is_valid}, Message: {msg}")

            # Delete the session
            deleted = session_mgr.delete_session(session['token'])
            print(f"Session deleted: {deleted}")
    else:
        print("Redis library not available. Install with: pip install redis")
