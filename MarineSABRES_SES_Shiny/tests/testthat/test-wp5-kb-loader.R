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

test_that("WP5 KB JSON file exists at expected path", {
  expect_true(file.exists(WP5_KB_PATH))
})

test_that("load_wp5_mechanisms_kb() loads without error", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("load_wp5_mechanisms_kb", mode = "function"),
              "load_wp5_mechanisms_kb not available")
  expect_no_error(load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE))
})

test_that("Loaded KB has all 3 demonstration_areas keys", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("load_wp5_mechanisms_kb", mode = "function"),
              "load_wp5_mechanisms_kb not available")
  db <- load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  expect_setequal(names(db$demonstration_areas), c("macaronesia", "tuscan", "arctic"))
})

test_that("valuation_unit_values block is parsed as numeric", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("load_wp5_mechanisms_kb", mode = "function"),
              "load_wp5_mechanisms_kb not available")
  db <- load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  pos <- db$valuation_unit_values$posidonia_oceanica
  expect_true(is.numeric(pos$coastal_protection$low))
  expect_true(is.numeric(pos$coastal_protection$central))
  expect_true(is.numeric(pos$coastal_protection$high))
  expect_true(pos$coastal_protection$low <= pos$coastal_protection$central)
  expect_true(pos$coastal_protection$central <= pos$coastal_protection$high)
})

test_that("get_mechanisms_for_da('macaronesia') returns the seeded entry", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("get_mechanisms_for_da", mode = "function"),
              "get_mechanisms_for_da not available")
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("macaronesia")
  expect_true(length(mechs) >= 1)
  expect_true(any(vapply(mechs, function(m) m$id == "mac_01_blue_corridor_facility", logical(1))))
})

test_that("get_mechanisms_for_da() rejects unknown DA names", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("get_mechanisms_for_da", mode = "function"),
              "get_mechanisms_for_da not available")
  expect_error(get_mechanisms_for_da("atlantis"), "Unknown DA")
})

test_that("get_valuation_unit_values('posidonia_oceanica') returns 5 services", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  skip_if_not(exists("get_valuation_unit_values", mode = "function"),
              "get_valuation_unit_values not available")
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  v <- get_valuation_unit_values("posidonia_oceanica")
  expect_setequal(names(v), c("coastal_protection","carbon_sequestration","recreation_tourism","food_provision","water_purification"))
})

# ==============================================================================
# Reference-pane render-data tests (Task F3)
# ==============================================================================
# These do not exercise the renderUI itself (that requires a Shiny session and
# would require shinytest2 / testServer machinery). Instead they verify the
# data the pane reads is well-formed for every DA — the pane will render
# correctly iff these fields are populated.

test_that("Every Macaronesia mechanism has the fields the reference pane renders", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("macaronesia")
  expect_true(length(mechs) >= 1)
  for (m in mechs) {
    expect_true(nzchar(m$name %||% ""), info = paste("name empty for", m$id %||% "<no-id>"))
    expect_true(nzchar(m$cost_profile %||% ""), info = paste("cost_profile empty for", m$id))
    expect_true(nzchar(m$what_it_funds %||% ""), info = paste("what_it_funds empty for", m$id))
    expect_true(length(m$finance_flow$payer %||% character(0)) >= 1,
                info = paste("finance_flow.payer empty for", m$id))
    expect_true(nzchar(m$finance_flow$receiver %||% ""),
                info = paste("finance_flow.receiver empty for", m$id))
    expect_true(nzchar(m$use_in_impact_assessment %||% ""),
                info = paste("use_in_impact_assessment empty for", m$id))
  }
})

test_that("Every Tuscan mechanism has the fields the reference pane renders", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("tuscan")
  expect_true(length(mechs) >= 1)
  for (m in mechs) {
    expect_true(nzchar(m$name %||% ""), info = paste("name empty for", m$id %||% "<no-id>"))
    expect_true(nzchar(m$cost_profile %||% ""), info = paste("cost_profile empty for", m$id))
    expect_true(nzchar(m$what_it_funds %||% ""), info = paste("what_it_funds empty for", m$id))
    expect_true(length(m$finance_flow$payer %||% character(0)) >= 1,
                info = paste("finance_flow.payer empty for", m$id))
    expect_true(nzchar(m$finance_flow$receiver %||% ""),
                info = paste("finance_flow.receiver empty for", m$id))
  }
})

test_that("Every Arctic mechanism has the fields the reference pane renders", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("arctic")
  expect_true(length(mechs) >= 1)
  for (m in mechs) {
    expect_true(nzchar(m$name %||% ""), info = paste("name empty for", m$id %||% "<no-id>"))
    expect_true(nzchar(m$cost_profile %||% ""), info = paste("cost_profile empty for", m$id))
    expect_true(nzchar(m$what_it_funds %||% ""), info = paste("what_it_funds empty for", m$id))
    expect_true(length(m$finance_flow$payer %||% character(0)) >= 1,
                info = paste("finance_flow.payer empty for", m$id))
    expect_true(nzchar(m$finance_flow$receiver %||% ""),
                info = paste("finance_flow.receiver empty for", m$id))
  }
})

test_that("get_mechanisms_for_da('arctic') returns at least the cost-recovery sample", {
  skip_if_not(file.exists(WP5_KB_PATH), "ses_knowledge_db_wp5_mechanisms.json not found")
  .ensure_wp5_loader()
  load_wp5_mechanisms_kb(WP5_KB_PATH, force_reload = TRUE)
  mechs <- get_mechanisms_for_da("arctic")
  ids <- vapply(mechs, function(m) m$id %||% "", character(1))
  expect_true("arc_01_cost_recovery_fees" %in% ids)
})
