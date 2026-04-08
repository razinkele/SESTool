# tests/testthat/test-template-loading.R
# End-to-end template loading tests — verifies each template loads
# through the actual R loader pipeline and produces valid ISA structures.

library(testthat)

# --- Setup ---
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(a, b) if (!is.null(a)) a else b
}

.test_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") return(dirname(dirname(wd)))
  if (file.exists(file.path(wd, "data/ses_knowledge_db.json"))) return(wd)
  candidate <- dirname(dirname(wd))
  if (file.exists(file.path(candidate, "data/ses_knowledge_db.json"))) return(candidate)
  return(wd)
}

ROOT <- .test_root()

# Source the template loader (need its helper functions)
loader_path <- file.path(ROOT, "functions", "template_loader.R")
if (!exists("load_template_from_json", mode = "function") && file.exists(loader_path)) {
  # Stub dependencies the loader expects
  if (!exists("debug_log", mode = "function")) {
    debug_log <- function(...) invisible(NULL)
  }
  if (!exists("log_warning", mode = "function")) {
    log_warning <- function(...) invisible(NULL)
  }
  tryCatch(source(loader_path, local = FALSE), error = function(e) {
    message("Could not source template_loader.R: ", e$message)
  })
}

# ==============================================================================
# 1. All production templates load without error
# ==============================================================================
test_that("All 7 production templates load through load_template_from_json()", {
  skip_if_not(exists("load_template_from_json", mode = "function"),
              "load_template_from_json not available")

  template_files <- c(
    "Fisheries_SES_Template.json",
    "Aquaculture_SES_Template.json",
    "Pollution_SES_Template.json",
    "Tourism_SES_Template.json",
    "ClimateChange_SES_Template.json",
    "OffshoreWind_SES_Template.json",
    "Caribbean_SES_Template.json"
  )

  for (tpl_file in template_files) {
    path <- file.path(ROOT, "data", tpl_file)
    skip_if_not(file.exists(path), paste("File not found:", tpl_file))

    result <- load_template_from_json(path, use_cache = FALSE)
    expect_false(is.null(result),
      info = paste(tpl_file, "returned NULL — loader failed"))
    expect_true(is.list(result),
      info = paste(tpl_file, "did not return a list"))
  }
})

# ==============================================================================
# 2. Loaded templates have all required ISA data frame components
# ==============================================================================
test_that("Loaded templates have all required data frame components", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  required_dfs <- c("drivers", "activities", "pressures", "marine_processes",
                    "ecosystem_services", "goods_benefits", "responses")

  template_files <- list.files(file.path(ROOT, "data"),
                               pattern = "_SES_Template\\.json$", full.names = TRUE)

  for (path in template_files) {
    tpl_name <- gsub("_SES_Template\\.json$", "", basename(path))
    result <- load_template_from_json(path, use_cache = FALSE)
    skip_if(is.null(result), paste(tpl_name, "failed to load"))

    for (df_name in required_dfs) {
      df <- result[[df_name]]
      expect_true(is.data.frame(df),
        info = paste(tpl_name, "$", df_name, "is not a data.frame"))
      expect_true(nrow(df) >= 1,
        info = paste(tpl_name, "$", df_name, "has 0 rows"))
      expect_true("ID" %in% names(df),
        info = paste(tpl_name, "$", df_name, "missing ID column"))
      expect_true("Name" %in% names(df),
        info = paste(tpl_name, "$", df_name, "missing Name column"))
    }
  }
})

# ==============================================================================
# 3. Adjacency matrices are built correctly
# ==============================================================================
test_that("Loaded templates have adjacency matrices", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  # Core matrices expected for every template with a complete chain
  core_matrices <- c("d_a", "a_p", "p_mpf", "mpf_es", "es_gb")

  template_files <- list.files(file.path(ROOT, "data"),
                               pattern = "_SES_Template\\.json$", full.names = TRUE)

  for (path in template_files) {
    tpl_name <- gsub("_SES_Template\\.json$", "", basename(path))
    result <- load_template_from_json(path, use_cache = FALSE)
    skip_if(is.null(result), paste(tpl_name, "failed to load"))

    matrices <- result$adjacency_matrices
    expect_true(is.list(matrices),
      info = paste(tpl_name, "adjacency_matrices is not a list"))
    expect_true(length(matrices) >= 3,
      info = paste(tpl_name, "has fewer than 3 matrices"))

    # Check d_a matrix exists (all templates should have drivers→activities)
    expect_true("d_a" %in% names(matrices),
      info = paste(tpl_name, "missing d_a matrix"))

    if (!is.null(matrices$d_a)) {
      expect_true(is.matrix(matrices$d_a),
        info = paste(tpl_name, "d_a is not a matrix"))
      expect_true(nrow(matrices$d_a) >= 1 && ncol(matrices$d_a) >= 1,
        info = paste(tpl_name, "d_a matrix is empty"))
    }
  }
})

# ==============================================================================
# 4. Feedback loop matrix (gb_d) is built for templates with feedback connections
# ==============================================================================
test_that("Templates with welfare-driver feedback have gb_d matrix", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  templates_with_feedback <- c(
    "Fisheries_SES_Template.json",
    "Aquaculture_SES_Template.json",
    "Pollution_SES_Template.json",
    "Tourism_SES_Template.json",
    "ClimateChange_SES_Template.json",
    "OffshoreWind_SES_Template.json",
    "Caribbean_SES_Template.json"
  )

  for (tpl_file in templates_with_feedback) {
    path <- file.path(ROOT, "data", tpl_file)
    result <- load_template_from_json(path, use_cache = FALSE)
    skip_if(is.null(result))

    tpl_name <- gsub("_SES_Template\\.json$", "", tpl_file)
    matrices <- result$adjacency_matrices

    expect_true("gb_d" %in% names(matrices),
      info = paste(tpl_name, "missing gb_d (welfare→driver feedback) matrix"))

    if (!is.null(matrices$gb_d)) {
      # At least one non-empty cell
      has_feedback <- any(matrices$gb_d != "")
      expect_true(has_feedback,
        info = paste(tpl_name, "gb_d matrix exists but is all empty — no feedback connections loaded"))
    }
  }
})

# ==============================================================================
# 5. Measure connections are preserved in r_r matrix
# ==============================================================================
test_that("Templates with measures have r_r matrix with content", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  templates_with_measures <- c(
    "Fisheries_SES_Template.json",
    "Aquaculture_SES_Template.json",
    "Pollution_SES_Template.json",
    "Tourism_SES_Template.json",
    "ClimateChange_SES_Template.json",
    "OffshoreWind_SES_Template.json"
  )

  for (tpl_file in templates_with_measures) {
    path <- file.path(ROOT, "data", tpl_file)
    result <- load_template_from_json(path, use_cache = FALSE)
    skip_if(is.null(result))

    tpl_name <- gsub("_SES_Template\\.json$", "", tpl_file)

    # Responses df should include merged measures
    expect_true(nrow(result$responses) >= 3,
      info = paste(tpl_name, "responses should have responses + measures (expected >=3, got",
                   nrow(result$responses), ")"))

    # r_r matrix should exist and contain M→R connections
    matrices <- result$adjacency_matrices
    expect_true("r_r" %in% names(matrices),
      info = paste(tpl_name, "missing r_r matrix (measure→response connections)"))

    if (!is.null(matrices$r_r)) {
      has_mr <- any(matrices$r_r != "")
      expect_true(has_mr,
        info = paste(tpl_name, "r_r matrix is all empty — measure→response connections not loaded"))
    }
  }
})

# ==============================================================================
# 6. Same-type matrices (p_p, s_s) are built when data exists
# ==============================================================================
test_that("Templates with same-type connections have p_p or s_s matrices", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  # Check at least one template has p_p and one has s_s
  found_pp <- FALSE
  found_ss <- FALSE

  template_files <- list.files(file.path(ROOT, "data"),
                               pattern = "_SES_Template\\.json$", full.names = TRUE)

  for (path in template_files) {
    result <- load_template_from_json(path, use_cache = FALSE)
    if (is.null(result)) next
    matrices <- result$adjacency_matrices
    if ("p_p" %in% names(matrices) && any(matrices$p_p != "")) found_pp <- TRUE
    if ("s_s" %in% names(matrices) && any(matrices$s_s != "")) found_ss <- TRUE
  }

  expect_true(found_pp,
    info = "No template produced a non-empty p_p (pressure→pressure) matrix")
  expect_true(found_ss,
    info = "No template produced a non-empty s_s (state→state) matrix")
})

# ==============================================================================
# 7. Matrix cell format is correct (polarity+strength:confidence)
# ==============================================================================
test_that("Adjacency matrix cells have correct format", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  path <- file.path(ROOT, "data", "Fisheries_SES_Template.json")
  result <- load_template_from_json(path, use_cache = FALSE)
  skip_if(is.null(result))

  # Check d_a matrix cells match pattern: +/-strength:N
  mat <- result$adjacency_matrices$d_a
  non_empty <- mat[mat != ""]

  if (length(non_empty) > 0) {
    for (cell in non_empty) {
      # Expected format: +medium:3 or -strong:5 etc.
      expect_true(grepl("^[+-](weak|medium|strong):[1-5]$", cell),
        info = paste("Invalid matrix cell format:", cell,
                     "— expected pattern: +/-strength:confidence"))
    }
  }
})

# ==============================================================================
# 8. Test fixtures also load correctly
# ==============================================================================
test_that("Test fixture templates load through the loader", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  fixture_dir <- file.path(ROOT, "tests", "fixtures", "templates")
  skip_if_not(dir.exists(fixture_dir), "Fixture directory not found")

  fixture_files <- list.files(fixture_dir, pattern = "\\.json$", full.names = TRUE)

  for (path in fixture_files) {
    fname <- basename(path)
    result <- load_template_from_json(path, use_cache = FALSE)
    expect_false(is.null(result),
      info = paste("Fixture", fname, "failed to load"))

    if (!is.null(result)) {
      expect_true(nrow(result$drivers) >= 1,
        info = paste("Fixture", fname, "has no drivers"))
      expect_true(length(result$connections) >= 1,
        info = paste("Fixture", fname, "has no connections"))
    }
  }
})

# ==============================================================================
# 9. Template metadata fields are present
# ==============================================================================
test_that("Loaded templates have required metadata", {
  skip_if_not(exists("load_template_from_json", mode = "function"))

  template_files <- list.files(file.path(ROOT, "data"),
                               pattern = "_SES_Template\\.json$", full.names = TRUE)

  for (path in template_files) {
    tpl_name <- gsub("_SES_Template\\.json$", "", basename(path))
    result <- load_template_from_json(path, use_cache = FALSE)
    skip_if(is.null(result))

    expect_true(nchar(result$name) > 0,
      info = paste(tpl_name, "has empty name"))
    expect_true(nchar(result$description) > 0,
      info = paste(tpl_name, "has empty description"))
    expect_true(result$complexity %in% c("simple", "complex"),
      info = paste(tpl_name, "complexity is not simple/complex:", result$complexity))
  }
})
