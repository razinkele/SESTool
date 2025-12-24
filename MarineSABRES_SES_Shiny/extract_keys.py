import re

# Read the file
with open('modules/pims_stakeholder_module.R', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract all i18n$t("...") patterns
pattern = r'i18n\$t\("([^"]+)"\)'
matches = re.findall(pattern, content)

# Get unique keys and sort them
unique_keys = sorted(set(matches))

# Write to file
with open('pims_stakeholder_keys.txt', 'w', encoding='utf-8') as f:
    for key in unique_keys:
        f.write(key + '\n')

print(f"Extracted {len(unique_keys)} unique keys")
