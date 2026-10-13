# test-prod-log-errors-2026-10-13.R
# Regression tests for the errors tallied in the laguna worker logs on
# 2026-10-13 (besides the reactive-loop hang covered by
# test-ai-isa-recovery-loop.R):
#   - "Error in data.frame: arguments imply differing number of rows: 0, 1"
#     in build_leverage_reset_data (leverage switch off on an empty CLD)
#   - "Error in $: $ operator is invalid for atomic vectors" in
#     bs4TimelineItem from output$dashboard_timeline (icon passed as a string)
#   - "object 'QUESTION_FLOW' not found" in observeEvent(input$confirm_start_over)
#     (action_handlers.R is sourced at file level, so the module-local
#     QUESTION_FLOW was out of scope)
#   - eigen_centrality() unguarded on the full graph in calculate_network_metrics
#     (the codebase already notes it can hang on disconnected graphs)

library(testthat)
library(shiny)

# ---------------------------------------------------------------------------
# build_leverage_reset_data
# ---------------------------------------------------------------------------

test_that("build_leverage_reset_data tolerates an empty or NULL node frame", {
  skip_if_not(exists("build_leverage_reset_data", mode = "function"))

  empty_nodes <- data.frame(id = character(0), color = character(0), font.size = integer(0),
                            stringsAsFactors = FALSE)
  res <- build_leverage_reset_data(empty_nodes, data.frame())
  expect_equal(nrow(res$reset_nodes), 0L)
  expect_equal(nrow(res$reset_edges), 0L)

  res_null <- build_leverage_reset_data(NULL, NULL)
  expect_equal(nrow(res_null$reset_nodes), 0L)
  expect_equal(nrow(res_null$reset_edges), 0L)
})

test_that("build_leverage_reset_data still resets a populated CLD and tolerates missing style columns", {
  skip_if_not(exists("build_leverage_reset_data", mode = "function"))

  nodes <- data.frame(id = c("D1", "A1"), color = c("#111111", "#222222"), font.size = c(14, 14),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = "D1", to = "A1", stringsAsFactors = FALSE)
  res <- build_leverage_reset_data(nodes, edges)
  expect_equal(res$reset_nodes$id, c("D1", "A1"))
  expect_false(any(res$reset_nodes$hidden))
  expect_equal(res$reset_edges$id, 1L)

  bare <- data.frame(id = c("D1", "A1"), stringsAsFactors = FALSE)
  expect_silent(res2 <- build_leverage_reset_data(bare, edges))
  expect_equal(nrow(res2$reset_nodes), 2L)
})

# ---------------------------------------------------------------------------
# safe_eigen_centrality / calculate_network_metrics
# ---------------------------------------------------------------------------

test_that("safe_eigen_centrality returns a full-length vector on disconnected and edgeless graphs", {
  skip_if_not(exists("safe_eigen_centrality", mode = "function"))

  g_disc <- igraph::graph_from_data_frame(
    data.frame(from = c("a", "b", "d"), to = c("b", "a", "e")),
    directed = TRUE,
    vertices = data.frame(name = c("a", "b", "c", "d", "e"))
  )
  ev <- safe_eigen_centrality(g_disc)
  expect_length(ev, 5L)
  expect_true(all(is.finite(ev)))
  expect_equal(ev[3], 0)  # isolated vertex "c"

  g_edgeless <- igraph::make_empty_graph(n = 3, directed = TRUE)
  expect_equal(safe_eigen_centrality(g_edgeless), c(0, 0, 0))
  expect_length(safe_eigen_centrality(igraph::make_empty_graph(n = 0)), 0L)
})

test_that("calculate_network_metrics uses the guarded eigenvector path", {
  skip_if_not(exists("calculate_network_metrics", mode = "function"))

  nodes <- data.frame(id = c("a", "b", "c", "d"), label = c("a", "b", "c", "d"),
                      group = "Drivers", stringsAsFactors = FALSE)
  edges <- data.frame(from = c("a", "c"), to = c("b", "d"), polarity = "+",
                      stringsAsFactors = FALSE)
  m <- calculate_network_metrics(nodes, edges)
  expect_length(m$eigenvector, 4L)
  expect_true(all(is.finite(m$eigenvector)))

  src <- readLines(file.path(
    if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd(),
    "functions", "network_analysis.R"))
  expect_false(any(grepl("eigenvector = tryCatch(eigen_centrality(g", src, fixed = TRUE)),
               label = "calculate_network_metrics no longer calls eigen_centrality unguarded")
})

# ---------------------------------------------------------------------------
# dashboard timeline: bs4TimelineItem needs an icon tag, not a name
# ---------------------------------------------------------------------------

test_that("dashboard timeline renders when the project has elements (icon passed as a tag)", {
  td   <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  skip_if_not(file.exists(file.path(root, "server", "dashboard.R")))
  if (!exists("setup_dashboard_rendering", mode = "function")) {
    sys.source(file.path(root, "server", "dashboard.R"), envir = .GlobalEnv)
  }
  setup_fn <- get("setup_dashboard_rendering", envir = .GlobalEnv)
  i18n <- list(t = function(key, ...) key, get_translation_language = function() "en")

  pd <- reactiveVal(list(
    last_modified = Sys.time(),
    data = list(
      metadata = list(created = as.Date("2026-10-01")),
      isa_data = list(
        drivers = data.frame(id = "D001", name = "Food demand", stringsAsFactors = FALSE),
        adjacency_matrices = list()
      ),
      cld = list(
        nodes = data.frame(id = "D001", label = "Food demand", leverage_score = 0.5,
                           stringsAsFactors = FALSE),
        edges = data.frame(from = character(0), to = character(0))
      )
    )
  ))

  html <- NULL
  testServer(
    function(input, output, session) setup_fn(input, output, session, pd, i18n),
    {
      session$flushReact()
      html <- as.character(htmltools::renderTags(output$dashboard_timeline$html)$html)
      if (is.null(html) || !nzchar(html)) html <- output$dashboard_timeline$html
      html <<- html
    }
  )
  expect_true(is.character(html) && nzchar(html))
  # Four events: created, SES framework, CLD, analysis
  expect_gte(length(gregexpr("timeline-item", html, fixed = TRUE)[[1]]), 4L)
  expect_true(grepl("fa-layer-group", html, fixed = TRUE) || grepl("layer-group", html, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# AI ISA "Start over": QUESTION_FLOW must reach the action handlers
# ---------------------------------------------------------------------------

test_that("confirm_start_over resets the assistant instead of erroring on QUESTION_FLOW", {
  td   <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  local({
    old_wd <- setwd(root); on.exit(setwd(old_wd), add = TRUE)
    for (sm in c("modules/ai_isa/connection_generator.R", "modules/ai_isa/ui_components.R",
                 "modules/ai_isa/question_flow.R", "modules/ai_isa/data_persistence.R",
                 "modules/ai_isa/ui_renderers.R", "modules/ai_isa/template_handlers.R",
                 "modules/ai_isa/action_handlers.R", "modules/ai_isa/step_navigation.R")) {
      sys.source(file.path(root, sm), envir = .GlobalEnv)
    }
    sys.source(file.path(root, "modules/ai_isa_assistant_module.R"), envir = .GlobalEnv)
  })
  server_fn <- get("ai_isa_assistant_server", envir = .GlobalEnv)
  i18n <- list(t = function(key, ...) key, get_translation_language = function() "en")
  pd <- reactiveVal(list(project_id = "p", name = "p", data = list(isa_data = list())))

  state <- NULL
  testServer(server_fn, args = list(project_data_reactive = pd, i18n = i18n), {
    session$flushReact()
    rv$current_step <- 4
    rv$elements$drivers <- list(list(name = "Food demand", description = "", timestamp = Sys.time()))
    rv$conversation <- c(rv$conversation, list(list(type = "user", message = "x", timestamp = Sys.time())))
    session$setInputs(confirm_start_over = 1)
    session$flushReact()
    state <<- list(step = rv$current_step, n_drivers = length(rv$elements$drivers),
                   conversation = rv$conversation)
  })

  expect_equal(state$step, 0)
  expect_equal(state$n_drivers, 0L)
  expect_length(state$conversation, 1L)
  expect_equal(state$conversation[[1]]$type, "ai")
  expect_true(nzchar(state$conversation[[1]]$message))
})
