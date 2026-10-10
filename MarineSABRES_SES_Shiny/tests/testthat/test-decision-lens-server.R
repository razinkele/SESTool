# tests/testthat/test-decision-lens-server.R
# Review 2026-10-07 N73: the Decision Lens server body was never executed by
# any test (only a signature test existed), and its tryCatch -> showNotification
# meant a broken call would only ever surface as a toast. Drive the real server.
source_for_test("modules/analysis_decision_lens.R")

dl_nodes <- function() data.frame(
  id    = c("D_1", "A_1", "P_1", "MPF_1"),
  label = c("Driver", "Activity", "Pressure", "State"),
  group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning"),
  stringsAsFactors = FALSE
)
dl_edges <- function() data.frame(
  from     = c("D_1", "A_1", "P_1", "MPF_1"),
  to       = c("A_1", "P_1", "MPF_1", "D_1"),
  polarity = c("+", "+", "-", "+"),
  stringsAsFactors = FALSE
)
# A valid DAPSIWRM loop (D -> A -> P -> MPF -> ES -> GB -> D); the 4-node
# fixture's MPF -> D closure is not a valid transition, so process_cycles_to_loops
# rightly drops it.
loop_nodes <- function() data.frame(
  id    = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
  label = c("Driver", "Activity", "Pressure", "State", "Service", "Benefit"),
  group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
            "Ecosystem Services", "Goods & Benefits"),
  stringsAsFactors = FALSE
)
loop_edges <- function() data.frame(
  from     = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
  to       = c("A_1", "P_1", "MPF_1", "ES_1", "GB_1", "D_1"),
  polarity = c("+", "+", "-", "+", "+", "+"),
  stringsAsFactors = FALSE
)
fake_bus <- function(nodes, edges) list(
  get_isa_igraph = function() list(nodes = nodes, edges = edges, graph = NULL),
  on_isa_change  = function() NULL
)
i18n_echo <- list(t = function(k, ...) k, translator = NULL)
real_dl_server <- get("analysis_decision_lens_server", envir = .GlobalEnv)

test_that("N73: Analyze classifies every node; invalid loops are not reported", {
  notes <- character(0)
  local_mocked_bindings(showNotification = function(ui, ...) {
    notes <<- c(notes, paste(as.character(ui), collapse = "")); invisible(NULL)
  }, .package = "shiny")
  testServer(real_dl_server,
             args = list(project_data_reactive = shiny::reactiveVal(list()), i18n = i18n_echo,
                         event_bus = fake_bus(dl_nodes(), dl_edges())), {
    session$setInputs(analyze = 1)
    expect_equal(nrow(rv$factors), 4L)
    expect_setequal(rv$factors$id, dl_nodes()$id)
    expect_true(is.data.frame(rv$loop_info))       # ran, not left NULL
    expect_equal(nrow(rv$loop_info), 0L)            # MPF -> D is not a valid closure
    expect_true(is.list(rv$archetypes))
  })
  expect_false(any(grepl("context_|error", notes)))  # no error toast
})

test_that("N73/N35: a valid loop is found and 2-node cycles are not reported", {
  e <- rbind(loop_edges(), data.frame(from = "A_1", to = "D_1", polarity = "-"))
  testServer(real_dl_server,
             args = list(project_data_reactive = shiny::reactiveVal(list()), i18n = i18n_echo,
                         event_bus = fake_bus(loop_nodes(), e)), {
    session$setInputs(analyze = 1)
    expect_equal(nrow(rv$factors), 6L)
    expect_equal(nrow(rv$loop_info), 1L)            # the 6-node loop; D<->A excluded
    expect_setequal(trimws(strsplit(rv$loop_info$NodeIDs[1], ",", fixed = TRUE)[[1]]), loop_nodes()$id)
  })
})

test_that("N73/N36: an empty network warns and leaves no stale results", {
  notes <- character(0)
  local_mocked_bindings(showNotification = function(ui, ...) {
    notes <<- c(notes, paste(as.character(ui), collapse = "")); invisible(NULL)
  }, .package = "shiny")
  testServer(real_dl_server,
             args = list(project_data_reactive = shiny::reactiveVal(list()), i18n = i18n_echo,
                         event_bus = fake_bus(dl_nodes(), dl_edges()[0, ])), {
    session$setInputs(analyze = 1)
    expect_null(rv$factors)
    expect_null(rv$loop_info)
  })
  expect_true(any(grepl("no_network_data", notes, fixed = TRUE)))
})
