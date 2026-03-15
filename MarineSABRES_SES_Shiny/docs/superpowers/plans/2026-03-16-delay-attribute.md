# Delay Attribute Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add temporal delay as a first-class connection attribute (UI, persistence, visualization, import/export, i18n) following the approved spec at `docs/superpowers/specs/2026-03-15-delay-attribute-design.md`.

**Architecture:** Delay extends the existing polarity/strength/confidence pipeline. Constants and helpers go in `constants.R` and `utils.R`. The adjacency matrix cell format extends from `+strength:confidence` to `+strength:confidence:delay_category:delay_years`. The connection review UI gets a toggle + dropdown + numeric input. CLD edges use dash patterns to visualize delay. All existing `lag` references are renamed to `delay`/`delay_years`.

**Tech Stack:** R/Shiny, bs4Dash, shiny.i18n, visNetwork, shinyWidgets

**Spec:** `docs/superpowers/specs/2026-03-15-delay-attribute-design.md`

---

## Chunk 1: Foundation (Constants, Parser, Tests)

### Task 1: Add delay constants and helper to constants.R

**Files:**
- Modify: `constants.R` (after line 281, below `CONFIDENCE_OPACITY`)

- [ ] **Step 1: Add DELAY_* constants and derive_delay_category()**

Add after the `DEFAULT_GROUP_SHAPE` line (~line 285):

```r
# ============================================================================
# DELAY (TEMPORAL LAG) CONSTANTS
# ============================================================================

# Delay categories for temporal lag between cause and effect
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

#' Derive delay category from numeric years
#'
#' @param years Numeric value in years (NA returns NA)
#' @return Character delay category or NA_character_
derive_delay_category <- function(years) {
  if (is.na(years)) return(NA_character_)
  if (years <= 1/12) return("immediate")
  if (years < 0.5) return("short-term")
  if (years < 3) return("medium-term")
  return("long-term")
}

#' Convert delay category to visNetwork dash pattern
#'
#' @param delay_category Character delay category or NA
#' @return FALSE (solid) or numeric vector for dashes
delay_to_dashes <- function(delay_category) {
  if (is.null(delay_category) || is.na(delay_category)) return(FALSE)
  DELAY_DASH_PATTERNS[[delay_category]] %||% FALSE
}
```

- [ ] **Step 2: Verify constants.R parses without errors**

Run: `Rscript -e "source('constants.R'); cat('DELAY_CATEGORIES:', DELAY_CATEGORIES, '\n'); cat('derive_delay_category(0.25):', derive_delay_category(0.25), '\n')"`

Expected: `DELAY_CATEGORIES: immediate short-term medium-term long-term` and `derive_delay_category(0.25): short-term`

- [ ] **Step 3: Commit**

```bash
git add constants.R
git commit -m "feat(delay): add DELAY_* constants, derive_delay_category(), delay_to_dashes()"
```

---

### Task 2: Write failing tests for delay parsing

**Files:**
- Modify: `tests/testthat/test-global-utils.R` (after line ~84)
- Modify: `tests/testthat/test-confidence.R` (after existing parse tests)

- [ ] **Step 1: Add delay parsing tests to test-global-utils.R**

Add after the existing `parse_connection_value` test block (after line ~84):

```r
test_that("parse_connection_value parses delay categories correctly", {
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")
  skip_if_not(exists("DELAY_CATEGORIES"), "DELAY_CATEGORIES not available")

  # No delay (backward compat)
  result1 <- parse_connection_value("+strong:4")
  expect_equal(result1$polarity, "+")
  expect_equal(result1$strength, "strong")
  expect_equal(result1$confidence, 4L)
  expect_true(is.na(result1$delay))
  expect_true(is.na(result1$delay_years))

  # Category only
  result2 <- parse_connection_value("+medium:3:short-term")
  expect_equal(result2$delay, "short-term")
  expect_true(is.na(result2$delay_years))

  # Category + numeric override
  result3 <- parse_connection_value("-strong:4:medium-term:2.5")
  expect_equal(result3$delay, "medium-term")
  expect_equal(result3$delay_years, 2.5)

  # All four categories
  for (cat in DELAY_CATEGORIES) {
    result <- parse_connection_value(paste0("+medium:3:", cat))
    expect_equal(result$delay, cat, info = paste("Category:", cat))
  }

  # Old numeric lag format (backward compat)
  result4 <- parse_connection_value("+strong:4:2.5")
  expect_equal(result4$delay, "medium-term")  # 2.5 years -> medium-term
  expect_equal(result4$delay_years, 2.5)

  # Old numeric lag = 0 (immediate)
  result5 <- parse_connection_value("+medium:3:0")
  expect_equal(result5$delay, "immediate")
  expect_equal(result5$delay_years, 0)

  # Invalid 3rd field
  result6 <- parse_connection_value("+medium:3:invalid")
  expect_true(is.na(result6$delay))

  # Negative delay_years
  result7 <- parse_connection_value("+medium:3:short-term:-1")
  expect_equal(result7$delay, "short-term")
  expect_true(is.na(result7$delay_years))
})

test_that("delay round-trip: serialize then parse preserves values", {
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")
  skip_if_not(exists("DELAY_CATEGORIES"), "DELAY_CATEGORIES not available")

  # Round-trip with category only
  cell1 <- "+strong:4:short-term"
  parsed1 <- parse_connection_value(cell1)
  rebuilt1 <- paste0(parsed1$polarity, parsed1$strength, ":", parsed1$confidence, ":", parsed1$delay)
  expect_equal(rebuilt1, cell1)

  # Round-trip with category + years
  cell2 <- "+medium:3:long-term:5.5"
  parsed2 <- parse_connection_value(cell2)
  rebuilt2 <- paste0(parsed2$polarity, parsed2$strength, ":", parsed2$confidence, ":", parsed2$delay, ":", parsed2$delay_years)
  expect_equal(rebuilt2, cell2)

  # Round-trip with no delay
  cell3 <- "-weak:2"
  parsed3 <- parse_connection_value(cell3)
  rebuilt3 <- paste0(parsed3$polarity, parsed3$strength, ":", parsed3$confidence)
  expect_equal(rebuilt3, cell3)
  expect_true(is.na(parsed3$delay))
})

test_that("derive_delay_category maps numeric years to categories", {
  skip_if_not(exists("derive_delay_category", mode = "function"),
              "derive_delay_category not available")

  expect_true(is.na(derive_delay_category(NA)))
  expect_equal(derive_delay_category(0), "immediate")
  expect_equal(derive_delay_category(1/12), "immediate")  # exactly 1 month
  expect_equal(derive_delay_category(0.25), "short-term")  # 3 months
  expect_equal(derive_delay_category(0.49), "short-term")
  expect_equal(derive_delay_category(0.5), "medium-term")  # 6 months
  expect_equal(derive_delay_category(2.9), "medium-term")
  expect_equal(derive_delay_category(3), "long-term")      # 3 years
  expect_equal(derive_delay_category(10), "long-term")
})

test_that("delay_to_dashes returns correct patterns", {
  skip_if_not(exists("delay_to_dashes", mode = "function"),
              "delay_to_dashes not available")

  expect_equal(delay_to_dashes(NA), FALSE)
  expect_equal(delay_to_dashes(NULL), FALSE)
  expect_equal(delay_to_dashes("immediate"), FALSE)
  expect_equal(delay_to_dashes("short-term"), c(15, 10))
  expect_equal(delay_to_dashes("medium-term"), c(8, 8))
  expect_equal(delay_to_dashes("long-term"), c(3, 5))
  expect_equal(delay_to_dashes("unknown-value"), FALSE)
})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-global-utils.R')"`

Expected: FAIL — `parse_connection_value` returns `$lag` not `$delay`, and old format tests expect new behavior.

- [ ] **Step 3: Commit failing tests**

```bash
git add tests/testthat/test-global-utils.R
git commit -m "test(delay): add failing tests for delay parsing, derive_delay_category, delay_to_dashes"
```

---

### Task 3: Update parse_connection_value() and rename lag → delay

**Files:**
- Modify: `functions/utils.R` lines 40-79 (the `parse_connection_value` function)

- [ ] **Step 1: Rewrite parse_connection_value to return delay/delay_years instead of lag**

Replace the function at lines 40-79 with:

```r
#' Parse Connection Value
#'
#' Converts adjacency matrix value to list with polarity, strength, confidence,
#' delay (category), and delay_years (numeric override).
#' Format: "+strong:4" or "+strong:4:short-term" or "+strong:4:short-term:2.5"
#' Old numeric lag format ("+strong:4:2.5") is auto-converted to category.
#'
#' @param value Character string like "+strong:4" or "+strong:4:short-term:2.5"
#' @return List with polarity, strength, confidence, delay, delay_years; or NULL if empty/NA
parse_connection_value <- function(value) {
  if (is.na(value) || value == "") {
    return(NULL)
  }

  delay <- NA_character_
  delay_years <- NA_real_

  # Check if confidence/delay is included (format: "+strong:4" or "+strong:4:short-term:2.5")
  if (grepl(":", value)) {
    parts <- strsplit(value, ":")[[1]]
    polarity_strength <- parts[1]
    confidence <- as.integer(parts[2])

    # Validate confidence is within allowed range
    if (is.na(confidence) || !confidence %in% CONFIDENCE_LEVELS) {
      confidence <- CONFIDENCE_DEFAULT
    }

    # Parse optional delay (3rd colon-separated value)
    if (length(parts) >= 3) {
      if (parts[3] %in% DELAY_CATEGORIES) {
        # New category format: "+strong:4:short-term"
        delay <- parts[3]
      } else {
        # Backward compatibility: old numeric lag format "+strong:4:2.5"
        old_lag <- suppressWarnings(as.numeric(parts[3]))
        if (!is.na(old_lag) && old_lag >= 0) {
          delay <- derive_delay_category(old_lag)
          delay_years <- old_lag
        }
      }
    }

    # Parse optional delay_years (4th colon-separated value)
    if (length(parts) >= 4) {
      yrs <- suppressWarnings(as.numeric(parts[4]))
      if (!is.na(yrs) && yrs >= 0) delay_years <- yrs
    }
  } else {
    # No confidence specified, use default
    polarity_strength <- value
    confidence <- CONFIDENCE_DEFAULT
  }

  polarity <- substr(polarity_strength, 1, 1)
  strength <- substr(polarity_strength, 2, nchar(polarity_strength))

  list(polarity = polarity, strength = strength, confidence = confidence,
       delay = delay, delay_years = delay_years)
}
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-global-utils.R')"`

Expected: All new delay tests PASS. Existing tests may fail if they check for `$lag` field.

- [ ] **Step 3: Update existing tests that reference $lag**

In `tests/testthat/test-confidence.R`, if any test checks `result$lag`, change to check `result$delay` and `result$delay_years` instead. The existing confidence tests should still pass since `$polarity`, `$strength`, and `$confidence` fields are unchanged.

Run: `Rscript -e "testthat::test_file('tests/testthat/test-confidence.R')"`

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add functions/utils.R tests/testthat/test-global-utils.R tests/testthat/test-confidence.R
git commit -m "feat(delay): extend parse_connection_value() with delay/delay_years, migrate from lag"
```

---

## Chunk 2: Backend (Persistence, Generator, Visualization)

### Task 4: Update data_persistence.R serialization

**Files:**
- Modify: `modules/ai_isa/data_persistence.R` lines 299-339

- [ ] **Step 1: Update connection serialization to include delay**

At line 307, replace the lag reading and serialization block. The current code reads `lag <- conn$lag %||% conn$temporal_lag_years %||% NA` and serializes as `paste0(conn$polarity, conn$strength, ":", confidence, ":", lag)`.

Replace with:

```r
# Read delay from connection (with backward compat for old `lag` field)
delay_cat <- conn$delay %||% NA_character_
delay_yrs <- conn$delay_years %||% NA_real_

# Backward compat: convert old `lag` field to new delay fields
if (is.na(delay_cat) && !is.null(conn$lag)) {
  if (is.numeric(conn$lag)) {
    delay_cat <- derive_delay_category(conn$lag)
    delay_yrs <- conn$lag
  } else if (is.character(conn$lag) && conn$lag %in% DELAY_CATEGORIES) {
    delay_cat <- conn$lag
  }
}

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

- [ ] **Step 2: Verify the file parses**

Run: `Rscript -e "tryCatch(parse(file='modules/ai_isa/data_persistence.R'), error=function(e) stop(e)); cat('OK\n')"`

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add modules/ai_isa/data_persistence.R
git commit -m "feat(delay): serialize delay category and years in adjacency matrix cells"
```

---

### Task 5: Update connection_generator.R to use delay categories

**Files:**
- Modify: `modules/ai_isa/connection_generator.R` (~lines 467-541)

- [ ] **Step 1: Replace numeric temporal_lag mapping with category mapping**

Find the block around line 470 where `temporal_lag` is set via `switch(tolower(kb_match$temporal_lag), ...)`. Replace the numeric mapping with:

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
```

Then at line 537 where the connection object is built, replace `lag = temporal_lag` with:

```r
delay = delay_category,
delay_years = NA_real_,
```

Remove any remaining references to the old `temporal_lag` numeric variable (the `switch` that mapped to 0, 0.5, 3, 10).

- [ ] **Step 2: Verify the file parses**

Run: `Rscript -e "tryCatch(parse(file='modules/ai_isa/connection_generator.R'), error=function(e) stop(e)); cat('OK\n')"`

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add modules/ai_isa/connection_generator.R
git commit -m "feat(delay): map KB temporal_lag to delay categories instead of numeric years"
```

---

### Task 6: Update visnetwork_helpers.R (edge dashes, tooltip, rename lag)

**Files:**
- Modify: `functions/visnetwork_helpers.R` (lines 295-310, 760-848, 1206)

- [ ] **Step 1: Update edge dataframe initialization (line 305)**

Change `lag = numeric()` to:

```r
delay = character(),
delay_years = numeric(),
dashes = list(),
```

- [ ] **Step 2: Update edge construction (lines 766-796)**

Replace the `edge_lag` block (lines 768-771) with:

```r
# Extract delay fields from parsed connection
edge_delay <- connection$delay %||% NA_character_
edge_delay_years <- connection$delay_years %||% NA_real_
```

In the `edge <- data.frame(...)` block (~line 773), replace `lag = edge_lag,` with:

```r
delay = edge_delay %||% NA_character_,
delay_years = edge_delay_years %||% NA_real_,
```

After the `data.frame()` call but before `edges <- bind_rows(edges, edge)`, add the dashes list column:

```r
edge$dashes <- I(list(delay_to_dashes(edge_delay)))
```

Update the `create_edge_tooltip` call (~line 780) to pass the new delay fields instead of `edge_lag`.

- [ ] **Step 3: Update create_edge_tooltip function (line 821)**

Replace the function signature and lag handling:

```r
create_edge_tooltip <- function(from_name, to_name, polarity, strength,
                                confidence = CONFIDENCE_DEFAULT,
                                delay = NA_character_, delay_years = NA_real_) {
  polarity_text <- ifelse(polarity == "+", "Reinforcing", "Opposing")
  confidence_text <- CONFIDENCE_LABELS[as.character(confidence)]

  # Delay display
  delay_html <- ""
  if (!is.na(delay)) {
    if (!is.na(delay_years)) {
      # Show both category and numeric
      delay_text <- paste0(DELAY_LABELS[[delay]], " (~", round(delay_years, 1), " years)")
    } else {
      # Show category with range
      delay_text <- paste0(DELAY_LABELS[[delay]], " (", DELAY_RANGES[[delay]], ")")
    }
    delay_html <- sprintf("<br>Temporal delay: %s", delay_text)
  }

  esc <- htmltools::htmlEscape
  sprintf(
    "<div style='padding: 8px;'>
      <b>%s \u2192 %s</b><br>
      Polarity: %s (%s)<br>
      Strength: %s<br>
      Confidence: %s (%d/5)%s
    </div>",
    esc(from_name), esc(to_name), esc(polarity), polarity_text,
    esc(strength), confidence_text, confidence, delay_html
  )
}
```

- [ ] **Step 4: Update ghost edge dash pattern (line 1206)**

Change `dashes = TRUE` to `dashes = I(list(c(10, 10)))` to use a fixed pattern that won't conflict with delay dashes.

- [ ] **Step 5: Verify the file parses**

Run: `Rscript -e "tryCatch(parse(file='functions/visnetwork_helpers.R'), error=function(e) stop(e)); cat('OK\n')"`

Expected: `OK`

- [ ] **Step 6: Commit**

```bash
git add functions/visnetwork_helpers.R
git commit -m "feat(delay): add edge dash patterns, update tooltip, rename lag to delay"
```

---

## Chunk 3: UI (Connection Review Toggle + Inputs)

### Task 7: Add delay toggle and inputs to connection_review_tabbed.R

**Files:**
- Modify: `modules/connection_review_tabbed.R`

This is the largest change. Three insertion points:

- [ ] **Step 1: Add delay toggle to the panel header**

Find the batch stats area in the UI output (around line 456-470 where `div(class = "batch-stats-box"` is rendered). Before the `tabsetPanel`, add:

```r
div(style = "margin-bottom: 10px; padding: 8px 12px; background: #f8f9fa; border-radius: 4px;",
  shinyWidgets::materialSwitch(
    inputId = ns("show_delay_toggle"),
    label = span(icon("clock"), " ", i18n$t("common.labels.show_temporal_delay")),
    value = FALSE,
    status = "warning",
    right = TRUE
  )
),
```

- [ ] **Step 2: Add delay inputs to render_connection_card()**

Find the `render_connection_card` function (~line 990). After the confidence slider block (look for the `conn-slider-container` div with confidence), add a conditional delay block:

```r
# Delay input (visible when toggle is on)
if (isTRUE(rv$show_delay)) {
  # Get current delay value
  amended <- rv$amended_data[[as.character(conn_idx)]]
  current_delay <- if (!is.null(amended$delay) && !is.na(amended$delay)) {
    amended$delay
  } else {
    conn$delay %||% ""
  }
  current_delay_years <- if (!is.null(amended$delay_years) && !is.na(amended$delay_years)) {
    amended$delay_years
  } else {
    conn$delay_years %||% NA_real_
  }

  delay_choices <- c(
    "" = "",
    setNames(DELAY_CATEGORIES,
      sapply(DELAY_CATEGORIES, function(cat) {
        paste0(i18n$t(paste0("common.labels.delay_", gsub("-", "_", cat))),
               " (", DELAY_RANGES[[cat]], ")")
      })
    )
  )

  tags$div(
    style = "border-top: 1px dashed #dee2e6; margin-top: 8px; padding-top: 8px;",
    tags$div(
      class = "conn-slider-container",
      style = "display: flex; align-items: center; gap: 8px;",
      tags$span(
        style = "color: #f0c040; min-width: 70px;",
        icon("clock"), " ", i18n$t("common.labels.delay"), ":"
      ),
      tags$div(
        style = "flex: 1;",
        selectInput(
          ns(paste0("delay_cat_", conn_idx)),
          label = NULL,
          choices = delay_choices,
          selected = current_delay,
          width = "100%"
        )
      ),
      tags$span(style = "color: #999;", i18n$t("common.labels.or") %||% "or"),
      tags$div(
        style = "width: 70px;",
        numericInput(
          ns(paste0("delay_years_", conn_idx)),
          label = NULL,
          value = if (!is.na(current_delay_years)) current_delay_years else NA,
          min = 0,
          step = 0.1,
          width = "100%"
        )
      ),
      tags$span(style = "color: #999; font-size: 0.85em;", i18n$t("common.labels.delay_years"))
    )
  )
}
```

- [ ] **Step 3: Track delay toggle state**

In the `moduleServer` section where `rv` is defined (~line 355), add:

```r
rv$show_delay <- FALSE
```

Add an observer for the toggle:

```r
observeEvent(input$show_delay_toggle, {
  rv$show_delay <- isTRUE(input$show_delay_toggle)
})
```

**IMPORTANT:** The card-rendering `renderUI` blocks must read `rv$show_delay` to trigger re-rendering when the toggle changes. Since `render_connection_card()` is called inside `renderUI(output[[paste0("batch_connections_", batch_id)]])`, ensure that `rv$show_delay` is explicitly read at the top of that `renderUI` block (e.g., `show_delay <- rv$show_delay`) so Shiny registers it as a reactive dependency. Without this, toggling the switch won't re-render the cards.

Note: The spec says `session$userData$show_delay` but `rv$show_delay` is better for module encapsulation since `session$userData` is shared across all modules.

- [ ] **Step 4: Include delay in amended data on approve**

Find the approve handler (~line 900-923 where `rv$amended_data` is set). After reading `polarity_value`, add:

```r
# Read delay values
delay_cat <- input[[paste0("delay_cat_", local_idx)]]
delay_yrs <- input[[paste0("delay_years_", local_idx)]]

# Normalize
if (is.null(delay_cat) || delay_cat == "") delay_cat <- NA_character_
if (is.null(delay_yrs) || is.na(delay_yrs)) delay_yrs <- NA_real_

# If numeric was set but no category, derive it
if (!is.na(delay_yrs) && is.na(delay_cat)) {
  delay_cat <- derive_delay_category(delay_yrs)
}
```

Then in the `rv$amended_data[[...]] <- list(...)` assignment, add:

```r
delay = delay_cat,
delay_years = delay_yrs
```

- [ ] **Step 5: Verify the file parses**

Run: `Rscript -e "tryCatch(parse(file='modules/connection_review_tabbed.R'), error=function(e) stop(e)); cat('OK\n')"`

Expected: `OK`

- [ ] **Step 6: Commit**

```bash
git add modules/connection_review_tabbed.R
git commit -m "feat(delay): add toggle, dropdown, numeric input to connection review cards"
```

---

## Chunk 4: Import/Export, i18n, Verification

### Task 8: Add delay to Excel import

**Files:**
- Modify: `functions/excel_import_helpers.R` (~line 440-462)

- [ ] **Step 1: Add delay column reading to the import cell builder**

Find the block where `cell_value <- paste0(polarity_sign, strength, ":", confidence)` is built (around line 460). Before that line, add:

```r
# Read Delay column if present
delay <- NA_character_
if ("Delay" %in% names(connections)) {
  delay_val <- tolower(trimws(as.character(connections$Delay[j])))
  if (!is.na(delay_val) && nzchar(delay_val) && delay_val %in% DELAY_CATEGORIES) {
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
```

Then replace the `cell_value` assignment with:

```r
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

- [ ] **Step 2: Commit**

```bash
git add functions/excel_import_helpers.R
git commit -m "feat(delay): read Delay columns from Excel imports"
```

---

### Task 9: Add delay to Excel export

**Files:**
- Modify: `functions/isa_export_helpers.R`

- [ ] **Step 1: Update Kumu export to include delay in connections.csv**

In `functions/isa_export_helpers.R`, the Kumu export function `create_kumu_export()` (line 93) currently writes an empty connections dataframe at line 106:
```r
connections <- data.frame(From = character(), To = character(), Type = character())
```

This needs to be populated with actual connection data from the adjacency matrices. If connections are already being built from the matrices elsewhere, add `Delay` and `Delay..years.` columns by parsing each cell value:

```r
parsed <- parse_connection_value(cell_value)
# Add to connections dataframe:
Delay = parsed$delay %||% "",
`Delay (years)` = if (!is.na(parsed$delay_years)) parsed$delay_years else ""
```

**Also verify the main Excel export** (`write_isa_element_sheets`, line 17): Adjacency matrix cells are written as-is, so the new format (`+strong:4:short-term:0.5`) will be preserved automatically. No change needed for matrix sheets.

- [ ] **Step 2: Commit**

```bash
git add functions/isa_export_helpers.R
git commit -m "feat(delay): include delay columns in Excel/Kumu export"
```

---

### Task 10: Add i18n translations for delay

**Files:**
- Modify: `translations/common/labels.json`
- Modify: `translations/modules/connection_review.json`

- [ ] **Step 1: Add delay keys to labels.json**

Open `translations/common/labels.json` and add entries to the `translation` object for all 9 languages. Follow the existing format in the file. Keys to add:

```
common.labels.delay
common.labels.delay_years
common.labels.show_temporal_delay
common.labels.temporal_delay
common.labels.not_specified
common.labels.delay_immediate
common.labels.delay_short_term
common.labels.delay_medium_term
common.labels.delay_long_term
common.labels.delay_tooltip
common.labels.or
```

Each key needs values for: `en`, `es`, `fr`, `de`, `lt`, `pt`, `it`, `no`, `el`.

Example for `common.labels.delay`:
```json
{
  "en": "Delay",
  "es": "Retardo",
  "fr": "Délai",
  "de": "Verzögerung",
  "lt": "Vėlavimas",
  "pt": "Atraso",
  "it": "Ritardo",
  "no": "Forsinkelse",
  "el": "Καθυστέρηση"
}
```

- [ ] **Step 2: Add toggle label to connection_review.json**

Add the show/hide toggle label if not already covered by the common labels.

- [ ] **Step 3: Regenerate merged translations**

Run: `Rscript -e "source('functions/translation_loader.R'); result <- load_translations('translations'); save_merged_translations(result, 'translations/_merged_translations.json'); cat('Merged', length(result$translation), 'keys\n')"`

- [ ] **Step 4: Commit**

```bash
git add translations/common/labels.json translations/modules/connection_review.json translations/_merged_translations.json
git commit -m "feat(delay): add delay translation keys for all 9 languages"
```

---

### Task 11: Verify ses_dynamics.R and project_io.R compatibility

**Files:**
- Read: `functions/ses_dynamics.R` (lines 249-278)
- Read: `server/project_io.R`

- [ ] **Step 1: Verify ses_dynamics.R**

Read `functions/ses_dynamics.R` lines 249-278 where it uses `parse_connection_value()`. Confirm it accesses `$polarity`, `$strength`, `$confidence` only (not `$lag`). If it does access `$lag`, rename to `$delay`.

- [ ] **Step 2: Verify project_io.R**

Read `server/project_io.R`. Check if it does any direct manipulation of connection objects that reference `$lag`. If so, add backward compat. The `parse_connection_value()` change in Task 3 already handles the matrix cell format migration.

- [ ] **Step 3: Commit if changes were needed**

```bash
git add functions/ses_dynamics.R server/project_io.R
git commit -m "fix(delay): verify ses_dynamics.R and project_io.R compatibility with delay migration"
```

---

### Task 12: Run full test suite and verify

- [ ] **Step 1: Run all tests**

Run: `Rscript -e "testthat::test_dir('tests/testthat', reporter = 'summary')"`

Expected: No NEW failures. Pre-existing failures from the audit (test-p0-fixes, test-auto-save-module, test-excel-import-helpers, test-ml-ensemble, test-network-metrics-module) are acceptable.

- [ ] **Step 2: Manual smoke test**

Start the app: `Rscript -e "shiny::runApp()"`

Verify:
1. App starts without errors
2. Load a template SES model (e.g., Fisheries)
3. Navigate to AI assistant, generate connections
4. In connection review, toggle "Show temporal delay" on
5. Verify dropdown and numeric input appear on cards
6. Set a delay on a connection, approve it
7. Navigate to CLD visualization — verify dashed edges appear for delayed connections
8. Hover over a dashed edge — verify tooltip shows delay info

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat(delay): complete delay attribute implementation - v1.9.0"
```
