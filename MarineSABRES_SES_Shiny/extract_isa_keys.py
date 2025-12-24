import re

# Read the file
with open('modules/isa_data_entry_module.R', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract all i18n$t("...") patterns
pattern = r'i18n\$t\("([^"]+)"\)'
matches = re.findall(pattern, content)

# Get unique keys and sort them
unique_keys = sorted(set(matches))

# Write to file
with open('isa_data_entry_new_keys.txt', 'w', encoding='utf-8') as f:
    for key in unique_keys:
        f.write(key + '\n')

print(f"Extracted {len(unique_keys)} unique keys total")

# Find keys that are just the new ones we added (notifications and validation)
new_keys_patterns = [
    'Exercise', 'saved', 'Entry removed', 'Loop connection',
    'Please', 'Validation', 'OK', 'Goods & Benefits',
    'Ecosystem Services', 'Marine Processes', 'Pressures',
    'Activities', 'Drivers', 'loop connections'
]

new_keys = [k for k in unique_keys if any(pattern in k for pattern in new_keys_patterns)]

print(f"New keys added in this task: {len(new_keys)}")
print("\nNew keys:")
for key in new_keys:
    print(f"  - {key}")
