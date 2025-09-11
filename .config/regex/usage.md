After you've saved the script to /home/cli/git/dotfiles/scripts/regex_toolkit.sh, you'll need to make it executable with the following command:

```
chmod +x /home/cli/git/dotfiles/scripts/regex_toolkit.sh
```

Using the Regex Toolkit Script
Here's a quick guide on how to use this comprehensive regex toolkit:

1. HTTP/URL Utilities

```
# Extract URLs from a file
./regex_toolkit.sh http extract-urls file.txt

# Validate a URL
./regex_toolkit.sh http validate-url https://example.com

# Parse URL into components
./regex_toolkit.sh http parse-url "https://example.com/path?param=value#fragment"

# Extract query parameters
./regex_toolkit.sh http extract-params "https://example.com?id=123&name=test"

# Extract domain from URL
./regex_toolkit.sh http extract-domain "https://subdomain.example.com/path"
```

2. HTML Utilities

```
# Extract specific HTML tags
./regex_toolkit.sh html extract-tags div index.html

# Extract specific HTML attributes
./regex_toolkit.sh html extract-attrs href index.html

# Strip all HTML tags
./regex_toolkit.sh html strip-tags index.html

# Extract all links from HTML
./regex_toolkit.sh html extract-links index.html

# Extract all image sources
./regex_toolkit.sh html extract-images index.html
```

3. Base64 Utilities

```
# Encode text to Base64
./regex_toolkit.sh base64 encode "Hello World"

# Decode Base64 to text
./regex_toolkit.sh base64 decode "SGVsbG8gV29ybGQ="

# Detect Base64 encoded strings in text
./regex_toolkit.sh base64 detect file.txt

# Validate if a string is valid Base64
./regex_toolkit.sh base64 validate "SGVsbG8gV29ybGQ="
```

4. Validation Utilities

```
# Validate email address
./regex_toolkit.sh validate email user@example.com

# Validate phone number
./regex_toolkit.sh validate phone "+1 (123) 456-7890"

# Validate IP address (IPv4 or IPv6)
./regex_toolkit.sh validate ip 192.168.1.1

# Validate date format
./regex_toolkit.sh validate date "2025-09-06"

# Validate credit card number
./regex_toolkit.sh validate credit-card "4111-1111-1111-1111"

# Check password strength
./regex_toolkit.sh validate password "MySecureP@ssw0rd"

# Validate UUID
./regex_toolkit.sh validate uuid "123e4567-e89b-12d3-a456-426614174000"
```

5. Advanced Matching

```
# Match regex pattern in file
./regex_toolkit.sh match pattern "\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b" file.txt

# Count matches of pattern
./regex_toolkit.sh match count "\d+" file.txt

# Print lines matching pattern
./regex_toolkit.sh match lines "error" log.txt

# Extract capture groups
./regex_toolkit.sh match capture "name: (.*)" config.txt

# Match using lookahead/lookbehind
./regex_toolkit.sh match lookaround "(?<=prefix)main(?=suffix)" file.txt

```

6. Extraction Utilities

```
# Extract email addresses
./regex_toolkit.sh extract emails file.txt

# Extract phone numbers
./regex_toolkit.sh extract phones contacts.txt

# Extract dates
./regex_toolkit.sh extract dates document.txt

# Extract IP addresses
./regex_toolkit.sh extract ips logs.txt

# Extract using custom pattern
./regex_toolkit.sh extract custom "\b[A-Z]{2}\d{6}\b" document.txt
```

7. Search and Replace

```
# Replace text in file
./regex_toolkit.sh replace "old" "new" file.txt

# Replace all occurrences
./regex_toolkit.sh replace "old" "new" file.txt -g

# Case insensitive replace
./regex_toolkit.sh replace "pattern" "replacement" file.txt -i

# Create backup before replacing
./regex_toolkit.sh replace "pattern" "replacement" file.txt -b

# Dry run (show what would be changed)
./regex_toolkit.sh replace "pattern" "replacement" file.txt --dry-run
```

This script provides a comprehensive set of regex tools that can be used for various text processing tasks, especially useful for developers, system administrators, and data analysts.
