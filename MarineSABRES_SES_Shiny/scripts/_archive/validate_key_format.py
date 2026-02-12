#!/usr/bin/env python3
"""
Translation Key Format Validator

Ensures translation keys follow naming conventions:
- Namespace pattern: namespace.category.item
- Valid namespaces: common, ui, modules, data
- Only lowercase, dots, and underscores allowed
- Minimum depth: 3 levels (namespace.category.item)
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict


class KeyFormatValidator:
    """Validates translation key format and naming conventions."""

    # Valid namespace prefixes
    VALID_NAMESPACES = {'common', 'ui', 'modules', 'data'}

    # Key format regex: lowercase, dots, underscores only
    KEY_PATTERN = re.compile(r'^[a-z][a-z0-9_.]*$')

    # Minimum key depth (e.g., "common.buttons.save" = 3 parts)
    MIN_KEY_DEPTH = 3

    def __init__(self, translations_dir="translations"):
        self.translations_dir = Path(translations_dir)
        self.issues = []
        self.stats = defaultdict(int)

    def validate_key(self, key, file_name):
        """Validate a single translation key."""
        issues_found = []

        # Check for empty or None key
        if not key or key.strip() == "":
            issues_found.append({
                "file": file_name,
                "key": key or "(empty)",
                "severity": "ERROR",
                "issue": "Key is empty or None"
            })
            return issues_found

        # Check key format (lowercase, dots, underscores only)
        if not self.KEY_PATTERN.match(key):
            issues_found.append({
                "file": file_name,
                "key": key,
                "severity": "ERROR",
                "issue": "Invalid characters in key (use lowercase, dots, underscores only)"
            })
            self.stats['invalid_format'] += 1

        # Check key depth
        parts = key.split('.')
        if len(parts) < self.MIN_KEY_DEPTH:
            issues_found.append({
                "file": file_name,
                "key": key,
                "severity": "WARNING",
                "issue": f"Key depth {len(parts)} < minimum {self.MIN_KEY_DEPTH} (expected: namespace.category.item)"
            })
            self.stats['insufficient_depth'] += 1

        # Check namespace
        namespace = parts[0] if parts else ""
        if namespace not in self.VALID_NAMESPACES:
            issues_found.append({
                "file": file_name,
                "key": key,
                "severity": "WARNING",
                "issue": f"Invalid namespace '{namespace}' (expected: {', '.join(sorted(self.VALID_NAMESPACES))})"
            })
            self.stats['invalid_namespace'] += 1
        else:
            self.stats[f'namespace_{namespace}'] += 1

        # Check for uppercase characters
        if key != key.lower():
            issues_found.append({
                "file": file_name,
                "key": key,
                "severity": "WARNING",
                "issue": "Key contains uppercase characters (should be lowercase)"
            })
            self.stats['has_uppercase'] += 1

        # Check for consecutive dots or underscores
        if '..' in key or '__' in key:
            issues_found.append({
                "file": file_name,
                "key": key,
                "severity": "WARNING",
                "issue": "Key contains consecutive dots or underscores"
            })
            self.stats['consecutive_separators'] += 1

        # Check for leading/trailing dots or underscores
        if key.startswith('.') or key.startswith('_') or key.endswith('.') or key.endswith('_'):
            issues_found.append({
                "file": file_name,
                "key": key,
                "severity": "WARNING",
                "issue": "Key has leading/trailing dots or underscores"
            })
            self.stats['improper_boundaries'] += 1

        if not issues_found:
            self.stats['valid_keys'] += 1

        return issues_found

    def validate_file(self, file_path):
        """Validate all keys in a translation file."""
        print(f"\n[CHECKING] {file_path.relative_to(self.translations_dir.parent)}")

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            error = {
                "file": str(file_path.name),
                "severity": "ERROR",
                "issue": f"Failed to load file: {e}"
            }
            self.issues.append(error)
            print(f"  [ERROR] Failed to load file: {e}")
            return

        translations = data.get('translation')
        if not translations:
            print(f"  [SKIP] No translations found")
            return

        # Detect format
        is_object_format = isinstance(translations, dict)

        # Extract keys
        if is_object_format:
            keys = list(translations.keys())
        else:
            keys = [entry.get('key', f'entry_{i}') for i, entry in enumerate(translations)]

        # Validate each key
        file_issues = []
        for key in keys:
            self.stats['total_keys'] += 1
            key_issues = self.validate_key(key, file_path.name)
            file_issues.extend(key_issues)

        if file_issues:
            self.issues.extend(file_issues)
            print(f"  [WARN] {len(file_issues)} issues found in {len(keys)} keys")
        else:
            print(f"  [OK] All {len(keys)} keys valid")

    def validate_all(self):
        """Validate all translation files."""
        print("=" * 70)
        print("TRANSLATION KEY FORMAT VALIDATION")
        print("=" * 70)
        print(f"Valid namespaces: {', '.join(sorted(self.VALID_NAMESPACES))}")
        print(f"Key pattern: lowercase, dots, underscores only")
        print(f"Minimum depth: {self.MIN_KEY_DEPTH} levels")

        # Find all JSON files
        json_files = []
        for subdir in ['common', 'ui', 'modules', 'data']:
            subdir_path = self.translations_dir / subdir
            if subdir_path.exists():
                json_files.extend(subdir_path.glob('*.json'))

        # Exclude backup and generated files
        json_files = [
            f for f in json_files
            if 'backup' not in str(f).lower()
            and '_merged' not in str(f).lower()
            and 'ui_flat_keys' not in str(f).lower()
        ]

        print(f"Found {len(json_files)} translation files to validate\n")

        # Validate each file
        for json_file in sorted(json_files):
            self.validate_file(json_file)

        # Print summary
        self.print_summary()

        return len([i for i in self.issues if i['severity'] == 'ERROR']) == 0

    def print_summary(self):
        """Print validation summary."""
        print("\n" + "=" * 70)
        print("VALIDATION SUMMARY")
        print("=" * 70)

        total_keys = self.stats['total_keys']
        valid_keys = self.stats['valid_keys']

        print(f"\nKey Statistics:")
        print(f"  Total keys validated: {total_keys}")
        print(f"  Valid keys: {valid_keys} ({valid_keys/total_keys*100:.1f}%)")
        print(f"  Keys with issues: {total_keys - valid_keys}")

        # Namespace distribution
        print(f"\nNamespace Distribution:")
        for ns in sorted(self.VALID_NAMESPACES):
            count = self.stats[f'namespace_{ns}']
            pct = (count / total_keys * 100) if total_keys > 0 else 0
            print(f"  {ns}: {count} ({pct:.1f}%)")

        # Issue types
        print(f"\nIssue Types:")
        issue_types = [
            ('invalid_format', 'Invalid format (special characters)'),
            ('insufficient_depth', 'Insufficient depth (< 3 levels)'),
            ('invalid_namespace', 'Invalid namespace'),
            ('has_uppercase', 'Contains uppercase'),
            ('consecutive_separators', 'Consecutive separators'),
            ('improper_boundaries', 'Leading/trailing separators')
        ]

        has_issues = False
        for key, label in issue_types:
            count = self.stats[key]
            if count > 0:
                has_issues = True
                print(f"  {label}: {count}")

        if not has_issues:
            print(f"  No issues found!")

        # Severity summary
        print(f"\nIssues by Severity:")
        severity_counts = defaultdict(int)
        for issue in self.issues:
            severity_counts[issue['severity']] += 1

        for severity in ['ERROR', 'WARNING']:
            if severity in severity_counts:
                print(f"  {severity}: {severity_counts[severity]}")

        # Quality grade
        if valid_keys == total_keys:
            grade = "A"
        elif valid_keys / total_keys >= 0.95:
            grade = "B"
        elif valid_keys / total_keys >= 0.85:
            grade = "C"
        else:
            grade = "D"

        print(f"\nQuality Grade: {grade} ({valid_keys/total_keys*100:.1f}% valid)")

        # Recommendations
        print(f"\nRecommendations:")
        if self.stats['invalid_format'] > 0:
            print(f"  - Fix {self.stats['invalid_format']} keys with invalid characters")
        if self.stats['invalid_namespace'] > 0:
            print(f"  - Fix {self.stats['invalid_namespace']} keys with invalid namespaces")
        if self.stats['insufficient_depth'] > 0:
            print(f"  - Review {self.stats['insufficient_depth']} keys with insufficient depth")
        if valid_keys == total_keys:
            print(f"  - Perfect! All keys follow naming conventions")

    def save_report(self, output_path="validation_reports/key_format_report.json"):
        """Save detailed report to JSON."""
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        report = {
            "validation_type": "key_format",
            "statistics": dict(self.stats),
            "issues": self.issues,
            "summary": {
                "total_keys": self.stats['total_keys'],
                "valid_keys": self.stats['valid_keys'],
                "error_count": len([i for i in self.issues if i['severity'] == 'ERROR']),
                "warning_count": len([i for i in self.issues if i['severity'] == 'WARNING'])
            }
        }

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        print(f"\n[SAVED] Detailed report: {output_file}")


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Validate translation key format")
    parser.add_argument(
        "--dir",
        default="translations",
        help="Translation directory (default: translations)"
    )
    parser.add_argument(
        "--save-report",
        action="store_true",
        help="Save detailed report to JSON"
    )

    args = parser.parse_args()

    # Run validation
    validator = KeyFormatValidator(translations_dir=args.dir)
    success = validator.validate_all()

    # Save report if requested
    if args.save_report:
        validator.save_report()

    print("\n" + "=" * 70)
    if success:
        print("[PASS] No critical errors found")
        sys.exit(0)
    else:
        print("[FAIL] Critical errors found")
        sys.exit(1)


if __name__ == "__main__":
    main()
