#!/usr/bin/env python3
# =============================================================================
# regex_toolkit.py - A comprehensive regex utility script in Python
# Created: September 6, 2025
# Author: GitHub Copilot
#
# Usage: python regex_toolkit.py [command] [options]
# =============================================================================

import argparse
import base64
import ipaddress
import json
import os
import re
import sys
import urllib.parse
from datetime import datetime
from html.parser import HTMLParser
from typing import Any, Dict, List, Optional, Tuple, Union

import colorama
from colorama import Fore, Style

# Initialize colorama
colorama.init()

# =============================================================================
# Utility Classes
# =============================================================================

class RegexPatterns:
    """Common regex patterns for various use cases including security patterns"""

    # URL and HTTP patterns
    URL = r'https?://(?:[-\w.]|(?:%[\da-fA-F]{2}))+(?:/[^"\'\s]*)?'
    EMAIL = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    IP_V4 = r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
    IP_V6 = r'(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}'

    # HTML patterns
    HTML_TAG = r'<[^>]+>'
    HTML_COMMENT = r'<!--.*?-->'

    # Validation patterns
    NUMBER = r'\d+'
    FLOAT = r'\d+\.\d+'
    HEX = r'0x[0-9a-fA-F]+'
    DATE = r'\d{4}-\d{2}-\d{2}'

    # Security patterns - SQL Injection
    SQL_BASIC = r'(?i)(select\s+[\w\*\)\(\,\s]+\s+from)|(\bunion\b.+?\bselect\b)|(\binsert\b.+?\binto\b)|(\bupdate\b.+?\bset\b)|(\bdelete\b.+?\bfrom\b)'
    SQL_KEYWORDS = r'(?i)\b(select|insert|update|delete|drop|union|truncate|alter|exec|execute|information_schema|sysobjects|syscolumns|where|group\s+by|order\s+by)\b'
    SQL_FUNCTIONS = r'(?i)\b(sleep|benchmark|wait|delay|pg_sleep|dbms_pipe\.receive_message)\b\s*\('
    SQL_COMMENTS = r'(?i)(\/\*[\s\S]*?\*\/)|(--.+?$)|(\#.+?$)'

    # Security patterns - Cross-Site Scripting (XSS)
    XSS_TAGS = r'(?i)<\s*(script|iframe|embed|object|img|svg|style)\b[^>]*>'
    XSS_ATTRIBUTES = r'(?i)(on\w+\s*=\s*["\'][^"\']*["\'])'
    XSS_JS_FUNCTIONS = r'(?i)((?:document|window|eval|setTimeout|setInterval|alert|confirm|prompt)\s*\()'
    XSS_DATA_URI = r'(?i)data:(?:.+?)base64'
    XSS_JS_PROTOCOL = r'(?i)(?:\b|\s)javascript\s*:'

    # Security-focused patterns (from attackercan/regexp-security-cheatsheet)

    # SQL Injection Patterns
    SQL_OPERATORS = r'(?i:(?:(\!\=|\&\&|\|\||>>|<<|>=|<=|<>|<=>|\bxor\b|\brlike\b|\bregexp\b|\bisnull\b)|(?:not\s+between\s+0\s+and)|(?:is\s+null)|(like\s+null)|(?:(?:^|\W)in[+\s]*\([\s\d\"]+[^()]*\))|(?:\bxor\b|<>|rlike(?:\s+binary)?)|(?:regexp\s+binary)))'

    SQL_FUNCTION_CALLS = r'(?i:(?:t(?:able_name\b|extpos[^a-zA-Z0-9_]{1,}\()|(?:a(?:ll_objects|tt(?:rel|typ)id)|column_(?:id|name)|mb_users|object_(?:id|(?:nam|typ)e)|pg_(?:attribute|class)|rownum|s(?:ubstr(?:ing){0,1}|ys(?:c(?:at|o(?:lumn|nstraint)s)|dba|ibm|(?:filegroup|object|(?:process|tabl)e)s))|user_(?:group|password|(?:ind_column|tab(?:_column|le)|user|(?:constrain|objec)t)s)|xtype[^a-zA-Z0-9_]{1,}\bchar)\b)'

    SQL_SLEEP_COMMANDS = r'(?i:(sleep\((\s*?)(\d*?)(\s*?)\)|benchmark\((.*?)\,(.*?)\)))'

    SQL_UNION_SELECT = r'(?i:(?:(union(.*?)select(.*?)from)))'

    # Remove duplicated patterns
    SQL_COMMENTS = r'(?i)(/\*.*?\*/|--.*?$|#.*?$)'

    # XSS Patterns
    XSS_SCRIPTS = r'(?i:<script[^>]*>[\s\S]*?<\/script>|<script[^>]*>[\s\S]*?)'

    XSS_EVENT_HANDLERS = r'(?i:[\s\"\'`;\/0-9\=\x0B\x09\x0C\x3B\x2C\x28\x3B]+on\w+[\s\x0B\x09\x0C\x3B\x2C\x28\x3B]*?=)'

    XSS_DATA_ATTRIBUTES = r'(?i)[\s\S](?:x(?:link:href|html|mlns)|!ENTITY.*?SYSTEM|data:text\/html|pattern(?=.*?=)|formaction|\@import|base64)[\s\S]'

    XSS_DANGEROUS_TAGS = r'(?i:<(?:(?:apple|objec)t|isindex|embed|style|form|meta)[^>]*?>[\s\S]*?|(?:=|U\s*?R\s*?L\s*?\()\s*?[^>]*?\s*?S\s*?C\s*?R\s*?I\s*?P\s*?T\s*?:)'

    XSS_JAVASCRIPT_PROTOCOL = r'(?i)(?:\W|^)(?:javascript:(?:[\s\S]+[=\\\(\[\.<]|[\s\S]*?(?:\bname\b|\\[ux]\d))|data:(?:(?:[a-z]\w+\/\w[\w+-]+\w)?[;,]|[\s\S]*?;[\s\S]*?\b(?:base64|charset=)|[\s\S]*?,[\s\S]*?<[\s\S]*?\w[\s\S]*?>))'

    # Path Traversal Patterns
    PATH_TRAVERSAL = r'(?:\.\.[\\/]){1,}|(?:\.\.[\\\/]){1,}|(?:[\\/]\.\.){1,}|(?:[\\\/]\.\.){1,}'

    # Command Injection Patterns
    COMMAND_INJECTION = r'(?:\;|\||\`|\$\(|\$\{|\&\&|\|\||\n|\r|\$\'|<%=|<\?php|>\?|\?\>|\<%|\%>|\{\{|\(\s*?\)\s*?\{)'

class SimpleHTMLParser(HTMLParser):
    """A simple HTML parser to extract tags, attributes, and links."""

    def __init__(self, target_tag=None, target_attr=None):
        super().__init__()
        self.target_tag = target_tag
        self.target_attr = target_attr
        self.tags = []
        self.attrs = []
        self.links = []
        self.images = []
        self.current_tag = None
        self.current_data = ""

    def handle_starttag(self, tag, attrs):
        if self.target_tag and tag == self.target_tag:
            self.current_tag = tag
            self.current_data = ""

        if self.target_attr:
            for attr, value in attrs:
                if attr == self.target_attr:
                    self.attrs.append(value)

        if tag == 'a':
            for attr, value in attrs:
                if attr == 'href':
                    self.links.append(value)

        if tag == 'img':
            for attr, value in attrs:
                if attr == 'src':
                    self.images.append(value)

    def handle_endtag(self, tag):
        if self.current_tag and tag == self.current_tag:
            self.tags.append({
                'tag': self.current_tag,
                'content': self.current_data.strip()
            })
            self.current_tag = None

    def handle_data(self, data):
        if self.current_tag:
            self.current_data += data

# =============================================================================
# Utility Functions
# =============================================================================

def print_color(text: str, color: str = Fore.WHITE, bold: bool = False) -> None:
    """Print colored and optionally bold text."""
    if bold:
        print(f"{color}{Style.BRIGHT}{text}{Style.RESET_ALL}")
    else:
        print(f"{color}{text}{Style.RESET_ALL}")

def read_input(source: Optional[str]) -> str:
    """Read input from file or stdin."""
    if not source or source == "-":
        return sys.stdin.read()
    elif os.path.isfile(source):
        with open(source, 'r') as file:
            return file.read()
    else:
        print_color(f"Error: File not found - {source}", Fore.RED)
        sys.exit(1)

# =============================================================================
# HTTP/URL Functions
# =============================================================================

def extract_urls(args: argparse.Namespace) -> None:
    """Extract URLs from text."""
    input_text = read_input(args.file)
    url_pattern = r'https?://[a-zA-Z0-9./?=_%:-]*|www\.[a-zA-Z0-9./?=_%:-]*'
    urls = re.findall(url_pattern, input_text)

    for url in urls:
        print(url)

def validate_url(args: argparse.Namespace) -> None:
    """Validate if a URL is properly formatted."""
    url = args.url
    url_pattern = r'^(https?|ftp)://[^\s/$.?#].[^\s]*$'

    if re.match(url_pattern, url):
        print_color(f"Valid URL: {url}", Fore.GREEN)
    else:
        print_color(f"Invalid URL: {url}", Fore.RED)

def parse_url(args: argparse.Namespace) -> None:
    """Parse URL into components."""
    url = args.url
    parsed = urllib.parse.urlparse(url)

    print_color("URL Components:", Fore.CYAN)
    print_color(f"Protocol: {parsed.scheme}", Fore.YELLOW, False)
    print_color(f"Domain: {parsed.netloc}", Fore.YELLOW, False)
    print_color(f"Path: {parsed.path or '/'}", Fore.YELLOW, False)
    print_color(f"Query: {parsed.query or '(none)'}", Fore.YELLOW, False)
    print_color(f"Fragment: {parsed.fragment or '(none)'}", Fore.YELLOW, False)

def extract_params(args: argparse.Namespace) -> None:
    """Extract query parameters from URL."""
    url = args.url
    parsed = urllib.parse.urlparse(url)
    query_params = urllib.parse.parse_qs(parsed.query)

    if not query_params:
        print_color("No query parameters found in URL", Fore.YELLOW)
        return

    print_color("Query Parameters:", Fore.CYAN)
    for key, values in query_params.items():
        print_color(f"{key}: {values[0]}", Fore.YELLOW, False)

def extract_domain(args: argparse.Namespace) -> None:
    """Extract domain from URL."""
    url = args.url
    parsed = urllib.parse.urlparse(url)
    print(parsed.netloc)

# =============================================================================
# HTML Functions
# =============================================================================

def extract_tags(args: argparse.Namespace) -> None:
    """Extract specific HTML tags from file or stdin."""
    input_text = read_input(args.file)
    parser = SimpleHTMLParser(target_tag=args.tag)
    parser.feed(input_text)

    for item in parser.tags:
        print(f"<{item['tag']}>{item['content']}</{item['tag']}>")

def extract_attrs(args: argparse.Namespace) -> None:
    """Extract specific HTML attributes from file or stdin."""
    input_text = read_input(args.file)
    parser = SimpleHTMLParser(target_attr=args.attr)
    parser.feed(input_text)

    for attr in parser.attrs:
        print(attr)

def strip_tags(args: argparse.Namespace) -> None:
    """Strip all HTML tags from file or stdin."""
    input_text = read_input(args.file)
    cleaned_text = re.sub(r'<[^>]*>', '', input_text)
    print(cleaned_text)

def extract_links(args: argparse.Namespace) -> None:
    """Extract all links from HTML."""
    input_text = read_input(args.file)
    parser = SimpleHTMLParser()
    parser.feed(input_text)

    for link in parser.links:
        print(link)

def extract_images(args: argparse.Namespace) -> None:
    """Extract all image sources from HTML."""
    input_text = read_input(args.file)
    parser = SimpleHTMLParser()
    parser.feed(input_text)

    for img in parser.images:
        print(img)

# =============================================================================
# Base64 Functions
# =============================================================================

def base64_encode(args: argparse.Namespace) -> None:
    """Encode text or file content to Base64."""
    if not args.input and not args.file:
        input_text = sys.stdin.read()
    elif args.file and args.file != "-":
        with open(args.file, 'rb') as file:
            input_bytes = file.read()
        encoded = base64.b64encode(input_bytes).decode('utf-8')
        print(encoded)
        return
    else:
        input_text = args.input

    encoded = base64.b64encode(input_text.encode('utf-8')).decode('utf-8')
    print(encoded)

def base64_decode(args: argparse.Namespace) -> None:
    """Decode Base64 to text."""
    if not args.input and not args.file:
        input_text = sys.stdin.read()
    elif args.file and args.file != "-":
        with open(args.file, 'r') as file:
            input_text = file.read()
    else:
        input_text = args.input

    try:
        decoded = base64.b64decode(input_text).decode('utf-8')
        print(decoded)
    except Exception as e:
        print_color(f"Error decoding Base64: {str(e)}", Fore.RED)

def base64_detect(args: argparse.Namespace) -> None:
    """Detect Base64 encoded strings in text."""
    input_text = read_input(args.file)
    pattern = r'[A-Za-z0-9+/]{20,}={0,2}'
    matches = re.findall(pattern, input_text)

    for match in matches:
        print(match)

def base64_validate(args: argparse.Namespace) -> None:
    """Validate if a string is valid Base64."""
    string = args.string
    pattern = r'^[A-Za-z0-9+/]+={0,2}$'

    if re.match(pattern, string):
        # Check if padding is correct
        mod = len(string) % 4

        if mod == 0:
            print_color("Valid Base64 string", Fore.GREEN)
            return
        elif mod == 2 and string[-2:] == "==":
            print_color("Valid Base64 string", Fore.GREEN)
            return
        elif mod == 3 and string[-1] == "=":
            print_color("Valid Base64 string", Fore.GREEN)
            return

    print_color("Invalid Base64 string", Fore.RED)

# =============================================================================
# Validation Functions
# =============================================================================

def validate_email(args: argparse.Namespace) -> None:
    """Validate email address."""
    email = args.email
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    if re.match(pattern, email):
        print_color(f"Valid email address: {email}", Fore.GREEN)
    else:
        print_color(f"Invalid email address: {email}", Fore.RED)

def validate_phone(args: argparse.Namespace) -> None:
    """Validate phone number."""
    phone = args.phone
    # Remove any non-digit characters for normalization
    normalized = re.sub(r'\D', '', phone)

    if 10 <= len(normalized) <= 15:
        print_color(f"Valid phone number: {phone}", Fore.GREEN)
    else:
        print_color(f"Invalid phone number: {phone}", Fore.RED)

def validate_ip(args: argparse.Namespace) -> None:
    """Validate IP address (IPv4 or IPv6)."""
    ip = args.ip

    try:
        ipaddress.ip_address(ip)
        if '.' in ip:
            print_color(f"Valid IPv4 address: {ip}", Fore.GREEN)
        else:
            print_color(f"Valid IPv6 address: {ip}", Fore.GREEN)
    except ValueError:
        print_color(f"Invalid IP address: {ip}", Fore.RED)

def validate_date(args: argparse.Namespace) -> None:
    """Validate date format."""
    date_str = args.date
    formats = ["%Y-%m-%d", "%m/%d/%Y", "%d.%m.%Y"]

    for fmt in formats:
        try:
            datetime.strptime(date_str, fmt)
            print_color(f"Valid date: {date_str}", Fore.GREEN)
            return
        except ValueError:
            continue

    print_color(f"Invalid date: {date_str}", Fore.RED)

def validate_credit_card(args: argparse.Namespace) -> None:
    """Validate credit card number using Luhn algorithm."""
    number = args.number
    # Remove spaces and dashes for normalization
    normalized = re.sub(r'[\s-]', '', number)

    if not normalized.isdigit():
        print_color("Invalid credit card number: contains non-digits", Fore.RED)
        return

    if not 13 <= len(normalized) <= 19:
        print_color("Invalid credit card number: incorrect length", Fore.RED)
        return

    # Apply Luhn algorithm
    digits = [int(d) for d in normalized]
    for i in range(len(digits) - 2, -1, -2):
        digits[i] *= 2
        if digits[i] > 9:
            digits[i] -= 9

    if sum(digits) % 10 == 0:
        print_color("Valid credit card number", Fore.GREEN)
    else:
        print_color("Invalid credit card number: failed Luhn check", Fore.RED)

def validate_password(args: argparse.Namespace) -> None:
    """Check password strength."""
    password = args.password
    score = 0

    # Length check
    if len(password) >= 8:
        score += 1
    if len(password) >= 12:
        score += 1
    if len(password) >= 16:
        score += 1

    # Complexity checks
    if re.search(r'[A-Z]', password):
        score += 1
    if re.search(r'[a-z]', password):
        score += 1
    if re.search(r'[0-9]', password):
        score += 1
    if re.search(r'[^A-Za-z0-9]', password):
        score += 1

    # Sequential character check
    seq_patterns = [
        r'012|123|234|345|456|567|678|789',
        r'abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz',
        r'ABC|BCD|CDE|DEF|EFG|FGH|GHI|HIJ|IJK|JKL|KLM|LMN|MNO|NOP|OPQ|PQR|QRS|RST|STU|TUV|UVW|VWX|WXY|XYZ'
    ]
    if not any(re.search(pattern, password) for pattern in seq_patterns):
        score += 1

    # Repeated character check
    if not re.search(r'(.)\1{2,}', password):
        score += 1

    # Output score and strength assessment
    print_color("Password strength assessment:", Fore.CYAN)
    print_color(f"Score: {score}/10", Fore.YELLOW)

    if score <= 3:
        print_color("Strength: Very Weak", Fore.RED)
    elif score <= 5:
        print_color("Strength: Weak", Fore.RED)
    elif score <= 7:
        print_color("Strength: Moderate", Fore.YELLOW)
    elif score <= 9:
        print_color("Strength: Strong", Fore.GREEN)
    else:
        print_color("Strength: Very Strong", Fore.GREEN)

    # Provide improvement suggestions
    print_color("Suggestions:", Fore.CYAN)
    if len(password) < 12:
        print("- Increase length to at least 12 characters")
    if not re.search(r'[A-Z]', password):
        print("- Add uppercase letters")
    if not re.search(r'[a-z]', password):
        print("- Add lowercase letters")
    if not re.search(r'[0-9]', password):
        print("- Add numbers")
    if not re.search(r'[^A-Za-z0-9]', password):
        print("- Add special characters")

def validate_uuid(args: argparse.Namespace) -> None:
    """Validate UUID."""
    uuid = args.uuid
    pattern = r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

    if re.match(pattern, uuid):
        print_color(f"Valid UUID: {uuid}", Fore.GREEN)
    else:
        print_color(f"Invalid UUID: {uuid}", Fore.RED)

# =============================================================================
# Advanced Matching Functions
# =============================================================================

def match_pattern(args: argparse.Namespace) -> None:
    """Match regex pattern in file or stdin."""
    input_text = read_input(args.file)
    pattern = args.pattern

    try:
        matches = re.findall(pattern, input_text, re.DOTALL)
        for match in matches:
            print(match)
    except re.error as e:
        print_color(f"Error in regex pattern: {str(e)}", Fore.RED)

def match_count(args: argparse.Namespace) -> None:
    """Count matches of pattern in file or stdin."""
    input_text = read_input(args.file)
    pattern = args.pattern

    try:
        matches = re.findall(pattern, input_text)
        count = len(matches)
        print(f"Pattern '{pattern}' matched {Fore.CYAN}{count}{Style.RESET_ALL} times")
    except re.error as e:
        print_color(f"Error in regex pattern: {str(e)}", Fore.RED)

def match_lines(args: argparse.Namespace) -> None:
    """Print lines matching pattern."""
    if not args.file or args.file == "-":
        for line in sys.stdin:
            if re.search(args.pattern, line):
                print(line.rstrip())
    elif os.path.isfile(args.file):
        with open(args.file, 'r') as file:
            for line in file:
                if re.search(args.pattern, line):
                    print(line.rstrip())
    else:
        print_color(f"Error: File not found - {args.file}", Fore.RED)
        sys.exit(1)

def match_capture(args: argparse.Namespace) -> None:
    """Extract capture groups from pattern matches."""
    input_text = read_input(args.file)
    pattern = args.pattern

    try:
        matches = re.finditer(pattern, input_text)
        for match in matches:
            if match.groups():
                for group in match.groups():
                    print(group)
            else:
                print(match.group(0))
    except re.error as e:
        print_color(f"Error in regex pattern: {str(e)}", Fore.RED)

def match_lookaround(args: argparse.Namespace) -> None:
    """Match using lookahead/lookbehind assertions."""
    input_text = read_input(args.file)
    pattern = args.pattern

    try:
        matches = re.findall(pattern, input_text)
        for match in matches:
            print(match)
    except re.error as e:
        print_color(f"Error in regex pattern: {str(e)}", Fore.RED)

# =============================================================================
# Extraction Functions
# =============================================================================

def extract_emails(args: argparse.Namespace) -> None:
    """Extract email addresses."""
    input_text = read_input(args.file)
    pattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    emails = set(re.findall(pattern, input_text))

    for email in emails:
        print(email)

def extract_phones(args: argparse.Namespace) -> None:
    """Extract phone numbers."""
    input_text = read_input(args.file)
    pattern = r'\+?[0-9]{1,3}[-. ]?\(?\d{1,4}\)?[-. ]?\d{1,4}[-. ]?\d{1,4}'
    phones = set(re.findall(pattern, input_text))

    for phone in phones:
        print(phone)

def extract_dates(args: argparse.Namespace) -> None:
    """Extract dates."""
    input_text = read_input(args.file)
    pattern = r'\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{4}|\d{1,2}\.\d{1,2}\.\d{4}'
    dates = set(re.findall(pattern, input_text))

    for date in dates:
        print(date)

def extract_ips(args: argparse.Namespace) -> None:
    """Extract IP addresses."""
    input_text = read_input(args.file)

    # IPv4 extraction
    ipv4_pattern = r'((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
    ipv4s = set(re.findall(ipv4_pattern, input_text))

    # IPv6 extraction (simplified for common formats)
    ipv6_pattern = r'([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}'
    ipv6s = set(re.findall(ipv6_pattern, input_text))

    print_color("IPv4 Addresses:", Fore.CYAN)
    for ip in ipv4s:
        print(ip[0] + ip[3])  # Join the capture groups to form the full IP

    print_color("IPv6 Addresses:", Fore.CYAN)
    for ip in ipv6s:
        print(ip[0])  # Only print the first capture group which contains the IP

def extract_ssn(args: argparse.Namespace) -> None:
    """Extract social security numbers."""
    input_text = read_input(args.file)
    pattern = r'\b\d{3}[-]?\d{2}[-]?\d{4}\b'
    ssns = set(re.findall(pattern, input_text))

    for ssn in ssns:
        print(ssn)

def extract_custom(args: argparse.Namespace) -> None:
    """Extract using custom pattern."""
    input_text = read_input(args.file)
    pattern = args.pattern

    try:
        matches = set(re.findall(pattern, input_text))
        for match in matches:
            print(match)
    except re.error as e:
        print_color(f"Error in regex pattern: {str(e)}", Fore.RED)

# =============================================================================
# Search and Replace Functions
# =============================================================================

def do_replace(args: argparse.Namespace) -> None:
    """Perform search and replace with regex."""
    pattern = args.pattern
    replacement = args.replacement
    source = args.file

    # Build regex flags
    flags = 0
    if args.case_insensitive:
        flags |= re.IGNORECASE

    try:
        if not source or source == "-":
            # Read from stdin
            input_text = sys.stdin.read()
            if args.dry_run:
                print(input_text)
                print("\n--- After replacement ---\n")

            if args.global_replace:
                result = re.sub(pattern, replacement, input_text, flags=flags)
            else:
                result = re.sub(pattern, replacement, input_text, count=1, flags=flags)

            print(result)
        elif os.path.isfile(source):
            # Process file
            with open(source, 'r') as file:
                content = file.read()

            if args.backup:
                with open(f"{source}.bak", 'w') as backup_file:
                    backup_file.write(content)

            if args.dry_run:
                if args.global_replace:
                    result = re.sub(pattern, replacement, content, flags=flags)
                else:
                    result = re.sub(pattern, replacement, content, count=1, flags=flags)

                print(content)
                print("\n--- After replacement ---\n")
                print(result)
            else:
                if args.global_replace:
                    result = re.sub(pattern, replacement, content, flags=flags)
                else:
                    result = re.sub(pattern, replacement, content, count=1, flags=flags)

                with open(source, 'w') as file:
                    file.write(result)

                print_color(f"Replacement complete in {source}", Fore.GREEN)
        else:
            print_color(f"Error: File not found - {source}", Fore.RED)
            sys.exit(1)
    except re.error as e:
        print_color(f"Error in regex pattern: {str(e)}", Fore.RED)
        sys.exit(1)

# =============================================================================
# Security Functions
# =============================================================================

def detect_sql_injection(text, verbose=False):
    """
    Detects potential SQL injection attacks in the provided text.

    Args:
        text (str): The text to check for SQL injection
        verbose (bool): Whether to print detailed matches

    Returns:
        bool: True if potential SQL injection is detected, False otherwise
    """
    patterns = [
        (RegexPatterns.SQL_BASIC, "Basic SQL query"),
        (RegexPatterns.SQL_KEYWORDS, "SQL keywords"),
        (RegexPatterns.SQL_FUNCTIONS, "SQL function calls"),
        (RegexPatterns.SQL_COMMENTS, "SQL comments")
    ]

    detections = []
    for pattern, desc in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            if verbose:
                print_color(f"SQL Injection detected ({desc}): {match.group(0)}", Fore.YELLOW)
            detections.append((match.group(0), desc))

    return len(detections) > 0, detections

def detect_xss(text, verbose=False):
    """
    Detects potential Cross-Site Scripting (XSS) attacks in the provided text.

    Args:
        text (str): The text to check for XSS
        verbose (bool): Whether to print detailed matches

    Returns:
        bool: True if potential XSS is detected, False otherwise
    """
    patterns = [
        (RegexPatterns.XSS_TAGS, "Dangerous HTML tags"),
        (RegexPatterns.XSS_ATTRIBUTES, "Event handlers"),
        (RegexPatterns.XSS_JS_FUNCTIONS, "JavaScript functions"),
        (RegexPatterns.XSS_DATA_URI, "Data URI"),
        (RegexPatterns.XSS_JS_PROTOCOL, "JavaScript protocol")
    ]

    detections = []
    for pattern, desc in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            if verbose:
                print_color(f"XSS detected ({desc}): {match.group(0)}", Fore.YELLOW)
            detections.append((match.group(0), desc))

    return len(detections) > 0, detections

def detect_security_threats(args):
    """
    Detect security threats in file or string.

    Args:
        args (argparse.Namespace): Command-line arguments
    """
    try:
        source = args.file if args.file else '-'

        if source == '-':
            content = sys.stdin.read()
        elif os.path.isfile(source):
            with open(source, 'r') as file:
                content = file.read()
        else:
            print_color(f"Error: File not found - {source}", Fore.RED)
            sys.exit(1)

        if args.threat_type == 'all' or args.threat_type == 'sql':
            detected, matches = detect_sql_injection(content, args.verbose)
            if detected:
                print_color(f"SQL Injection vulnerabilities detected: {len(matches)}", Fore.RED)
                if args.verbose:
                    for match, desc in matches:
                        print_color(f"  - {desc}: {match}", Fore.YELLOW)
            else:
                print_color("No SQL Injection vulnerabilities detected", Fore.GREEN)

        if args.threat_type == 'all' or args.threat_type == 'xss':
            detected, matches = detect_xss(content, args.verbose)
            if detected:
                print_color(f"XSS vulnerabilities detected: {len(matches)}", Fore.RED)
                if args.verbose:
                    for match, desc in matches:
                        print_color(f"  - {desc}: {match}", Fore.YELLOW)
            else:
                print_color("No XSS vulnerabilities detected", Fore.GREEN)

    except Exception as e:
        print_color(f"Error: {str(e)}", Fore.RED)
        sys.exit(1)# =============================================================================
# Command Line Interface
# =============================================================================

def setup_http_parser(subparsers):
    """Set up HTTP/URL command line parser."""
    http_parser = subparsers.add_parser('http', help='HTTP/URL parsing utilities')
    http_subparsers = http_parser.add_subparsers(dest='http_command', help='HTTP/URL subcommands')

    # extract-urls
    extract_urls_parser = http_subparsers.add_parser('extract-urls', help='Extract all URLs from file or stdin')
    extract_urls_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    extract_urls_parser.set_defaults(func=extract_urls)

    # validate-url
    validate_url_parser = http_subparsers.add_parser('validate-url', help='Validate if a URL is properly formatted')
    validate_url_parser.add_argument('url', help='URL to validate')
    validate_url_parser.set_defaults(func=validate_url)

    # parse-url
    parse_url_parser = http_subparsers.add_parser('parse-url', help='Parse URL into components')
    parse_url_parser.add_argument('url', help='URL to parse')
    parse_url_parser.set_defaults(func=parse_url)

    # extract-params
    extract_params_parser = http_subparsers.add_parser('extract-params', help='Extract query parameters from URL')
    extract_params_parser.add_argument('url', help='URL to extract parameters from')
    extract_params_parser.set_defaults(func=extract_params)

    # extract-domain
    extract_domain_parser = http_subparsers.add_parser('extract-domain', help='Extract domain from URL')
    extract_domain_parser.add_argument('url', help='URL to extract domain from')
    extract_domain_parser.set_defaults(func=extract_domain)

def setup_html_parser(subparsers):
    """Set up HTML command line parser."""
    html_parser = subparsers.add_parser('html', help='HTML parsing utilities')
    html_subparsers = html_parser.add_subparsers(dest='html_command', help='HTML subcommands')

    # extract-tags
    extract_tags_parser = html_subparsers.add_parser('extract-tags', help='Extract specific HTML tags from file or stdin')
    extract_tags_parser.add_argument('tag', help='Tag name to extract')
    extract_tags_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    extract_tags_parser.set_defaults(func=extract_tags)

    # extract-attrs
    extract_attrs_parser = html_subparsers.add_parser('extract-attrs', help='Extract specific HTML attributes from file or stdin')
    extract_attrs_parser.add_argument('attr', help='Attribute name to extract')
    extract_attrs_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    extract_attrs_parser.set_defaults(func=extract_attrs)

    # strip-tags
    strip_tags_parser = html_subparsers.add_parser('strip-tags', help='Strip all HTML tags from file or stdin')
    strip_tags_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    strip_tags_parser.set_defaults(func=strip_tags)

    # extract-links
    extract_links_parser = html_subparsers.add_parser('extract-links', help='Extract all links from HTML')
    extract_links_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    extract_links_parser.set_defaults(func=extract_links)

    # extract-images
    extract_images_parser = html_subparsers.add_parser('extract-images', help='Extract all image sources from HTML')
    extract_images_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    extract_images_parser.set_defaults(func=extract_images)

def setup_base64_parser(subparsers):
    """Set up Base64 command line parser."""
    base64_parser = subparsers.add_parser('base64', help='Base64 encoding/decoding utilities')
    base64_subparsers = base64_parser.add_subparsers(dest='base64_command', help='Base64 subcommands')

    # encode
    encode_parser = base64_subparsers.add_parser('encode', help='Encode text or file content to Base64')
    encode_group = encode_parser.add_mutually_exclusive_group()
    encode_group.add_argument('--input', '-i', help='Text to encode')
    encode_group.add_argument('--file', '-f', help='File to encode (use - for stdin)')
    encode_parser.set_defaults(func=base64_encode)

    # decode
    decode_parser = base64_subparsers.add_parser('decode', help='Decode Base64 to text')
    decode_group = decode_parser.add_mutually_exclusive_group()
    decode_group.add_argument('--input', '-i', help='Base64 string to decode')
    decode_group.add_argument('--file', '-f', help='File containing Base64 to decode (use - for stdin)')
    decode_parser.set_defaults(func=base64_decode)

    # detect
    detect_parser = base64_subparsers.add_parser('detect', help='Detect Base64 encoded strings in text')
    detect_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    detect_parser.set_defaults(func=base64_detect)

    # validate
    validate_parser = base64_subparsers.add_parser('validate', help='Validate if a string is valid Base64')
    validate_parser.add_argument('string', help='String to validate')
    validate_parser.set_defaults(func=base64_validate)

def setup_validate_parser(subparsers):
    """Set up validation command line parser."""
    validate_parser = subparsers.add_parser('validate', help='Validation utilities')
    validate_subparsers = validate_parser.add_subparsers(dest='validate_command', help='Validation subcommands')

    # email
    email_parser = validate_subparsers.add_parser('email', help='Validate email address')
    email_parser.add_argument('email', help='Email address to validate')
    email_parser.set_defaults(func=validate_email)

    # phone
    phone_parser = validate_subparsers.add_parser('phone', help='Validate phone number')
    phone_parser.add_argument('phone', help='Phone number to validate')
    phone_parser.set_defaults(func=validate_phone)

    # ip
    ip_parser = validate_subparsers.add_parser('ip', help='Validate IP address (IPv4 or IPv6)')
    ip_parser.add_argument('ip', help='IP address to validate')
    ip_parser.set_defaults(func=validate_ip)

    # date
    date_parser = validate_subparsers.add_parser('date', help='Validate date format')
    date_parser.add_argument('date', help='Date to validate')
    date_parser.set_defaults(func=validate_date)

    # credit-card
    cc_parser = validate_subparsers.add_parser('credit-card', help='Validate credit card number')
    cc_parser.add_argument('number', help='Credit card number to validate')
    cc_parser.set_defaults(func=validate_credit_card)

    # password
    pw_parser = validate_subparsers.add_parser('password', help='Check password strength')
    pw_parser.add_argument('password', help='Password to check')
    pw_parser.set_defaults(func=validate_password)

    # uuid
    uuid_parser = validate_subparsers.add_parser('uuid', help='Validate UUID')
    uuid_parser.add_argument('uuid', help='UUID to validate')
    uuid_parser.set_defaults(func=validate_uuid)

def setup_match_parser(subparsers):
    """Set up advanced matching command line parser."""
    match_parser = subparsers.add_parser('match', help='Advanced regex matching utilities')
    match_subparsers = match_parser.add_subparsers(dest='match_command', help='Match subcommands')

    # pattern
    pattern_parser = match_subparsers.add_parser('pattern', help='Match regex pattern in file or stdin')
    pattern_parser.add_argument('pattern', help='Regex pattern to match')
    pattern_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    pattern_parser.set_defaults(func=match_pattern)

    # count
    count_parser = match_subparsers.add_parser('count', help='Count matches of pattern in file or stdin')
    count_parser.add_argument('pattern', help='Regex pattern to count')
    count_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    count_parser.set_defaults(func=match_count)

    # lines
    lines_parser = match_subparsers.add_parser('lines', help='Print lines matching pattern')
    lines_parser.add_argument('pattern', help='Regex pattern to match')
    lines_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    lines_parser.set_defaults(func=match_lines)

    # capture
    capture_parser = match_subparsers.add_parser('capture', help='Extract capture groups from pattern matches')
    capture_parser.add_argument('pattern', help='Regex pattern with capture groups')
    capture_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    capture_parser.set_defaults(func=match_capture)

    # lookaround
    lookaround_parser = match_subparsers.add_parser('lookaround', help='Match using lookahead/lookbehind assertions')
    lookaround_parser.add_argument('pattern', help='Regex pattern with lookahead/lookbehind')
    lookaround_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    lookaround_parser.set_defaults(func=match_lookaround)

def setup_extract_parser(subparsers):
    """Set up extraction command line parser."""
    extract_parser = subparsers.add_parser('extract', help='Extraction utilities')
    extract_subparsers = extract_parser.add_subparsers(dest='extract_command', help='Extract subcommands')

    # emails
    emails_parser = extract_subparsers.add_parser('emails', help='Extract email addresses')
    emails_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    emails_parser.set_defaults(func=extract_emails)

    # phones
    phones_parser = extract_subparsers.add_parser('phones', help='Extract phone numbers')
    phones_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    phones_parser.set_defaults(func=extract_phones)

    # dates
    dates_parser = extract_subparsers.add_parser('dates', help='Extract dates')
    dates_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    dates_parser.set_defaults(func=extract_dates)

    # ips
    ips_parser = extract_subparsers.add_parser('ips', help='Extract IP addresses')
    ips_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    ips_parser.set_defaults(func=extract_ips)

    # ssn
    ssn_parser = extract_subparsers.add_parser('ssn', help='Extract social security numbers')
    ssn_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    ssn_parser.set_defaults(func=extract_ssn)

    # custom
    custom_parser = extract_subparsers.add_parser('custom', help='Extract using custom pattern')
    custom_parser.add_argument('pattern', help='Custom regex pattern')
    custom_parser.add_argument('file', nargs='?', help='File to read (use - for stdin)')
    custom_parser.set_defaults(func=extract_custom)

def setup_replace_parser(subparsers):
    """Set up search and replace command line parser."""
    replace_parser = subparsers.add_parser('replace', help='Search and replace with regex')
    replace_parser.add_argument('pattern', help='Regex pattern to search for')
    replace_parser.add_argument('replacement', help='Replacement string')
    replace_parser.add_argument('file', nargs='?', help='File to process (use - for stdin)')
    replace_parser.add_argument('-g', '--global-replace', action='store_true', help='Replace globally (all occurrences)')
    replace_parser.add_argument('-i', '--case-insensitive', action='store_true', help='Case insensitive matching')
    replace_parser.add_argument('-b', '--backup', action='store_true', help='Backup original file (creates .bak)')
    replace_parser.add_argument('--dry-run', action='store_true', help='Show what would be changed without making changes')
    replace_parser.set_defaults(func=do_replace)

def setup_security_parser(subparsers):
    """Set up security command line parser."""
    security_parser = subparsers.add_parser('security', help='Security-focused regex utilities')
    security_subparsers = security_parser.add_subparsers(dest='security_command', help='Security subcommands')

    # detect
    detect_parser = security_subparsers.add_parser('detect', help='Detect security threats')
    detect_parser.add_argument('file', nargs='?', help='File to scan (use - for stdin)')
    detect_parser.add_argument('--type', '-t', dest='threat_type', choices=['sql', 'xss', 'all'],
                               default='all', help='Type of threat to detect')
    detect_parser.add_argument('--verbose', '-v', action='store_true', help='Show detailed matches')
    detect_parser.set_defaults(func=detect_security_threats)

def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description='RegEx Toolkit - A comprehensive regex utility in Python')
    subparsers = parser.add_subparsers(dest='command', help='Commands')

    # Set up command parsers
    setup_http_parser(subparsers)
    setup_html_parser(subparsers)
    setup_base64_parser(subparsers)
    setup_validate_parser(subparsers)
    setup_match_parser(subparsers)
    setup_extract_parser(subparsers)
    setup_replace_parser(subparsers)
    setup_security_parser(subparsers)

    # Parse arguments
    args = parser.parse_args()

    # Show help if no command specified
    if not args.command:
        parser.print_help()
        sys.exit(0)

    # Show help if no subcommand specified
    if hasattr(args, f"{args.command}_command") and not getattr(args, f"{args.command}_command"):
        getattr(subparsers.choices[args.command], "print_help")()
        sys.exit(0)

    # Execute function
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
