# tests/testthat/test-load-roundtrip-integrity.R
# Review 2026-10-07 batch "load / round-trip integrity": N23, N24, N25, N27,
# N28, N51, N57, plus the false "IDs repaired ... duplicates from an older
# version" toast seen on laguna when recovering an autosaved template project.
source_for_test(c("functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/isa_export_helpers.R",
                  "functions/universal_excel_loader.R", "functions/template_loader.R"))

# ---------------------------------------------------------------------------
# Template false alarm + N24
# ---------------------------------------------------------------------------
test_that("an autosaved template project recovers without a false 'IDs repaired' flag", {
  t <- load_all_templates()$fisheries
  pd <- create_empty_project("x")
  for (k in c("drivers", "activities", "pressures", "marine_processes", "ecosystem_services",
              "goods_benefits", "responses")) pd$data$isa_data[[k]] <- t[[k]]
  pd$data$isa_data$adjacency_matrices <- t$adjacency_matrices
  n <- normalize_and_reconcile_project(pd)            # what autosave recovery does
  expect_true("ID" %in% names(n$data$isa_data$responses))      # responses now canonicalised too
  rec <- recover_isa_data(n$data$isa_data, new_stable_id_store())
  expect_false(isTRUE(rec$repaired))
})

test_that("a pure id -> ID rename is not reported as a repair; real repairs still are", {
  r <- reconcile_loaded_element_ids(data.frame(id = c("D001", "D002"), name = c("a", "b")), "D", new_stable_id_store())
  expect_equal(r$df$ID, c("D001", "D002"))
  expect_false(isTRUE(r$repaired))
  r2 <- reconcile_loaded_element_ids(data.frame(ID = c("D001", "D001"), Name = c("a", "b")), "D", new_stable_id_store())
  expect_true(isTRUE(r2$repaired))
})

test_that("N24: every load door hands the module canonical column case", {
  df <- data.frame(id = "ES001", name = "Fish", linkedgb = "GB001", confidence = "High",
                   Mechanism = "x", stringsAsFactors = FALSE)
  out <- canonicalize_element_columns(df)
  expect_equal(names(out), c("ID", "Name", "LinkedGB", "Confidence", "Mechanism"))
  both <- canonicalize_element_columns(data.frame(Name = "keep", name = "other"))
  expect_equal(names(both), c("Name", "name"))                  # never overwrite an existing canonical column
  isa <- list(ecosystem_services = df,
              goods_benefits = data.frame(id = "GB001", name = "Food", stringsAsFactors = FALSE))
  rec <- recover_isa_data(isa, new_stable_id_store())
  expect_true(all(c("ID", "Name", "LinkedGB") %in% names(rec$elements$ecosystem_services)))
  # and the by-name forward rebuild now runs on this (load) door too
  expect_true(is.matrix(rec$adjacency_matrices$es_gb))
  expect_true(nzchar(rec$adjacency_matrices$es_gb["ES001", "GB001"]))
})

# ---------------------------------------------------------------------------
# N25 — one parseable cell grammar
# ---------------------------------------------------------------------------
test_that("N25: confidence labels map to the integer cell grammar", {
  expect_equal(normalize_confidence_level("High"), "5")
  expect_equal(normalize_confidence_level("medium"), "3")
  expect_equal(normalize_confidence_level("LOW"), "1")
  expect_equal(normalize_confidence_level(4), "4")
  expect_equal(normalize_confidence_level(""), "3")
  expect_equal(normalize_confidence_level("weird", "2"), "2")
})

test_that("N25: forward rebuilds write '+medium:<int>' cells that parse with the user's confidence", {
  es <- data.frame(ID = "ES001", Name = "Fish", LinkedGB = "GB001", Confidence = "High", stringsAsFactors = FALSE)
  m <- rebuild_matrix_from_linked(es, "LinkedGB", "ES001", "GB001")$matrix
  expect_equal(m["ES001", "GB001"], "+medium:5")
  conn <- parse_connection_value(m["ES001", "GB001"])
  expect_equal(conn$confidence, 5L)
  mb <- rebuild_forward_matrix_by_name(es, "LinkedGB", data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE))
  expect_equal(mb["ES001", "GB001"], "+medium:5")
  d <- data.frame(ID = "D001", Name = "Demand", LinkedA = "A001", stringsAsFactors = FALSE)
  expect_equal(rebuild_matrix_from_linked(d, "LinkedA", "D001", "A001")$matrix["D001", "A001"], "+medium:3")
})

# ---------------------------------------------------------------------------
# N27 / N51
# ---------------------------------------------------------------------------
test_that("N27: exact legacy duplicates collapse; same-ID different-name rows are re-keyed", {
  isa <- list(goods_benefits = data.frame(ID = c("GB001", "GB001", "GB001"),
                                          Name = c("Food", "food ", "Jobs"), stringsAsFactors = FALSE))
  rec <- recover_isa_data(isa, new_stable_id_store())
  gb <- rec$elements$goods_benefits
  expect_equal(nrow(gb), 2)                      # the "food " copy collapsed into "Food"
  expect_equal(rec$deduped_rows, 1L)
  expect_equal(anyDuplicated(gb$ID), 0)
  expect_true(isTRUE(rec$repaired))
})

test_that("N51: a label's exact ID wins over the first same-name row", {
  tgt <- data.frame(ID = c("GB001", "GB003"), Name = c("Food", "food "), stringsAsFactors = FALSE)
  expect_equal(resolve_linked_to_target_ids("GB003: food ", tgt), "GB003")
  expect_equal(resolve_linked_to_target_ids("GB009: Food", tgt), "GB001")   # stale id -> name match
  expect_equal(resolve_linked_to_target_ids("GB003", tgt), "GB003")         # bare id
})

# ---------------------------------------------------------------------------
# N23 / N28 — workbook round trip
# ---------------------------------------------------------------------------
test_that("N23: the analysis workbook always carries matrices and loop connections", {
  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    drivers = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
    responses = data.frame(),
    adjacency_matrices = list(gb_d = matrix("+strong:4", 1, 1, dimnames = list("GB001", "D001"))),
    loop_connections = data.frame(DriverID = "D001", GBID = "GB001", Effect = "+", Strength = "strong",
                                  Confidence = 4L, Mechanism = "", stringsAsFactors = FALSE))
  wb <- create_isa_analysis_workbook(isa)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  expect_true(all(c("Matrix_gb_d", "Loop_Connections") %in% openxlsx::getSheetNames(f)))
  back <- read_standard_entry_workbook(f)
  expect_equal(back$adjacency_matrices$gb_d["GB001", "D001"], "+strong:4")
  expect_equal(nrow(back$loop_connections), 1)
})

test_that("N28: a blank Matrix_* sheet is skipped and cells are trimmed", {
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Goods_Benefits")
  openxlsx::writeData(wb, "Goods_Benefits", data.frame(ID = "GB001", Name = "Food"))
  openxlsx::addWorksheet(wb, "Ecosystem_Services")
  openxlsx::writeData(wb, "Ecosystem_Services", data.frame(ID = "ES001", Name = "Fish"))
  openxlsx::addWorksheet(wb, "Matrix_d_a")                         # present but empty
  openxlsx::addWorksheet(wb, "Matrix_es_gb")
  openxlsx::writeData(wb, "Matrix_es_gb", data.frame(GB001 = " +strong:4 ", row.names = "ES001"), rowNames = TRUE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  back <- read_standard_entry_workbook(f)
  expect_null(back$adjacency_matrices$d_a)
  expect_equal(back$adjacency_matrices$es_gb["ES001", "GB001"], "+strong:4")
})

# ---------------------------------------------------------------------------
# N57
# ---------------------------------------------------------------------------
test_that("N57: sheet prefixes with regex metacharacters match literally", {
  sheets <- c("Site (A) node labels", "Site (A) edges", "Site [1 node labels", "Site [1 kumu", "Other edges")
  expect_equal(.sheets_after_prefix(sheets, "Site (A)", "edge|kumu"), "Site (A) edges")
  expect_equal(.sheets_after_prefix(sheets, "Site [1", "edge|kumu"), "Site [1 kumu")   # unbalanced bracket: no regex error
})
