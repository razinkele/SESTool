import json

# Read the new keys
with open('isa_new_keys_only.txt', 'r', encoding='utf-8') as f:
    keys = [line.strip() for line in f if line.strip()]

# Categorize keys
messages_keys = [
    "Entry removed",
    "Exercise 0 saved successfully!",
    "Exercise 1 saved:",
    "Exercise 2a saved:",
    "Exercise 2b saved:",
    "Exercise 3 saved:",
    "Exercise 4 saved:",
    "Exercise 5 saved:",
    "Exercise 6 saved:",
    "Loop connection added"
]

validation_keys = [
    " Validation Errors",
    "Please add at least one Ecosystem Service entry before saving.",
    "Please add at least one Good/Benefit entry before saving.",
    "Please add at least one valid Ecosystem Service entry.",
    "Please add at least one valid Good/Benefit entry.",
    "Please fix the following issues before saving:"
]

labels_keys = [
    "Activities",
    "Drivers",
    "Ecosystem Services",
    "Goods & Benefits",
    "Marine Processes",
    "Pressures",
    "loop connections",
    "OK"
]

def add_keys_to_file(file_path, keys_to_add):
    """Add keys to a translation file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Get existing keys
    existing_keys = {item['key'] for item in data['translation']}

    # Add new keys
    added_count = 0
    for key in keys_to_add:
        if key not in existing_keys:
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
            data['translation'].append(entry)
            added_count += 1

    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    return added_count

# Add to appropriate files
messages_added = add_keys_to_file('translations/common/messages.json', messages_keys)
validation_added = add_keys_to_file('translations/common/validation.json', validation_keys)
labels_added = add_keys_to_file('translations/common/labels.json', labels_keys)

print(f"Added {messages_added} keys to messages.json")
print(f"Added {validation_added} keys to validation.json")
print(f"Added {labels_added} keys to labels.json")
print(f"Total: {messages_added + validation_added + labels_added} new translation keys")
