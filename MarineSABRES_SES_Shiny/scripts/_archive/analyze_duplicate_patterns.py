#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Analyze patterns in duplicate translations to identify intentional vs accidental duplicates

This helps identify:
1. Cross-module duplicates (likely intentional for namespacing)
2. Within-module duplicates (likely accidental)
3. Common vs module duplicates (intentional shadowing)
"""

import json
import sys
from pathlib import Path
from collections import defaultdict

# Fix Windows console encoding
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')


def categorize_duplicates(base_path="translations"):
    """Categorize duplicates by pattern type"""

    base = Path(base_path)

    # Build index
    en_text_index = defaultdict(list)

    for pattern in ["common/*.json", "data/*.json", "ui/*.json", "modules/*.json"]:
        for file_path in base.glob(pattern):
            if 'backup' in file_path.name.lower():
                continue

            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)

                if 'translation' not in data:
                    continue

                translations = data['translation']

                # Handle array format
                if isinstance(translations, list):
                    for entry in translations:
                        if 'en' in entry and entry['en']:
                            en_text = entry['en']
                            key = entry.get('key', '<no-key>')
                            folder = file_path.parent.name
                            filename = file_path.stem

                            en_text_index[en_text].append({
                                'folder': folder,
                                'file': filename,
                                'key': key,
                                'path': str(file_path.relative_to(base))
                            })

                # Handle object format
                elif isinstance(translations, dict):
                    for key, langs in translations.items():
                        if isinstance(langs, dict) and 'en' in langs and langs['en']:
                            en_text = langs['en']
                            folder = file_path.parent.name
                            filename = file_path.stem

                            en_text_index[en_text].append({
                                'folder': folder,
                                'file': filename,
                                'key': key,
                                'path': str(file_path.relative_to(base))
                            })

            except Exception as e:
                print(f"[ERROR] Failed to read {file_path}: {e}")

    # Categorize duplicates
    categories = {
        'common_module_shadow': [],      # common/* + modules/* (intentional)
        'common_ui_shadow': [],          # common/* + ui/* (intentional)
        'cross_module': [],              # different modules/* files (likely intentional)
        'within_file': [],               # same file (accidental!)
        'data_module': [],               # data/* + modules/* (intentional definitions)
        'other': []
    }

    for en_text, occurrences in en_text_index.items():
        if len(occurrences) < 2:
            continue

        folders = set(occ['folder'] for occ in occurrences)
        files = [occ['file'] for occ in occurrences]

        # Within same file (definitely accidental)
        if len(set(files)) == 1:
            categories['within_file'].append((en_text, occurrences))

        # Common + Module shadowing (intentional namespace)
        elif 'common' in folders and 'modules' in folders:
            categories['common_module_shadow'].append((en_text, occurrences))

        # Common + UI shadowing
        elif 'common' in folders and 'ui' in folders:
            categories['common_ui_shadow'].append((en_text, occurrences))

        # Data + Module (definitions)
        elif 'data' in folders and 'modules' in folders:
            categories['data_module'].append((en_text, occurrences))

        # Different modules (cross-module duplication)
        elif all(f == 'modules' for f in folders):
            categories['cross_module'].append((en_text, occurrences))

        else:
            categories['other'].append((en_text, occurrences))

    return categories


def print_summary(categories):
    """Print summary statistics"""

    print("=" * 80)
    print("DUPLICATE PATTERN ANALYSIS")
    print("=" * 80)

    total_duplicates = sum(len(cat) for cat in categories.values())
    print(f"\nTotal duplicate English texts: {total_duplicates}\n")

    print("Category Breakdown:")
    print("-" * 80)

    for category, items in categories.items():
        count = len(items)
        pct = (count / total_duplicates * 100) if total_duplicates > 0 else 0

        label = {
            'common_module_shadow': 'Common + Module shadowing (intentional)',
            'common_ui_shadow': 'Common + UI shadowing (intentional)',
            'cross_module': 'Cross-module duplicates (likely intentional)',
            'within_file': 'Within same file (ACCIDENTAL!)',
            'data_module': 'Data + Module (definitions)',
            'other': 'Other patterns'
        }.get(category, category)

        print(f"  {label:50s}: {count:4d} ({pct:5.1f}%)")

    print("-" * 80)


def print_detailed_report(categories, limit=10):
    """Print detailed examples from each category"""

    print("\n" + "=" * 80)
    print("DETAILED EXAMPLES BY CATEGORY")
    print("=" * 80)

    for category, items in categories.items():
        if not items:
            continue

        label = {
            'common_module_shadow': 'Common + Module Shadowing',
            'common_ui_shadow': 'Common + UI Shadowing',
            'cross_module': 'Cross-Module Duplicates',
            'within_file': 'Within Same File (ACCIDENTAL)',
            'data_module': 'Data + Module',
            'other': 'Other Patterns'
        }.get(category, category)

        print(f"\n{label}")
        print("-" * 80)

        for i, (en_text, occurrences) in enumerate(items[:limit], 1):
            display_text = en_text[:60] + "..." if len(en_text) > 60 else en_text
            print(f"\n{i}. \"{display_text}\"")

            for occ in occurrences:
                print(f"   - {occ['path']} -> {occ['key']}")

        if len(items) > limit:
            print(f"\n   ... and {len(items) - limit} more in this category")


def generate_cleanup_recommendations(categories):
    """Generate recommendations for cleanup"""

    print("\n" + "=" * 80)
    print("CLEANUP RECOMMENDATIONS")
    print("=" * 80)

    # Within-file duplicates (definitely need fixing)
    within_file = categories.get('within_file', [])
    if within_file:
        print(f"\n[HIGH PRIORITY] {len(within_file)} within-file duplicates found!")
        print("These are likely copy-paste errors and should be reviewed:")
        for en_text, occurrences in within_file[:5]:
            display_text = en_text[:50] + "..." if len(en_text) > 50 else en_text
            file_path = occurrences[0]['path']
            print(f"  - \"{display_text}\"")
            print(f"    File: {file_path}")
            print(f"    Keys: {[occ['key'] for occ in occurrences]}")
        if len(within_file) > 5:
            print(f"  ... and {len(within_file) - 5} more")

    # Common + Module shadowing (review but likely OK)
    common_module = categories.get('common_module_shadow', [])
    if common_module:
        print(f"\n[REVIEW] {len(common_module)} common/module duplicates")
        print("These are likely intentional for namespacing, but review to confirm")
        print("Consider: Do modules really need to repeat common translations?")

    # Cross-module (review for consolidation)
    cross_module = categories.get('cross_module', [])
    if cross_module:
        print(f"\n[REVIEW] {len(cross_module)} cross-module duplicates")
        print("Consider moving frequently duplicated text to common/")

    print("\n" + "=" * 80)


def main():
    """Main entry point"""

    import argparse

    parser = argparse.ArgumentParser(
        description="Analyze duplicate translation patterns"
    )
    parser.add_argument(
        '--detailed',
        action='store_true',
        help="Show detailed examples (default: summary only)"
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=10,
        help="Number of examples per category (default: 10)"
    )
    parser.add_argument(
        '--base-path',
        default='translations',
        help="Base path to translations directory"
    )

    args = parser.parse_args()

    print("\nAnalyzing duplicate patterns...\n")

    categories = categorize_duplicates(base_path=args.base_path)

    print_summary(categories)

    if args.detailed:
        print_detailed_report(categories, limit=args.limit)

    generate_cleanup_recommendations(categories)

    # Exit code based on findings
    within_file = len(categories.get('within_file', []))
    if within_file > 0:
        print(f"\n[WARNING] Found {within_file} high-priority issues to fix")
        sys.exit(1)
    else:
        print("\n[OK] No critical duplicate issues found")
        sys.exit(0)


if __name__ == "__main__":
    main()
