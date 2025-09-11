#!/usr/bin/env python3
"""
Rate Limiter

Provides rate limiting functionality for session management to protect
against brute force attacks and abuse.
"""

import time
from collections import defaultdict
from typing import Dict, Tuple


class RateLimiter:
    """
    Simple rate limiter to prevent brute force attacks.

    Keeps track of attempts per user/IP and blocks if too many attempts
    occur within a specified time window.
    """

    def __init__(self, max_attempts: int = 5, window_seconds: int = 900):
        """
        Initialize the rate limiter.

        Args:
            max_attempts: Maximum number of attempts allowed in window
            window_seconds: Time window in seconds
        """
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds
        self.attempts: Dict[str, list] = defaultdict(list)

    def check_rate_limit(self, key: str) -> Tuple[bool, int, int]:
        """
        Check if a key (user ID or IP) is rate limited.

        Args:
            key: Identifier to check (user ID, IP, etc.)

        Returns:
            Tuple of (is_allowed, attempts_remaining, retry_after_seconds)
        """
        now = time.time()
        key_attempts = self.attempts[key]

        # Remove attempts outside the current window
        self.attempts[key] = [
            timestamp for timestamp in key_attempts
            if now - timestamp < self.window_seconds
        ]

        # Count recent attempts
        recent_attempts = len(self.attempts[key])

        if recent_attempts >= self.max_attempts:
            # Calculate when the oldest attempt will expire
            oldest_timestamp = min(self.attempts[key]) if self.attempts[key] else now
            retry_after = int(oldest_timestamp + self.window_seconds - now)
            return False, 0, max(1, retry_after)

        # Not rate limited
        return True, self.max_attempts - recent_attempts, 0

    def add_attempt(self, key: str):
        """
        Record an attempt for the specified key.

        Args:
            key: Identifier to record attempt for
        """
        now = time.time()
        self.attempts[key].append(now)

    def reset(self, key: str):
        """
        Reset attempts for a specific key.

        Args:
            key: Identifier to reset
        """
        if key in self.attempts:
            del self.attempts[key]

    def cleanup(self):
        """Remove expired entries to prevent memory growth."""
        now = time.time()
        cutoff = now - self.window_seconds

        # For each key, remove old attempts
        for key in list(self.attempts.keys()):
            self.attempts[key] = [
                timestamp for timestamp in self.attempts[key]
                if timestamp > cutoff
            ]

            # Remove empty entries
            if not self.attempts[key]:
                del self.attempts[key]


if __name__ == "__main__":
    # Simple usage example
    limiter = RateLimiter(max_attempts=3, window_seconds=10)

    test_key = "test_user"

    for i in range(5):
        allowed, remaining, retry_after = limiter.check_rate_limit(test_key)
        status = "ALLOWED" if allowed else "BLOCKED"

        print(f"Attempt {i+1}: {status}, Remaining: {remaining}")

        if allowed:
            limiter.add_attempt(test_key)
        else:
            print(f"  Retry after: {retry_after} seconds")

        # Small delay between attempts
        time.sleep(1)

    # Wait for rate limit to reset
    print("\nWaiting for rate limit window to expire...")
    time.sleep(10)

    # Try again after window expiry
    allowed, remaining, _ = limiter.check_rate_limit(test_key)
    print(f"After window expiry: {'ALLOWED' if allowed else 'BLOCKED'}")
    print(f"Attempts remaining: {remaining}")
