# AI ISA Assistant - Remaining Implementation Steps

**Status**: 80% Complete
**Remaining**: 20% (Observers + Testing)

## What's Already Done ✅

1. ✅ Context-aware knowledge base (`REGIONAL_SEAS` + `get_context_suggestions()`)
2. ✅ Updated `rv$context` to include regional_sea and ecosystem_subtype
3. ✅ Redesigned QUESTION_FLOW with 12 steps
4. ✅ Updated `rv$total_steps` to 12
5. ✅ Completely rewrote `output$quick_options` rendering

## What Remains 🔨

### Step 1: Add Observers for New Button Types

The new quick options render creates buttons with IDs like:
- `regional_sea_baltic`, `regional_sea_mediterranean`, etc.
- `ecosystem_1`, `ecosystem_2`, etc.
- `issue_1`, `issue_2`, etc.

These buttons need observers to handle clicks. The existing observer pattern (around line 1475) handles `quick_opt_` buttons, but we need to add handlers for the new button patterns.

**Location**: Find the existing observer block around line 1475 that sets up observers for quick options. Add this BEFORE that existing block:

```r
# ========================================================================
# OBSERVERS FOR CONTEXT-AWARE BUTTONS (Regional Sea, Ecosystem, Issue)
# ========================================================================

# Observer for Regional Sea Buttons
observe({
  current_step <- rv$current_step

  if (current_step == 1) {  # Regional sea selection step
    lapply(names(REGIONAL_SEAS), function(sea_key) {
      button_id <- paste0("regional_sea_", sea_key)
      observeEvent(input[[button_id]], {
        if (rv$current_step == 1) {  # Still on regional sea step
          sea_name <- REGIONAL_SEAS[[sea_key]]$name_en
          rv$context$regional_sea <- sea_key

          # Add to conversation
          rv$conversation <- c(rv$conversation, list(
            list(type = "user", message = sea_name, timestamp = Sys.time())
          ))

          ai_response <- paste0(
            i18n$t("Great! You selected"), " ", REGIONAL_SEAS[[sea_key]]$name_i18n, ". ",
            i18n$t("This will help me suggest relevant activities and pressures specific to your region.")
          )

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

          cat(sprintf("[AI ISA] Regional sea set to: %s\n", sea_name))
          move_to_next_step()
        }
      }, ignoreInit = TRUE, once = TRUE)
    })
  }
})

# Observer for Ecosystem Type Buttons
observe({
  current_step <- rv$current_step

  if (current_step == 2 && !is.null(rv$context$regional_sea)) {  # Ecosystem selection step
    ecosystem_types <- REGIONAL_SEAS[[rv$context$regional_sea]]$ecosystem_types

    lapply(seq_along(ecosystem_types), function(i) {
      button_id <- paste0("ecosystem_", i)
      observeEvent(input[[button_id]], {
        if (rv$current_step == 2) {  # Still on ecosystem step
          ecosystem_name <- ecosystem_types[i]
          rv$context$ecosystem_type <- ecosystem_name

          # Add to conversation
          rv$conversation <- c(rv$conversation, list(
            list(type = "user", message = ecosystem_name, timestamp = Sys.time())
          ))

          ai_response <- paste0(
            i18n$t("Perfect!"), " ", ecosystem_name, " ",
            i18n$t("ecosystems have unique characteristics that I'll consider in my suggestions.")
          )

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

          cat(sprintf("[AI ISA] Ecosystem type set to: %s\n", ecosystem_name))
          move_to_next_step()
        }
      }, ignoreInit = TRUE, once = TRUE)
    })
  }
})

# Observer for Main Issue Buttons
observe({
  current_step <- rv$current_step

  if (current_step == 3 && !is.null(rv$context$regional_sea)) {  # Issue selection step
    issues <- REGIONAL_SEAS[[rv$context$regional_sea]]$common_issues

    lapply(seq_along(issues), function(i) {
      button_id <- paste0("issue_", i)
      observeEvent(input[[button_id]], {
        if (rv$current_step == 3) {  # Still on issue step
          issue_name <- issues[i]
          rv$context$main_issue <- issue_name

          # Add to conversation
          rv$conversation <- c(rv$conversation, list(
            list(type = "user", message = issue_name, timestamp = Sys.time())
          ))

          ai_response <- paste0(
            i18n$t("Understood. I'll focus suggestions on"), " ", tolower(issue_name), "-related issues. ",
            i18n$t("Now let's start building your DAPSI(W)R(M) framework!")
          )

          rv$conversation <- c(rv$conversation, list(
            list(type = "ai", message = ai_response, timestamp = Sys.time())
          ))

          cat(sprintf("[AI ISA] Main issue set to: %s\n", issue_name))
          move_to_next_step()
        }
      }, ignoreInit = TRUE, once = TRUE)
    })
  }
})
```

### Step 2: Update process_answer() Function

**Location**: Find the `process_answer <- function(answer) {` around line 1718

Add this code at the START of the function (before existing checks):

```r
process_answer <- function(answer) {
  if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
    step_info <- QUESTION_FLOW[[rv$current_step + 1]]

    # === NEW: Handle context-setting steps ===

    # Regional sea (should be handled by buttons, but allow text input too)
    if (step_info$target == "regional_sea") {
      # Try to match input to a regional sea
      matched_sea <- NULL
      for (sea_key in names(REGIONAL_SEAS)) {
        if (grepl(answer, REGIONAL_SEAS[[sea_key]]$name_en, ignore.case = TRUE) ||
            grepl(answer, REGIONAL_SEAS[[sea_key]]$name_i18n, ignore.case = TRUE)) {
          matched_sea <- sea_key
          break
        }
      }

      if (!is.null(matched_sea)) {
        rv$context$regional_sea <- matched_sea
        cat(sprintf("[AI ISA] Regional sea set to: %s (text input)\n", REGIONAL_SEAS[[matched_sea]]$name_en))

        ai_response <- paste0(
          i18n$t("Great! You selected"), " ", REGIONAL_SEAS[[matched_sea]]$name_i18n, ". ",
          i18n$t("This will help me suggest relevant activities and pressures specific to your region.")
        )
      } else {
        # Couldn't match, use "other"
        rv$context$regional_sea <- "other"
        cat("[AI ISA] Regional sea set to: other (text input not matched)\n")
        ai_response <- i18n$t("I'll use general marine suggestions for your area.")
      }

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = ai_response, timestamp = Sys.time())
      ))

      move_to_next_step()
      return()
    }

    # Ecosystem type (should be handled by buttons, but allow text input too)
    else if (step_info$target == "ecosystem_type") {
      rv$context$ecosystem_type <- answer
      cat(sprintf("[AI ISA] Ecosystem type set to: %s (text input)\n", answer))

      ai_response <- paste0(
        i18n$t("Perfect!"), " ", answer, " ",
        i18n$t("ecosystems have unique characteristics that I'll consider in my suggestions.")
      )

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = ai_response, timestamp = Sys.time())
      ))

      move_to_next_step()
      return()
    }

    # Main issue
    else if (step_info$target == "main_issue") {
      rv$context$main_issue <- answer
      cat(sprintf("[AI ISA] Main issue set to: %s\n", answer))

      ai_response <- paste0(
        i18n$t("Understood. I'll focus suggestions on"), " ", tolower(answer), "-related issues. ",
        i18n$t("Now let's start building your DAPSI(W)R(M) framework!")
      )

      rv$conversation <- c(rv$conversation, list(
        list(type = "ai", message = ai_response, timestamp = Sys.time())
      ))

      move_to_next_step()
      return()
    }

    # === EXISTING CODE CONTINUES HERE ===
    # Store answer based on target
    if (step_info$type == "multiple") {
      # ... existing code for multiple type
```

## Testing Checklist

Once the above code is added, test the following:

### Basic Flow Test
1. ✅ Start new ISA framework
2. ✅ Enter project name → proceeds to step 2
3. ✅ Select regional sea (e.g., "Baltic Sea") → buttons work
4. ✅ Verify ecosystem options change based on regional sea
5. ✅ Select ecosystem type → proceeds to step 4
6. ✅ Verify main issue suggestions are relevant to selected region
7. ✅ Select main issue → proceeds to step 5

### Context-Aware Suggestions Test
8. ✅ At drivers step: verify suggestions include region-specific items
9. ✅ At activities step: verify suggestions include ecosystem-specific items
10. ✅ At pressures step: verify suggestions include issue-specific items
11. ✅ Verify header shows "AI-suggested options (tailored for Baltic Sea - Estuary)"

### Different Region Test
12. ✅ Start new framework
13. ✅ Select "Mediterranean Sea"
14. ✅ Verify ecosystem options show: "Open coast", "Coastal lagoon", "Rocky shore", etc.
15. ✅ Select "Coral reef" ecosystem
16. ✅ Verify activities include: "Scuba diving", "Snorkeling", "Reef fishing"

### Edge Cases
17. ✅ Text input instead of button click works for all three context steps
18. ✅ Progress bar shows "X of 12" correctly
19. ✅ Step counter shows "Step X of 12"
20. ✅ Auto-save preserves regional_sea and ecosystem_type context
21. ✅ Recovery restores context correctly

## Files to Verify

After implementation, check these files compile without errors:

1. `modules/ai_isa_assistant_module.R` - Main file with all changes
2. `translations/translation.json` - May need new translations for:
   - "Select your regional sea:"
   - "Common ecosystem types in"
   - "Common issues in your region (or type your own below):"
   - "AI-suggested options"
   - "tailored for"
   - "This will help me suggest relevant activities and pressures specific to your region."
   - "ecosystems have unique characteristics that I'll consider in my suggestions."
   - "I'll focus suggestions on"
   - "Now let's start building your DAPSI(W)R(M) framework!"

## Final Restart

After adding the observers and updating process_answer():

```bash
# Kill running servers
tasklist | findstr Rscript

# Restart
cd "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny"
Rscript -e "shiny::runApp(port = 3838, launch.browser = FALSE)"
```

## Expected Behavior Summary

**Before**: Static examples for all steps, no regional context

**After**:
- Step 1: Choose from 10 regional seas
- Step 2: See 3-5 ecosystem types specific to chosen sea
- Step 3: See 4-6 common issues specific to chosen sea
- Steps 4-11: See 8-15 context-aware suggestions combining region + ecosystem + issue
- Headers show which context is active
- Users can still type custom answers

---

**Last Updated**: 2025-11-07
**Completion Status**: 80% → Ready for final 20% implementation
