#!/usr/bin/env python3
"""
Remove duplicate response.measures keys from files that have wrong values.
Keep only the correct versions in response_measures.json.
"""

import json
import os

# Keys to remove (they should only exist in response_measures.json)
KEYS_TO_REMOVE = [
    "modules.response.measures.activities",
    "modules.response.measures.drivers",
    "modules.response.measures.pressures",
    "modules.response.measures.state_changes",
    "modules.response.measures.impacts",
    "modules.response.measures.welfare",
    "modules.response.measures.responses"
]

# Files to clean (do NOT include response_measures.json)
FILES_TO_CLEAN = [
    "translations/modules/entry_point.json",
    "translations/modules/isa_data_entry.json",
    "translations/modules/scenario_builder.json",
    "translations/modules/ses_creation.json"
]

def remove_keys_from_file(filepath, keys_to_remove):
    """Remove specified keys from a JSON file."""
    if not os.path.exists(filepath):
        print(f"WARNING: File not found: {filepath}")
        return 0

    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    removed_count = 0
    # Keys are nested under "translation" object
    if "translation" in data:
        for key in keys_to_remove:
            if key in data["translation"]:
                del data["translation"][key]
                removed_count += 1
                print(f"  - Removed '{key}' from {os.path.basename(filepath)}")
    else:
        print(f"  WARNING: No 'translation' key found in {filepath}")

    if removed_count > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  SAVED {filepath} ({removed_count} keys removed)")

    return removed_count

def main():
    print("=" * 70)
    print("Removing duplicate response.measures keys from files with wrong values")
    print("=" * 70)
    print()

    total_removed = 0

    for filepath in FILES_TO_CLEAN:
        print(f"Processing {filepath}...")
        count = remove_keys_from_file(filepath, KEYS_TO_REMOVE)
        total_removed += count
        print()

    print("=" * 70)
    print(f"Complete! Removed {total_removed} duplicate keys total")
    print()
    print("Next step: Run the merge script to update _merged_translations.json")
    print("  Rscript scripts/merge_translations.R")
    print("=" * 70)

if __name__ == "__main__":
    main()
