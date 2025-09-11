#!/usr/bin/env python3
"""
File-Based Session Manager

Simple session management using local files instead of a database.
Provides TTL-based expiration with automatic file cleanup.
"""

import datetime
import glob
import hashlib
import json
import os
import threading
import time
import uuid
from typing import Any, Dict, Optional, Tuple


class FileSessionManager:
    """
    Privacy-first token manager with file system storage.

    Stores only the minimal information needed for session validation
    with automatic expiration. No logs or tracking data are stored.
    """

    def __init__(
        self,
        storage_dir: str = "./sessions",
        session_expiry_minutes: int = 60,
        privacy_mode: bool = True,
        cleanup_interval: int = 5
    ):
        """
        Initialize the file-based session manager.

        Args:
            storage_dir: Directory to store session files
            session_expiry_minutes: Minutes until a token expires
            privacy_mode: When True (default), store absolute minimum data
            cleanup_interval: Minutes between cleanup runs
        """
        self.storage_dir = storage_dir
        self.expiry_minutes = session_expiry_minutes
        self.privacy_mode = privacy_mode
        self.cleanup_interval = cleanup_interval

        # Create storage directory if it doesn't exist
        os.makedirs(self.storage_dir, exist_ok=True)

        # Create index directory for user lookups
        self.index_dir = os.path.join(self.storage_dir, "index")
        os.makedirs(self.index_dir, exist_ok=True)

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
                time.sleep(self.cleanup_interval * 60)

        # Start daemon thread
        cleanup_thread = threading.Thread(target=cleanup_worker, daemon=True)
        cleanup_thread.start()

    def _cleanup_expired_sessions(self):
        """Remove expired session files."""
        now = datetime.datetime.utcnow()
        count = 0

        # Clean up session files
        for session_file in glob.glob(os.path.join(self.storage_dir, "*.json")):
            try:
                with open(session_file, 'r') as f:
                    session_data = json.load(f)

                # Parse expiry time
                expires_at = datetime.datetime.fromisoformat(
                    session_data.get("expires_at", "2000-01-01T00:00:00")
                )

                if expires_at < now:
                    # Remove expired session file
                    os.remove(session_file)

                    # Remove index file if it exists
                    user_id = session_data.get("user_id")
                    if user_id:
                        index_file = os.path.join(
                            self.index_dir, f"{user_id}.txt"
                        )
                        if os.path.exists(index_file):
                            os.remove(index_file)

                    count += 1
            except Exception:
                # Skip files with errors
                continue

        if count > 0:
            print(f"Cleaned up {count} expired sessions")

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
        index_file = os.path.join(self.index_dir, f"{user_id}.txt")

        if os.path.exists(index_file):
            try:
                with open(index_file, 'r') as f:
                    existing_token = f.read().strip()

                # Check if token file exists and is not expired
                token_file = os.path.join(
                    self.storage_dir, f"{existing_token}.json"
                )

                if os.path.exists(token_file):
                    with open(token_file, 'r') as f:
                        session_data = json.load(f)

                    # Parse expiry time
                    expires_at = datetime.datetime.fromisoformat(
                        session_data.get("expires_at", "2000-01-01T00:00:00")
                    )

                    if expires_at > datetime.datetime.utcnow():
                        return (
                            False,
                            "User already has an active session",
                            session_data
                        )
                    else:
                        # Clean up expired session
                        os.remove(token_file)
                        os.remove(index_file)
            except Exception:
                # If any error occurs, proceed with creating a new session
                pass

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

        # Save session to file
        token_file = os.path.join(self.storage_dir, f"{token}.json")
        with open(token_file, 'w') as f:
            json.dump(session_data, f)

        # Create index for user lookup
        with open(index_file, 'w') as f:
            f.write(token)

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
        token_file = os.path.join(self.storage_dir, f"{token}.json")

        if not os.path.exists(token_file):
            return False, "Invalid or expired token", None

        try:
            with open(token_file, 'r') as f:
                session_data = json.load(f)

            # Parse expiry time
            expires_at = datetime.datetime.fromisoformat(
                session_data.get("expires_at", "2000-01-01T00:00:00")
            )

            # Check if token is expired
            if expires_at < datetime.datetime.utcnow():
                # Clean up expired session
                os.remove(token_file)

                # Remove index file if it exists
                user_id = session_data.get("user_id")
                if user_id:
                    index_file = os.path.join(
                        self.index_dir, f"{user_id}.txt"
                    )
                    if os.path.exists(index_file):
                        os.remove(index_file)

                return False, "Token has expired", None

            return True, "Token is valid", session_data
        except Exception as e:
            return False, f"Error validating token: {e}", None

    def delete_session(self, token: str) -> bool:
        """
        Delete a session by token.

        Args:
            token: The session token to delete

        Returns:
            True if successful, False otherwise
        """
        token_file = os.path.join(self.storage_dir, f"{token}.json")

        if not os.path.exists(token_file):
            return False

        try:
            # Read the file to get the user_id
            with open(token_file, 'r') as f:
                session_data = json.load(f)

            # Remove the token file
            os.remove(token_file)

            # Remove index file if it exists
            user_id = session_data.get("user_id")
            if user_id:
                index_file = os.path.join(self.index_dir, f"{user_id}.txt")
                if os.path.exists(index_file):
                    os.remove(index_file)

            return True
        except Exception:
            return False

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
    session_mgr = FileSessionManager(
        storage_dir="./sessions",
        session_expiry_minutes=60
    )

    success, msg, session = session_mgr.create_session("test_user")
    if success:
        print(f"Session created: {session['token']}")

        # Validate the token
        is_valid, msg, data = session_mgr.validate_session(session['token'])
        print(f"Token valid: {is_valid}, Message: {msg}")

        # Delete the session
        deleted = session_mgr.delete_session(session['token'])
        print(f"Session deleted: {deleted}")
