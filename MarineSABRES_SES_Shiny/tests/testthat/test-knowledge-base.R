# tests/testthat/test-knowledge-base.R
# Comprehensive test suite for the MarineSABRES SES Knowledge Base
# Tests cover: structure, data quality, cross-contamination, geographic
# consistency, API functions, governance DB, and KB-report integration.
# ==============================================================================

library(testthat)

# ==============================================================================
# Helper: resolve project root and file paths
# ==============================================================================

.kb_project_root <- function() {
  wd <- getwd()
  # When run via testthat::test_file() from project root or tests/testthat/
  if (basename(wd) == "testthat") {
    return(dirname(dirname(wd)))
  }
  # When run from project root
  if (file.exists(file.path(wd, "data/ses_knowledge_db.json"))) {
    return(wd)
  }
  # Fallback: climb up
  candidate <- dirname(dirname(wd))
  if (file.exists(file.path(candidate, "data/ses_knowledge_db.json"))) {
    return(candidate)
  }
  return(wd)
}

PROJECT_ROOT_KB <- .kb_project_root()
KB_PATH         <- file.path(PROJECT_ROOT_KB, "data", "ses_knowledge_db.json")
GOV_PATH        <- file.path(PROJECT_ROOT_KB, "data", "country_governance_db.json")

# Load once at file scope for data-quality tests (raw JSON access)
.kb_raw <- NULL
.gov_raw <- NULL

if (file.exists(KB_PATH)) {
  tryCatch(
    .kb_raw <- jsonlite::fromJSON(KB_PATH, simplifyVector = FALSE),
    error = function(e) message("KB parse error: ", e$message)
  )
}
if (file.exists(GOV_PATH)) {
  tryCatch(
    .gov_raw <- jsonlite::fromJSON(GOV_PATH, simplifyVector = FALSE),
    error = function(e) message("Gov DB parse error: ", e$message)
  )
}

# Source loader functions with stubs (only if not already in global env from setup.R)
.ensure_kb_functions <- function() {
  if (!exists("load_ses_knowledge_db", mode = "function")) {
    if (!exists("%||%", mode = "function")) {
      `%||%` <<- function(a, b) if (!is.null(a)) a else b
    }
    if (!exists("debug_log", mode = "function")) {
      debug_log <<- function(...) invisible(NULL)
    }
    tryCatch(
      source(file.path(PROJECT_ROOT_KB, "functions/ses_knowledge_db_loader.R"),
             local = FALSE),
      error = function(e) message("Could not source ses_knowledge_db_loader.R: ", e$message)
    )
  }
  if (exists("load_ses_knowledge_db", mode = "function")) {
    load_ses_knowledge_db(KB_PATH, force_reload = TRUE)
  }
}

.ensure_gov_functions <- function() {
  if (!exists("load_country_governance_db", mode = "function")) {
    if (!exists("%||%", mode = "function")) {
      `%||%` <<- function(a, b) if (!is.null(a)) a else b
    }
    if (!exists("debug_log", mode = "function")) {
      debug_log <<- function(...) invisible(NULL)
    }
    tryCatch(
      source(file.path(PROJECT_ROOT_KB, "functions/country_governance_loader.R"),
             local = FALSE),
      error = function(e) message("Could not source country_governance_loader.R: ", e$message)
    )
  }
  if (exists("load_country_governance_db", mode = "function")) {
    load_country_governance_db(GOV_PATH, force_reload = TRUE)
  }
}

.ensure_kb_report_functions <- function() {
  .ensure_kb_functions()
  .ensure_gov_functions()
  if (!exists("get_kb_context_for_report", mode = "function")) {
    tryCatch(
      source(file.path(PROJECT_ROOT_KB, "functions/kb_report_helpers.R"),
             local = FALSE),
      error = function(e) message("Could not source kb_report_helpers.R: ", e$message)
    )
  }
}


# ==============================================================================
# 1. KB Structure & Loading
# ==============================================================================

test_that("KB file exists at expected path", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  expect_true(file.exists(KB_PATH))
})

test_that("KB file is valid JSON", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  result <- tryCatch(
    jsonlite::fromJSON(KB_PATH, simplifyVector = FALSE),
    error = function(e) NULL
  )
  expect_false(is.null(result), info = "fromJSON returned NULL — file may be malformed JSON")
})

test_that("KB has expected version field", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  expect_true(!is.null(.kb_raw$version))
  expect_true(nchar(.kb_raw$version) > 0)
})

test_that("KB has exactly 33 contexts", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  expect_equal(length(.kb_raw$contexts), 33)
})

test_that("All context keys follow the {sea}_{habitat} naming pattern", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  ctx_keys <- names(.kb_raw$contexts)
  # Must contain at least one underscore separating sea from habitat
  all_valid <- all(grepl("^[a-z][a-z_]+_[a-z][a-z_]+$", ctx_keys))
  expect_true(all_valid,
    info = paste("Invalid keys:", paste(ctx_keys[!grepl("^[a-z][a-z_]+_[a-z][a-z_]+$", ctx_keys)], collapse = ", ")))
})

test_that("load_ses_knowledge_db() loads without error", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("load_ses_knowledge_db", mode = "function"),
              "load_ses_knowledge_db not available")
  expect_no_error(load_ses_knowledge_db(KB_PATH, force_reload = TRUE))
})

test_that("ses_knowledge_db_available() returns TRUE after loading", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("ses_knowledge_db_available", mode = "function"),
              "ses_knowledge_db_available not available")
  expect_true(ses_knowledge_db_available())
})

test_that("get_available_contexts() returns 30 context keys", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_available_contexts", mode = "function"),
              "get_available_contexts not available")
  ctx <- get_available_contexts()
  expect_equal(length(ctx), 33)
  expect_type(ctx, "character")
})


# ==============================================================================
# 2. Context Data Completeness
# ==============================================================================

test_that("Every context has a non-empty description field", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  missing_desc <- vapply(names(contexts), function(k) {
    d <- contexts[[k]]$description
    is.null(d) || nchar(trimws(d)) == 0
  }, logical(1))
  bad <- names(contexts)[missing_desc]
  expect_true(length(bad) == 0,
    info = paste("Contexts missing description:", paste(bad, collapse = ", ")))
})

test_that("Every context has a connections array with at least 30 connections", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  counts <- vapply(names(contexts), function(k) {
    length(contexts[[k]]$connections %||% list())
  }, integer(1))
  bad <- names(contexts)[counts < 30]
  expect_true(length(bad) == 0,
    info = paste("Contexts with <30 connections:", paste(bad, collapse = ", ")))
})

test_that("Every context has regional_sea and habitat fields", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  missing <- vapply(names(contexts), function(k) {
    ctx <- contexts[[k]]
    is.null(ctx$regional_sea) || is.null(ctx$habitat)
  }, logical(1))
  bad <- names(contexts)[missing]
  expect_true(length(bad) == 0,
    info = paste("Contexts missing regional_sea or habitat:", paste(bad, collapse = ", ")))
})


# ==============================================================================
# 3. Connection Data Quality
# ==============================================================================

# Build a flat list of all (context_name, connection_index, connection) triples
# once for reuse in quality tests
.all_connections <- local({
  if (is.null(.kb_raw)) return(list())
  contexts <- .kb_raw$contexts
  result <- list()
  for (ctx_name in names(contexts)) {
    conns <- contexts[[ctx_name]]$connections %||% list()
    for (i in seq_along(conns)) {
      result[[length(result) + 1]] <- list(ctx = ctx_name, idx = i, conn = conns[[i]])
    }
  }
  result
})

test_that("Every connection has required fields: from, to, polarity, confidence, rationale, references", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  required_fields <- c("from", "to", "polarity", "confidence", "rationale", "references")
  bad <- character(0)
  for (item in .all_connections) {
    missing <- required_fields[!required_fields %in% names(item$conn)]
    if (length(missing) > 0) {
      bad <- c(bad, sprintf("%s[%d]: missing %s", item$ctx, item$idx,
                            paste(missing, collapse = ",")))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Connections missing required fields:", paste(head(bad, 5), collapse = "; ")))
})

test_that("All polarity values are '+' or '-'", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  bad <- character(0)
  for (item in .all_connections) {
    pol <- item$conn$polarity
    if (is.null(pol) || !pol %in% c("+", "-")) {
      bad <- c(bad, sprintf("%s[%d]: polarity='%s'", item$ctx, item$idx,
                            if (is.null(pol)) "NULL" else pol))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Invalid polarity:", paste(head(bad, 5), collapse = "; ")))
})

test_that("All confidence values are integers 1-5", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  bad <- character(0)
  for (item in .all_connections) {
    conf <- item$conn$confidence
    if (is.null(conf) || !is.numeric(conf) || conf < 1 || conf > 5 ||
        conf != round(conf)) {
      bad <- c(bad, sprintf("%s[%d]: confidence=%s",
                            item$ctx, item$idx,
                            if (is.null(conf)) "NULL" else as.character(conf)))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Invalid confidence:", paste(head(bad, 5), collapse = "; ")))
})

test_that("All rationale strings are at least 20 characters", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  bad <- character(0)
  for (item in .all_connections) {
    rat <- item$conn$rationale
    if (is.null(rat) || nchar(rat) < 20) {
      bad <- c(bad, sprintf("%s[%d]: rationale_len=%d",
                            item$ctx, item$idx,
                            if (is.null(rat)) 0L else nchar(rat)))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Short/missing rationale:", paste(head(bad, 5), collapse = "; ")))
})

test_that("All references arrays have at least 2 entries", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  bad <- character(0)
  for (item in .all_connections) {
    refs <- item$conn$references
    if (is.null(refs) || length(refs) < 2) {
      bad <- c(bad, sprintf("%s[%d]: n_refs=%d",
                            item$ctx, item$idx,
                            if (is.null(refs)) 0L else length(refs)))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Connections with <2 references:", paste(head(bad, 5), collapse = "; ")))
})

test_that("All temporal_lag values are valid (immediate/short-term/medium-term/long-term)", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  valid_lags <- c("immediate", "short-term", "medium-term", "long-term")
  bad <- character(0)
  for (item in .all_connections) {
    tl <- item$conn$temporal_lag
    if (is.null(tl) || !tl %in% valid_lags) {
      bad <- c(bad, sprintf("%s[%d]: temporal_lag='%s'",
                            item$ctx, item$idx,
                            if (is.null(tl)) "NULL" else tl))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Invalid temporal_lag:", paste(head(bad, 5), collapse = "; ")))
})

test_that("All reversibility values are valid (reversible/partially_reversible/irreversible)", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  valid_rev <- c("reversible", "partially_reversible", "irreversible")
  bad <- character(0)
  for (item in .all_connections) {
    rev <- item$conn$reversibility
    if (is.null(rev) || !rev %in% valid_rev) {
      bad <- c(bad, sprintf("%s[%d]: reversibility='%s'",
                            item$ctx, item$idx,
                            if (is.null(rev)) "NULL" else rev))
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Invalid reversibility:", paste(head(bad, 5), collapse = "; ")))
})

test_that("No duplicate connections (same from+to) within any context", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  dup_contexts <- character(0)
  for (ctx_name in names(contexts)) {
    conns <- contexts[[ctx_name]]$connections %||% list()
    pairs <- vapply(conns, function(conn) {
      paste(conn$from %||% "", "->", conn$to %||% "")
    }, character(1))
    dups <- pairs[duplicated(pairs)]
    if (length(dups) > 0) {
      dup_contexts <- c(dup_contexts,
                        sprintf("%s: %s", ctx_name, paste(dups, collapse = "; ")))
    }
  }
  expect_true(length(dup_contexts) == 0,
    info = paste("Duplicate from+to in:", paste(head(dup_contexts, 3), collapse = " | ")))
})


# ==============================================================================
# 4. Cross-Contamination Check
# ==============================================================================

# Helper: collect all text fields from all connections in one context
.get_context_text <- function(ctx) {
  conns <- ctx$connections %||% list()
  texts <- vapply(conns, function(conn) {
    paste(
      conn$from      %||% "",
      conn$to        %||% "",
      conn$rationale %||% "",
      paste(unlist(conn$references %||% list()), collapse = " "),
      collapse = " "
    )
  }, character(1))
  paste(texts, collapse = " ")
}

test_that("No Baltic-specific references in non-Baltic contexts", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  baltic_markers <- c("HELCOM", "Elmgren", "Snoeijs-Leijonmalm")
  bad <- character(0)
  non_baltic <- names(contexts)[!startsWith(names(contexts), "baltic")]
  for (ctx_name in non_baltic) {
    text <- .get_context_text(contexts[[ctx_name]])
    for (marker in baltic_markers) {
      if (grepl(marker, text, fixed = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, marker))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Baltic contamination:", paste(bad, collapse = "; ")))
})

test_that("No Arctic-specific references in non-Arctic contexts", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  arctic_markers <- c("AMAP", "Wassmann")
  bad <- character(0)
  non_arctic <- names(contexts)[!startsWith(names(contexts), "arctic")]
  for (ctx_name in non_arctic) {
    text <- .get_context_text(contexts[[ctx_name]])
    for (marker in arctic_markers) {
      # Use word-boundary to avoid false positives
      pattern <- paste0("\\b", marker, "\\b")
      if (grepl(pattern, text, perl = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, marker))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Arctic contamination:", paste(bad, collapse = "; ")))
})

test_that("No Caribbean-specific references in non-Caribbean contexts", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  carib_markers <- c("Status and Trends of Caribbean")
  bad <- character(0)
  non_carib <- names(contexts)[!startsWith(names(contexts), "caribbean")]
  for (ctx_name in non_carib) {
    text <- .get_context_text(contexts[[ctx_name]])
    for (marker in carib_markers) {
      if (grepl(marker, text, fixed = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, marker))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Caribbean contamination:", paste(bad, collapse = "; ")))
})

test_that("No Mediterranean-specific references in non-Mediterranean contexts", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  med_markers <- c("biodiversity of the Mediterranean")
  bad <- character(0)
  non_med <- names(contexts)[!startsWith(names(contexts), "mediterranean")]
  for (ctx_name in non_med) {
    text <- .get_context_text(contexts[[ctx_name]])
    for (marker in med_markers) {
      if (grepl(marker, text, fixed = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, marker))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Mediterranean contamination:", paste(bad, collapse = "; ")))
})


# ==============================================================================
# 5. Geographic Consistency
# ==============================================================================

# Helper: get all connection field text (lower-cased) for a context
.get_context_text_lower <- function(ctx) {
  tolower(.get_context_text(ctx))
}

test_that("North Sea contexts don't contain 'black sea' or 'danube'", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  ns_contexts <- names(contexts)[startsWith(names(contexts), "north_sea")]
  bad_terms <- c("black sea", "danube")
  bad <- character(0)
  for (ctx_name in ns_contexts) {
    text <- .get_context_text_lower(contexts[[ctx_name]])
    for (term in bad_terms) {
      pattern <- paste0("\\b", term, "\\b")
      if (grepl(pattern, text, perl = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, term))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("North Sea geo issue:", paste(bad, collapse = "; ")))
})

test_that("Baltic contexts don't contain 'caribbean' or 'bosphorus'", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  baltic_contexts <- names(contexts)[startsWith(names(contexts), "baltic")]
  bad_terms <- c("caribbean", "bosphorus")
  bad <- character(0)
  for (ctx_name in baltic_contexts) {
    text <- .get_context_text_lower(contexts[[ctx_name]])
    for (term in bad_terms) {
      pattern <- paste0("\\b", term, "\\b")
      if (grepl(pattern, text, perl = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, term))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Baltic geo issue:", paste(bad, collapse = "; ")))
})

test_that("Mediterranean contexts don't contain 'danube' or 'bosphorus'", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  med_contexts <- names(contexts)[startsWith(names(contexts), "mediterranean")]
  bad_terms <- c("danube", "bosphorus")
  bad <- character(0)
  for (ctx_name in med_contexts) {
    text <- .get_context_text_lower(contexts[[ctx_name]])
    for (term in bad_terms) {
      pattern <- paste0("\\b", term, "\\b")
      if (grepl(pattern, text, perl = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, term))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Mediterranean geo issue:", paste(bad, collapse = "; ")))
})

test_that("Caribbean contexts don't contain 'baltic', 'north sea', or 'black sea'", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  carib_contexts <- names(contexts)[startsWith(names(contexts), "caribbean")]
  bad_terms <- c("baltic", "north sea", "black sea")
  bad <- character(0)
  for (ctx_name in carib_contexts) {
    text <- .get_context_text_lower(contexts[[ctx_name]])
    for (term in bad_terms) {
      pattern <- paste0("\\b", term, "\\b")
      if (grepl(pattern, text, perl = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, term))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Caribbean geo issue:", paste(bad, collapse = "; ")))
})


test_that("Macaronesia contexts don't contain 'baltic', 'north sea', 'danube', or 'black sea'", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  mac_contexts <- names(contexts)[startsWith(names(contexts), "macaronesia")]
  expect_true(length(mac_contexts) >= 3, info = "Must have at least 3 Macaronesia contexts")
  bad_terms <- c("baltic", "north sea", "black sea", "danube", "bosphorus", "helcom")
  bad <- character(0)
  for (ctx_name in mac_contexts) {
    text <- .get_context_text_lower(contexts[[ctx_name]])
    for (term in bad_terms) {
      pattern <- paste0("\\b", term, "\\b")
      if (grepl(pattern, text, perl = TRUE)) {
        bad <- c(bad, sprintf("%s contains '%s'", ctx_name, term))
      }
    }
  }
  expect_true(length(bad) == 0,
    info = paste("Macaronesia geo issue:", paste(bad, collapse = "; ")))
})

test_that("Macaronesia contexts have Macaronesia-specific content", {
  skip_if_not(!is.null(.kb_raw), "KB not loaded")
  contexts <- .kb_raw$contexts
  mac_contexts <- names(contexts)[startsWith(names(contexts), "macaronesia")]
  for (ctx_name in mac_contexts) {
    text <- .get_context_text_lower(contexts[[ctx_name]])
    has_mac_terms <- grepl("azores|canary|canaries|madeira|cape verde|macaronesia", text, perl = TRUE)
    expect_true(has_mac_terms,
      info = paste(ctx_name, "must reference Macaronesian locations"))
  }
})

# ==============================================================================
# 6. KB API Functions
# ==============================================================================

test_that("get_context_elements('baltic', 'lagoon', 'drivers') returns non-empty character vector", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_elements", mode = "function"),
              "get_context_elements not available")
  result <- get_context_elements("baltic", "lagoon", "drivers")
  expect_type(result, "character")
  expect_gt(length(result), 0L)
})

test_that("get_context_elements('baltic', 'lagoon', 'activities') returns non-empty character vector", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_elements", mode = "function"),
              "get_context_elements not available")
  result <- get_context_elements("baltic", "lagoon", "activities")
  expect_type(result, "character")
  expect_gt(length(result), 0L)
})

test_that("get_context_connections('baltic', 'lagoon') returns list with 30+ connections", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_connections", mode = "function"),
              "get_context_connections not available")
  result <- get_context_connections("baltic", "lagoon")
  expect_type(result, "list")
  expect_gte(length(result), 30L)
})

test_that("get_context_connections('mediterranean', 'seagrass') returns list with 30+ connections", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_connections", mode = "function"),
              "get_context_connections not available")
  result <- get_context_connections("mediterranean", "seagrass")
  expect_type(result, "list")
  expect_gte(length(result), 30L)
})

test_that("Each returned connection has from, to, polarity, rationale, references fields", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_connections", mode = "function"),
              "get_context_connections not available")
  conns <- get_context_connections("baltic", "lagoon")
  skip_if(length(conns) == 0, "No connections returned")
  required <- c("from", "to", "polarity", "rationale", "references")
  for (req in required) {
    expect_true(req %in% names(conns[[1]]),
                info = paste("First connection missing field:", req))
  }
})

test_that("get_context_elements with min_relevance=0.9 returns fewer results than min_relevance=0.0", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_elements", mode = "function"),
              "get_context_elements not available")
  all_el  <- get_context_elements("baltic", "lagoon", "drivers", min_relevance = 0.0)
  high_el <- get_context_elements("baltic", "lagoon", "drivers", min_relevance = 0.9)
  expect_lte(length(high_el), length(all_el))
})

test_that("Unknown context returns empty result gracefully (no crash)", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_functions()
  skip_if_not(exists("get_context_connections", mode = "function"),
              "get_context_connections not available")
  expect_no_error({
    result <- get_context_connections("unknown_sea_xyz", "unknown_habitat_xyz")
  })
  result <- get_context_connections("unknown_sea_xyz", "unknown_habitat_xyz")
  # Should return empty list or character(0), not crash
  expect_true(length(result) == 0)
})


# ==============================================================================
# 7. Governance DB
# ==============================================================================

test_that("Governance DB file exists at expected path", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  expect_true(file.exists(GOV_PATH))
})

test_that("Governance DB file is valid JSON", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  result <- tryCatch(
    jsonlite::fromJSON(GOV_PATH, simplifyVector = FALSE),
    error = function(e) NULL
  )
  expect_false(is.null(result),
    info = "fromJSON returned NULL — file may be malformed JSON")
})

test_that("get_countries_for_sea('baltic') returns 5+ country records", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  .ensure_gov_functions()
  skip_if_not(exists("get_countries_for_sea", mode = "function"),
              "get_countries_for_sea not available")
  result <- get_countries_for_sea("baltic")
  expect_gte(length(result), 5L)
})

test_that("Each country record has: code, name_en, regional_conventions", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  .ensure_gov_functions()
  skip_if_not(exists("get_countries_for_sea", mode = "function"),
              "get_countries_for_sea not available")
  countries <- get_countries_for_sea("baltic")
  skip_if(length(countries) == 0, "No countries returned for 'baltic'")
  required_fields <- c("code", "name_en", "regional_conventions")
  first <- countries[[1]]
  for (req in required_fields) {
    expect_true(req %in% names(first),
                info = paste("Country record missing field:", req))
  }
})

test_that("get_countries_for_sea('nonexistent') returns empty list without crashing", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  .ensure_gov_functions()
  skip_if_not(exists("get_countries_for_sea", mode = "function"),
              "get_countries_for_sea not available")
  expect_no_error({
    result <- get_countries_for_sea("nonexistent_sea_xyz")
  })
  result <- get_countries_for_sea("nonexistent_sea_xyz")
  expect_equal(length(result), 0L)
})

test_that("All 8 mapped regional seas have countries in governance DB", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  .ensure_gov_functions()
  skip_if_not(exists("get_countries_for_sea", mode = "function"),
              "get_countries_for_sea not available")
  # The spec says "atlantic (as east_atlantic)" — DB uses "east_atlantic" key
  mapped_seas <- c("baltic", "north_sea", "east_atlantic", "mediterranean",
                   "black_sea", "arctic", "caribbean", "pacific")
  for (sea in mapped_seas) {
    result <- get_countries_for_sea(sea)
    expect_gt(length(result), 0L,
              label = paste("Sea has no countries:", sea))
  }
})


# ==============================================================================
# 8. KB-Report Integration
# ==============================================================================

test_that("get_kb_context_for_report('baltic', 'lagoon') returns available=TRUE", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_report_functions()
  skip_if_not(exists("get_kb_context_for_report", mode = "function"),
              "get_kb_context_for_report not available")
  result <- get_kb_context_for_report("baltic", "lagoon")
  expect_true(isTRUE(result$available))
})

test_that("get_kb_context_for_report result has non-empty description and top_elements", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_report_functions()
  skip_if_not(exists("get_kb_context_for_report", mode = "function"),
              "get_kb_context_for_report not available")
  result <- get_kb_context_for_report("baltic", "lagoon")
  skip_if_not(isTRUE(result$available), "Context not available")
  expect_gt(nchar(trimws(result$description %||% "")), 0L)
  expect_gt(length(result$top_elements %||% list()), 0L)
})

test_that("get_governance_context('baltic') returns available=TRUE with frameworks", {
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  .ensure_kb_report_functions()
  skip_if_not(exists("get_governance_context", mode = "function"),
              "get_governance_context not available")
  result <- get_governance_context("baltic")
  expect_true(isTRUE(result$available))
  expect_gt(length(result$frameworks %||% character(0)), 0L)
})

test_that("match_user_connections_to_kb with known element names returns some kb_matched=TRUE", {
  skip_if_not(file.exists(KB_PATH), "ses_knowledge_db.json not found")
  .ensure_kb_report_functions()
  skip_if_not(exists("match_user_connections_to_kb", mode = "function"),
              "match_user_connections_to_kb not available")
  skip_if_not(exists("get_context_connections", mode = "function"),
              "get_context_connections not available")

  # Use actual KB element names from baltic lagoon so at least one should match
  conns <- get_context_connections("baltic", "lagoon")
  skip_if(length(conns) == 0, "No KB connections available")

  c1 <- conns[[1]]
  user_edges <- data.frame(
    from_label = c(c1$from %||% "A", "Nonexistent Source XYZ"),
    to_label   = c(c1$to   %||% "B", "Nonexistent Target XYZ"),
    stringsAsFactors = FALSE
  )

  result <- match_user_connections_to_kb(user_edges, "baltic", "lagoon")
  expect_true(is.data.frame(result))
  expect_true("kb_matched" %in% names(result))
  expect_true(any(result$kb_matched == TRUE))
})

test_that("format_kb_section_for_report produces non-empty Markdown with expected headings", {
  skip_if_not(file.exists(KB_PATH),  "ses_knowledge_db.json not found")
  skip_if_not(file.exists(GOV_PATH), "country_governance_db.json not found")
  .ensure_kb_report_functions()
  skip_if_not(exists("get_kb_context_for_report",    mode = "function"),
              "get_kb_context_for_report not available")
  skip_if_not(exists("get_governance_context",       mode = "function"),
              "get_governance_context not available")
  skip_if_not(exists("format_kb_section_for_report", mode = "function"),
              "format_kb_section_for_report not available")

  kb_ctx <- get_kb_context_for_report("baltic", "lagoon")
  gov    <- get_governance_context("baltic")

  md <- format_kb_section_for_report(kb_ctx, NULL, gov)

  expect_type(md, "character")
  expect_gt(nchar(md), 0L)
  expect_true(grepl("Site Ecological Context", md, fixed = TRUE),
              info = "Markdown missing 'Site Ecological Context' heading")
  expect_true(grepl("Key DAPSI", md, fixed = TRUE),
              info = "Markdown missing 'Key DAPSI' heading")
  expect_true(grepl("Governance Frameworks", md, fixed = TRUE),
              info = "Markdown missing 'Governance Frameworks' heading")
})
