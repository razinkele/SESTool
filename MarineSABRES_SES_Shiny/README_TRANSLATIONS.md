# Translation System - Command Reference

**One tool to rule them all: `translation_workflow.R`**

---

## 🎯 Quick Start

### **Add translations? Use translation_workflow.R:**

```bash
# Show all commands
Rscript scripts/translation_workflow.R help

# Add single translation (auto-mode, recommended)
Rscript scripts/translation_workflow.R add

# Process ALL missing translations (complete workflow)
Rscript scripts/translation_workflow.R process_missing

# Before committing (ALWAYS!)
Rscript scripts/translation_workflow.R check
```

---

## 📋 Complete Command Reference

All commands use: `Rscript scripts/translation_workflow.R <command>`

### **Adding Translations**

| Command | Description | Use When |
|---------|-------------|----------|
| `add` | Add single translation (auto-mode) | Adding 1-5 translations |
| `add_batch FILE.txt` | Add multiple from file | Have a list of keys |
| `add_manual` | Add manually (full control) | Need precise control |
| `process_missing` | Find & add ALL missing | Want to fix everything |

### **Checking & Validation**

| Command | Description | Use When |
|---------|-------------|----------|
| `check` | Validate + test everything | **Before every commit!** |
| `validate` | Validate JSON files | Just check syntax/structure |
| `test` | Run automated tests | After making changes |

### **Discovery**

| Command | Description | Use When |
|---------|-------------|----------|
| `find_missing` | Find missing translation keys | Want to see what's missing |
| `find_unused` | Find unused translations | Cleaning up old keys |
| `stats` | Show translation statistics | Check coverage |

### **Maintenance**

| Command | Description | Use When |
|---------|-------------|----------|
| `format` | Reformat all JSON files | Inconsistent formatting |

---

## 🚀 Common Workflows

### **Workflow 1: Add ALL Missing Translations (Recommended)**

```bash
# ONE command does everything!
Rscript scripts/translation_workflow.R process_missing
```

**What happens**:
1. Finds all missing translations (1,132 found)
2. Asks for confirmation
3. Auto-detects correct file for each
4. Extracts from legacy (all 7 languages!)
5. Adds all translations (2-3 minutes)
6. Validates everything
7. Reports results

**Time**: 3-5 minutes for 1,000+ translations!

---

### **Workflow 2: Add Single Translation**

```bash
Rscript scripts/translation_workflow.R add
```

**Prompts**:
1. Enter English text
2. Confirm auto-detected file (or choose)
3. Auto-extracts from legacy if found
4. Done!

**Time**: ~10 seconds

---

### **Workflow 3: Add Translations from List**

```bash
# Create file with keys
echo "Save Project" > my_keys.txt
echo "Load Project" >> my_keys.txt
echo "Export Data" >> my_keys.txt

# Process them
Rscript scripts/translation_workflow.R add_batch my_keys.txt
```

**Time**: ~30 seconds for 10-20 translations

---

### **Workflow 4: Before Committing (REQUIRED)**

```bash
# ALWAYS run this before committing!
Rscript scripts/translation_workflow.R check

# If passes, commit
git add translations/
git commit -m "Add translations for [feature]"
```

---

## 📖 Detailed Command Descriptions

### `add` - Add Translation (Auto-Mode)

**Recommended for most cases**

```bash
Rscript scripts/translation_workflow.R add
```

**Features**:
- ✅ Auto-detects correct file (buttons, messages, etc.)
- ✅ Auto-extracts from legacy file (all 7 languages!)
- ✅ Auto-generates namespaced keys
- ✅ Minimal interaction (1-2 prompts)
- ✅ Duplicate detection
- ✅ Validation before save

**When to use**: Adding 1-5 translations interactively

---

### `add_batch` - Batch Add from File

```bash
Rscript scripts/translation_workflow.R add_batch FILE.txt
```

**File format** (one English key per line):
```
Save
Cancel
Load Project
Export Data
```

**Features**:
- ✅ Processes multiple translations at once
- ✅ Same auto-features as `add`
- ✅ No interaction needed
- ✅ Shows progress

**When to use**: Have a list of 10+ translations

---

### `process_missing` - Complete Workflow

```bash
Rscript scripts/translation_workflow.R process_missing
```

**Complete 3-step workflow**:
1. Finds all missing translations
2. Asks for confirmation
3. Adds all automatically
4. Validates results

**Features**:
- ✅ Most comprehensive
- ✅ Handles everything
- ✅ One confirmation prompt
- ✅ Validates at end

**When to use**: Want to fix all missing translations at once

---

### `check` - Pre-Commit Check

```bash
Rscript scripts/translation_workflow.R check
```

**Runs**:
1. Full validation (JSON, structure, languages, encoding)
2. Automated test suite (18 tests)
3. Reports any issues

**Features**:
- ✅ Catches all errors
- ✅ Clear error messages
- ✅ Exit code for CI/CD
- ✅ **Required before committing**

**When to use**: **Before EVERY commit with translation changes**

---

### `find_missing` - Find Missing Keys

```bash
Rscript scripts/translation_workflow.R find_missing
```

**Finds**:
- Translation keys used in code (`i18n$t("key")`)
- But not in translation files

**Output**:
- `missing_translations.txt` (one key per line)
- Can be used with `add_batch`

**When to use**: Want to see what's missing without adding yet

---

### `stats` - Show Statistics

```bash
Rscript scripts/translation_workflow.R stats
```

**Shows**:
- Total entries
- Namespaced vs flat keys
- Glossary terms
- Entries per language
- Characters per language
- Files by category

**When to use**: Check translation coverage

---

## 🎯 Best Practices

### **1. Always Use translation_workflow.R**

❌ **Don't**:
```bash
Rscript scripts/add_translation_auto.R
Rscript scripts/validate_translations.R
```

✅ **Do**:
```bash
Rscript scripts/translation_workflow.R add
Rscript scripts/translation_workflow.R check
```

**Why?** Single entry point, consistent interface, easier to remember

---

### **2. Always Check Before Committing**

```bash
# ALWAYS run this
Rscript scripts/translation_workflow.R check

# Only commit if it passes
git add translations/
git commit -m "Add translations"
```

---

### **3. Use process_missing for Bulk Work**

```bash
# Instead of adding 100 translations one by one
# Use the complete workflow
Rscript scripts/translation_workflow.R process_missing
```

**Saves hours of work!**

---

## 🆘 Getting Help

### **Show All Commands**
```bash
Rscript scripts/translation_workflow.R help
```

### **Command Not Working?**

1. Check you're using `translation_workflow.R`
2. Run with `help` to see all commands
3. Check file paths are correct
4. See error messages for specific issues

### **Need More Details?**

See the comprehensive guides:
- `QUICK_START_TRANSLATIONS.md` - Quick reference
- `TRANSLATION_WORKFLOW_GUIDE.md` - Complete guide (46 pages)
- `AUTOMATED_TRANSLATION_SYSTEM.md` - Automation details

---

## 📊 Command Cheat Sheet

**Copy-paste these commands**:

```bash
# Add single translation
Rscript scripts/translation_workflow.R add

# Process all missing translations
Rscript scripts/translation_workflow.R process_missing

# Add from file
Rscript scripts/translation_workflow.R add_batch missing_translations.txt

# Before committing (ALWAYS!)
Rscript scripts/translation_workflow.R check

# Show statistics
Rscript scripts/translation_workflow.R stats

# Find missing
Rscript scripts/translation_workflow.R find_missing

# Show help
Rscript scripts/translation_workflow.R help
```

---

## ✅ Quick Reference Card

### **Most Common Use Cases**

| Task | Command |
|------|---------|
| Add 1 translation | `translation_workflow.R add` |
| Add all missing | `translation_workflow.R process_missing` |
| Add from list | `translation_workflow.R add_batch FILE.txt` |
| Before commit | `translation_workflow.R check` |
| See what's missing | `translation_workflow.R find_missing` |
| Check coverage | `translation_workflow.R stats` |

---

## 🎉 Summary

**Remember**: Use `translation_workflow.R` for everything!

```bash
# Your main command
Rscript scripts/translation_workflow.R <command>

# Most used commands
translation_workflow.R add              # Add translation
translation_workflow.R process_missing  # Fix everything
translation_workflow.R check            # Before commit
translation_workflow.R help             # Show all commands
```

**Simple, consistent, powerful!**

---

**Last Updated**: 2025-11-23
**Version**: 2.0
**Status**: Production Ready ✅
