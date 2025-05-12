#!/usr/bin/env python3
import argparse
import datetime
import hashlib
import os
import shutil


# Script to find and manage duplicate PDF files in a directory
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


def find_duplicates(pdf_files, keep_strategy="newest"):
    """Find duplicate PDF files based on content hash.

    Args:
        pdf_files: List of PDF file paths
        keep_strategy: Which file to keep when duplicates are found
                      - 'newest': Keep the most recently modified file
                        (default)
                      - 'oldest': Keep the oldest file
                      - 'shortest_path': Keep the file with shortest path
                      - 'longest_path': Keep the file with longest path
    """
    file_hashes = {}
    duplicates = []

    for file_path in pdf_files:
        file_hash = calculate_file_hash(file_path)

        if file_hash in file_hashes:
            # This is a duplicate - determine which to keep based on strategy
            original_file = file_hashes[file_hash]

            # Decide if we should swap which file is considered "original"
            if keep_strategy == "newest":
                orig_mtime = os.path.getmtime(original_file)
                dup_mtime = os.path.getmtime(file_path)
                if dup_mtime > orig_mtime:
                    # The "duplicate" is actually newer, so swap them
                    duplicates.append((original_file, file_path))
                    file_hashes[file_hash] = file_path
                    continue

            elif keep_strategy == "oldest":
                orig_mtime = os.path.getmtime(original_file)
                dup_mtime = os.path.getmtime(file_path)
                if dup_mtime < orig_mtime:
                    # The "duplicate" is actually older, so swap them
                    duplicates.append((original_file, file_path))
                    file_hashes[file_hash] = file_path
                    continue

            elif keep_strategy == "shortest_path":
                if len(file_path) < len(original_file):
                    # The "duplicate" has a shorter path, so swap them
                    duplicates.append((original_file, file_path))
                    file_hashes[file_hash] = file_path
                    continue

            elif keep_strategy == "longest_path":
                if len(file_path) > len(original_file):
                    # The "duplicate" has a longer path, so swap them
                    duplicates.append((original_file, file_path))
                    file_hashes[file_hash] = file_path
                    continue

            # If we didn't swap, the current file is the duplicate
            duplicates.append((file_path, original_file))
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
    moved_files = []

    for duplicate_file, original_file in duplicates:
        # Get just the filename without the path
        filename = os.path.basename(duplicate_file)

        # Create a unique name with more information
        dup_dirname = os.path.basename(os.path.dirname(duplicate_file))
        orig_filename = os.path.basename(original_file)
        base_name = os.path.splitext(filename)[0]
        ext = os.path.splitext(filename)[1]

        new_filename = f"{base_name}_from_{dup_dirname}{ext}"
        counter = 1

        # Ensure the filename is unique
        while os.path.exists(os.path.join(target_dir, new_filename)):
            new_filename = f"{base_name}_from_{dup_dirname}_{counter}{ext}"
            counter += 1

        dest_path = os.path.join(target_dir, new_filename)

        # Store info before moving
        moved_files.append(
            {
                "from": duplicate_file,
                "to": dest_path,
                "original": original_file,
                "size": os.path.getsize(duplicate_file),
                "mtime": datetime.datetime.fromtimestamp(
                    os.path.getmtime(duplicate_file)
                ).strftime("%Y-%m-%d %H:%M:%S"),
            }
        )

        # Move the file
        shutil.move(duplicate_file, dest_path)

    return moved_files


def format_file_path(path, base_dir):
    """
    Format a file path for display.
    Show it relative to base_dir if possible.
    """
    try:
        rel_path = os.path.relpath(path, base_dir)
        if not rel_path.startswith(".."):
            return rel_path
    except Exception as e:
        pass
    return path


def print_duplicates_summary(duplicates, base_dir):
    """Print a summary of duplicate files found."""
    if not duplicates:
        print("\n✅ No duplicate files found.")
        return

    total_size = sum(os.path.getsize(dup[0]) for dup in duplicates)
    print(
        f"\n🔍 Found {len(duplicates)} duplicate files (total size: {total_size / (1024*1024):.2f} MB)"
    )

    # Group by original file
    by_original = {}
    for dup, orig in duplicates:
        if orig not in by_original:
            by_original[orig] = []
        by_original[orig].append(dup)

    print("\nDuplicates grouped by original file:")
    for orig, dups in by_original.items():
        print(f"\n  📄 Original: {format_file_path(orig, base_dir)}")
        for dup in dups:
            print(f"      - {format_file_path(dup, base_dir)}")


def main():
    parser = argparse.ArgumentParser(
        description="Find duplicate PDF files in a directory and move them"
    )
    parser.add_argument("directory", help="Directory to scan for PDF files")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without moving any files",
    )
    parser.add_argument(
        "--keep",
        choices=["newest", "oldest", "shortest_path", "longest_path"],
        default="newest",
        help="Strategy for choosing which file to keep (default: newest)",
    )
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
    duplicates = find_duplicates(pdf_files, args.keep)

    print_duplicates_summary(duplicates, directory)

    if not duplicates:
        return

    if args.dry_run:
        print("\n⚠️ DRY RUN - No files were moved")
        return

    # Ask for confirmation before proceeding
    response = input("\nDo you want to move these duplicate files? (y/n): ")
    if response.lower() not in ["y", "yes"]:
        print("Operation cancelled.")
        return

    duplicates_dir = create_duplicates_folder(directory)
    print(f"\nCreated duplicates folder: {duplicates_dir}")

    moved_files = move_duplicates(duplicates, duplicates_dir)

    # Print summary of moved files
    print(f"\n✅ Moved {len(moved_files)} duplicate files to {duplicates_dir}")
    print("\nMoved files:")
    for file in moved_files:
        print(
            f"  • {format_file_path(file['from'], directory)} → {os.path.basename(file['to'])}"
        )
        print(f"    (duplicate of: {format_file_path(file['original'], directory)})")
        print(f"    Size: {file['size'] / 1024:.1f} KB, Modified: {file['mtime']}")


if __name__ == "__main__":
    main()
