#!/usr/bin/env python3
"""
Generate translations for AI ISA Assistant module strings
Flattens the categorized JSON and generates translations for all 7 languages
"""

import json
from deep_translator import GoogleTranslator

# Language codes
LANGUAGES = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'lt': 'Lithuanian',
    'pt': 'Portuguese',
    'it': 'Italian'
}

def flatten_strings(data):
    """Flatten categorized JSON into unique list of strings"""
    all_strings = []
    for category, strings in data.items():
        if isinstance(strings, list):
            all_strings.extend(strings)
    # Remove duplicates while preserving order
    seen = set()
    unique_strings = []
    for s in all_strings:
        if s not in seen:
            seen.add(s)
            unique_strings.append(s)
    return unique_strings

def translate_text(text, target_lang):
    """Translate text to target language"""
    if target_lang == 'en':
        return text

    try:
        translator = GoogleTranslator(source='en', target=target_lang)
        # Split long texts into chunks if needed
        if len(text) > 500:
            # Split by sentences
            sentences = text.split('. ')
            translated_sentences = []
            for sentence in sentences:
                if sentence:
                    trans = translator.translate(sentence)
                    translated_sentences.append(trans)
            return '. '.join(translated_sentences)
        else:
            return translator.translate(text)
    except Exception as e:
        print(f"Error translating '{text[:50]}...' to {target_lang}: {e}")
        return text  # Return original on error

def main():
    # Load categorized strings
    print("Loading AI ISA strings...")
    with open('ai_isa_assistant_all_strings.json', 'r', encoding='utf-8') as f:
        categorized_data = json.load(f)

    # Flatten to unique strings
    unique_strings = flatten_strings(categorized_data)
    print(f"Found {len(unique_strings)} unique strings to translate")

    # Generate translations
    translations = []

    for idx, text in enumerate(unique_strings, 1):
        try:
            print(f"\\nTranslating {idx}/{len(unique_strings)}: {text[:60]}...")
        except UnicodeEncodeError:
            print(f"\\nTranslating {idx}/{len(unique_strings)}: [text with special characters]")

        translation_entry = {"en": text}

        for lang_code in ['es', 'fr', 'de', 'lt', 'pt', 'it']:
            translated = translate_text(text, lang_code)
            translation_entry[lang_code] = translated
            # Avoid printing Unicode to console on Windows
            try:
                print(f"  {lang_code}: {translated[:60]}...")
            except UnicodeEncodeError:
                print(f"  {lang_code}: [translated]")

        translations.append(translation_entry)

    # Save results
    output_file = 'ai_isa_assistant_translations.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({"translation": translations}, f, indent=2, ensure_ascii=False)

    print(f"\\n✓ Translations saved to {output_file}")
    print(f"Total entries: {len(translations)}")

if __name__ == '__main__':
    main()
