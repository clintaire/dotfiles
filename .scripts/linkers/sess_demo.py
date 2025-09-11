#!/usr/bin/env python3
"""
Session Manager Example

This script demonstrates how to use the session management system
with different backends (Redis, File, Memory, MongoDB).
"""

import os
import sys

# Add parent directory to path
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

# Try to import from linkers directory
try:
    # Import additional functions
    from linkers.sess_intg import check_user, create_user, init_sess_mgr
except ImportError:
    print("Warning: Could not import from linkers directory")
    print("Make sure the linkers directory is in your Python path")
    sys.exit(1)


def get_mgrs():
    """Show available session managers."""
    mgrs = []

    # Check for locally session managers
    try:
        # Try importing the module without storing the import
        __import__('locally')
        print("Locally session managers available")

        try:
            # Check if memory session is available
            __import__('locally.memory_session')
            mgrs.append("memory")
        except ImportError:
            pass

        try:
            # Check if file session is available
            __import__('locally.file_session')
            mgrs.append("file")
        except ImportError:
            pass

        try:
            # Check if redis session is available
            __import__('locally.redis_session')
            mgrs.append("redis")
        except ImportError:
            pass
    except ImportError:
        print("Locally session managers not available")

    # Check for MongoDB session manager
    try:
        # Check if mongo session is available
        __import__('mongo.session')
        print("MongoDB session manager available")
        mgrs.append("mongo")
    except ImportError:
        print("MongoDB session manager not available")

    return mgrs


def test_mgr(mgr_type: str):
    """
    Test a specific session manager.

    Args:
        mgr_type: Type of session manager to test
    """
    print(f"\nTesting {mgr_type} session manager:")
    print("-" * 40)

    # Initialize the manager
    config = {
        "session_expiry_minutes": 5,  # Short expiry for testing
        "privacy_mode": True
    }

    # Add manager-specific config
    if mgr_type == "file":
        config["storage_dir"] = os.path.join(parent_dir, "sessions_test")
    elif mgr_type == "redis":
        config["redis_host"] = "localhost"
        config["redis_port"] = 6379
    elif mgr_type == "mongo":
        config["connection_string"] = "mongodb://localhost:27017/"
        config["db_name"] = "session_test"

    # Initialize the manager
    manager = init_sess_mgr(mgr_type, config)

    if not manager:
        print(f"Failed to initialize {mgr_type} session manager")
        return

    print(f"Session manager initialized: {type(manager).__name__}")

    # Create a test session
    user_id = f"test_user_{mgr_type}"
    print(f"Creating session for user: {user_id}")

    success, message, session = create_user(manager, user_id)
    if not success:
        print(f"Failed to create session: {message}")
        return

    token = session.get("token", "")
    print(f"Session created with token: {token[:8]}...")

    # Check if user has an active session
    user_session = check_user(manager, user_id)
    if user_session:
        print("User has an active session")
    else:
        print("User does not have an active session")

    # Validate the session
    if hasattr(manager, "validate_session"):
        is_valid, msg, _ = manager.validate_session(token)
        print(f"Session valid: {is_valid}, Message: {msg}")

    # Delete the session
    if hasattr(manager, "delete_session"):
        deleted = manager.delete_session(token)
        print(f"Session deleted: {deleted}")

    print(f"{mgr_type} session manager test completed\n")


def main():
    """Main function."""
    print("Session Manager Example")
    print("======================\n")

    # Show available session managers
    print("Checking available session managers...")
    avail_mgrs = get_mgrs()

    if not avail_mgrs:
        print("No session managers available")
        return

    print(f"Available session managers: {', '.join(avail_mgrs)}")

    # Test each available session manager
    for mgr_type in avail_mgrs:
        test_mgr(mgr_type)

    print("All tests completed!")


if __name__ == "__main__":
    main()
