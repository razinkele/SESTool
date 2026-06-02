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

test_that("import guard: elements but no connections — panels load, no crash (L5 defense)", {
  source_for_test("functions/isa_export_helpers.R")
  source_for_test("functions/standard_entry_excel_import.R")

  # Two elements in unconnected categories; no Matrix_* sheets, empty/absent links.
  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = character(), Name = character()),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE)
    # no adjacency_matrices -> reader writes no Matrix_* sheets; fallback finds no
    # valid (src,tgt) pair (activities empty), so zero edges.
  )
  wb <- openxlsx::createWorkbook(); write_isa_element_sheets(wb, isa, include_adjacency = TRUE)
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  testServer(isa_data_entry_server,
    args = list(project_data_reactive = reactiveVal(init_session_data()),
                i18n = fake_i18n, parent_session = NULL), {
      session$setInputs(import_file = data.frame(
        name = "x.xlsx", size = 1, type = "", datapath = tmp, stringsAsFactors = FALSE))
      session$setInputs(import_data = 1)
      session$flushReact()
      rv <- session$getReturned()()
      # elements loaded (import ran through apply_saved_isa)
      expect_setequal(rv$gb_panel_ids, "GB001")
      expect_setequal(rv$d_panel_ids, "D001")
      # but no edges were produced
      n_edges <- sum(vapply(rv$adjacency_matrices,
                            function(m) if (is.matrix(m)) sum(nzchar(m) & !is.na(m)) else 0L,
                            integer(1)))
      expect_equal(n_edges, 0)
  })
})

test_that("import replaces prior project state (no stale matrices/elements)", {
  source_for_test("functions/isa_export_helpers.R")
  source_for_test("functions/standard_entry_excel_import.R")

  # Project A loaded first: faithful es_gb "+High:High" AND a driver D001.
  projA <- list(project_id = "A", name = "A", data = list(isa_data = list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001", Mechanism = "", Confidence = "High", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(es_gb = matrix("+High:High", 1, 1, dimnames = list("ES001", "GB001")))
  )))

  # Import B: element sheets only (NO Matrix_*); ES Confidence "Low"; NO drivers.
  isaB <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001", Mechanism = "", Confidence = "Low", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character())
  )
  wb <- openxlsx::createWorkbook(); write_isa_element_sheets(wb, isaB, include_adjacency = FALSE)
  tmpB <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmpB, overwrite = TRUE)

  testServer(isa_data_entry_server,
    args = list(project_data_reactive = reactiveVal(projA), i18n = fake_i18n, parent_session = NULL), {
      session$flushReact()  # load project A
      rvA <- session$getReturned()()
      expect_equal(rvA$adjacency_matrices$es_gb["ES001", "GB001"], "+High:High")
      expect_setequal(rvA$d_panel_ids, "D001")

      # Import B; state is non-empty so the confirm modal path is exercised.
      session$setInputs(import_file = data.frame(
        name = "b.xlsx", size = 1, type = "", datapath = tmpB, stringsAsFactors = FALSE))
      session$setInputs(import_data = 1)     # shows confirm modal
      session$flushReact()
      session$setInputs(import_confirm = 1)  # confirm replace
      session$flushReact()

      rv <- session$getReturned()()
      # B's fallback es_gb ("+Medium:Low") REPLACED A's faithful "+High:High"
      expect_equal(rv$adjacency_matrices$es_gb["ES001", "GB001"], "+Medium:Low")
      # A's driver is fully gone (element df cleared, not just the panel tracker)
      expect_equal(nrow(rv$drivers), 0)
      expect_length(rv$d_panel_ids, 0)
  })
})

test_that("import of an unrecognized workbook is a clean no-op (state unchanged)", {
  source_for_test("functions/standard_entry_excel_import.R")

  # A workbook with no Standard-Entry element sheets and no Matrix_* sheets.
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "RandomSheet")
  openxlsx::writeData(wb, "RandomSheet", data.frame(foo = 1, bar = 2))
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  testServer(isa_data_entry_server,
    args = list(project_data_reactive = reactiveVal(init_session_data()),
                i18n = fake_i18n, parent_session = NULL), {
      session$setInputs(import_file = data.frame(
        name = "bad.xlsx", size = 1, type = "", datapath = tmp, stringsAsFactors = FALSE))
      session$setInputs(import_data = 1)
      session$flushReact()
      rv <- session$getReturned()()
      # nothing imported — all panels remain empty
      expect_length(rv$gb_panel_ids, 0)
      expect_length(rv$d_panel_ids, 0)
      expect_length(rv$es_panel_ids, 0)
  })
})
