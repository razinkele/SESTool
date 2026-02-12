#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Detect and optionally fix duplicate translation entries in modular translation system

This script:
1. Scans all modular translation files (common/, data/, ui/, modules/)
2. Detects duplicates based on English text
3. Reports conflicts with file sources
4. Optionally fixes duplicates in the merged file
"""

import json
import os
import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Set

# Fix Windows console encoding issues
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

class DuplicateDetector:
    """Detect duplicate translations across modular files"""

    def __init__(self, base_path: str = "translations", debug: bool = False):
        self.base_path = Path(base_path)
        self.debug = debug
        self.duplicates = defaultdict(list)
        self.total_entries = 0
        self.total_files = 0

    def log(self, message: str):
        """Print debug messages"""
        if self.debug:
            print(f"[DEBUG] {message}")

    def scan_modular_files(self) -> Dict[str, List[Tuple[str, str]]]:
        """
        Scan all modular translation files and build duplicate index

        Returns:
            Dict mapping English text -> [(file, key), ...]
        """
        en_text_index = defaultdict(list)

        # Find all modular JSON files
        patterns = [
            "common/*.json",
            "data/*.json",
            "ui/*.json",
            "modules/*.json"
        ]

        for pattern in patterns:
            for file_path in self.base_path.glob(pattern):
                # Skip backup files
                if 'backup' in file_path.name.lower():
                    continue

                self.log(f"Scanning {file_path.relative_to(self.base_path)}")
                self.total_files += 1

                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)

                    # Handle both array and object formats
                    if 'translation' in data:
                        translations = data['translation']

                        # Array format: [{key: "x", en: "..."}]
                        if isinstance(translations, list):
                            for entry in translations:
                                if 'en' in entry and entry['en']:
                                    en_text = entry['en']
                                    key = entry.get('key', '<no-key>')
                                    en_text_index[en_text].append((
                                        str(file_path.relative_to(self.base_path)),
                                        key
                                    ))
                                    self.total_entries += 1

                        # Object format: {key: {en: "..."}}
                        elif isinstance(translations, dict):
                            for key, langs in translations.items():
                                if isinstance(langs, dict) and 'en' in langs and langs['en']:
                                    en_text = langs['en']
                                    en_text_index[en_text].append((
                                        str(file_path.relative_to(self.base_path)),
                                        key
                                    ))
                                    self.total_entries += 1

                except json.JSONDecodeError as e:
                    print(f"[ERROR] Invalid JSON in {file_path}: {e}")
                except Exception as e:
                    print(f"[ERROR] Failed to read {file_path}: {e}")

        return en_text_index

    def find_duplicates(self) -> Dict[str, List[Tuple[str, str]]]:
        """
        Find all duplicate English texts

        Returns:
            Dict of en_text -> [(file, key), ...] for duplicates only
        """
        en_text_index = self.scan_modular_files()

        # Filter to only duplicates (same en_text in multiple places)
        duplicates = {
            en_text: occurrences
            for en_text, occurrences in en_text_index.items()
            if len(occurrences) > 1
        }

        return duplicates

    def report_duplicates(self, duplicates: Dict[str, List[Tuple[str, str]]]):
        """Print detailed report of duplicates"""

        print("=" * 80)
        print("DUPLICATE TRANSLATION DETECTION REPORT")
        print("=" * 80)
        print(f"Scanned: {self.total_files} files")
        print(f"Total entries: {self.total_entries}")
        print(f"Duplicate English texts: {len(duplicates)}")
        print("=" * 80)

        if not duplicates:
            print("\n[OK] No duplicates found!")
            print("All English texts are unique across modular files.\n")
            return

        print(f"\n[WARNING] Found {len(duplicates)} duplicate English texts:\n")

        for i, (en_text, occurrences) in enumerate(sorted(duplicates.items()), 1):
            # Truncate long texts for display
            display_text = en_text[:70] + "..." if len(en_text) > 70 else en_text

            print(f"{i}. \"{display_text}\"")
            print(f"   Occurrences: {len(occurrences)}")

            for file_path, key in occurrences:
                print(f"   - {file_path} -> key: {key}")

            print()

    def check_merged_file(self, merged_path: str = "translations/_merged_translations.json"):
        """Check the merged translations file for duplicates"""

        merged_file = Path(merged_path)

        if not merged_file.exists():
            print(f"[INFO] Merged file not found: {merged_path}")
            print("[INFO] Run the app once to generate it, or use translation_loader.R")
            return None

        print(f"\n{'=' * 80}")
        print(f"CHECKING MERGED FILE: {merged_path}")
        print("=" * 80)

        try:
            with open(merged_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            if 'translation' not in data:
                print("[ERROR] No 'translation' key in merged file")
                return None

            translations = data['translation']

            # Count by English text
            en_texts = defaultdict(list)
            total = 0

            for i, entry in enumerate(translations):
                if 'en' in entry and entry['en']:
                    en_text = entry['en']
                    key = entry.get('key', f'<entry-{i}>')
                    en_texts[en_text].append((i, key))
                    total += 1

            # Find duplicates
            merged_duplicates = {
                en_text: indices
                for en_text, indices in en_texts.items()
                if len(indices) > 1
            }

            print(f"Total entries: {total}")
            print(f"Unique English texts: {len(en_texts)}")
            print(f"Duplicate English texts: {len(merged_duplicates)}")

            if merged_duplicates:
                print(f"\n[WARNING] Found {len(merged_duplicates)} duplicates in merged file:\n")

                for en_text, indices in list(merged_duplicates.items())[:10]:  # Show first 10
                    display_text = en_text[:60] + "..." if len(en_text) > 60 else en_text
                    print(f"  \"{display_text}\"")
                    print(f"    Appears {len(indices)} times at indices: {[i for i, _ in indices]}")
                    print(f"    Keys: {[k for _, k in indices]}")
                    print()

                if len(merged_duplicates) > 10:
                    print(f"  ... and {len(merged_duplicates) - 10} more duplicates")

                return merged_duplicates
            else:
                print("\n[OK] No duplicates in merged file!")
                return {}

        except Exception as e:
            print(f"[ERROR] Failed to check merged file: {e}")
            return None

    def fix_merged_file(self, merged_path: str = "translations/_merged_translations.json",
                       backup: bool = True):
        """Remove duplicates from merged file by keeping first occurrence"""

        merged_file = Path(merged_path)

        if not merged_file.exists():
            print(f"[ERROR] Merged file not found: {merged_path}")
            return False

        try:
            with open(merged_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            original_count = len(data['translation'])

            # Create backup
            if backup:
                backup_path = merged_file.with_suffix('.json.backup')
                with open(backup_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                print(f"[BACKUP] Created backup: {backup_path}")

            # Deduplicate by English text - keep first occurrence
            seen_en = set()
            deduplicated = []

            for entry in data['translation']:
                en_text = entry.get('en', '')
                if en_text and en_text not in seen_en:
                    seen_en.add(en_text)
                    deduplicated.append(entry)
                elif not en_text:
                    # Keep entries without English text (shouldn't happen)
                    deduplicated.append(entry)

            data['translation'] = deduplicated
            removed_count = original_count - len(deduplicated)

            # Write back
            with open(merged_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

            print(f"\n[OK] Fixed {merged_path}")
            print(f"  Original entries: {original_count}")
            print(f"  After deduplication: {len(deduplicated)}")
            print(f"  Removed: {removed_count} duplicates")

            return True

        except Exception as e:
            print(f"[ERROR] Failed to fix merged file: {e}")
            return False


def main():
    """Main entry point"""

    import argparse

    parser = argparse.ArgumentParser(
        description="Detect and fix duplicate translations in modular system"
    )
    parser.add_argument(
        '--fix-merged',
        action='store_true',
        help="Fix duplicates in _merged_translations.json"
    )
    parser.add_argument(
        '--no-backup',
        action='store_true',
        help="Don't create backup when fixing (not recommended)"
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help="Print debug information"
    )
    parser.add_argument(
        '--base-path',
        default='translations',
        help="Base path to translations directory (default: translations)"
    )

    args = parser.parse_args()

    # Initialize detector
    detector = DuplicateDetector(base_path=args.base_path, debug=args.debug)

    # Scan modular files for duplicates
    print("\n[1/3] Scanning modular translation files...\n")
    duplicates = detector.find_duplicates()
    detector.report_duplicates(duplicates)

    # Check merged file
    print("\n[2/3] Checking merged translations file...\n")
    merged_duplicates = detector.check_merged_file()

    # Fix if requested
    if args.fix_merged and merged_duplicates:
        print("\n[3/3] Fixing merged file...\n")
        success = detector.fix_merged_file(backup=not args.no_backup)

        if success:
            print("\n[SUCCESS] Duplicates fixed successfully!")
            sys.exit(0)
        else:
            print("\n[ERROR] Failed to fix duplicates")
            sys.exit(1)
    elif args.fix_merged and not merged_duplicates:
        print("\n[3/3] No duplicates to fix in merged file")
    else:
        print("\n[3/3] Skipping fix (use --fix-merged to fix)")

        if duplicates or merged_duplicates:
            print("\n[WARNING] Duplicates detected. Run with --fix-merged to fix the merged file.")
            sys.exit(1)
        else:
            print("\n[SUCCESS] No duplicates found!")
            sys.exit(0)


if __name__ == "__main__":
    main()
