# tests/testthat/test-analysis-modules-batch.R
# Review 2026-10-07, analysis-module batch: N30-N36.
source_for_test(c("modules/analysis_intervention.R", "modules/scenario_builder_module.R",
                  "modules/analysis_decision_lens.R", "modules/connection_review_tabbed.R",
                  "modules/analysis_simulation.R"))

mk_cld <- function() {
  nodes <- data.frame(id = c("D1", "A1", "P1", "C1", "C2"),
                      label = c("Food demand", "Fishing", "Bycatch", "Fish stock", "Seals"),
                      group = c("Drivers", "Activities", "Pressures", "Marine Processes", "Marine Processes"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D1", "A1", "P1", "C1", "C1", "C2"),
                      to   = c("A1", "P1", "C1", "D1", "C2", "C1"),
                      polarity = c("+", "+", "-", "-", "+", "-"),
                      strength = "medium", confidence = 3,
                      stringsAsFactors = FALSE)
  list(nodes = nodes, edges = edges)
}

# ---- N32 -------------------------------------------------------------------
test_that("N32: loop highlight resolves by stored NodeIDs, not by position", {
  info <- data.frame(LoopID = 1:2, NodeIDs = c("A1,P1,C1", "X9,C2"), stringsAsFactors = FALSE)
  current <- c("C2", "C1", "P1", "A1")            # order changed since analysis
  expect_identical(loop_highlight_node_ids(info, 1, c(1, 2, 3), current), c("A1", "P1", "C1"))
  # unknown ids are dropped
  expect_identical(loop_highlight_node_ids(info, 2, integer(0), current), "C2")
})

test_that("N32: legacy saves without NodeIDs fall back to positional indices", {
  expect_identical(loop_highlight_node_ids(NULL, 1, c(2, 9, 1), c("a", "b", "c")), c("b", "a"))
  expect_identical(loop_highlight_node_ids(data.frame(x = 1), 1, 3, c("a", "b", "c")), "c")
})

# ---- N33 -------------------------------------------------------------------
test_that("N33: scenario_loops returns real cycles as objects the panel can render", {
  res <- scenario_loops(mk_cld())
  # D1->A1->P1->C1->D1 is the only cycle longer than 2 (C1<->C2 is excluded)
  expect_equal(res$count, 1L)
  expect_length(res$loops, 1)
  expect_true(all(c("type", "nodes") %in% names(res$loops[[1]])))
  expect_setequal(res$loops[[1]]$nodes, c("Food demand", "Fishing", "Bycatch", "Fish stock"))
  expect_true(nzchar(res$loops[[1]]$type))
})

test_that("N33: scenario_loops is empty-safe", {
  expect_equal(scenario_loops(NULL)$count, 0L)
  net <- mk_cld(); net$edges <- net$edges[0, ]
  expect_equal(scenario_loops(net)$count, 0L)
})

test_that("N33: the module no longer defines a local detect_feedback_loops and stores a baseline count", {
  src <- paste(readLines(file.path(getwd(), "../../modules/scenario_builder_module.R"), warn = FALSE), collapse = "\n")
  if (!nzchar(src)) src <- paste(readLines("modules/scenario_builder_module.R"), collapse = "\n")
  expect_false(grepl("detect_feedback_loops <- function", src, fixed = TRUE))
  expect_false(grepl("data$loop_detection", src, fixed = TRUE))
  expect_true(grepl("baseline_loop_count = baseline_loop_count", src, fixed = TRUE))
})

# ---- N31 / N34 -------------------------------------------------------------
read_src <- function(rel) {
  for (p in c(file.path(getwd(), "../..", rel), rel)) if (file.exists(p)) return(paste(readLines(p, warn = FALSE), collapse = "\n"))
  stop("not found: ", rel)
}

test_that("N31: simulation and intervention never reuse a cached matrix", {
  sim <- read_src("modules/analysis_simulation.R")
  expect_false(grepl("\"dynamics\", \"numeric_matrix\"", sim, fixed = TRUE))
  int <- read_src("modules/analysis_intervention.R")
  expect_false(grepl("if (is.null(rv$numeric_matrix))", int, fixed = TRUE))
  # each intervention is rebuilt from its spec at run time
  expect_true(grepl("int$matrix <- ses_add_intervention(", int, fixed = TRUE))
})

test_that("N34: interventions can be removed, and the remove button carries the name", {
  srv <- get("analysis_intervention_server", envir = .GlobalEnv)
  pd <- shiny::reactiveVal(list(data = list(cld = mk_cld())))
  i18n <- list(t = function(k, ...) k)
  shiny::testServer(srv, args = list(project_data_reactive = pd, i18n = i18n), {
    session$setInputs(intervention_name = "Quota", affected_nodes = c("A1"),
                      indicator_nodes = c("C1"), effect_range = c(-0.5, 0.5), n_iter = 100)
    session$setInputs(add_intervention = 1)
    session$setInputs(intervention_name = "MPA", affected_nodes = c("C1"))
    session$setInputs(add_intervention = 2)
    expect_setequal(names(rv$interventions), c("Quota", "MPA"))

    html <- as.character(output$interventions_list$html)
    expect_true(grepl("remove_intervention", html, fixed = TRUE))

    session$setInputs(remove_intervention = "Quota")
    expect_identical(names(rv$interventions), "MPA")
    session$setInputs(remove_intervention = "nonexistent")   # ignored
    expect_identical(names(rv$interventions), "MPA")
  })
})

test_that("N34: failed comparisons are shown in the results panel", {
  int <- read_src("modules/analysis_intervention.R")
  expect_true(grepl("length(rv$error_message) > 0", int, fixed = TRUE))
})

# ---- N30 / N35 / N36 -------------------------------------------------------
test_that("N30: connection-review observers are destroyed before being regenerated", {
  src <- read_src("modules/connection_review_tabbed.R")
  expect_true(grepl("obs_env$batch <- destroy_all(obs_env$batch)", src, fixed = TRUE))
  expect_true(grepl("obs_env$conn <- destroy_all(obs_env$conn)", src, fixed = TRUE))
  n_tracked <- sum(vapply(c("obs_env$batch[[length", "obs_env$conn[[length"), function(s) lengths(regmatches(src, gregexpr(s, src, fixed = TRUE))), integer(1)))
  expect_equal(n_tracked, 6L)
})

test_that("N35/N36: decision lens resets loops first and drops 1- and 2-node cycles", {
  src <- read_src("modules/analysis_decision_lens.R")
  reset_at <- regexpr("rv$loop_info <- NULL", src, fixed = TRUE)
  factors_at <- regexpr("rv$factors <- classify_factors_micmac", src, fixed = TRUE)
  expect_true(reset_at > 0 && reset_at < factors_at)
  expect_true(grepl("Filter(function(l) length(l) > 2, loops)", src, fixed = TRUE))
  # the node picker is filled before the loop step can fail
  expect_true(regexpr("updateSelectInput(session, \"why_node\"", src, fixed = TRUE) <
              regexpr("find_all_cycles(g$nodes", src, fixed = TRUE))
})
