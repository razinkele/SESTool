# AI ISA Assistant Module - Internationalization Debug Report

## Executive Summary

The AI-Assisted ISA Creation module contains **178 unique hard-coded English strings** that require internationalization. The module currently has `shiny.i18n::usei18n(i18n)` added on line 14, but the function signatures and string usage need to be updated to properly support i18n.

## Current Issues

### 1. Missing i18n Parameter
**Function Signatures Need Update:**
- Line 9: `ai_isa_assistant_ui <- function(id)` → Should be: `function(id, i18n)`
- Line 287: `ai_isa_assistant_server <- function(id, project_data_reactive)` → Should be: `function(id, project_data_reactive, i18n)`

### 2. Hard-Coded Strings Distribution

| Category | Count | Example |
|----------|-------|---------|
| UI Headers & Titles | 15 | "AI-Assisted ISA Creation" |
| Step Titles | 12 | "Welcome & Introduction" |
| Step Questions | 12 | Long instructional text |
| Ecosystem Types | 8 | "Coastal waters", "Open ocean" |
| Example Options (8 categories) | 65 | Driver/Activity/Pressure examples |
| Button Labels | 20 | "Save Progress", "Submit Answer" |
| Modal Dialogs | 13 | "Confirm Start Over" |
| Notification Messages | 10 | "Session saved successfully!" |
| Dynamic Messages | 15 | "✓ Added", "connections out of" |
| Session Management | 13 | "Auto-saved", "Not yet saved" |

**Total:** 178 unique strings

## Critical Code Locations

### UI Function (Lines 178-280)
- **Hard-coded headers:** Lines 178-179
- **Progress panel labels:** Lines 211-236
- **Session management UI:** Lines 241-276
- **Button labels:** Lines 262-276

### Server Function - QUESTION_FLOW (Lines 322-412)
- **Step titles:** All 12 steps need i18n keys
- **Questions:** Long text requiring special translation keys
- **Example arrays:** 65 ecosystem/driver/activity examples

### Dynamic Content (Lines 456-2003)
- **AI response messages:** Lines 755-757, 893, 905, 1081-1097
- **Modal dialogs:** Lines 526-534, 1300-1353
- **Notifications:** Lines 1292, 1439, 1528, 1614, 1702, 1998-2000
- **Button labels:** Lines 622-627, 643, 692, 697, 779-805
- **Connection UI:** Lines 616-618, 663

## Translation Strategy

### Phase 1: Question Keys
Long questions need abbreviated translation keys:
```r
# Before:
question = "Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model..."

# After:
question = i18n$t("ai_isa_question_welcome")
```

### Phase 2: Dynamic Messages
Messages with variable insertion:
```r
# Before:
paste0("✓ Added '", answer, "' (", element_count, " ", step_info$target, " total)")

# After:
paste0(i18n$t("✓ Added"), " '", answer, "' (", element_count, " ",
       i18n$t(step_info$target), " ", i18n$t("total"), ")")
```

### Phase 3: Step Navigation
Context-aware button labels need conditional translation:
```r
# Before:
if (next_step$title == "Activities - Human Actions") {
  button_label <- "Continue to Activities"
}

# After:
if (next_step$title == i18n$t("Activities - Human Actions")) {
  button_label <- i18n$t("Continue to Activities")
}
```

## Implementation Plan

### Step 1: Update Function Signatures ✓
```r
ai_isa_assistant_ui <- function(id, i18n)
ai_isa_assistant_server <- function(id, project_data_reactive, i18n)
```

### Step 2: Wrap UI Strings (Lines 178-280)
- Wrap all static text in `i18n$t()`
- Update button labels
- Update panel titles

### Step 3: Update QUESTION_FLOW (Lines 322-412)
- Create translation keys for step titles
- Create translation keys for questions
- Translate all example arrays

### Step 4: Update Server Messages (Lines 456-2003)
- Wrap all showNotification() messages
- Wrap modal dialog text
- Wrap dynamic AI responses
- Update button labels in renderUI()

### Step 5: Update app.R
- Pass i18n parameter to module: `ai_isa_assistant_ui("ai_isa_mod", i18n)`
- Pass i18n to server: `ai_isa_assistant_server("ai_isa_mod", project_data, i18n)`

## Translation File Structure

The generated `ai_isa_assistant_translations.json` will contain:
```json
{
  "translation": [
    {
      "en": "AI-Assisted ISA Creation",
      "es": "Creación de ISA asistida por IA",
      "fr": "Création ISA assistée par l'IA",
      "de": "KI-gestützte ISA-Erstellung",
      "lt": "AI padedamas ISA kūrimas",
      "pt": "Criação de ISA assistida por IA",
      "it": "Creazione ISA assistita da AI"
    },
    ...178 more entries
  ]
}
```

## Testing Requirements

1. **Module Loading:** Verify module loads without errors
2. **Language Switching:** Test all 7 languages
3. **Dynamic Content:** Verify AI responses display correctly
4. **Template Loading:** Test all 4 example templates
5. **Session Management:** Verify save/load works across languages
6. **Connection Review:** Test connection approval/reject in all languages

## Risk Assessment

### High Risk
- **QUESTION_FLOW logic:** Step titles used for conditional navigation (Lines 777-797)
  - **Solution:** Use translation keys for comparison, not translated strings
  - Example: `if (next_step$title_key == "activities") ...`

### Medium Risk
- **Dynamic message assembly:** Multiple paste0() calls with variable insertion
  - **Solution:** Use sprintf() or glue() for better control

### Low Risk
- **Static UI labels:** Straightforward i18n$t() wrapping
- **Example options:** Simple string arrays

## Estimated Effort

- **String Extraction:** ✓ Complete (178 strings)
- **Translation Generation:** In Progress (178 × 6 = 1068 translations)
- **Code Updates:** ~3-4 hours
  - UI function: 30 min
  - QUESTION_FLOW: 1 hour
  - Server messages: 1.5 hours
  - app.R updates: 15 min
  - Testing: 1 hour
- **Total:** ~4-5 hours

## Next Steps

1. ✓ Extract all strings → Complete
2. ⏳ Generate translations → In Progress
3. ⏭ Merge translations into translation.json
4. ⏭ Update function signatures
5. ⏭ Wrap UI strings with i18n$t()
6. ⏭ Update QUESTION_FLOW structure
7. ⏭ Update server messages
8. ⏭ Update app.R
9. ⏭ Test module thoroughly
10. ⏭ Commit changes

## Notes

- The module uses `shiny.i18n::usei18n(i18n)` which requires the i18n object to be available
- Current implementation on line 14 assumes global i18n object
- After adding i18n parameter, remove line 14 or keep it as fallback
- Consider creating abbreviated keys for long questions to improve maintainability
- Template data (lines 1357-1703) contains hard-coded English that may need translation

---

**Report Generated:** 2025-11-03
**Status:** Analysis Complete, Translation In Progress
**Module:** modules/ai_isa_assistant_module.R
**Total Strings:** 178
