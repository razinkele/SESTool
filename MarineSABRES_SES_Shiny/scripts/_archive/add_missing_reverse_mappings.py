#!/usr/bin/env python3
"""
Add missing reverse key mappings for AI ISA Assistant module.
"""

import json
from pathlib import Path

def add_missing_mappings():
    """Add missing reverse key mappings."""
    script_dir = Path(__file__).parent
    reverse_mapping_file = script_dir / 'reverse_key_mapping.json'

    if not reverse_mapping_file.exists():
        print(f"Reverse mapping file not found: {reverse_mapping_file}")
        return False

    print(f"Processing: {reverse_mapping_file}")

    try:
        with open(reverse_mapping_file, 'r', encoding='utf-8') as f:
            mapping = json.load(f)

        # Keys to add
        new_mappings = {
            "modules.isa.ai_assistant.ai_assisted_isa_creation": "AI-Assisted ISA Creation",
            "modules.isa.ai_assistant.subtitle": "Let me guide you step-by-step through building your DAPSI(W)R(M) model.",
            "modules.isa.ai_assistant.welcome_message": "Welcome! I'm here to help you build a comprehensive DAPSI(W)R(M) framework for your marine ecosystem."
        }

        added_count = 0
        updated_count = 0

        for key, english_text in new_mappings.items():
            if key in mapping:
                if mapping[key] != english_text:
                    mapping[key] = english_text
                    updated_count += 1
                    print(f"  [OK] Updated: {key}")
                else:
                    print(f"  [SKIP] Already exists: {key}")
            else:
                mapping[key] = english_text
                added_count += 1
                print(f"  [OK] Added: {key} -> {english_text}")

        # Write back to file with sorted keys for readability
        with open(reverse_mapping_file, 'w', encoding='utf-8') as f:
            json.dump(mapping, f, ensure_ascii=False, indent=2, sort_keys=True)

        print(f"\n  [COMPLETE] Added: {added_count}, Updated: {updated_count}")
        print(f"  Total mappings in file: {len(mapping)}")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Adding missing reverse key mappings for AI ISA Assistant")
    print("=" * 70)
    print()

    success = add_missing_mappings()

    print()
    print("=" * 70)
    if success:
        print("Processing complete")
        print()
        print("The translation keys should now work correctly!")
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
