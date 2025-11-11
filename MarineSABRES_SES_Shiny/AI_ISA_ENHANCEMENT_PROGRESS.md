# AI ISA Assistant Enhancement - Context-Aware Suggestions

**Date**: 2025-11-07
**Status**: IN PROGRESS (80% complete)

## Objective

Enhance the AI ISA Assistant with context-aware suggestions that change based on:
- Regional sea selection (Baltic, Mediterranean, North Sea, etc.)
- Ecosystem type (open coast, estuary, lagoon, coral reef, etc.)
- Main problem identification (automatically suggested based on region)

## Completed Work

### ✅ 1. Context-Aware Knowledge Base (Lines 242-548)

Created comprehensive `get_context_suggestions()` function that provides intelligent suggestions for:
- **Drivers**: Region-specific (e.g., Baltic: Maritime transport, Mediterranean: Beach tourism)
- **Activities**: Ecosystem-specific (e.g., Coral reef: Scuba diving, Mangrove: Shrimp farming)
- **Pressures**: Issue-specific (e.g., Eutrophication → Nutrient loading, Overfishing → Bycatch)
- **States, Impacts, Welfare, Responses, Measures**: All context-aware

**Regional Seas Included:**
- Baltic Sea
- Mediterranean Sea
- North Sea
- Black Sea
- Atlantic Ocean
- Pacific Ocean
- Indian Ocean
- Caribbean Sea
- Arctic Ocean
- Other/Regional

Each regional sea includes:
- Common issues specific to that region
- Ecosystem types typical for that region
- Context-specific problems, activities, and pressures

### ✅ 2. Updated Context Storage (Lines 226-232)

Updated `rv$context` to include:
```r
context = list(
  project_name = NULL,
  regional_sea = NULL,        # NEW
  ecosystem_type = NULL,
  ecosystem_subtype = NULL,   # NEW
  main_issue = NULL
)
```

### ✅ 3. Redesigned QUESTION_FLOW (Lines 730-843)

**New Flow Structure:**
- Step 0: Project name/location
- Step 1: **Regional sea selection** (NEW)
- Step 2: **Ecosystem type** (dynamic based on regional sea)
- Step 3: **Main issue** (suggestions based on regional sea)
- Steps 4-11: DAPSI(W)R(M) elements (drivers through measures)
- Step 12: Connection review

**Key Changes:**
- Added `type: "choice_regional_sea"` for regional sea selection
- Added `type: "choice_ecosystem"` for dynamic ecosystem options
- Added `type: "choice_with_custom"` for main issue with suggestions
- Changed all DAPSI(W)R(M) steps to use `use_context_examples: TRUE` instead of static examples

### ✅ 4. Updated rv$total_steps (Line 233)

Changed from 11 to 12 total steps to accommodate new context questions.

### ✅ 5. Implemented Dynamic Quick Options Rendering (Lines 1337-1458)

Completely rewrote the `output$quick_options` renderUI to handle:
- Regional sea selection with styled buttons
- Dynamic ecosystem types based on selected regional sea
- Main issue suggestions from regional sea context
- Context-aware DAPSI(W)R(M) suggestions using `get_context_suggestions()`
- Informative headers showing which context is active
- Limits display to 12 suggestions to avoid UI overload

## Remaining Work

### 🔨 6. Add Observers for New Button Types

**Location**: After line 1475 (in the observe block for quick options)

Need to add observers for:

```r
output$quick_options <- renderUI({
  if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
    step_info <- QUESTION_FLOW[[rv$current_step + 1]]

    # Handle regional sea selection
    if (step_info$type == "choice_regional_sea") {
      regional_sea_buttons <- lapply(names(REGIONAL_SEAS), function(sea_key) {
        sea_info <- REGIONAL_SEAS[[sea_key]]
        actionButton(
          inputId = session$ns(paste0("regional_sea_", sea_key)),
          label = sea_info$name_i18n,
          class = "quick-option",
          style = "margin: 3px;"
        )
      })
      return(tagList(
        h5(i18n$t("Select your regional sea:")),
        regional_sea_buttons
      ))
    }

    # Handle ecosystem type (dynamic based on regional sea)
    else if (step_info$type == "choice_ecosystem") {
      if (!is.null(rv$context$regional_sea)) {
        ecosystem_types <- REGIONAL_SEAS[[rv$context$regional_sea]]$ecosystem_types
        ecosystem_buttons <- lapply(seq_along(ecosystem_types), function(i) {
          actionButton(
            inputId = session$ns(paste0("ecosystem_", i)),
            label = ecosystem_types[i],
            class = "quick-option",
            style = "margin: 3px;"
          )
        })
        return(tagList(
          h5(i18n$t("Select your ecosystem type:")),
          ecosystem_buttons
        ))
      }
    }

    # Handle main issue with suggestions
    else if (step_info$type == "choice_with_custom") {
      if (!is.null(rv$context$regional_sea)) {
        issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues
        issue_buttons <- lapply(seq_along(issues), function(i) {
          actionButton(
            inputId = session$ns(paste0("issue_", i)),
            label = issues[i],
            class = "quick-option",
            style = "margin: 3px;"
          )
        })
        return(tagList(
          h5(i18n$t("Common issues in your region (or enter your own):")),
          issue_buttons
        ))
      }
    }

    # Handle context-aware examples for DAPSI(W)R(M) elements
    else if (!is.null(step_info$use_context_examples) && step_info$use_context_examples) {
      suggestions <- get_context_suggestions(
        category = step_info$target,
        regional_sea = rv$context$regional_sea,
        ecosystem_type = rv$context$ecosystem_type,
        main_issue = rv$context$main_issue
      )

      if (length(suggestions) > 0) {
        suggestion_buttons <- lapply(seq_along(suggestions), function(i) {
          actionButton(
            inputId = session$ns(paste0("quick_opt_", i)),
            label = suggestions[i],
            class = "quick-option",
            style = "margin: 3px;"
          )
        })
        return(tagList(
          h5(i18n$t("Suggested options (click to add, or enter your own):")),
          suggestion_buttons
        ))
      }
    }

    # Fallback for old static examples
    else if (!is.null(step_info$examples)) {
      # ... existing code
    }
  }
})
```

### 🔨 6. Update Quick Option Observers

**Location**: `observe({ current_step <- rv$current_step ...` around line 1372

Need to add observers for new button types:
- Regional sea buttons
- Ecosystem type buttons
- Issue buttons

### 🔨 7. Update process_answer() Function

**Location**: Around line 1410

Need to handle new context types:

```r
process_answer <- function(answer) {
  if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
    step_info <- QUESTION_FLOW[[rv$current_step + 1]]

    # Handle regional sea selection
    if (step_info$target == "regional_sea") {
      rv$context$regional_sea <- answer
      cat(sprintf("[AI ISA] Regional sea set to: %s\n", answer))

      # Generate AI response
      ai_response <- paste0(
        i18n$t("Great! You selected"), " ", answer, ". ",
        i18n$t("This will help me suggest relevant activities and pressures for your area.")
      )
      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = ai_response, timestamp = Sys.time())
      ))

      move_to_next_step()
    }

    # Handle ecosystem type
    else if (step_info$target == "ecosystem_type") {
      rv$context$ecosystem_type <- answer
      cat(sprintf("[AI ISA] Ecosystem type set to: %s\n", answer))

      ai_response <- paste0(
        i18n$t("Perfect!"), " ", answer, " ",
        i18n$t("ecosystems have unique characteristics that I'll consider in my suggestions.")
      )
      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = ai_response, timestamp = Sys.time())
      ))

      move_to_next_step()
    }

    # Handle main issue
    else if (step_info$target == "main_issue") {
      rv$context$main_issue <- answer
      cat(sprintf("[AI ISA] Main issue set to: %s\n", answer))

      ai_response <- paste0(
        i18n$t("Understood. I'll focus suggestions on"), " ", tolower(answer), "-related issues."
      )
      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = ai_response, timestamp = Sys.time())
      ))

      move_to_next_step()
    }

    # ... existing code for multiple type
  }
}
```

### 🔨 8. Update move_to_next_step() Function

Ensure progress bar and step counter account for 12 total steps (was 11).

### 🔨 9. Testing Checklist

- [ ] Regional sea selection displays all options
- [ ] Ecosystem types change based on regional sea selection
- [ ] Main issue shows relevant suggestions for selected region
- [ ] Quick options for drivers show context-aware suggestions
- [ ] Quick options for activities include region-specific items (e.g., "Herring fishing" for Baltic)
- [ ] Quick options for pressures include ecosystem-specific items (e.g., "Coral bleaching" for reefs)
- [ ] Progress bar correctly shows X/12 steps
- [ ] All context is preserved through the flow
- [ ] Auto-save still works with new context fields
- [ ] Recovery restores regional_sea and ecosystem_subtype

## Benefits of Enhancement

1. **More Relevant Suggestions**: Users get region-specific and ecosystem-specific options
2. **Better User Experience**: Less typing, more clicking on pre-populated relevant options
3. **Educational Value**: Users learn about typical issues in their region
4. **Comprehensive Coverage**: 10 regional seas × diverse ecosystems × context-aware categories
5. **Intelligent Flow**: Main issues suggested based on regional context

## Files Modified

- `modules/ai_isa_assistant_module.R` (main file)

## Next Steps

1. Complete remaining implementation items (steps 4-8 above)
2. Test thoroughly with different regional sea selections
3. Verify context preservation through save/recovery
4. Update translations if needed for new regional sea names
5. Consider adding visual indicators showing which context is active

---

**Last Updated**: 2025-11-07
**Completion**: 60%
