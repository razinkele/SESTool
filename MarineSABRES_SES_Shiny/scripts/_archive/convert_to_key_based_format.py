#!/usr/bin/env python3
"""
Convert translation files from array-based to key-based format.

This eliminates the need for reverse_key_mapping.json by making translation
keys the primary identifiers in the JSON structure.

Current format (array-based):
{
  "languages": ["en", "es", ...],
  "translation": [
    {"key": "common.buttons.add", "en": "Add", "es": "Agregar", ...}
  ]
}

New format (key-based, shiny.i18n native):
{
  "languages": ["en", "es", ...],
  "translation": {
    "common.buttons.add": {
      "en": "Add",
      "es": "Agregar",
      ...
    }
  }
}
"""

import json
from pathlib import Path
from collections import OrderedDict

def convert_translation_file(input_file, output_file=None, dry_run=False):
    """
    Convert a single translation file from array to key-based format.

    Args:
        input_file: Path to input JSON file
        output_file: Path to output file (default: overwrite input)
        dry_run: If True, only show what would be done

    Returns:
        dict with conversion statistics
    """
    print(f"\nProcessing: {input_file}")

    # Read input file
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'translation' not in data:
        print("  [SKIP] No translation array found")
        return {"status": "skipped", "reason": "no_translation_array"}

    # Check if already converted
    if isinstance(data['translation'], dict):
        print("  [SKIP] Already in key-based format")
        return {"status": "skipped", "reason": "already_converted"}

    # Convert array to key-based object
    translation_obj = OrderedDict()
    languages = data.get('languages', [])
    duplicate_keys = []
    entries_converted = 0

    for entry in data['translation']:
        key = entry.get('key')
        if not key:
            print(f"  [WARN] Entry without key: {entry.get('en', 'unknown')}")
            continue

        # Check for duplicates
        if key in translation_obj:
            duplicate_keys.append(key)
            # For duplicates, we'll keep the first one (could also merge)
            print(f"  [WARN] Duplicate key found: {key}")
            continue

        # Create translation object for this key (exclude 'key' field)
        trans_obj = OrderedDict()
        for lang in languages:
            if lang in entry:
                trans_obj[lang] = entry[lang]

        translation_obj[key] = trans_obj
        entries_converted += 1

    # Create new structure
    new_data = OrderedDict()
    new_data['languages'] = data['languages']
    new_data['translation'] = translation_obj

    # Add glossary if present
    if 'glossary' in data:
        new_data['glossary'] = data['glossary']

    # Statistics
    stats = {
        "status": "converted",
        "entries": entries_converted,
        "duplicates": len(duplicate_keys),
        "duplicate_keys": duplicate_keys[:10] if duplicate_keys else []
    }

    print(f"  [OK] Converted {entries_converted} entries")
    if duplicate_keys:
        print(f"  [WARN] Found {len(duplicate_keys)} duplicate keys (kept first occurrence)")
        if len(duplicate_keys) <= 10:
            for dup in duplicate_keys:
                print(f"        - {dup}")

    # Write output (unless dry run)
    if not dry_run:
        output_path = output_file or input_file
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(new_data, f, ensure_ascii=False, indent=2)
        print(f"  [SAVED] {output_path}")
        stats["output_file"] = str(output_path)
    else:
        print(f"  [DRY RUN] Would save to: {output_file or input_file}")

    return stats

def convert_all_translation_files(translations_dir="translations", dry_run=False, backup=True):
    """
    Convert all translation files in the translations directory.

    Args:
        translations_dir: Base directory containing translation files
        dry_run: If True, only show what would be done
        backup: If True, create backups before conversion

    Returns:
        Summary statistics
    """
    trans_path = Path(translations_dir)

    # Find all JSON files (exclude backups and merged files)
    json_files = []
    for subdir in ['common', 'ui', 'modules', 'data']:
        subdir_path = trans_path / subdir
        if subdir_path.exists():
            json_files.extend(subdir_path.glob('*.json'))

    # Filter out backup files
    json_files = [f for f in json_files if 'backup' not in str(f).lower()]

    print("=" * 70)
    print("Translation Format Conversion: Array -> Key-Based")
    print("=" * 70)
    print(f"Mode: {'DRY RUN' if dry_run else 'LIVE CONVERSION'}")
    print(f"Backup: {'Enabled' if backup else 'Disabled'}")
    print(f"Found {len(json_files)} translation files")
    print("=" * 70)

    # Create backup directory if needed
    if backup and not dry_run:
        backup_dir = trans_path / f"_backup_before_key_conversion_{Path.cwd().name}"
        backup_dir.mkdir(exist_ok=True)
        print(f"\nBackup directory: {backup_dir}")

    # Convert each file
    summary = {
        "total_files": len(json_files),
        "converted": 0,
        "skipped": 0,
        "errors": 0,
        "total_entries": 0,
        "total_duplicates": 0
    }

    for json_file in sorted(json_files):
        try:
            # Create backup if enabled
            if backup and not dry_run:
                import shutil
                backup_file = backup_dir / json_file.relative_to(trans_path)
                backup_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(json_file, backup_file)

            # Convert file
            stats = convert_translation_file(json_file, dry_run=dry_run)

            if stats['status'] == 'converted':
                summary['converted'] += 1
                summary['total_entries'] += stats['entries']
                summary['total_duplicates'] += stats['duplicates']
            elif stats['status'] == 'skipped':
                summary['skipped'] += 1

        except Exception as e:
            print(f"  [ERROR] {e}")
            summary['errors'] += 1

    # Print summary
    print("\n" + "=" * 70)
    print("CONVERSION SUMMARY")
    print("=" * 70)
    print(f"Total files processed: {summary['total_files']}")
    print(f"  [OK] Converted: {summary['converted']}")
    print(f"  - Skipped: {summary['skipped']}")
    print(f"  [ERROR] Errors: {summary['errors']}")
    print(f"\nTotal entries converted: {summary['total_entries']}")
    if summary['total_duplicates'] > 0:
        print(f"[WARN] Total duplicate keys found: {summary['total_duplicates']}")
    print("=" * 70)

    if dry_run:
        print("\n[WARN] DRY RUN MODE - No files were modified")
        print("Run with dry_run=False to apply changes")
    else:
        print("\n[OK] Conversion complete!")
        if backup:
            print(f"[OK] Backups saved to: {backup_dir}")

    return summary

if __name__ == "__main__":
    import sys

    # Parse arguments
    dry_run = "--dry-run" in sys.argv or "-d" in sys.argv
    no_backup = "--no-backup" in sys.argv

    # Run conversion
    summary = convert_all_translation_files(
        translations_dir="translations",
        dry_run=dry_run,
        backup=not no_backup
    )

    # Exit with error if any failures
    if summary['errors'] > 0:
        sys.exit(1)
