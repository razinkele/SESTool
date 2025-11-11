# Bug Analysis: Intervention Analysis Inconsistency

**Date:** November 5, 2025
**Sprint:** Phase 1, Sprint 2 (Days 3-5)
**Priority:** HIGH
**Impact:** Users can't trust intervention predictions

---

## User-Reported Issue

"Intervention analysis inconsistent"

---

## Root Cause Analysis

The intervention analysis in the Scenario Builder module has multiple issues causing inconsistent predictions:

1. **Incomplete impact prediction algorithm** - only considers positive impacts
2. **Missing negative impact handling** - removed nodes/links have no effect
3. **Ignored link polarity** - positive/negative relationships not factored in
4. **Stale results caching** - old analysis persists after modifications
5. **Data structure mismatches** - column inconsistencies cause corruption
6. **Missing loop detection** - can't identify system-level effects

---

## File Location

**Primary File:** `modules/scenario_builder_module.R`

---

## Critical Bugs Identified

### Bug #1: Incomplete Impact Prediction Logic (Lines 1172-1211)

**Location:** `predict_impacts()` function

**Problem:** The impact prediction algorithm is overly simplistic and doesn't account for several intervention scenarios.

```r
# Lines 1187-1196
impact_magnitude <- 0
impact_direction <- "neutral"

if (is_added) {
  impact_magnitude <- 3
  impact_direction <- "positive"
} else if (connected_links_added) {
  impact_magnitude <- 2
  impact_direction <- "positive"
}
```

**Issues:**
1. **Missing negative impacts**: The function ONLY assigns positive impacts - never negative ones
2. **No handling of removed nodes**: Variable `is_removed` is calculated (line 1180) but never used
3. **No handling of removed links**: Removed links don't affect impact calculations
4. **No polarity consideration**: Link polarity (+ or -) is completely ignored in impact predictions
5. **No indirect/cascading effects**: Only direct modifications are considered

**Result:** All interventions appear positive, causing inconsistent analysis results.

---

### Bug #2: Inconsistent Data Structure (Lines 1107-1116)

**Location:** `apply_scenario_modifications()` - Adding new nodes

**Problem:** Column mismatch between baseline CLD and scenario-added nodes.

```r
# Lines 1107-1116
new_nodes <- do.call(rbind, lapply(modifications$nodes_added, function(n) {
  data.frame(
    id = n$id,
    label = n$label,
    dapsi = n$dapsi,
    description = ifelse(is.null(n$description), "", n$description),
    stringsAsFactors = FALSE
  )
}))
```

**Problem:**
- Baseline CLD nodes may have additional columns (e.g., `group`, `color`, `size`, `x`, `y`, `confidence`, etc.)
- New nodes only have 4 columns
- `rbind()` will fail or create NA values if column structures don't match

**Result:** Network structure becomes corrupted after modifications.

---

### Bug #3: Edge Polarity Not Propagated (Lines 1125-1140)

**Location:** `apply_scenario_modifications()` - Adding new links

**Problem:** While polarity is stored in the edge data frame, it's never used in impact calculations.

```r
# Lines 1130-1138
data.frame(
  id = l$id,
  from = l$from,
  to = l$to,
  from_label = from_label,
  to_label = to_label,
  polarity = l$polarity,  # Stored but never used!
  stringsAsFactors = FALSE
)
```

**Result:** Impact direction doesn't account for whether a link amplifies (+) or dampens (-) effects.

---

### Bug #4: State Management Issues

**Issue #1: No validation on modifications** (Lines 280-295)
- Scenarios can have conflicting modifications (add and remove same node)
- No check for circular dependencies
- No validation of node/link existence

**Issue #2: Results not invalidated when modifications change** (Lines 492, 516, 581, 603)
- When user modifies a scenario after running analysis, `results` object is not set to NULL
- Old analysis results persist even though modifications have changed
- UI shows stale impact predictions

**Issue #3: Inconsistent scenario index lookup** (Lines 491, 510, 578, 597, 810)
```r
idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))
```
- If scenario is deleted while another is active, index can become invalid
- No bounds checking on `idx`

---

### Bug #5: Missing Loop Detection Implementation (Lines 1164-1169)

**Location:** `detect_feedback_loops()` function

**Problem:** Placeholder function always returns empty list.

```r
detect_feedback_loops <- function(network) {
  # This is a placeholder - would need full loop detection algorithm
  # For now, return empty list
  list()
}
```

**Result:**
- Loop count in network stats is always 0 (line 1160)
- Impact analysis can't identify leverage points in feedback loops
- Inconsistent with loop detection in other parts of the app

---

## State Management Flow Issue

**Current (Broken) Workflow:**
1. User creates scenario → `results = NULL` ✓
2. User adds modifications → `results` still NULL ✓
3. User runs analysis → `results` populated ✓
4. **User adds MORE modifications → `results` NOT cleared ✗**
5. User views Impact Analysis tab → Shows OLD results ✗

---

## Fix Implementation Plan

### Fix #1: Complete predict_impacts() Function (Lines 1172-1211)

**Replace entire function with:**

```r
predict_impacts <- function(baseline_cld, modifications, node_id) {
  # Check if node was added
  is_added <- node_id %in% sapply(modifications$nodes_added, function(n) n$id)

  # Check if node was removed
  is_removed <- node_id %in% modifications$nodes_removed

  # If node was removed, it has negative impact
  if (is_removed) {
    return(list(
      direction = "negative",
      magnitude = 3,
      reason = "Node marked for removal"
    ))
  }

  # Check for connected links
  added_links <- modifications$links_added
  removed_links <- modifications$links_removed

  # Links where this node is involved
  connected_links_added <- sapply(added_links, function(l) {
    l$from == node_id || l$to == node_id
  })

  connected_links_removed <- sapply(removed_links, function(l) {
    l$from == node_id || l$to == node_id
  })

  # Calculate impact
  impact_magnitude <- 0
  impact_direction <- "neutral"
  reason <- ""

  if (is_added) {
    # New node added - positive impact
    impact_magnitude <- 3
    impact_direction <- "positive"
    reason <- "New node added to network"

  } else if (any(connected_links_added)) {
    # Links added involving this node
    # Consider polarity of links
    link_polarities <- sapply(added_links[connected_links_added], function(l) l$polarity)

    positive_links <- sum(link_polarities == "+")
    negative_links <- sum(link_polarities == "-")

    if (positive_links > negative_links) {
      impact_magnitude <- 2
      impact_direction <- "positive"
      reason <- sprintf("%d positive link(s) added", positive_links)
    } else if (negative_links > positive_links) {
      impact_magnitude <- 2
      impact_direction <- "negative"
      reason <- sprintf("%d negative link(s) added", negative_links)
    } else {
      impact_magnitude <- 1
      impact_direction <- "mixed"
      reason <- sprintf("%d links added (mixed polarity)", length(link_polarities))
    }

  } else if (any(connected_links_removed)) {
    # Links removed involving this node - negative impact
    impact_magnitude <- 2
    impact_direction <- "negative"
    reason <- sprintf("%d link(s) removed", sum(connected_links_removed))

  } else {
    # No direct modifications to this node
    # Check for indirect effects (simplified - could be enhanced)
    impact_magnitude <- 0
    impact_direction <- "neutral"
    reason <- "No direct modifications"
  }

  list(
    direction = impact_direction,
    magnitude = impact_magnitude,
    reason = reason
  )
}
```

---

### Fix #2: Invalidate Results on Modification

**Add after lines 494, 516, 581, 603:**

```r
# Invalidate cached analysis results since modifications changed
scenario_list[[idx]]$results <- NULL
```

**Example (after line 494):**

```r
# Line 489-495
observeEvent(input$add_node, {
  req(input$new_node_id, input$new_node_label, input$new_node_dapsi)

  active_scenario <- get_active_scenario()
  req(active_scenario)

  scenario_list <- scenarios()
  idx <- which(sapply(scenario_list, function(s) s$id == active_scenario$id))

  # Add new node
  scenario_list[[idx]]$modifications$nodes_added <- c(
    scenario_list[[idx]]$modifications$nodes_added,
    list(list(
      id = input$new_node_id,
      label = input$new_node_label,
      dapsi = input$new_node_dapsi,
      description = input$new_node_description
    ))
  )
  scenario_list[[idx]]$modified <- Sys.time()

  # INVALIDATE RESULTS
  scenario_list[[idx]]$results <- NULL

  scenarios(scenario_list)
  save_scenarios_to_project()

  showNotification(i18n$t("scenario_node_added"), type = "message")
})
```

---

### Fix #3: Standardize Data Structures (Lines 1107-1116)

**Replace with:**

```r
# Get baseline column structure
baseline_cols <- names(baseline_cld$nodes)

new_nodes <- do.call(rbind, lapply(modifications$nodes_added, function(n) {
  # Create base node with required columns
  new_node <- data.frame(
    id = n$id,
    label = n$label,
    dapsi = n$dapsi,
    description = ifelse(is.null(n$description), "", n$description),
    stringsAsFactors = FALSE
  )

  # Add any missing columns from baseline with default values
  for (col in baseline_cols) {
    if (!(col %in% names(new_node))) {
      if (col == "group") {
        new_node[[col]] <- n$dapsi  # Use DAPSI as group
      } else if (col == "color") {
        new_node[[col]] <- "#999999"  # Default gray
      } else if (col == "size") {
        new_node[[col]] <- 20  # Default size
      } else if (col == "confidence") {
        new_node[[col]] <- 3  # Default confidence
      } else {
        new_node[[col]] <- NA  # Default NA for other columns
      }
    }
  }

  new_node
}))
```

---

### Fix #4: Implement Loop Detection (Lines 1164-1169)

**Import from analysis_tools_module.R or implement simplified version:**

```r
detect_feedback_loops <- function(network) {
  # Convert to igraph
  if (nrow(network$edges) == 0) {
    return(list())
  }

  g <- igraph::graph_from_data_frame(
    d = network$edges[, c("from", "to")],
    directed = TRUE,
    vertices = network$nodes$id
  )

  # Find all simple cycles
  cycles <- tryCatch({
    # Get feedback_arcs (creates cycle basis)
    feedback_arcs <- igraph::feedback_arc_set(g, algo = "approx_eades")
    if (length(feedback_arcs) > 0) {
      # Return basic cycle info
      list(
        count = length(feedback_arcs),
        edges = feedback_arcs
      )
    } else {
      list(count = 0, edges = list())
    }
  }, error = function(e) {
    list(count = 0, edges = list())
  })

  cycles
}
```

---

### Fix #5: Add Modification Validation

**Add validation function:**

```r
validate_modifications <- function(baseline_cld, modifications) {
  errors <- character()

  # Check for conflicts: can't add and remove same node
  if (length(modifications$nodes_added) > 0 && length(modifications$nodes_removed) > 0) {
    added_ids <- sapply(modifications$nodes_added, function(n) n$id)
    conflicts <- intersect(added_ids, modifications$nodes_removed)
    if (length(conflicts) > 0) {
      errors <- c(errors, sprintf("Conflicting modifications for nodes: %s", paste(conflicts, collapse = ", ")))
    }
  }

  # Check that removed nodes exist in baseline
  for (node_id in modifications$nodes_removed) {
    if (!(node_id %in% baseline_cld$nodes$id)) {
      errors <- c(errors, sprintf("Cannot remove non-existent node: %s", node_id))
    }
  }

  # Check that added links reference valid nodes
  for (link in modifications$links_added) {
    # Check in baseline + added nodes
    all_node_ids <- c(
      baseline_cld$nodes$id,
      sapply(modifications$nodes_added, function(n) n$id)
    )
    # Exclude removed nodes
    all_node_ids <- setdiff(all_node_ids, modifications$nodes_removed)

    if (!(link$from %in% all_node_ids)) {
      errors <- c(errors, sprintf("Link references non-existent 'from' node: %s", link$from))
    }
    if (!(link$to %in% all_node_ids)) {
      errors <- c(errors, sprintf("Link references non-existent 'to' node: %s", link$to))
    }
  }

  list(
    valid = length(errors) == 0,
    errors = errors
  )
}
```

**Call before running analysis (line 773):**

```r
observeEvent(input$run_impact_analysis, {
  active_scenario <- get_active_scenario()
  req(active_scenario)

  # Validate modifications first
  validation <- validate_modifications(
    baseline_cld = list(
      nodes = project_data_reactive()$data$cld$nodes,
      edges = project_data_reactive()$data$cld$edges
    ),
    modifications = active_scenario$modifications
  )

  if (!validation$valid) {
    showNotification(
      paste("Validation errors:", paste(validation$errors, collapse = "; ")),
      type = "error",
      duration = 5
    )
    return()
  }

  # Continue with analysis...
})
```

---

## Translation Needs

New strings to add:
- "Validation errors: %s"
- "Conflicting modifications for nodes: %s"
- "Cannot remove non-existent node: %s"
- "Link references non-existent 'from' node: %s"
- "Link references non-existent 'to' node: %s"
- "Node marked for removal"
- "New node added to network"
- "%d positive link(s) added"
- "%d negative link(s) added"
- "%d links added (mixed polarity)"
- "%d link(s) removed"
- "No direct modifications"

---

## Testing Protocol

### Test Scenario 1: Positive Impact Prediction
1. Create scenario
2. Add new response measure node
3. Run impact analysis
4. **Expected:** Node shows positive impact, magnitude 3

### Test Scenario 2: Negative Impact from Removal
1. Create scenario
2. Mark existing node for removal
3. Run impact analysis
4. **Expected:** Node shows negative impact, magnitude 3

### Test Scenario 3: Link Polarity Effects
1. Create scenario
2. Add positive link (+) from Driver to Pressure
3. Run impact analysis
4. **Expected:** Pressure node shows positive impact with reason "1 positive link(s) added"

### Test Scenario 4: Stale Results Fix
1. Create scenario and run analysis
2. Add new modification
3. View Impact Analysis tab
4. **Expected:** Should show "Run analysis to see results" (results invalidated)

### Test Scenario 5: Data Structure Consistency
1. Create scenario with nodes that have custom columns (color, size, confidence)
2. Add new node via scenario
3. Apply scenario modifications
4. **Expected:** No errors, new node has all required columns with defaults

### Test Scenario 6: Validation
1. Create scenario
2. Try to add link referencing non-existent node
3. Run analysis
4. **Expected:** Error message: "Link references non-existent 'from' node: X"

---

## Files to Modify

1. `modules/scenario_builder_module.R` - All 5 fixes
2. `translations/translation.json` - New translation strings
3. `PHASE1_IMPLEMENTATION_GUIDE.md` - Update Sprint 2 progress

---

## Expected Outcomes

After fixes:
- ✅ Impact predictions account for both positive and negative effects
- ✅ Link polarity considered in impact direction
- ✅ Removed nodes/links affect predictions correctly
- ✅ Results invalidated when modifications change (no stale data)
- ✅ Data structure consistency maintained
- ✅ Loop detection provides accurate network statistics
- ✅ Validation prevents invalid modifications

---

**Analysis completed by:** Claude Code
**Next Step:** Implement all 5 fixes
