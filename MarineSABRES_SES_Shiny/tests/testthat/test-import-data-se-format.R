# tests/testthat/test-import-data-se-format.R
# The sidebar "Import Data" menu (generic Elements/Connections importer) must
# ALSO accept a Standard Entry export (per-category element sheets + Matrix_*),
# routing it through read_standard_entry_workbook + recover_isa_data so it loads
# with edges recovered by name despite the legacy duplicate-ID / empty-forward
# pathology.
source_for_test("functions/isa_export_helpers.R")
source_for_test("functions/standard_entry_excel_import.R")
source_for_test("functions/matrix_from_linked.R")
source_for_test("modules/import_data_module.R")
import_data_server <- get("import_data_server", envir = .GlobalEnv)  # defeat any stub

.idse_i18n <- list(t = function(x, ...) x)

test_that("Import Data menu loads a Standard Entry export (legacy pathology) with recovered edges", {
  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001: Food", Mechanism = "", Confidence = "High",
                                    stringsAsFactors = FALSE),
    marine_processes = data.frame(
      ID = c("MPF005", "MPF005"), Name = c("Fish biomass", "Biodiversity richness"),
      Type = "", Description = "", LinkedES = c("ES001: Fish", "ES001: Fish"),
      Mechanism = "", Spatial = "", stringsAsFactors = FALSE),
    pressures = data.frame(ID = "P001", Name = "Overfishing", Type = "", Description = "",
                           LinkedMPF = "MPF005: Biodiversity richness",
                           Intensity = "", Spatial = "", Temporal = "", stringsAsFactors = FALSE),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(
      es_gb = matrix("", 1, 1, dimnames = list("ES001", "GB001")),         # present but empty
      gb_d  = matrix("+Strong:3", 1, 1, dimnames = list("GB001", "D001"))  # faithful
    )
  )
  wb <- openxlsx::createWorkbook(); write_isa_element_sheets(wb, isa, include_adjacency = TRUE)
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  pdr <- reactiveVal(init_session_data())
  testServer(import_data_server,
    args = list(project_data_reactive = pdr, i18n = .idse_i18n,
                parent_session = NULL, event_bus = NULL), {
      session$setInputs(excel_file = data.frame(
        name = "ISA_Export.xlsx", size = 1, type = "", datapath = tmp, stringsAsFactors = FALSE))
      session$flushReact()

      pd <- pdr()
      isa_loaded <- pd$data$isa_data
      # duplicate MPF id reconciled to two unique elements
      expect_equal(nrow(isa_loaded$marine_processes), 2)
      expect_equal(length(unique(isa_loaded$marine_processes$ID)), 2)
      # faithful gb_d preserved
      expect_equal(isa_loaded$adjacency_matrices$gb_d["GB001", "D001"], "+Strong:3")
      # forward edges recovered (es_gb rebuilt from label LinkedGB)
      expect_true(any(nzchar(isa_loaded$adjacency_matrices$es_gb)))
      # CLD built with edges -> the diagram won't be empty
      expect_gt(nrow(pd$data$cld$edges), 0)
      expect_identical(pd$data$metadata$data_source, "excel_import")
  })
})

test_that("Import Data menu still rejects a non-Standard-Entry, non-Elements/Connections workbook", {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "RandomSheet")
  openxlsx::writeData(wb, "RandomSheet", data.frame(foo = 1, bar = 2))
  tmp <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, tmp, overwrite = TRUE)

  pdr <- reactiveVal(init_session_data())
  testServer(import_data_server,
    args = list(project_data_reactive = pdr, i18n = .idse_i18n,
                parent_session = NULL, event_bus = NULL), {
      session$setInputs(excel_file = data.frame(
        name = "bad.xlsx", size = 1, type = "", datapath = tmp, stringsAsFactors = FALSE))
      session$flushReact()
      # nothing loaded (no isa_data elements committed)
      pd <- pdr()
      gb <- pd$data$isa_data$goods_benefits
      expect_true(is.null(gb) || nrow(gb) == 0)
  })
})
