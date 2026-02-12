#!/usr/bin/env python3
"""
Translation Completeness Validator

Checks that all translation entries have values for all supported languages.
Reports missing translations, empty values, and completion percentages.
"""

import json
import sys
from pathlib import Path
from collections import defaultdict


class CompletenessValidator:
    """Validates translation completeness across all files."""

    def __init__(self, translations_dir="translations", expected_languages=None):
        self.translations_dir = Path(translations_dir)
        self.expected_languages = expected_languages or [
            "en", "es", "fr", "de", "lt", "pt", "it", "no"
        ]
        self.issues = []
        self.stats = defaultdict(lambda: defaultdict(int))

    def validate_file(self, file_path):
        """Validate a single translation file."""
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

        # Get languages from file
        file_languages = data.get('languages', [])

        # Check language list completeness
        missing_languages = set(self.expected_languages) - set(file_languages)
        if missing_languages:
            issue = {
                "file": str(file_path.name),
                "severity": "WARNING",
                "issue": f"Missing languages in language list: {sorted(missing_languages)}"
            }
            self.issues.append(issue)
            print(f"  [WARN] Language list missing: {', '.join(sorted(missing_languages))}")

        # Check translation entries
        translations = data.get('translation')
        if not translations:
            print(f"  [SKIP] No translations found")
            return

        # Detect format
        is_object_format = isinstance(translations, dict)

        if is_object_format:
            # Object-based format: {key: {en: "...", es: "..."}}
            entries = [(key, value) for key, value in translations.items()]
        else:
            # Array-based format: [{key: "...", en: "...", es: "..."}]
            entries = [(entry.get('key', f'entry_{i}'), entry) for i, entry in enumerate(translations)]

        file_issues = 0
        for key, entry in entries:
            self.stats['total']['entries'] += 1

            for lang in self.expected_languages:
                value = entry.get(lang, "")

                if not value:
                    # Missing or empty translation
                    file_issues += 1
                    self.stats[lang]['missing'] += 1
                    self.stats['total']['missing'] += 1

                    issue = {
                        "file": str(file_path.name),
                        "key": key,
                        "language": lang,
                        "severity": "MISSING",
                        "issue": "Translation missing or empty"
                    }
                    self.issues.append(issue)
                else:
                    # Check for TODO markers
                    if "TODO" in value:
                        file_issues += 1
                        self.stats[lang]['todo'] += 1
                        self.stats['total']['todo'] += 1

                        issue = {
                            "file": str(file_path.name),
                            "key": key,
                            "language": lang,
                            "severity": "TODO",
                            "issue": f"Contains TODO marker: {value[:50]}"
                        }
                        self.issues.append(issue)
                    else:
                        # Complete translation
                        self.stats[lang]['complete'] += 1
                        self.stats['total']['complete'] += 1

        if file_issues == 0:
            print(f"  [OK] All translations complete ({len(entries)} entries)")
        else:
            print(f"  [WARN] {file_issues} issues found in {len(entries)} entries")

    def validate_all(self):
        """Validate all translation files."""
        print("=" * 70)
        print("TRANSLATION COMPLETENESS VALIDATION")
        print("=" * 70)
        print(f"Expected languages: {', '.join(self.expected_languages)}")
        print(f"Translation directory: {self.translations_dir}")

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

        print(f"Found {len(json_files)} translation files to validate")

        # Validate each file
        for json_file in sorted(json_files):
            self.validate_file(json_file)

        # Print summary
        self.print_summary()

        return len([i for i in self.issues if i['severity'] in ['ERROR', 'MISSING']]) == 0

    def print_summary(self):
        """Print validation summary."""
        print("\n" + "=" * 70)
        print("VALIDATION SUMMARY")
        print("=" * 70)

        # Overall statistics
        total_entries = self.stats['total']['entries']
        total_translations = total_entries * len(self.expected_languages)
        complete = self.stats['total']['complete']
        missing = self.stats['total']['missing']
        todo = self.stats['total']['todo']

        print(f"\nOverall Statistics:")
        print(f"  Total entries: {total_entries}")
        print(f"  Expected translations: {total_translations} ({total_entries} x {len(self.expected_languages)} languages)")
        print(f"  Complete: {complete} ({complete/total_translations*100:.1f}%)")
        print(f"  Missing/Empty: {missing} ({missing/total_translations*100:.1f}%)")
        print(f"  TODO markers: {todo} ({todo/total_translations*100:.1f}%)")

        # Per-language statistics
        print(f"\nPer-Language Completeness:")
        for lang in self.expected_languages:
            lang_complete = self.stats[lang]['complete']
            lang_missing = self.stats[lang]['missing']
            lang_todo = self.stats[lang]['todo']
            lang_total = total_entries

            completion_pct = (lang_complete / lang_total * 100) if lang_total > 0 else 0

            status = "[OK]" if completion_pct >= 95 else "[WARN]"
            print(f"  {status} {lang.upper()}: {completion_pct:.1f}% complete ({lang_complete}/{lang_total}), {lang_missing} missing, {lang_todo} TODO")

        # Issue summary by severity
        print(f"\nIssues by Severity:")
        severity_counts = defaultdict(int)
        for issue in self.issues:
            severity_counts[issue['severity']] += 1

        for severity in ['ERROR', 'MISSING', 'TODO', 'WARNING']:
            if severity in severity_counts:
                print(f"  {severity}: {severity_counts[severity]}")

        # Quality grade
        completion_rate = (complete / total_translations * 100) if total_translations > 0 else 0
        if completion_rate >= 95:
            grade = "A"
        elif completion_rate >= 85:
            grade = "B"
        elif completion_rate >= 70:
            grade = "C"
        elif completion_rate >= 50:
            grade = "D"
        else:
            grade = "F"

        print(f"\nQuality Grade: {grade} ({completion_rate:.1f}% complete)")

        # Recommendations
        print(f"\nRecommendations:")
        if missing > 0:
            print(f"  - Fix {missing} missing/empty translations")
        if todo > 0:
            print(f"  - Complete {todo} TODO translations")
        if completion_rate < 95:
            print(f"  - Target: 95% completion (currently {completion_rate:.1f}%)")
        if completion_rate >= 95:
            print(f"  - Excellent! Maintain current quality standards")

    def save_report(self, output_path="validation_reports/completeness_report.json"):
        """Save detailed report to JSON."""
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)

        report = {
            "validation_type": "completeness",
            "timestamp": str(Path(__file__).stat().st_mtime),
            "expected_languages": self.expected_languages,
            "statistics": dict(self.stats),
            "issues": self.issues,
            "summary": {
                "total_entries": self.stats['total']['entries'],
                "complete": self.stats['total']['complete'],
                "missing": self.stats['total']['missing'],
                "todo": self.stats['total']['todo']
            }
        }

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        print(f"\n[SAVED] Detailed report: {output_file}")


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Validate translation completeness")
    parser.add_argument(
        "--dir",
        default="translations",
        help="Translation directory (default: translations)"
    )
    parser.add_argument(
        "--fail-threshold",
        type=float,
        default=95.0,
        help="Fail if completion percentage is below this (default: 95.0)"
    )
    parser.add_argument(
        "--save-report",
        action="store_true",
        help="Save detailed report to JSON"
    )

    args = parser.parse_args()

    # Run validation
    validator = CompletenessValidator(translations_dir=args.dir)
    success = validator.validate_all()

    # Save report if requested
    if args.save_report:
        validator.save_report()

    # Check threshold
    total_translations = validator.stats['total']['entries'] * len(validator.expected_languages)
    completion_pct = (validator.stats['total']['complete'] / total_translations * 100) if total_translations > 0 else 0

    print("\n" + "=" * 70)
    if completion_pct >= args.fail_threshold:
        print(f"[PASS] Completion rate {completion_pct:.1f}% meets threshold {args.fail_threshold}%")
        sys.exit(0)
    else:
        print(f"[FAIL] Completion rate {completion_pct:.1f}% below threshold {args.fail_threshold}%")
        sys.exit(1)


if __name__ == "__main__":
    main()
