# tests/testthat/test-old-excel-backward-compat.R
# End-to-end backward compatibility tests for old Excel files (pre-delay)
# ==============================================================================
#
# These tests verify that Excel files created before the delay feature
# (i.e., without Delay/Delay (years) columns) load correctly through
# the full import pipeline and that parse_connection_value correctly
# round-trips old-format adjacency cells.
# ==============================================================================

library(testthat)

# Resolve project root
test_dir <- getwd()
if (basename(test_dir) == "testthat") {
  project_root <- file.path(dirname(dirname(test_dir)))
} else {
  project_root <- test_dir
}

# ==============================================================================
# Helper: Build path to data files relative to project root
# ==============================================================================
data_path <- function(...) file.path(project_root, "data", ...)

# ==============================================================================
# Section 1: Real Kumu-format Excel file loading (TuscanySES.xlsx)
# ==============================================================================

test_that("old Kumu Excel file (TuscanySES.xlsx) loads via universal loader without errors", {
  skip_if_not(file.exists(data_path("TuscanySES.xlsx")),
              "TuscanySES.xlsx not available")
  skip_if_not(exists("load_ses_model_universal", mode = "function"),
              "load_ses_model_universal not available")

  result <- load_ses_model_universal(data_path("TuscanySES.xlsx"))

  expect_equal(length(result$errors), 0,
               info = paste("Loader errors:", paste(result$errors, collapse = "; ")))
  expect_true(!is.null(result$elements), info = "Elements should be loaded")
  expect_true(!is.null(result$connections), info = "Connections should be loaded")
  expect_true(nrow(result$elements) > 0, info = "Should have at least one element")
  expect_true(nrow(result$connections) > 0, info = "Should have at least one connection")
})

test_that("old Kumu Excel file (TuscanySES.xlsx) has no Delay columns", {
  skip_if_not(file.exists(data_path("TuscanySES.xlsx")),
              "TuscanySES.xlsx not available")
  skip_if_not(exists("load_ses_model_universal", mode = "function"),
              "load_ses_model_universal not available")

  result <- load_ses_model_universal(data_path("TuscanySES.xlsx"))

  expect_false("Delay" %in% names(result$connections),
               info = "Old file should not have Delay column")
  expect_false("Delay (years)" %in% names(result$connections),
               info = "Old file should not have Delay (years) column")
})

test_that("old Kumu Excel (TuscanySES.xlsx) converts to ISA without error", {
  skip_if_not(file.exists(data_path("TuscanySES.xlsx")),
              "TuscanySES.xlsx not available")
  skip_if_not(exists("load_ses_model_universal", mode = "function"),
              "load_ses_model_universal not available")
  skip_if_not(exists("convert_excel_to_isa", mode = "function"),
              "convert_excel_to_isa not available")

  result <- load_ses_model_universal(data_path("TuscanySES.xlsx"))

  # Should not error even with the file's column naming quirks
  isa <- convert_excel_to_isa(result$elements, result$connections)

  expect_type(isa, "list")
  expect_true("adjacency_matrices" %in% names(isa))

  # All element categories should be present in the structure
  for (cat_name in c("drivers", "activities", "pressures",
                     "marine_processes", "ecosystem_services", "goods_benefits")) {
    expect_true(cat_name %in% names(isa),
                info = paste("ISA structure should contain", cat_name))
  }
})

# ==============================================================================
# Section 2: Second real Kumu file (KUMU_TA_Full model CLD.xlsx)
# ==============================================================================

test_that("old Kumu Excel (KUMU_TA_Full model CLD.xlsx) loads without errors", {
  skip_if_not(file.exists(data_path("KUMU_TA_Full model CLD.xlsx")),
              "KUMU_TA_Full model CLD.xlsx not available")
  skip_if_not(exists("load_ses_model_universal", mode = "function"),
              "load_ses_model_universal not available")

  result <- load_ses_model_universal(data_path("KUMU_TA_Full model CLD.xlsx"))

  expect_equal(length(result$errors), 0,
               info = paste("Loader errors:", paste(result$errors, collapse = "; ")))
  expect_false("Delay" %in% names(result$connections),
               info = "Old file should not have Delay column")
})

test_that("old Kumu Excel (KUMU_TA_Full model CLD.xlsx) converts to ISA without error", {
  skip_if_not(file.exists(data_path("KUMU_TA_Full model CLD.xlsx")),
              "KUMU_TA_Full model CLD.xlsx not available")
  skip_if_not(exists("load_ses_model_universal", mode = "function"),
              "load_ses_model_universal not available")
  skip_if_not(exists("convert_excel_to_isa", mode = "function"),
              "convert_excel_to_isa not available")

  result <- load_ses_model_universal(data_path("KUMU_TA_Full model CLD.xlsx"))
  isa <- convert_excel_to_isa(result$elements, result$connections)

  expect_type(isa, "list")
  expect_true("adjacency_matrices" %in% names(isa))
})

# ==============================================================================
# Section 3: Synthetic old-format pipeline (convert + parse round-trip)
# ==============================================================================

test_that("old-format connections produce adjacency cells with no delay suffix", {
  skip_if_not(exists("convert_excel_to_isa", mode = "function"),
              "convert_excel_to_isa not available")

  elements <- data.frame(
    Label = c("Climate change", "Population growth",
              "Fishing", "Tourism",
              "Habitat loss", "Nutrient loading",
              "Coral cover", "Water quality",
              "Fish provision", "Recreation",
              "Seafood", "Tourism revenue"),
    Type = c("Driver", "Driver",
             "Activity", "Activity",
             "Pressure", "Pressure",
             "Marine Process and Function", "Marine Process and Function",
             "Ecosystem Service", "Ecosystem Service",
             "Good and Benefit", "Good and Benefit"),
    stringsAsFactors = FALSE
  )

  connections <- data.frame(
    From = c("Climate change", "Population growth", "Fishing", "Habitat loss",
             "Coral cover", "Fish provision"),
    To = c("Fishing", "Tourism", "Habitat loss", "Coral cover",
           "Fish provision", "Seafood"),
    Label = c("+", "+", "-", "-", "+", "+"),
    Strength = c("strong", "medium", "strong", "medium", "weak", "strong"),
    Confidence = c(5, 3, 4, 2, 1, 4),
    stringsAsFactors = FALSE
  )
  # Intentionally NO Delay or Delay (years) columns

  isa <- convert_excel_to_isa(elements, connections)

  expect_type(isa, "list")
  expect_true(length(isa$adjacency_matrices) > 0,
              info = "Should produce at least one adjacency matrix")

  # Collect and verify all non-empty cells
  all_cells <- character()
  for (mat_name in names(isa$adjacency_matrices)) {
    mat <- isa$adjacency_matrices[[mat_name]]
    non_empty <- mat[mat != ""]
    all_cells <- c(all_cells, non_empty)
  }

  expect_true(length(all_cells) > 0, info = "Should have non-empty cells")

  for (cell in all_cells) {
    # Should be +/-strength:confidence with no delay suffix
    expect_true(grepl("^[+-]\\w+:\\d+$", cell),
                info = paste("Cell should be +strength:confidence, got:", cell))
    for (delay_cat in c("immediate", "short-term", "medium-term", "long-term")) {
      expect_false(grepl(delay_cat, cell, fixed = TRUE),
                   info = paste("Cell should NOT contain delay category:", delay_cat))
    }
  }
})

test_that("old-format adjacency cells round-trip through parse_connection_value", {
  skip_if_not(exists("convert_excel_to_isa", mode = "function"),
              "convert_excel_to_isa not available")
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")

  elements <- data.frame(
    Label = c("Climate change", "Population growth",
              "Fishing", "Tourism",
              "Habitat loss", "Nutrient loading",
              "Coral cover", "Water quality",
              "Fish provision", "Recreation",
              "Seafood", "Tourism revenue"),
    Type = c("Driver", "Driver",
             "Activity", "Activity",
             "Pressure", "Pressure",
             "Marine Process and Function", "Marine Process and Function",
             "Ecosystem Service", "Ecosystem Service",
             "Good and Benefit", "Good and Benefit"),
    stringsAsFactors = FALSE
  )

  connections <- data.frame(
    From = c("Climate change", "Population growth", "Fishing", "Habitat loss",
             "Coral cover", "Fish provision"),
    To = c("Fishing", "Tourism", "Habitat loss", "Coral cover",
           "Fish provision", "Seafood"),
    Label = c("+", "+", "-", "-", "+", "+"),
    Strength = c("strong", "medium", "strong", "medium", "weak", "strong"),
    Confidence = c(5, 3, 4, 2, 1, 4),
    stringsAsFactors = FALSE
  )

  isa <- convert_excel_to_isa(elements, connections)

  cells_checked <- 0
  for (mat_name in names(isa$adjacency_matrices)) {
    mat <- isa$adjacency_matrices[[mat_name]]
    non_empty <- mat[mat != ""]
    for (cell in non_empty) {
      parsed <- parse_connection_value(cell)

      expect_true(!is.null(parsed),
                  info = paste("Should parse:", cell))
      expect_true(parsed$polarity %in% c("+", "-"),
                  info = paste("Polarity should be + or -, got:", parsed$polarity))
      expect_true(parsed$strength %in% c("weak", "medium", "strong"),
                  info = paste("Strength should be weak/medium/strong, got:", parsed$strength))
      expect_true(parsed$confidence %in% 1:5,
                  info = paste("Confidence should be 1-5, got:", parsed$confidence))
      expect_true(is.na(parsed$delay),
                  info = paste("Delay should be NA for old format, got:", parsed$delay))
      expect_true(is.na(parsed$delay_years),
                  info = paste("Delay years should be NA for old format, got:", parsed$delay_years))

      # Verify exact round-trip: cell reconstructs to same value
      reconstructed <- paste0(parsed$polarity, parsed$strength, ":", parsed$confidence)
      expect_equal(cell, reconstructed,
                   info = paste("Cell should round-trip:", cell, "vs", reconstructed))

      cells_checked <- cells_checked + 1
    }
  }

  expect_true(cells_checked > 0, info = "Should have checked at least one cell")
})

# ==============================================================================
# Section 4: parse_connection_value mixed old/new format
# ==============================================================================

test_that("parse_connection_value handles all old format variations", {
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")

  old_cells <- list(
    list(cell = "+medium:3", pol = "+", str = "medium", conf = 3L),
    list(cell = "-strong:4", pol = "-", str = "strong", conf = 4L),
    list(cell = "+weak:1",   pol = "+", str = "weak",   conf = 1L),
    list(cell = "-medium:5", pol = "-", str = "medium", conf = 5L),
    list(cell = "+strong:2", pol = "+", str = "strong", conf = 2L)
  )

  for (item in old_cells) {
    parsed <- parse_connection_value(item$cell)
    expect_true(!is.null(parsed), info = paste("Should parse:", item$cell))
    expect_equal(parsed$polarity, item$pol,
                 info = paste("Polarity mismatch for:", item$cell))
    expect_equal(parsed$strength, item$str,
                 info = paste("Strength mismatch for:", item$cell))
    expect_equal(parsed$confidence, item$conf,
                 info = paste("Confidence mismatch for:", item$cell))
    expect_true(is.na(parsed$delay),
                info = paste("Old cell delay should be NA:", item$cell))
    expect_true(is.na(parsed$delay_years),
                info = paste("Old cell delay_years should be NA:", item$cell))
  }
})

test_that("parse_connection_value distinguishes old from new format cells", {
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")

  # New format cells (from delay-enabled Excel files)
  new_cells <- list(
    list(cell = "+strong:4:short-term",       delay = "short-term",  years = NA_real_),
    list(cell = "-medium:3:long-term:5",      delay = "long-term",   years = 5),
    list(cell = "+weak:2:immediate:0",        delay = "immediate",   years = 0),
    list(cell = "-strong:5:medium-term:1.5",  delay = "medium-term", years = 1.5)
  )

  for (item in new_cells) {
    parsed <- parse_connection_value(item$cell)
    expect_true(!is.null(parsed), info = paste("Should parse:", item$cell))
    expect_equal(parsed$delay, item$delay,
                 info = paste("Delay category mismatch for:", item$cell))
    if (is.na(item$years)) {
      expect_true(is.na(parsed$delay_years),
                  info = paste("Delay years should be NA for:", item$cell))
    } else {
      expect_equal(parsed$delay_years, item$years,
                   info = paste("Delay years mismatch for:", item$cell))
    }
  }
})

# ==============================================================================
# Section 5: Minimal old format (polarity only, no strength/confidence/delay)
# ==============================================================================

test_that("minimal old format (From/To/Label only) gets defaults, no delay", {
  skip_if_not(exists("convert_excel_to_isa", mode = "function"),
              "convert_excel_to_isa not available")
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")

  elements <- data.frame(
    Label = c("Driver A", "Activity B"),
    Type = c("Driver", "Activity"),
    stringsAsFactors = FALSE
  )

  connections <- data.frame(
    From = c("Driver A"),
    To = c("Activity B"),
    Label = c("+"),
    stringsAsFactors = FALSE
  )

  isa <- convert_excel_to_isa(elements, connections)
  expect_type(isa, "list")
  expect_true(length(isa$adjacency_matrices) > 0)

  for (mat_name in names(isa$adjacency_matrices)) {
    mat <- isa$adjacency_matrices[[mat_name]]
    non_empty <- mat[mat != ""]
    for (cell in non_empty) {
      expect_equal(cell, "+medium:3",
                   info = "Minimal connection should default to +medium:3")
      parsed <- parse_connection_value(cell)
      expect_equal(parsed$polarity, "+")
      expect_equal(parsed$strength, "medium")
      expect_equal(parsed$confidence, 3L)
      expect_true(is.na(parsed$delay))
      expect_true(is.na(parsed$delay_years))
    }
  }
})

# ==============================================================================
# Section 6: Negative polarity preservation
# ==============================================================================

test_that("old format negative polarity connections import correctly", {
  skip_if_not(exists("convert_excel_to_isa", mode = "function"),
              "convert_excel_to_isa not available")

  elements <- data.frame(
    Label = c("Fishing", "Fish stock"),
    Type = c("Activity", "Pressure"),
    stringsAsFactors = FALSE
  )

  connections <- data.frame(
    From = c("Fishing"),
    To = c("Fish stock"),
    Label = c("-"),
    Strength = c("strong"),
    Confidence = c(5),
    stringsAsFactors = FALSE
  )

  isa <- convert_excel_to_isa(elements, connections)

  for (mat_name in names(isa$adjacency_matrices)) {
    mat <- isa$adjacency_matrices[[mat_name]]
    non_empty <- mat[mat != ""]
    for (cell in non_empty) {
      expect_equal(cell, "-strong:5",
                   info = "Negative polarity should be preserved as -strong:5")
    }
  }
})

# ==============================================================================
# Section 7: Old format with numeric lag (backward compat migration)
# ==============================================================================

test_that("parse_connection_value migrates old numeric lag to delay category", {
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")
  skip_if_not(exists("derive_delay_category", mode = "function"),
              "derive_delay_category not available")

  # Old format: "+strong:4:0.5" (3rd field is numeric years, not a category)
  parsed <- parse_connection_value("+strong:4:0.5")
  expect_equal(parsed$polarity, "+")
  expect_equal(parsed$strength, "strong")
  expect_equal(parsed$confidence, 4L)
  expect_false(is.na(parsed$delay),
               info = "Numeric lag should be auto-converted to delay category")
  expect_equal(parsed$delay_years, 0.5)

  # Verify the derived category matches derive_delay_category
  expected_cat <- derive_delay_category(0.5)
  expect_equal(parsed$delay, expected_cat)

  # Test with various numeric lag values
  for (lag in c(0, 0.1, 1, 3, 10)) {
    cell <- paste0("+medium:3:", lag)
    parsed <- parse_connection_value(cell)
    expect_equal(parsed$delay, derive_delay_category(lag),
                 info = paste("Lag", lag, "should map to", derive_delay_category(lag)))
    expect_equal(parsed$delay_years, lag)
  }
})

# ==============================================================================
# Section 8: Polarity-only format (no colon, no confidence)
# ==============================================================================

test_that("parse_connection_value handles polarity+strength without confidence", {
  skip_if_not(exists("parse_connection_value", mode = "function"),
              "parse_connection_value not available")

  parsed <- parse_connection_value("+strong")
  expect_equal(parsed$polarity, "+")
  expect_equal(parsed$strength, "strong")
  expect_equal(parsed$confidence, 3L, info = "Should default to CONFIDENCE_DEFAULT")
  expect_true(is.na(parsed$delay))
  expect_true(is.na(parsed$delay_years))

  parsed2 <- parse_connection_value("-weak")
  expect_equal(parsed2$polarity, "-")
  expect_equal(parsed2$strength, "weak")
  expect_true(is.na(parsed2$delay))
})

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Old Excel Backward Compatibility Tests Complete\n")
cat(strrep("=", 70), "\n")
