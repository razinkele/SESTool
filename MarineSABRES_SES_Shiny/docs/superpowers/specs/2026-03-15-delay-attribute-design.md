# Delay (Temporal Lag) Attribute — Design Spec

**Date:** 2026-03-15
**Status:** Approved
**Scope:** Data pipeline only (no analysis module changes)

## Overview

Add temporal delay as a first-class connection attribute alongside polarity, strength, and confidence. Connections in SES models often have time lags between cause and effect (e.g., fishing pressure takes years to affect fish stocks). This feature makes that temporal dimension explicit, editable, and visible.

## Field Naming Migration

The existing codebase uses `lag` as the field name for temporal delay (in `utils.R`, `visnetwork_helpers.R`, `connection_generator.R`, `data_persistence.R`). This spec introduces `delay` (category) and `delay_years` (numeric override) as the new canonical names.

**Migration strategy:** Rename all existing `$lag` references to `$delay` and `$delay_years` atomically. The old numeric `lag` values are converted to categories via `derive_delay_category()`. All consumers of `parse_connection_value()` and connection objects are updated in the same change.

Affected references to rename:
- `functions/utils.R` line 51, 68, 78: `lag` → `delay`/`delay_years`
- `functions/visnetwork_helpers.R` lines 305, 768-791, 821: `lag`/`edge_lag` → `delay`/`delay_years`
- `modules/ai_isa/connection_generator.R` line 537: `lag` → `delay`
- `modules/ai_isa/data_persistence.R` line 307: `lag` → `delay`/`delay_years`
- `functions/ses_dynamics.R` lines 249-278: verify no `lag` field access (currently unused — confirm and leave)

## Data Model

### Categories

4 labels + unset default:

| Internal Value | Label | Approximate Range | CLD Dash Pattern |
|---------------|-------|-------------------|-----------------|
| `NA` | *(Not specified)* | Unknown | Solid (default) |
| `"immediate"` | Immediate | < 1 month | Solid |
| `"short-term"` | Short-term | 1-6 months | Long dash `c(15, 10)` |
| `"medium-term"` | Medium-term | 6 months - 3 years | Short dash `c(8, 8)` |
| `"long-term"` | Long-term | 3+ years | Dotted `c(3, 5)` |

### Numeric Override

Optional `delay_years` field (float, in years). When set, takes precedence over category label for tooltip display. Category auto-derived from numeric value:

```r
derive_delay_category <- function(years) {
  if (is.na(years)) return(NA_character_)
  if (years <= 1/12) return("immediate")      # <= 1 month (inclusive boundary)
  if (years < 0.5) return("short-term")       # 1-6 months
  if (years < 3) return("medium-term")        # 6 months - 3 years
  return("long-term")                          # 3+ years
}
```

This function is defined in `constants.R` alongside the delay constants.

### Storage Format

Adjacency matrix cell format extends from `+strength:confidence` to include delay:

```
+strength:confidence                           # No delay (backward compatible)
+strength:confidence:delay_category            # Category only: +strong:4:short-term
+strength:confidence:delay_category:years      # With override: +strong:4:short-term:0.5
```

Backward compatible: existing matrices without delay fields parse as `delay = NA`. Old numeric lag format (e.g., `+strong:4:2.5`) auto-converts via `derive_delay_category()`.

### Connection Object

```r
list(
  from_type = "Activities",
  from_index = 1,
  from_name = "Fishing",
  to_type = "Pressures",
  to_index = 2,
  to_name = "Stock Decline",
  polarity = "+",
  strength = "strong",
  confidence = 4,
  delay = "medium-term",       # Category label or NA (replaces old `lag`)
  delay_years = 2.5,           # Numeric override or NA (replaces old numeric `lag`)
  rationale = "..."
)
```

## Old Project Migration

When loading projects saved before this change:
- Connection objects with `$lag` (numeric): convert to `delay = derive_delay_category(lag)` and `delay_years = lag`
- Connection objects with `$lag` (character like "short-term"): convert to `delay = lag`, `delay_years = NA`
- Connection objects without `$lag`: `delay = NA`, `delay_years = NA`
- Adjacency matrix cells with old numeric 3rd field (e.g., `+strong:4:2.5`): parser auto-detects numeric vs category string

Migration happens at parse time in `parse_connection_value()` and at connection read time in `data_persistence.R`. No batch migration script needed — old formats are read transparently.

## UI: Connection Review Card

### Delay Toggle

- `shinyWidgets::materialSwitch` at top of the connection review panel, near batch controls
- Label: clock icon + i18n "Show temporal delay"
- **Off by default** for all experience levels (beginner, intermediate, expert)
- Controls visibility of delay inputs on cards only — does NOT affect CLD visualization or stored data
- State stored in `session$userData$show_delay` (session UI preference, not project data)
- Resets on page refresh (intentional — this is a view toggle, not project state)
- When toggled off, delay values are **preserved**, not cleared

### Delay Input (per card)

Appears below the confidence slider when toggle is on. Single row layout:

```
[clock icon] Delay:  [Dropdown: (Not set) ▾]  or  [____] years
```

- **Dropdown:** `selectInput` with i18n choices:
  - `""` = "(Not set)" (default)
  - `"immediate"` = "Immediate (< 1 month)"
  - `"short-term"` = "Short-term (1-6 months)"
  - `"medium-term"` = "Medium-term (6mo - 3y)"
  - `"long-term"` = "Long-term (3+ years)"
- **Numeric input:** `numericInput`, placeholder "years", min=0, step=0.1, width ~60px
- When user selects a category, numeric field shows midpoint as placeholder (not value)
- When user types a number, dropdown auto-updates to matching category via `derive_delay_category()`
- Amber color (#f0c040) to distinguish from blue strength/confidence
- Separated from strength/confidence by a dashed border-top

### Amended Data Tracking

```r
rv$amended_data[[as.character(local_idx)]] <- list(
  strength = strength_label,
  confidence = conf_value,
  polarity = polarity,
  delay = delay_category,      # "short-term" or NA
  delay_years = delay_years    # 0.5 or NA
)
```

### on_amend Callback

The `on_amend()` callback signature does NOT change. Delay values flow through `rv$amended_data` which is read directly by the persistence layer. The callback is used only for immediate UI feedback (toast notifications) and does not need delay parameters.

## CLD Visualization

### Edge Dash Pattern

Always reflects stored delay data, regardless of review UI toggle state.

```r
# In visnetwork_helpers.R, when building edge dataframe:
delay_to_dashes <- function(delay_category) {
  if (is.null(delay_category) || is.na(delay_category)) return(FALSE)
  DELAY_DASH_PATTERNS[[delay_category]] %||% FALSE
}
```

### Ghost Edge Conflict Resolution

Ghost/preview edges (line 1206 of `visnetwork_helpers.R`) currently use `dashes = TRUE`. To avoid visual conflict with delay dashes, ghost edges will use a **fixed long-dash pattern `c(10, 10)`** plus their existing lower opacity and distinct color. This keeps ghost edges visually distinct from delay-dashed confirmed edges.

### Edge Dashes as List Column

The `dashes` column in the edges dataframe must be a list column to hold vectors of different lengths alongside scalar `FALSE`. Construction:

```r
# When building each edge row:
edge_row$dashes <- I(list(delay_to_dashes(connection$delay)))

# Or when assembling the full dataframe:
edges$dashes <- lapply(edges$delay, delay_to_dashes)
```

### Edge Tooltip

Existing tooltip format adds delay line when set:

```html
<b>Fishing → Stock Decline</b>
Polarity: + (Reinforcing)
Strength: strong
Confidence: High (4/5)
Temporal delay: Medium-term (~2.5 years)   <!-- NEW -->
```

When numeric override exists, show both: "Medium-term (~2.5 years)".
When only category: "Short-term (1-6 months)".
When NA: line omitted entirely.

### Edge Dataframe

```r
edges$delay <- character()       # Category: "short-term", NA
edges$delay_years <- numeric()   # Override: 0.5, NA
edges$dashes <- list()           # visNetwork dashes property (list column)
```

## Data Persistence

### Serialization (data_persistence.R)

```r
# Read delay from connection object (with backward compat for old `lag` field)
delay_cat <- conn$delay %||% NA_character_
delay_yrs <- conn$delay_years %||% NA_real_

# Backward compat: if old `lag` field exists but new fields don't
if (is.na(delay_cat) && !is.null(conn$lag)) {
  if (is.numeric(conn$lag)) {
    delay_cat <- derive_delay_category(conn$lag)
    delay_yrs <- conn$lag
  } else if (is.character(conn$lag)) {
    delay_cat <- conn$lag
  }
}

confidence <- conn$confidence %||% CONFIDENCE_DEFAULT

value <- if (!is.na(delay_cat)) {
  if (!is.na(delay_yrs)) {
    paste0(conn$polarity, conn$strength, ":", confidence, ":", delay_cat, ":", delay_yrs)
  } else {
    paste0(conn$polarity, conn$strength, ":", confidence, ":", delay_cat)
  }
} else {
  paste0(conn$polarity, conn$strength, ":", confidence)
}
```

### Parsing (utils.R parse_connection_value)

Extend to handle 3rd and 4th colon-separated fields:

```r
# parts[1] = "+strong", parts[2] = "4", parts[3] = "short-term", parts[4] = "0.5"
delay <- NA_character_
delay_years <- NA_real_

if (length(parts) >= 3) {
  # 3rd field: delay category (text) or old numeric lag format
  if (parts[3] %in% DELAY_CATEGORIES) {
    delay <- parts[3]
  } else {
    # Backward compatibility: old numeric lag format
    old_lag <- suppressWarnings(as.numeric(parts[3]))
    if (!is.na(old_lag) && old_lag >= 0) {
      delay <- derive_delay_category(old_lag)
      delay_years <- old_lag
    }
  }
}

if (length(parts) >= 4) {
  yrs <- suppressWarnings(as.numeric(parts[4]))
  if (!is.na(yrs) && yrs >= 0) delay_years <- yrs
}

# Return includes: delay = delay, delay_years = delay_years
# (replaces old `lag` field)
```

## Connection Generator (AI Assistant)

### KB Mapping (connection_generator.R)

Replace current numeric temporal_lag mapping with category mapping:

```r
delay_category <- NA_character_

if (!is.null(kb_match$temporal_lag)) {
  delay_category <- switch(tolower(kb_match$temporal_lag),
    "immediate" = "immediate",
    "short-term" = "short-term",
    "medium-term" = "medium-term",
    "long-term" = "long-term",
    NA_character_
  )
}

# Store in connection:
delay = delay_category,
delay_years = NA_real_   # No numeric override from KB
```

## Excel Import/Export

### Export (isa_export_helpers.R)

Delay data flows through the adjacency matrix cell format (e.g., `+strong:4:short-term:0.5`). This is the primary storage — no separate connections sheet needed.

Additionally, if a "Connections Summary" sheet is generated (as in Kumu export), add columns:

| From | To | Polarity | Strength | Confidence | Delay | Delay (years) |
|------|-----|----------|----------|------------|-------|---------------|
| Fishing | Stock Decline | + | strong | 4 | medium-term | 2.5 |

- "Delay" column: category label or empty
- "Delay (years)" column: numeric override or empty
- Values parsed from adjacency matrix cell values via `parse_connection_value()`

### Import (excel_import_helpers.R)

When building adjacency matrix cells from imported connections data:

```r
# Read Delay column if present
delay <- NA_character_
if ("Delay" %in% names(connections)) {
  delay_val <- tolower(trimws(as.character(connections$Delay[j])))
  if (!is.na(delay_val) && delay_val %in% DELAY_CATEGORIES) {
    delay <- delay_val
  }
}

delay_years <- NA_real_
if ("Delay (years)" %in% names(connections)) {
  yr_val <- suppressWarnings(as.numeric(connections[["Delay (years)"]][j]))
  if (!is.na(yr_val) && yr_val >= 0) {
    delay_years <- yr_val
  }
}

# Include in cell value format:
cell_value <- if (!is.na(delay)) {
  if (!is.na(delay_years)) {
    paste0(polarity_sign, strength, ":", confidence, ":", delay, ":", delay_years)
  } else {
    paste0(polarity_sign, strength, ":", confidence, ":", delay)
  }
} else {
  paste0(polarity_sign, strength, ":", confidence)
}
```

Backward compatible: missing columns = NA (no delay stored).

## Constants (constants.R)

```r
# Delay categories for temporal lag
DELAY_CATEGORIES <- c("immediate", "short-term", "medium-term", "long-term")

DELAY_LABELS <- c(
  "immediate" = "Immediate",
  "short-term" = "Short-term",
  "medium-term" = "Medium-term",
  "long-term" = "Long-term"
)

DELAY_RANGES <- c(
  "immediate" = "< 1 month",
  "short-term" = "1-6 months",
  "medium-term" = "6 months - 3 years",
  "long-term" = "3+ years"
)

DELAY_DASH_PATTERNS <- list(
  "immediate" = FALSE,
  "short-term" = c(15, 10),
  "medium-term" = c(8, 8),
  "long-term" = c(3, 5)
)

# Helper to derive category from numeric years
derive_delay_category <- function(years) {
  if (is.na(years)) return(NA_character_)
  if (years <= 1/12) return("immediate")
  if (years < 0.5) return("short-term")
  if (years < 3) return("medium-term")
  return("long-term")
}
```

## Internationalization

### New translation keys (all 9 languages)

Keys follow the existing namespaced format used throughout the app (e.g., `i18n$t("common.labels.delay")`). Added to the modular JSON translation files:

```
common.labels.delay = "Delay"
common.labels.delay_years = "years"
common.labels.show_temporal_delay = "Show temporal delay"
common.labels.temporal_delay = "Temporal delay"
common.labels.not_specified = "Not specified"
common.labels.delay_immediate = "Immediate (< 1 month)"
common.labels.delay_short_term = "Short-term (1-6 months)"
common.labels.delay_medium_term = "Medium-term (6mo - 3y)"
common.labels.delay_long_term = "Long-term (3+ years)"
common.labels.delay_tooltip = "How long before this connection's effect is observed"
```

Files to update:
- `translations/common/labels.json` — delay category labels, ranges, tooltip
- `translations/modules/connection_review.json` — toggle label

## Testing

### Existing tests to update

- `tests/testthat/test-global-utils.R` — extend `parse_connection_value()` tests for delay parsing, backward compat with old numeric lag format
- `tests/testthat/test-confidence.R` — if it tests connection attribute round-trips, add delay coverage

### New test cases needed

- `parse_connection_value()` with: no delay, category-only, category+years, old numeric format, invalid values
- `derive_delay_category()` boundary tests: 0, 1/12, 0.5, 3, 10
- `delay_to_dashes()` for each category + NA
- Round-trip: serialize connection → parse cell value → verify delay fields match
- UI: toggle visibility (if testServer tests exist for connection_review)

## Files Changed (14 total)

| # | File | Change Type |
|---|------|-------------|
| 1 | `constants.R` | Add DELAY_* constants + `derive_delay_category()` |
| 2 | `functions/utils.R` | Extend `parse_connection_value()`, rename `lag` → `delay`/`delay_years` |
| 3 | `modules/connection_review_tabbed.R` | Add toggle + dropdown + numeric input per card |
| 4 | `modules/ai_isa/data_persistence.R` | Serialize delay to matrix cells, backward compat for `lag` |
| 5 | `modules/ai_isa/connection_generator.R` | Map KB temporal_lag to categories, rename `lag` → `delay` |
| 6 | `functions/visnetwork_helpers.R` | Edge dashes + tooltip + ghost edge fix, rename `lag` → `delay` |
| 7 | `functions/isa_export_helpers.R` | Add Delay columns to Kumu/summary export |
| 8 | `functions/excel_import_helpers.R` | Read Delay columns, include in cell format |
| 9 | `functions/ses_dynamics.R` | Verify no `lag` field access (rename if needed) |
| 10 | `translations/common/labels.json` | Delay label translations (9 languages) |
| 11 | `translations/modules/connection_review.json` | Toggle label translation (9 languages) |
| 12 | `tests/testthat/test-global-utils.R` | Extend parser tests for delay |
| 13 | `tests/testthat/test-confidence.R` | Add delay round-trip tests |
| 14 | `server/project_io.R` | Verify old project loading handles `lag` → `delay` migration |

## Not In Scope

- Analysis modules (loops, metrics, leverage, simulation) — future iteration
- Scenario builder delay modeling — future iteration
- Template data updates — templates work as-is, delay defaults to NA
- ISA data entry module delay input — only connection review for now
- `functions/network_analysis.R` — deals with igraph topology, not edge metadata; no changes needed
