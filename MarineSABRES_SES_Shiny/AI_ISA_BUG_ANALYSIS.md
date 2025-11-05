# AI ISA Assistant - Bug Analysis and Fix Plan

**Date:** November 5, 2025
**Sprint:** Phase 1, Sprint 2 (Days 1-3)
**Module:** `modules/ai_isa_assistant_module.R`

---

## User-Reported Issues

From user feedback:
1. **"AI Assistant: Only provided list of elements, not integrated model"**
2. **"AI Assistant: Zero elements in final DAPSI(W)R(M) output"**
3. **"Bug: adding everything instead of selected items"**

---

## Root Cause Analysis

### Bug #1: Multiple Observer Registration (Lines 888-894)

**Location:** `modules/ai_isa_assistant_module.R:888-894`

```r
observe({
  rv$current_step

  # ... other code ...

  if (!is.null(step_info$examples)) {
    lapply(seq_along(step_info$examples), function(i) {
      observeEvent(input[[paste0("quick_opt_", i)]], {
        example <- step_info$examples[i]
        process_answer(example)
      }, ignoreInit = TRUE)
    })
  }
})
```

**Problem:**
- Observer handlers for quick option buttons are created inside an `observe()` block
- This block re-executes whenever `rv$current_step` changes
- Each time it runs, NEW observers are created for the same inputs
- Result: Multiple handlers accumulate, causing the same action to trigger multiple times
- **This explains the "adding everything instead of selected items" bug**

**Impact:**
- Clicking a quick option button once may add the item multiple times
- The number of duplicates increases as the user progresses through steps
- Creates memory leaks and performance degradation

### Bug #2: Save Function Works Correctly

**Location:** `modules/ai_isa_assistant_module.R:1736-2033`

**Analysis:**
After reviewing the `save_to_isa` handler, the save functionality appears to be implemented correctly:
- Elements are properly converted from `rv$elements` to dataframes
- All DAPSI(W)R(M) components are mapped correctly
- Adjacency matrices are built from approved connections
- Project data is updated via `project_data_reactive(current_data)`

**Conclusion:**
The "zero elements in output" issue is likely a **side effect of Bug #1**:
- If elements are duplicated or corrupted due to the multiple observer bug
- Or if the data structure becomes malformed
- The save might complete but data quality is compromised

### Bug #3: Missing Progress Visualization

**Current State:**
- Progress bar CSS exists (lines 52-68)
- Step indicator div exists (lines 43-51)
- BUT: Progress bar is not actively rendered/updated
- Users have no visual feedback of their position in the workflow

**Impact:**
- Users don't know how many steps remain
- No sense of completion progress
- Contributes to perception of "not working"

---

## Fix Plan

### Fix #1: Refactor Observer Pattern

**Solution:** Move observer registration outside reactive context

**Before (Buggy):**
```r
observe({
  rv$current_step
  # Creates new observers on every step change
  lapply(seq_along(step_info$examples), function(i) {
    observeEvent(input[[paste0("quick_opt_", i)]], {
      process_answer(example)
    })
  })
})
```

**After (Fixed):**
```r
# Create a reactive value to store current examples
current_examples <- reactiveVal(NULL)

# Update examples when step changes
observe({
  step_info <- QUESTION_FLOW[[rv$current_step + 1]]
  if (!is.null(step_info$examples)) {
    current_examples(step_info$examples)
  } else {
    current_examples(NULL)
  }
})

# Single observer using observeEvent with dynamic ID handling
observe({
  examples <- current_examples()
  if (!is.null(examples)) {
    lapply(seq_along(examples), function(i) {
      local({
        idx <- i  # Capture index in closure
        observeEvent(input[[paste0("quick_opt_", idx)]], {
          process_answer(examples[idx])
        }, ignoreInit = TRUE, once = TRUE)  # Use once=TRUE for each step
      })
    })
  }
})
```

### Fix #2: Add Active Progress Indicator

**Implementation:**

1. **Add progress bar output** to sidebar (already have CSS)
2. **Calculate and display progress** based on `rv$current_step / rv$total_steps`
3. **Update dynamically** as user progresses

**Code to Add:**
```r
output$progress_indicator <- renderUI({
  progress_pct <- round((rv$current_step / rv$total_steps) * 100)

  div(class = "progress-bar-custom",
    div(class = "progress-fill",
      style = sprintf("width: %d%%;", progress_pct),
      sprintf("%d%%", progress_pct)
    )
  )
})
```

### Fix #3: Integrate New Progress Indicator Module

**Implementation:**

1. Import the progress indicator module created in Sprint 1
2. Replace inline progress with proper module
3. Add step titles for each DAPSI(W)R(M) stage
4. Show visual step list with completion status

**Benefits:**
- Professional progress visualization
- Clear step titles (not just numbers)
- Visual completion status
- Consistent with Sprint 1 navigation components

### Fix #4: Add Element Preview Before Save

**Implementation:**

1. Show preview modal with all elements before "Save to ISA"
2. Allow users to review and confirm
3. Provide element counts per category
4. Show connection summary

**Code Pattern:**
```r
observeEvent(input$save_to_isa, {
  # Show confirmation modal first
  showModal(modalDialog(
    title = i18n$t("Confirm Save"),
    h4(i18n$t("You are about to save the following elements:")),

    # Element summary
    tags$ul(
      tags$li(sprintf(i18n$t("%d Drivers"), length(rv$elements$drivers))),
      tags$li(sprintf(i18n$t("%d Activities"), length(rv$elements$activities))),
      # ... etc for all categories
    ),

    footer = tagList(
      modalButton(i18n$t("Cancel")),
      actionButton(ns("confirm_save"), i18n$t("Confirm Save"), class = "btn-success")
    )
  ))
})

observeEvent(input$confirm_save, {
  # Actual save logic here
  # ... existing save code ...
  removeModal()
})
```

---

## Testing Protocol

### Test Scenario 1: Quick Option Bug Fix

1. Start AI Assistant
2. Reach a step with quick options (e.g., Drivers)
3. Click first quick option
4. Verify ONLY ONE element is added (not multiple)
5. Continue through multiple steps
6. Click quick options at each step
7. Verify each click adds exactly one element

**Expected Result:** Each quick option click adds exactly one element, no duplicates

### Test Scenario 2: Progress Indicator

1. Start AI Assistant
2. Verify progress bar shows 0% initially
3. Answer first question
4. Verify progress updates (e.g., to 9% for step 1/11)
5. Continue through all steps
6. Verify progress reaches 100% at completion

**Expected Result:** Progress bar updates smoothly, shows accurate percentage

### Test Scenario 3: Complete Model Creation

1. Start AI Assistant
2. Answer all questions, adding elements at each step
3. Review final element counts in sidebar
4. Click "Save to ISA Data Entry"
5. Navigate to ISA Data Entry module
6. Verify all elements appear in correct categories
7. Check CLD visualization
8. Verify connections are present

**Expected Result:** All elements saved correctly, model is complete and usable

### Test Scenario 4: Element Counts

1. Complete full workflow
2. Before saving, note element counts in sidebar:
   - Drivers: X
   - Activities: Y
   - Pressures: Z
   - etc.
3. Save to ISA
4. In ISA Data Entry, verify counts match exactly

**Expected Result:** Element counts match between AI Assistant and ISA Data Entry

---

## Implementation Priority

1. **CRITICAL (Do First):** Fix multiple observer bug
2. **HIGH:** Add active progress indicator
3. **MEDIUM:** Integrate Sprint 1 progress module
4. **LOW:** Add save confirmation modal

---

## Translation Needs

New strings to translate:
- "Step %d of %d: %s" (step progress format)
- "Review your model" (save confirmation)
- "%d Drivers" (element count format)
- "%d Activities" (element count format)
- ... (one for each DAPSI(W)R(M) category)

---

## Files to Modify

1. `modules/ai_isa_assistant_module.R` - Main fixes
2. `translations/translation.json` - New translation strings
3. `PHASE1_IMPLEMENTATION_GUIDE.md` - Update Sprint 2 progress

---

## Expected Outcomes

After fixes:
- ✅ Quick options work correctly (no duplicates)
- ✅ Progress clearly visible to users
- ✅ All elements save correctly to ISA
- ✅ Model is complete and usable
- ✅ User confidence in AI Assistant restored

---

**Analysis completed by:** Claude Code
**Next Step:** Implement fixes starting with critical observer bug
