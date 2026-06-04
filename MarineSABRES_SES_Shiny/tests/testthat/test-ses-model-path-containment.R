# test-ses-model-path-containment.R
# Security tests for SES model path containment (M5: arbitrary file read)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Resolve the project root reliably whether run via test_file() or test_dir()
.ses_containment_app_dir <- local({
  d <- tryCatch(
    normalizePath(file.path(testthat::test_path(), "..", ".."),
                  winslash = "/", mustWork = FALSE),
    error = function(e) NULL
  )
  if (is.null(d) || !file.exists(file.path(d, "app.R"))) {
    d <- "C:/Users/arturas.baziukas/OneDrive - ku.lt/HORIZON_EUROPE/Marine-SABRES/SESToolbox/MarineSABRES_SES_Shiny"
  }
  d
})

# Source the module into .GlobalEnv so top-level helpers become available in
# the test environment.  The module uses Shiny/bslib at the top-level only
# inside function bodies, so sourcing it is safe when those packages are loaded
# (which global.R already did via the helper chain).
.source_ses_models_module_once <- local({
  done <- FALSE
  function() {
    if (done) return(invisible(NULL))
    module_path <- file.path(.ses_containment_app_dir, "modules", "ses_models_module.R")
    if (!file.exists(module_path)) {
      warning("ses_models_module.R not found; containment helper tests will skip")
      return(invisible(NULL))
    }
    tryCatch(
      source(module_path, local = FALSE),   # into .GlobalEnv
      error = function(e) warning("Could not source ses_models_module.R: ", e$message)
    )
    done <<- TRUE
    invisible(NULL)
  }
})

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_that("ses_model_path_is_contained exists after sourcing the module", {
  .source_ses_models_module_once()
  expect_true(exists("ses_model_path_is_contained", mode = "function",
                     envir = .GlobalEnv))
})

test_that("a model path inside the models root is accepted", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_contained", mode = "function", envir = .GlobalEnv))

  root   <- tempfile("modelsroot"); dir.create(root)
  inside <- file.path(root, "ok.xlsx"); file.create(inside)
  on.exit(unlink(c(root, inside), recursive = TRUE), add = TRUE)

  expect_true(ses_model_path_is_contained(inside, root))
})

test_that("a model path outside the models root is rejected", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_contained", mode = "function", envir = .GlobalEnv))

  root    <- tempfile("modelsroot"); dir.create(root)
  inside  <- file.path(root, "ok.xlsx");          file.create(inside)
  outside <- tempfile(fileext = ".xlsx");          file.create(outside)
  on.exit(unlink(c(root, inside, outside), recursive = TRUE), add = TRUE)

  expect_true( ses_model_path_is_contained(inside,  root))
  expect_false(ses_model_path_is_contained(outside, root))
})

test_that("path traversal via .. is rejected", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_contained", mode = "function", envir = .GlobalEnv))

  root <- tempfile("modelsroot"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  # file.path(root, "..", "escape.xlsx") normalises to a sibling of root
  escape <- file.path(root, "..", "escape.xlsx")
  expect_false(ses_model_path_is_contained(escape, root))
})

test_that("NULL or empty candidate path is rejected", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_contained", mode = "function", envir = .GlobalEnv))

  root <- tempfile("modelsroot"); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  expect_false(ses_model_path_is_contained(NULL,         root))
  expect_false(ses_model_path_is_contained("",           root))
  expect_false(ses_model_path_is_contained(NA_character_, root))
})

test_that("NULL or empty root causes rejection (fail-closed)", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_contained", mode = "function", envir = .GlobalEnv))

  root   <- tempfile("modelsroot"); dir.create(root)
  inside <- file.path(root, "ok.xlsx"); file.create(inside)
  on.exit(unlink(c(root, inside), recursive = TRUE), add = TRUE)

  expect_false(ses_model_path_is_contained(inside, NULL))
  expect_false(ses_model_path_is_contained(inside, ""))
})

test_that("a scanned-whitelist check rejects an off-whitelist path", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_in_scanned_set", mode = "function",
                     envir = .GlobalEnv))

  root    <- tempfile("modelsroot"); dir.create(root)
  # Use winslash="/" to match what ses_model_path_is_in_scanned_set produces
  # internally (it calls normalizePath(..., winslash="/")).
  allowed <- normalizePath(file.path(root, "valid.xlsx"), winslash = "/", mustWork = FALSE)
  foreign <- normalizePath(tempfile(fileext = ".xlsx"),   winslash = "/", mustWork = FALSE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  expect_true( ses_model_path_is_in_scanned_set(allowed,  c(allowed)))
  expect_false(ses_model_path_is_in_scanned_set(foreign,  c(allowed)))
  expect_false(ses_model_path_is_in_scanned_set(NULL,     c(allowed)))
  expect_false(ses_model_path_is_in_scanned_set(allowed,  character(0)))
})

# Sibling-prefix attack: a dir sharing the root's name prefix must be rejected.
# This locks in the trailing-slash guard in ses_model_path_is_contained.
test_that("sibling directory with shared prefix is rejected (trailing-slash guard)", {
  .source_ses_models_module_once()
  skip_if_not(exists("ses_model_path_is_contained", mode = "function"))
  root    <- tempfile("models"); dir.create(root)
  sibling <- paste0(root, "foo"); dir.create(sibling)   # same prefix, different dir
  evil    <- file.path(sibling, "evil.xlsx"); file.create(evil)
  on.exit(unlink(c(root, sibling), recursive = TRUE), add = TRUE)
  expect_false(ses_model_path_is_contained(evil, root))
})
