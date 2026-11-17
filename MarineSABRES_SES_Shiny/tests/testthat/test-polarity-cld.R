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
    # the client edge drawn by vis-network is not removed on confirm
    expect_length(prx$removed, 0)
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

test_that("confirm recolours and labels the drawn client edge under its id", {
  prx <- stub_proxy_edges()
  pd <- reactiveVal(make_cld_project())
  testServer(cld_viz_server, args = list(project_data_reactive = pd, i18n = cld_tr), {
    session$flushReact()
    draw_edge(session, client_id = "pending_1")
    set_input(session, rv$pending_edge_edit$picker_id, "-")
    respond(session, "confirm")
    expect_length(prx$updated, 1)
    upd <- prx$updated[[1]]
    expect_equal(upd$id, "pending_1")
    expect_equal(upd$label, "-")
    expect_equal(upd$color, EDGE_COLORS$opposing)
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
