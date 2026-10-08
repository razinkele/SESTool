# tests/testthat/test-isa-load-save-integrity.R
# Red->green anchor for review 2026-10-07 N1/N2 (docs/code-review-2026-10-07.md).
# N1: after a project load, Save on an ISA exercise must NOT replace the loaded
#     rows of that category with only the rows added this session (loaded IDs
#     have no form panels; collectors skip them; save did a full replace).
# N2: switching to a different project must clear the previous project's
#     element frames / loop connections / case info from the module.
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/data_structure.R",
                  "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R"))

# helper-stubs.R shadows the real server AND redefines reactiveVal as a
# non-reactive closure; re-bind the real module and use shiny::reactiveVal so
# project switches actually propagate (see test-stable-element-ids.R).
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)
rv <- shiny::reactiveVal

gb_cols <- c("Name", "Type", "Description", "Stakeholder", "Importance", "Trend")

# ---------------------------------------------------------------------------
# Pure helper: merge_collected_with_existing
# ---------------------------------------------------------------------------
test_that("merge keeps loaded rows that have no live panel and takes live rows from the collection", {
  existing <- data.frame(ID = c("GB001", "GB002"), Name = c("Food", "Jobs"),
                         Type = c("Provisioning", "Cultural"), Description = "",
                         Stakeholder = "", Importance = "High", Trend = "Stable",
                         stringsAsFactors = FALSE)
  collected <- data.frame(ID = "GB003", Name = "Recreation", Type = "Cultural",
                          Description = "", Stakeholder = "", Importance = "Low",
                          Trend = "Up", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(existing, collected,
                                       panel_ids = c("GB001", "GB002", "GB003"),
                                       live_ids = "GB003", col_names = gb_cols)
  expect_equal(out$ID, c("GB001", "GB002", "GB003"))
  expect_equal(out$Name, c("Food", "Jobs", "Recreation"))
  expect_equal(names(out), c("ID", gb_cols))
})

test_that("merge aligns lowercase loaded columns to the canonical schema", {
  existing <- data.frame(id = "GB001", name = "Food", type = "Provisioning",
                         importance = "High", stringsAsFactors = FALSE)   # no desc/stakeholder/trend
  out <- merge_collected_with_existing(existing, data.frame(),
                                       panel_ids = "GB001", live_ids = character(0),
                                       col_names = gb_cols)
  expect_equal(names(out), c("ID", gb_cols))
  expect_equal(out$Name, "Food")
  expect_equal(out$Description, "")
})

test_that("merge: a live panel whose name was blanked is dropped; a live edit replaces the loaded row", {
  existing <- data.frame(ID = c("GB001", "GB002"), Name = c("Food", "Jobs"),
                         Type = "Cultural", Description = "", Stakeholder = "",
                         Importance = "", Trend = "", stringsAsFactors = FALSE)
  collected <- data.frame(ID = "GB002", Name = "Jobs (edited)", Type = "Cultural",
                          Description = "", Stakeholder = "", Importance = "",
                          Trend = "", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(existing, collected,
                                       panel_ids = c("GB001", "GB002"),
                                       live_ids = c("GB001", "GB002"),   # both rendered; GB001 blanked
                                       col_names = gb_cols)
  expect_equal(out$ID, "GB002")
  expect_equal(out$Name, "Jobs (edited)")
})

test_that("merge with nothing loaded and nothing collected returns a 0-row canonical frame", {
  out <- merge_collected_with_existing(NULL, data.frame(), character(0), character(0), gb_cols)
  expect_equal(nrow(out), 0)
  expect_equal(names(out), c("ID", gb_cols))
})

# ---------------------------------------------------------------------------
# Module: load -> add -> save keeps the loaded rows (N1)
# ---------------------------------------------------------------------------
loaded_gb <- function() list(project_id = "p1", data = list(isa_data = list(
  goods_benefits = data.frame(ID = c("GB001", "GB002"), Name = c("Food", "Jobs"),
                              Type = c("Provisioning", "Cultural"), Description = "",
                              Stakeholder = "", Importance = "High", Trend = "Stable",
                              stringsAsFactors = FALSE),
  adjacency_matrices = list(), user_edited_matrices = list())))

test_that("N1: load 2 GB, add 1, Save Exercise 1 -> project keeps all 3", {
  i18n <- make_test_i18n()
  pdr <- rv(loaded_gb())
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    expect_equal(isa()$gb_panel_ids, c("GB001", "GB002"))

    session$setInputs(add_gb = 1)
    new_id <- setdiff(isa()$gb_panel_ids, c("GB001", "GB002"))
    expect_length(new_id, 1)
    args <- setNames(list("Recreation", "Cultural", "Low", "Up"),
                     paste0("gb_", c("name", "type", "importance", "trend"), "_", new_id))
    do.call(session$setInputs, args)
    session$setInputs(save_ex1 = 1)

    expect_setequal(isa()$goods_benefits$ID, c("GB001", "GB002", new_id))
    expect_setequal(pdr()$data$isa_data$goods_benefits$ID, c("GB001", "GB002", new_id))
    expect_equal(pdr()$data$isa_data$goods_benefits$Name[1:2], c("Food", "Jobs"))
  })
})

test_that("N1: loaded frames with lowercase columns survive a save with canonical names", {
  i18n <- make_test_i18n()
  pdr <- rv(list(project_id = "p1", data = list(isa_data = list(
    goods_benefits = data.frame(ID = "GB001", name = "Food", type = "Provisioning",
                                importance = "High", trend = "Stable", stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    session$setInputs(add_gb = 1)
    new_id <- setdiff(isa()$gb_panel_ids, "GB001")
    args <- setNames(list("Recreation", "Cultural", "Low", "Up"),
                     paste0("gb_", c("name", "type", "importance", "trend"), "_", new_id))
    do.call(session$setInputs, args)
    session$setInputs(save_ex1 = 1)

    gb <- pdr()$data$isa_data$goods_benefits
    expect_setequal(gb$ID, c("GB001", new_id))
    expect_true("Name" %in% names(gb))
    expect_equal(gb$Name[gb$ID == "GB001"], "Food")
  })
})

test_that("N1: bare Save Exercise 5 after load keeps the drivers AND their d_a edges", {
  i18n <- make_test_i18n()
  d_a <- matrix(c("+Medium:Medium", ""), nrow = 2, ncol = 1,
                dimnames = list(c("D001", "D002"), "A001"))
  pdr <- rv(list(project_id = "p1", data = list(isa_data = list(
    drivers = data.frame(ID = c("D001", "D002"), Name = c("Demand", "Policy"), Type = "",
                         Description = "", LinkedA = c("A001", ""), Trend = "",
                         Controllability = "", stringsAsFactors = FALSE),
    activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "",
                            LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(d_a = d_a), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    session$setInputs(save_ex5 = 1)

    expect_equal(isa()$drivers$ID, c("D001", "D002"))
    expect_equal(pdr()$data$isa_data$drivers$ID, c("D001", "D002"))
    m <- pdr()$data$isa_data$adjacency_matrices$d_a
    expect_true(is.matrix(m))
    expect_true(nzchar(m["D001", "A001"]))
  })
})

test_that("N1: loaded drivers with BLANK LinkedA still keep their d_a edges on save (re-derived from the matrix)", {
  i18n <- make_test_i18n()
  d_a <- matrix("+Medium:Medium", nrow = 1, ncol = 1, dimnames = list("D001", "A001"))
  pdr <- rv(list(project_id = "p1", data = list(isa_data = list(
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "",
                            LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(d_a = d_a), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    session$flushReact()
    session$setInputs(save_ex5 = 1)
    m <- pdr()$data$isa_data$adjacency_matrices$d_a
    expect_true(nzchar(m["D001", "A001"]))
  })
})

test_that("N1: bare Save on the Responses tab after load keeps the responses and the R-arm matrices", {
  i18n <- make_test_i18n()
  r_d  <- matrix("-medium:3", 1, 1, dimnames = list("R001", "D001"))
  gb_r <- matrix("+medium:3", 1, 1, dimnames = list("GB001", "R001"))
  pdr <- rv(list(project_id = "p1", data = list(isa_data = list(
    responses = data.frame(ID = "R001", Name = "Quota", Type = "", Description = "",
                           Stakeholder = "", Importance = "", Trend = "",
                           LinkedGB = "GB001", LinkedD = "D001", LinkedA = "", LinkedP = "",
                           stringsAsFactors = FALSE),
    drivers = data.frame(ID = "D001", Name = "Demand", Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "Provisioning",
                                Description = "", Stakeholder = "", Importance = "",
                                Trend = "", stringsAsFactors = FALSE),
    adjacency_matrices = list(r_d = r_d, gb_r = gb_r), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    expect_equal(isa()$r_panel_ids, "R001")
    session$setInputs(save_responses = 1)

    expect_equal(pdr()$data$isa_data$responses$ID, "R001")
    am <- pdr()$data$isa_data$adjacency_matrices
    expect_true(is.matrix(am$r_d) && nzchar(am$r_d["R001", "D001"]))
    expect_true(is.matrix(am$gb_r) && nzchar(am$gb_r["GB001", "R001"]))
  })
})

# ---------------------------------------------------------------------------
# Module: project switch clears previous project's state (N2)
# ---------------------------------------------------------------------------
test_that("N2: switching to a new empty project clears the previous project's frames and loop connections", {
  i18n <- make_test_i18n()
  pdr <- rv(list(project_id = "pA", data = list(isa_data = list(
    drivers = data.frame(ID = c("D001", "D002"), Name = c("x", "y"), Type = "", Description = "",
                         LinkedA = "", Trend = "", Controllability = "", stringsAsFactors = FALSE),
    loop_connections = data.frame(DriverID = "D001", GBID = "GB001", Effect = "+",
                                  Strength = "Medium", Confidence = 3L, Mechanism = "",
                                  stringsAsFactors = FALSE),
    case_info = list(site = "A"),
    adjacency_matrices = list(), user_edited_matrices = list()))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()
    expect_equal(nrow(isa()$drivers), 2)

    # New Project: fresh id, all categories empty (as create_empty_project() yields)
    pdr(list(project_id = "pB", data = list(isa_data = list(
      drivers = data.frame(), goods_benefits = data.frame(),
      adjacency_matrices = list(), user_edited_matrices = list()))))
    session$flushReact()

    expect_equal(nrow(isa()$drivers), 0)
    expect_equal(length(isa()$d_panel_ids), 0)
    expect_equal(nrow(isa()$loop_connections), 0)
    expect_equal(length(isa()$case_info), 0)

    # And a save in project B must not resurrect A's drivers
    session$setInputs(add_d = 1)
    new_id <- isa()$d_panel_ids
    args <- setNames(list("New driver"), paste0("d_name_", new_id))
    do.call(session$setInputs, args)
    session$setInputs(save_ex5 = 1)
    expect_equal(pdr()$data$isa_data$drivers$ID, new_id)
  })
})
