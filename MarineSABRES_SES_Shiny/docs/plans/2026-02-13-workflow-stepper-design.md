# Workflow Stepper Overlay — Design Document

**Date:** 2026-02-13
**Status:** Approved
**Scope:** Beginner-level guided workflow improvement

## Problem

Beginners using the SES Toolbox face three issues:
1. **Users get lost** — after completing a step, they don't know what to do next
2. **Too many options** — the sidebar presents 15+ items without clear sequencing
3. **Steps feel disconnected** — each module feels standalone rather than part of a pipeline

## Solution

A persistent horizontal stepper bar rendered above the main content area (inside `bs4DashBody`), visible only for beginner-level users. It shows the full analysis pipeline and the user's current position.

## Pipeline Stages

| Step | Label | Sidebar Tab | Complete When |
|------|-------|-------------|---------------|
| 1 | Get Started | `entry_point` | EP4 recommendations shown |
| 2 | Create SES | `isa_data_entry` / `ai_isa` / `template_ses` | `elements` list has >= 2 items (user-modified) |
| 3 | Visualize | `cld_visualization` | CLD tab visited with data loaded (3s dwell) |
| 4 | Analyze | `loop_detection` | Loop detection results generated |
| 5 | Report | `prepare_report` | Report generated (any format) |

## UI Design

```
┌──────────────────────────────────────────────────────────────────────┐
│  checkmark Get Started ── dot Create SES ── o Visualize ── o Analyze ── o Report   x  │
│     Completed          In Progress         Locked        Locked      Locked         │
└──────────────────────────────────────────────────────────────────────┘
```

### Step States

- **Completed** — green checkmark, clickable, navigates to that tab
- **Current/Active** — blue filled dot, pulsing glow (reuses `.pulse-glow`)
- **Enabled** — grey hollow dot, clickable
- **Locked** — grey hollow dot, not clickable, tooltip: "Create your SES first"
- **Connecting lines** — solid between completed, dashed between incomplete

### Dismiss

The x button hides the bar for the current session (`workflow$visible <- FALSE`). It reappears on next session.

## State Model

```r
workflow <- reactiveValues(
  current_step = 1,
  completed = c(FALSE, FALSE, FALSE, FALSE, FALSE),
  enabled = c(TRUE, TRUE, FALSE, FALSE, FALSE),
  visible = TRUE,
  user_modified_ses = FALSE
)
```

Steps 3-5 unlock when step 2 completes. Steps are not strictly sequential — users can revisit earlier steps.

## Completion Detection & Navigation Nudges

Each step completion triggers a one-time `showNotification()` with an action button pointing to the next step:

- **Step 1 done:** Entry point module shows recommendations. Set `completed[1] <- TRUE`.
- **Step 2 done:** Observe `project_data_reactive()`. When `length(data$elements) >= 2` AND `user_modified_ses == TRUE`, mark complete. Unlock steps 3-5. Notification: "Your SES model has X elements. Next: visualize it." `[Go to Visualization]`
- **Step 3 done:** Observe sidebar tab == `cld_visualization` with data present for 3 seconds. Notification: "Next: run Loop Detection." `[Go to Loop Detection]`
- **Step 4 done:** Observe loop detection results stored in reactive. Notification: "Analysis complete! Generate a report." `[Generate Report]`
- **Step 5 done:** Observe report path reactive is non-NULL. Celebration notification: "You've completed the full pipeline!"

Notifications fire once per step (tracked by flag). They don't repeat on revisit.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| User imports a pre-built project | Steps 1-2 auto-complete, stepper starts at step 3 |
| User deletes all elements | Steps 3-5 re-lock, step 2 reverts |
| User switches to intermediate level | Stepper hides immediately |
| Saved project loaded via JSON restore | Re-evaluate all completion conditions |
| Caribbean template auto-loads on startup | Step 2 does NOT auto-complete (no user modification yet) |

### Auto-load vs User Work

`workflow$user_modified_ses` starts as `FALSE`. Flips to `TRUE` on any `project_data_reactive()` change after initial load. This prevents the auto-loaded Caribbean template from triggering step 2 completion.

## Visibility Rules

- Shown when `user_level == "beginner"` AND `workflow$visible == TRUE`
- Hidden for intermediate/expert users
- Dismiss is session-only (reappears next session)

## Accessibility

- `role="navigation"` with `aria-label="Workflow progress"`
- Active step: `aria-current="step"`
- Locked steps: `aria-disabled="true"`

## File Changes

### New Files (3)

| File | Purpose | Est. Lines |
|------|---------|------------|
| `modules/workflow_stepper_module.R` | Module UI + server | ~150 |
| `www/workflow-stepper.css` | Stepper bar styling | ~80 |
| `translations/modules/workflow_stepper.json` | 10 keys x 9 languages | ~100 |

### Modified Files (2)

| File | Change | Est. Lines |
|------|--------|------------|
| `global.R` | Add `source("modules/workflow_stepper_module.R")` | +1 |
| `app.R` | Add stepper UI in `bs4DashBody()` + wire server | +11 |

### No Changes To

All existing modules remain untouched. The stepper observes shared reactives from the parent session.

## Dependencies

Zero new R packages. Uses shiny, bs4Dash, and existing `navigation_helpers.R` functions (`create_progress_bar`, `create_nav_buttons`).

## Total Scope

~250 lines of new code across 3 new files + 2 minor modifications.
