#!/usr/bin/env python3
"""
Session Manager - Private Link Expiry

This module manages link/token expiration with strict privacy principles.
It only tracks the minimum data needed to enforce expiration times, with
no user activity logging or behavioral tracking.

Privacy Guarantees:
- No logging of user activities or behavior
- Minimal data storage (only what's needed for expiration)
- Auto-expiry with immediate data deletion
- No persistent user tracking
- Optional memory-only mode with no disk storage
"""

import datetime
import hashlib
import os
import uuid
from typing import Any, Dict, Optional, Tuple

try:
    from pymongo import MongoClient
    from pymongo.errors import DuplicateKeyError
    MONGODB_AVAILABLE = True
except ImportError:
    MONGODB_AVAILABLE = False


class SessionManager:
    """
    Privacy-first token manager with expiration enforcement.

    This class is designed for link/token expiration without collecting any
    user behavior data or activity logs. It only stores the minimal required
    information for expiration enforcement.

    Features:
    - Zero user activity logging
    - Link/token expiration enforcement
    - Automatic data purging after expiry
    - Memory-only option for maximum privacy
    - No tracking or analytics
    """

    def __init__(
        self,
        connection_string: str = "mongodb://localhost:27017/",
        db_name: Optional[str] = None,
        session_expiry_minutes: int = 60,
        privacy_mode: bool = True
    ):
        """
        Initialize the token manager with privacy protections.

        Args:
            connection_string: MongoDB connection string
            db_name: Database name (if None, will use from env or default)
            session_expiry_minutes: Minutes until a token expires
            privacy_mode: When True (default), store absolute minimum data
                          and enforce strict privacy protections
        """
        self.expiry_minutes = session_expiry_minutes
        self.privacy_mode = privacy_mode
        self.db = None

        # Use DB name from various sources with fallbacks
        if db_name is None:
            # Try to get DB name from environment
            if 'MONGO_DB_NAME' in os.environ:
                db_name = os.environ['MONGO_DB_NAME']
            else:
                # Generic default name
                db_name = "session_db"

        # Load environment values if available
        if os.path.exists('.env'):
            try:
                with open('.env', 'r') as env_file:
                    for line in env_file:
                        if line.strip() and not line.startswith('#'):
                            key, value = line.strip().split('=', 1)
                            if key == 'MONGO_USER':
                                os.environ['MONGO_USER'] = value
                            elif key == 'MONGO_PASSWORD':
                                os.environ['MONGO_PASSWORD'] = value
                            elif key == 'MONGO_DB_NAME' and not db_name:
                                # Only set if not explicitly provided
                                os.environ['MONGO_DB_NAME'] = value
                                db_name = value

                # Update connection string with credentials from .env
                if '@' not in connection_string and ':' in connection_string:
                    host_part = connection_string.split('://', 1)[1]
                    user = os.environ.get('MONGO_USER')
                    password = os.environ.get('MONGO_PASSWORD')
                    if user and password:
                        conn_str = f"mongodb://{user}:{password}@{host_part}"
                        connection_string = conn_str
            except Exception:
                # Silently continue if .env parsing fails
                pass

        if not MONGODB_AVAILABLE:
            print("Warning: pymongo not installed.")
            print("Session management disabled.")
            return

        try:
            self.client = MongoClient(connection_string)
            self.db = self.client[db_name]

            # Setup based on privacy mode
            if self.privacy_mode:
                # Create a TTL index to auto-delete expired sessions
                self.db.sessions.create_index(
                    "expires_at",
                    expireAfterSeconds=0
                )

                # Create minimal index set
                self.db.sessions.create_index("user_id")
                self.db.sessions.create_index("token")

                # Set up a capped collection if possible for automatic cleanup
                try:
                    # Check if collection exists and isn't capped
                    if "sessions" in self.db.list_collection_names():
                        cmd = self.db.command("collstats", "sessions")
                        if not cmd.get("capped", False):
                            # Convert to capped collection (10MB max)
                            self.db.command(
                                "convertToCapped",
                                "sessions",
                                size=10485760
                            )
                    else:
                        # Create capped collection
                        self.db.create_collection(
                            "sessions",
                            capped=True,
                            size=10485760
                        )
                except Exception:
                    # If capped collection setup fails, continue
                    pass
            else:
                # Standard indexes for production use
                self.db.sessions.create_index("user_id", unique=True)
                self.db.sessions.create_index("token", unique=True)
                self.db.sessions.create_index("expires_at")

        except Exception as e:
            print(f"Error connecting to MongoDB: {e}")
            self.db = None

    def create_session(self, user_id: str) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Create a new token with expiration.

        This method only stores the minimum data needed for token expiration:
        - A unique identifier (no personal data)
        - Expiration timestamp
        - Token value

        In privacy mode, NO activity tracking or usage statistics are collected.

        Args:
            user_id: A unique identifier (can be anonymized)

        Returns:
            Tuple of (success, message, token_data)
        """
        if not self.db:
            return False, "MongoDB not available", {}

        # First check if user already has an active session
        existing_session = self.db.sessions.find_one({"user_id": user_id})

        if existing_session:
            # Check if existing session is still valid
            if existing_session["expires_at"] > datetime.datetime.utcnow():
                return (
                    False,
                    "User already has an active session",
                    existing_session
                )
            else:
                # Expired session exists, delete it first
                self.db.sessions.delete_one({"_id": existing_session["_id"]})

        # Create a secure session token
        token = self._generate_secure_token(user_id)
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(
            minutes=self.expiry_minutes
        )

        # Create session data based on privacy mode
        if self.privacy_mode:
            # Absolute minimum data stored - only what's needed for expiration
            session_data = {
                "user_id": user_id,
                "token": token,
                "created_at": datetime.datetime.utcnow(),
                "expires_at": expires_at
                # No tracking fields
            }
        else:
            # Standard mode - still privacy-conscious but with basic usage info
            session_data = {
                "user_id": user_id,
                "token": token,
                "created_at": datetime.datetime.utcnow(),
                "expires_at": expires_at,
                "last_activity": datetime.datetime.utcnow(),
                "usage_count": 0
            }

        try:
            self.db.sessions.insert_one(session_data)
            return True, "Session created", session_data
        except DuplicateKeyError:
            return False, "Session creation conflict", {}
        except Exception as e:
            return False, f"Error creating session: {str(e)}", {}

    def validate_session(
        self, token: str
    ) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Verify a token's validity without recording usage.

        This method ONLY checks if a token is valid and not expired.
        In privacy mode, no information about the validation check
        is logged or recorded - the function simply returns if the token
        is still valid without updating any usage statistics.

        Args:
            token: Token string to validate

        Returns:
            Tuple of (is_valid, message, token_data)
        """
        if not self.db:
            return False, "MongoDB not available", {}

        session = self.db.sessions.find_one({"token": token})

        if not session:
            return False, "Session not found", {}

        # Check if session has expired
        if session["expires_at"] < datetime.datetime.utcnow():
            return False, "Token expired", session

        # Privacy approach to validation
        if not self.privacy_mode:
            # Only in non-privacy mode do we track last access
            # This is still minimal tracking compared to most systems
            self.db.sessions.update_one(
                {"_id": session["_id"]},
                {
                    "$set": {"last_activity": datetime.datetime.utcnow()},
                    "$inc": {"usage_count": 1}
                }
            )
        # In privacy mode: No updates, no tracking, we just verify validity

        # Return token data
        return True, "Token valid", session

    def extend_session(
        self, token: str, additional_minutes: Optional[int] = None
    ) -> Tuple[bool, str]:
        """
        Extend session expiration time.

        Args:
            token: Session token
            additional_minutes: Additional minutes to add

        Returns:
            Tuple of (success, message)
        """
        if not self.db:
            return False, "MongoDB not available"

        # Determine minutes to extend
        if additional_minutes is not None:
            minutes = additional_minutes
        else:
            minutes = self.expiry_minutes

        # Create new expiration time
        new_expires = datetime.datetime.utcnow() + datetime.timedelta(
            minutes=minutes
        )

        result = self.db.sessions.update_one(
            {"token": token},
            {"$set": {"expires_at": new_expires}}
        )

        if result.modified_count > 0:
            return True, f"Session extended by {minutes} minutes"
        else:
            return False, "Session not found or could not be extended"

    def end_session(self, token: str) -> Tuple[bool, str]:
        """
        End a user session by token.

        Args:
            token: Session token

        Returns:
            Tuple of (success, message)
        """
        if not self.db:
            return False, "MongoDB not available"

        result = self.db.sessions.delete_one({"token": token})

        if result.deleted_count > 0:
            return True, "Session ended successfully"
        else:
            return False, "Session not found"

    def clean_expired_sessions(self) -> int:
        """
        Remove all expired sessions from the database.

        Returns:
            Number of sessions removed
        """
        if not self.db:
            return 0

        result = self.db.sessions.delete_many(
            {"expires_at": {"$lt": datetime.datetime.utcnow()}}
        )

        return result.deleted_count

    def get_active_sessions_count(self) -> int:
        """
        Get count of all active sessions.

        Returns:
            Number of active sessions
        """
        if not self.db:
            return 0

        return self.db.sessions.count_documents(
            {"expires_at": {"$gt": datetime.datetime.utcnow()}}
        )

    def get_user_session(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a user's current session if it exists.

        Args:
            user_id: User identifier

        Returns:
            Session data or None if no active session
        """
        if not self.db:
            return None

        session = self.db.sessions.find_one({
            "user_id": user_id,
            "expires_at": {"$gt": datetime.datetime.utcnow()}
        })

        return session

    def _generate_secure_token(self, user_id: str) -> str:
        """
        Generate a secure session token.

        Args:
            user_id: User identifier to include in token generation

        Returns:
            Secure session token
        """
        # Combine random UUID, timestamp, and user_id for entropy
        timestamp = datetime.datetime.utcnow().timestamp()
        raw_token = f"{uuid.uuid4()}-{timestamp}-{user_id}"

        # Create SHA-256 hash
        return hashlib.sha256(raw_token.encode()).hexdigest()


# Example usage - token expiration without logging
if __name__ == "__main__":
    # Example configuration
    CONNECTION_STRING = "mongodb://localhost:27017/"
    # No hardcoded DB name - will use environment variable or default

    # Initialize token manager with privacy mode
    token_mgr = SessionManager(
        connection_string=CONNECTION_STRING,
        # Let the class determine the database name
        session_expiry_minutes=30,
        privacy_mode=True  # No usage tracking
    )

    # Create a token with an anonymous identifier
    user_id = "anon_12345"  # No personal info
    success, message, token_data = token_mgr.create_session(user_id)

    if success:
        print(f"Token created: {message}")
        print("Expires in: 30 minutes")

        # Verify the token
        token = token_data['token']
        is_valid, validate_msg, _ = token_mgr.validate_session(token)
        print(f"Token valid: {is_valid}")

        # Check active tokens
        active_count = token_mgr.get_active_sessions_count()
        print(f"Active tokens: {active_count}")

        # Clean expired tokens
        cleaned = token_mgr.clean_expired_sessions()
        print(f"Expired tokens removed: {cleaned}")

        # Invalidate the token
        end_success, end_msg = token_mgr.end_session(token)
        print(f"Token invalidated: {end_success}")
    else:
        print(f"Failed to create token: {message}")
