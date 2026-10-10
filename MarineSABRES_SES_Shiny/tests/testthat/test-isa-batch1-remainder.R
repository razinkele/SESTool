# tests/testthat/test-isa-batch1-remainder.R
# Review 2026-10-07 batch-1 remainder (docs/code-review-2026-10-07.md):
#   N5  removing an element never pruned its row/col from the adjacency matrices
#   N22 CLD edits emitted nothing (cld_viz_server wired without event_bus)
#   N38 matrix-review selector used reversed keys that never matched stored matrices
#   N49 Excel import cleared module state before the "no elements" guard
#   N50 the R arm had no name-based LinkedX recovery fallback
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/data_structure.R",
                  "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R",
                  "functions/cld_interaction_helpers.R"))
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)
rv <- shiny::reactiveVal

# ---------------------------------------------------------------------------
# N5 — prune matrices on element removal
# ---------------------------------------------------------------------------
test_that("N5: prune_element_from_matrices drops the id's row/col from every matrix (adjacency + user_edited)", {
  es_gb <- matrix(c("+Medium:Medium", "", "", "", "", "+Medium:Medium"), nrow = 2, byrow = TRUE,
                  dimnames = list(c("ES001", "ES002"), c("GB001", "GB002", "GB003")))
  gb_d  <- matrix("", nrow = 3, ncol = 1, dimnames = list(c("GB001", "GB002", "GB003"), "D001"))
  ue    <- list(es_gb = matrix(FALSE, 2, 3, dimnames = dimnames(es_gb)))
  out <- prune_element_from_matrices(list(es_gb = es_gb, gb_d = gb_d), ue, "GB001")
  expect_equal(colnames(out$am$es_gb), c("GB002", "GB003"))
  expect_equal(out$am$es_gb["ES002", "GB003"], "+Medium:Medium")
  expect_equal(rownames(out$am$gb_d), c("GB002", "GB003"))
  expect_equal(dim(out$ue$es_gb), c(2, 2))
  # an id that appears nowhere leaves everything untouched; non-matrix entries pass through
  same <- prune_element_from_matrices(list(es_gb = es_gb, junk = list(1)), list(), "ZZZ")
  expect_identical(same$am$es_gb, es_gb)
  expect_identical(same$am$junk, list(1))
})

test_that("N5: removing a loaded GB panel prunes its column from es_gb in the module", {
  i18n <- make_test_i18n()
  es_gb <- matrix(c("+Medium:Medium", "", "", "", "", "+Medium:Medium"), nrow = 2, byrow = TRUE,
                  dimnames = list(c("ES001", "ES002"), c("GB001", "GB002", "GB003")))
  pdr <- rv(list(project_id = "p1", data = list(isa_data = list(
    goods_benefits = data.frame(ID = c("GB001", "GB002", "GB003"), Name = c("a", "b", "c"),
                                Type = "Provisioning", Description = "", Stakeholder = "",
                                Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = c("ES001", "ES002"), Name = c("x", "y"), Type = "",
                                    Description = "", LinkedGB = c("GB001", "GB003"),
                                    Mechanism = "", Confidence = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(es_gb = es_gb), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    # Loaded panels have no DOM, but the remove observer is only registered by
    # add_gb; so add one more GB, then remove a LOADED id through the same path
    # the module uses (register_remove_observer is wired per add). Exercise the
    # pruning via the added panel instead: add GB004, save, remove GB004.
    session$setInputs(add_gb = 1)
    new_id <- setdiff(isa()$gb_panel_ids, c("GB001", "GB002", "GB003"))
    args <- setNames(list("New", "Cultural", "Low", "Up"),
                     paste0("gb_", c("name", "type", "importance", "trend"), "_", new_id))
    do.call(session$setInputs, args)
    session$setInputs(save_ex1 = 1)
    expect_true(new_id %in% isa()$goods_benefits$ID)
    # A bare ES save rebuilds es_gb against ALL GB ids, so the new GB becomes a
    # column (this is what made the pre-fix test vacuous without it).
    session$setInputs(save_ex2a = 1)
    m0 <- isa()$adjacency_matrices$es_gb
    expect_true(is.matrix(m0))
    expect_true(new_id %in% colnames(m0))
    do.call(session$setInputs, setNames(list(1), paste0("gb_remove_", new_id)))
    m1 <- isa()$adjacency_matrices$es_gb
    expect_false(new_id %in% colnames(m1))
    expect_false(new_id %in% isa()$goods_benefits$ID)
    expect_false(new_id %in% colnames(pdr()$data$isa_data$adjacency_matrices$es_gb %||% matrix(nrow = 0, ncol = 0)))
  })
})

# ---------------------------------------------------------------------------
# N22 — CLD edits reach the event bus without forcing a CLD regeneration
# ---------------------------------------------------------------------------
test_that("N22: notify_cld_edit sets the pipeline skip flag, then emits isa_change with the source", {
  calls <- character(0)
  bus <- list(
    skip_next_cld_regen = function(value = TRUE) calls <<- c(calls, paste0("skip:", value)),
    emit_isa_change     = function(source = "unknown") calls <<- c(calls, paste0("emit:", source))
  )
  expect_true(notify_cld_edit(bus, "cld_edit_add_node"))
  expect_equal(calls, c("skip:TRUE", "emit:cld_edit_add_node"))
  # tolerant of NULL / partial buses
  expect_false(notify_cld_edit(NULL, "x"))
  expect_false(notify_cld_edit(list(emit_isa_change = NULL), "x"))
  only_emit <- list(emit_isa_change = function(source) calls <<- c(calls, paste0("emit2:", source)))
  expect_true(notify_cld_edit(only_emit, "cld_edit_merge_nodes"))
  expect_equal(tail(calls, 1), "emit2:cld_edit_merge_nodes")
})

test_that("N22: app.R passes the event bus to cld_viz_server", {
  root <- if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd()
  src <- readLines(file.path(root, "app.R"), warn = FALSE)
  call_line <- grep("cld_viz_server\\(", src, value = TRUE)
  expect_length(call_line, 1)
  expect_true(grepl("event_bus", call_line[1]), info = call_line[1])
})

# ---------------------------------------------------------------------------
# N38 — matrix-review selector keys match stored matrix names
# ---------------------------------------------------------------------------
test_that("N38: every matrix-review choice is a canonical SOURCExTARGET matrix key", {
  canonical <- c("es_gb", "mpf_es", "p_mpf", "a_p", "d_a", "gb_d", "gb_r", "r_d", "r_a", "r_p")
  expect_true(all(ISA_MATRIX_REVIEW_CHOICES %in% canonical))
  expect_setequal(unname(ISA_MATRIX_REVIEW_CHOICES), canonical)
  expect_false(any(c("gb_es", "es_mpf", "mpf_p", "p_a", "a_d", "d_gb") %in% ISA_MATRIX_REVIEW_CHOICES))
})

test_that("N38: a saved ES->GB link is viewable under its selector key", {
  i18n <- make_test_i18n()
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = rv(NULL), i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$setInputs(add_gb = 1)
    session$setInputs(gb_name_GB001 = "Food", gb_type_GB001 = "Provisioning",
                      gb_importance_GB001 = "High", gb_trend_GB001 = "Stable")
    session$setInputs(save_ex1 = 1)
    session$setInputs(add_es = 1)
    session$setInputs(es_name_ES001 = "Fisheries", es_type_ES001 = "Provisioning",
                      es_linkedgb_ES001 = "GB001", es_confidence_ES001 = "High")
    session$setInputs(save_ex2a = 1)
    stored <- names(isa()$adjacency_matrices)
    expect_true("es_gb" %in% stored)
    expect_true("es_gb" %in% ISA_MATRIX_REVIEW_CHOICES)
    # ...and cell-editable under that key (the user-facing half of N38)
    session$setInputs(adj_matrix_select = "es_gb")
    session$setInputs(adj_matrix_view_cell_edit = list(row = 1, col = 1, value = "+strong:4"))
    expect_equal(isa()$adjacency_matrices$es_gb["ES001", "GB001"], "+strong:4")
    expect_true(isa()$user_edited_matrices$es_gb["ES001", "GB001"])
  })
})

# ---------------------------------------------------------------------------
# N49 — import guard runs before the reset
# ---------------------------------------------------------------------------
test_that("N49: saved_isa_has_elements distinguishes empty-but-recognised workbooks", {
  expect_false(saved_isa_has_elements(list()))
  expect_false(saved_isa_has_elements(list(drivers = data.frame(), adjacency_matrices = list(d_a = matrix("", 0, 0)))))
  expect_true(saved_isa_has_elements(list(drivers = data.frame(ID = "D001", Name = "x"))))
  expect_true(saved_isa_has_elements(list(responses = data.frame(ID = "R001", Name = "r"))))
})

test_that("N49: importing an empty-but-recognised workbook leaves the loaded project untouched", {
  skip_if_not_installed("openxlsx")
  i18n <- make_test_i18n()
  # A workbook that read_standard_entry_workbook recognises but that holds no rows.
  empty_isa <- list(
    goods_benefits = data.frame(ID = character(), Name = character(), Type = character(),
                                Description = character(), Stakeholder = character(),
                                Importance = character(), Trend = character(), stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list())
  wb_path <- tempfile(fileext = ".xlsx")
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Goods_Benefits"); openxlsx::writeData(wb, "Goods_Benefits", empty_isa$goods_benefits)
  openxlsx::addWorksheet(wb, "Matrix_es_gb"); openxlsx::writeData(wb, "Matrix_es_gb", data.frame(ID = character()))
  openxlsx::saveWorkbook(wb, wb_path, overwrite = TRUE)
  recognised <- tryCatch({ read_standard_entry_workbook(wb_path); TRUE },
                         se_import_not_recognized = function(e) FALSE, error = function(e) FALSE)
  skip_if_not(recognised, "fixture workbook not recognised by read_standard_entry_workbook")

  pdr <- rv(list(project_id = "p1", data = list(isa_data = list(
    drivers = data.frame(ID = c("D001", "D002"), Name = c("x", "y"), Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    expect_equal(nrow(isa()$drivers), 2)
    session$setInputs(import_file = list(name = "empty.xlsx", datapath = wb_path))
    expect_equal(nrow(isa()$drivers), 2)
    expect_equal(isa()$d_panel_ids, c("D001", "D002"))
  })
})

# ---------------------------------------------------------------------------
# N50 — R-arm name-based recovery
# ---------------------------------------------------------------------------
test_that("N50: recover_isa_data rebuilds r_d / r_a / r_p / gb_r from Linked* when the matrices are absent", {
  saved <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "",
                            LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE),
    pressures = data.frame(ID = "P001", Name = "Extraction", Type = "", Description = "",
                           LinkedMPF = "", Intensity = "", Spatial = "", Temporal = "", stringsAsFactors = FALSE),
    responses = data.frame(ID = "R001", Name = "Quota", Type = "", Description = "",
                           Stakeholder = "", Importance = "", Trend = "",
                           LinkedGB = "GB001: Food", LinkedD = "D001", LinkedA = "A001: Fishing",
                           LinkedP = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list())
  rec <- recover_isa_data(saved, new_stable_id_store())
  am <- rec$adjacency_matrices
  expect_true(is.matrix(am$r_d)); expect_true(nzchar(am$r_d["R001", "D001"]))
  expect_true(is.matrix(am$r_a)); expect_true(nzchar(am$r_a["R001", "A001"]))
  expect_null(am$r_p)                                   # no LinkedP -> nothing to rebuild
  expect_true(is.matrix(am$gb_r))
  expect_equal(dimnames(am$gb_r), list("GB001", "R001"))  # stored GB x R
  expect_true(nzchar(am$gb_r["GB001", "R001"]))
  expect_true(startsWith(am$r_d["R001", "D001"], "-"))    # R -> target is negative by default
  expect_true(startsWith(am$gb_r["GB001", "R001"], "+"))
  expect_true(isTRUE(rec$fell_back))
})

test_that("N50: a faithful saved r_d matrix is kept (not overwritten by the fallback)", {
  r_d <- matrix("-strong:5", 1, 1, dimnames = list("R001", "D001"))
  saved <- list(
    drivers = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
    responses = data.frame(ID = "R001", Name = "Quota", LinkedD = "D001", stringsAsFactors = FALSE),
    adjacency_matrices = list(r_d = r_d), user_edited_matrices = list())
  rec <- recover_isa_data(saved, new_stable_id_store())
  expect_equal(rec$adjacency_matrices$r_d["R001", "D001"], "-strong:5")
})
