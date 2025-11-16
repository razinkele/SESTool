#!/usr/bin/env python3
"""
Add remaining Dashboard ISA component translations (with colons) to translation.json
"""

import json
from pathlib import Path

# ISA component translations with colons (as used in Dashboard)
ISA_DASHBOARD_TRANSLATIONS = {
    "Goods & Benefits:": {
        "es": "Bienes y Beneficios:",
        "fr": "Biens et Avantages :",
        "de": "Güter und Vorteile:",
        "lt": "Gėrybės ir naudos:",
        "pt": "Bens e Benefícios:",
        "it": "Beni e Benefici:"
    },
    "Ecosystem Services:": {
        "es": "Servicios Ecosistémicos:",
        "fr": "Services Écosystémiques :",
        "de": "Ökosystemleistungen:",
        "lt": "Ekosistemų paslaugos:",
        "pt": "Serviços Ecossistêmicos:",
        "it": "Servizi Ecosistemici:"
    },
    "Marine Processes:": {
        "es": "Procesos Marinos:",
        "fr": "Processus Marins :",
        "de": "Marine Prozesse:",
        "lt": "Jūriniai procesai:",
        "pt": "Processos Marinhos:",
        "it": "Processi Marini:"
    },
    "Pressures:": {
        "es": "Presiones:",
        "fr": "Pressions :",
        "de": "Belastungen:",
        "lt": "Spaudimai:",
        "pt": "Pressões:",
        "it": "Pressioni:"
    },
    "Activities:": {
        "es": "Actividades:",
        "fr": "Activités :",
        "de": "Aktivitäten:",
        "lt": "Veiklos:",
        "pt": "Atividades:",
        "it": "Attività:"
    },
    "Drivers:": {
        "es": "Impulsores:",
        "fr": "Facteurs de Changement :",
        "de": "Treiber:",
        "lt": "Veiksniai:",
        "pt": "Impulsionadores:",
        "it": "Fattori di Cambiamento:"
    }
}

# Load existing translations
trans_path = Path("translations/translation.json")
with open(trans_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Get existing English keys
existing_keys = {entry['en'] for entry in data['translation']}

# Add new translations
added_count = 0
for eng_text, translations in ISA_DASHBOARD_TRANSLATIONS.items():
    if eng_text not in existing_keys:
        entry = {
            "en": eng_text,
            "es": translations["es"],
            "fr": translations["fr"],
            "de": translations["de"],
            "lt": translations["lt"],
            "pt": translations["pt"],
            "it": translations["it"]
        }
        data['translation'].append(entry)
        added_count += 1
        print(f"[ADDED] {eng_text}")
    else:
        print(f"[EXISTS] {eng_text}")

# Save updated translations
with open(trans_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n{'='*60}")
print(f"Dashboard ISA Component Translation Summary:")
print(f"  New translations added: {added_count}")
print(f"  Already existed: {len(ISA_DASHBOARD_TRANSLATIONS) - added_count}")
print(f"  Total strings: {len(ISA_DASHBOARD_TRANSLATIONS)}")
print(f"{'='*60}")
print(f"\nUpdated translation.json successfully!")
print(f"Total entries now: {len(data['translation'])}")
