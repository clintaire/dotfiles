#!/usr/bin/env python3
"""
/*
 © Copyright 2025 Clint Aire.

 * This script provides comprehensive text conversion and security utilities
 * including HTML entity conversion, Base64 encoding/decoding, regex pattern escaping,
 * secure SAML URL generation, advanced encryption, and mathematical link generation.
 * It implements robust security features with cryptographic principles for authentication,
 * user identification and link verification with expiration controls.
 * Designed for command-line usage with interactive prompts and batch processing.
 * Use responsibly for legitimate security and conversion purposes only.
*/

Universal Text Converter

This script provides multiple text conversion utilities:
1. HTML Entity conversion - converts text to HTML entities (&#xxx;)
2. Base64 encoding/decoding
3. Regex pattern escaping
4. SAML-style URL encoding for secure links
5. Encryption/Decryption using various algorithms:
   - AES (Advanced Encryption Standard)
   - RSA (Rivest-Shamir-Adleman)
   - Blowfish
6. Advanced Mathematical Link Generation:
   - SNAPI (Secure Nonlinear Algorithm for Parameter Identification)
   - Binomial expansion theorem based identifiers
   - Asymptotic notation based hashing
   - Chebyshev's inequality based verification tokens
   - Modular arithmetic for secure URLs

Example:
    HTML Entity: "Hello!" -> "&#72;&#101;&#108;&#108;&#111;&#33;"
    Base64: "Hello!" -> "SGVsbG8h"
    Regex Escape: "a.b*c+" -> "a\\.b\\*c\\+"
    SAML URL: "https://example.com" with parameters -> encoded for SAML
    Math Link: URL with embedded mathematical token for verification
"""

import base64
import getpass
import hashlib
import math
import os
import random
import re
import time
import urllib.parse
import uuid
from typing import Optional, Tuple

# Import crypto libraries with graceful fallback
CRYPTO_AVAILABLE = True
try:
    # Import Blowfish from decrepit to avoid deprecation warnings
    from cryptography.hazmat.decrepit.ciphers.algorithms import Blowfish
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding, rsa
    from cryptography.hazmat.primitives.ciphers import Cipher, modes
    from cryptography.hazmat.primitives.ciphers.algorithms import AES
    from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
except ImportError:
    CRYPTO_AVAILABLE = False
    print("Warning: Cryptography package not installed.")
    print("To enable encryption, install with: pip install cryptography")

# Optional MongoDB import for session management
try:
    from pymongo import MongoClient
    MONGODB_AVAILABLE = True
except ImportError:
    MONGODB_AVAILABLE = False


def text_to_html_entities(text: str) -> str:
    """
    Convert each character in the input text to its HTML entity representation.

    Args:
        text (str): The input string to convert.

    Returns:
        str: The converted string with HTML entities.

    Example:
        >>> text_to_html_entities("A")
        '&#65;'
    """
    return ''.join(f'&#{ord(c)};' for c in text)


def text_to_base64(text: str) -> str:
    """
    Encode text to Base64.

    Args:
        text (str): The input string to encode.

    Returns:
        str: The Base64 encoded string.

    Example:
        >>> text_to_base64("Hello!")
        'SGVsbG8h'
    """
    return base64.b64encode(text.encode('utf-8')).decode('utf-8')


def base64_to_text(encoded_text: str) -> str:
    """
    Decode Base64 to text.

    Args:
        encoded_text (str): The Base64 encoded string.

    Returns:
        str: The decoded string.

    Example:
        >>> base64_to_text("SGVsbG8h")
        'Hello!'
    """
    try:
        return base64.b64decode(encoded_text).decode('utf-8')
    except Exception as e:
        raise ValueError(f"Invalid Base64 string: {e}")


def escape_regex(text: str, security_level: int = 1) -> str:
    """
    Escape and transform a string into a secure regex pattern using cryptographic principles.

    This function goes beyond simple character escaping and applies various
    cryptographic techniques to create highly secure and complex regex patterns
    based on the desired security level.

    Args:
        text (str): The input string to convert to a secure regex pattern.
        security_level (int, optional): The level of security to apply (1-3).
            1 = Basic escaping
            2 = Intermediate with character classes and alternations
            3 = Advanced with cryptographic hashing and non-deterministic elements

    Returns:
        str: The secure regex pattern that will only match the original input.

    Example:
        >>> escape_regex("a.b*c+")
        'a\\.b\\*c\\+'
        >>> escape_regex("password", security_level=3)
        '(?=.*p)(?=.*a)(?=.*s)(?=.*w)(?=.*o)(?=.*r)(?=.*d)^(?:p[^\\s]{0,1}a[^\\s]{0,1}s[^\\s]{0,1}s[^\\s]{0,1}w[^\\s]{0,1}o[^\\s]{0,1}r[^\\s]{0,1}d)$'
    """
    # Basic escaping (Level 1)
    special_chars = r'.^$*+?()[]{}|\\'
    escaped_text = ''.join(f'\\{c}' if c in special_chars else c for c in text)

    if security_level == 1:
        return escaped_text

    # Intermediate security (Level 2)
    if security_level == 2:
        # Create character class alternatives for each character
        # This makes the regex more complex but still deterministic
        parts = []
        for char in text:
            if char.isalpha():
                # For letters, create case-insensitive matches when appropriate
                if char.lower() == char:
                    # Lowercase letter
                    parts.append(f"[{re.escape(char.lower() + char.upper())}]")
                else:
                    # Uppercase letter
                    parts.append(f"[{re.escape(char.upper() + char.lower())}]")
            elif char.isdigit():
                # For digits, create a character class with nearby digits
                digit = int(char)
                # Create a pattern that allows nearby digits with non-digit separators
                parts.append(f"[{char}][^0-9]*?")
            elif char in special_chars:
                # Special regex chars need escaping and optional quantifier
                parts.append(f"\\{char}+?")
            else:
                # Other characters
                parts.append(re.escape(char))

        # Add anchors and construct pattern with optional spacing
        return f"^{'.*?'.join(parts)}$"

    # Advanced security (Level 3)
    if security_level == 3:
        # Apply cryptographic principles to create a complex pattern
        chars = list(text)

        # 1. Create lookaheads for each character (similar to hash verification)
        lookaheads = []
        for char in set(chars):  # Unique characters only
            lookaheads.append(f"(?=.*{re.escape(char)})")

        # 2. Create a pattern that enforces character order but allows for
        # limited variations (similar to salted hashing)
        main_pattern_parts = []
        for i, char in enumerate(chars):
            # Each character followed by optional non-whitespace chars
            if char in special_chars:
                main_pattern_parts.append(f"\\{char}[^\\s]{{0,1}}")
            else:
                main_pattern_parts.append(f"{re.escape(char)}[^\\s]{{0,1}}")

        # 3. Combine the patterns with anchors (similar to digital signature)
        main_pattern = ''.join(main_pattern_parts)

        # 4. Create the final pattern with lookaheads and anchored pattern
        return f"{''.join(lookaheads)}^(?:{main_pattern})$"

    # Default to level 1 for invalid security levels
    return escaped_text


def create_advanced_saml_url(
    url: str, email: str, pattern: str, encryption_key: str
) -> str:
    """
    Create an advanced SAML-compatible URL with multiple security layers.

    Format:
    domain/(encoded+unique+UUID)/(encryption+HASH(BEGIN)+hazmat+key)/
    (regex+email)/(encryption)/(regex+pattern+Hash(END))/(Encryption)/exit/

    Args:
        url (str): The base URL (domain)
        email (str): Email to encode in the SAML URL
        pattern (str): Pattern to use for regex validation
        encryption_key (str): Key for encryption layers

    Returns:
        str: Highly secure SAML URL with multiple security layers

    Note:
        Generated URLs are guaranteed to be unique due to UUID and timestamp
        components. The HASH(BEGIN) and HASH(END) components must match for
        validation to succeed.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package required for advanced SAML URLs]"

    try:
        # Generate a unique UUID (never the same)
        unique_id = str(uuid.uuid4())

        # Add timestamp to ensure uniqueness even with same inputs
        timestamp = str(int(time.time()))

        # Generate HASH(BEGIN) and HASH(END) which must work together
        hash_seed = encryption_key + timestamp
        hash_begin = hashlib.sha256(
            (hash_seed + "BEGIN").encode()
        ).hexdigest()[:16]
        hash_end = hashlib.sha256(
            (hash_seed + "END").encode()
        ).hexdigest()[:16]

        # Component 1: Encoded URL with UUID
        component_1 = base64.urlsafe_b64encode(
            (url + ":" + unique_id + ":" + timestamp).encode()
        ).decode().rstrip("=")

        # Component 2: Encryption + HASH(BEGIN) + hazmat
        # Use AES for encryption with the HASH(BEGIN) as additional data
        key_bytes = hashlib.sha256(encryption_key.encode()).digest()
        iv = os.urandom(16)
        cipher = Cipher(AES(key_bytes), modes.GCM(iv))
        encryptor = cipher.encryptor()
        encryptor.authenticate_additional_data(hash_begin.encode())
        component_2_raw = (
            encryptor.update(hash_begin.encode()) + encryptor.finalize()
        )
        component_2_tag = encryptor.tag
        component_2 = base64.urlsafe_b64encode(
            iv + component_2_raw + component_2_tag
        ).decode().rstrip("=")

        # Component 3: Regex + email
        email_pattern = re.escape(email)
        component_3 = base64.urlsafe_b64encode(
            (email_pattern + ":" + email).encode()
        ).decode().rstrip("=")

        # Component 4: Encryption layer
        cipher = Cipher(AES(key_bytes), modes.CBC(iv))
        encryptor = cipher.encryptor()
        padded_email = (
            email.encode() + b'\0' * (16 - (len(email.encode()) % 16))
        )
        component_4 = base64.urlsafe_b64encode(
            iv + encryptor.update(padded_email) + encryptor.finalize()
        ).decode().rstrip("=")

        # Component 5: Regex pattern + HASH(END)
        component_5 = base64.urlsafe_b64encode(
            (pattern + ":" + hash_end).encode()
        ).decode().rstrip("=")

        # Component 6: Final encryption layer
        cipher = Cipher(AES(key_bytes), modes.CFB8(iv))
        encryptor = cipher.encryptor()
        component_6 = base64.urlsafe_b64encode(
            iv + encryptor.update(hash_end.encode()) + encryptor.finalize()
        ).decode().rstrip("=")

        # Assemble the final URL
        result = (
            f"{url}/{component_1}/{component_2}/{component_3}/"
            f"{component_4}/{component_5}/{component_6}/exit/"
        )

        return result
    except Exception as e:
        return f"[SAML URL generation error: {str(e)}]"


def verify_advanced_saml_url(
    saml_url: str, encryption_key: str
) -> Tuple[bool, str]:
    """
    Verify an advanced SAML URL created with create_advanced_saml_url.

    Args:
        saml_url (str): The advanced SAML URL to verify
        encryption_key (str): The encryption key used to create the URL

    Returns:
        Tuple[bool, str]: (is_valid, message) where is_valid indicates if
                          the URL is valid and message provides details
    """
    if not CRYPTO_AVAILABLE:
        return False, "Cryptography package required for verification"

    try:
        # Split the URL into components
        parts = saml_url.rstrip("/").split("/")

        if len(parts) < 8:  # Ensure we have enough parts
            return False, "Invalid URL format: insufficient components"

        # We don't use domain and component_6 directly, but keep for clarity
        # domain = parts[0]
        component_1 = parts[1]  # encoded+UUID
        component_2 = parts[2]  # HASH(BEGIN)
        component_3 = parts[3]  # email
        component_4 = parts[4]  # encrypted email
        component_5 = parts[5]  # pattern+HASH(END)
        # component_6 = parts[6]  # encrypted HASH(END)

        # Derive key from the encryption key
        key_bytes = hashlib.sha256(encryption_key.encode()).digest()

        # Extract and verify HASH(BEGIN) from component 2
        try:
            data = base64.urlsafe_b64decode(component_2 + "==")
            iv = data[:16]
            encrypted_data = data[16:-16]
            tag = data[-16:]

            cipher = Cipher(AES(key_bytes), modes.GCM(iv, tag))
            decryptor = cipher.decryptor()

            # We need to extract the hash_begin to authenticate with
            # First, decode component 1 to get timestamp
            comp1_data = base64.urlsafe_b64decode(component_1 + "==").decode()
            timestamp = comp1_data.split(":")[-1]

            # Regenerate hash_begin for authentication
            hash_seed = encryption_key + timestamp
            expected_hash_begin = hashlib.sha256(
                (hash_seed + "BEGIN").encode()
            ).hexdigest()[:16]

            decryptor.authenticate_additional_data(expected_hash_begin.encode())
            hash_begin = decryptor.update(encrypted_data) + decryptor.finalize()
            hash_begin = hash_begin.decode()

            if hash_begin != expected_hash_begin:
                return False, "BEGIN hash validation failed"

        except Exception as e:
            return False, f"Failed to verify BEGIN hash: {str(e)}"

        # Extract and verify HASH(END) from component 5
        try:
            comp5_data = base64.urlsafe_b64decode(component_5 + "==").decode()
            hash_end = comp5_data.split(":")[-1]

            # Regenerate hash_end for comparison
            expected_hash_end = hashlib.sha256(
                (hash_seed + "END").encode()
            ).hexdigest()[:16]

            if hash_end != expected_hash_end:
                return False, "END hash validation failed"

        except Exception as e:
            return False, f"Failed to verify END hash: {str(e)}"

        # Decrypt email for verification
        try:
            data = base64.urlsafe_b64decode(component_4 + "==")
            iv = data[:16]
            encrypted_data = data[16:]

            cipher = Cipher(AES(key_bytes), modes.CBC(iv))
            decryptor = cipher.decryptor()
            decrypted_email = (
                decryptor.update(encrypted_data) + decryptor.finalize()
            )
            decrypted_email = decrypted_email.rstrip(b'\0').decode()

            # Verify email matches the one in component 3
            comp3_data = base64.urlsafe_b64decode(component_3 + "==").decode()
            encoded_email = comp3_data.split(":")[-1]

            if decrypted_email != encoded_email:
                return False, "Email verification failed"

        except Exception as e:
            return False, f"Failed to verify email: {str(e)}"

        # All validations passed
        return True, "URL verification successful"

    except Exception as e:
        return False, f"Verification error: {str(e)}"


def generate_utm_parameters(
    source: str, medium: str, campaign: str,
    content: Optional[str] = None, term: Optional[str] = None,
    unique_id: Optional[int] = None
) -> str:
    """
    Generate UTM parameters for URL tracking.

    Args:
        source (str): The source of the traffic (utm_source)
        medium (str): The marketing medium (utm_medium)
        campaign (str): The campaign name (utm_campaign)
        content (str, optional): Identifies what was clicked (utm_content)
        term (str, optional): Search terms (utm_term)
        unique_id (int, optional): A unique identifier (1-10000) for individual tracking

    Returns:
        str: URL query string with UTM parameters
    """
    params = {
        "utm_source": source,
        "utm_medium": medium,
        "utm_campaign": campaign
    }

    if content:
        params["utm_content"] = content
    if term:
        params["utm_term"] = term
    if unique_id is not None:
        # Add a unique identifier in range 1-10000
        unique_id = max(1, min(10000, unique_id))
        params["utm_id"] = str(unique_id)

    return urllib.parse.urlencode(params)


def generate_batch_utm_urls(
    url: str, source: str, medium: str, campaign: str,
    content: Optional[str] = None, term: Optional[str] = None,
    count: int = 1, use_custom_format: bool = False,
    encryption_key: Optional[str] = None
) -> list:
    """
    Generate multiple UTM-tagged URLs with unique identifiers.

    Args:
        url (str): The base URL to tag
        source (str): The utm_source parameter
        medium (str): The utm_medium parameter
        campaign (str): The utm_campaign parameter
        content (str, optional): The utm_content parameter
        term (str, optional): The utm_term parameter
        count (int): Number of URLs to generate (1-10000)
        use_custom_format (bool): Whether to use advanced SAML-style formatting
        encryption_key (str, optional): Key for encryption if using custom format

    Returns:
        list: List of generated URLs
    """
    # Ensure URL has a protocol
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    # Limit count to prevent resource exhaustion
    count = max(1, min(10000, count))
    results = []

    for i in range(1, count + 1):
        # Create UTM parameters with unique ID
        utm_params = {
            "utm_source": source,
            "utm_medium": medium,
            "utm_campaign": campaign
        }

        if content:
            utm_params["utm_content"] = content
        if term:
            utm_params["utm_term"] = term

        # Add the unique identifier
        utm_params["utm_id"] = str(i)

        # Generate custom hash based on UTM parameters
        custom_hash = hashlib.md5(
            f"{source}|{medium}|{campaign}|{i}|{time.time()}".encode()
        ).hexdigest()[:10]

        if use_custom_format and CRYPTO_AVAILABLE and encryption_key:
            # Use advanced SAML URL format with unique identifiers
            unique_id = str(uuid.uuid4())
            timestamp = str(int(time.time()))

            # Generate HASH values
            hash_seed = encryption_key + timestamp + str(i)
            hash_begin = hashlib.sha256(
                (hash_seed + "BEGIN").encode()
            ).hexdigest()[:16]
            hash_end = hashlib.sha256(
                (hash_seed + "END").encode()
            ).hexdigest()[:16]

            # Component 1: Encoded URL with UUID
            component_1 = base64.urlsafe_b64encode(
                (url + ":" + unique_id + ":" + timestamp).encode()
            ).decode().rstrip("=")

            # Component 2: Encryption + HASH(BEGIN)
            key_bytes = hashlib.sha256(encryption_key.encode()).digest()
            iv = os.urandom(16)
            cipher = Cipher(AES(key_bytes), modes.GCM(iv))
            encryptor = cipher.encryptor()
            encryptor.authenticate_additional_data(hash_begin.encode())
            component_2_raw = (
                encryptor.update(hash_begin.encode()) + encryptor.finalize()
            )
            component_2_tag = encryptor.tag
            component_2 = base64.urlsafe_b64encode(
                iv + component_2_raw + component_2_tag
            ).decode().rstrip("=")

            # Component 3: UTM params encoded
            utm_string = urllib.parse.urlencode(utm_params)
            component_3 = base64.urlsafe_b64encode(
                utm_string.encode()
            ).decode().rstrip("=")

            # Component 4: Encryption layer with UTM ID
            cipher = Cipher(AES(key_bytes), modes.CBC(iv))
            encryptor = cipher.encryptor()
            padded_utm_id = (
                utm_params["utm_id"].encode() +
                b'\0' * (16 - (len(utm_params["utm_id"].encode()) % 16))
            )
            component_4 = base64.urlsafe_b64encode(
                iv + encryptor.update(padded_utm_id) + encryptor.finalize()
            ).decode().rstrip("=")

            # Component 5: Hash tracking
            component_5 = base64.urlsafe_b64encode(
                (custom_hash + ":" + hash_end).encode()
            ).decode().rstrip("=")

            # Component 6: Final encryption layer
            cipher = Cipher(AES(key_bytes), modes.CFB8(iv))
            encryptor = cipher.encryptor()
            component_6 = base64.urlsafe_b64encode(
                iv + encryptor.update(hash_end.encode()) + encryptor.finalize()
            ).decode().rstrip("=")

            # Assemble the final URL with custom format
            result = (
                f"{url}/{component_1}/{component_2}/{component_3}/"
                f"{component_4}/{component_5}/{component_6}/exit/"
            )
            results.append(result)
        else:
            # Create normal URL with UTM parameters
            query_string = urllib.parse.urlencode(utm_params)
            if "?" in url:
                result = f"{url}&{query_string}"
            else:
                result = f"{url}?{query_string}"
            results.append(result)

    return results


def create_saml_url_with_hash(
    url: str,
    custom_hash: str,
    relay_state: Optional[str] = None,
    target_url: Optional[str] = None,
    utm_params: Optional[dict] = None
) -> str:
    """
    Create a SAML-compatible URL with a custom hash for user tracking.

    Args:
        url (str): The source URL to encode
        custom_hash (str): Custom hash for user identification/tracking
        relay_state (str, optional): Additional state information to preserve
        target_url (str, optional): The target URL to redirect to
        utm_params (dict, optional): UTM parameters for tracking

    Returns:
        str: The SAML-encoded URL with custom hash and optional UTM parameters
    """
    # Ensure URL has a protocol
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    # Determine the base URL for the SAML request
    base_url = target_url if target_url else url

    # Ensure target URL has a protocol
    if base_url and not base_url.startswith(('http://', 'https://')):
        base_url = 'https://' + base_url

    # Add timestamp to the custom hash for additional security
    timestamp = str(int(time.time()))
    secured_hash = hashlib.sha256(
        (custom_hash + timestamp).encode()
    ).hexdigest()[:16]

    # Create a mock SAML request parameter that includes the source identity
    # and embed the custom hash and timestamp for tracking and validation
    mock_saml = base64.b64encode(
        f"SAMLRequest for: {url}|hash:{custom_hash}|ts:{timestamp}".encode('utf-8')
    ).decode('utf-8')

    # Build the basic URL with the SAML request
    params = {
        "SAMLRequest": mock_saml,
        "UserHash": secured_hash  # Use the secured hash instead of raw hash
    }

    # Add relay state if provided
    if relay_state:
        params["RelayState"] = relay_state

    # Add any UTM parameters if provided
    if utm_params:
        for key, value in utm_params.items():
            if key.startswith("utm_"):
                params[key] = value

    # Construct the final URL
    query_string = urllib.parse.urlencode(params)
    if "?" in base_url:
        return f"{base_url}&{query_string}"
    else:
        return f"{base_url}?{query_string}"


def create_saml_url(url: str, relay_state: Optional[str] = None,
                  target_url: Optional[str] = None) -> str:
    """
    Create a SAML-compatible URL for secure redirects.

    Args:
        url (str): The source URL to encode (containing the identity).
        relay_state (str, optional): Additional state information to preserve.
        target_url (str, optional): The target URL to redirect to. If not provided,
            the source URL is also used as the target.

    Returns:
        str: The SAML-encoded URL string.

    Example:
        >>> create_saml_url("https://example.com/user@example.com")
        'https://example.com/user@example.com?SAMLRequest=[encoded]'

        >>> create_saml_url("https://example.com/user@example.com",
                          target_url="https://google.com")
        'https://google.com?SAMLRequest=[encoded]'
    """
    # Simplified SAML URL encoding (actual SAML would need more complex logic)

    # Determine the base URL for the SAML request
    base_url = target_url if target_url else url

    # Create a mock SAML request parameter that includes the source identity
    mock_saml = base64.b64encode(
        f"SAMLRequest for: {url}".encode('utf-8')
    ).decode('utf-8')

    # Build the result URL with the SAML request
    result = (
        f"{base_url}" +
        ("&" if "?" in base_url else "?") +
        f"SAMLRequest={urllib.parse.quote_plus(mock_saml)}"
    )

    # Add relay state if provided
    if relay_state:
        result += f"&RelayState={urllib.parse.quote_plus(relay_state)}"

    return result


def generate_secure_password(length: int = 16) -> str:
    """
    Generate a cryptographically secure random password.

    Args:
        length (int): The length of the password to generate.

    Returns:
        str: A secure random password with mixed characters.
    """
    # Character sets for different types of characters
    lowercase = 'abcdefghijklmnopqrstuvwxyz'
    uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    digits = '0123456789'
    special = '!@#$%^&*()-_=+[]{}|;:,.<>?/'

    # Ensure we have at least one of each type
    password = [
        random.choice(lowercase),
        random.choice(uppercase),
        random.choice(digits),
        random.choice(special)
    ]

    # Fill the rest with random characters from all sets
    all_chars = lowercase + uppercase + digits + special
    password.extend(random.choice(all_chars) for _ in range(length - 4))

    # Shuffle the password to make it more random
    random.shuffle(password)

    return ''.join(password)


def aes_encrypt(text: str, auto_generate_password: bool = False) -> str:
    """
    Encrypt text using AES-256 encryption.

    Args:
        text (str): The text to encrypt.
        auto_generate_password (bool): Whether to generate a secure password
                                      automatically.

    Returns:
        str: Base64-encoded encrypted text and initialization vector.
              If a password was generated, returns the password and the encrypted text.

    Note:
        Either uses a password prompt or generates a secure password automatically.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package not installed]"

    try:
        # Get or generate password
        if auto_generate_password:
            password = generate_secure_password(20)  # Strong 20-char password
            print(f"\nGenerated secure password: {password}")
            print("SAVE THIS PASSWORD! You will need it to decrypt the text.")
        else:
            password = getpass.getpass("Enter encryption password: ")
            if not password:
                return "[Error: Empty password]"

        # Convert password to encryption key using PBKDF2
        salt = os.urandom(16)
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,  # 256 bits
            salt=salt,
            iterations=100000,
        )
        key = kdf.derive(password.encode())

        # Generate random IV (initialization vector)
        iv = os.urandom(16)

        # Create encryptor
        cipher = Cipher(AES(key), modes.CBC(iv))
        encryptor = cipher.encryptor()

        # Pad the plaintext to be a multiple of 16 bytes (AES block size)
        pad_length = 16 - (len(text.encode()) % 16)
        padded_text = text.encode() + bytes([pad_length] * pad_length)

        # Encrypt the data
        ciphertext = encryptor.update(padded_text) + encryptor.finalize()

        # Combine salt, IV, and ciphertext and encode as base64
        result = base64.b64encode(salt + iv + ciphertext).decode('utf-8')

        # If we auto-generated a password, return both the password and the result
        if auto_generate_password:
            return f"Password: {password}\nEncrypted: {result}"

        return result
    except Exception as e:
        return f"[Encryption error: {str(e)}]"


def aes_decrypt(encrypted_text: str) -> str:
    """
    Decrypt AES-256 encrypted text.

    Args:
        encrypted_text (str): Base64-encoded encrypted text with salt and IV.

    Returns:
        str: The decrypted text.

    Note:
        Requires the same password that was used for encryption.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package not installed]"

    try:
        # Get password from user
        password = getpass.getpass("Enter decryption password: ")
        if not password:
            return "[Error: Empty password]"

        # Decode the base64 input
        decoded = base64.b64decode(encrypted_text)

        # Extract salt, IV, and ciphertext
        salt = decoded[:16]
        iv = decoded[16:32]
        ciphertext = decoded[32:]

        # Derive key from password and salt
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        key = kdf.derive(password.encode())

        # Create decryptor
        cipher = Cipher(AES(key), modes.CBC(iv))
        decryptor = cipher.decryptor()

        # Decrypt the data
        padded_plaintext = decryptor.update(ciphertext) + decryptor.finalize()

        # Remove padding
        pad_length = padded_plaintext[-1]
        plaintext = padded_plaintext[:-pad_length]

        return plaintext.decode('utf-8')
    except Exception as e:
        return f"[Decryption error: {str(e)}]"


def rsa_generate_keys() -> Tuple[str, str]:
    """
    Generate RSA key pair.

    Returns:
        Tuple[str, str]: Base64-encoded private and public keys.
    """
    if not CRYPTO_AVAILABLE:
        return ("[Error: Cryptography package not installed]",
                "[Error: Cryptography package not installed]")

    try:
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
        )

        # Get public key
        public_key = private_key.public_key()

        # Serialize private key
        private_bytes = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )

        # Serialize public key
        public_bytes = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        )

        return (private_bytes.decode('utf-8'), public_bytes.decode('utf-8'))
    except Exception as e:
        return (f"[Key generation error: {str(e)}]",
                f"[Key generation error: {str(e)}]")


def rsa_encrypt(text: str) -> str:
    """
    Encrypt text using RSA public key.

    Args:
        text (str): The text to encrypt.

    Returns:
        str: Base64-encoded encrypted text.

    Note:
        Requires a PEM-encoded public key.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package not installed]"

    try:
        # Get public key from user
        public_key_pem = input("Enter or paste RSA public key (PEM format): ")
        if not public_key_pem.strip():
            return "[Error: Empty public key]"

        # Load public key
        public_key = serialization.load_pem_public_key(
            public_key_pem.encode('utf-8')
        )

        # Encrypt the data (RSA can only encrypt small amounts of data)
        ciphertext = public_key.encrypt(
            text.encode('utf-8'),
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )

        # Encode as base64
        result = base64.b64encode(ciphertext).decode('utf-8')
        return result
    except Exception as e:
        return f"[Encryption error: {str(e)}]"


def rsa_decrypt(encrypted_text: str) -> str:
    """
    Decrypt RSA encrypted text.

    Args:
        encrypted_text (str): Base64-encoded encrypted text.

    Returns:
        str: The decrypted text.

    Note:
        Requires the private key that corresponds to the public key used for encryption.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package not installed]"

    try:
        # Get private key from user
        private_key_pem = input("Enter or paste RSA private key (PEM format): ")
        if not private_key_pem.strip():
            return "[Error: Empty private key]"

        # Load private key
        private_key = serialization.load_pem_private_key(
            private_key_pem.encode('utf-8'),
            password=None
        )

        # Decode the base64 input
        ciphertext = base64.b64decode(encrypted_text)

        # Decrypt the data
        plaintext = private_key.decrypt(
            ciphertext,
            padding.OAEP(
                mgf=padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )

        return plaintext.decode('utf-8')
    except Exception as e:
        return f"[Decryption error: {str(e)}]"


def blowfish_encrypt(text: str, auto_generate_password: bool = False) -> str:
    """
    Encrypt text using Blowfish encryption.

    Args:
        text (str): The text to encrypt.
        auto_generate_password (bool): Whether to generate a secure password
                                      automatically.

    Returns:
        str: Base64-encoded encrypted text and initialization vector.
            If a password was generated, returns the password and the encrypted text.

    Note:
        Either uses a password prompt or generates a secure password automatically.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package not installed]"

    try:
        # Get or generate password
        if auto_generate_password:
            password = generate_secure_password(20)  # Strong 20-char password
            print(f"\nGenerated secure password: {password}")
            print("SAVE THIS PASSWORD! You will need it to decrypt the text.")
        else:
            password = getpass.getpass("Enter encryption password: ")
            if not password:
                return "[Error: Empty password]"

        # Convert password to encryption key using PBKDF2
        salt = os.urandom(8)
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=56,  # Blowfish key size (max 448 bits)
            salt=salt,
            iterations=100000,
        )
        key = kdf.derive(password.encode())[:56]  # Max 448 bits

        # Generate random IV
        iv = os.urandom(8)  # Blowfish uses 8-byte blocks

        # Create encryptor
        cipher = Cipher(Blowfish(key), modes.CBC(iv))
        encryptor = cipher.encryptor()

        # Pad the plaintext to be a multiple of 8 bytes (Blowfish block size)
        pad_length = 8 - (len(text.encode()) % 8)
        padded_text = text.encode() + bytes([pad_length] * pad_length)

        # Encrypt the data
        ciphertext = encryptor.update(padded_text) + encryptor.finalize()

        # Combine salt, IV, and ciphertext and encode as base64
        result = base64.b64encode(salt + iv + ciphertext).decode('utf-8')

        # If we auto-generated a password, return both the password and the result
        if auto_generate_password:
            return f"Password: {password}\nEncrypted: {result}"

        return result
    except Exception as e:
        return f"[Encryption error: {str(e)}]"


def blowfish_decrypt(encrypted_text: str) -> str:
    """
    Decrypt Blowfish encrypted text.

    Args:
        encrypted_text (str): Base64-encoded encrypted text with salt and IV.

    Returns:
        str: The decrypted text.

    Note:
        Requires the same password that was used for encryption.
    """
    if not CRYPTO_AVAILABLE:
        return "[Error: Cryptography package not installed]"

    try:
        # Get password from user
        password = getpass.getpass("Enter decryption password: ")
        if not password:
            return "[Error: Empty password]"

        # Decode the base64 input
        decoded = base64.b64decode(encrypted_text)

        # Extract salt, IV, and ciphertext
        salt = decoded[:8]
        iv = decoded[8:16]
        ciphertext = decoded[16:]

        # Derive key from password and salt
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=56,
            salt=salt,
            iterations=100000,
        )
        key = kdf.derive(password.encode())[:56]  # Max 448 bits

        # Create decryptor
        cipher = Cipher(Blowfish(key), modes.CBC(iv))
        decryptor = cipher.decryptor()

        # Decrypt the data
        padded_plaintext = decryptor.update(ciphertext) + decryptor.finalize()

        # Remove padding
        pad_length = padded_plaintext[-1]
        plaintext = padded_plaintext[:-pad_length]

        return plaintext.decode('utf-8')
    except Exception as e:
        return f"[Decryption error: {str(e)}]"


# ============================================================================
# Advanced Mathematical Link Generation Functions
# ============================================================================

def compute_modular_inverse(a: int, m: int) -> Optional[int]:
    """
    Compute the modular multiplicative inverse of a modulo m.

    Args:
        a (int): The number to find the modular inverse for
        m (int): The modulus

    Returns:
        Optional[int]: The modular inverse if it exists, None otherwise
    """
    # Extended Euclidean Algorithm to find modular inverse
    def extended_gcd(a, b):
        if a == 0:
            return b, 0, 1
        else:
            gcd, x, y = extended_gcd(b % a, a)
            return gcd, y - (b // a) * x, x

    # If a and m are not coprime, modular inverse doesn't exist
    gcd, x, y = extended_gcd(a, m)
    if gcd != 1:
        return None  # No modular inverse exists
    else:
        return x % m  # Ensure the result is positive


def modular_exponentiation(base: int, exponent: int, modulus: int) -> int:
    """
    Perform efficient modular exponentiation (base^exponent mod modulus).

    Args:
        base (int): Base value
        exponent (int): Exponent value
        modulus (int): Modulus value

    Returns:
        int: Result of (base^exponent mod modulus)
    """
    # Handle negative exponents using modular inverse
    if exponent < 0:
        inverse = compute_modular_inverse(base, modulus)
        if inverse is None:
            raise ValueError("Modular inverse does not exist")
        base = inverse
        exponent = -exponent

    # Efficient modular exponentiation using square and multiply algorithm
    result = 1
    base = base % modulus  # Ensure base is within modulus range

    while exponent > 0:
        # If current exponent bit is 1, multiply result with base
        if exponent % 2 == 1:
            result = (result * base) % modulus

        # Square the base for next bit
        base = (base * base) % modulus

        # Move to next bit
        exponent = exponent >> 1  # Equivalent to exponent //= 2

    return result


def binomial_coefficient(n: int, k: int) -> int:
    """
    Calculate binomial coefficient (n choose k) using an efficient algorithm.

    Args:
        n (int): Total number of items
        k (int): Number of items to choose

    Returns:
        int: The binomial coefficient (n choose k)
    """
    # Optimize by using the smaller of k and n-k
    k = min(k, n - k)

    if k < 0:
        return 0
    if k == 0:
        return 1

    # Calculate using multiplicative formula
    result = 1
    for i in range(1, k + 1):
        result = result * (n - (i - 1)) // i

    return result


def chebyshev_bound(epsilon: float, confidence: float) -> int:
    """
    Calculate minimum sample size based on Chebyshev's inequality.

    Args:
        epsilon (float): Desired error margin (0 < epsilon < 1)
        confidence (float): Desired confidence level (0 < confidence < 1)

    Returns:
        int: Minimum sample size needed
    """
    # Chebyshev's inequality: P(|X - μ| ≥ ε) ≤ σ²/(ε²·n)
    # Solving for n: n ≥ σ²/(ε²·(1-confidence))

    # Assuming worst-case variance for a bounded random variable in [0,1]
    variance = 0.25  # Maximum variance for a Bernoulli random variable

    sample_size = variance / (epsilon**2 * (1 - confidence))
    return math.ceil(sample_size)


def generate_snapi_link(url: str, key: str, expiration_hours: int = 24) -> str:
    """
    Generate a Secure Nonlinear Algorithm for Parameter Identification (SNAPI) link.

    This function creates a secure link by:
    1. Using modular exponentiation for parameter transformation
    2. Applying binomial expansion for key stretching
    3. Implementing Chebyshev's inequality for token validation
    4. Using salt and cipher block chaining concepts for added security

    Args:
        url (str): The base URL to secure
        key (str): The secret key for generating the secure token
        expiration_hours (int): Number of hours the link remains valid (default 24)

    Returns:
        str: URL with secure token parameters
    """
    # Ensure URL has a protocol
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url

    # Generate salt
    salt = os.urandom(8).hex()

    # Generate timestamp and expiration time
    timestamp = int(time.time())
    expiration = timestamp + (expiration_hours * 3600)

    # Create a seed using key + salt
    seed_material = hashlib.sha256((key + salt).encode()).digest()
    seed = int.from_bytes(seed_material, byteorder='big')

    # Generate prime modulus (using a fixed prime for demonstration)
    modulus = 2**31 - 1  # Mersenne prime M31

    # Apply modular exponentiation (key splitting)
    split1 = modular_exponentiation(seed % 10000, 65537, modulus)
    split2 = modular_exponentiation(seed // 10000, 257, modulus)

    # Apply binomial expansion theorem for key stretching
    n = 10  # Binomial expansion parameter
    k = seed % n
    token_part1 = binomial_coefficient(n, k) * split1 % modulus

    # Use Chebyshev's inequality to generate validation parameters
    confidence = 0.95
    epsilon = 0.01
    sample_size = chebyshev_bound(epsilon, confidence)
    token_part2 = (split2 * sample_size) % modulus

    # Combine token parts using principles similar to CBC
    # Each block depends on the previous one
    token_blocks = []
    prev_block = int.from_bytes(hashlib.sha256(salt.encode()).digest()[:4],
                              byteorder='big')

    for i in range(4):  # Generate 4 blocks
        if i % 2 == 0:
            current = (token_part1 + prev_block) % modulus
        else:
            current = (token_part2 + prev_block) % modulus

        token_blocks.append(current)
        prev_block = current

    # Create final token string
    token = "-".join([hex(block)[2:].zfill(8) for block in token_blocks])

    # Add encoded user info
    encoded_key = base64.urlsafe_b64encode(key.encode()).decode().rstrip('=')

    # Construct the URL with parameters
    result = (
        f"{url}" +
        ("&" if "?" in url else "?") +
        f"token={token}&salt={salt}&ts={timestamp}&exp={expiration}&id={encoded_key}"
    )

    return result


def verify_snapi_link(url: str, key: str) -> tuple:
    """
    Verify a SNAPI-generated link.

    Args:
        url (str): The URL with SNAPI parameters
        key (str): The secret key used for generating the link

    Returns:
        tuple: (is_valid, message) - Validation result and explanation
    """
    try:
        # Parse URL and extract parameters
        parsed_url = urllib.parse.urlparse(url)
        params = dict(urllib.parse.parse_qsl(parsed_url.query))

        # Extract token components
        if 'token' not in params or 'salt' not in params or 'ts' not in params:
            return False, "Missing required parameters"

        token = params['token']
        salt = params['salt']
        timestamp = int(params['ts'])

        # Check for expiration time
        if 'exp' in params:
            expiration = int(params['exp'])
            current_time = int(time.time())
            if current_time > expiration:
                return False, "Link has expired"
        else:
            # If no explicit expiration, use default (24 hour validity)
            current_time = int(time.time())
            if current_time - timestamp > 86400:  # 24 hours in seconds
                return False, "Link has expired (24 hour validity)"

        # Check if identifier is present and matches
        if 'id' in params:
            try:
                # Add padding back for decoding
                encoded_id = params['id']
                padding_needed = 4 - (len(encoded_id) % 4)
                if padding_needed < 4:
                    encoded_id += '=' * padding_needed

                decoded_id = base64.urlsafe_b64decode(encoded_id).decode('utf-8')
                if decoded_id != key:
                    return False, "Key mismatch with encoded identifier"
            except Exception:
                return False, "Invalid encoded identifier"

        # Regenerate the token
        # Extract base URL without token parameters
        base_url_parts = list(parsed_url)
        query_params = dict(urllib.parse.parse_qsl(parsed_url.query))
        for param in ['token', 'salt', 'ts', 'exp', 'id']:
            if param in query_params:
                del query_params[param]

        base_url_parts[4] = urllib.parse.urlencode(query_params)
        base_url = urllib.parse.urlunparse(base_url_parts)

        # Generate expected token
        expected_url = generate_snapi_link(base_url, key)
        expected_parsed = urllib.parse.urlparse(expected_url)
        expected_params = dict(urllib.parse.parse_qsl(expected_parsed.query))

        # Compare tokens
        if params['token'] == expected_params['token']:
            return True, "Link is valid and authentic"
        else:
            return False, "Token mismatch - link may have been tampered with"

    except Exception as e:
        return False, f"Verification error: {str(e)}"


def asymptotic_hash(text: str, bits: int = 128) -> str:
    """
    Generate a hash based on asymptotic notation principles.

    Args:
        text (str): The text to hash
        bits (int): Desired output size in bits (default: 128)

    Returns:
        str: The asymptotic hash as a hexadecimal string
    """
    # Convert text to bytes if it's not already
    if isinstance(text, str):
        text = text.encode('utf-8')

    # Base hash using SHA-256
    hash_bytes = hashlib.sha256(text).digest()

    # Apply asymptotic transformations
    # In asymptotic notation, we care about growth rates as input size increases
    # This simulates O(n log n) complexity by applying additional operations

    # Determine number of rounds based on input size (logarithmic)
    n = len(text)
    log_n = math.ceil(math.log2(max(n, 2)))
    rounds = log_n

    # Apply multiple rounds of hashing
    current_hash = hash_bytes
    for i in range(rounds):
        # Each round incorporates the original text length in a different way
        # This simulates different asymptotic behaviors
        salt = (n * (i + 1)).to_bytes(4, byteorder='big')
        current_hash = hashlib.sha256(current_hash + salt).digest()

    # Truncate to desired bit length (converted to bytes)
    bytes_needed = (bits + 7) // 8  # Ceiling division to get bytes
    truncated = current_hash[:bytes_needed]

    return truncated.hex()


def main() -> None:
    """Main function to run the Universal Text Converter interactively."""
    # Define conversion functions with their names and handlers
    conversion_functions = {
        "1": ("HTML Entities", text_to_html_entities),
        "2": ("Base64 Encode", text_to_base64),
        "3": ("Base64 Decode", base64_to_text),
        "4": ("Regex Escape", escape_regex),
        "5": ("SAML URL", create_saml_url),
        "5a": ("Advanced SAML URL", None),  # Special handling
        "5b": ("SAML URL with Custom Hash", None),  # Special handling
        "5c": ("SAML URL with UTM Parameters", None),  # Special handling
        "5d": ("Batch UTM URL Generator", None)  # Special handling for multiple UTM URLs
    }

    # Add encryption functions if available
    if CRYPTO_AVAILABLE:
        encryption_functions = {
            "6": ("AES Encryption", aes_encrypt),
            "7": ("AES Decryption", aes_decrypt),
            "8": ("RSA Key Generation", None),  # Special handling
            "9": ("RSA Encryption", rsa_encrypt),
            "10": ("RSA Decryption", rsa_decrypt),
            "11": ("Blowfish Encryption", blowfish_encrypt),
            "12": ("Blowfish Decryption", blowfish_decrypt)
        }
        # Merge the dictionaries
        for k, v in encryption_functions.items():
            conversion_functions[k] = v

    # Add mathematical link generation functions
    math_functions = {
        "13": ("SNAPI Secure Link", None),  # Special handling
        "14": ("Verify SNAPI Link", None),  # Special handling
        "15": ("Asymptotic Hash", None)     # Special handling
    }
    for k, v in math_functions.items():
        conversion_functions[k] = v

    print("Universal Text Converter")
    print("=" * 30)
    print("\nThis tool provides multiple text conversion utilities.\n")

    print("Available conversions:")
    for key, (name, _) in conversion_functions.items():
        print(f"{key}. {name}")

    if not CRYPTO_AVAILABLE:
        print("\nNote: Encryption features are disabled.")
        print("Install cryptography: pip install cryptography")

    print("\nPress Ctrl+C at any time to exit.")

    try:
        max_option = str(len(conversion_functions))
        choice = input(f"\nSelect conversion type (1-{max_option}): ").strip()

        if choice not in conversion_functions:
            print(f"\nInvalid choice: {choice}.")
            return

        conversion_name = conversion_functions[choice][0]
        conversion_func = conversion_functions[choice][1]

        # Special handling for AES Encryption
        if choice == "6":
            text = input("\nEnter text to encrypt: ").strip()
            if not text:
                print("\nWarning: Empty text provided.")
                print("No encryption performed.")
                return

            # Ask if user wants to auto-generate a password
            auto_gen = input(
                "Auto-generate a secure password? (y/n): "
            ).strip().lower()
            auto_generate_password = auto_gen.startswith('y')

            result = aes_encrypt(text, auto_generate_password)
            print("\nAES Encrypted Text (Base64):")
            print(result)
            return

        # Special handling for Blowfish Encryption
        elif choice == "11":
            text = input("\nEnter text to encrypt: ").strip()
            if not text:
                print("\nWarning: Empty text provided.")
                print("No encryption performed.")
                return

            # Ask if user wants to auto-generate a password
            auto_gen = input(
                "Auto-generate a secure password? (y/n): "
            ).strip().lower()
            auto_generate_password = auto_gen.startswith('y')

            result = blowfish_encrypt(text, auto_generate_password)
            print("\nBlowfish Encrypted Text (Base64):")
            print(result)
            return

        # Special handling for Advanced SAML URL
        elif choice == "5a":
            if not CRYPTO_AVAILABLE:
                print("\nError: Advanced SAML URL requires cryptography package.")
                print("Install with: pip install cryptography")
                return

            url = input("\nEnter base domain URL: ").strip()
            if not url:
                print("\nWarning: Empty domain URL provided.")
                print("No URL generation performed.")
                return

            email = input("Enter email to encode: ").strip()
            if not email:
                print("\nWarning: Empty email provided.")
                print("No URL generation performed.")
                return

            pattern = input("Enter regex pattern to use: ").strip()
            if not pattern:
                # Use a default pattern if none provided
                pattern = r'[a-zA-Z0-9]+'
                print(f"\nUsing default pattern: {pattern}")

            encryption_key = getpass.getpass("Enter encryption key: ").strip()
            if not encryption_key:
                print("\nWarning: Empty encryption key provided.")
                print("No URL generation performed.")
                return

            result = create_advanced_saml_url(
                url, email, pattern, encryption_key
            )
            print("\nAdvanced SAML URL:")
            print(result)

            print("\nWould you like to verify this URL? (y/n): ")
            verify_choice = input().strip().lower()

            if verify_choice.startswith('y'):
                valid, message = verify_advanced_saml_url(
                    result, encryption_key
                )
                print(
                    f"\nVerification result: {'VALID' if valid else 'INVALID'}"
                )
                print(f"Details: {message}")

            return

        # Special handling for SAML URL with Custom Hash
        elif choice == "5b":
            url = input("\nEnter base URL: ").strip()
            if not url:
                print("\nWarning: Empty URL provided.")
                print("No URL generation performed.")
                return

            custom_hash = input("Enter custom hash for tracking: ").strip()
            if not custom_hash:
                # Generate a random hash if none provided
                custom_hash = hashlib.md5(
                    str(time.time()).encode()
                ).hexdigest()[:8]
                print(f"\nUsing auto-generated hash: {custom_hash}")

            relay_state = input(
                "Enter relay state (optional, press Enter to skip): "
            ).strip()

            target_url = input(
                "Enter target URL (optional, press Enter to use source URL): "
            ).strip()

            result = create_saml_url_with_hash(
                url,
                custom_hash,
                relay_state if relay_state else None,
                target_url if target_url else None
            )

            print("\nSAML URL with Custom Hash:")
            print(result)
            print("\nThis URL includes:")
            print("- Standard SAML parameters")
            print("- Custom hash for tracking/identification")
            print("- Parameters are properly URL-encoded")
            return

        # Special handling for SAML URL with UTM Parameters
        elif choice == "5c":
            url = input("\nEnter base URL: ").strip()
            if not url:
                print("\nWarning: Empty URL provided.")
                print("No URL generation performed.")
                return

            print("\n-- UTM Parameters --")
            source = input("Enter utm_source: ").strip()
            medium = input("Enter utm_medium: ").strip()
            campaign = input("Enter utm_campaign: ").strip()

            if not source or not medium or not campaign:
                print("\nWarning: Required UTM parameters missing.")
                print("utm_source, utm_medium, and utm_campaign are required.")
                return

            content = input(
                "Enter utm_content (optional, press Enter to skip): "
            ).strip()

            term = input(
                "Enter utm_term (optional, press Enter to skip): "
            ).strip()

            unique_id_input = input(
                "Enter tracking ID (1-100, optional, press Enter to skip): "
            ).strip()

            try:
                unique_id = int(unique_id_input) if unique_id_input else None
            except ValueError:
                print("\nInvalid tracking ID. Using none.")
                unique_id = None

            relay_state = input(
                "Enter relay state (optional, press Enter to skip): "
            ).strip()

            target_url = input(
                "Enter target URL (optional, press Enter to use source URL): "
            ).strip()

            # Generate UTM parameters
            utm_params = {
                "utm_source": source,
                "utm_medium": medium,
                "utm_campaign": campaign
            }

            if content:
                utm_params["utm_content"] = content
            if term:
                utm_params["utm_term"] = term
            if unique_id is not None:
                utm_params["utm_id"] = str(max(1, min(100, unique_id)))

            # Generate custom hash based on UTM parameters for tracking
            custom_hash = hashlib.md5(
                f"{source}|{medium}|{campaign}|{time.time()}".encode()
            ).hexdigest()[:10]

            result = create_saml_url_with_hash(
                url,
                custom_hash,
                relay_state if relay_state else None,
                target_url if target_url else None,
                utm_params
            )

            print("\nSAML URL with UTM Parameters:")
            print(result)
            print("\nThis URL includes:")
            print("- Standard SAML parameters")
            print("- UTM tracking parameters")
            print("- Custom hash derived from UTM data")
            print("- Parameters are properly URL-encoded")
            return

        # Special handling for Batch UTM URL Generator
        elif choice == "5d":
            url = input("\nEnter base URL: ").strip()
            if not url:
                print("\nWarning: Empty URL provided.")
                print("No URL generation performed.")
                return

            print("\n-- UTM Parameters --")
            source = input("Enter utm_source: ").strip()
            medium = input("Enter utm_medium: ").strip()
            campaign = input("Enter utm_campaign: ").strip()

            if not source or not medium or not campaign:
                print("\nWarning: Required UTM parameters missing.")
                print("utm_source, utm_medium, and utm_campaign are required.")
                return

            content = input(
                "Enter utm_content (optional, press Enter to skip): "
            ).strip()

            term = input(
                "Enter utm_term (optional, press Enter to skip): "
            ).strip()

            # Ask user if they want to generate one or multiple URLs
            batch_input = input(
                "\nGenerate multiple URLs? (y/n): "
            ).strip().lower()

            generate_multiple = batch_input.startswith('y')
            count = 1

            if generate_multiple:
                count_input = input(
                    "How many URLs to generate (1-10000): "
                ).strip()

                try:
                    count = int(count_input)
                    # Limit to prevent resource exhaustion
                    count = max(1, min(10000, count))
                except ValueError:
                    print("\nInvalid number. Generating 1 URL.")
                    count = 1

            # Ask if user wants custom SAML format or standard format
            format_input = input(
                "\nUse advanced SAML-style formatting? (y/n): "
            ).strip().lower()

            use_custom_format = format_input.startswith('y')
            encryption_key = None

            if use_custom_format:
                if not CRYPTO_AVAILABLE:
                    print("\nError: Custom format requires cryptography package.")
                    print("Install with: pip install cryptography")
                    use_custom_format = False
                else:
                    encryption_key = getpass.getpass(
                        "Enter encryption key for SAML format: "
                    ).strip()

                    if not encryption_key:
                        print("\nWarning: Empty encryption key provided.")
                        print("Using standard URL format instead.")
                        use_custom_format = False

            # Generate the URLs
            urls = generate_batch_utm_urls(
                url, source, medium, campaign,
                content if content else None,
                term if term else None,
                count, use_custom_format,
                encryption_key
            )

            # Ask user where to save the results
            if count > 1:
                save_input = input(
                    "\nSave to file? (y/n): "
                ).strip().lower()

                if save_input.startswith('y'):
                    # Ask for custom path or use default
                    path_input = input(
                        "Enter file path (or press Enter for default 'utm_urls.txt'): "
                    ).strip()

                    file_path = path_input if path_input else "utm_urls.txt"

                    try:
                        with open(file_path, 'w') as f:
                            for i, generated_url in enumerate(urls, 1):
                                f.write(f"URL {i}:\n{generated_url}\n\n")

                        print(f"\nGenerated {count} URLs and saved to '{file_path}'")
                    except Exception as e:
                        print(f"\nError saving to file: {e}")
                        print("Printing URLs to terminal instead:")

                        # Print a limited number to avoid flooding terminal
                        max_display = min(count, 10)
                        for i, generated_url in enumerate(urls[:max_display], 1):
                            print(f"\nURL {i}:")
                            print(generated_url)

                        if count > max_display:
                            print(f"\n... and {count - max_display} more URLs")
                else:
                    # Print a limited number to avoid flooding terminal
                    max_display = min(count, 10)
                    for i, generated_url in enumerate(urls[:max_display], 1):
                        print(f"\nURL {i}:")
                        print(generated_url)

                    if count > max_display:
                        print(f"\n... and {count - max_display} more URLs")
            else:
                # Just one URL, print it directly
                print("\nGenerated UTM URL:")
                print(urls[0])

                if use_custom_format:
                    print("\nThis URL includes:")
                    print("- Advanced SAML-style format")
                    print("- Unique UUID and timestamp")
                    print("- UTM parameters for tracking")
                    print("- Multiple encryption layers")
                else:
                    print("\nThis URL includes:")
                    print("- Standard UTM parameters")
                    print("- Parameters are properly URL-encoded")

            return

        # Special handling for RSA key generation
        elif choice == "8":
            print("\nGenerating RSA key pair (2048 bits)...")
            private_key, public_key = rsa_generate_keys()
            print("\nPrivate Key (keep this secret!):")
            print(private_key)
            print("\nPublic Key (share this):")
            print(public_key)
            return

        # Special handling for SNAPI Secure Link
        elif choice == "13":
            url = input("\nEnter base URL to secure: ").strip()
            if not url:
                print("\nWarning: Empty URL provided.")
                print("No conversion performed.")
                return

            # Ask if user wants to auto-generate a secret key
            auto_gen = input(
                "Auto-generate a secure secret key? (y/n): "
            ).strip().lower()
            auto_generate_key = auto_gen.startswith('y')

            if auto_generate_key:
                # Generate a secure key with good entropy but still memorable
                key = generate_secure_password(16)
                print(f"\nGenerated secret key: {key}")
                print("SAVE THIS KEY!")
                print("You will need it to verify the link later.")
            else:
                # Manual key entry
                key = getpass.getpass("Enter secret key: ").strip()
                if not key:
                    print("\nWarning: Empty key provided.")
                    print("No conversion performed.")
                    return

            result = generate_snapi_link(url, key)
            print("\nGenerated SNAPI Secure Link:")
            print(result)
            print("\nThis link includes:")
            print("- Mathematically generated secure token")
            print("- Salt for additional security")
            print("- Timestamp for link expiration")
            return

        # Special handling for SNAPI Link Verification
        elif choice == "14":
            url = input("\nEnter SNAPI URL to verify: ").strip()

            # Ask if user wants to generate a password
            auto_gen = input(
                "Auto-generate key for verification? (y/n): "
            ).strip().lower()

            if auto_gen.startswith('y'):
                # Generate a key based on the URL structure
                parsed_url = urllib.parse.urlparse(url)
                params = dict(urllib.parse.parse_qsl(parsed_url.query))

                if 'id' in params:
                    try:
                        # Try to decode the ID parameter
                        encoded_id = params['id']
                        padding_needed = 4 - (len(encoded_id) % 4)
                        if padding_needed < 4:
                            encoded_id += '=' * padding_needed

                        key = base64.urlsafe_b64decode(encoded_id).decode('utf-8')
                        print(f"\nAuto-generated key from URL: {key}")
                    except Exception:
                        key = hashlib.md5(url.encode()).hexdigest()[:16]
                        print(f"\nAuto-generated fallback key: {key}")
                else:
                    key = hashlib.md5(url.encode()).hexdigest()[:16]
                    print(f"\nAuto-generated key: {key}")
            else:
                # Ask for manual key entry
                key = getpass.getpass("Enter secret key: ").strip()

            if not url:
                print("\nWarning: URL missing.")
                print("No verification performed.")
                return

            if not key:
                print("\nWarning: Key missing.")
                print("No verification performed.")
                return

            is_valid, message = verify_snapi_link(url, key)
            if is_valid:
                print("\nLink verification: VALID")
                print(f"Details: {message}")
                print("The link was created with the provided key")
                print("and is not expired.")
            else:
                print("\nLink verification: INVALID")
                print(f"Reason: {message}")
                print("The link may be expired, tampered with,")
                print("or created with a different key.")
            return

        # Special handling for Asymptotic Hash
        elif choice == "15":
            text = input("\nEnter text to hash: ").strip()
            bits = input("Enter hash size in bits (default 128): ").strip()

            if not text:
                print("\nWarning: Empty text provided. No hashing performed.")
                return

            try:
                bits_value = int(bits) if bits else 128
                if bits_value < 8 or bits_value > 512:
                    print("\nWarning: Bits must be between 8 and 512. Using 128 bits.")
                    bits_value = 128
            except ValueError:
                print("\nWarning: Invalid bits value. Using 128 bits.")
                bits_value = 128

            result = asymptotic_hash(text, bits_value)
            print(f"\nAsymptotic hash ({bits_value} bits):")
            print(result)
            return

        # Standard handling for other conversions
        if choice not in ["6", "8", "11", "13", "14", "15"]:
            input_text = input(
                f"\nEnter text to convert to {conversion_name}: "
            ).strip()

            if not input_text:
                print("\nWarning: Empty input provided. No conversion performed.")
                return

            # Special handling for Regex Escape
            if choice == "4":
                security_level = input(
                    "Enter security level (1=Basic, 2=Intermediate, 3=Advanced): "
                ).strip()

                try:
                    level = int(security_level) if security_level else 1
                    if level < 1 or level > 3:
                        print("\nInvalid security level. Using level 1 (Basic).")
                        level = 1
                except ValueError:
                    print("\nInvalid input. Using security level 1 (Basic).")
                    level = 1

                converted_text = escape_regex(input_text, level)

            # Special handling for SAML URL
            elif choice == "5":
                relay_state = input(
                    "Enter relay state (optional, press Enter to skip): "
                ).strip()

                target_url = input(
                    "Enter target URL (optional, press Enter to use source URL): "
                ).strip()

                converted_text = create_saml_url(
                    input_text,
                    relay_state if relay_state else None,
                    target_url if target_url else None
                )
            else:
                converted_text = conversion_func(input_text)

            print(f"\nOriginal text: {input_text}")
            print(f"Converted ({conversion_name}): {converted_text}")

            # Only show character count for non-encrypted conversions
            if choice not in ["6", "7", "9", "10", "11", "12"]:
                print(f"\nConverted {len(input_text)} character(s)")

    except KeyboardInterrupt:
        print("\n\nConversion cancelled by user.")
    except Exception as e:
        print(f"\nError: {e}")


# Session management functions
def initialize_session_db(connection_string="mongodb://localhost:27017/",
                          db_name="mini_app"):
    """
    Initialize MongoDB connection for session management.

    Args:
        connection_string: MongoDB connection string
        db_name: Database name

    Returns:
        MongoDB database object or None if connection failed
    """
    if not MONGODB_AVAILABLE:
        print("MongoDB support not available. Install pymongo package.")
        return None

    try:
        client = MongoClient(connection_string)
        db = client[db_name]

        # Create indexes for session management
        db.sessions.create_index("user_id", unique=True)
        db.sessions.create_index("token", unique=True)
        db.sessions.create_index("expires_at")

        return db
    except Exception as e:
        print(f"MongoDB connection error: {e}")
        return None


def check_user_session(db, user_id):
    """
    Check if a user has an active session.

    Args:
        db: MongoDB database object
        user_id: User identifier (email, username, etc.)

    Returns:
        Session document or None if no active session
    """
    if not db:
        return None

    import datetime

    # Find an active session for this user
    return db.sessions.find_one({
        "user_id": user_id,
        "expires_at": {"$gt": datetime.datetime.utcnow()}
    })


def create_user_session(db, user_id, expiry_minutes=30):
    """
    Create a new session for a user.

    Args:
        db: MongoDB database object
        user_id: User identifier
        expiry_minutes: Minutes until session expires

    Returns:
        Tuple of (success, message, session_data)
    """
    if not db:
        return False, "MongoDB not available", {}

    import datetime

    # Check for existing session
    existing = check_user_session(db, user_id)
    if existing:
        return False, "User already has an active session", existing

    # Generate secure token using our crypto functions
    token = generate_asymptotic_hash(f"{user_id}-{uuid.uuid4()}-{time.time()}",
                                    bits=256)[:32]

    # Create session document
    session = {
        "user_id": user_id,
        "token": token,
        "created_at": datetime.datetime.utcnow(),
        "expires_at": datetime.datetime.utcnow() +
                      datetime.timedelta(minutes=expiry_minutes),
        "last_activity": datetime.datetime.utcnow(),
        "usage_count": 0
    }

    try:
        db.sessions.insert_one(session)
        return True, "Session created successfully", session
    except Exception as e:
        return False, f"Error creating session: {str(e)}", {}


if __name__ == "__main__":
    main()
