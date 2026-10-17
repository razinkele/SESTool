# test-pims-stakeholder-module.R
# Unit tests for modules/pims_stakeholder_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/pims_stakeholder_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("pims_stakeholder_ui function exists", {
  skip_if_not(exists("pims_stakeholder_ui", mode = "function"),
              "pims_stakeholder_ui not available")
  expect_true(is.function(pims_stakeholder_ui))
})

test_that("pims_stakeholder_ui returns valid shiny tags", {
  skip_if_not(exists("pims_stakeholder_ui", mode = "function"),
              "pims_stakeholder_ui not available")
  params <- names(formals(pims_stakeholder_ui))
  ui <- if ("i18n" %in% params) pims_stakeholder_ui("test_pst", i18n) else pims_stakeholder_ui("test_pst")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "pims_stakeholder_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("pims_stakeholder_server function exists", {
  skip_if_not(exists("pims_stakeholder_server", mode = "function"),
              "pims_stakeholder_server not available")
  expect_true(is.function(pims_stakeholder_server))
})

test_that("pims_stakeholder_server signature includes all required params", {
  skip_if_not(exists("pims_stakeholder_server", mode = "function"),
              "pims_stakeholder_server not available")
  params <- names(formals(pims_stakeholder_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("pims_stakeholder_server event_bus defaults to NULL", {
  skip_if_not(exists("pims_stakeholder_server", mode = "function"),
              "pims_stakeholder_server not available")
  default <- formals(pims_stakeholder_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

test_that("next_element_id returns exactly one id", {
  expect_equal(next_element_id("SH", 2), "SH002")
  expect_equal(next_element_id("RM", 12), "RM012")
})

test_that("adding two stakeholders gives two rows with distinct ids (bug: generate_element_id(prefix, n) returned 1..n)", {
  real_server <- get("pims_stakeholder_server", envir = .GlobalEnv)
  pdr <- shiny::reactiveVal(create_empty_project("t"))
  testServer(real_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    session$setInputs(sh_name = "Fishers", sh_type = "x", sh_sector = "", sh_contact = "", sh_interests = "", sh_role = "", sh_power = 1, sh_interest = 1, sh_attitude = "", sh_engagement_level = "", add_stakeholder = 1)
    session$setInputs(sh_name = "Divers", sh_type = "x", sh_sector = "", sh_contact = "", sh_interests = "", sh_role = "", sh_power = 1, sh_interest = 1, sh_attitude = "", sh_engagement_level = "", add_stakeholder = 2)
    sh <- stakeholder_data$stakeholders
    expect_equal(nrow(sh), 2L)
    expect_equal(sh$ID, c("SH001", "SH002"))
    expect_equal(sh$Name, c("Fishers", "Divers"))
  })
})

# ============================================================================
# WS-9a: D5.4 roles + "Load DA actor list"
# ============================================================================
source_for_test(c("functions/stakeholder_schema.R", "functions/wp5_governance.R"))
real_pst_server <- get("pims_stakeholder_server", envir = .GlobalEnv)
real_pst_ui <- get("pims_stakeholder_ui", envir = .GlobalEnv)
proj_da <- function(site) {
  p <- create_empty_project("t", da_site = site); p$project_id <- "p1"; p
}

test_that("the form offers the D5.4 roles multi-select and the seeding slot", {
  ui <- as.character(real_pst_ui("pst", make_test_i18n()))
  expect_match(ui, "pst-sh_ne_roles", fixed = TRUE)
  expect_match(ui, 'value="Regulators"', fixed = TRUE)
  expect_match(ui, "pst-seed_da_ui", fixed = TRUE)
})

test_that("a manual stakeholder stores its roles as codes in canonical order", {
  pdr <- shiny::reactiveVal(proj_da(NULL))
  testServer(real_pst_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    session$setInputs(sh_name = "Park", sh_type = "x", sh_ne_roles = c("Regulators", "Inputters"), add_stakeholder = 1)
    expect_equal(stakeholder_data$stakeholders$NERoles, "Inputters;Regulators")
    expect_equal(pdr()$min_app_version, WP5_GOVERNANCE_MIN_APP_VERSION)
  })
})

test_that("no DA: no seeding button, a hint instead (review focus 1)", {
  pdr <- shiny::reactiveVal(proj_da(NULL))
  testServer(real_pst_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    html <- as.character(output$seed_da_ui$html)
    expect_match(html, "modules.wp5_governance.seed_no_da", fixed = TRUE)
    expect_false(grepl("seed_da\"", html, fixed = TRUE))
  })
})

test_that("seeding the Arctic for Iceland adds Iceland and DA-wide actors once; a legacy project still works (review focus 2, 4)", {
  p <- proj_da("Arctic Northeast Atlantic")
  p$data$pims$stakeholders <- data.frame(ID = "SH001", Name = "Local fishers", Type = "x", Sector = "", Contact = "",
                                         Interests = "", Role = "", Power = "", Interest = "", Attitude = "",
                                         EngagementLevel = "", DateAdded = "2026-01-01", stringsAsFactors = FALSE)
  p$data$pims$stakeholder_counter <- 1
  pdr <- shiny::reactiveVal(p)
  arc <- wp5_gov_profile_for_site(load_wp5_governance_profiles(), "Arctic Northeast Atlantic")
  expected <- length(Filter(function(a) is.null(a$sub_area) || identical(a$sub_area, "iceland"), arc$actors))
  testServer(real_pst_server, args = list(project_data_reactive = pdr, i18n = make_test_i18n()), {
    session$flushReact()
    expect_match(as.character(output$seed_da_ui$html), "modules.wp5_governance.seed_button", fixed = TRUE)
    session$setInputs(seed_sub_areas = "iceland", seed_da_confirm = 1)
    sh <- stakeholder_data$stakeholders
    expect_equal(nrow(sh), 1L + expected)
    expect_equal(sh$ID[2], "SH002")
    expect_equal(names(sh), PIMS_STAKEHOLDER_COLUMNS)
    session$setInputs(seed_da_confirm = 2)
    expect_equal(nrow(stakeholder_data$stakeholders), 1L + expected)
    expect_equal(nrow(pdr()$data$pims$stakeholders), 1L + expected)
    expect_equal(pdr()$min_app_version, WP5_GOVERNANCE_MIN_APP_VERSION)
    session$setInputs(sh_name = "Divers", sh_type = "x", add_stakeholder = 1)
    expect_equal(nrow(stakeholder_data$stakeholders), 2L + expected)
  })
})

test_that("roles and SourceId survive a JSON save/load round trip", {
  sh <- seed_da_actors(NULL, wp5_gov_profile_for_site(load_wp5_governance_profiles(), "Tuscan Archipelago"),
                       NULL, make_test_i18n(), 0)$stakeholders
  pd <- list(data = list(pims = list(stakeholders = sh)))
  back <- normalize_json_project_data(jsonlite::fromJSON(jsonlite::toJSON(pd, auto_unbox = TRUE), simplifyVector = FALSE))
  expect_equal(back$data$pims$stakeholders$NERoles, sh$NERoles)
  expect_equal(back$data$pims$stakeholders$SourceId, sh$SourceId)
})
