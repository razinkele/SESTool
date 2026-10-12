# tests/testthat/test-impact-assessment-storage.R
# WS-6a: data$analysis$impact_assessment survives every load path unchanged.
library(testthat)

load_wp5_mechanisms_kb(file.path(PROJECT_ROOT, "data", "ses_knowledge_db_wp5_mechanisms.json"),
                       force_reload = TRUE)
load_impact_reference(file.path(PROJECT_ROOT, "data", "wp5_impact_reference.json"), force_reload = TRUE)

build_ia <- function() {
  ia <- impact_assessment_from_reference("macaronesia")
  ia <- impact_copy_reference_cell(ia, "EE", "S3")
  cl <- impact_get_cell(ia, "EQ", "S4")
  cl$direction <- "increase"; cl$magnitude <- "substantial"; cl$timing <- "long"
  cl$confidence <- "low"; cl$uncertainty_driver <- "implementation_dependency"
  cl$evidence <- c("literature", "stakeholder")
  cl$rationale <- "Needs compensation – €0.25–1m/yr band"
  cl$subdimension_notes <- list(distributional = "Small islands", recognitional = "")
  cl$indicator_roles <- list(C_01 = "primary", T_01 = "supporting")
  cl$mechanism_ids <- "mac_01"
  ia <- impact_set_cell(ia, "EQ", "S4", cl)
  one <- new_impact_cell(); one$evidence <- "dataset"; one$direction <- "no_change"
  ia <- impact_update_scenario(ia, "S3", description = "Coordinated corridor management",
                               dimensions = list(governance_form = "EEZ coordination", financing_capacity = "EU funds"))
  ia <- impact_set_cell(ia, "FF", "S2", one)                 # length-1 arrays are unboxed by toJSON
  ia <- impact_set_section(ia, "characterisation", list(focal_issue = "Migratory corridor", stakeholders = "Fishers; tour operators"))
  ia <- impact_set_section(ia, "uncertainty", list(notes = "Compliance in ABNJ"))
  ia <- impact_set_section(ia, "trade_offs", list(text = "S4: equity vs cost"))
  ia <- impact_set_section(ia, "recommendations", list(text = "Pilot S3 first"))
  ia <- impact_set_scope_items(ia, element_ids = c("P001", "C003"), indicator_codes = "C_01")
  impact_set_displacement(ia, "yes", "Effort may move to ABNJ waters", displaced_pressure_id = "P012")
}
project_with_ia <- function() set_impact_assessment(create_empty_project("WS-6a round trip"), build_ia())

test_that("set stamps min_app_version 1.25.0 and never lowers it; NULL removes without stamping", {
  p <- project_with_ia()
  expect_identical(p$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
  newer <- create_empty_project("newer"); newer$min_app_version <- "9.0.0"
  expect_identical(set_impact_assessment(newer, build_ia())$min_app_version, "9.0.0")
  plain <- create_empty_project("plain")
  cleared <- set_impact_assessment(plain, NULL)
  expect_null(get_impact_assessment(cleared))
  expect_identical(cleared$min_app_version, plain$min_app_version)
})

test_that("the normaliser is idempotent on the canonical form", {
  ia <- build_ia()
  expect_identical(normalize_impact_assessment(ia), ia)
})

test_that(".json load (simplifyVector = TRUE) round-trips exactly", {
  p <- project_with_ia()
  f <- tempfile(fileext = ".json")
  export_project_json(p, f)
  out <- normalize_json_project_data(jsonlite::fromJSON(f, simplifyVector = TRUE))
  expect_identical(get_impact_assessment(out), get_impact_assessment(p))
  expect_identical(out$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
})

test_that("local-storage / language-switch load (simplifyVector = FALSE) round-trips exactly", {
  p <- project_with_ia()
  f <- tempfile(fileext = ".json")
  export_project_json(p, f)
  out <- normalize_json_project_data(jsonlite::fromJSON(f, simplifyVector = FALSE))
  expect_identical(get_impact_assessment(out), get_impact_assessment(p))
})

test_that(".rds save/load round-trips exactly", {
  p <- project_with_ia()
  f <- tempfile(fileext = ".rds")
  saveRDS(p, f)
  out <- normalize_json_project_data(readRDS(f))
  expect_identical(get_impact_assessment(out), get_impact_assessment(p))
})

test_that("an older project (1.21.1 fixture) loads unchanged and can gain an assessment", {
  fx <- test_path("fixtures", "project_1_21_1_minimal.json")
  old <- normalize_json_project_data(jsonlite::fromJSON(fx, simplifyVector = TRUE))
  expect_null(get_impact_assessment(old))
  expect_identical(old$version, "1.21.1")
  expect_identical(old$min_app_version, "1.12.0")
  upd <- set_impact_assessment(old, build_ia())
  f <- tempfile(fileext = ".json")
  export_project_json(upd, f)
  back <- normalize_json_project_data(jsonlite::fromJSON(f, simplifyVector = TRUE))
  expect_identical(get_impact_assessment(back), build_ia())
  expect_identical(back$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
})

test_that("orphan cells are dropped and aliases resolve on load", {
  raw <- build_ia()
  raw$cells$EE$S9 <- raw$cells$EE$S3                         # scenario S9 does not exist
  raw$cells$PO <- raw$cells$EQ; raw$cells$EQ <- NULL          # alias key from fiche-derived data
  out <- normalize_impact_assessment(raw)
  expect_identical(names(out$cells$EE), "S3")
  expect_true("PI" %in% names(out$cells))
  expect_false("PO" %in% names(out$cells))
})

test_that("a malformed block is dropped and the project still loads", {
  for (bad in list("oops", 42, list(1, 2))) {
    p <- create_empty_project("bad")
    p$data$analysis$impact_assessment <- bad
    out <- normalize_json_project_data(p)
    expect_null(get_impact_assessment(out))
    expect_identical(out$project_name, "bad")
  }
  expect_identical(normalize_impact_assessment(list(da = "baltic", baseline_code = "S1"))$da, "")
})

test_that("a malformed field inside a valid block drops only that field", {
  for (bad_scope in list("x", 5, list(displacement = "yes"))) {
    p <- project_with_ia()
    p$data$analysis$impact_assessment$scope <- bad_scope
    out <- normalize_json_project_data(p)
    ia <- get_impact_assessment(out)
    expect_false(is.null(ia))
    expect_identical(ia$scope$displacement$answer, "")
    expect_identical(ia$scope$element_ids, character(0))
    expect_identical(impact_scenario_codes(ia), paste0("S", 1:4))   # the rest survives
  }
  p <- project_with_ia()
  p$data$analysis$impact_assessment$characterisation <- "not a section"
  p$data$analysis$impact_assessment$cells$EQ$S4$subdimension_notes <- "loose text"
  ia <- get_impact_assessment(normalize_json_project_data(p))
  expect_identical(ia$characterisation$focal_issue, "")
  expect_identical(ia$cells$EQ$S4$subdimension_notes, setNames(list(), character(0)))
  expect_identical(ia$cells$EQ$S4$direction, "increase")
})

test_that("storing a malformed block is an error and leaves the project untouched (I1)", {
  p <- project_with_ia()
  for (bad in list("garbage", list(1, 2))) {
    code <- tryCatch({ set_impact_assessment(p, bad); NA_character_ }, impact_error = function(e) e$code)
    expect_identical(code, "malformed_assessment")
  }
  expect_identical(get_impact_assessment(p), build_ia())
  expect_identical(p$min_app_version, WP5_IMPACT_MIN_APP_VERSION)
  fresh <- create_empty_project("fresh")
  before <- fresh$min_app_version
  code <- tryCatch({ set_impact_assessment(fresh, "garbage"); NA_character_ }, impact_error = function(e) e$code)
  expect_identical(code, "malformed_assessment")
  expect_identical(fresh$min_app_version, before)
})

test_that("scenario description and dimensions survive the round trips (I5)", {
  s3 <- get_impact_assessment(project_with_ia())$scenarios$S3
  expect_identical(s3$description, "Coordinated corridor management")
  expect_identical(s3$dimensions$financing_capacity, "EU funds")
})

test_that("a canonical criterion and its alias together leave exactly one cell row (M4)", {
  raw <- build_ia()
  raw$cells$PO <- raw$cells$EQ
  raw$cells$PI <- raw$cells$EE
  out <- normalize_impact_assessment(raw)
  expect_identical(sum(names(out$cells) == "PI"), 1L)
  expect_false("PO" %in% names(out$cells))
})
