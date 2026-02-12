#!/usr/bin/env python3
"""Generate translations for remaining missing strings"""

import json
from deep_translator import GoogleTranslator

# Load missing strings
with open('remaining_missing_strings.txt', 'r', encoding='utf-8') as f:
    strings = [line.strip() for line in f if line.strip()]

print(f"Generating translations for {len(strings)} strings...\n")

# Target languages
languages = {
    'es': 'spanish',
    'fr': 'french',
    'de': 'german',
    'lt': 'lithuanian',
    'pt': 'portuguese',
    'it': 'italian'
}

translations = []

for i, text in enumerate(strings, 1):
    print(f"[{i}/{len(strings)}] Translating: {text[:50]}...")

    entry = {'en': text}

    for lang_code, lang_name in languages.items():
        try:
            translated = GoogleTranslator(source='english', target=lang_code).translate(text)
            entry[lang_code] = translated
            print(f"  {lang_code}: {translated[:50]}...")
        except Exception as e:
            print(f"  {lang_code}: ERROR - {e}")
            entry[lang_code] = text  # Fallback to English

    translations.append(entry)
    print()

# Create output with proper structure
output = {
    'languages': ['en', 'es', 'fr', 'de', 'lt', 'pt', 'it'],
    'translation': translations
}

# Save
with open('remaining_translations.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print(f"✓ Generated {len(translations)} translations")
print("✓ Saved to remaining_translations.json")
