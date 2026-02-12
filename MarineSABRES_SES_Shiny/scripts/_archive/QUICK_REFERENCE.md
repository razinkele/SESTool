# Translation Duplicate Detection - Quick Reference

## TL;DR

```bash
# Daily check before committing
python scripts/check_translations.py --quick

# Status: ✓ PASSING (0 critical issues)
```

## Created Files

### Scripts (4)

1. **`check_translations.py`** - Main wrapper (use this!)
2. **`analyze_duplicate_patterns.py`** - Pattern categorization
3. **`detect_duplicate_translations.py`** - Full duplicate detection
4. **`fix_duplicate_translations.py`** - Legacy (monolithic files)

### Documentation (3)

1. **`DUPLICATE_DETECTION_README.md`** - Full guide (read this first!)
2. **`DUPLICATE_DETECTION_COMPLETE.md`** - Implementation summary
3. **`QUICK_REFERENCE.md`** - This file

## Common Commands

### ✅ Recommended Usage

```bash
# Quick daily check (5 seconds)
python scripts/check_translations.py --quick

# Full analysis before release (30 seconds)
python scripts/check_translations.py --detailed

# Fix merged file duplicates
python scripts/check_translations.py --fix
```

### 📊 Advanced Analysis

```bash
# Pattern categorization
python scripts/analyze_duplicate_patterns.py

# Detailed examples (10 per category)
python scripts/analyze_duplicate_patterns.py --detailed

# Full duplicate report (3000+ lines)
python scripts/detect_duplicate_translations.py > report.txt

# Fix merged file only
python scripts/detect_duplicate_translations.py --fix-merged
```

## Current Status

```
Total Entries: 2,465 in modular files
After Dedup:   1,739 in merged file

Duplicates: 663 (70% intentional shadowing)

Critical Issues: 0 ✓
  - Within-file duplicates: 0 (FIXED!)
  - Merged file duplicates: 0 (working)
```

## Duplicate Categories

```
Common + Module shadowing:  467 (70.4%) - INTENTIONAL ✓
Common + UI shadowing:       57 ( 8.6%) - INTENTIONAL ✓
Data + Module:               37 ( 5.6%) - INTENTIONAL ✓
Other patterns:              89 (13.4%) - REVIEW
Cross-module:                13 ( 2.0%) - REVIEW
Within-file:                  0 ( 0.0%) - CRITICAL ✓ NONE
```

## Exit Codes

```bash
python scripts/check_translations.py
echo $?  # Windows: echo %ERRORLEVEL%

# 0 = Pass (no critical issues)
# 1 = Fail (within-file duplicates found)
```

## What Was Fixed

### Issue #1: Within-File Duplicate ✓ FIXED

**Before:**
```json
// translations/modules/entry_point.json
{
  "modules.entry_point.recommended_tools...": "Recommended Tools...",
  "modules.ses.creation.recommended": "Recommended Tools..."  ← WRONG FILE!
}
```

**After:**
```json
// translations/modules/entry_point.json
{
  "modules.entry_point.recommended_tools...": "Recommended Tools..."
}

// translations/modules/ses_creation.json
{
  "modules.ses.creation.recommended": "Recommended Tools..."  ← CORRECT!
}
```

## Understanding the Output

### ✅ Passing Check

```
[OK] No critical duplicate issues found

[SUCCESS] All translation quality checks passed!

Your translation system is in good shape:
  - No critical within-file duplicates
  - Modular files properly organized
  - Merged file ready for use
```

### ❌ Failing Check

```
[HIGH PRIORITY] 1 within-file duplicates found!
File: modules/xxx.json
Keys: ['modules.xxx.key1', 'modules.yyy.key1']  ← Wrong namespace!

[WARNING] Found 1 high-priority issues to fix
```

**Action:** Fix the misplaced key (remove or move to correct file)

## Integration

### Git Pre-commit Hook

`.git/hooks/pre-commit`:
```bash
#!/bin/bash
python scripts/check_translations.py --quick || exit 1
```

### GitHub Actions

`.github/workflows/translation-check.yml`:
```yaml
- name: Check Translations
  run: python scripts/check_translations.py
```

### CI/CD

```bash
# In your CI script
python scripts/check_translations.py
if [ $? -ne 0 ]; then
  echo "Translation check failed!"
  exit 1
fi
```

## Troubleshooting

### Q: Script says "duplicates detected" but exits 0?

**A:** Intentional! Duplicates in modular files are often by design (common/module shadowing). Only fails on critical issues (within-file duplicates).

### Q: How often should I run this?

**A:**
- Daily: `--quick` before committing
- Weekly: Full check
- Before release: `--detailed` + `--fix`

### Q: Can I ignore the duplicates?

**A:**
- **Within-file**: NO! Fix immediately
- **Common/module**: YES, usually intentional
- **Cross-module**: Review case-by-case

### Q: How do I fix duplicates in modular files?

**A:** Currently manual - open the file and remove/fix the entry. Auto-fix coming in future version.

### Q: Merged file has duplicates?

**A:** Run `python scripts/check_translations.py --fix`

## Performance

```
Scan time:    ~0.5 seconds (22 files, 2465 entries)
Analysis:     ~1 second
Full report:  ~2 seconds
Fix merged:   ~0.1 seconds
```

## Files Changed

### Modified

- `translations/modules/entry_point.json` - Removed duplicate key

### Created

- 4 Python scripts in `scripts/`
- 3 documentation files

### Not Modified

- No changes to R code
- No changes to translation_loader.R
- No changes to other translation files

## Next Steps

1. ✓ Run `python scripts/check_translations.py --quick` to verify
2. ✓ Review this guide
3. ✓ Read `DUPLICATE_DETECTION_README.md` for details
4. ✓ Add to your workflow (pre-commit hook, CI/CD)
5. ✓ Commit changes

## Support

**Questions?**
1. Check `DUPLICATE_DETECTION_README.md` (comprehensive guide)
2. Run `python scripts/check_translations.py --help`
3. Examine script output carefully
4. Create GitHub issue with details

## Summary

✅ **System Status:** Healthy
✅ **Critical Issues:** 0
✅ **Ready for:** Production use
✅ **Tested on:** Windows (Python 3.13)
✅ **Compatible with:** Current modular translation system

---

**Last Updated:** 2025-11-29
**Version:** 1.0
**Status:** Complete ✓
