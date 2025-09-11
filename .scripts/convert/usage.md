# Universal Text Converter Usage Guide

This document provides comprehensive usage instructions for the Universal Text Converter tool, a powerful utility for text conversion, encryption, and secure link generation.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Available Functions](#available-functions)
- [Command Examples](#command-examples)
- [Security Features](#security-features)
- [Use Cases](#use-cases)
- [Quick Reference](#quick-reference)

## Basic Usage

Run the script directly from the command line:

```bash
python3 convert.py
```

This will launch the interactive menu where you can select conversion options.

## Available Functions

The Universal Text Converter offers the following capabilities:

### Text Conversion

1. HTML Entity conversion
2. Base64 Encoding
3. Base64 Decoding
4. Regex Pattern Escaping

### Secure URL Generation

1. SAML URL
   - 5a. Advanced SAML URL
   - 5b. SAML URL with Custom Hash
   - 5c. SAML URL with UTM Parameters
   - 5d. Batch UTM URL Generator

### Encryption

1. AES Encryption
2. AES Decryption
3. RSA Key Generation
4. RSA Encryption
5. RSA Decryption
6. Blowfish Encryption
7. Blowfish Decryption

### Mathematical Link Generation

1. SNAPI Secure Link
2. Verify SNAPI Link
3. Asymptotic Hash

## Command Examples

### Terminal Command Usage

You can run these commands directly from your terminal to quickly use the conversion functions:

```bash
# Generate a SAML URL with custom hash
python3 -c "import convert as c; print(c.create_saml_url_with_hash('www.example.com', '442ace6c'))"
# Output: https://www.example.com?SAMLRequest=U0FNTFJlcXVlc3QgZm9yOiBodHRwczovL3d3dy5leGFtcGxlLmNvbXxoYXNoOjQ0MmFjZTZjfHRzOjE3NTcyMDkzMzI%3D&UserHash=5dded28855af515a

# Generate a SNAPI secure link
python3 -c "import convert as c; print(c.generate_snapi_link('www.example.com', 'example@example.com'))"
# Output: https://www.example.com?token=6fa841ee-5fa4bc97-46021a03-35fe94ac&salt=eef0df673c328896&ts=1757209345&exp=1757295745&id=ZXhhbXBsZUBleGFtcGxlLmNvbQ

# Generate a single UTM URL
python3 -c "import convert as c; result = c.generate_batch_utm_urls('www.example.com', 'test', 'email', 'sept2023', count=1); print(result[0])"
# Output: https://www.example.com?utm_source=test&utm_medium=email&utm_campaign=sept2023&utm_id=1

# Generate multiple UTM URLs and print the first 3
python3 -c "import convert as c; results = c.generate_batch_utm_urls('www.example.com', 'newsletter', 'email', 'fall2025', count=10); [print(f'URL {i+1}: {url}') for i, url in enumerate(results[:3])]"

# Encrypt text with AES (auto-generated password)
python3 -c "import convert as c; result = c.aes_encrypt('My secret message', auto_generate_password=True); print(f'Password: {result[0]}\nEncrypted: {result[1]}')"

# Create advanced SAML URL
python3 -c "import convert as c; print(c.create_advanced_saml_url('www.example.com', 'user@example.com', '[a-zA-Z0-9]+', 'secretkey123'))"

# Generate secure hash
python3 -c "import convert as c; print(c.generate_asymptotic_hash('Important data to hash', bits=256))"

# Verify SNAPI link
python3 -c "import convert as c; result, message = c.verify_snapi_link('https://www.example.com?token=6fa841ee-5fa4bc97-46021a03-35fe94ac&salt=eef0df673c328896&ts=1757209345&exp=1757295745&id=ZXhhbXBsZUBleGFtcGxlLmNvbQ', 'example@example.com'); print(f'Valid: {result}, Message: {message}')"
```

### Python Script Usage

You can use the functions directly in your Python scripts by importing the module:

```python
# Import the module
import convert

# Generate a SAML URL with custom hash
saml_url = convert.create_saml_url_with_hash('www.example.com', '442ace6c')
print(saml_url)
# Output: https://www.example.com?SAMLRequest=U0FNTFJlcXVlc3QgZm9yOiBodHRwczovL3d3dy5leGFtcGxlLmNvbXxoYXNoOjQ0MmFjZTZjfHRzOjE3NTcyMDkzMzI%3D&UserHash=5dded28855af515a

# Generate a SNAPI secure link
snapi_link = convert.generate_snapi_link('www.example.com', 'example@example.com')
print(snapi_link)
# Output: https://www.example.com?token=6fa841ee-5fa4bc97-46021a03-35fe94ac&salt=eef0df673c328896&ts=1757209345&exp=1757295745&id=ZXhhbXBsZUBleGFtcGxlLmNvbQ

# Generate UTM parameters
utm_url = convert.generate_batch_utm_urls('www.example.com', 'test', 'email', 'sept2023', count=1)[0]
print(utm_url)
# Output: https://www.example.com?utm_source=test&utm_medium=email&utm_campaign=sept2023&utm_id=1
```

### Batch Processing

For generating multiple UTM-tagged URLs:

```python
import convert

# Generate 100 UTM URLs
urls = convert.generate_batch_utm_urls(
    'www.example.com',
    'newsletter',
    'email',
    'fall2025',
    content='promo',
    count=100
)

# Save to file
with open('campaign_urls.txt', 'w') as f:
    for i, url in enumerate(urls, 1):
        f.write(f"URL {i}: {url}\n\n")
```

## Security Features

The Universal Text Converter implements advanced security mechanisms:

### SNAPI Link Security

SNAPI (Secure Nonlinear Algorithm for Parameter Identification) links provide:

- **Authentication**: Secure token generation with cryptographic principles
- **Expiration Control**: Links automatically expire after configurable time periods
- **User Identification**: Encoded user identifiers for tracking and personalization
- **Tamper Prevention**: Mathematical verification methods detect link manipulation

### SAML URL Security

SAML URLs implement multi-layered security:

- **Custom Hash Tracking**: Track URL usage with secure hash identifiers
- **Timestamp Validation**: Prevent replay attacks with embedded timestamps
- **Secure Encoding**: Parameters are properly URL-encoded to prevent injection
- **Advanced Format**: Optional custom format with multiple encryption layers

## Use Cases

### Authentication & Authorization

The combination of tokens, salts, and timestamps enables secure user authentication. Tokens can be validated against server records, with timestamps ensuring validity periods.

### Secure Link Sharing

Generate links that can only be used by intended recipients within specific timeframes, perfect for sensitive document sharing or time-limited access grants.

### Marketing Campaign Tracking

UTM parameters with custom identifiers allow precise tracking of marketing campaigns across multiple channels and segments.

### Secure Data Exchange

Encrypt sensitive information for secure transmission using industry-standard algorithms with auto-generated or custom passwords.

### Enterprise SSO Integration

SAML URL functionality supports enterprise Single Sign-On integration with customizable security parameters.

## Efficiency Considerations

- For batch processing of more than 1,000 URLs, consider saving directly to file
- Use auto-generated passwords when possible for better entropy and security
- SNAPI links with security level 2 provide optimal balance between security and performance
- Use the custom format option for UTM URLs only when enhanced security is required

## Quick Reference

### Common Terminal Commands

```bash
# Generate SAML URL with hash
python3 -c "import convert as c; print(c.create_saml_url_with_hash('example.com', '12345'))"

# Generate SNAPI secure link
python3 -c "import convert as c; print(c.generate_snapi_link('example.com', 'user@example.com'))"

# Encrypt with auto-generated password
python3 -c "import convert as c; result = c.aes_encrypt('secret', auto_generate_password=True); print(f'Password: {result[0]}\\nEncrypted: {result[1]}')"

# Batch UTM URL generation (save to file)
python3 -c "import convert as c; urls = c.generate_batch_utm_urls('example.com', 'newsletter', 'email', 'q3campaign', count=10); open('urls.txt', 'w').write('\\n'.join(urls))"
```

### Command Options Reference

| Function        | Key Options                                            | Example                                                                                         |
| --------------- | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| SAML URL        | `custom_hash`, `timestamp`                             | `create_saml_url_with_hash('example.com', '12345', timestamp=True)`                             |
| Advanced SAML   | `user_id`, `format_regex`, `encryption_key`            | `create_advanced_saml_url('example.com', 'user123', '[a-z0-9]+', 'secretkey')`                  |
| UTM URLs        | `source`, `medium`, `campaign`, `content`, `count`     | `generate_batch_utm_urls('example.com', 'fb', 'social', 'winter', content='ad1', count=50)`     |
| SNAPI Link      | `url`, `user_id`, `security_level`, `expiration_hours` | `generate_snapi_link('example.com', 'user@example.com', security_level=2, expiration_hours=48)` |
| AES Encryption  | `text`, `password`, `auto_generate_password`           | `aes_encrypt('message', password=None, auto_generate_password=True)`                            |
| Asymptotic Hash | `data`, `bits`, `iterations`                           | `generate_asymptotic_hash('data', bits=256, iterations=10000)`                                  |
