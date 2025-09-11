#!/usr/bin/env python3
"""
In-Memory Session Manager

Simple session management that keeps everything in memory.
Maximum privacy with no persistence - sessions are lost on restart.
"""

import datetime
import hashlib
import os
import threading
import time
import uuid
from typing import Any, Dict, Optional, Tuple


class MemorySessionManager:
    """
    Privacy-first token manager with in-memory storage only.

    All data is kept in memory with no persistence to disk.
    When the process restarts, all sessions are lost - maximum privacy.
    """

    def __init__(
        self,
        session_expiry_minutes: int = 60,
        cleanup_interval_seconds: int = 60
    ):
        """
        Initialize the in-memory session manager.

        Args:
            session_expiry_minutes: Minutes until a token expires
            cleanup_interval_seconds: Seconds between cleanup runs
        """
        self.sessions = {}  # token -> session_data
        self.user_tokens = {}  # user_id -> token
        self.expiry_minutes = session_expiry_minutes
        self.cleanup_interval = cleanup_interval_seconds

        # Start cleanup thread
        self._start_cleanup_thread()

    def _start_cleanup_thread(self):
        """Start background thread to clean up expired sessions."""
        def cleanup_worker():
            while True:
                try:
                    self._cleanup_expired_sessions()
                except Exception as e:
                    print(f"Error in cleanup thread: {e}")

                # Sleep for the specified interval
                time.sleep(self.cleanup_interval)

        # Start daemon thread
        cleanup_thread = threading.Thread(target=cleanup_worker, daemon=True)
        cleanup_thread.start()

    def _cleanup_expired_sessions(self):
        """Remove expired sessions from memory."""
        now = datetime.datetime.utcnow()
        expired_tokens = []
        expired_users = []

        # Find expired sessions
        for token, session_data in self.sessions.items():
            expires_at = session_data.get("expires_at")
            if expires_at and expires_at < now:
                expired_tokens.append(token)
                user_id = session_data.get("user_id")
                if user_id:
                    expired_users.append(user_id)

        # Remove expired sessions
        for token in expired_tokens:
            del self.sessions[token]

        # Remove expired user references
        for user_id in expired_users:
            if user_id in self.user_tokens:
                del self.user_tokens[user_id]

    def create_session(self, user_id: str) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Create a new token with expiration.

        This method only stores the minimum data needed for token expiration.

        Args:
            user_id: A unique identifier (can be anonymized)

        Returns:
            Tuple of (success, message, token_data)
        """
        # Check if user already has an active session
        if user_id in self.user_tokens:
            existing_token = self.user_tokens[user_id]
            if existing_token in self.sessions:
                session_data = self.sessions[existing_token]
                expires_at = session_data.get("expires_at")

                if expires_at and expires_at > datetime.datetime.utcnow():
                    return (
                        False,
                        "User already has an active session",
                        session_data
                    )
                else:
                    # Clean up expired session
                    del self.sessions[existing_token]
                    del self.user_tokens[user_id]

        # Create a secure session token
        token = self._generate_secure_token(user_id)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(
            minutes=self.expiry_minutes
        )

        # Create minimal session data
        session_data = {
            "token": token,
            "user_id": user_id,
            "expires_at": expires_at
        }

        # Store in memory
        self.sessions[token] = session_data
        self.user_tokens[user_id] = token

        return True, "Session created", session_data

    def validate_session(
        self, token: str
    ) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
        """
        Validate a token and return session data if valid.

        Args:
            token: The session token to validate

        Returns:
            Tuple of (is_valid, message, session_data)
        """
        if token not in self.sessions:
            return False, "Invalid or expired token", None

        session_data = self.sessions[token]
        expires_at = session_data.get("expires_at")

        # Check if token is expired
        if expires_at and expires_at < datetime.datetime.utcnow():
            # Clean up expired session
            user_id = session_data.get("user_id")
            del self.sessions[token]
            if user_id and user_id in self.user_tokens:
                del self.user_tokens[user_id]

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
        if token not in self.sessions:
            return False

        session_data = self.sessions[token]
        user_id = session_data.get("user_id")

        # Remove from sessions
        del self.sessions[token]

        # Remove from user tokens
        if user_id and user_id in self.user_tokens:
            del self.user_tokens[user_id]

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
    session_mgr = MemorySessionManager(session_expiry_minutes=60)

    success, msg, session = session_mgr.create_session("test_user")
    if success:
        print(f"Session created: {session['token']}")

        # Validate the token
        is_valid, msg, data = session_mgr.validate_session(session['token'])
        print(f"Token valid: {is_valid}, Message: {msg}")

        # Delete the session
        deleted = session_mgr.delete_session(session['token'])
        print(f"Session deleted: {deleted}")

        print("Note: All sessions are lost when the process restarts.")
