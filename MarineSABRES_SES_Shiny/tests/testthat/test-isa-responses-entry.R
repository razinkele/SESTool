# tests/testthat/test-isa-responses-entry.R
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/matrix_from_linked.R"))
# helper-stubs.R defines a no-op stub `isa_data_entry_server` that SHADOWS the
# real module during name lookup. Re-bind the real implementation into this
# file's env so testServer() drives the real module, not the stub.
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

# setInputs for the dynamically-suffixed inputs of one panel. Backtick/glue
# names like `r_name_{rid}` are NOT interpolated by setInputs, so build the
# names with paste0 + setNames + do.call.
set_panel_inputs <- function(session, rid, ...) {
  vals <- list(...)
  names(vals) <- paste0("r_", names(vals), "_", rid)
  do.call(session$setInputs, vals)
}

test_that("adding + saving a response builds r_d (-) and gb_r (+) and persists", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    isa_data$goods_benefits <- data.frame(ID = c("GB001","GB002"), Name = c("Food","Tourism"),
                                           stringsAsFactors = FALSE)
    isa_data$drivers <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)

    session$setInputs(add_response = 1)
    rid <- isa_data$r_panel_ids[[1]]
    set_panel_inputs(session, rid, name = "MSP", linkedgb = "GB002", linkedd = "D001")
    session$setInputs(save_responses = 1)

    expect_equal(nrow(isa_data$responses), 1L)
    expect_true(grepl("^R[0-9]{3}$", isa_data$responses$ID[1]))
    expect_equal(isa_data$adjacency_matrices$r_d["R001","D001"], "-medium:3")
    expect_equal(dim(isa_data$adjacency_matrices$gb_r), c(2L, 1L))
    expect_equal(isa_data$adjacency_matrices$gb_r["GB002","R001"], "+medium:3")
    expect_equal(nrow(pd()$data$isa_data$responses), 1L)
  })
})

test_that("import re-derives responses Linked* from Matrix_* so a re-save reproduces edges", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    saved <- list(
      goods_benefits = data.frame(ID = c("GB001","GB002"), Name = c("Food","Tourism"), stringsAsFactors = FALSE),
      drivers   = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
      responses = data.frame(ID = "R001", Name = "MSP", stringsAsFactors = FALSE),  # no Linked* cols
      adjacency_matrices = list(
        r_d  = matrix("-medium:3", 1, 1, dimnames = list("R001","D001")),
        gb_r = matrix(c("","+medium:3"), 2, 1, dimnames = list(c("GB001","GB002"),"R001"))
      )
    )
    apply_saved_isa(saved)
    expect_equal(isa_data$responses$LinkedD[1], "D001")
    expect_equal(isa_data$responses$LinkedGB[1], "GB002")
  })
})

test_that("import-replace clears prior responses", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    isa_data$responses <- data.frame(ID = "R009", Name = "old", stringsAsFactors = FALSE)
    isa_data$r_panel_ids <- "R009"
    .reset_isa_state()
    expect_equal(nrow(isa_data$responses), 0L)
    expect_equal(length(isa_data$r_panel_ids), 0L)
  })
})

test_that("create_edges_df emits R->D and GB->R edges from a built responses model", {
  # Pure render check (no testServer). create_edges_df comes from global.R; skip
  # gracefully if the harness ran degraded (matches every other consumer).
  skip_if_not(exists("create_edges_df", mode = "function"), "create_edges_df not available")
  isa <- list(
    goods_benefits     = data.frame(ID = c("GB001","GB002"), Name = c("Food","Tourism"), stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = character(), Name = character()),
    marine_processes   = data.frame(ID = character(), Name = character()),
    pressures          = data.frame(ID = character(), Name = character()),
    activities         = data.frame(ID = character(), Name = character()),
    drivers            = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
    responses          = data.frame(ID = "R001", Name = "MSP", LinkedGB = "GB002",
                                    LinkedD = "D001", LinkedA = "", LinkedP = "",
                                    stringsAsFactors = FALSE)
  )
  built <- build_response_matrices(isa)
  isa$adjacency_matrices <- built$adjacency_matrices
  edges <- create_edges_df(isa, isa$adjacency_matrices)   # two args (verified signature)
  expect_true(any(grepl("^R_", edges$from)  & grepl("^D_", edges$to)))   # r_d edge
  expect_true(any(grepl("^GB_", edges$from) & grepl("^R_", edges$to)))   # gb_r edge
})

test_that("editing a matrix cell persists, flags user_edited, and survives a rebuild", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    # Trigger the first flush so the project_id load-observer runs once (it would
    # otherwise clear adjacency_matrices), THEN seed state.
    session$setInputs(adj_matrix_select = "r_d")
    isa_data$drivers   <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)
    isa_data$responses <- data.frame(ID = "R001", Name = "MSP", LinkedGB = "",
                                     LinkedD = "D001", LinkedA = "", LinkedP = "",
                                     stringsAsFactors = FALSE)
    isa_data$adjacency_matrices <- list(
      r_d = matrix("-medium:3", 1, 1, dimnames = list("R001", "D001")))

    session$setInputs(adj_matrix_view_cell_edit = list(row = 1, col = 1, value = "+strong:4"))

    expect_equal(isa_data$adjacency_matrices$r_d["R001","D001"], "+strong:4")  # edit applied
    expect_true(isa_data$user_edited_matrices$r_d["R001","D001"])              # flagged
    expect_equal(pd()$data$isa_data$adjacency_matrices$r_d["R001","D001"], "+strong:4")  # synced

    # a rebuild from the same LinkedD must NOT clobber the user edit
    built <- build_response_matrices(isa_data)
    expect_equal(built$adjacency_matrices$r_d["R001","D001"], "+strong:4")
  })
})

test_that("an invalid cell edit is rejected and leaves the matrix unchanged", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    session$setInputs(adj_matrix_select = "r_d")    # first flush (load-observer runs once)
    isa_data$adjacency_matrices <- list(
      r_d = matrix("-medium:3", 1, 1, dimnames = list("R001", "D001")))
    session$setInputs(adj_matrix_view_cell_edit = list(row = 1, col = 1, value = "nonsense"))
    expect_equal(isa_data$adjacency_matrices$r_d["R001","D001"], "-medium:3")  # unchanged
  })
})
