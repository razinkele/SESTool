#!/usr/bin/env python3
"""
Add translation for "AI-Assisted ISA Creation" module title.
"""

import json
from pathlib import Path

def add_ai_isa_title_translation():
    """Add AI-Assisted ISA Creation translation to ISA data entry JSON."""
    script_dir = Path(__file__).parent
    isa_file = script_dir.parent / 'translations' / 'modules' / 'isa_data_entry.json'

    if not isa_file.exists():
        print(f"ISA file not found: {isa_file}")
        return False

    print(f"Processing: {isa_file}")

    try:
        with open(isa_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # New translation entry
        new_entry = {
            "key": "modules.isa.ai_assistant.ai_assisted_isa_creation",
            "en": "AI-Assisted ISA Creation",
            "es": "Creación ISA Asistida por IA",
            "fr": "Création ISA Assistée par IA",
            "de": "KI-unterstützte ISA-Erstellung",
            "lt": "AI vadovaujama ISA kūrimas",
            "pt": "Criação ISA Assistida por IA",
            "it": "Creazione ISA Assistita da IA",
            "no": "AI-assistert ISA-opprettelse"
        }

        # Check if the key already exists
        existing_keys = [entry.get('key') for entry in data.get('translation', [])]
        if new_entry['key'] in existing_keys:
            print(f"  [INFO] Key '{new_entry['key']}' already exists")
            # Update the Norwegian translation if it exists
            for entry in data['translation']:
                if entry.get('key') == new_entry['key']:
                    entry['no'] = new_entry['no']
                    print(f"  [OK] Updated Norwegian translation to: {new_entry['no']}")
                    break
        else:
            # Add the new entry at the beginning of the translations array
            data['translation'].insert(0, new_entry)
            print(f"  [OK] Added new translation entry with Norwegian: {new_entry['no']}")

        # Write back to file
        with open(isa_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"  [OK] File saved successfully")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def add_subtitle_translation():
    """Add subtitle translation."""
    script_dir = Path(__file__).parent
    isa_file = script_dir.parent / 'translations' / 'modules' / 'isa_data_entry.json'

    try:
        with open(isa_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # New subtitle entry
        subtitle_entry = {
            "key": "modules.isa.ai_assistant.subtitle",
            "en": "Let me guide you step-by-step through building your DAPSI(W)R(M) model.",
            "es": "Permíteme guiarte paso a paso en la construcción de tu modelo DAPSI(W)R(M).",
            "fr": "Laissez-moi vous guider étape par étape dans la construction de votre modèle DAPSI(W)R(M).",
            "de": "Lassen Sie mich Sie Schritt für Schritt durch den Aufbau Ihres DAPSI(W)R(M)-Modells führen.",
            "lt": "Leiskite man žingsnis po žingsnio padėti kurti DAPSI(W)R(M) modelį.",
            "pt": "Deixe-me guiá-lo passo a passo na construção do seu modelo DAPSI(W)R(M).",
            "it": "Lascia che ti guidi passo dopo passo nella costruzione del tuo modello DAPSI(W)R(M).",
            "no": "La meg veilede deg trinn for trinn gjennom å bygge din DAPSI(W)R(M)-modell."
        }

        # Check if the key already exists
        existing_keys = [entry.get('key') for entry in data.get('translation', [])]
        if subtitle_entry['key'] in existing_keys:
            print(f"  [INFO] Subtitle key already exists")
            for entry in data['translation']:
                if entry.get('key') == subtitle_entry['key']:
                    entry['no'] = subtitle_entry['no']
                    print(f"  [OK] Updated subtitle Norwegian translation")
                    break
        else:
            data['translation'].insert(1, subtitle_entry)
            print(f"  [OK] Added subtitle translation entry")

        # Write back to file
        with open(isa_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Adding Norwegian translation for AI-Assisted ISA Creation title")
    print("=" * 70)
    print()

    success1 = add_ai_isa_title_translation()
    success2 = add_subtitle_translation()

    print()
    print("=" * 70)
    if success1 and success2:
        print("Processing complete: Translations added")
        print()
        print("Next step: Update ai_isa_assistant_module.R line 231 to use:")
        print('  i18n$t("modules.isa.ai_assistant.ai_assisted_isa_creation")')
        print("  and")
        print('  i18n$t("modules.isa.ai_assistant.subtitle")')
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
