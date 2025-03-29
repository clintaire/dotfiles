# PDF Duplicate Finder and Remover

A simple Python script to find duplicate PDF files in a directory and move them to a separate folder.

## Overview

This script scans a directory and its subdirectories for PDF files, calculates a hash of each file's content to identify duplicates, and moves duplicates to a separate folder while preserving one copy of each unique PDF in the original location.

## Requirements

- Python 3.6 or higher
- No external dependencies (uses only standard library modules)
- Works on Linux (including Arch Linux), macOS, and Windows

## Usage

```bash
python py01.py /path/to/your/pdf/collection
```

## How it Works

1. The script recursively scans the specified directory for all .pdf files
2. It calculates a SHA-256 hash for each file based on its content
3. Files with identical hashes (meaning identical content) are identified as duplicates
4. The first instance of each file is kept in place
5. All duplicates are moved to a new folder called "removed_duplicates" within the specified directory

## Example

If you have a folder structure like:

```
books/
├── programming/
│   ├── python_basics.pdf
│   └── python_reference.pdf
└── computer_science/
    ├── algorithms.pdf
    └── python_basics.pdf (duplicate)
```

After running:

```bash
python py01.py /path/to/books
```

The structure will become:

```
books/
├── programming/
│   ├── python_basics.pdf
│   └── python_reference.pdf
├── computer_science/
│   └── algorithms.pdf
└── removed_duplicates/
    └── python_basics.pdf
```

## Notes

- The script identifies duplicates based on content, not just filenames
- Duplicate files are moved, not deleted
- You can safely review the "removed_duplicates" folder before deciding to delete its contents
- If two files have the same name but different content, they are not considered duplicates
