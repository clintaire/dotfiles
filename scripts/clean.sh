#!/bin/bash
# make it executable with chmod +x clean.sh
# Simple Script to clean mac-generated dot underscore files

# Usage: ./clean.sh /path/to/directory
if [ -z "$1" ]; then
    echo "Usage: $0 ./clean.sh /path/to/directory"
    exit 1
fi

# List files first
echo "Files that would be removed:"
find "$1" -name "._*" -type f

# Ask for confirmation
read -p "Do you want to remove these files? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    find "$1" -name "._*" -type f -delete
    echo "Files removed successfully."
else
    echo "Operation cancelled."
fi
