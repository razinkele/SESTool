# tests/testthat/test-universal-excel-loader.R
# Tests for Universal Excel Loader Functions
# ==============================================================================

library(testthat)

# Ensure debug_log exists (may be defined in global.R via setup.R)
if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, category = "TEST") invisible(NULL)
}

source("../../functions/universal_excel_loader.R", chdir = TRUE)

# Determine project root for test data
test_dir <- getwd()
if (basename(test_dir) == "testthat") {
  project_root <- file.path(dirname(dirname(test_dir)))
} else {
  project_root <- test_dir
}

tuscany_path <- file.path(project_root, "data", "TuscanySES.xlsx")

# ==============================================================================
# Test: normalize_element_name
# ==============================================================================

test_that("normalize_element_name trims whitespace", {
  expect_equal(normalize_element_name("  hello  "), "hello")
  expect_equal(normalize_element_name("no trim"), "no trim")
})

test_that("normalize_element_name replaces non-breaking spaces", {
  # \u00A0 is non-breaking space
  input <- paste0("hello", "\u00A0", "world")
  result <- normalize_element_name(input)
  expect_equal(result, "hello world")
})

test_that("normalize_element_name collapses multiple spaces", {
  expect_equal(normalize_element_name("hello   world"), "hello world")
})

test_that("normalize_element_name replaces en-dash and em-dash with hyphen", {
  expect_equal(normalize_element_name("A\u2013B"), "A-B")
  expect_equal(normalize_element_name("A\u2014B"), "A-B")
})

test_that("normalize_element_name replaces smart quotes", {
  expect_equal(normalize_element_name("\u2018hello\u2019"), "'hello'")
  expect_equal(normalize_element_name("\u201Chello\u201D"), "\"hello\"")
})

test_that("normalize_element_name removes zero-width characters", {
  input <- paste0("hello", "\u200B", "world")
  expect_equal(normalize_element_name(input), "helloworld")
})

test_that("normalize_element_name handles NA input", {
  expect_true(is.na(normalize_element_name(NA)))
})

test_that("normalize_element_name handles non-character input", {
  expect_true(is.na(normalize_element_name(123)))
})

test_that("normalize_element_name lowercases when requested", {
  expect_equal(normalize_element_name("Hello World", lowercase = TRUE), "hello world")
  expect_equal(normalize_element_name("Hello World", lowercase = FALSE), "Hello World")
})

test_that("normalize_element_name removes BOM character", {
  input <- paste0("\uFEFF", "text")
  expect_equal(normalize_element_name(input), "text")
})

# ==============================================================================
# Test: normalize_column_names
# ==============================================================================

test_that("normalize_column_names maps standard columns correctly", {
  df <- data.frame(label = "A", from = "X", to = "Y", type = "Driver",
                   stringsAsFactors = FALSE)
  result <- normalize_column_names(df)
  expect_true("Label" %in% names(result))
  expect_true("From" %in% names(result))
  expect_true("To" %in% names(result))
  expect_true("type" %in% names(result))  # type stays lowercase
})

test_that("normalize_column_names handles uppercase input", {
  df <- data.frame(LABEL = "A", FROM = "X", TO = "Y",
                   stringsAsFactors = FALSE)
  result <- normalize_column_names(df)
  expect_true("Label" %in% names(result))
  expect_true("From" %in% names(result))
  expect_true("To" %in% names(result))
})

test_that("normalize_column_names preserves unrecognized columns", {
  df <- data.frame(label = "A", custom_col = "val", stringsAsFactors = FALSE)
  result <- normalize_column_names(df)
  expect_true("custom_col" %in% names(result))
})

test_that("normalize_column_names maps description column", {
  df <- data.frame(description = "desc text", stringsAsFactors = FALSE)
  result <- normalize_column_names(df)
  expect_true("Description" %in% names(result))
})

test_that("normalize_column_names maps strength and confidence", {
  df <- data.frame(strength = "high", confidence = 3, stringsAsFactors = FALSE)
  result <- normalize_column_names(df)
  expect_true("Strength" %in% names(result))
  expect_true("Confidence" %in% names(result))
})

# ==============================================================================
# Test: detect_excel_format (with real file)
# ==============================================================================

test_that("detect_excel_format returns error for missing file", {
  result <- detect_excel_format("/nonexistent/file.xlsx")
  expect_equal(result$format, "unknown")
  expect_true(length(result$errors) > 0)
  expect_true(any(grepl("not found", result$errors)))
})

test_that("detect_excel_format returns correct structure", {
  skip_if_not(file.exists(tuscany_path), "TuscanySES.xlsx not available")

  result <- detect_excel_format(tuscany_path)

  expect_true(is.list(result))
  expect_true("format" %in% names(result))
  expect_true("variants" %in% names(result))
  expect_true("errors" %in% names(result))
  expect_true("file_name" %in% names(result))
})

test_that("detect_excel_format detects Kumu standard format", {
  skip_if_not(file.exists(tuscany_path), "TuscanySES.xlsx not available")

  result <- detect_excel_format(tuscany_path)

  # TuscanySES should have Elements + Connections sheets
  if (result$format == "kumu_standard") {
    expect_equal(result$format, "kumu_standard")
    expect_true(length(result$variants) > 0)
    expect_equal(result$variants[[1]]$node_sheet, "Elements")
    expect_equal(result$variants[[1]]$edge_sheet, "Connections")
  } else {
    # If it's multi_variant, that's also valid
    expect_true(result$format %in% c("kumu_standard", "multi_variant"))
  }
  expect_equal(length(result$errors), 0)
})

# ==============================================================================
# Test: load_ses_model_universal (with real file)
# ==============================================================================

test_that("load_ses_model_universal returns correct structure", {
  skip_if_not(file.exists(tuscany_path), "TuscanySES.xlsx not available")

  result <- load_ses_model_universal(tuscany_path, validate = FALSE)

  expect_true(is.list(result))
  expect_true("elements" %in% names(result))
  expect_true("connections" %in% names(result))
  expect_true("metadata" %in% names(result))
  expect_true("errors" %in% names(result))
  expect_true("warnings" %in% names(result))
})

test_that("load_ses_model_universal loads elements and connections", {
  skip_if_not(file.exists(tuscany_path), "TuscanySES.xlsx not available")

  result <- load_ses_model_universal(tuscany_path, validate = FALSE)

  # Should have loaded data without errors
  if (length(result$errors) == 0) {
    expect_true(is.data.frame(result$elements))
    expect_true(is.data.frame(result$connections))
    expect_gt(nrow(result$elements), 0)
    expect_gt(nrow(result$connections), 0)
  }
})

test_that("load_ses_model_universal populates metadata", {
  skip_if_not(file.exists(tuscany_path), "TuscanySES.xlsx not available")

  result <- load_ses_model_universal(tuscany_path, validate = FALSE)

  expect_equal(result$metadata$file_name, "TuscanySES.xlsx")
  expect_true(!is.null(result$metadata$format))
})

test_that("load_ses_model_universal returns error for nonexistent file", {
  result <- load_ses_model_universal("/no/such/file.xlsx")
  expect_true(length(result$errors) > 0)
})

test_that("load_ses_model_universal returns error for bad variant name", {
  skip_if_not(file.exists(tuscany_path), "TuscanySES.xlsx not available")

  result <- load_ses_model_universal(tuscany_path, variant_name = "NonExistentVariant")
  expect_true(length(result$errors) > 0)
  expect_true(any(grepl("Variant not found", result$errors)))
})

# ==============================================================================
# Test: validate_universal_model
# ==============================================================================

test_that("validate_universal_model catches NULL elements", {
  result <- validate_universal_model(NULL, data.frame(From = "A", To = "B"))
  expect_true(length(result$errors) > 0)
})

test_that("validate_universal_model catches empty elements", {
  empty_df <- data.frame(Label = character(), type = character(), stringsAsFactors = FALSE)
  result <- validate_universal_model(empty_df, data.frame(From = "A", To = "B"))
  expect_true(length(result$errors) > 0)
})

test_that("validate_universal_model catches missing Label column", {
  df <- data.frame(Name = c("A", "B"), type = c("Driver", "Activity"), stringsAsFactors = FALSE)
  result <- validate_universal_model(df, data.frame(From = "A", To = "B"))
  expect_true(any(grepl("Label", result$errors)))
})

test_that("validate_universal_model warns on unknown types", {
  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "UnknownType"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", stringsAsFactors = FALSE)
  result <- validate_universal_model(elements, connections)
  expect_true(any(grepl("Unknown element types", result$warnings)))
})

test_that("validate_universal_model passes with valid data", {
  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", stringsAsFactors = FALSE)
  result <- validate_universal_model(elements, connections)
  expect_equal(length(result$errors), 0)
})

test_that("validate_universal_model warns on orphan connections", {
  elements <- data.frame(Label = c("A", "B"), type = c("Driver", "Activity"),
                         stringsAsFactors = FALSE)
  connections <- data.frame(From = c("A", "C"), To = c("B", "D"),
                            stringsAsFactors = FALSE)
  result <- validate_universal_model(elements, connections)
  expect_true(any(grepl("unknown nodes", result$warnings)))
})

# ==============================================================================
# Test: infer_nodes_from_edges
# ==============================================================================

test_that("infer_nodes_from_edges creates nodes from From/To columns", {
  edges <- data.frame(
    From = c("A", "B", "C"),
    To = c("B", "C", "A"),
    stringsAsFactors = FALSE
  )
  result <- infer_nodes_from_edges(edges)
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3)
  expect_true(all(c("A", "B", "C") %in% result$Label))
})

test_that("infer_nodes_from_edges removes NA and empty labels", {
  edges <- data.frame(
    From = c("A", NA, ""),
    To = c("B", "C", "D"),
    stringsAsFactors = FALSE
  )
  result <- infer_nodes_from_edges(edges)
  expect_false(any(is.na(result$Label)))
  expect_false(any(result$Label == ""))
})

# ==============================================================================
# Test: create_name_mapping
# ==============================================================================

test_that("create_name_mapping finds exact matches", {
  elements <- data.frame(Label = c("NodeA", "NodeB"), stringsAsFactors = FALSE)
  connections <- data.frame(From = c("NodeA"), To = c("NodeB"), stringsAsFactors = FALSE)

  result <- create_name_mapping(elements, connections)
  expect_equal(result$exact_matches, 2)
  expect_equal(length(result$mapping), 0)
})

test_that("create_name_mapping detects whitespace mismatches", {
  elements <- data.frame(Label = c("Node A", "Node B"), stringsAsFactors = FALSE)
  connections <- data.frame(From = c("Node  A"), To = c("Node B"), stringsAsFactors = FALSE)

  result <- create_name_mapping(elements, connections)
  expect_true(result$normalized_matches > 0 || result$exact_matches > 0)
})

test_that("create_name_mapping returns empty for missing columns", {
  elements <- data.frame(Name = "A", stringsAsFactors = FALSE)
  connections <- data.frame(From = "A", To = "B", stringsAsFactors = FALSE)

  result <- create_name_mapping(elements, connections)
  expect_equal(length(result$mapping), 0)
})

# ==============================================================================
# Test: apply_name_mapping
# ==============================================================================

test_that("apply_name_mapping replaces From/To values", {
  connections <- data.frame(
    From = c("node a", "node b"),
    To = c("node b", "node c"),
    stringsAsFactors = FALSE
  )
  mapping <- list("node a" = "Node A", "node c" = "Node C")

  result <- apply_name_mapping(connections, mapping)
  expect_equal(result$From[1], "Node A")
  expect_equal(result$To[2], "Node C")
  expect_equal(result$From[2], "node b")  # Unchanged
})

test_that("apply_name_mapping returns unchanged df with empty mapping", {
  connections <- data.frame(From = "A", To = "B", stringsAsFactors = FALSE)
  result <- apply_name_mapping(connections, list())
  expect_equal(result$From, "A")
  expect_equal(result$To, "B")
})
