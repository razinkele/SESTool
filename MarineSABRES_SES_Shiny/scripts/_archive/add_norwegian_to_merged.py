#!/usr/bin/env python3
"""
Add Norwegian (no) translations to the merged translations file.
"""

import json
from pathlib import Path

def add_norwegian_to_merged():
    """Add Norwegian language support to the merged translation file."""

    script_dir = Path(__file__).parent
    merged_file = script_dir.parent / 'translations' / '_merged_translations.json'

    if not merged_file.exists():
        print(f"Merged file not found: {merged_file}")
        return False

    print(f"Processing: {merged_file}")

    try:
        with open(merged_file, 'r', encoding='utf-8') as f:
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
                        entry['no'] = entry['en']
                        modified_count += 1

            if modified_count > 0:
                print(f"  [OK] Added Norwegian translations to {modified_count} entries")
            else:
                print(f"  [SKIP] All entries already have Norwegian translations")

        # Write back to file with proper formatting
        with open(merged_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"  [OK] File saved successfully")
        return True

    except Exception as e:
        print(f"  [ERROR] Error processing file: {e}")
        return False

if __name__ == "__main__":
    print("=" * 70)
    print("Adding Norwegian (no) translations to merged translations file")
    print("=" * 70)
    print()

    success = add_norwegian_to_merged()

    print()
    print("=" * 70)
    if success:
        print("Processing complete: Merged file updated successfully")
    else:
        print("Processing failed")
    print("=" * 70)
