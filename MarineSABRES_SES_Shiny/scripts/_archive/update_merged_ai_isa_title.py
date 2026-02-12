#!/usr/bin/env python3
"""
Add AI-Assisted ISA Creation translations to merged file.
"""

import json
from pathlib import Path

def update_merged_translations():
    """Add AI ISA title translations to merged file."""
    script_dir = Path(__file__).parent
    merged_file = script_dir.parent / 'translations' / '_merged_translations.json'

    if not merged_file.exists():
        print(f"Merged file not found: {merged_file}")
        return False

    print(f"Processing: {merged_file}")

    try:
        with open(merged_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # New entries
        new_entries = [
            {
                "key": "modules.isa.ai_assistant.ai_assisted_isa_creation",
                "en": "AI-Assisted ISA Creation",
                "es": "Creación ISA Asistida por IA",
                "fr": "Création ISA Assistée par IA",
                "de": "KI-unterstützte ISA-Erstellung",
                "lt": "AI vadovaujama ISA kūrimas",
                "pt": "Criação ISA Assistida por IA",
                "it": "Creazione ISA Assistita da IA",
                "no": "AI-assistert ISA-opprettelse"
            },
            {
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
        ]

        # Check and add/update entries
        existing_keys = [entry.get('key') for entry in data.get('translation', [])]
        added_count = 0
        updated_count = 0

        for new_entry in new_entries:
            if new_entry['key'] in existing_keys:
                # Update existing entry
                for entry in data['translation']:
                    if entry.get('key') == new_entry['key']:
                        entry.update(new_entry)
                        updated_count += 1
                        print(f"  [OK] Updated: {new_entry['key']}")
                        break
            else:
                # Add new entry
                data['translation'].insert(0, new_entry)
                added_count += 1
                print(f"  [OK] Added: {new_entry['key']}")

        # Write back to file
        with open(merged_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\n  [COMPLETE] Added: {added_count}, Updated: {updated_count}")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Updating merged translations with AI ISA title")
    print("=" * 70)
    print()

    success = update_merged_translations()

    print()
    print("=" * 70)
    if success:
        print("Processing complete")
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
