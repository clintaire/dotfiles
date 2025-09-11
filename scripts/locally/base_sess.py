#!/usr/bin/env python3
"""
Base Session Manager

Abstract base class defining the interface for all session manager implementations.
Ensures consistent behavior across different storage backends.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Tuple


class BaseSessionManager(ABC):
    """
    Abstract base class for all session manager implementations.

    This class defines the common interface that all session managers must implement,
    making it easier to switch between different storage backends while ensuring
    consistent behavior.
    """

    @abstractmethod
    def create_session(self, user_id: str) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Create a new session for the specified user.

        Args:
            user_id: A unique identifier for the user

        Returns:
            Tuple of (success, message, session_data)
        """
        pass

    @abstractmethod
    def validate_session(self, token: str) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
        """
        Validate a session token and return session data if valid.

        Args:
            token: The session token to validate

        Returns:
            Tuple of (is_valid, message, session_data)
        """
        pass

    @abstractmethod
    def delete_session(self, token: str) -> bool:
        """
        Delete a session by its token.

        Args:
            token: The session token to delete

        Returns:
            True if successful, False otherwise
        """
        pass

    @abstractmethod
    def cleanup_expired_sessions(self) -> int:
        """
        Manually clean up expired sessions.

        Returns:
            Number of expired sessions that were cleaned up
        """
        pass
