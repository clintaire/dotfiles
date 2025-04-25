#!/usr/bin/env python3
import argparse
import hashlib
import os
import shutil
from pathlib import Path


def calculate_file_hash(file_path):
    """Calculate a SHA-256 hash of file content."""
    hash_obj = hashlib.sha256()
    with open(file_path, "rb") as file:
        # Read the file in chunks to handle large files efficiently
        for chunk in iter(lambda: file.read(4096), b""):
            hash_obj.update(chunk)
    return hash_obj.hexdigest()


def find_pdf_files(directory):
    """Find all PDF files in a directory and its subdirectories."""
    pdf_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(".pdf"):
                pdf_files.append(os.path.join(root, file))
    return pdf_files


def find_duplicates(pdf_files):
    """Find duplicate PDF files based on content hash."""
    file_hashes = {}
    duplicates = []

    for file_path in pdf_files:
        file_hash = calculate_file_hash(file_path)

        if file_hash in file_hashes:
            # This is a duplicate
            duplicates.append((file_path, file_hashes[file_hash]))
        else:
            # First time seeing this hash
            file_hashes[file_hash] = file_path

    return duplicates


def create_duplicates_folder(directory):
    """Create a folder for duplicate files."""
    duplicates_dir = os.path.join(directory, "removed_duplicates")
    os.makedirs(duplicates_dir, exist_ok=True)
    return duplicates_dir


def move_duplicates(duplicates, target_dir):
    """Move duplicate files to the target directory."""
    for duplicate_file, original_file in duplicates:
        # Get just the filename without the path
        filename = os.path.basename(duplicate_file)

        # Create a unique name by adding the original filename as a prefix if needed
        if os.path.exists(os.path.join(target_dir, filename)):
            orig_filename = os.path.basename(original_file)
            new_filename = f"{os.path.splitext(orig_filename)[0]}_{filename}"
        else:
            new_filename = filename

        # Move the file instead of copying
        shutil.move(duplicate_file, os.path.join(target_dir, new_filename))
        print(f"Duplicate found: {duplicate_file} (same as {original_file})")
        print(f"Moved to: {os.path.join(target_dir, new_filename)}")


def main():
    parser = argparse.ArgumentParser(
        description="Find duplicate PDF files in a directory and move them"
    )
    parser.add_argument("directory", help="Directory to scan for PDF files")
    args = parser.parse_args()

    directory = args.directory

    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory")
        return

    print(f"Scanning {directory} for PDF files...")
    pdf_files = find_pdf_files(directory)
    print(f"Found {len(pdf_files)} PDF files")

    if len(pdf_files) == 0:
        print("No PDF files found. Exiting.")
        return

    print("Analyzing files for duplicates...")
    duplicates = find_duplicates(pdf_files)

    if not duplicates:
        print("No duplicate files found.")
        return

    print(f"Found {len(duplicates)} duplicate files")

    duplicates_dir = create_duplicates_folder(directory)
    print(f"Created duplicates folder: {duplicates_dir}")

    move_duplicates(duplicates, duplicates_dir)
    print(f"All duplicates have been removed and moved to {duplicates_dir}")


if __name__ == "__main__":
    main()
