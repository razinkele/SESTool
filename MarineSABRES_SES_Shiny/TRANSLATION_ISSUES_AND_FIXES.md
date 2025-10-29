# Translation Issues and Fixes

## Issues Identified

### 1. ✅ FIXED: Flag Not Updating When Language Changes
**Problem**: The flag in the language selector stayed the same even after changing language.

**Root Cause**: The `selectInput` widget doesn't automatically refresh its displayed label after the value changes.

**Fix Applied**: Added `updateSelectInput()` call in the language change observer to force refresh the display with the correct flag.

**Location**: `app.R` lines 554-559

### 2. ⚠️ PARTIAL: Incomplete Italian Translations
**Problem**: All Italian translations show "[IT]" prefix, indicating they are placeholders.

**Status**: 110 Italian translation entries need to be completed

**File**: `translations/translation.json`

**Example**:
```json
{
  "en": "Welcome to the MarineSABRES Toolbox",
  "it": "[IT] Welcome to the MarineSABRES Toolbox"  // Needs translation
}
```

**Action Required**: Replace all "[IT]" prefixed strings with proper Italian translations.

### 3. ⚠️ CRITICAL: Dashboard and PIMS Modules Not Translated
**Problem**: Dashboard and PIMS modules don't change language (remain in English).

**Root Cause**: These modules use hardcoded English text instead of `i18n$t()` translation function.

**Affected Modules**:
- Dashboard (`app.R` lines 305-372)
- PIMS Project Setup
- PIMS Stakeholders
- PIMS Resources
- PIMS Data Management
- PIMS Evaluation

**Example of Issue**:
```r
# Current (NOT translatable):
h2("MarineSABRES Social-Ecological Systems Analysis Tool")

# Should be:
h2(i18n$t("MarineSABRES Social-Ecological Systems Analysis Tool"))
```

### 4. ⚠️ PARTIAL: Entry Point Module Examples Remain in English
**Problem**: When Portuguese selected, the quick option examples (like "Food security", "Economic development") remain in English.

**Root Cause**: The `EP0_MANAGER_ROLES`, `EP1_BASIC_NEEDS`, `EP2_ACTIVITY_SECTORS`, etc. data structures in `global.R` have hardcoded English strings that aren't in the translation file.

**File**: `global.R` (lines defining entry point data)

**Action Required**: Add these strings to `translation.json` and update `global.R` to use `i18n$t()`.

### 5. ✅ WORKING: French and Spanish on Getting Started
**Status**: Working correctly because Entry Point module properly uses `i18n$t()`.

**Confirmation**: These languages work on Getting Started but not on other modules (see issue #3).

## Fix Priority

### HIGH PRIORITY (Breaking User Experience):
1. ✅ Flag display - **FIXED**
2. Dashboard translation implementation
3. PIMS modules translation implementation

### MEDIUM PRIORITY (Affects Specific Language):
4. Italian translation completion (110 strings)
5. Entry Point examples translation (Portuguese, German, etc.)

### LOW PRIORITY (Enhancement):
6. Add missing translations for AI ISA Assistant module
7. Add missing translations for Analysis Tools

## Implementation Plan

### Phase 1: Core Module Translations (2-3 hours)

**Dashboard Module** (`app.R` lines 305-372):
```r
# Update these lines to use i18n$t():
- Line 307: h2(i18n$t("MarineSABRES Social-Ecological Systems Analysis Tool"))
- Line 308: p(i18n$t("Welcome to the computer-assisted SES creation and analysis platform."))
- Line 323: title = i18n$t("Project Overview")
- Line 333: title = i18n$t("Quick Access")
- Line 338: h4(i18n$t("Recent Activities"))
- Line 346: title = i18n$t("CLD Preview")
- Line 360: h4(i18n$t("No CLD Generated Yet"))
- Line 361: p(i18n$t("Build your Causal Loop Diagram from the ISA data to visualize system connections."))
- Line 362: actionButton label: i18n$t("Build Network from ISA Data")
```

**Value Box Outputs** (`app.R` lines 594-658):
- All `subtitle` parameters need `i18n$t()` wrapper
- All `color` and `icon` can remain as-is

**PIMS Modules**: Each PIMS module file needs similar updates.

### Phase 2: Translation File Updates (1-2 hours)

**Add to `translation.json`**:
1. Dashboard strings (20-30 entries)
2. PIMS strings (50-100 entries per module)
3. Entry Point data strings (100+ entries)

**Italian Translation**:
- Option 1: Use Google Translate API or DeepL for initial translation
- Option 2: Hire professional translator
- Option 3: Use community translation (e.g., invite Italian speakers)

### Phase 3: Entry Point Data Translation (1 hour)

**Update `global.R`**:
```r
# Before:
EP0_MANAGER_ROLES <- list(
  list(id = "policy_creator", label = "Policy Creator", ...)
)

# After:
EP0_MANAGER_ROLES <- list(
  list(id = "policy_creator", label = i18n$t("Policy Creator"), ...)
)
```

**Note**: This requires restructuring because `global.R` runs before i18n is initialized. Solution: Move these data structures inside reactive context or create translation keys.

## Quick Test Checklist

After implementing fixes, test each language:

- [ ] English: All modules display correctly
- [ ] Spanish: Dashboard, PIMS, Entry Point all translate
- [ ] French: Dashboard, PIMS, Entry Point all translate
- [ ] German: Dashboard, PIMS, Entry Point all translate
- [ ] Portuguese: Dashboard, PIMS, Entry Point all translate (including examples)
- [ ] Italian: All modules show Italian text (not "[IT]" prefixes)
- [ ] Flag updates correctly for each selection
- [ ] No console errors

## Estimated Effort

| Task | Time | Priority |
|------|------|----------|
| Flag display fix | ✅ Done | HIGH |
| Dashboard translation code | 30 min | HIGH |
| PIMS translation code | 2 hours | HIGH |
| Add Dashboard/PIMS strings to translation.json | 1 hour | HIGH |
| Complete Italian translations | 4-8 hours | MEDIUM |
| Entry Point examples translation | 2 hours | MEDIUM |
| Testing all languages | 1 hour | HIGH |
| **TOTAL** | **10-15 hours** | - |

## Recommended Approach

**Option A: Full Implementation (10-15 hours)**
- Fix all modules
- Complete all translations
- Comprehensive testing

**Option B: Phased Approach (2-3 hours initial)**
- ✅ Fix flag display (done)
- Fix Dashboard translations (highest visibility)
- Mark Italian as "Coming Soon" instead of showing "[IT]"
- Add note about Portuguese examples coming soon
- Schedule Phase 2 for later

**Option C: Minimal Fix (30 minutes)**
- ✅ Fix flag display (done)
- Hide Italian option temporarily
- Add disclaimer about partial translations
- Focus on English, Spanish, French only

## Current Status

✅ **Completed**: Flag display now updates correctly when language changes

⚠️ **In Progress**: Documentation of translation issues and implementation plan

🔴 **Pending**: Dashboard and PIMS module translation implementation

🔴 **Pending**: Italian translation completion

🔴 **Pending**: Entry Point examples translation

## Next Steps

1. **Immediate** (if continuing): Implement Dashboard translation in `app.R`
2. **Short-term**: Update `translation.json` with Dashboard strings
3. **Medium-term**: Implement PIMS module translations
4. **Long-term**: Complete Italian translations professionally
