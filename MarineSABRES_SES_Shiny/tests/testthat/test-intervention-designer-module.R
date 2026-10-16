# tests/testthat/test-intervention-designer-module.R
source_for_test(c("functions/network_analysis.R", "functions/scenario_network.R",
                  "functions/intervention_designer.R", "functions/intervention_designer_job.R",
                  "modules/intervention_designer_module.R", "modules/analysis_intervention.R"))

i18n_echo <- list(t = function(k, ...) k, translator = NULL)
proj <- function() {
  nodes <- data.frame(
    id = c("D_1", "A_1", "P_1", "MPF_1", "GB_1"),
    label = c("Demand", "Boating", "Anchoring", "P. oceanica extension", "Habitat"),
    group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning", "Goods & Benefits"),
    stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "A_1", "P_1", "MPF_1"), to = c("A_1", "P_1", "MPF_1", "GB_1"),
                      polarity = c("+", "+", "-", "+"), strength = "medium", stringsAsFactors = FALSE)
  list(data = list(cld = list(nodes = nodes, edges = edges)))
}
# Synchronous fake job API: runs the engine in-process.
fake_api <- function(fail = FALSE) {
  list(start = function(payload) list(payload = payload, type = "run"),
       start_compare = function(payload) list(payload = payload, type = "compare"),
       poll = function(job) {
         if (fail) return(list(state = "error", reason = "engine", message = "boom"))
         if (identical(job$type, "compare")) return(list(state = "done", result = suppressWarnings(ses_compare_structure(job$payload))))  # igraph warns on the acyclic fixture
         list(state = "done", result = ses_run_design(job$payload))
       },
       cancel = function(job) invisible(TRUE))
}
real_designer_server <- get("intervention_designer_server", envir = .GlobalEnv)

test_that("designer UI has the conventional contract", {
  ui <- intervention_designer_ui("dz", i18n_echo)
  expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"))
  expect_true(grepl("dz-", as.character(ui), fixed = TRUE))
  fm <- names(formals(intervention_designer_server))
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus", "job_api") %in% fm))
})

test_that("intervention page now has Quick compare and Designer tabs", {
  html <- as.character(analysis_intervention_ui("iv", i18n_echo))
  expect_true(grepl("modules.intervention_designer.tab_quick", html, fixed = TRUE))
  expect_true(grepl("modules.intervention_designer.tab_designer", html, fixed = TRUE))
  expect_true(grepl("iv-designer-", html, fixed = TRUE))
})

test_that("payload substitutes the node name at run time (review focus 2)", {
  net <- list(matrix = matrix(0, 2, 2, dimnames = rep(list(c("a", "b")), 2)))
  e <- data.frame(from = c(".NEW_NODE.", "b"), to = c("a", ".NEW_NODE."), kind = "intervention",
                  min_level = -1, max_level = 1, stringsAsFactors = FALSE)
  p <- .designer_payload(net, e, "Renamed IV", "a", character(0))
  expect_equal(p$design$new_node, "Renamed IV")
  expect_equal(p$design$edges$from, c("Renamed IV", "b"))
  expect_equal(p$design$edges$to, c("a", "Renamed IV"))
  e2 <- data.frame(from = "a", to = "a", kind = "context", min_level = 0, max_level = 1)
  expect_null(.designer_payload(net, e2, "", "a", character(0))$design$new_node)
})

test_that("server drives a design to results with a fake job API", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(name = "Moorings", type = "", node_targets = "Anchoring",
                      node_indicators = "P. oceanica extension")
    session$setInputs(add_node_edges = 1)
    expect_equal(nrow(rv$edges), 2L)
    session$setInputs(self_loop_node = "P. oceanica extension", add_self_loop = 1)
    expect_equal(nrow(rv$edges), 3L)
    session$setInputs(objectives = "P. oceanica extension", sustain = "Habitat")
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_null(rv$job)
    expect_false(is.null(rv$result))
    expect_equal(rv$result$n_eval, 7^3)
    expect_equal(rv$result$design_matrix$new_node, "Moorings")
    expect_error(output$results_ui, NA)
  })
})

test_that("renaming after adding edges carries them to the new name (review focus 2)", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(name = "Old", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1)
    session$setInputs(name = "New name", objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_equal(rv$result$design_matrix$new_node, "New name")
    # One variable edge: the top table still has one row per configuration and one level column
    expect_equal(nrow(rv$result$top_levels), 1L)
    js <- jsonlite::fromJSON(output$top_table)
    expect_equal(lengths(regmatches(js$x$container, gregexpr("<th>", js$x$container))),
                 5L + nrow(rv$result$design_matrix$edges))
    expect_false(grepl(">NA<", js$x$container, fixed = TRUE))
    # Criterion (c) is not evaluated for rows that failed (a): shown as a dash, not "NA"/"no"
    top <- rv$result$top
    expect_true(any(!top$a))
    col_c <- top_df()[[4]]                                    # the (c) column of the top table
    expect_length(col_c, nrow(top))
    expect_true(all(col_c[!top$a] == "\u2014"))
    expect_false(any(col_c[is.na(top$c)] %in% c("NA", "modules.intervention_designer.no")))
  })
})

test_that("Run is blocked with a reason when the design is incomplete", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    expect_equal(run_block_reason(), "modules.intervention_designer.need_edges")
    session$setInputs(name = "", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1)
    expect_equal(run_block_reason(), "modules.intervention_designer.need_name")
    session$setInputs(name = "Demand")
    expect_equal(run_block_reason(), "modules.intervention_designer.name_clash")
    session$setInputs(name = "IV", objectives = NULL)
    expect_equal(run_block_reason(), "modules.intervention_designer.need_objective")
  })
})

test_that("an existing edge is refused as a mode-B edge", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(edge_from = "Demand", edge_to = "Boating", add_edge = 1)
    expect_equal(nrow(rv$edges), 0L)
  })
})

test_that("a failing job shows an error and frees Run (review focus 5)", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api(fail = TRUE)), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_null(rv$job)
    expect_null(rv$result)
    expect_match(rv$error_detail, "boom")                    # raw worker text: log/detail only
    expect_match(rv$error, "modules.intervention_designer.context_job", fixed = TRUE)
    expect_false(grepl("boom", rv$error, fixed = TRUE))       # never shown to the user
    expect_null(run_block_reason())
  })
})

test_that("a timed-out job shows the translated timeout context", {
  api <- fake_api(); api$poll <- function(job) list(state = "error", reason = "timeout",
                                                    message = "designer run timed out after 600 s")
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = api), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_null(rv$job)
    expect_match(rv$error, "modules.intervention_designer.context_timeout", fixed = TRUE)
    expect_false(grepl("timed out", rv$error, fixed = TRUE))
  })
})

test_that("the pre-check is shown above the progress bar while the job runs (spec §6)", {
  api <- fake_api()
  api$poll <- function(job) list(state = "running", done = 0, total = 1000,
                                 precheck = "topology_change_needed")
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = api), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_false(is.null(rv$job))
    expect_equal(run_block_reason(), "modules.intervention_designer.job_running")
    html <- as.character(output$results_ui$html)
    expect_true(grepl("modules.intervention_designer.cancel", html, fixed = TRUE))
    prog <- as.character(output$progress_ui$html)
    pc_at <- regexpr("modules.intervention_designer.precheck.topology_change_needed", prog, fixed = TRUE)
    expect_gt(pc_at, 0)
    expect_lt(pc_at, regexpr("progress-bar", prog, fixed = TRUE))
    expect_false(grepl("modules.intervention_designer.cancel", prog, fixed = TRUE))
    session$setInputs(cancel = 1)
    expect_null(rv$job)
  })
})

test_that("node choices equal the matrix dimnames when CLD labels repeat", {
  p <- proj(); p$data$cld$nodes$label[5] <- "Demand"         # GB_1 relabelled to a duplicate
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo,
                         job_api = fake_api()), {
    expect_identical(net()$labels, rownames(net()$matrix))
    # Labels (not node ids) are exposed: no names carried over from cld_to_numeric_matrix
    expect_null(names(net()$labels))
    expect_null(names(rownames(net()$matrix)))
    expect_null(names(colnames(net()$matrix)))
    expect_equal(net()$labels[c(1, 5)], c("Demand", "Demand_1"))
    expect_equal(net()$types[match("Demand_1", net()$labels)], "Goods & Benefits")
  })
})

test_that("a self-loop that already exists in the network is refused", {
  p <- proj()
  p$data$cld$edges <- rbind(p$data$cld$edges, data.frame(from = "MPF_1", to = "MPF_1", polarity = "+",
                                                         strength = "medium", stringsAsFactors = FALSE))
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(self_loop_node = "P. oceanica extension", add_self_loop = 1)
    expect_equal(nrow(rv$edges), 0L)
  })
})

test_that("the edge editor keeps the selected edge and shows its range", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(edge_from = "Demand", edge_to = "Anchoring", add_edge = 1)
    session$setInputs(edge_from = "Boating", edge_to = "Habitat", add_edge = 2)
    session$setInputs(edge_from = "Demand", edge_to = "Habitat", add_edge = 3)
    expect_equal(nrow(rv$edges), 3L)
    session$setInputs(edit_edge = "3", min_level = "0", max_level = "1", apply_range = 1)
    expect_equal(c(rv$edges$min_level[3], rv$edges$max_level[3]), c(0, 1))
    html <- as.character(output$edge_editor_ui$html)
    expect_true(grepl('<option value="3" selected>', html, fixed = TRUE))   # selection survives the re-render
    session$setInputs(sign_nonpos = 1)
    expect_equal(c(rv$edges$min_level[3], rv$edges$max_level[3]), c(0, 0))
    expect_equal(c(rv$edges$min_level[1], rv$edges$max_level[1]), c(-1, 1))
  })
})

test_that("the design panel keeps the user's entries when project data is written", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    session$setInputs(name = "Moorings", objectives = "P. oceanica extension")
    s1 <- node_sig()
    p3 <- proj(); p3$last_modified <- Sys.time(); pd(p3)       # e.g. a Quick compare run writing back
    session$flushReact()
    expect_identical(node_sig(), s1)                          # same node set: the panel is not rebuilt
    p4 <- proj()
    p4$data$cld$nodes <- rbind(p4$data$cld$nodes, data.frame(id = "MPF_2", label = "Seagrass",
      group = "Marine Processes & Functioning", stringsAsFactors = FALSE))
    p4$data$cld$edges <- rbind(p4$data$cld$edges, data.frame(from = "MPF_2", to = "GB_1", polarity = "+",
      strength = "medium", stringsAsFactors = FALSE))
    pd(p4)
    session$flushReact()
    html <- as.character(output$design_ui$html)
    expect_true(grepl("Seagrass", html, fixed = TRUE))
    expect_true(grepl('value="Moorings"', html, fixed = TRUE))
    expect_true(grepl('<option value="P. oceanica extension" selected>', html, fixed = TRUE))
  })
})

test_that("edges that no longer match the CLD block Run", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    session$setInputs(edge_from = "Demand", edge_to = "Habitat", add_edge = 1,
                      objectives = "P. oceanica extension")
    expect_null(run_block_reason())
    p2 <- proj(); p2$data$cld$nodes <- p2$data$cld$nodes[-5, ]; p2$data$cld$edges <- p2$data$cld$edges[1:3, ]
    pd(p2)                                                    # "Habitat" deleted from the CLD
    expect_equal(run_block_reason(), "modules.intervention_designer.stale_edges")
    p3 <- proj()
    p3$data$cld$edges <- rbind(p3$data$cld$edges, data.frame(from = "D_1", to = "GB_1", polarity = "+",
                                                             strength = "medium", stringsAsFactors = FALSE))
    pd(p3)                                                    # the designed edge now exists in the CLD
    expect_equal(run_block_reason(), "modules.intervention_designer.edge_exists")
  })
})

test_that("app.R loads intervention_designer_module.R in OPTIONAL_MODULES", {
  root <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }
  app_src <- paste(readLines(file.path(root(), "app.R"), warn = FALSE), collapse = "\n")
  opt <- regmatches(app_src, regexpr("(?s)OPTIONAL_MODULES <- c\\(.*?\\n\\)", app_src, perl = TRUE))  # to the closing ")" line; comments contain ")"
  expect_length(opt, 1)
  expect_true(grepl("modules/intervention_designer_module.R", opt, fixed = TRUE))
})

test_that("the comparison uses the network the run used, not the current one (review focus 3)", {
  # A positive self-loop on the objective (and a positive P -> MPF edge) keeps its state
  # alive over the 1000 steps, so the top configuration passes (a) with non-zero states.
  proj_loop <- function() {
    p <- proj()
    p$data$cld$edges$polarity[3] <- "+"
    p$data$cld$edges <- rbind(p$data$cld$edges, data.frame(from = "MPF_1", to = "MPF_1", polarity = "+",
                                                           strength = "strong", stringsAsFactors = FALSE))
    p
  }
  pd <- shiny::reactiveVal(proj_loop())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    r <- rv$result
    expect_true(r$top$a[1])                                   # top row passes criterion (a)
    design_edges <- rv$edges
    p2 <- proj_loop(); p2$data$cld$edges <- p2$data$cld$edges[1:2, ]   # edited: P -> MPF, loop, MPF -> GB gone
    pd(p2)
    session$flushReact()
    session$setInputs(top_table_rows_selected = 1)
    cmp <- selected_comparison()
    expect_equal(sum(r$base != 0), 5L)                       # the run's network, 5 edges
    nodes <- rownames(r$base)
    fo <- ses_config_final_state(r$base, r$x0[seq_len(nrow(r$base))], r$steps)
    fi <- ses_config_final_state(ses_apply_config(r$design_matrix, r$top_levels[, 1]), r$x0, r$steps)
    expect_equal(cmp$node, nodes)
    expect_equal(cmp$state_original, unname(fo[nodes]))
    expect_equal(cmp$state_intervention, unname(fi[nodes]))
    # signs agree with criterion (a): every objective is strictly positive
    expect_true(all(cmp$state_intervention[match(r$objectives, cmp$node)] > 0))
    # ... and the comparison differs from one built on the edited (current) network
    cur <- net()$matrix
    expect_equal(sum(cur != 0), 2L)
    cur_dm <- ses_design_matrix(cur, .designer_payload(net(), design_edges, "IV", r$objectives,
                                                       character(0))$design, INTERVENTION_GRID_LEVELS)
    fo_cur <- ses_config_final_state(cur, r$x0[seq_len(nrow(cur))], r$steps)
    fi_cur <- ses_config_final_state(ses_apply_config(cur_dm, r$top_levels[, 1]), r$x0, r$steps)
    expect_false(isTRUE(all.equal(cmp$state_original, unname(fo_cur[nodes]))))
    expect_false(isTRUE(all.equal(cmp$state_intervention, unname(fi_cur[nodes]))))
    expect_error(output$compare_plot, NA)
  })
})

# -- Final review fix wave --------------------------------------------------------
# i18n stub that counts how often each key is translated (a key's count grows
# each time the output that uses it re-renders).
counting_i18n <- function() {
  cnt <- new.env()
  list(t = function(k, ...) { assign(k, get0(k, envir = cnt, inherits = FALSE, ifnotfound = 0) + 1, envir = cnt); k },
       translator = NULL,
       count = function(k) get0(k, envir = cnt, inherits = FALSE, ifnotfound = 0))
}
# 20 full-range context edges on empty cells of proj(): 7^20 combinations
many_edges <- function() {
  lab <- c("Demand", "Boating", "Anchoring", "P. oceanica extension", "Habitat")
  pairs <- expand.grid(from = lab, to = lab, stringsAsFactors = FALSE)
  existing <- paste(c("Demand", "Boating", "Anchoring", "P. oceanica extension"),
                    c("Boating", "Anchoring", "P. oceanica extension", "Habitat"))
  pairs <- pairs[!paste(pairs$from, pairs$to) %in% existing, ][1:20, ]
  data.frame(from = pairs$from, to = pairs$to, kind = "context", min_level = -1, max_level = 1,
             stringsAsFactors = FALSE)
}

test_that("a design with too many combinations blocks Run and grid_info does not error (item 1)", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(objectives = "P. oceanica extension", sustain = NULL)
    rv$edges <- many_edges()
    session$flushReact()
    expect_equal(nrow(rv$edges), 20L)
    expect_equal(run_block_reason(), "modules.intervention_designer.too_many_combinations")
    expect_error(output$grid_info, NA)
    expect_true(grepl("modules.intervention_designer.too_many_combinations",
                      as.character(output$grid_info$html), fixed = TRUE))
  })
})

test_that("grid_info does not error when edges grow too many while a job runs (item 1)", {
  api <- fake_api()
  api$poll <- function(job) list(state = "running", done = 0, total = 1000)
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = api), {
    session$setInputs(edge_from = "Demand", edge_to = "Habitat", add_edge = 1,
                      objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_false(is.null(rv$job))
    rv$edges <- many_edges()
    expect_error(session$flushReact(), NA)
    expect_error(output$grid_info, NA)
    expect_true(grepl("modules.intervention_designer.too_many_combinations",
                      as.character(output$grid_info$html), fixed = TRUE))
  })
})

test_that("payload carries the stability budget; a partial result shows the note (item 2)", {
  net <- list(matrix = matrix(0, 2, 2, dimnames = rep(list(c("a", "b")), 2)))
  e <- data.frame(from = "a", to = "b", kind = "context", min_level = -1, max_level = 1)
  expect_equal(.designer_payload(net, e, "", "a", character(0))$stability_budget_s,
               INTERVENTION_STABILITY_BUDGET_FRACTION * INTERVENTION_JOB_TIMEOUT_S)
  expect_equal(INTERVENTION_STABILITY_BUDGET_FRACTION, 0.7)
  run_with <- function(budget) {
    api <- fake_api()
    api$poll <- function(job) { job$payload$stability_budget_s <- budget
                                list(state = "done", result = ses_run_design(job$payload)) }
    html <- NULL
    # Positive P -> MPF and a self-loop on the objective: some rows pass (a)
    p <- proj(); p$data$cld$edges$polarity[3] <- "+"
    p$data$cld$edges <- rbind(p$data$cld$edges, data.frame(from = "MPF_1", to = "MPF_1", polarity = "+",
                                                           strength = "strong", stringsAsFactors = FALSE))
    testServer(real_designer_server,
               args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo,
                           job_api = api), {
      session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
      session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
      session$setInputs(run = 1)
      session$elapse(1100)
      expect_gt(rv$result$n_a, 0)
      html <<- as.character(output$results_ui$html)
    })
    html
  }
  expect_true(grepl("modules.intervention_designer.stability_partial", run_with(0), fixed = TRUE))
  expect_false(grepl("modules.intervention_designer.stability_partial", run_with(NULL), fixed = TRUE))
})

test_that("a stale edge or self-loop label is ignored without ending the session (item 5)", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    expect_error(session$setInputs(edge_from = "Gone", edge_to = "Demand", add_edge = 1), NA)
    expect_error(session$setInputs(edge_from = "Demand", edge_to = "Gone", add_edge = 2), NA)
    expect_error(session$setInputs(self_loop_node = "Gone", add_self_loop = 1), NA)
    expect_equal(nrow(rv$edges), 0L)
    session$setInputs(edge_from = "Demand", edge_to = "Habitat", add_edge = 3)   # still works afterwards
    expect_equal(nrow(rv$edges), 1L)
  })
})

test_that("progress ticks re-render only the progress output, not the card with Cancel (item 6)", {
  tick <- 0
  api <- fake_api()
  api$poll <- function(job) { tick <<- tick + 100
                              list(state = "running", done = tick, total = 1000, precheck = "passed") }
  i18n_c <- counting_i18n()
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_c,
                         job_api = api), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_true(grepl("modules.intervention_designer.cancel", as.character(output$results_ui$html), fixed = TRUE))
    p1 <- as.character(output$progress_ui$html)
    n_card <- i18n_c$count("modules.intervention_designer.cancel")
    n_pc <- i18n_c$count("modules.intervention_designer.precheck.passed")
    expect_gt(n_card, 0)
    session$elapse(1000)
    session$elapse(1000)
    expect_gt(tick, 200)
    p2 <- as.character(output$progress_ui$html)
    expect_false(identical(p1, p2))                                  # the bar moved
    expect_equal(i18n_c$count("modules.intervention_designer.cancel"), n_card)   # the card did not re-render
    expect_equal(i18n_c$count("modules.intervention_designer.precheck.passed"), n_pc + 2)
  })
})

test_that("Cancel after the job finished does nothing (item 7)", {
  n_cancel <- 0
  api <- fake_api()
  api$cancel <- function(job) { n_cancel <<- n_cancel + 1; invisible(TRUE) }
  i18n_c <- counting_i18n()
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_c,
                         job_api = api), {
    session$setInputs(name = "IV", type = "", node_targets = "Anchoring", node_indicators = NULL)
    session$setInputs(add_node_edges = 1, objectives = "P. oceanica extension", sustain = NULL)
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_null(rv$job)
    expect_false(is.null(rv$result))
    session$setInputs(cancel = 1)                                   # stale click
    expect_equal(n_cancel, 0)
    expect_equal(i18n_c$count("modules.intervention_designer.cancelled"), 0)
    expect_false(is.null(rv$result))
  })
})

test_that("mode C: ticked links become sign-fixed reweight rows", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo,
                         job_api = fake_api()), {
    session$setInputs(name = "", type = "", rw_links = c("Boating\rAnchoring", "Anchoring\rP. oceanica extension"))
    session$setInputs(add_reweight = 1)
    expect_equal(rv$edges$kind, c("reweight", "reweight"))
    expect_equal(rv$edges$min_level, c(0.25, -1))
    expect_equal(rv$edges$max_level, c(1, -0.25))
    session$setInputs(rw_node = "Demand", add_node_links = 1)
    expect_equal(nrow(rv$edges), 3L)                            # Demand -> Boating added once
    session$setInputs(objectives = "P. oceanica extension", sustain = NULL)
    expect_null(run_block_reason())
    session$setInputs(run = 1)
    session$elapse(1100)
    expect_equal(rv$result$n_eval, 27)
  })
})

test_that("mode C: a link that changed sign or vanished blocks Run (review focus 1)", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    session$setInputs(name = "", type = "", rw_links = "Boating\rAnchoring", objectives = "Habitat")
    session$setInputs(add_reweight = 1)
    expect_null(run_block_reason())
    p <- proj(); p$data$cld$edges$polarity[2] <- "-"; pd(p)    # Boating -> Anchoring flipped
    session$flushReact()
    expect_equal(run_block_reason(), "modules.intervention_designer.reweight_stale")
    p$data$cld$edges <- p$data$cld$edges[-2, ]; pd(p)          # and now deleted
    session$flushReact()
    expect_equal(run_block_reason(), "modules.intervention_designer.reweight_stale")
  })
})

test_that("mode C: ranking falls back to an unranked list (review focus 4)", {
  p <- proj()
  p$data$cld$edges <- data.frame(from = c("D_1", "A_1"), to = c("A_1", "D_1"), polarity = "+",
                                 strength = "strong", stringsAsFactors = FALSE)   # eigenvalues 1 and -1
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(p), i18n = i18n_echo, job_api = fake_api()), {
    expect_null(link_rank()$ranked)
    expect_equal(nrow(link_rank()$links), 2L)
    expect_match(as.character(output$reweight_ui$html), "modules.intervention_designer.ranking_unavailable")
  })
})

run_mode_c <- function(session) {
  session$setInputs(name = "", type = "", rw_links = c("Boating\rAnchoring", "Anchoring\rP. oceanica extension"),
                    objectives = "Habitat", sustain = NULL)
  session$setInputs(add_reweight = 1)
  session$setInputs(run = 1)
  session$elapse(1100)
}

test_that("dependence table is built from the result", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo, job_api = fake_api()), {
    run_mode_c(session)
    expect_false(is.null(rv$result$dependence) && rv$result$n_a > 0)
    expect_error(output$dependence_ui, NA)
  })
})

test_that("Compare runs as its own job and fills rv$compare", {
  testServer(real_designer_server,
             args = list(project_data_reactive = shiny::reactiveVal(proj()), i18n = i18n_echo, job_api = fake_api()), {
    run_mode_c(session)
    session$setInputs(top_table_rows_selected = 1)
    session$setInputs(compare = 1)
    session$elapse(1100)
    expect_null(rv$cmp_job)
    expect_named(rv$compare, c("loops", "loop_diff", "leverage", "attractors"))
    expect_error(output$compare_ui, NA)
  })
})

test_that("Apply writes one designer scenario into the project", {
  pd <- shiny::reactiveVal(proj())
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api()), {
    run_mode_c(session)
    session$setInputs(top_table_rows_selected = 1)
    session$setInputs(apply = 1)
    session$setInputs(apply_name = "My scenario", apply_description = "x", confirm_apply = 1)
    sc <- pd()$data$analysis$scenarios
    expect_length(sc, 1L)
    expect_equal(sc[[1]]$source, "intervention_designer")
    expect_equal(sc[[1]]$name, "My scenario")
    session$setInputs(confirm_apply = 2)                        # same name again
    expect_equal(pd()$data$analysis$scenarios[[2]]$name, "My scenario (2)")
  })
})

test_that("Apply is refused after the network changed", {
  pd <- shiny::reactiveVal(proj())
  eb <- list(on_isa_change = function() pd())                   # minimal bus: fires on project change
  testServer(real_designer_server,
             args = list(project_data_reactive = pd, i18n = i18n_echo, job_api = fake_api(), event_bus = eb), {
    run_mode_c(session)
    p <- proj(); p$data$cld$edges$strength[1] <- "strong"; pd(p)
    session$flushReact()
    expect_true(rv$stale)
    session$setInputs(top_table_rows_selected = 1, apply = 1, apply_name = "S", apply_description = "", confirm_apply = 1)
    expect_length(pd()$data$analysis$scenarios, 0L)
  })
})
