import json
import re
from pathlib import Path
from collections import defaultdict, Counter

print('=' * 80)
print('TRANSLATION ANALYSIS REPORT')
print('=' * 80)

# 1. Load translation.json
print('\n1. ANALYZING TRANSLATION.JSON')
print('-' * 80)

with open('translations/translation.json', 'r', encoding='utf-8') as f:
    translations = json.load(f)

languages = translations.get('languages', [])
translation_array = translations.get('translation', [])

print(f'Supported languages: {", ".join(languages)}')
print(f'Total translation entries: {len(translation_array)}')

# Extract all keys (using English text as key)
json_keys = set()
for entry in translation_array:
    if 'en' in entry:
        json_keys.add(entry['en'])

print(f'Unique translation keys: {len(json_keys)}')

# Check for duplicates
all_en_keys = [entry['en'] for entry in translation_array if 'en' in entry]
duplicates = [k for k in set(all_en_keys) if all_en_keys.count(k) > 1]
if duplicates:
    print(f'\nWARNING: Found {len(duplicates)} duplicate keys:')
    for dup in duplicates[:10]:
        print(f'  - "{dup[:60]}..."')

# Check for missing translations by language
print(f'\nTranslation completeness by language:')
for lang in languages:
    missing = sum(1 for entry in translation_array if lang not in entry or not entry[lang])
    if missing > 0:
        print(f'  {lang}: {len(translation_array) - missing}/{len(translation_array)} ({missing} missing)')
    else:
        print(f'  {lang}: Complete')

# 2. Extract i18n$t() calls from R files
print('\n\n2. ANALYZING R FILES FOR i18n$t() USAGE')
print('-' * 80)

r_files = [f for f in Path('.').rglob('*.R') 
           if 'temp_files_backup' not in str(f) 
           and '.Rproj.user' not in str(f)]

print(f'Scanning {len(r_files)} R files...')

# Match i18n$t("key") or i18n$t('key')
pattern = r'i18n\$t\(["\']([^"\'\\]*)["\']\)'

used_keys = []
usage_by_file = defaultdict(list)

for r_file in r_files:
    try:
        content = r_file.read_text(encoding='utf-8')
        matches = re.findall(pattern, content)
        for key in matches:
            used_keys.append(key)
            usage_by_file[str(r_file)].append(key)
    except Exception as e:
        print(f'Error reading {r_file}: {e}')

print(f'Found {len(used_keys)} i18n$t() calls')
print(f'Unique keys referenced: {len(set(used_keys))}')

# 3. Cross-reference analysis
print('\n\n3. CROSS-REFERENCE ANALYSIS')
print('-' * 80)

used_keys_set = set(used_keys)

# Find keys defined but never used
unused_keys = json_keys - used_keys_set
if unused_keys:
    print(f'\nKeys defined in translation.json but NEVER USED ({len(unused_keys)}):')
    for key in sorted(list(unused_keys))[:20]:
        print(f'  - "{key[:70]}"')
    if len(unused_keys) > 20:
        print(f'  ... and {len(unused_keys) - 20} more')
else:
    print('\nAll translation keys are used in the codebase.')

# Find keys used but missing from translation.json
missing_keys = used_keys_set - json_keys
if missing_keys:
    print(f'\n\nWARNING: Keys used in code but MISSING from translation.json ({len(missing_keys)}):')
    for key in sorted(list(missing_keys))[:30]:
        # Show where it's used
        files = [f for f, keys in usage_by_file.items() if key in keys]
        print(f'  - "{key[:60]}"')
        if files:
            print(f'    Used in: {Path(files[0]).name}')
    if len(missing_keys) > 30:
        print(f'  ... and {len(missing_keys) - 30} more')
else:
    print('\n\nAll used keys are defined in translation.json.')

# 4. Key format analysis
print('\n\n4. KEY FORMAT CONSISTENCY')
print('-' * 80)

all_keys = json_keys.union(used_keys_set)

camelCase = [k for k in all_keys if re.search(r'[a-z][A-Z]', k)]
snake_case = [k for k in all_keys if '_' in k and not ' ' in k]
kebab_case = [k for k in all_keys if '-' in k and not ' ' in k]
sentence_case = [k for k in all_keys if ' ' in k]

print(f'Format distribution:')
print(f'  Sentence/phrase format (with spaces): {len(sentence_case)} keys')
print(f'  camelCase format: {len(camelCase)} keys')
print(f'  snake_case format: {len(snake_case)} keys')
print(f'  kebab-case format: {len(kebab_case)} keys')

# 5. Most frequently used keys
print('\n\n5. MOST FREQUENTLY USED TRANSLATION KEYS')
print('-' * 80)
key_counts = Counter(used_keys)
for key, count in key_counts.most_common(20):
    print(f'  {count:3}x: "{key[:65]}"')

# 6. Files with most translation calls
print('\n\n6. FILES WITH MOST TRANSLATION CALLS')
print('-' * 80)
file_counts = [(f, len(keys)) for f, keys in usage_by_file.items()]
for filepath, count in sorted(file_counts, key=lambda x: x[1], reverse=True)[:15]:
    print(f'  {count:3}x: {Path(filepath).name}')

print('\n' + '=' * 80)
print('ANALYSIS COMPLETE')
print('=' * 80)
