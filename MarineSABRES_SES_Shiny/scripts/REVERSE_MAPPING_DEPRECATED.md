# DEPRECATION NOTICE: reverse_key_mapping.json

**Date**: 2025-11-28
**Status**: DEPRECATED - No Longer Required

---

## Summary

The `reverse_key_mapping.json` file is **no longer required** for the translation system to function. The MarineSABRES translation system now uses **direct key-based lookup** instead of reverse mapping.

---

## What Changed?

### Before (Old System)
Translation lookup required two files:
1. Translation JSON files (e.g., `isa_data_entry.json`)
2. **`reverse_key_mapping.json`** ← You are here

The system would:
1. Look up the namespaced key in `reverse_key_mapping.json` to get English text
2. Use English text to look up the translation in the merged JSON
3. Return the translation

**Problem**: If you added a translation key to the JSON but forgot to add it to reverse_key_mapping.json, the key would display instead of the translation.

### After (New System)
Translation lookup requires only:
1. Translation JSON files (object-based format)

The system now:
1. Directly looks up the namespaced key in the merged translations
2. Returns the translation

**Benefit**: Single source of truth, no synchronization issues!

---

## Why Is This File Still Here?

We're keeping it for **1-2 weeks** as a backup in case we need to roll back to the legacy mode.

**Current mode**: Direct lookup (no reverse mapping)
**Fallback**: Legacy mode (uses this file) - can be enabled if needed

---

## Can I Delete This File?

**Recommendation**: Keep it for 1-2 weeks, then delete it.

**If you need to delete it now**:
- The app will still work (direct lookup mode is default)
- Legacy mode won't work (but it's not needed)

**To verify it's not being used**:
Check `global.R` - if `use_direct_lookup = TRUE` (or not specified), this file is not used.

---

## How to Use Legacy Mode (If Needed)

If you need to temporarily use the old system:

```r
# In global.R
translation_system <- init_translation_system(
  base_path = "translations",
  use_direct_lookup = FALSE,  # Enable legacy mode
  mapping_path = "scripts/reverse_key_mapping.json"
)
```

**Note**: This is not recommended. Use direct lookup mode instead.

---

## File Information

**Size**: 113 KB
**Entries**: 1,334 key mappings
**Last Updated**: Before 2025-11-28 (frozen)
**Status**: DEPRECATED

---

## Related Documentation

See `PRIORITY_1_IMPLEMENTATION_COMPLETE.md` for full details on the new translation system.

---

**Action Items**:
- ✅ Keep for 1-2 weeks as backup
- ⚪ Monitor app functionality
- ⚪ Delete after verification period
