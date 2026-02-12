#!/usr/bin/env python3
# Generate translations for missing template strings

import json
from deep_translator import GoogleTranslator

# Load missing strings
with open('missing_template_strings.txt', 'r', encoding='utf-8') as f:
    missing_strings = [line.strip() for line in f if line.strip()]

print(f"Generating translations for {len(missing_strings)} template strings...")

# Target languages
target_langs = {
    'es': 'spanish',
    'fr': 'french',
    'de': 'german',
    'lt': 'lithuanian',
    'pt': 'portuguese',
    'it': 'italian'
}

def translate_text(text, target_lang):
    if target_lang == 'en':
        return text
    try:
        translator = GoogleTranslator(source='en', target=target_lang)
        return translator.translate(text)
    except Exception as e:
        print(f"Error translating '{text[:50]}...' to {target_lang}: {e}")
        return text

# Generate translations
translations = []

for idx, text in enumerate(missing_strings, 1):
    try:
        print(f"\n[{idx}/{len(missing_strings)}] Translating: {text[:60]}...")
    except UnicodeEncodeError:
        print(f"\n[{idx}/{len(missing_strings)}] Translating: [text with special characters]")

    entry = {'en': text}

    for lang_code, lang_name in target_langs.items():
        translated = translate_text(text, lang_code)
        entry[lang_code] = translated
        try:
            print(f"  {lang_code}: {translated[:60]}...")
        except UnicodeEncodeError:
            print(f"  {lang_code}: [translated]")

    translations.append(entry)

# Create output with proper structure (with languages field!)
output = {
    'languages': ['en', 'es', 'fr', 'de', 'lt', 'pt', 'it'],
    'translation': translations
}

# Save
output_file = 'template_translations.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print(f"\n✓ Generated {len(translations)} translations")
print(f"✓ Saved to {output_file}")
print(f"✓ Total translation entries: {len(translations)} × 7 languages = {len(translations) * 7} translations")
