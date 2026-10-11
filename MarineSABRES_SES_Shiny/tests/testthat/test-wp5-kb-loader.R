# tests/testthat/test-wp5-kb-loader.R
# Tests for the WP5 mechanism KB loader.
# Mirrors the testing pattern used by tests/testthat/test-knowledge-base.R.

library(testthat)

# Resolve project root the same way test-knowledge-base.R does
.wp5_project_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") return(dirname(dirname(wd)))
  if (file.exists(file.path(wd, "data/ses_knowledge_db_wp5_mechanisms.json"))) return(wd)
  candidate <- dirname(dirname(wd))
  if (file.exists(file.path(candidate, "data/ses_knowledge_db_wp5_mechanisms.json"))) {
    return(candidate)
  }
  return(wd)
}

PROJECT_ROOT_WP5 <- .wp5_project_root()
WP5_KB_PATH      <- file.path(PROJECT_ROOT_WP5, "data", "ses_knowledge_db_wp5_mechanisms.json")
WP5_LOADER_PATH  <- file.path(PROJECT_ROOT_WP5, "functions", "wp5_kb_loader.R")

# Source loader explicitly (helper-00-load-functions.R may not pick this up
# until it's added to global.R's source chain)
.ensure_wp5_loader <- function() {
  if (!exists("load_wp5_mechanisms_kb", mode = "function")) {
    if (file.exists(WP5_LOADER_PATH)) source(WP5_LOADER_PATH, local = FALSE)
  }
}

EXTRACT_PATH_WP5 <- file.path(PROJECT_ROOT_WP5, "scripts", "wp5_kb_sources", "d5.2_v5_mechanism_sources.md")
WP5_SECTIONS <- c("table9_arctic", "table20_tuscan", "table22_macaronesia",
                  "toolkit_annex_table2", "toolkit_references", "scenario_headings")

wp5_clean <- function(s) {
  s <- gsub("**", "", s, fixed = TRUE)
  s <- gsub("<br\\s*/?>", " ", s, perl = TRUE)
  s <- gsub("\\\\(.)", "\\1", s, perl = TRUE)
  trimws(gsub("\\s+", " ", s, perl = TRUE))
}
wp5_sections <- function() {
  txt <- paste(readLines(EXTRACT_PATH_WP5, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  m <- regmatches(txt, gregexpr("(?s)<!-- wp5-extract: (\\w+) -->\\n(.*?)\\n<!-- /wp5-extract -->", txt, perl = TRUE))[[1]]
  setNames(lapply(m, function(x) sub("(?s)^<!-- wp5-extract: \\w+ -->\\n(.*)\\n<!-- /wp5-extract -->$", "\\1", x, perl = TRUE)),
           sub("(?s)^<!-- wp5-extract: (\\w+) -->.*", "\\1", m, perl = TRUE))
}
# Named character vector: names are field paths, values are strings (derived/provenance/source skipped)
wp5_strings <- function(x, path = "", skip = c("id","da","number","provenance","source_ref","derived","reference_numbers","toolkit")) {
  if (is.list(x)) {
    nm <- names(x) %||% as.character(seq_along(x))
    out <- lapply(seq_along(x), function(i) if (nm[i] %in% skip) character() else
      wp5_strings(x[[i]], if (nzchar(path)) paste0(path, ".", nm[i]) else nm[i], skip))
    unlist(out)
  } else if (is.character(x)) setNames(x, rep(path, length(x))) else character()
}

test_that("v2 KB loads with FINAL D5.2 counts (8/7/16) and schema 2", {
  .ensure_wp5_loader()
  kb <- load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  expect_equal(kb$schema, 2L)
  expect_equal(vapply(c("arctic","tuscan","macaronesia"), function(d) length(get_mechanisms_for_da(d)), integer(1)),
               c(arctic = 8L, tuscan = 7L, macaronesia = 16L))
})

test_that("extract parses into all six sections (guards against a silent regex miss)", {
  expect_setequal(names(wp5_sections()), WP5_SECTIONS)
  expect_true(all(nzchar(unlist(wp5_sections()))))
})

test_that("every mechanism string is verbatim in its own source section", {
  kb <- jsonlite::fromJSON(WP5_KB_PATH, simplifyVector = FALSE)
  secs <- lapply(wp5_sections(), wp5_clean)
  hay <- list(arctic = secs$table9_arctic, tuscan = secs$table20_tuscan, macaronesia = secs$table22_macaronesia)
  for (da in names(hay)) for (m in kb$demonstration_areas[[da]]$mechanisms) {
    s <- wp5_strings(m)
    for (i in seq_along(s)) expect_true(grepl(wp5_clean(s[[i]]), hay[[da]], fixed = TRUE),
                                        info = paste0(m$id, ".", names(s)[i]))
    if (!is.null(m$toolkit)) {
      ts <- wp5_strings(m$toolkit, skip = c("provenance","source_ref","reference_numbers"))
      for (i in seq_along(ts)) expect_true(grepl(wp5_clean(ts[[i]]), secs$toolkit_annex_table2, fixed = TRUE),
                                           info = paste0(m$id, ".toolkit.", names(ts)[i]))
    }
  }
})

test_that("provenance and source_ref on every mechanism; toolkit is pre-final; no guidance shipped", {
  kb <- jsonlite::fromJSON(WP5_KB_PATH, simplifyVector = FALSE)
  for (da in names(kb$demonstration_areas)) for (m in kb$demonstration_areas[[da]]$mechanisms) {
    expect_equal(m$provenance, "wp5_source", info = m$id)
    expect_true(nzchar(m$source_ref$document %||% "") && nzchar(m$source_ref$table %||% ""), info = m$id)
    expect_equal(m$derived$provenance, "wp5_derived", info = m$id)
    expect_null(m$use_in_impact_assessment)
    if (!is.null(m$toolkit)) {
      expect_equal(m$toolkit$provenance, "wp5_prefinal", info = m$id)
      expect_false(isTRUE(m$toolkit$source_ref$in_final_d52), info = m$id)
      expect_null(m$toolkit$use_in_impact_assessment)
    }
  }
})

test_that("every Macaronesia cost band is a D5.2 legend band; invented codes absent", {
  kb <- jsonlite::fromJSON(WP5_KB_PATH, simplifyVector = FALSE)
  glyphs <- c("\u20ac", "\u20ac\u20ac", "\u20ac\u20ac\u20ac", "\u20ac\u20ac\u20ac\u20ac")
  for (m in kb$demonstration_areas$macaronesia$mechanisms) {
    parts <- trimws(strsplit(sub("\\*$", "", m$cost_band), "\u2013", fixed = TRUE)[[1]])
    expect_true(length(parts) > 0 && all(parts %in% glyphs), info = m$id)
  }
  raw <- paste(readLines(WP5_KB_PATH, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_false(grepl("\u00a7x\\.x|POS_density", raw))
  expect_length(kb$scenarios$tuscan, 0)
  expect_equal(vapply(kb$scenarios$macaronesia, `[[`, "", "code"), paste0("S", 1:4))
  canon <- c("C_01","C_02","F_01","F_02","F_03","M_01","M_02","T_01","T_02","T_03","T_04")
  codes <- unlist(lapply(kb$demonstration_areas$macaronesia$mechanisms, function(m) unlist(m$derived$success_metrics)))
  expect_true(all(codes %in% canon))
})

test_that("valuation block numeric with band order", {
  .ensure_wp5_loader(); load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  v <- get_valuation_unit_values("posidonia_oceanica")
  expect_equal(length(v), 5L)
  for (s in v) expect_true(s$low <= s$central && s$central <= s$high)
  expect_equal(v$coastal_protection$high, 17200)
})

test_that("v2 accessors: scenarios, cost-band legend, references, provenance", {
  .ensure_wp5_loader(); load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  expect_equal(wp5_kb_schema(), 2L)
  expect_equal(vapply(get_scenarios_for_da("arctic"), `[[`, "", "code"),
               c("no_agreement", "partial_agreement", "full_agreement"))
  expect_length(get_scenarios_for_da("tuscan"), 0)
  expect_match(get_cost_band_legend(), "Cost bands")
  expect_true(nzchar(get_wp5_reference(1)))
  expect_equal(get_wp5_reference(9999), "")
  expect_equal(mechanism_provenance("tus_01", "applicability_text")$provenance, "wp5_source")
  expect_equal(mechanism_provenance("mac_01", "toolkit.design_parameters")$provenance, "wp5_prefinal")
  expect_equal(mechanism_provenance("mac_01", "derived.success_metrics")$provenance, "wp5_derived")
  expect_null(mechanism_provenance("nope_99"))
})

test_that("a v1 KB still loads with a warning; accessors degrade gracefully", {
  .ensure_wp5_loader()
  on.exit(load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE), add = TRUE)
  v1 <- tempfile(fileext = ".json")
  writeLines(jsonlite::toJSON(list(version = "1.0.0", demonstration_areas = list(
    tuscan = list(mechanisms = list(list(id = "tus_01", name = "PES")))),
    valuation_unit_values = list()), auto_unbox = TRUE), v1)
  expect_warning(load_wp5_mechanisms_kb(v1, force_reload = TRUE), "schema 1")
  expect_equal(wp5_kb_schema(), 1L)
  expect_equal(get_mechanisms_for_da("tuscan")[[1]]$id, "tus_01")
  expect_length(get_scenarios_for_da("macaronesia"), 0)
  expect_equal(get_cost_band_legend(), "")
})
