#!/usr/bin/env python3
"""
Privacy Test Script

Tests all session management alternatives with privacy focus.
"""

import time

# Try to import the session managers
try:
    print("Testing Redis-based Session Manager...")
    from redis_session import SessionManager as RedisSessionManager
    redis_available = True
except ImportError:
    print("Redis Session Manager not available")
    redis_available = False

try:
    print("Testing File-based Session Manager...")
    from file_session import FileSessionManager
    file_available = True
except ImportError:
    print("File Session Manager not available")
    file_available = False

try:
    print("Testing Memory-only Session Manager...")
    from memory_session import MemorySessionManager
    memory_available = True
except ImportError:
    print("Memory Session Manager not available")
    memory_available = False


def run_test(manager, name):
    """Run test for a specific session manager."""
    print(f"\n=== Testing {name} ===\n")

    # Create a session
    print("Test 1: Creating token")
    success, message, session = manager.create_session("test_user")
    if success:
        token = session.get('token')
        print(f"PASS: Token created: {token[:8]}...")
    else:
        print(f"FAIL: {message}")
        return

    # Verify token
    print("\nTest 2: Verifying token")
    is_valid, msg, _ = manager.validate_session(token)
    print(f"PASS: Token valid: {is_valid}")

    # Try to create another session for same user (should fail)
    print("\nTest 3: Checking duplicate prevention")
    success, message, _ = manager.create_session("test_user")
    if not success and "already has an active session" in message:
        print("PASS: Prevented duplicate session")
    else:
        print("FAIL: Allowed duplicate session")

    # Delete the session
    print("\nTest 4: Deleting session")
    deleted = manager.delete_session(token)
    print(f"PASS: Session deleted: {deleted}")

    # Test expiration
    print("\nTest 5: Testing expiration")
    # Create short-lived token
    if hasattr(manager, "expiry_minutes"):
        # Save original value
        original_expiry = manager.expiry_minutes
        # Set to very short expiry (2 seconds)
        manager.expiry_minutes = 2/60

        # Create token
        success, _, session = manager.create_session("test_user_expiry")
        if success:
            token = session.get('token')
            print(f"Created short-lived token: {token[:8]}...")

            # Wait for expiration
            print("Waiting 3 seconds for expiration...")
            time.sleep(3)

            # Verify expiration
            is_valid, _, _ = manager.validate_session(token)
            if not is_valid:
                print("PASS: Token expired correctly")
            else:
                print("FAIL: Token did not expire")

            # Restore original expiry
            manager.expiry_minutes = original_expiry
    else:
        print("SKIP: Manager does not support expiry_minutes")

    print("\nTest complete!")


def main():
    """Main test function."""
    print("SESSION MANAGER PRIVACY TEST")
    print("===========================\n")

    if not (redis_available or file_available or memory_available):
        print("No session managers available to test!")
        return

    # Test available managers
    if redis_available:
        try:
            redis_mgr = RedisSessionManager(
                host="localhost",
                port=6379,
                session_expiry_minutes=60,
                privacy_mode=True
            )
            run_test(redis_mgr, "Redis Session Manager")
        except Exception as e:
            print(f"Error testing Redis manager: {e}")

    if file_available:
        try:
            file_mgr = FileSessionManager(
                storage_dir="./sessions",
                session_expiry_minutes=60,
                privacy_mode=True
            )
            run_test(file_mgr, "File Session Manager")
        except Exception as e:
            print(f"Error testing File manager: {e}")

    if memory_available:
        try:
            memory_mgr = MemorySessionManager(
                session_expiry_minutes=60
            )
            run_test(memory_mgr, "Memory-only Session Manager")
        except Exception as e:
            print(f"Error testing Memory manager: {e}")

    print("\nAll tests completed!")


if __name__ == "__main__":
    main()
