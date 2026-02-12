#!/usr/bin/env python3
"""
Fix Norwegian translations for AI ISA Assistant module.
"""

import json
from pathlib import Path

def fix_norwegian_translations():
    """Fix Norwegian translations in ISA data entry JSON."""
    script_dir = Path(__file__).parent
    isa_file = script_dir.parent / 'translations' / 'modules' / 'isa_data_entry.json'

    if not isa_file.exists():
        print(f"ISA file not found: {isa_file}")
        return False

    print(f"Processing: {isa_file}")

    try:
        with open(isa_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Norwegian translations to update
        norwegian_updates = {
            "modules.isa.ai_assistant.your_ses_model_progress": "Din SES-modellfremdrift",
            "modules.isa.ai_assistant.welcome_message": "Hei! Jeg er din AI-assistent for å lage en DAPSI(W)R(M)-modell. La oss starte med å velge ditt regionale hav eller osean. Dette hjelper meg å gi relevante forslag for ditt område."
        }

        updated_count = 0
        for entry in data.get('translation', []):
            key = entry.get('key')
            if key in norwegian_updates:
                old_value = entry.get('no', '')
                new_value = norwegian_updates[key]
                if old_value != new_value:
                    entry['no'] = new_value
                    updated_count += 1
                    print(f"  [OK] Updated '{key}'")
                    print(f"       Old: {old_value}")
                    print(f"       New: {new_value}")

        # Write back to file
        with open(isa_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\n  [COMPLETE] Updated {updated_count} Norwegian translations")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def update_merged_translations():
    """Update merged translations file."""
    script_dir = Path(__file__).parent
    merged_file = script_dir.parent / 'translations' / '_merged_translations.json'

    if not merged_file.exists():
        print(f"Merged file not found: {merged_file}")
        return False

    print(f"\nProcessing: {merged_file}")

    try:
        with open(merged_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Norwegian translations to update
        norwegian_updates = {
            "modules.isa.ai_assistant.your_ses_model_progress": "Din SES-modellfremdrift",
            "modules.isa.ai_assistant.welcome_message": "Hei! Jeg er din AI-assistent for å lage en DAPSI(W)R(M)-modell. La oss starte med å velge ditt regionale hav eller osean. Dette hjelper meg å gi relevante forslag for ditt område."
        }

        updated_count = 0
        for entry in data.get('translation', []):
            key = entry.get('key')
            if key in norwegian_updates:
                old_value = entry.get('no', '')
                new_value = norwegian_updates[key]
                if old_value != new_value:
                    entry['no'] = new_value
                    updated_count += 1
                    print(f"  [OK] Updated '{key}' in merged file")

        # Write back to file
        with open(merged_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"  [COMPLETE] Updated {updated_count} entries in merged file")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Fixing Norwegian translations for AI ISA Assistant")
    print("=" * 70)
    print()

    success1 = fix_norwegian_translations()
    success2 = update_merged_translations()

    print()
    print("=" * 70)
    if success1 and success2:
        print("Processing complete: Norwegian translations fixed")
        print()
        print("Translations updated:")
        print("  - Your SES Model Progress -> Din SES-modellfremdrift")
        print("  - Welcome message -> Norwegian translation")
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
