#!/usr/bin/env python3
"""
Privacy Test for Mong    # Test 2: Verify token
    print("\nTest 2: Verifying token")
    is_valid, msg, _ = session_mgr.validate_session(token)
    print(f"PASS: Token valid: {is_valid}")Session Manager

Simple test for token expiry with zero tracking or logging.
"""

import sys
import time

# Import the SessionManager
try:
    from session import MONGODB_AVAILABLE, SessionManager
except ImportError:
    print("Error: Cannot import SessionManager from session.py")
    sys.exit(1)

if not MONGODB_AVAILABLE:
    print("Error: MongoDB support not available")
    print("Install pymongo first")
    sys.exit(1)


def run_test():
    """Run a simple privacy test."""
    print("\n=== Privacy Test ===\n")

    # Test setup
    DB_NAME = f"test_db_{int(time.time())}"  # Unique test DB
    SHORT_EXPIRY = 2  # 2 seconds for quick testing

    # Create manager with privacy mode ON
    session_mgr = SessionManager(
        db_name=DB_NAME,
        session_expiry_minutes=SHORT_EXPIRY / 60,
        privacy_mode=True
    )

    # Test 1: Create a token
    print("Test 1: Creating token")
    success, message, session = session_mgr.create_session("test_user")
    if success:
        token = session['token']
        print("PASS: Token created")
    else:
        print(f"FAIL: {message}")
        return

    # Test 2: Verify token works
    print("\nTest 2: Verifying token")
    is_valid, msg, _ = session_mgr.validate_session(token)
    print(f"✓ Token valid: {is_valid}")

    # Test 3: Check privacy
    print("\nTest 3: Checking privacy")
    session_doc = session_mgr.db.sessions.find_one({"token": token})

    # Remove MongoDB internal ID for cleaner output
    if '_id' in session_doc:
        del session_doc['_id']

    print("Data stored (should be minimal):")
    for key in session_doc:
        print(f"  - {key}")

    # Check for tracking fields
    bad_fields = ['ip', 'browser', 'device', 'location', 'usage_stats']
    for field in bad_fields:
        if any(field in key for key in session_doc):
            print(f"FAIL: Found tracking field: {field}")
            break
    else:
        print("PASS: No tracking fields found")

    # Test 4: Expiration
    print("\nTest 4: Testing expiration")
    print(f"Waiting {SHORT_EXPIRY} seconds...")
    time.sleep(SHORT_EXPIRY + 0.5)

    is_valid, msg, _ = session_mgr.validate_session(token)
    if not is_valid:
        print("PASS: Token expired correctly")
    else:
        print("FAIL: Token did not expire")

    # Cleanup
    try:
        session_mgr.client.drop_database(DB_NAME)
        print("\nPASS: Test database removed")
    except Exception:
        print("\nFAIL: Failed to clean up test database")

    print("\nTest complete!")


if __name__ == "__main__":
    run_test()
