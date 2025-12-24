#!/usr/bin/env python3
"""Migrate legacy flat-key translations to modular namespaced files

Converts translation.json.backup (legacy) to organized modular files
using the generated key mapping.
"""

import json
from pathlib import Path
from collections import defaultdict

def main():
    print("=" * 70)
    print("Legacy Translation Migration")
    print("=" * 70)
    print()

    # Load legacy translations
    legacy_file = 'translations/translation.json.backup'
    if not Path(legacy_file).exists():
        # Try alternative location
        legacy_file = 'translations/translation.json'

    print(f"Loading legacy translations from: {legacy_file}")
    with open(legacy_file, 'r', encoding='utf-8') as f:
        legacy = json.load(f)

    print(f"✓ Loaded {len(legacy.get('translation', []))} legacy entries")
    print()

    # Load key mapping
    with open('scripts/key_mapping_simple.json', 'r', encoding='utf-8') as f:
        key_mapping = json.load(f)

    print(f"✓ Loaded {len(key_mapping)} key mappings")
    print()

    # Group by target file based on namespace
    files_content = defaultdict(lambda: {
        "languages": ["en", "es", "fr", "de", "lt", "pt", "it"],
        "translation": []
    })

    migrated = 0
    skipped = 0
    no_mapping = []

    for entry in legacy.get('translation', []):
        # Get flat key (English text)
        flat_key = entry.get('en', '').strip()
        if not flat_key:
            skipped += 1
            continue

        # Get namespaced key from mapping
        namespaced_key = key_mapping.get(flat_key)
        if not namespaced_key:
            no_mapping.append(flat_key)
            skipped += 1
            continue

        # Determine target file from namespace
        parts = namespaced_key.split('.')
        if len(parts) < 2:
            print(f"Warning: Invalid namespace '{namespaced_key}' for '{flat_key}'")
            skipped += 1
            continue

        # Map to file path with smart grouping
        if parts[0] == 'common':
            target_file = f"translations/common/{parts[1]}.json"
        elif parts[0] == 'ui':
            target_file = f"translations/ui/{parts[1]}.json"
        elif parts[0] == 'modules':
            # Group by module and submodule (first 3 parts)
            # modules.isa.data_entry.ex1.key → modules/isa_data_entry.json
            # modules.isa.ai_assistant.key → modules/isa_ai_assistant.json
            # modules.pims.stakeholder.key → modules/pims_stakeholder.json
            if len(parts) >= 4 and parts[2] in ['data_entry', 'ai_assistant']:
                # ISA modules with sub-categories
                if parts[3].startswith('ex'):
                    # ISA data entry exercises
                    target_file = f"translations/modules/isa_data_entry_{parts[3]}.json"
                else:
                    target_file = f"translations/modules/{parts[1]}_{parts[2]}.json"
            elif len(parts) >= 3:
                target_file = f"translations/modules/{parts[1]}_{parts[2]}.json"
            else:
                target_file = f"translations/modules/{parts[1]}.json"
        elif parts[0] == 'data':
            target_file = f"translations/data/{parts[1]}.json"
        else:
            target_file = f"translations/common/misc.json"

        # Add entry with namespaced key
        files_content[target_file]['translation'].append({
            "key": namespaced_key,
            "en": entry.get('en', ''),
            "es": entry.get('es', ''),
            "fr": entry.get('fr', ''),
            "de": entry.get('de', ''),
            "lt": entry.get('lt', ''),
            "pt": entry.get('pt', ''),
            "it": entry.get('it', '')
        })

        migrated += 1

    print(f"Processed {migrated + skipped} entries:")
    print(f"  ✓ Migrated: {migrated}")
    print(f"  ⊘ Skipped: {skipped}")
    if no_mapping:
        print(f"  ⚠ No mapping for {len(no_mapping)} keys")
    print()

    # Merge with existing modular files
    print("Merging with existing modular files...")
    merged_count = 0
    new_count = 0

    for file_path, new_content in files_content.items():
        Path(file_path).parent.mkdir(parents=True, exist_ok=True)

        # Check if file exists
        if Path(file_path).exists():
            # Load existing
            with open(file_path, 'r', encoding='utf-8') as f:
                existing = json.load(f)

            # Get existing keys
            existing_keys = {entry['key'] for entry in existing.get('translation', [])}

            # Merge: keep existing, add new
            for entry in new_content['translation']:
                if entry['key'] not in existing_keys:
                    existing['translation'].append(entry)
                    new_count += 1
                else:
                    merged_count += 1

            # Sort by key for readability
            existing['translation'] = sorted(existing['translation'], key=lambda x: x['key'])

            # Write merged
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(existing, f, indent=2, ensure_ascii=False)
                f.write('\n')  # Add trailing newline

        else:
            # Write new file
            # Sort by key
            new_content['translation'] = sorted(new_content['translation'], key=lambda x: x['key'])

            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(new_content, f, indent=2, ensure_ascii=False)
                f.write('\n')

            new_count += len(new_content['translation'])

        print(f"  ✓ {file_path}: {len(new_content['translation'])} entries")

    print()
    print(f"✓ Created/updated {len(files_content)} files")
    print(f"  - New entries added: {new_count}")
    print(f"  - Existing entries kept: {merged_count}")
    print()

    # Summary by category
    category_counts = defaultdict(int)
    for file_path in files_content.keys():
        category = Path(file_path).parts[1]  # translations/CATEGORY/file.json
        category_counts[category] += 1

    print("Files by category:")
    for category, count in sorted(category_counts.items()):
        print(f"  {category:15s}: {count:2d} files")

    print()
    print("=" * 70)
    print("Migration complete!")
    print("=" * 70)
    print()
    print("NEXT STEP: Run migrate_r_code.py to update R files")

if __name__ == '__main__':
    main()
