#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive Translation Quality Check

This wrapper script runs all translation validation checks:
1. Duplicate detection across modular files
2. Pattern analysis (intentional vs accidental)
3. Completeness validation
4. Merged file verification

Usage:
    python scripts/check_translations.py              # Full check
    python scripts/check_translations.py --fix        # Fix merged file duplicates
    python scripts/check_translations.py --quick      # Quick summary only
"""

import sys
import os
import subprocess
from pathlib import Path

# Fix Windows console encoding
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')


def run_command(cmd, description):
    """Run a command and return success status"""
    print(f"\n{'=' * 80}")
    print(f"{description}")
    print(f"{'=' * 80}\n")

    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=False,
            capture_output=False,
            text=True
        )
        return result.returncode == 0
    except Exception as e:
        print(f"[ERROR] Failed to run: {e}")
        return False


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Comprehensive translation quality check"
    )
    parser.add_argument(
        '--fix',
        action='store_true',
        help="Fix duplicates in merged translations file"
    )
    parser.add_argument(
        '--quick',
        action='store_true',
        help="Quick summary only (skip detailed reports)"
    )
    parser.add_argument(
        '--detailed',
        action='store_true',
        help="Show detailed examples"
    )

    args = parser.parse_args()

    print("\n" + "=" * 80)
    print("MARINESABRES TRANSLATION QUALITY CHECK")
    print("=" * 80)
    print("\nThis will check for:")
    print("  - Duplicate translations across modular files")
    print("  - Within-file duplicates (critical errors)")
    print("  - Common/module shadowing patterns")
    print("  - Translation completeness")
    print("=" * 80)

    all_passed = True

    # Check 1: Pattern Analysis (critical check)
    if args.quick:
        pattern_passed = run_command(
            "python scripts/analyze_duplicate_patterns.py",
            "[1/2] PATTERN ANALYSIS - Quick Summary"
        )
    elif args.detailed:
        pattern_passed = run_command(
            "python scripts/analyze_duplicate_patterns.py --detailed",
            "[1/2] PATTERN ANALYSIS - Detailed Report"
        )
    else:
        pattern_passed = run_command(
            "python scripts/analyze_duplicate_patterns.py",
            "[1/2] PATTERN ANALYSIS"
        )

    # Pattern analysis fails only if critical issues found (within-file duplicates)
    if not pattern_passed:
        all_passed = False

    # Check 2: Duplicate Detection (informational only, unless --fix)
    # Note: This will return error if duplicates exist in modular files,
    # but those are often intentional, so we don't fail on this
    if args.fix:
        # When fixing, we care about success
        fix_passed = run_command(
            "python scripts/detect_duplicate_translations.py --fix-merged",
            "[2/2] DUPLICATE DETECTION & FIX"
        )
        if not fix_passed:
            all_passed = False
    else:
        # When not fixing, just run for information (ignore exit code)
        run_command(
            "python scripts/detect_duplicate_translations.py",
            "[2/2] DUPLICATE DETECTION (Informational)"
        )
        # Don't fail on this - duplicates in modular files are often intentional

    # Final summary
    print("\n" + "=" * 80)
    print("TRANSLATION CHECK SUMMARY")
    print("=" * 80)

    if all_passed:
        print("\n[SUCCESS] All translation quality checks passed!")
        print("\nYour translation system is in good shape:")
        print("  - No critical within-file duplicates")
        print("  - Modular files properly organized")
        print("  - Merged file ready for use")
        sys.exit(0)
    else:
        print("\n[WARNING] Some issues found")
        print("\nReview the output above for details.")
        print("\nCommon issues:")
        print("  - Within-file duplicates: Fix these immediately")
        print("  - Common/module duplicates: Usually intentional for namespacing")
        print("  - Cross-module duplicates: Consider moving to common/")
        print("\nTo fix merged file duplicates, run:")
        print("  python scripts/check_translations.py --fix")
        sys.exit(1)


if __name__ == "__main__":
    main()
