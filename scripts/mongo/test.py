#!/usr/bin/env python3
"""
MongoDB Session Manager Test Script

This script tests the functionality of the session manager by:
1. Creating a new session
2. Validating the session
3. Trying to create a duplicate session (should fail)
4. Extending the session
5. Ending the session
"""

import sys

# Import session manager
try:
    from session import MONGODB_AVAILABLE, SessionManager
except ImportError:
    print("Error: session.py not found in current directory")
    sys.exit(1)

# Check if MongoDB is available
if not MONGODB_AVAILABLE:
    print("MongoDB support not available.")
    print("Install required packages: pip install pymongo dnspython")
    sys.exit(1)

def run_tests():
    """Run a series of tests on the session manager"""

    print("Initializing SessionManager...")
    session_mgr = SessionManager(
        connection_string="mongodb://localhost:27017/",
        db_name="test_db",
        session_expiry_minutes=5
    )

    # Test 1: Create a session
    print("\nTest 1: Create a new session")
    user_id = f"test.user@example.com"
    success, message, session = session_mgr.create_session(user_id)

    if success:
        print(f"  Success: {message}")
        print(f"  Session token: {session['token']}")
        print(f"  Expires at: {session['expires_at']}")
        token = session['token']
    else:
        print(f"  Failed: {message}")
        if 'already has an active session' in message:
            # Get existing session
            print("  Retrieving existing session...")
            session = session_mgr.get_user_session(user_id)
            if session:
                token = session['token']
                print(f"  Found existing session: {token}")
            else:
                print("  No existing session found, ending tests")
                return
        else:
            print("  Ending tests due to failure")
            return

    # Test 2: Validate the session
    print("\nTest 2: Validate the session")
    is_valid, message, _ = session_mgr.validate_session(token)
    print(f"  Session valid: {is_valid}")
    print(f"  Message: {message}")

    # Test 3: Try to create a duplicate session (should fail)
    print("\nTest 3: Try to create a duplicate session")
    success, message, _ = session_mgr.create_session(user_id)
    print(f"  Expected failure: {not success}")
    print(f"  Message: {message}")

    # Test 4: Extend the session
    print("\nTest 4: Extend the session")
    success, message = session_mgr.extend_session(token, 10)
    print(f"  Success: {success}")
    print(f"  Message: {message}")

    # Test 5: End the session
    print("\nTest 5: End the session")
    success, message = session_mgr.end_session(token)
    print(f"  Success: {success}")
    print(f"  Message: {message}")

    # Test 6: Clean expired sessions
    print("\nTest 6: Clean expired sessions")
    cleaned = session_mgr.clean_expired_sessions()
    print(f"  Cleaned {cleaned} expired sessions")

    # Test 7: Count active sessions
    print("\nTest 7: Count active sessions")
    active = session_mgr.get_active_sessions_count()
    print(f"  Active sessions: {active}")

    print("\nTests completed successfully!")

if __name__ == "__main__":
    run_tests()
