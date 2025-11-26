import json

# Read the new keys
keys = [
    "Loop detection failed or timed out.",
    "Error during loop detection:",
    "Loop detection failed:"
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

# Add to messages.json (error/failure messages)
added = add_keys_to_file('translations/common/messages.json', keys)

print(f"Added {added} keys to messages.json")
print(f"Total: {added} new translation keys")
