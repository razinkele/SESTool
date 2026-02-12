#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Remove duplicate translation keys from translation.json
Keeps the first occurrence of each unique English key
"""

import json
import sys

def remove_duplicates(json_file_path):
    """Remove duplicate translation entries based on English key"""

    try:
        # Read existing translation file
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        initial_count = len(data['translation'])

        # Use a dictionary to track unique entries by English key
        seen = {}
        unique_translations = []

        for entry in data['translation']:
            en_key = entry['en']
            if en_key not in seen:
                seen[en_key] = True
                unique_translations.append(entry)

        # Update data with deduplicated translations
        data['translation'] = unique_translations

        final_count = len(data['translation'])
        removed_count = initial_count - final_count

        # Write back to file
        with open(json_file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)

        print(f"[OK] Successfully removed {removed_count} duplicate entries")
        print(f"[OK] Total entries: {initial_count} -> {final_count}")
        print(f"[OK] All entries now have unique English keys")

        return True

    except FileNotFoundError:
        print(f"[ERROR] Translation file not found: {json_file_path}")
        return False
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON in translation file: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Failed to remove duplicates: {e}")
        return False


if __name__ == "__main__":
    translation_file = "translations/translation.json"

    print("=" * 60)
    print("Translation Deduplication")
    print("=" * 60)
    print(f"Target file: {translation_file}")
    print("=" * 60)

    success = remove_duplicates(translation_file)

    if success:
        print("\n[OK] Duplicates removed successfully!")
        sys.exit(0)
    else:
        print("\n[ERROR] Failed to remove duplicates")
        sys.exit(1)
