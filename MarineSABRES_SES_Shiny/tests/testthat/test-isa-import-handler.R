# tests/testthat/test-isa-import-handler.R
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/data_structure.R"))

# source_for_test() writes to .GlobalEnv, but helper-stubs.R defines a stub
# isa_data_entry_server in testthat's helper environment, which SHADOWS
# .GlobalEnv during name lookup. Re-bind the real implementation into this
# file's env so testServer() drives the real module, not the stub.
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

fake_i18n <- list(t = function(x, ...) x)

# A saved project shaped like project$data$isa_data, with elements + one matrix.
make_saved_project <- function() {
  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "",
                                stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001", Mechanism = "", Confidence = "High",
                                    stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character()),
    adjacency_matrices = list(
      es_gb = matrix("+High:High", 1, 1, dimnames = list("ES001", "GB001"))
    )
  )
  list(project_id = "p1", name = "P1", data = list(isa_data = isa))
}

test_that("project-load observer populates panel_ids and loads matrices (characterization)", {
  testServer(isa_data_entry_server,
    args = list(project_data_reactive = reactiveVal(make_saved_project()), i18n = fake_i18n), {
      session$flushReact()
      rv <- session$getReturned()()
      expect_setequal(rv$gb_panel_ids, "GB001")
      expect_setequal(rv$es_panel_ids, "ES001")
      expect_equal(rv$adjacency_matrices$es_gb["ES001", "GB001"], "+High:High")
  })
})

test_that("apply_saved_isa rebuilds forward matrices from Linked* when none supplied", {
  saved <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001", Mechanism = "", Confidence = "High", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character())
    # NOTE: no adjacency_matrices
  )
  proj <- list(project_id = "pX", name = "PX", data = list(isa_data = saved))

  testServer(isa_data_entry_server,
    args = list(project_data_reactive = reactiveVal(proj), i18n = fake_i18n), {
      session$flushReact()
      rv <- session$getReturned()()
      expect_equal(rv$adjacency_matrices$es_gb["ES001", "GB001"], "+Medium:High")
  })
})

test_that("import handler loads a Matrix_* workbook, populates panels + matrices", {
  source_for_test("functions/isa_export_helpers.R")
  source_for_test("functions/standard_entry_excel_import.R")

  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001", Mechanism = "", Confidence = "High", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character()),
    adjacency_matrices = list(es_gb = matrix("+Strong:High", 1, 1, dimnames = list("ES001", "GB001")))
  )
  wb <- openxlsx::createWorkbook(); write_isa_element_sheets(wb, isa, include_adjacency = TRUE)
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  testServer(isa_data_entry_server,
    args = list(project_data_reactive = reactiveVal(init_session_data()),
                i18n = fake_i18n, parent_session = NULL), {
      session$setInputs(import_file = data.frame(
        name = "x.xlsx", size = 1, type = "", datapath = tmp, stringsAsFactors = FALSE))
      session$setInputs(import_data = 1)   # click Import
      session$flushReact()
      rv <- session$getReturned()()
      expect_setequal(rv$es_panel_ids, "ES001")
      expect_setequal(rv$gb_panel_ids, "GB001")
      expect_equal(rv$adjacency_matrices$es_gb["ES001", "GB001"], "+Strong:High")
  })
})
