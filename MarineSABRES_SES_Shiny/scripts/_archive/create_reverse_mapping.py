#!/usr/bin/env python3
"""Create reverse mapping from namespaced keys to English text

This mapping enables the custom wrapper to translate:
  namespaced key → English text → shiny.i18n translation
"""

import json
from pathlib import Path

def main():
    print("=" * 70)
    print("Creating Reverse Key Mapping")
    print("=" * 70)
    print()

    # Load forward mapping (English → namespaced)
    with open('scripts/key_mapping_simple.json', 'r', encoding='utf-8') as f:
        forward_mapping = json.load(f)

    print(f"✓ Loaded {len(forward_mapping)} forward mappings")

    # Create reverse mapping (namespaced → English)
    reverse_mapping = {}
    duplicates = []

    for english_text, namespaced_key in forward_mapping.items():
        if namespaced_key in reverse_mapping:
            # Duplicate namespaced key - this is a problem
            duplicates.append({
                'key': namespaced_key,
                'text1': reverse_mapping[namespaced_key],
                'text2': english_text
            })
        else:
            reverse_mapping[namespaced_key] = english_text

    print(f"✓ Created {len(reverse_mapping)} reverse mappings")

    # Report duplicates
    if duplicates:
        print()
        print(f"⚠ Found {len(duplicates)} duplicate namespaced keys:")
        for dup in duplicates[:10]:
            print(f"  - {dup['key']}")
            print(f"    '{dup['text1']}'")
            print(f"    '{dup['text2']}'")
        if len(duplicates) > 10:
            print(f"  ... and {len(duplicates) - 10} more")

    # Save reverse mapping
    output_path = Path('scripts/reverse_key_mapping.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(reverse_mapping, f, indent=2, ensure_ascii=False)
        f.write('\n')

    print()
    print(f"✓ Saved reverse mapping to: {output_path}")
    print(f"  Entries: {len(reverse_mapping)}")
    print()
    print("=" * 70)
    print("NEXT STEP: Create wrapper function in translation_loader.R")

if __name__ == '__main__':
    main()
