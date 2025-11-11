# Bug Analysis: Deleted Nodes Keep Reappearing in Reports

**Date:** November 5, 2025
**Sprint:** Phase 1, Sprint 2 (Days 3-5)
**Priority:** HIGH
**Impact:** Users lose work when simplified networks aren't saved

---

## User-Reported Issue

"Deleted nodes keep reappearing in reports"

---

## Root Cause Analysis

### The Problem

When users apply network simplification in the Analysis Tools module (removing nodes via endogenization, encapsulation, etc.), the changes are only stored in **local reactive values** within `analysis_tools_module.R`. These simplified versions are **never written back** to `project_data_reactive()$data$cld$nodes`.

All export and report functions access the original `project_data$data$cld$nodes` directly, which still contains all nodes including those that were supposedly "deleted."

### State Management Flow (Current - Broken)

```
User deletes nodes via simplification
    ↓
rv$simplified_nodes (local only)
    ↓
Export/Report generated
    ↓
Accesses project_data$data$cld$nodes (original, unchanged)
    ↓
Deleted nodes reappear!
```

### What Should Happen

```
User deletes nodes via simplification
    ↓
rv$simplified_nodes (local)
    ↓
User chooses to save to project
    ↓
project_data$data$cld$nodes updated
    ↓
Export/Report generated
    ↓
Uses updated project_data$data$cld$nodes
    ↓
Deleted nodes stay deleted!
```

---

## File Locations and Code

### Report Generation Code (Always uses original data)

**modules/export_functions.R:152-156** - CLD Nodes Export:
```r
if (!is.null(project_data$data$cld$nodes) &&
    is.data.frame(project_data$data$cld$nodes) &&
    nrow(project_data$data$cld$nodes) > 0) {
  addWorksheet(wb, "CLD_Nodes")
  writeData(wb, "CLD_Nodes", project_data$data$cld$nodes)  # ← Uses original data
}
```

**app.R:1291-1293** - Data Export:
```r
if("cld" %in% components) {
  export_list$cld_nodes <- data$data$cld$nodes  # ← Uses original data
  export_list$cld_edges <- data$data$cld$edges
}
```

### Node Deletion/Simplification Code (Only modifies local reactive values)

**modules/analysis_tools_module.R:2297-2488** - Apply Simplification Observer:
```r
observeEvent(input$apply_simplification, {
  req(rv$original_nodes, rv$original_edges)

  # Start with original network
  nodes <- rv$original_nodes
  edges <- rv$original_edges

  # ... performs various deletion operations ...

  # Lines 2474-2480 - Only updates LOCAL reactive values:
  rv$simplified_nodes <- nodes  # ← Only local
  rv$simplified_edges <- edges  # ← Only local
  rv$removed_nodes <- all_removed_nodes  # ← Only local
  rv$removed_edges <- all_removed_edges  # ← Only local
  rv$simplification_history <- history
  rv$has_simplified <- TRUE

  # ← NO SAVE TO project_data_reactive() !!
})
```

**modules/analysis_tools_module.R:2707-2730** - Export Simplified Network:
```r
output$export_simplified <- downloadHandler(
  filename = function() {
    paste0("simplified_network_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".RData")
  },
  content = function(file) {
    simplified_network <- list(
      nodes = rv$simplified_nodes,  # ← Local data
      edges = rv$simplified_edges,
      removed_nodes = rv$removed_nodes,
      removed_edges = rv$removed_edges,
      ...
    )
    save(simplified_network, file = file)  # ← Saves to separate file
  }
)
```

---

## Why It Happens

The simplification is designed as a **temporary analysis tool** for viewing simplified networks, not for permanent modification. The module exports simplified data to a **separate RData file** rather than updating the main project.

There's no mechanism to persist simplifications back to the main CLD data structure.

---

## Comparison with Working Code

**Scenario Builder module works correctly** because:
1. It stores modifications in the scenario object
2. It explicitly saves back to project data via `save_scenarios_to_project()`
3. When applying scenario modifications, it creates a new filtered network on-the-fly

**Analysis Tools simplification module fails** because:
1. It only stores modifications in local reactive values
2. It never saves back to project data
3. Exports always use the original, unmodified data

---

## Fix Implementation Plan

### Option A: Add Explicit Save Functionality (RECOMMENDED)

Add a "Save Simplified Network to Project" button that gives users control over when to persist changes.

**Changes to modules/analysis_tools_module.R:**

1. **Add UI checkbox (after line ~1984):**
```r
checkboxInput(
  ns("save_to_project"),
  i18n$t("Save simplified network to project"),
  value = FALSE
),
helpText(i18n$t("save_simplification_warning"))
```

2. **Add save logic (after line 2480):**
```r
# After: rv$has_simplified <- TRUE

if (input$save_to_project) {
  data <- project_data_reactive()

  # Store original for undo capability
  if (is.null(data$data$cld$original_nodes)) {
    data$data$cld$original_nodes <- data$data$cld$nodes
    data$data$cld$original_edges <- data$data$cld$edges
  }

  # Save simplified network
  data$data$cld$nodes <- rv$simplified_nodes
  data$data$cld$edges <- rv$simplified_edges
  data$data$cld$removed_nodes <- rv$removed_nodes
  data$data$cld$simplification_history <- rv$simplification_history
  data$last_modified <- Sys.time()

  project_data_reactive(data)

  showNotification(
    i18n$t("Simplified network saved to project"),
    type = "message",
    duration = 3
  )
}
```

3. **Add undo functionality:**
```r
observeEvent(input$restore_original, {
  req(project_data_reactive()$data$cld$original_nodes)

  data <- project_data_reactive()
  data$data$cld$nodes <- data$data$cld$original_nodes
  data$data$cld$edges <- data$data$cld$original_edges
  data$data$cld$original_nodes <- NULL
  data$data$cld$original_edges <- NULL
  data$data$cld$removed_nodes <- NULL
  data$data$cld$simplification_history <- NULL
  data$last_modified <- Sys.time()

  project_data_reactive(data)

  showNotification(
    i18n$t("Original network restored"),
    type = "message",
    duration = 3
  )
})
```

### Option B: Filter Exports Based on Simplification State

Modify export functions to check if simplification exists and use those nodes instead.

**Changes to functions/export_functions.R:**

```r
# Line 152-156 - Check for simplified data:
nodes_to_export <- if (!is.null(project_data$data$cld$simplified_nodes)) {
  project_data$data$cld$simplified_nodes
} else {
  project_data$data$cld$nodes
}

if (!is.null(nodes_to_export) && nrow(nodes_to_export) > 0) {
  addWorksheet(wb, "CLD_Nodes")
  writeData(wb, "CLD_Nodes", nodes_to_export)
}
```

---

## Translation Needs

New strings to add:
- "Save simplified network to project"
- "Warning: This will permanently modify your CLD data. Consider saving project first."
- "Simplified network saved to project"
- "Restore Original Network"
- "Original network restored"

---

## Testing Protocol

### Test Scenario 1: Simplification Without Save
1. Load project with 50 nodes
2. Apply endogenization to remove 10 exogenous nodes
3. Verify simplified visualization shows 40 nodes
4. Export to Excel WITHOUT checking "Save to project"
5. Open Excel file
6. **Expected:** Should show all 50 original nodes (not saved)

### Test Scenario 2: Simplification With Save
1. Load project with 50 nodes
2. Apply endogenization to remove 10 exogenous nodes
3. Check "Save to project" checkbox
4. Apply simplification
5. Verify notification: "Simplified network saved to project"
6. Export to Excel
7. Open Excel file
8. **Expected:** Should show only 40 remaining nodes

### Test Scenario 3: Restore Original
1. Continue from Test 2 (simplified network saved)
2. Click "Restore Original Network" button
3. Verify notification: "Original network restored"
4. Export to Excel
5. Open Excel file
6. **Expected:** Should show all 50 original nodes again

### Test Scenario 4: Generate Report
1. Simplify network and save to project
2. Generate executive summary report
3. Open PDF/HTML report
4. **Expected:** Network statistics should reflect simplified network (e.g., "Network has 40 nodes")

---

## Files to Modify

1. `modules/analysis_tools_module.R` - Add save/restore functionality
2. `translations/translation.json` - New translation strings
3. `PHASE1_IMPLEMENTATION_GUIDE.md` - Update Sprint 2 progress

---

## Expected Outcomes

After fix:
- ✅ Users have explicit control over when to save simplifications
- ✅ Exports and reports reflect saved simplifications
- ✅ Undo capability allows restoring original network
- ✅ Clear warnings prevent accidental data loss
- ✅ All exports (Excel, CSV, JSON, reports) use consistent data

---

**Analysis completed by:** Claude Code
**Next Step:** Implement Option A (explicit save functionality)
