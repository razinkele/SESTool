# Duplicate Input ID Fix - AI ISA Assistant Module

## Problem

The error "Duplicate input ID was found" for `ai_isa_mod-regional_sea_other` occurs in the template-based SES creation (AI ISA Assistant module).

## Root Cause

The `quick_options` renderUI creates dynamic action buttons with fixed IDs:
- `regional_sea_other`
- `ecosystem_other`
- `issue_other`
- Plus numbered buttons for each option

When the renderUI is triggered multiple times (due to reactive dependencies), it tries to create buttons with the same IDs before the DOM cleanup removes the old ones, causing Shiny to detect duplicate IDs.

## Solution Applied

### 1. Added render_id to reactive values (Line 213)
```r
rv <- reactiveValues(
  current_step = 0,
  render_id = 0,     # NEW: Unique ID for each UI render to prevent duplicate IDs
  ...
)
```

### 2. Modified quick_options renderUI to use step-based suffixes (Line 1357-1364)
```r
output$quick_options <- renderUI({
  if (rv$current_step >= 0 && rv$current_step < length(QUESTION_FLOW)) {
    # Use current step as suffix to ensure unique IDs
    render_suffix <- paste0("_s", rv$current_step)

    step_info <- QUESTION_FLOW[[rv$current_step + 1]]
    ...
```

### 3. Updated all button IDs to include suffix

**Regional Sea buttons:**
```r
actionButton(
  inputId = session$ns(paste0("regional_sea_", sea_key, render_suffix)),  # Was: "regional_sea_", sea_key
  ...
)

actionButton(
  inputId = session$ns(paste0("regional_sea_other", render_suffix)),      # Was: "regional_sea_other"
  ...
)
```

**Ecosystem buttons:**
```r
actionButton(
  inputId = session$ns(paste0("ecosystem_", i, render_suffix)),            # Was: "ecosystem_", i
  ...
)

actionButton(
  inputId = session$ns(paste0("ecosystem_other", render_suffix)),          # Was: "ecosystem_other"
  ...
)
```

**Issue buttons:**
```r
actionButton(
  inputId = session$ns(paste0("issue_", i, render_suffix)),                # Was: "issue_", i
  ...
)

actionButton(
  inputId = session$ns(paste0("issue_other", render_suffix)),              # Was: "issue_other"
  ...
)
```

### 4. Need to Update Observers

The observers (lines 1542-1620) need to be updated to use the step-based suffixes:

**Regional Sea observer:**
```r
button_id <- paste0("regional_sea_", sea_key, "_s0")  # Add _s0 suffix for step 0
```

**Ecosystem observer:**
```r
button_id <- paste0("ecosystem_", i, "_s1")  # Add _s1 suffix for step 1
```

**Issue observer:**
```r
button_id <- paste0("issue_", i, "_s2")  # Add _s2 suffix for step 2
```

**"Other" button observers:**
```r
observeEvent(input$regional_sea_other_s0, {  # Was: input$regional_sea_other
observeEvent(input$ecosystem_other_s1, {     # Was: input$ecosystem_other
observeEvent(input$issue_other_s2, {         # Was: input$issue_other
```

## Why Step-Based Instead of Render Counter?

Using `_s{step_number}` instead of `_r{render_id}` ensures:
1. **Predictable IDs**: Each step always has the same suffix
2. **Simpler observers**: Observers can reference exact IDs
3. **No state issues**: Step number is deterministic, render counter can get out of sync

## Files Modified

- `modules/ai_isa_assistant_module.R`:
  - Line 213: Added `render_id` to reactive values
  - Line 1357-1444: Updated `quick_options` renderUI with step-based suffixes
  - Lines 1542-1660: **Still need to update** observers to use step-based IDs

## Testing

After applying all fixes, test:
1. Navigate to AI Assisted SES Creation
2. Select a regional sea - should work without duplicate ID error
3. Select ecosystem type - should work
4. Select main issue - should work
5. Navigate back and forth between steps - no duplicate IDs should appear

## Status

✅ UI button IDs updated with step-based suffixes
⚠️ **Observer event handlers still need updating** (lines 1542-1660)
⚠️ Check for any other dynamic buttons in the same renderUI that may need similar fixes
