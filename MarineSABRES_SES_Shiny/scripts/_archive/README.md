# Archived Scripts

This directory contains scripts that were used during early development phases and are no longer actively used. They are kept for reference purposes only.

## Contents

Most files here are translation-related utility scripts that were used during the migration to the modular i18n system (`translations/common/`, `translations/modules/`, `translations/ui/`). These include:

- **Translation migration scripts** (`migrate_*.py`, `convert_*.py`): One-time migration from the legacy single-file translation format to the current modular key-based format.
- **Translation generation scripts** (`generate_*.py`, `add_*_translations.py`, `translate_*.py`): Used to bulk-generate translations for new languages (Norwegian, Greek) or new modules.
- **Validation and debugging scripts** (`validate_*.R`, `test_*.R`, `debug_*.R`, `check_translations.py`): Ad-hoc scripts used to diagnose translation loading issues during development.
- **Duplicate detection scripts** (`detect_duplicate_translations.py`, `find_duplicate_*.R`, `analyze_duplicate_patterns.py`): Used to clean up duplicate translation keys.
- **Fix scripts** (`fix_*.py`, `fix_*.R`, `fix_*.ps1`): One-time fixes for specific translation data issues.

## Why archived (not deleted)

These scripts document the translation system's evolution and may be useful as reference if similar migrations or bulk operations are needed in the future. The current translation workflow is handled by `scripts/translation_workflow.R` and `scripts/add_translation.R`.
