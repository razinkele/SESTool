# tests/testthat/test-matrix-alignment-on-load.R
# Signed off 2026-10-11: validate matrices on project load and WARN only.
# The CLD reads matrix cells by position, so a matrix row left over from a
# deleted element silently attaches its links to the next element. The ISA
# module now checks alignment after loading and shows a warning; it never
# changes the data.
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/data_structure.R",
                  "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R",
                  "functions/project_transactions.R"))

isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)
rv <- shiny::reactiveVal

project_with_d_a <- function(drivers, d_a, pid = "p1") list(project_id = pid, data = list(isa_data = list(
  drivers = drivers,
  activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "",
                          LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE),
  adjacency_matrices = list(d_a = d_a), user_edited_matrices = list())))

driver_df <- function(ids, names) data.frame(ID = ids, Name = names, Type = "", Description = "",
                                             LinkedA = "", Trend = "", Controllability = "",
                                             stringsAsFactors = FALSE)

test_that("loading a project whose matrix has a stale row records a warning finding", {
  # D001 "Demand" was deleted but d_a still has its row: with positional reading,
  # its link would show on "Policy".
  d_a <- matrix(c("+Medium:Medium", ""), nrow = 2, ncol = 1,
                dimnames = list(c("Demand", "Policy"), "Fishing"))
  pdr <- rv(project_with_d_a(driver_df("D002", "Policy"), d_a))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_length(alignment_state$last, 1)
    expect_true(grepl("d_a: 2 rows for 1 drivers", alignment_state$last, fixed = TRUE))
    # warn only: the loaded matrix is not changed
    expect_equal(dim(session$getReturned()()$adjacency_matrices$d_a), c(2L, 1L))
    # the observer re-runs on every project write; same findings -> no new warning
    first <- alignment_state$last
    pdr(pdr())
    session$flushReact()
    expect_identical(alignment_state$last, first)
  })
})

test_that("an aligned project records no finding", {
  d_a <- matrix(c("+Medium:Medium", ""), nrow = 2, ncol = 1,
                dimnames = list(c("D001", "D002"), "A001"))
  pdr <- rv(project_with_d_a(driver_df(c("D001", "D002"), c("Demand", "Policy")), d_a))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_length(alignment_state$last, 0)
  })
})

test_that("the warning is wired after apply_saved_isa and uses a translated count message", {
  s <- paste(readLines(file.path(getwd(), "../..", "modules/isa_data_entry_module.R"), warn = FALSE),
             collapse = "\n")
  expect_true(grepl("apply_saved_isa(project$data$isa_data)\n        data_initialized(TRUE)\n        warn_if_matrices_misaligned()",
                    s, fixed = TRUE))
  expect_true(grepl("changed <- !identical(findings, alignment_state$last)", s, fixed = TRUE))
  tr <- jsonlite::fromJSON(file.path(getwd(), "../..", "translations/modules/isa_data_entry.json"),
                           simplifyVector = FALSE)$translation
  msg <- tr[["modules.isa.data_entry.common.matrices_misaligned_on_load"]]
  for (lang in c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")) {
    expect_true(grepl("%d", msg[[lang]], fixed = TRUE), info = lang)
  }
})
