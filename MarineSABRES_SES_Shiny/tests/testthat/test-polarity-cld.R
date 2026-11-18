# CLD editor: a drawn edge gets its sign from the user before it is created
# (evidenced polarity, Task 8).

source_for_test(c("functions/polarity_evidence.R",
                  "functions/cld_interaction_helpers.R",
                  "modules/cld_visualization_module.R"))
# helper-stubs.R shadows the module server with a stub; drive the real one
cld_viz_server <- get("cld_viz_server", envir = .GlobalEnv)

# Bind a value in .GlobalEnv (where the module's free names resolve) for one test
local_global <- function(name, value, env = parent.frame()) {
  had <- exists(name, envir = .GlobalEnv, inherits = FALSE)
  old <- if (had) get(name, envir = .GlobalEnv) else NULL
  assign(name, value, envir = .GlobalEnv)
  withr::defer(if (had) assign(name, old, envir = .GlobalEnv) else rm(list = name, envir = .GlobalEnv),
               envir = env)
}

# Records client-side edge removals/updates sent through visNetworkProxy
stub_proxy_edges <- function(env = parent.frame()) {
  rec <- new.env(); rec$removed <- list(); rec$updated <- list()
  local_global("visRemoveEdges", function(graph, id, ...) {
    rec$removed[[length(rec$removed) + 1]] <- id
    graph
  }, env)
  local_global("visUpdateEdges", function(graph, edges, ...) {
    rec$updated[[length(rec$updated) + 1]] <- edges
    graph
  }, env)
  rec
}
stub_notifications <- function(env = parent.frame()) {
  rec <- new.env(); rec$texts <- character(0)
  real <- shiny::showNotification
  local_global("showNotification", function(ui, ...) {
    rec$texts <- c(rec$texts, paste(as.character(ui), collapse = " "))
    real(ui, ...)
  }, env)
  rec
}

cld_tr <- make_test_i18n()

# Three nodes and one existing edge A_1 -> P_1 with sign "-"
make_cld_project <- function() {
  nodes <- data.frame(
    id = c("D_1", "A_1", "P_1"),
    label = c("Food demand", "Trawling", "Seabed damage"),
    group = c("Drivers", "Activities", "Pressures"),
    stringsAsFactors = FALSE)
  edges <- data.frame(from = "A_1", to = "P_1", label = "-", polarity = "-",
                      stringsAsFactors = FALSE)
  pd <- list(project_id = "t", project_name = "T",
             data = list(cld = list(nodes = nodes, edges = edges), isa_data = list()))
  sync_cld_to_isa_data(pd)
}

edges_between <- function(e, from, to) e[e$from == from & e$to == to, , drop = FALSE]
set_input <- function(session, id, value) do.call(session$setInputs, setNames(list(value), id))
draw_edge <- function(session, from = "D_1", to = "A_1", client_id = "pending_1") {
  session$setInputs(edge_added = list(from = from, to = to, id = client_id, nonce = runif(1)))
}
respond <- function(session, what) {
  session$setInputs(edit_edge_response = setNames(list(TRUE, runif(1)), c(what, "nonce")))
}

test_that("create_new_edge_data requires and applies a sign", {
  expect_error(create_new_edge_data("A", "B", 0))
  expect_error(create_new_edge_data("A", "B", 0, polarity = NA))
  expect_error(create_new_edge_data("A", "B", 0, polarity = ""))
  expect_error(create_new_edge_data("A", "B", 0, polarity = "x"))
  e <- create_new_edge_data("A", "B", 0, polarity = "-")
  expect_equal(e$polarity, "-"); expect_equal(e$label, "-")
  expect_equal(e$color, EDGE_COLORS$opposing); expect_equal(e$originalColor, EDGE_COLORS$opposing)
  p <- create_new_edge_data("A", "B", 0, polarity = "+")
  expect_equal(p$polarity, "+"); expect_equal(p$label, "+")
  expect_equal(p$color, EDGE_COLORS$reinforcing); expect_equal(p$originalColor, EDGE_COLORS$reinforcing)
})

test_that("the manipulation JS gives a drawn edge a known id and reports it", {
  js <- generate_manipulation_enable_js("cldv", function(x) paste0("ns-", x))
  # scope to the addEdge handler (editEdge also sends "id: edgeData.id")
  add_edge <- regmatches(js, regexpr("(?s)addEdge:.*?editNode:", js, perl = TRUE))
  expect_length(add_edge, 1)
  expect_match(add_edge, "edgeData.id = ", fixed = TRUE)
  expect_match(add_edge, "id: edgeData.id", fixed = TRUE)
  expect_match(add_edge, "ns-edge_added", fixed = TRUE)
  # the id is set before vis-network draws the edge
  expect_lt(regexpr("edgeData.id = ", add_edge, fixed = TRUE),
            regexpr("callback(edgeData)", add_edge, fixed = TRUE))
})

test_that("a drawn edge is added only after its sign is confirmed", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()   # run the load observer: rv$nodes / rv$edges
    expect_false(is.null(rv$edges))
    before <- rv$edges
    pd_before <- pd()
    draw_edge(session)
    # nothing created yet: neither the edge store nor project data changed
    expect_identical(rv$edges, before)
    expect_identical(pd(), pd_before)
    pend <- rv$pending_edge_edit
    expect_true(isTRUE(pend$is_new))
    expect_equal(pend$client_id, "pending_1")
    # the picker opens unset and confirm is disabled
    expect_true(is.na(pend$polarity))
    expect_false(grepl("checked", output$edit_edge_polarity_ui$html))
    expect_match(output$edit_edge_confirm_ui$html, "disabled")

    set_input(session, pend$picker_id, "-")
    expect_false(grepl("disabled", output$edit_edge_confirm_ui$html))
    respond(session, "confirm")

    expect_null(rv$pending_edge_edit)
    new <- edges_between(rv$edges, "D_1", "A_1")
    expect_equal(nrow(new), 1L)
    expect_equal(nrow(rv$edges), nrow(before) + 1L)
    expect_equal(new$polarity, "-")
    expect_equal(new$label, "-")
    # the handler's own row reached project data and synced into the matrices
    # (rv$edges is then rebuilt from the matrices, with create_edges_df colours)
    cld_new <- edges_between(pd()$data$cld$edges, "D_1", "A_1")
    expect_equal(nrow(cld_new), 1L)
    expect_equal(cld_new$polarity, "-")
    expect_equal(cld_new$label, "-")
    expect_equal(cld_new$color, EDGE_COLORS$opposing)
    expect_equal(cld_new$originalColor, EDGE_COLORS$opposing)
    expect_equal(cld_new$strength, "medium")
    expect_equal(cld_new$confidence, 3)
    cell <- pd()$data$isa_data$adjacency_matrices$d_a
    expect_false(is.null(cell))
    expect_true(any(startsWith(cell[!is.na(cell) & nzchar(cell)], "-")))
    # the drawn client edge is swapped for the saved edge under its own id
    # (through the proxy: the network is not re-rendered)
    expect_equal(prx$removed, list("pending_1"))
  })
})

test_that("cancel creates nothing and removes the client-side edge", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()   # run the load observer: rv$nodes / rv$edges
    before <- rv$edges
    pd_before <- pd()
    draw_edge(session, client_id = "pending_7")
    set_input(session, rv$pending_edge_edit$picker_id, "-")
    respond(session, "cancel")
    expect_null(rv$pending_edge_edit)
    expect_identical(rv$edges, before)
    expect_identical(pd(), pd_before)
    expect_equal(prx$removed, list("pending_7"))
  })
})

test_that("confirm without a sign is refused server-side and keeps the dialog", {
  prx <- stub_proxy_edges()
  nt <- stub_notifications()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()   # run the load observer: rv$nodes / rv$edges
    before <- rv$edges
    draw_edge(session)
    pend <- rv$pending_edge_edit
    respond(session, "confirm")
    expect_identical(rv$edges, before)
    expect_identical(rv$pending_edge_edit, pend)
    expect_true(any(grepl("common.polarity.approve_blocked", nt$texts, fixed = TRUE)))
    expect_length(prx$removed, 0)
    # a later pick plus confirm succeeds
    set_input(session, pend$picker_id, "+")
    respond(session, "confirm")
    new <- edges_between(rv$edges, "D_1", "A_1")
    expect_equal(nrow(new), 1L)
    expect_equal(new$polarity, "+")
    expect_equal(edges_between(pd()$data$cld$edges, "D_1", "A_1")$color, EDGE_COLORS$reinforcing)
  })
})

test_that("each opening uses a fresh picker: an earlier pick is not inherited", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()   # run the load observer: rv$nodes / rv$edges
    before <- rv$edges
    draw_edge(session, client_id = "pending_1")
    first_id <- rv$pending_edge_edit$picker_id
    set_input(session, first_id, "-")
    respond(session, "cancel")
    draw_edge(session, client_id = "pending_2")
    expect_false(identical(rv$pending_edge_edit$picker_id, first_id))
    expect_match(output$edit_edge_confirm_ui$html, "disabled")
    respond(session, "confirm")
    expect_identical(rv$edges, before)
    expect_false(is.null(rv$pending_edge_edit))
  })
})

test_that("drawing a second edge while one is pending discards the first", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()   # run the load observer: rv$nodes / rv$edges
    before <- rv$edges
    draw_edge(session, client_id = "pending_1")
    draw_edge(session, from = "D_1", to = "P_1", client_id = "pending_2")
    expect_equal(prx$removed, list("pending_1"))
    expect_equal(rv$pending_edge_edit$client_id, "pending_2")
    expect_identical(rv$edges, before)
  })
})

test_that("the edit-edge dialog preselects the edge's sign and applies a change", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()   # run the load observer: rv$nodes / rv$edges
    old <- edges_between(rv$edges, "A_1", "P_1")
    expect_equal(old$polarity, "-")
    n_before <- nrow(rv$edges)
    session$setInputs(edit_edge_triggered = list(id = old$id, from = "A_1", to = "P_1", nonce = runif(1)))
    pend <- rv$pending_edge_edit
    expect_false(isTRUE(pend$is_new))
    expect_equal(pend$polarity, "-")
    html <- output$edit_edge_polarity_ui$html
    expect_match(html, 'value="-"[^>]*checked')
    expect_false(grepl('value="\\+"[^>]*checked', html))
    expect_false(grepl("disabled", output$edit_edge_confirm_ui$html))

    set_input(session, pend$picker_id, "+")
    respond(session, "confirm")
    upd <- edges_between(rv$edges, "A_1", "P_1")
    expect_equal(nrow(upd), 1L)
    expect_equal(upd$polarity, "+")
    expect_equal(upd$label, "+")
    expect_equal(edges_between(pd()$data$cld$edges, "A_1", "P_1")$color, EDGE_COLORS$reinforcing)
    expect_equal(nrow(rv$edges), n_before)
    cell <- pd()$data$isa_data$adjacency_matrices$a_p
    expect_true(any(startsWith(cell[!is.na(cell) & nzchar(cell)], "+")))
    expect_length(prx$removed, 0)
  })
})

# --- Fix round 1 -------------------------------------------------------------

stub_runjs <- function(env = parent.frame()) {
  rec <- new.env(); rec$js <- character(0)
  local_global("runjs", function(code) { rec$js <- c(rec$js, code); invisible(NULL) }, env)
  rec
}

test_that("confirm replaces the drawn client edge with the saved, coloured edge", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    n0 <- nrow(rv$edges)
    draw_edge(session, client_id = "pending_1")
    set_input(session, rv$pending_edge_edit$picker_id, "-")
    respond(session, "confirm")
    expect_equal(prx$removed, list("pending_1"))
    expect_length(prx$updated, 1)
    upd <- prx$updated[[1]]
    row <- upd[upd$from == "D_1" & upd$to == "A_1", , drop = FALSE]
    expect_equal(nrow(row), 1L)
    expect_equal(as.numeric(row$id), n0 + 1)
    expect_equal(row$label, "-")
    expect_equal(row$color, EDGE_COLORS$opposing)
  })
})

test_that("'Edit edge' on the drawn edge keeps its sign dialog and answers vis with null", {
  prx <- stub_proxy_edges()
  rj <- stub_runjs()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    draw_edge(session, client_id = "pending_1")
    pend <- rv$pending_edge_edit
    rj$js <- character(0)
    session$setInputs(edit_edge_triggered = list(id = "pending_1", from = "D_1", to = "A_1",
                                                 nonce = runif(1)))
    expect_identical(rv$pending_edge_edit, pend)        # same dialog, same picker
    expect_length(prx$removed, 0)
    expect_true(any(grepl(paste0("editEdgeCallback_", id, "(null)"), rj$js, fixed = TRUE)))
    # the sign dialog still works
    set_input(session, pend$picker_id, "-")
    respond(session, "confirm")
    expect_equal(edges_between(pd()$data$cld$edges, "D_1", "A_1")$polarity, "-")
  })
})

test_that("turning edit mode off drops a drawn edge awaiting its sign", {
  prx <- stub_proxy_edges()
  rj <- stub_runjs()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    before <- rv$edges
    draw_edge(session, client_id = "pending_1")
    rj$js <- character(0)
    session$setInputs(enable_manipulation = FALSE)
    expect_null(rv$pending_edge_edit)
    expect_equal(prx$removed, list("pending_1"))
    expect_identical(rv$edges, before)
    # manipulation is not turned back on while the switch is off
    expect_false(any(grepl("reEnableManipulation", rj$js, fixed = TRUE)))
  })
})

test_that("deleting a node of the drawn edge drops its dialog; a late confirm adds nothing", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    draw_edge(session, client_id = "pending_1")
    picker <- rv$pending_edge_edit$picker_id
    set_input(session, picker, "-")
    session$setInputs(nodes_deleted = list(nodes = list("D_1"), nonce = runif(1)))
    expect_null(rv$pending_edge_edit)
    respond(session, "confirm")
    expect_equal(nrow(edges_between(rv$edges, "D_1", "A_1")), 0L)
    expect_equal(nrow(edges_between(pd()$data$cld$edges, "D_1", "A_1")), 0L)
  })
})

test_that("compute_edge_properties refuses a missing sign instead of colouring it", {
  expect_error(compute_edge_properties(NA_character_, "medium", 3), "must be")
  expect_error(compute_edge_properties("", "medium", 3), "must be")
  expect_equal(compute_edge_properties("-", "strong", 3),
               list(color = EDGE_COLORS$opposing, width = 3))
  expect_equal(compute_edge_properties("+", "weak", 3)$color, EDGE_COLORS$reinforcing)
})

test_that("a cancelled edit can skip re-enabling manipulation", {
  expect_match(generate_edge_edit_callback_js("cldv", confirm = FALSE), "reEnableManipulation", fixed = TRUE)
  expect_false(grepl("reEnableManipulation",
                     generate_edge_edit_callback_js("cldv", confirm = FALSE, reenable = FALSE), fixed = TRUE))
  clear <- generate_edge_edit_clear_js("cldv")
  expect_match(clear, "window.editEdgeCallback_cldv = null", fixed = TRUE)
  expect_false(grepl("(null)", clear, fixed = TRUE))
})

# --- Final fix round: edit-mode toolbar after Save (manual check, CLD bug 1) --
# Saving a drawn or edited edge syncs it into the matrices, which changes the
# ISA hash and re-renders the network. The new vis-network starts without
# manipulation, so the toolbar vanished while the Edit Mode switch stayed on.

test_that("the edit-mode JS records whether edit mode is on", {
  en <- generate_manipulation_enable_js("cldv", function(x) paste0("m-", x))
  expect_match(en, "window.cldEditMode_cldv = true", fixed = TRUE)
  expect_match(generate_manipulation_disable_js("cldv"), "window.cldEditMode_cldv = false", fixed = TRUE)
})

test_that("a re-rendered network re-applies manipulation when edit mode is on", {
  js <- generate_network_stored_js("cldv")
  expect_match(js, "window.network_cldv = this", fixed = TRUE)
  expect_match(js, "if (window.cldEditMode_cldv && window.manipulationConfig_cldv)", fixed = TRUE)
  expect_match(js, "this.setOptions({ manipulation: window.manipulationConfig_cldv })", fixed = TRUE)
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    session$setInputs(layout_type = "hierarchical", hierarchy_direction = "DU", level_separation = 150)
    widget <- paste(as.character(output$network), collapse = "")
    expect_match(widget, "cldEditMode_", fixed = TRUE)   # both stabilization handlers
  })
})

test_that("confirming a drawn edge and saving an edited edge both re-enable manipulation", {
  stub_proxy_edges()
  js <- stub_runjs()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    draw_edge(session)
    set_input(session, rv$pending_edge_edit$picker_id, "+")
    n0 <- length(js$js)
    respond(session, "confirm")
    expect_true(any(grepl("reEnableManipulation_", js$js[-seq_len(n0)], fixed = TRUE)))
    old <- edges_between(rv$edges, "A_1", "P_1")
    session$setInputs(edit_edge_triggered = list(id = old$id, from = "A_1", to = "P_1", nonce = runif(1)))
    set_input(session, rv$pending_edge_edit$picker_id, "+")
    n1 <- length(js$js)
    respond(session, "confirm")
    expect_true(any(grepl("reEnableManipulation_", js$js[-seq_len(n1)], fixed = TRUE)))
  })
})

test_that("recovered CLD nodes that are not a data frame do not break the load observer", {
  pd0 <- make_cld_project()
  # an autosave-recovered project can carry the CLD nodes as a plain list
  pd0$data$cld$nodes <- lapply(seq_len(nrow(pd0$data$cld$nodes)),
                               function(i) as.list(pd0$data$cld$nodes[i, ]))
  pd <- reactiveVal(pd0)
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    expect_true(is.data.frame(rv$nodes))
    expect_gt(nrow(rv$nodes), 0)
  })
})

# Recheck 2026-11-18: recovery hit create_nodes_df with an empty-list category
# (`TRUE && NULL > 0` is NA), and list-shaped CLD nodes were rebuilt from ISA,
# losing positions and leverage scores
test_that("create_nodes_df skips a category stored as an empty list", {
  pd0 <- make_cld_project()
  isa <- pd0$data$isa_data
  isa$responses <- list()
  nodes <- create_nodes_df(isa)
  expect_true(is.data.frame(nodes))
  expect_gt(nrow(nodes), 0)
})

test_that("list-shaped recovered CLD nodes keep their positions and leverage scores", {
  pd0 <- make_cld_project()
  n <- pd0$data$cld$nodes
  n$title <- n$label; n$x <- c(10, 20, 30); n$y <- c(1, 2, 3); n$leverage_score <- c(0.5, NA, 2)
  pd0$data$cld$nodes <- lapply(seq_len(nrow(n)), function(i) as.list(n[i, ]))
  tbl <- as_cld_node_table(pd0$data$cld$nodes)
  expect_true(is.data.frame(tbl))
  expect_equal(tbl$x, c(10, 20, 30))
  expect_equal(tbl$leverage_score, c(0.5, NA, 2))
  expect_identical(as_cld_node_table(n), n)
  expect_null(as_cld_node_table(list()))
  pd <- reactiveVal(pd0)
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    expect_equal(rv$nodes$x, c(10, 20, 30))
    expect_equal(rv$nodes$y, c(1, 2, 3))
    expect_equal(rv$nodes$id, n$id)
  })
})

# Re-review N3 (ruling R11): saving or deleting in the CLD editor updates the
# network through the proxy instead of re-rendering it, so the network, its
# layout and its edit-mode toolbar survive
test_that("saving a drawn edge, editing one and deleting a node do not re-render the network", {
  prx <- stub_proxy_edges()
  pd <- shiny::reactiveVal(make_cld_project())   # a real reactive: the load observer must see the sync
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    key0 <- rv$render_key
    expect_false(is.null(key0))
    draw_edge(session, client_id = "pending_1")
    set_input(session, rv$pending_edge_edit$picker_id, "+")
    respond(session, "confirm")
    session$flushReact()
    expect_identical(rv$render_key, key0)
    expect_equal(nrow(edges_between(rv$edges, "D_1", "A_1")), 1L)
    old <- edges_between(rv$edges, "A_1", "P_1")
    session$setInputs(edit_edge_triggered = list(id = old$id, from = "A_1", to = "P_1", nonce = runif(1)))
    set_input(session, rv$pending_edge_edit$picker_id, "+")
    respond(session, "confirm")
    session$flushReact()
    expect_identical(rv$render_key, key0)
    expect_equal(edges_between(rv$edges, "A_1", "P_1")$polarity, "+")
    # deleting a node: its edges go, the rest are renumbered 1..n on both sides
    prx$removed <- list(); prx$updated <- list()
    session$setInputs(nodes_deleted = list(nodes = list("D_1"), nonce = runif(1)))
    session$flushReact()
    expect_identical(rv$render_key, key0)
    expect_equal(nrow(edges_between(rv$edges, "D_1", "A_1")), 0L)
    expect_equal(as.numeric(rv$edges$id), seq_len(nrow(rv$edges)))
    expect_length(prx$updated, 1)
    expect_equal(as.numeric(prx$updated[[1]]$id), seq_len(nrow(rv$edges)))
    # project data still follows every edit
    expect_equal(nrow(edges_between(pd()$data$cld$edges, "A_1", "P_1")), 1L)
    expect_equal(edges_between(pd()$data$cld$edges, "A_1", "P_1")$polarity, "+")
  })
})

test_that("an ISA change from outside the CLD editor still re-renders the network", {
  pd <- shiny::reactiveVal(make_cld_project())   # a real reactive: the load observer must see the sync
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    key0 <- rv$render_key
    p <- pd()
    p$data$cld$edges <- rbind(p$data$cld$edges,
      data.frame(from = "D_1", to = "A_1", label = "+", polarity = "+", stringsAsFactors = FALSE))
    pd(sync_cld_to_isa_data(p))
    session$flushReact()
    expect_false(identical(rv$render_key, key0))
  })
})

test_that("a re-rendered network is stored and gets edit mode back without physics", {
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    session$setInputs(layout_type = "hierarchical", hierarchy_direction = "DU", level_separation = 150)
    widget <- paste(as.character(output$network), collapse = "")
    # afterDrawing fires whatever the physics setting (stabilization does not
    # fire with physics off: saved positions, circular layout)
    expect_match(widget, "afterDrawing", fixed = TRUE)
  })
})

# --- Fix round 3 (re-review 2) -------------------------------------------------
# Four nodes, three edges with ids 1..3: D_1>A_1, A_1>P_1, P_1>GB_1
make_cld_project3 <- function() {
  nodes <- data.frame(id = c("D_1", "A_1", "P_1", "GB_1"),
    label = c("Food demand", "Trawling", "Seabed damage", "Fish"),
    group = c("Drivers", "Activities", "Pressures", "Goods & Benefits"), stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "A_1", "P_1"), to = c("A_1", "P_1", "GB_1"),
                      label = c("+", "-", "-"), polarity = c("+", "-", "-"), stringsAsFactors = FALSE)
  sync_cld_to_isa_data(list(project_id = "t", project_name = "T",
                            data = list(cld = list(nodes = nodes, edges = edges), isa_data = list())))
}
# The browser's edge ids after a delete: the old ids, minus those vis removed,
# minus those the proxy removed, plus those it added
client_after <- function(old, vis_removed, prx) {
  sort(union(setdiff(old, c(vis_removed, unlist(prx$removed))), prx$updated[[1]]$id))
}

test_that("deleting a non-last edge replaces the browser's surviving edges by their old ids (P1)", {
  prx <- stub_proxy_edges()
  pd <- shiny::reactiveVal(make_cld_project3())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    old <- rv$edges$id
    del <- old[rv$edges$from == "D_1" & rv$edges$to == "A_1"]
    survivors <- setdiff(old, del)
    session$setInputs(edges_deleted = list(edges = list(del), nonce = runif(1)))
    session$flushReact()
    expect_equal(sort(as.numeric(unlist(prx$removed))), sort(as.numeric(survivors)))
    expect_equal(as.numeric(prx$updated[[1]]$id), seq_len(nrow(rv$edges)))
    # no orphan: the browser holds exactly R's edges
    expect_equal(client_after(old, del, prx), as.numeric(rv$edges$id))
    expect_setequal(paste(prx$updated[[1]]$from, prx$updated[[1]]$to), c("A_1 P_1", "P_1 GB_1"))
  })
})

test_that("deleting a mid-list node with links leaves no orphan edge in the browser (P1)", {
  prx <- stub_proxy_edges()
  pd <- shiny::reactiveVal(make_cld_project3())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    old <- rv$edges$id
    gone <- old[rv$edges$from == "A_1" | rv$edges$to == "A_1"]   # vis removes these itself
    survivors <- setdiff(old, gone)
    session$setInputs(nodes_deleted = list(nodes = list("A_1"), nonce = runif(1)))
    session$flushReact()
    expect_equal(sort(as.numeric(unlist(prx$removed))), sort(as.numeric(survivors)))
    expect_equal(client_after(old, gone, prx), as.numeric(rv$edges$id))
    expect_equal(paste(prx$updated[[1]]$from, prx$updated[[1]]$to), "P_1 GB_1")
  })
})

test_that("an outside change back to the last rendered data re-renders the network (P2)", {
  stub_proxy_edges()
  p0 <- make_cld_project()
  pd <- shiny::reactiveVal(p0)
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    key0 <- rv$render_key
    draw_edge(session, client_id = "pending_1")
    set_input(session, rv$pending_edge_edit$picker_id, "+")
    respond(session, "confirm")
    session$flushReact()
    expect_identical(rv$render_key, key0)           # absorbed: no re-render
    pd(p0)                                          # the same project loaded again
    session$flushReact()
    expect_equal(nrow(rv$edges), 1L)
    expect_false(identical(rv$render_key, key0))   # the canvas must be rebuilt
  })
})

.cld_root_dir <- function() {
  td <- getwd()
  if (basename(td) == "testthat") dirname(dirname(td)) else td
}
test_that("the network widget is not cached app-wide (P3)", {
  src <- paste(readLines(file.path(.cld_root_dir(), "modules", "cld_visualization_module.R"), warn = FALSE),
               collapse = "\n")
  start <- regexpr("output$network <- renderVisNetwork(", src, fixed = TRUE)
  expect_gt(start, 0)
  rest <- substring(src, start)
  block <- substring(rest, 1, regexpr("\n    # ", substring(rest, 2), fixed = TRUE) + 1)
  # either no bindCache on this output, or one scoped to the session
  has_bind <- grepl("bindCache(", block, fixed = TRUE)
  expect_true(!has_bind || grepl('cache = "session"', block, fixed = TRUE))
})

test_that("as_cld_node_table returns NULL unless the nodes have an id column (M-r1)", {
  expect_null(as_cld_node_table(list(id = list("D_1", "A_1"), x = list(1, 2), label = list("a", "b"))))
  expect_null(as_cld_node_table(list(list(label = "a"), list(label = "b"))))
  cols <- as_cld_node_table(list(id = c("D_1", "A_1"), label = c("a", "b")))
  expect_equal(cols$id, c("D_1", "A_1"))
  recs <- as_cld_node_table(list(list(id = "D_1", label = "a"), list(id = "A_1", label = "b")))
  expect_equal(recs$id, c("D_1", "A_1"))
})

test_that("create_nodes_df warns when it skips a non-empty list-shaped category (M-r2)", {
  msgs <- character(0)
  local_global("log_warning", function(context, message) msgs <<- c(msgs, message))
  isa <- make_cld_project()$data$isa_data
  isa$responses <- list(list(ID = "R1", Name = "Gear rules"))
  nodes <- create_nodes_df(isa)
  expect_true(is.data.frame(nodes))
  expect_true(any(grepl("responses", msgs, fixed = TRUE)))
  msgs <- character(0)
  isa$responses <- list()
  create_nodes_df(isa)
  expect_length(msgs, 0)   # an empty list is just "no responses"
})

# --- Fix round 4 (browser recheck after b40cdf6) ------------------------------

test_that("a real reload renders the widget once (M-r5)", {
  stub_proxy_edges()
  n <- new.env(); n$k <- 0
  real_vn <- visNetwork::visNetwork
  local_global("visNetwork", function(...) { n$k <- n$k + 1; real_vn(...) })
  p0 <- make_cld_project()
  pd <- shiny::reactiveVal(p0)
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$setInputs(layout_type = "physics", hierarchy_direction = "UD", level_separation = 150)
    session$flushReact()
    invisible(output$network)
    expect_equal(n$k, 1)
    p <- pd()
    p$data$cld$edges <- rbind(p$data$cld$edges,
      data.frame(from = "D_1", to = "A_1", label = "+", polarity = "+", stringsAsFactors = FALSE))
    pd(sync_cld_to_isa_data(p))
    session$flushReact()
    invisible(output$network)
    expect_equal(n$k, 2)
  })
})

# Two drivers, D_1 first: deleting D_1 shifts the drivers' positions in the ISA
make_cld_project_b5 <- function() {
  nodes <- data.frame(id = c("D_1", "D_2", "A_1", "P_1"),
    label = c("Food demand", "Jobs", "Trawling", "Seabed damage"),
    group = c("Drivers", "Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "D_2", "A_1", "D_1"), to = c("A_1", "A_1", "P_1", "A_1"),
                      label = c("+", "-", "-", "+"), polarity = c("+", "-", "-", "+"),
                      stringsAsFactors = FALSE)[1:3, ]
  sync_cld_to_isa_data(list(project_id = "t", project_name = "T",
                            data = list(cld = list(nodes = nodes, edges = edges), isa_data = list())))
}

test_that("after deleting a node and adding another, no edge references the deleted node (B5)", {
  stub_proxy_edges()
  pd <- shiny::reactiveVal(make_cld_project_b5())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    expect_equal(nrow(rv$edges), 3L)
    session$setInputs(nodes_deleted = list(nodes = list("D_1"), nonce = runif(1)))
    session$flushReact()
    check <- function(where) {
      expect_false(any(c(rv$edges$from, rv$edges$to) == "D_1"), info = where)
      expect_true(all(c(rv$edges$from, rv$edges$to) %in% rv$nodes$id), info = where)
      expect_false(any(duplicated(paste(rv$edges$from, rv$edges$to))), info = where)
      expect_equal(sort(paste(rv$edges$from, rv$edges$to)), c("A_1 P_1", "D_2 A_1"), info = where)
    }
    check("after delete")
    # add a node elsewhere (a full reload, as the CLD node add does)
    p <- pd()
    p$data$cld$nodes <- dplyr::bind_rows(p$data$cld$nodes,
      data.frame(id = "GB_1", label = "Fish", group = "Goods & Benefits", stringsAsFactors = FALSE))
    pd(sync_cld_to_isa_data(p))
    session$flushReact()
    check("after reload")
    # the matrices hold no row for the deleted element
    d_ids <- as.character(pd()$data$isa_data$drivers$ID)
    expect_length(d_ids, 1L)
    expect_equal(rownames(pd()$data$isa_data$adjacency_matrices$d_a), d_ids)
  })
})
