import json

# Read the keys
with open('pims_stakeholder_keys.txt', 'r', encoding='utf-8') as f:
    keys = [line.strip() for line in f if line.strip()]

# Create translation data structure
data = {
    "languages": ["en", "es", "fr", "de", "lt", "pt", "it"],
    "translation": []
}

# Add each key
for key in keys:
    entry = {
        "key": key,
        "en": key,
        "es": key,
        "fr": key,
        "de": key,
        "lt": key,
        "pt": key,
        "it": key
    }
    data["translation"].append(entry)

# Write to JSON file
output_file = 'translations/modules/pims_stakeholder.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"Successfully created {output_file} with {len(keys)} translations")
