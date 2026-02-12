#!/usr/bin/env python3
"""
Add proper Norwegian translations for navigation items.
"""

import json
from pathlib import Path

# Norwegian translations for navigation items
NAVIGATION_NORWEGIAN_TRANSLATIONS = {
    "About": "Om",
    "App Settings": "App-innstillinger",
    "Application Settings": "Programinnstillinger",
    "Auto-save helps prevent data loss from unexpected disconnections.": "Automatisk lagring forhindrer tap av data ved uventede frakoblinger.",
    "Auto-Save Settings": "Innstillinger for automatisk lagring",
}

def translate_navigation():
    """Translate navigation Norwegian entries."""
    script_dir = Path(__file__).parent
    navigation_file = script_dir.parent / 'translations' / 'common' / 'navigation.json'

    if not navigation_file.exists():
        print(f"Navigation file not found: {navigation_file}")
        return False

    print(f"Processing: {navigation_file}")

    try:
        with open(navigation_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if 'translation' not in data:
            print(f"  [ERROR] No translation array found")
            return False

        translated_count = 0
        for entry in data['translation']:
            if 'no' in entry and 'en' in entry:
                english_text = entry['en']
                # Check if we have a Norwegian translation for this English text
                if english_text in NAVIGATION_NORWEGIAN_TRANSLATIONS:
                    old_value = entry['no']
                    entry['no'] = NAVIGATION_NORWEGIAN_TRANSLATIONS[english_text]
                    if old_value != entry['no']:
                        translated_count += 1
                        print(f"  [OK] '{english_text}' -> '{entry['no']}'")

        # Write back to file
        with open(navigation_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\n  [COMPLETE] Translated {translated_count} navigation entries")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Adding Norwegian translations for navigation items")
    print("=" * 70)
    print()

    success = translate_navigation()

    print()
    print("=" * 70)
    if success:
        print(f"Processing complete: {len(NAVIGATION_NORWEGIAN_TRANSLATIONS)} navigation translations available")
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
