#!/usr/bin/env python3
"""Extract all translation keys from R code files

This script scans all .R files and extracts i18n$t() and safe_t() calls
to generate a comprehensive audit of translation usage.
"""

import re
import json
from pathlib import Path
from collections import Counter, defaultdict

def extract_keys_from_file(file_path):
    """Extract i18n$t() and safe_t() translation calls from an R file"""
    # Pattern matches: i18n$t("key") or safe_t("key", ...) or safe_t('key', ...)
    pattern = r'(?:i18n\$t|safe_t)\s*\(\s*["\']([^"\']+)["\']\s*[,\)]'

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            matches = re.findall(pattern, content)
            return [(str(file_path), key) for key in matches]
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}")
        return []

def group_by_file(all_keys):
    """Group keys by source file"""
    file_groups = defaultdict(list)
    for file_path, key in all_keys:
        file_groups[file_path].append(key)
    return file_groups

def group_by_key(all_keys):
    """Group files by key"""
    key_groups = defaultdict(list)
    for file_path, key in all_keys:
        key_groups[key].append(file_path)
    return key_groups

def count_frequency(all_keys):
    """Count key frequency"""
    keys_only = [key for _, key in all_keys]
    return Counter(keys_only).most_common()

def main():
    print("=" * 60)
    print("Translation Key Extraction Tool")
    print("=" * 60)
    print()

    # Define base directory
    base_dir = Path('.')

    # Find all R files (exclude backup directories)
    print("Scanning for R files...")
    r_files = []
    for pattern in ['*.R', '**/*.R']:
        for file in base_dir.glob(pattern):
            if 'backup' not in str(file) and 'archive' not in str(file):
                r_files.append(file)

    print(f"Found {len(r_files)} R files")
    print()

    # Extract all keys
    print("Extracting translation keys...")
    all_keys = []
    for file in r_files:
        keys = extract_keys_from_file(file)
        all_keys.extend(keys)
        if keys:
            print(f"  {file}: {len(keys)} keys")

    print()
    print(f"Total translation calls found: {len(all_keys)}")
    print(f"Unique keys: {len(set(k for _, k in all_keys))}")
    print()

    # Group and analyze
    by_file = group_by_file(all_keys)
    by_key = group_by_key(all_keys)
    frequency = count_frequency(all_keys)

    # Generate report
    report = {
        'summary': {
            'total_calls': len(all_keys),
            'unique_keys': len(set(k for _, k in all_keys)),
            'files_scanned': len(r_files),
            'files_with_translations': len(by_file)
        },
        'by_file': {
            file: {
                'count': len(keys),
                'unique': len(set(keys)),
                'keys': list(set(keys))
            }
            for file, keys in sorted(by_file.items(), key=lambda x: len(x[1]), reverse=True)
        },
        'by_key': {
            key: {
                'count': len(files),
                'files': list(set(files))
            }
            for key, files in by_key.items()
        },
        'most_common': [
            {'key': key, 'count': count}
            for key, count in frequency[:100]  # Top 100
        ]
    }

    # Save report
    output_file = 'scripts/migration_audit.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)

    print(f"✓ Report saved to: {output_file}")
    print()

    # Print top statistics
    print("Top 20 Most Frequent Keys:")
    print("-" * 60)
    for i, (key, count) in enumerate(frequency[:20], 1):
        print(f"{i:2d}. {key:40s} ({count}x)")

    print()
    print("Top 10 Files by Translation Count:")
    print("-" * 60)
    for i, (file, keys) in enumerate(sorted(by_file.items(), key=lambda x: len(x[1]), reverse=True)[:10], 1):
        print(f"{i:2d}. {Path(file).name:40s} ({len(keys)} calls)")

    print()
    print("=" * 60)
    print("Extraction complete!")
    print("=" * 60)

if __name__ == '__main__':
    main()
