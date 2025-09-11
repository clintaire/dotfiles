#!/usr/bin/env python3
"""
Mini App Integration Example

This example shows how to integrate the session manager with your mini app to
limit users to one active session and track usage.
"""

import os
import sys
import time

# Add parent directory to path to import convert
sys.path.append('/home/cli/git/dotfiles/scripts')

# Import your convert module and session manager
try:
    from convert import convert
    from session import MONGODB_AVAILABLE, SessionManager
except ImportError:
    print("Error: Missing required modules.")
    print("Make sure convert.py is in the scripts directory and")
    print("session.py is in the current directory.")
    sys.exit(1)

# MongoDB configuration (change these settings for your environment)
MONGODB_URI = os.environ.get("MONGODB_URI", "mongodb://localhost:27017/")
DB_NAME = "mini_app"
SESSION_EXPIRY_MINUTES = 30

def display_menu():
    """Display the mini app menu."""
    print("\n===== Mini App =====")
    print("1. Create HTML Entities")
    print("2. Base64 Encode")
    print("3. Base64 Decode")
    print("4. Generate SAML URL")
    print("5. Create SNAPI Secure Link")
    print("6. Generate UTM URLs")
    print("7. Encrypt Text")
    print("8. Decrypt Text")
    print("9. Exit")
    return input("Select an option: ")

def process_option(option, user_id, session_token):
    """Process the selected menu option."""
    if option == "1":
        text = input("Enter text to convert to HTML entities: ")
        result = convert.convert_to_html_entities(text)
        print(f"Result: {result}")
    elif option == "2":
        text = input("Enter text to encode: ")
        result = convert.base64_encode(text)
        print(f"Result: {result}")
    elif option == "3":
        text = input("Enter text to decode: ")
        result = convert.base64_decode(text)
        print(f"Result: {result}")
    elif option == "4":
        url = input("Enter URL for SAML: ")
        result = convert.create_saml_url(url)
        print(f"Result: {result}")
    elif option == "5":
        url = input("Enter URL for SNAPI link: ")
        result = convert.generate_snapi_link(url, user_id)
        print(f"Result: {result}")
    elif option == "6":
        url = input("Enter base URL: ")
        source = input("Enter UTM source: ")
        medium = input("Enter UTM medium: ")
        campaign = input("Enter UTM campaign: ")
        count = int(input("How many URLs? "))
        results = convert.generate_batch_utm_urls(
            url, source, medium, campaign, count=count
        )
        print(f"Generated {len(results)} URLs. First URL: {results[0]}")
    elif option == "7":
        text = input("Enter text to encrypt: ")
        result = convert.aes_encrypt(text, auto_generate_password=True)
        print(f"Password: {result[0]}")
        print(f"Encrypted: {result[1]}")
    elif option == "8":
        text = input("Enter text to decrypt: ")
        password = input("Enter password: ")
        result = convert.aes_decrypt(text, password)
        print(f"Decrypted: {result}")
    elif option == "9":
        return False
    else:
        print("Invalid option")

    # Add a small delay between operations
    time.sleep(1)
    return True

def main():
    """Main function to run the mini app with session management."""

    # Check if MongoDB is available
    if not MONGODB_AVAILABLE:
        print("Warning: MongoDB support not available.")
        print("Session management is disabled. Users will have unlimited access.")
        print("To enable session management: pip install pymongo dnspython")

        # Run without session management
        while True:
            option = display_menu()
            if not process_option(option, "anonymous", None):
                break
        return

    # Initialize session manager
    session_mgr = SessionManager(
        connection_string=MONGODB_URI,
        db_name=DB_NAME,
        session_expiry_minutes=SESSION_EXPIRY_MINUTES
    )

    # Get user information
    user_id = input("Please enter your email for session tracking: ")

    # Check if user already has an active session
    existing_session = session_mgr.get_user_session(user_id)

    if existing_session:
        print(f"You already have an active session that expires at: "
              f"{existing_session['expires_at'].strftime('%Y-%m-%d %H:%M:%S')}")
        print("Only one session per user is allowed in the free tier.")

        # Option to continue with existing session
        choice = input("Do you want to continue with this session? (y/n): ")
        if choice.lower() != 'y':
            print("Session limited. Please try again later.")
            return

        # Use existing session
        session_token = existing_session['token']
        print("Continuing with existing session.")
    else:
        # Create new session
        success, message, session = session_mgr.create_session(user_id)

        if not success:
            print(f"Session error: {message}")
            return

        session_token = session['token']
        print(f"New session created. Expires in {SESSION_EXPIRY_MINUTES} minutes.")

    # Main application loop
    continue_app = True

    try:
        while continue_app:
            # Validate session before each operation
            is_valid, message, session = session_mgr.validate_session(session_token)

            if not is_valid:
                print(f"Session error: {message}")
                break

            # Display usage count
            print(f"Session usage count: {session['usage_count']}")

            # Check if approaching usage limit
            if session['usage_count'] >= 20:
                print("Warning: Approaching free tier usage limit (20 operations).")

            option = display_menu()
            continue_app = process_option(option, user_id, session_token)

    except KeyboardInterrupt:
        print("\nExiting application...")
    finally:
        # Always clean up sessions on exit
        print("Cleaning up expired sessions...")
        cleaned = session_mgr.clean_expired_sessions()
        if cleaned > 0:
            print(f"Removed {cleaned} expired sessions")

        print("Thank you for using the mini app!")

if __name__ == "__main__":
    main()
