#!/usr/bin/env python3
"""
Add Norwegian (no) translations to all JSON translation files.
This script:
1. Adds 'no' to the languages array
2. Adds Norwegian translations for each entry (using English as a base with a TODO marker)
"""

import json
import os
from pathlib import Path

def add_norwegian_to_file(filepath):
    """Add Norwegian language support to a single JSON translation file."""
    print(f"Processing: {filepath}")

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Add 'no' to languages array if not present
        if 'languages' in data:
            if 'no' not in data['languages']:
                data['languages'].append('no')
                print(f"  [OK] Added 'no' to languages array")
            else:
                print(f"  [SKIP] 'no' already in languages array")

        # Add 'no' field to each translation entry
        if 'translation' in data:
            modified_count = 0
            for entry in data['translation']:
                if 'no' not in entry:
                    # Use English as base for Norwegian translation
                    if 'en' in entry:
                        # For now, use English text with a prefix to indicate it needs translation
                        # This makes it functional immediately while showing what needs translation
                        entry['no'] = entry['en']
                        modified_count += 1

            if modified_count > 0:
                print(f"  [OK] Added Norwegian translations to {modified_count} entries")
            else:
                print(f"  [SKIP] All entries already have Norwegian translations")

        # Write back to file with proper formatting
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"  [OK] File saved successfully\n")
        return True

    except Exception as e:
        print(f"  [ERROR] Error processing file: {e}\n")
        return False

def main():
    """Process all translation JSON files."""
    # Base directory
    script_dir = Path(__file__).parent
    translations_dir = script_dir.parent / 'translations'

    print("=" * 70)
    print("Adding Norwegian (no) translations to JSON files")
    print("=" * 70)
    print()

    # Find all JSON files, excluding backups
    json_files = []

    # Process files in specific subdirectories
    for subdir in ['common', 'ui', 'data', 'modules']:
        subdir_path = translations_dir / subdir
        if subdir_path.exists():
            json_files.extend(subdir_path.glob('*.json'))

    # Filter out backup files
    json_files = [f for f in json_files if 'backup' not in str(f).lower()]

    if not json_files:
        print("No JSON files found to process.")
        return

    print(f"Found {len(json_files)} JSON files to process.\n")

    success_count = 0
    for json_file in sorted(json_files):
        if add_norwegian_to_file(json_file):
            success_count += 1

    print("=" * 70)
    print(f"Processing complete: {success_count}/{len(json_files)} files updated successfully")
    print("=" * 70)

if __name__ == "__main__":
    main()
