# Translation Workflow Guide
## Smooth and Seamless Translation Management for MarineSABRES SES Toolbox

**Version**: 1.0
**Date**: 2025-11-23
**Status**: ✅ Production Ready

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Common Workflows](#common-workflows)
3. [Tools Overview](#tools-overview)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)
6. [Advanced Usage](#advanced-usage)

---

## 🚀 Quick Start

### Prerequisites

```r
# Install required packages (one-time setup)
install.packages(c("jsonlite", "shiny.i18n"))
```

### Adding Your First Translation

```bash
# Interactive mode (recommended for beginners)
Rscript scripts/add_translation.R

# Or use the workflow manager
Rscript scripts/translation_workflow.R add
```

Follow the prompts to add your translation safely.

### Before Committing Changes

```bash
# Run all validation and tests
Rscript scripts/translation_workflow.R check
```

This ensures your translations won't break the app!

---

## 📖 Common Workflows

### Workflow 1: Add a Single Translation

**Use Case**: Adding one or a few new UI elements

```bash
# Step 1: Add translation interactively
Rscript scripts/add_translation.R

# Step 2: Validate
Rscript scripts/translation_workflow.R validate

# Step 3: Test in app
# Start R/RStudio and run:
source("global.R")
# Test the translation is working

# Step 4: Commit if all good
git add translations/
git commit -m "Add translation for [feature]"
```

**Interactive prompts will guide you through:**
- Selecting the file (common/, ui/, data/, etc.)
- Creating namespaced key (optional)
- Entering all 7 language translations
- Validation and preview

### Workflow 2: Add Multiple Translations (Batch)

**Use Case**: Adding many translations at once

```bash
# Step 1: Create CSV file with translations
# Format: key, en, es, fr, de, lt, pt, it, file
# Example: translations_to_add.csv

# Step 2: Import from CSV
Rscript scripts/add_translation.R --csv translations_to_add.csv

# Step 3: Validate all
Rscript scripts/translation_workflow.R check

# Step 4: Commit
git add translations/
git commit -m "Add batch translations"
```

**CSV Example** (`translations_to_add.csv`):
```csv
key,en,es,fr,de,lt,pt,it,file
common.buttons.export,Export,Exportar,Exporter,Exportieren,Eksportuoti,Exportar,Esporta,translations/common/buttons.json
common.buttons.import,Import,Importar,Importer,Importieren,Importuoti,Importar,Importa,translations/common/buttons.json
```

### Workflow 3: Update Existing Translation

**Use Case**: Fixing or improving a translation

```bash
# Step 1: Find the translation file
# Use search or check translations/common/, ui/, data/

# Step 2: Edit JSON file directly
# Open in text editor (VS Code, RStudio, etc.)

# Step 3: Validate changes
Rscript scripts/translation_workflow.R validate

# Step 4: Test
Rscript scripts/test_translations.R

# Step 5: Commit
git add translations/[file].json
git commit -m "Update translation: [description]"
```

### Workflow 4: Pre-Commit Check

**Use Case**: Before committing any translation changes

```bash
# Run comprehensive check
Rscript scripts/translation_workflow.R check

# This runs:
# 1. Validation (syntax, structure, completeness)
# 2. Automated tests (integration, loading, etc.)
# 3. Reports any issues

# Only commit if all checks pass!
```

### Workflow 5: Find Missing Translations

**Use Case**: Finding keys used in code but not translated

```bash
# Find missing keys
Rscript scripts/translation_workflow.R find_missing

# This will show:
# - Keys used in code (i18n$t("key"))
# - But not found in translation files

# Add the missing translations:
Rscript scripts/add_translation.R
```

### Workflow 6: Reformat All Files

**Use Case**: Clean up JSON formatting

```bash
# Reformat all translation JSON files
Rscript scripts/translation_workflow.R format

# This ensures:
# - Consistent indentation
# - Alphabetical ordering (if applicable)
# - Valid JSON syntax
```

---

## 🛠️ Tools Overview

### 1. Translation Workflow Manager

**Script**: `scripts/translation_workflow.R`

**Purpose**: Master tool for all translation operations

**Commands**:

```bash
# Show help
Rscript scripts/translation_workflow.R help

# Validate all files
Rscript scripts/translation_workflow.R validate

# Run tests
Rscript scripts/translation_workflow.R test

# Add new translation
Rscript scripts/translation_workflow.R add

# Show statistics
Rscript scripts/translation_workflow.R stats

# Pre-commit check
Rscript scripts/translation_workflow.R check

# Reformat files
Rscript scripts/translation_workflow.R format

# Find missing keys
Rscript scripts/translation_workflow.R find_missing

# Find unused keys
Rscript scripts/translation_workflow.R find_unused
```

### 2. Validation Tool

**Script**: `scripts/validate_translations.R`

**Purpose**: Comprehensive validation of translation files

**Checks**:
- ✅ JSON syntax validity
- ✅ File structure (languages, translation/glossary)
- ✅ Language completeness (all 7 languages present)
- ✅ Encoding issues (Lithuanian chars in wrong languages)
- ✅ Duplicate keys across files
- ✅ Namespaced key format
- ✅ Empty or too-long translations

**Usage**:
```bash
# Run validation
Rscript scripts/validate_translations.R

# Exit code 0 = success, 1 = errors found
```

**Output Example**:
```
=== Translation Validation ===

Found 11 translation files

Validating: _framework.json
✓ Valid JSON: _framework.json
✓ Valid structure: _framework.json
✓ All languages complete: _framework.json
✓ No encoding issues: _framework.json
✓ Valid key formats: _framework.json

...

Cross-file Validation:
✓ No duplicate keys found

=== Validation Summary ===
Files checked: 11
Issues found: 0
  Critical: 0
  Warnings: 0

✓ ALL VALIDATIONS PASSED!
Translations are ready to commit.
```

### 3. Add Translation Tool

**Script**: `scripts/add_translation.R`

**Purpose**: Interactive tool for safely adding translations

**Features**:
- Interactive prompts for all fields
- File selection (existing or new)
- Namespaced key support
- All 7 languages required
- Validation before saving
- Duplicate detection
- Preview before commit

**Modes**:

**Interactive Mode**:
```bash
Rscript scripts/add_translation.R
```

**Batch Import Mode**:
```bash
Rscript scripts/add_translation.R --csv translations.csv
```

### 4. Automated Test Suite

**Script**: `scripts/test_translations.R`

**Purpose**: End-to-end testing of translation system

**Test Suites**:

1. **JSON File Validation**
   - Valid syntax
   - Required structure
   - All languages present

2. **Translation Loader**
   - Script exists and loads
   - Functions work correctly
   - Merging logic correct
   - Temp file creation

3. **Integration Tests**
   - shiny.i18n integration
   - Translator initialization
   - Framework translations accessible
   - Common translations accessible
   - Language switching works
   - Glossary loaded

4. **Validation Functions**
   - Missing translation detection
   - Statistics calculation

**Usage**:
```bash
# Run all tests
Rscript scripts/test_translations.R

# Exit code 0 = all pass, 1 = failures
```

**Output Example**:
```
╔═══════════════════════════════════════════════════╗
║  Translation System - Automated Test Suite       ║
╚═══════════════════════════════════════════════════╝

[Test 1] All JSON files are valid syntax
  ✓ PASS

[Test 2] All translation files have required structure
  ✓ PASS

...

╔═══════════════════════════════════════════════════╗
║  Test Summary                                     ║
╚═══════════════════════════════════════════════════╝

Total tests:  18
Passed:       18 (100%)
Failed:       0 (0%)
Duration:     2.34 seconds

✓ ALL TESTS PASSED!
```

---

## 💡 Best Practices

### 1. Always Use Tools

❌ **Don't**:
```r
# Manually editing translation.json.backup
# Copy-pasting from other files
# Using text editor without validation
```

✅ **Do**:
```bash
# Use the interactive tool
Rscript scripts/add_translation.R

# Always validate after manual edits
Rscript scripts/translation_workflow.R validate
```

### 2. Use Namespaced Keys for New Translations

❌ **Don't**:
```json
{
  "en": "Save",
  "es": "Guardar"
}
```

✅ **Do**:
```json
{
  "key": "common.buttons.save",
  "en": "Save",
  "es": "Guardar"
}
```

**Why?**
- Better organization
- Avoids collisions
- Clearer context
- Easier to find

### 3. File Organization

**Use appropriate directories**:

```
translations/
├── common/          # UI elements used everywhere
│   ├── buttons.json
│   ├── labels.json
│   ├── messages.json
│   └── validation.json
│
├── ui/              # Component-specific UI
│   ├── sidebar.json
│   ├── header.json
│   └── modals.json
│
├── data/            # Data-specific terms
│   └── node_types.json
│
└── modules/         # Module-specific translations
    ├── entry_point.json
    └── analysis_tools.json
```

### 4. Translation Quality

**Completeness**:
- ✅ All 7 languages filled
- ✅ No "TODO" placeholders in production
- ✅ Consistent terminology

**Accuracy**:
- ✅ Contextually appropriate
- ✅ Same tone/formality across languages
- ✅ Technical terms consistent with glossary

**Length**:
- ✅ Similar length across languages
- ✅ Not too long (< 500 chars)
- ✅ Not empty

### 5. Testing

**Always test before committing**:

```r
# 1. Load in R session
source("global.R")

# 2. Check translation works
i18n$t("your.new.key")

# 3. Test language switching
i18n$set_translation_language("es")
i18n$t("your.new.key")  # Should show Spanish

# 4. Run automated tests
system("Rscript scripts/test_translations.R")
```

### 6. Git Workflow

```bash
# 1. Create feature branch
git checkout -b feature/add-translations

# 2. Make changes
Rscript scripts/add_translation.R

# 3. Validate
Rscript scripts/translation_workflow.R check

# 4. Commit with clear message
git add translations/
git commit -m "Add translations for export functionality

- Added common.buttons.export
- Added common.messages.export_success
- All 7 languages included"

# 5. Push and create PR
git push origin feature/add-translations
```

---

## 🔧 Troubleshooting

### Problem: "Translation not found" error in app

**Symptoms**:
```
Warning: 'my.key' translation does not exist
```

**Causes & Solutions**:

1. **Key doesn't exist**
   ```bash
   # Check if key is in any file
   Rscript scripts/translation_workflow.R find_missing

   # Add the translation
   Rscript scripts/add_translation.R
   ```

2. **Wrong key name**
   ```r
   # Check exact key name in file
   # Make sure it matches exactly
   i18n$t("common.buttons.save")  # Correct
   i18n$t("common.button.save")   # Wrong (button vs buttons)
   ```

3. **File not discovered by loader**
   ```r
   # Check file is in correct location
   # translations/common/, ui/, data/, or modules/
   # And has .json extension
   # And doesn't contain "backup" in name
   ```

### Problem: Validation fails with "Invalid JSON"

**Symptoms**:
```
✗ Invalid JSON: buttons.json
  Error: lexical error: invalid char in json text.
```

**Causes & Solutions**:

1. **Trailing comma**
   ```json
   {
     "en": "Save",
     "es": "Guardar",  // ← Remove this comma
   }
   ```

2. **Missing quote**
   ```json
   {
     "en": "Save,  // ← Missing closing quote
     "es": "Guardar"
   }
   ```

3. **Use JSON validator**
   ```bash
   # Online: jsonlint.com
   # Or use format command to fix
   Rscript scripts/translation_workflow.R format
   ```

### Problem: "Lithuanian characters in wrong language"

**Symptoms**:
```
✗ Entry 5 has Lithuanian chars in pt
```

**Cause**: Copy-pasted from Lithuanian translation

**Solution**:
```bash
# Find and fix manually in the JSON file
# Or use add_translation.R to create new entry
```

### Problem: Duplicate keys

**Symptoms**:
```
⚠ Duplicate translation keys found:
  Key: Save
    - common/buttons.json (entry 1)
    - ui/modals.json (entry 3)
```

**Solution**:
- Remove duplicate from one file
- Or rename one to be more specific
- Modular files take precedence over legacy

### Problem: Tests fail

**Symptoms**:
```
[Test 5] Framework translations are accessible
  ✗ FAIL: Cannot translate: Driver
```

**Causes & Solutions**:

1. **Translation missing**
   ```bash
   # Add missing translation
   Rscript scripts/add_translation.R
   ```

2. **File structure wrong**
   ```bash
   # Validate structure
   Rscript scripts/validate_translations.R
   ```

3. **Loader not finding files**
   ```r
   # Check file naming and location
   # Must match pattern: _*.json or in common/ui/data/modules/
   ```

---

## 🎓 Advanced Usage

### Custom Validation Rules

Edit `scripts/validate_translations.R`:

```r
# Add custom validation
validate_custom <- function(data, file_path) {
  issues <- list()

  # Example: Check for specific terminology
  for (entry in data$translation) {
    if (grepl("eco-system", entry$en)) {
      issues <- c(issues, list(list(
        type = "terminology",
        message = "Use 'ecosystem' not 'eco-system'"
      )))
    }
  }

  return(issues)
}
```

### Automated Translation via API

For professional translations:

```r
# Example using Google Translate API
translate_entry <- function(text, target_lang) {
  # Implement API call
  # Return translated text
}

# Batch translate
source("functions/translation_loader.R")
data <- load_translations("translations")

for (entry in data$translation) {
  if (entry$pt == "" || grepl("TODO", entry$pt)) {
    entry$pt <- translate_entry(entry$en, "pt")
  }
}
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Validate translations before commit

echo "Validating translations..."
Rscript scripts/translation_workflow.R validate

if [ $? -ne 0 ]; then
  echo "Translation validation failed!"
  echo "Fix errors and try again."
  exit 1
fi

echo "Translation validation passed!"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### CI/CD Integration

Add to GitHub Actions (`.github/workflows/translations.yml`):

```yaml
name: Translation Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup R
        uses: r-lib/actions/setup-r@v2

      - name: Install dependencies
        run: |
          install.packages(c("jsonlite", "shiny.i18n"))
        shell: Rscript {0}

      - name: Validate translations
        run: |
          Rscript scripts/validate_translations.R

      - name: Run tests
        run: |
          Rscript scripts/test_translations.R
```

### Translation Coverage Report

```r
# Generate HTML report
generate_coverage_report <- function() {
  source("functions/translation_loader.R")

  data <- load_translations("translations")
  stats <- get_translation_stats(data)

  # Calculate coverage per language
  total <- stats$total_entries

  html <- sprintf("<html><body><h1>Translation Coverage</h1>")

  for (lang in stats$languages) {
    count <- stats$entries_per_language[[lang]]
    percent <- round(100 * count / total)

    html <- paste0(html, sprintf(
      "<p>%s: %d/%d (%d%%)</p>",
      toupper(lang), count, total, percent
    ))
  }

  html <- paste0(html, "</body></html>")

  writeLines(html, "translation_coverage.html")
  cat("Report saved to translation_coverage.html\n")
}
```

---

## 📚 Quick Reference

### File Structure
```
translations/
  ├── _framework.json      # Framework terms
  ├── _glossary.json       # Common glossary
  ├── common/              # Common UI
  ├── ui/                  # UI components
  ├── data/                # Data terms
  └── modules/             # Module-specific
```

### Required Languages
```
en, es, fr, de, lt, pt, it
```

### Namespaced Key Format
```
category.subcategory.name
Examples:
  common.buttons.save
  ui.sidebar.dashboard
  framework.drivers.singular
```

### Command Cheat Sheet
```bash
# Add translation
Rscript scripts/add_translation.R

# Validate
Rscript scripts/translation_workflow.R validate

# Test
Rscript scripts/test_translations.R

# Pre-commit check
Rscript scripts/translation_workflow.R check

# Statistics
Rscript scripts/translation_workflow.R stats

# Find missing
Rscript scripts/translation_workflow.R find_missing

# Format files
Rscript scripts/translation_workflow.R format
```

---

## 📞 Support

### Common Issues

1. **App errors after adding translation**
   - Run validation: `Rscript scripts/validate_translations.R`
   - Check for syntax errors
   - Verify all languages present

2. **Translation not showing in app**
   - Restart R session
   - Check key name is correct
   - Verify file is in translations/ directory

3. **Duplicate key warnings**
   - Remove duplicate from one file
   - Modular files take precedence

### Getting Help

1. Check this guide
2. Run validation to see specific errors
3. Check `TRANSLATION_MODULARIZATION_COMPLETE.md` for system details
4. Review `functions/translation_loader.R` for loader logic

---

## ✅ Success Checklist

Before committing translations:

- [ ] Added all 7 languages (en, es, fr, de, lt, pt, it)
- [ ] Ran validation: `Rscript scripts/validate_translations.R`
- [ ] Passed all tests: `Rscript scripts/test_translations.R`
- [ ] Tested in app: `source("global.R")` and verified translation works
- [ ] No Lithuanian chars in non-Lithuanian languages
- [ ] No empty translations or TODO placeholders
- [ ] Used namespaced keys for new translations
- [ ] Files are in correct directory (common/, ui/, data/, modules/)
- [ ] Clear commit message describing what was added

---

**Last Updated**: 2025-11-23
**Version**: 1.0
**Maintained By**: MarineSABRES Development Team
