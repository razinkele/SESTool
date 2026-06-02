# tests/testthat/test-recover-isa-data.R
# Pure recovery used by BOTH the Standard Entry import handler and the sidebar
# Import Data menu: reconcile duplicate IDs + rebuild empty forward matrices
# from label-form LinkedX (resolved by NAME) + keep faithful matrices.
source_for_test("functions/data_structure.R")        # reconcile_loaded_element_ids, new_stable_id_store
source_for_test("functions/matrix_from_linked.R")    # resolve/rebuild helpers
source_for_test("functions/standard_entry_excel_import.R")  # recover_isa_data

test_that("recover_isa_data reconciles dup IDs, rebuilds forward edges by name, keeps faithful matrices", {
  saved <- list(
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
    drivers = data.frame(ID = character(), Name = character()),
    adjacency_matrices = list(
      es_gb = matrix("", 1, 1, dimnames = list("ES001", "GB001")),          # present but empty
      gb_d  = matrix("+Strong:3", 1, 1, dimnames = list("GB001", "D001"))   # faithful
    )
  )

  rec <- recover_isa_data(saved)

  # duplicate MPF id reconciled to two unique ids; names preserved
  expect_equal(nrow(rec$elements$marine_processes), 2)
  expect_equal(length(unique(rec$elements$marine_processes$ID)), 2)
  expect_true(rec$repaired)
  expect_setequal(rec$panel_ids$mpf_panel_ids, as.character(rec$elements$marine_processes$ID))

  # faithful gb_d preserved; empty es_gb rebuilt from label-form LinkedGB
  expect_equal(rec$adjacency_matrices$gb_d["GB001", "D001"], "+Strong:3")
  expect_true(nzchar(rec$adjacency_matrices$es_gb["ES001", "GB001"]))
  expect_true(rec$fell_back)

  # p_mpf rebuilt resolving BY NAME -> "Biodiversity richness", not stale MPF005="Fish biomass"
  mp <- rec$elements$marine_processes
  id_biodiv <- mp$ID[mp$Name == "Biodiversity richness"]
  id_fish   <- mp$ID[mp$Name == "Fish biomass"]
  pm <- rec$adjacency_matrices$p_mpf
  expect_true(nzchar(pm["P001", id_biodiv]))
  expect_equal(pm["P001", id_fish], "")
})

test_that("recover_isa_data leaves a clean (no-dup, faithful) project unchanged", {
  saved <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", LinkedGB = "GB001", stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character()),
    adjacency_matrices = list(es_gb = matrix("+High:High", 1, 1, dimnames = list("ES001", "GB001")))
  )
  rec <- recover_isa_data(saved)
  expect_false(rec$repaired)
  expect_false(rec$fell_back)                       # es_gb already had an edge
  expect_equal(rec$adjacency_matrices$es_gb["ES001", "GB001"], "+High:High")
})
