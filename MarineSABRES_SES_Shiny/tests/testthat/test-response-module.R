# test-response-module.R
# Unit tests for modules/response_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/response_module.R")
i18n <- list(t = function(key) key)

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("response_measures_ui function exists", {
  skip_if_not(exists("response_measures_ui", mode = "function"),
              "response_measures_ui not available")
  expect_true(is.function(response_measures_ui))
})

test_that("response_measures_ui returns valid shiny tags", {
  skip_if_not(exists("response_measures_ui", mode = "function"),
              "response_measures_ui not available")
  params <- names(formals(response_measures_ui))
  ui <- if ("i18n" %in% params) response_measures_ui("test_rm", i18n) else response_measures_ui("test_rm")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "response_measures_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("response_measures_server function exists", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  expect_true(is.function(response_measures_server))
})

test_that("response_measures_server signature includes all required params", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  params <- names(formals(response_measures_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("response_measures_server event_bus defaults to NULL", {
  skip_if_not(exists("response_measures_server", mode = "function"),
              "response_measures_server not available")
  default <- formals(response_measures_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

# ---- WS-2: WP5 reference pane renders KB v2 -------------------------------------
real_response_measures_server <- get("response_measures_server", envir = .GlobalEnv)
wp5_pane_html <- function(da_site) {
  proj <- create_empty_project("t"); proj$data$metadata$da_site <- da_site
  pd <- reactiveVal(proj); html <- NULL
  testServer(real_response_measures_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$flushReact()
    html <<- as.character(output$wp5_reference_pane$html)
  })
  html
}

test_that("Macaronesia pane: cost band, toolkit block with pre-final badge, references, no guidance", {
  load_wp5_mechanisms_kb(force_reload = TRUE)
  h <- wp5_pane_html("Macaronesia")
  for (k in c("attr.cost_band", "attr.toolkit_details", "provenance.wp5_prefinal",
              "attr.references", "pane.english_only_note"))
    expect_match(h, paste0("modules.wp5_mechanisms.", k), fixed = TRUE)
  expect_match(h, "Corridor coordination", fixed = TRUE)
  expect_false(grepl("use_in_impact_assessment", h, fixed = TRUE))
})

test_that("Tuscan pane: applicability + source, no toolkit block, no scenario labels", {
  load_wp5_mechanisms_kb(force_reload = TRUE)
  h <- wp5_pane_html("Tuscan Archipelago")
  expect_match(h, "modules.wp5_mechanisms.attr.applicability", fixed = TRUE)
  expect_match(h, "modules.wp5_mechanisms.attr.source", fixed = TRUE)
  expect_match(h, "Biodiversity / blue-carbon credits", fixed = TRUE)
  expect_false(grepl("modules.wp5_mechanisms.attr.toolkit_details", h, fixed = TRUE))
  expect_false(grepl("S2 Light|S3 Coordinated|Light Designation", h))
})

test_that("legacy v1 KB shows the update warning", {
  on.exit(load_wp5_mechanisms_kb(force_reload = TRUE), add = TRUE)
  v1 <- tempfile(fileext = ".json")
  writeLines(jsonlite::toJSON(list(version = "1.0.0", demonstration_areas = list(
    tuscan = list(mechanisms = list(list(id = "tus_01", name = "PES")))), valuation_unit_values = list()),
    auto_unbox = TRUE), v1)
  suppressWarnings(load_wp5_mechanisms_kb(v1, force_reload = TRUE))
  expect_match(wp5_pane_html("Tuscan Archipelago"), "modules.wp5_mechanisms.pane.legacy_kb_warning", fixed = TRUE)
})

# ---- final-review fixes: derived indicator codes are not "success metrics"; lt pre-final label
test_that("Macaronesia pane labels derived codes as indicators referenced, not success metrics", {
  load_wp5_mechanisms_kb(force_reload = TRUE)
  h <- wp5_pane_html("Macaronesia")
  expect_match(h, "modules.wp5_mechanisms.attr.indicators_referenced", fixed = TRUE)
  expect_false(grepl("modules.wp5_mechanisms.attr.success_metrics", h, fixed = TRUE))
})

test_that("Lithuanian pre-final badge and legacy warning use correct wording", {
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "wp5_mechanisms.json"),
                           simplifyVector = FALSE)$translation
  expect_equal(tr[["modules.wp5_mechanisms.provenance.wp5_prefinal"]]$lt, "Preliminarus projektas")
  expect_match(tr[["modules.wp5_mechanisms.pane.legacy_kb_warning"]]$lt, "^Šiame diegime")
})

# ---- WS-3a Task 3: codes in data, labels on display ------------------------------
real_response_measures_ui <- get("response_measures_ui", envir = .GlobalEnv)  # helper-stubs.R shadows it
rm_add <- function(inputs) {
  proj <- create_empty_project("t"); pd <- reactiveVal(proj); out <- NULL
  testServer(real_response_measures_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    do.call(session$setInputs, inputs)
    session$setInputs(add_response = 1)
    out <<- pd()$data$response_measures$measures
  })
  out
}

test_that("adding a measure stores codes, not translated labels", {
  m <- rm_add(list(rm_name = "Quota cut", rm_type = "regulatory", rm_target = "pressures",
                   rm_status = "planned", rm_description = "", rm_mechanism = "", rm_target_element = "",
                   rm_effectiveness = "HIGH", rm_feasibility = "MEDIUM", rm_cost = 4,
                   rm_stakeholders = "", rm_barriers = ""))
  expect_equal(c(m$Type, m$Target, m$Status), c("regulatory", "pressures", "planned"))
  expect_equal(names(m), RM_REGISTER_COLUMNS)
})

test_that("form choices are codes with translated names", {
  ui <- as.character(real_response_measures_ui("t", make_test_i18n()))
  expect_match(ui, 'value="regulatory"', fixed = TRUE)
  expect_match(ui, 'value="partially_implemented"', fixed = TRUE)
  expect_match(ui, "modules.response.measures.regulatory", fixed = TRUE)
})

# ---- WS-3a Task 4: classification + governance fields --------------------------
base_inputs <- list(rm_name = "Spatial closure", rm_type = "regulatory", rm_target = "multiple",
                    rm_status = "proposed", rm_description = "", rm_mechanism = "", rm_target_element = "",
                    rm_effectiveness = "", rm_feasibility = "", rm_cost = 5, rm_stakeholders = "", rm_barriers = "")

test_that("classification and governance fields are saved as codes/scalars", {
  m <- rm_add(c(base_inputs, list(rm_kind = "measure", rm_ebm_code = "spatial.seasonal",
                                  rm_gov_level = "regional_sea", rm_competent_authority = "Park authority",
                                  rm_legal_basis = "Law 394/1991", rm_impl_stakeholders = c("SH_1", "SH_3"),
                                  rm_paired_with = "")))
  expect_equal(c(m$Kind, m$EbmCode, m$GovernanceLevel), c("measure", "spatial.seasonal", "regional_sea"))
  expect_equal(m$ImplementingStakeholders, "SH_1;SH_3")
  expect_equal(c(m$CompetentAuthority, m$LegalBasis), c("Park authority", "Law 394/1991"))
})

test_that("measure with an empty EBM panel and no PIMS stakeholders still saves", {
  m <- rm_add(base_inputs)
  expect_equal(nrow(m), 1L)
  expect_equal(c(m$Kind, m$EbmCode, m$ImplementingStakeholders, m$PairedWith), c("", "", "", ""))
})

test_that("UI has the classification panel with i18n chrome", {
  ui <- as.character(real_response_measures_ui("t", make_test_i18n()))
  for (k in c("section_title", "kind", "ebm_code", "level", "competent_authority", "legal_basis",
              "implementing_stakeholders", "paired_with"))
    expect_match(ui, paste0("modules.response.governance.", k), fixed = TRUE)
})

# ---- WS-3a Task 5: tenet appraisal -----------------------------------------------
test_that("tenet levels are saved per tenet; intermediate offered only for ecol_effective", {
  m <- rm_add(c(base_inputs, list(rm_tenet_ecol_effective = "intermediate",
                                  rm_tenet_legally_permissible = "full", rm_tenet_communicable = "minimal")))
  expect_equal(c(m$Tenet_ecol_effective, m$Tenet_legally_permissible, m$Tenet_communicable, m$Tenet_econ_viable),
               c("intermediate", "full", "minimal", ""))
  ui <- as.character(real_response_measures_ui("t", make_test_i18n()))
  expect_match(ui, "modules.response.governance.tenets_title", fixed = TRUE)
  ecol <- regmatches(ui, regexpr('(?s)id="t-rm_tenet_ecol_effective".*?</select>', ui, perl = TRUE))
  comm <- regmatches(ui, regexpr('(?s)id="t-rm_tenet_communicable".*?</select>', ui, perl = TRUE))
  expect_match(ecol, 'value="intermediate"', fixed = TRUE)
  expect_false(grepl('value="intermediate"', comm, fixed = TRUE))
})

# ---- final-review fix I1: Word reports show labels, curated columns -------------------
rm_docx_text <- function(output_id) {
  proj <- create_empty_project("t"); pd <- reactiveVal(proj); txt <- NULL
  testServer(real_response_measures_server,
             args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    do.call(session$setInputs, c(base_inputs, list(rm_tenet_communicable = "full")))
    session$setInputs(add_response = 1)
    path <- output[[output_id]]
    txt <<- officer::docx_summary(officer::read_docx(path))$text
  })
  txt
}

test_that("priority report shows translated Type/Status, not raw codes", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  txt <- rm_docx_text("download_priority_report")
  expect_true(any(grepl("modules.response.measures.regulatory", txt, fixed = TRUE)))
  expect_false(any(txt %in% c("regulatory", "proposed", "multiple")))
})

test_that("implementation plan uses the curated columns (no Tenet_/ID-list columns)", {
  skip_if_not_installed("officer"); skip_if_not_installed("flextable")
  txt <- rm_docx_text("download_implementation_plan")
  expect_false(any(grepl("^Tenet_|ImplementingStakeholders|PairedWith", txt)))
  expect_true(any(grepl("modules.response.measures.regulatory", txt, fixed = TRUE)))
})

test_that("the PESTLE selection is saved as codes; none selected saves '' (review focus 5)", {
  base <- list(rm_name = "Quota cut", rm_type = "regulatory", rm_target = "pressures", rm_status = "planned",
               rm_description = "", rm_mechanism = "", rm_target_element = "", rm_effectiveness = "HIGH",
               rm_feasibility = "MEDIUM", rm_cost = 4, rm_stakeholders = "", rm_barriers = "")
  m1 <- rm_add(c(base, list(rm_pestle = c("legal", "political"))))
  expect_equal(m1$PestleTag, "political;legal")
  m2 <- rm_add(base)
  expect_equal(m2$PestleTag, "")
})

test_that("the governance section offers the PESTLE multi-select", {
  ui <- as.character(real_response_measures_ui("t", make_test_i18n()))
  expect_match(ui, "t-rm_pestle", fixed = TRUE)
  expect_match(ui, 'value="environmental"', fixed = TRUE)
})

test_that("adding two measures gives two rows with distinct ids", {
  proj <- create_empty_project("t"); pd <- reactiveVal(proj)
  testServer(real_response_measures_server, args = list(project_data_reactive = pd, i18n = make_test_i18n()), {
    session$setInputs(rm_name = "A", rm_type = "regulatory", add_response = 1)
    session$setInputs(rm_name = "B", rm_type = "regulatory", add_response = 2)
    m <- pd()$data$response_measures$measures
    expect_equal(nrow(m), 2L)
    expect_equal(m$ID, c("RM001", "RM002"))
  })
})
