# Phase 1 (v1.4.0) Implementation Guide
## Usability Foundations - Critical Fixes

**Status:** IN PROGRESS
**Started:** November 5, 2025
**Target Completion:** 2 weeks
**Version:** 1.4.0 - "Usability Foundations"

---

## Overview

Phase 1 focuses on the most critical usability issues that prevent data loss and improve basic navigation. These are the "must-fix" issues identified from user feedback.

---

## Sprint 1: Auto-Save and Navigation (Week 1)

### ✅ Day 1-2: Auto-Save Implementation

**Status:** COMPLETED (Module Created)

#### What Was Built

1. **Auto-Save Module** ([modules/auto_save_module.R](modules/auto_save_module.R))
   - Reactive timer triggering saves every 30 seconds
   - Debounced saves on data changes (minimum 5 seconds between saves)
   - Dual backup system:
     - RDS files in temp directory
     - JSON backup in browser localStorage
   - Session recovery modal on app restart
   - Visual save indicator (bottom-right corner)

2. **Features Implemented:**
   - ✅ Automatic saves every 30 seconds
   - ✅ localStorage backup via JavaScript
   - ✅ Session recovery with confirmation modal
   - ✅ "Last saved: X ago" indicator
   - ✅ Visual feedback (icons + colors):
     - 🔄 Yellow = Saving
     - ✓ Green = Saved
     - ⚠ Red = Error
   - ✅ Multilingual support (14 new translations)
   - ✅ Error handling and logging
   - ✅ Files stored up to 24 hours for recovery

#### How to Integrate into App

**Step 1: Merge Translations**

```r
# Run this script to merge auto-save translations
source("merge_autosave_translations.R")
```

**Step 2: Add to app.R UI**

```r
# In the UI section, add:

fluidPage(
  # ... existing UI ...

  # Add auto-save indicator
  auto_save_indicator_ui("auto_save"),

  # Add JavaScript handlers
  auto_save_js(),

  # ... rest of UI ...
)
```

**Step 3: Add to app.R Server**

```r
# In the server function:

server <- function(input, output, session) {
  # ... existing server code ...

  # Initialize auto-save
  auto_save_control <- auto_save_server(
    "auto_save",
    project_data,  # Your reactive project data
    i18n           # Translation object
  )

  # Optional: Control auto-save programmatically
  # auto_save_control$disable_autosave()  # When doing bulk operations
  # auto_save_control$enable_autosave()   # Re-enable after bulk ops
  # auto_save_control$force_save()        # Force immediate save

  # Handle recovered data
  observe({
    if (!is.null(session$userData$recovered_data)) {
      # Update your project_data with recovered data
      project_data(session$userData$recovered_data)
      session$userData$recovered_data <- NULL
    }
  })

  # ... rest of server code ...
}
```

#### Testing Checklist

- [ ] Auto-save triggers every 30 seconds
- [ ] Save indicator shows "Saving..." then "Saved"
- [ ] localStorage contains backup data
- [ ] Recovery modal appears after simulated crash
- [ ] "Recover Data" successfully loads previous state
- [ ] "Start Fresh" clears recovery file
- [ ] Works across all language settings
- [ ] No performance impact on large datasets

#### Known Limitations

1. **localStorage Size:** Browser localStorage typically limited to 5-10MB
   - Large projects may exceed this
   - RDS backup in temp directory is primary
   - localStorage is secondary backup only

2. **Temp Directory Cleanup:** Files older than 24 hours not auto-deleted
   - Consider adding cleanup routine in future version

3. **Multi-Tab Support:** Each tab creates separate auto-save
   - Not currently synchronized across tabs

---

### 🔄 Day 3-5: Navigation Improvements

**Status:** IN PROGRESS

#### Components to Build

1. **Breadcrumb Navigation Component**
   - Module: `modules/breadcrumb_nav_module.R`
   - Shows: Home > Create SES > Standard Entry > Step 2 of 7
   - Clickable navigation to previous steps
   - Updates dynamically based on current location

2. **Progress Bar Component**
   - Shows completion percentage
   - Visual progress: ████████░░░░░░░░ 30%
   - Step indicator: "Step 2 of 7: Ecosystem Services"

3. **Previous/Next Navigation**
   - Consistent buttons on all data entry pages
   - "← Back" and "Next →" buttons
   - Validation before proceeding to next step
   - "Edit" mode to return to completed steps

#### Implementation Plan

**Breadcrumb Module Structure:**

```r
breadcrumb_ui <- function(id) {
  # Breadcrumb trail with clickable links
  # Style: Home > Section > Page > Step
}

breadcrumb_server <- function(id, current_page, navigation_history) {
  # Track navigation history
  # Generate breadcrumb trail
  # Handle click events for navigation
}
```

**Progress Module Structure:**

```r
progress_indicator_ui <- function(id) {
  # Progress bar
  # Step counter
  # Step title
}

progress_indicator_server <- function(id, current_step, total_steps) {
  # Calculate progress percentage
  # Update visual indicators
}
```

---

## Sprint 2: AI Assistant Fix and Bug Fixes (Week 2)

### 📋 Day 1-3: AI Assistant Overhaul (Phase 1)

**Status:** PENDING

#### Current Problems
- Only provides list of elements, not integrated model
- Zero elements in final DAPSI(W)R(M) output
- No guidance on next steps
- Bug: adding everything instead of selected items

#### Solution Design

**Phase 1 Goals:**
1. Fix element generation to produce actual DAPSI(W)R(M) elements
2. Add step-by-step guidance
3. Show progress indicator
4. Fix selection bug

**New AI Assistant Flow:**

```
┌─────────────────────────────────────────────────┐
│ AI Assistant - Building Your Model              │
│ Progress: ███████░░░░░░░░░░░░░░░░ Step 3 of 7  │
├─────────────────────────────────────────────────┤
│                                                  │
│ Step 3: Identifying Ecosystem Services          │
│                                                  │
│ Based on your input, I've identified these      │
│ ecosystem services:                              │
│                                                  │
│ [ ✓ ] Fish provision                           │
│ [ ✓ ] Water filtration                         │
│ [ ✓ ] Coastal protection                       │
│ [   ] Nutrient cycling                         │
│ [   ] Carbon sequestration                     │
│                                                  │
│ Select the ones relevant to your system         │
│                                                  │
│ [Add Custom Service]    [Next: Marine Processes]│
└─────────────────────────────────────────────────┘
```

**Implementation Tasks:**
- [ ] Rewrite AI prompt to generate structured DAPSI(W)R(M) data
- [ ] Add progress tracking (Step X of 7)
- [ ] Implement checkbox selection (fix "add everything" bug)
- [ ] Add preview before committing elements
- [ ] Generate connections between levels
- [ ] Add "Edit" capability for each step

---

### 🐛 Day 4-5: Critical Bug Fixes

**Status:** PENDING

#### Bugs to Fix

1. **Deleted Nodes Reappearing in Reports**
   - Root cause: State management issue
   - Fix: Ensure deletions propagate to all data structures
   - Add deletion confirmation modal
   - Test: Delete node → generate report → verify absence

2. **Translation Issues**
   - Some strings still showing in English
   - Fix: Add missing translations
   - Complete translation QA pass
   - Test: Switch between all 7 languages, check all pages

3. **Intervention Analysis Inconsistency**
   - Sometimes works, sometimes doesn't
   - Root cause: Race condition in state updates
   - Fix: Proper reactive dependencies
   - Add validation before analysis runs

---

## Integration Checklist

Before releasing v1.4.0:

### Auto-Save
- [ ] Merged translations
- [ ] Added to app.R UI
- [ ] Added to app.R server
- [ ] Tested with all modules
- [ ] Tested recovery workflow
- [ ] Performance tested (large projects)
- [ ] Tested in all 7 languages

### Navigation
- [ ] Breadcrumb component created
- [ ] Progress indicator created
- [ ] Previous/Next buttons added to all data entry modules
- [ ] Step validation implemented
- [ ] Edit mode functional
- [ ] Tested navigation flow end-to-end

### AI Assistant
- [ ] Element generation fixed
- [ ] Progress indicator added
- [ ] Selection bug fixed
- [ ] Connection generation working
- [ ] Preview functionality added
- [ ] Tested with multiple scenarios

### Bug Fixes
- [ ] Deleted nodes stay deleted
- [ ] All translations complete
- [ ] Intervention analysis consistent
- [ ] All fixes tested

---

## Testing Protocol

### Test Scenarios

**Scenario 1: Auto-Save Recovery**
1. Start creating a model
2. Add several elements
3. Kill browser tab (simulate crash)
4. Reopen application
5. Verify recovery modal appears
6. Click "Recover Data"
7. Verify all data restored

**Scenario 2: Navigation Flow**
1. Start in Create SES > Standard Entry
2. Complete Step 1 (Drivers)
3. Click Next → Step 2
4. Verify progress bar updates
5. Click Back → Step 1
6. Verify can edit previous data
7. Click breadcrumb → Home
8. Verify navigation history

**Scenario 3: AI Assistant Complete Flow**
1. Start AI Assistant
2. Follow prompts through all 7 steps
3. Verify elements created at each step
4. Verify connections generated
5. View final CLD
6. Verify model is complete and usable

---

## Performance Metrics

### Before v1.4.0
- Data loss incidents: Several reported
- User abandonment: High (users lost work)
- Navigation clarity: 3/10
- AI Assistant success: 0%

### Target for v1.4.0
- Data loss incidents: 0 (with auto-save)
- User abandonment: < 20%
- Navigation clarity: 7/10
- AI Assistant success: 60%

---

## Release Notes (Draft)

### Version 1.4.0 - "Usability Foundations" (Target: November 19, 2025)

#### New Features

**Auto-Save System**
- Automatic saves every 30 seconds
- Browser backup in localStorage
- Session recovery on restart
- Visual save indicator with status
- Works across all modules

**Improved Navigation**
- Breadcrumb trail showing current location
- Progress indicator in data entry workflow
- Previous/Next buttons for easy navigation
- Step validation before proceeding
- Edit mode to revise completed steps

#### Major Fixes

**AI Assistant**
- Now generates complete DAPSI(W)R(M) models
- Step-by-step guidance with progress tracking
- Fixed selection bug (no longer adds everything)
- Preview before committing elements

**Critical Bugs**
- Fixed deleted nodes reappearing in reports
- Completed missing translations
- Fixed intervention analysis inconsistency

#### Technical Improvements
- Improved state management
- Better error handling
- Enhanced logging
- Performance optimizations

---

## Developer Notes

### File Structure
```
modules/
├── auto_save_module.R          # New - Auto-save functionality
├── breadcrumb_nav_module.R     # New - Breadcrumb navigation
├── progress_indicator_module.R # New - Progress tracking
├── ai_isa_assistant_module.R   # Modified - Overhauled
└── ... existing modules ...

translations/
├── translation.json             # Updated - Added 14 auto-save strings
└── ...
```

### Dependencies
- No new package dependencies required
- Uses existing: shiny, shinyjs, jsonlite

### Configuration
- Auto-save interval: 30 seconds (configurable in module)
- Recovery window: 24 hours (configurable)
- localStorage key prefix: 'marinesabres_autosave_'

---

## Next Steps

1. **Complete Sprint 1** (Days 3-5):
   - Build breadcrumb component
   - Build progress indicator
   - Add Previous/Next buttons
   - Test navigation flow

2. **Begin Sprint 2** (Week 2):
   - AI Assistant overhaul
   - Bug fixes
   - Integration testing

3. **Prepare for v1.4.0 Release**:
   - Complete all testing
   - Update VERSION_INFO.json
   - Update CHANGELOG.md
   - Create release notes
   - Deploy to production

---

**Last Updated:** November 5, 2025
**Status:** Sprint 1, Days 1-2 completed
**Next Milestone:** Complete navigation components by November 10, 2025
