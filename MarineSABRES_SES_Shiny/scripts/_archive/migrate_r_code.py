#!/usr/bin/env python3
"""Migrate R code to use namespaced translation keys

Updates all i18n$t() and safe_t() calls to use namespaced keys.
"""

import re
import json
from pathlib import Path

def replace_translation_call(match, key_mapping):
    """Replace flat-key call with namespaced key"""
    full_match = match.group(0)
    flat_key = match.group(1)

    # Get namespaced key
    namespaced_key = key_mapping.get(flat_key)
    if not namespaced_key:
        print(f"  ⚠ No mapping for: '{flat_key[:60]}'")
        return full_match  # Leave unchanged

    # Replace preserving function type
    if 'safe_t' in full_match:
        return f'safe_t("{namespaced_key}", i18n_obj = i18n)'
    else:
        return f'i18n$t("{namespaced_key}")'

def migrate_file(file_path, key_mapping, dry_run=False):
    """Migrate a single R file"""
    if not Path(file_path).exists():
        return 0, 0

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern matches: i18n$t("key") or safe_t("key", ...)
    pattern = r'(?:i18n\$t|safe_t)\s*\(\s*["\']([^"\']+)["\']\s*[,\)]'

    # Count and replace
    replacements = 0
    def replacement_counter(match):
        nonlocal replacements
        result = replace_translation_call(match, key_mapping)
        if result != match.group(0):
            replacements += 1
        return result

    new_content = re.sub(pattern, replacement_counter, content)

    if not dry_run and replacements > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

    return replacements, content.count('i18n$t(') + content.count('safe_t(')

def main():
    print("=" * 70)
    print("R Code Migration to Namespaced Keys")
    print("=" * 70)
    print()

    # Load key mapping
    with open('scripts/key_mapping_simple.json', 'r', encoding='utf-8') as f:
        key_mapping = json.load(f)

    print(f"✓ Loaded {len(key_mapping)} key mappings")
    print()

    # Get all R files
    r_files = sorted(Path('.').rglob('*.R'))
    r_files = [f for f in r_files if 'backup' not in str(f) and 'archive' not in str(f)]

    print(f"Found {len(r_files)} R files to migrate")
    print()

    # Migrate each file
    total_replaced = 0
    total_calls = 0
    files_modified = 0

    print("Migrating files:")
    print("-" * 70)

    for file_path in r_files:
        replaced, total = migrate_file(file_path, key_mapping, dry_run=False)

        if replaced > 0:
            files_modified += 1
            total_replaced += replaced
            total_calls += total
            print(f"✓ {str(file_path):50s} {replaced:3d}/{total:3d} calls")

    print("-" * 70)
    print()
    print(f"Migration complete!")
    print(f"  Files modified: {files_modified}")
    print(f"  Calls updated: {total_replaced}/{total_calls}")
    print()

    if total_calls > total_replaced:
        missing = total_calls - total_replaced
        print(f"⚠ {missing} calls not migrated (no mapping found)")
        print("  Check warnings above for details")
    print()
    print("=" * 70)
    print("NEXT STEP: Run validation script to verify changes")

if __name__ == '__main__':
    main()
