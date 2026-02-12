#!/usr/bin/env python3
"""Consolidate 167 fragmented translation files into ~15 logical files

This script merges all the small translation files into logical groupings
while ensuring no duplicate English texts (shiny.i18n requirement).
"""

import json
from pathlib import Path
from collections import defaultdict

def load_all_translations(base_path):
    """Load all translation files"""
    translations_by_category = defaultdict(lambda: {
        "languages": ["en", "es", "fr", "de", "lt", "pt", "it"],
        "translation": []
    })

    # Find all JSON files (excluding archives and backups)
    json_files = []
    for pattern in ['common/*.json', 'ui/*.json', 'modules/*.json', 'data/*.json']:
        json_files.extend(Path(base_path).glob(pattern))

    json_files = [f for f in json_files if 'archive' not in str(f) and 'backup' not in str(f)]

    print(f"Found {len(json_files)} translation files")

    for file_path in json_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # Determine target category
            parts = file_path.parts
            category = parts[-2]  # common, ui, modules, data

            # For modules, group by major module type
            if category == 'modules':
                filename = parts[-1].replace('.json', '')

                # Group ISA files
                if filename.startswith('isa_'):
                    target = 'modules/isa_data_entry.json'
                # Group analysis files
                elif filename.startswith('analysis_'):
                    target = 'modules/analysis_tools.json'
                # Group PIMS files
                elif filename.startswith('pims_'):
                    target = 'modules/pims_stakeholder.json'
                # Group scenario files
                elif filename.startswith('scenario_'):
                    target = 'modules/scenario_builder.json'
                # Group response files
                elif filename.startswith('response_'):
                    target = 'modules/response_measures.json'
                # Group SES/template files
                elif filename.startswith('ses_') or filename.startswith('template_'):
                    target = 'modules/ses_creation.json'
                # Group CLD files
                elif filename.startswith('cld_'):
                    target = 'modules/cld_visualization.json'
                # Group entry point files
                elif filename.startswith('entry_point_'):
                    target = 'modules/entry_point.json'
                # Group export files
                elif filename.startswith('export_'):
                    target = 'modules/export_reports.json'
                else:
                    # Keep other module files as-is
                    target = f'modules/{filename}.json'
            else:
                # Common, UI, data - keep directory structure
                target = f'{category}/{parts[-1]}'

            # Add entries to target
            if 'translation' in data:
                for entry in data['translation']:
                    translations_by_category[target]['translation'].append(entry)

        except Exception as e:
            print(f"Warning: Could not load {file_path}: {e}")

    return translations_by_category

def deduplicate_by_english(entries):
    """Remove duplicate English texts (keep first occurrence)"""
    seen = set()
    unique = []

    for entry in entries:
        en_text = entry.get('en', '')
        if en_text and en_text not in seen:
            seen.add(en_text)
            unique.append(entry)

    return unique

def main():
    print("=" * 70)
    print("Translation File Consolidation")
    print("=" * 70)
    print()

    base_path = 'translations'

    # Load all translations
    print("Loading all translation files...")
    translations_by_category = load_all_translations(base_path)

    print(f"Loaded into {len(translations_by_category)} target files")
    print()

    # Deduplicate and save
    print("Deduplicating and saving consolidated files...")

    total_entries = 0
    total_duplicates = 0

    for target_file, content in translations_by_category.items():
        original_count = len(content['translation'])

        # Deduplicate by English text
        content['translation'] = deduplicate_by_english(content['translation'])

        # Sort by key for readability
        content['translation'] = sorted(content['translation'], key=lambda x: x.get('key', x.get('en', '')))

        final_count = len(content['translation'])
        duplicates_removed = original_count - final_count

        # Save
        output_path = Path(base_path) / target_file
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(content, f, indent=2, ensure_ascii=False)
            f.write('\n')

        print(f"  ✓ {target_file}: {final_count} entries ({duplicates_removed} duplicates removed)")

        total_entries += final_count
        total_duplicates += duplicates_removed

    print()
    print(f"Consolidation complete!")
    print(f"  Total files: {len(translations_by_category)}")
    print(f"  Total entries: {total_entries}")
    print(f"  Duplicates removed: {total_duplicates}")
    print()

    # Cleanup - remove old fragmented files
    print("Cleaning up fragmented files...")
    cleanup_count = 0

    for file_path in Path(base_path).rglob('*.json'):
        if 'archive' in str(file_path) or 'backup' in str(file_path):
            continue

        # Check if it's a consolidated file
        relative = file_path.relative_to(base_path)
        if str(relative) not in translations_by_category:
            # This is an old fragmented file
            file_path.unlink()
            cleanup_count += 1

    print(f"  Removed {cleanup_count} fragmented files")
    print()
    print("=" * 70)
    print("NEXT STEP: Run validation script to test")

if __name__ == '__main__':
    main()
