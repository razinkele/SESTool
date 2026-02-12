#!/usr/bin/env python3
"""
Generate AI translations for Scenario Builder module using Claude
"""

import json
import os
from anthropic import Anthropic

def load_texts(filepath):
    """Load the texts to translate from JSON file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_translations(data, filepath):
    """Save translations to JSON file"""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Saved translations to: {filepath}")

def translate_batch(client, texts_batch, target_langs):
    """Translate a batch of texts to all target languages using Claude"""

    # Prepare the texts for translation
    texts_list = [item['en'] for item in texts_batch]

    prompt = f"""You are a professional translator specializing in marine science and environmental management software.

Translate the following {len(texts_list)} English texts into Spanish (ES), French (FR), German (DE), Lithuanian (LT), Portuguese (PT), and Italian (IT).

Context: These texts are from a "Scenario Builder" module in a marine social-ecological systems analysis application. The module allows users to create and analyze "what-if" scenarios by modifying causal loop diagrams.

Important guidelines:
1. Maintain technical accuracy for scientific/technical terms
2. Keep the tone professional but accessible
3. Preserve any formatting markers or special characters
4. For UI elements, use concise translations appropriate for buttons/labels
5. DAPSI(W)R(M) is a framework acronym - keep it as-is
6. "CLD" stands for "Causal Loop Diagram" - keep as CLD in translations

Return ONLY a valid JSON array with this exact structure for each text:
[
  {{
    "en": "original English text",
    "es": "Spanish translation",
    "fr": "French translation",
    "de": "German translation",
    "lt": "Lithuanian translation",
    "pt": "Portuguese translation",
    "it": "Italian translation"
  }},
  ...
]

English texts to translate:
{json.dumps(texts_list, ensure_ascii=False, indent=2)}

Provide the complete JSON array:"""

    try:
        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=16000,
            temperature=0.3,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )

        # Extract JSON from response
        response_text = message.content[0].text

        # Try to parse the response as JSON
        # Sometimes Claude wraps it in markdown code blocks
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()

        translations = json.loads(response_text)
        return translations

    except Exception as e:
        print(f"Error translating batch: {e}")
        print(f"Response: {message.content[0].text if 'message' in locals() else 'No response'}")
        return None

def main():
    # Initialize Anthropic client
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: ANTHROPIC_API_KEY environment variable not set")
        return

    client = Anthropic(api_key=api_key)

    # File paths
    base_dir = "C:/Users/DELL/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny"
    input_file = f"{base_dir}/scenario_builder_texts_to_translate.json"
    output_file = f"{base_dir}/scenario_builder_translations.json"

    # Load texts
    print("Loading texts to translate...")
    texts_to_translate = load_texts(input_file)
    total_texts = len(texts_to_translate)
    print(f"Found {total_texts} texts to translate")

    # Target languages
    target_langs = ["es", "fr", "de", "lt", "pt", "it"]

    # Translate in batches (Claude can handle quite a bit in one request)
    batch_size = 30  # Process 30 texts at a time
    all_translations = []

    for i in range(0, total_texts, batch_size):
        batch_end = min(i + batch_size, total_texts)
        batch = texts_to_translate[i:batch_end]

        print(f"\nTranslating batch {i//batch_size + 1} ({i+1}-{batch_end} of {total_texts})...")

        translations = translate_batch(client, batch, target_langs)

        if translations:
            all_translations.extend(translations)
            print(f"✓ Successfully translated {len(translations)} texts")
        else:
            print(f"✗ Failed to translate batch {i//batch_size + 1}")
            # Add empty translations as fallback
            for item in batch:
                all_translations.append(item)

    # Save all translations
    save_translations(all_translations, output_file)

    print(f"\n{'='*60}")
    print(f"Translation Summary:")
    print(f"  Total texts: {total_texts}")
    print(f"  Successfully translated: {len([t for t in all_translations if t.get('es', '')])}")
    print(f"  Output file: {output_file}")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()
