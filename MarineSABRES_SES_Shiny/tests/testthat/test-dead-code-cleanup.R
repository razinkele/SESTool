# tests/testthat/test-dead-code-cleanup.R
# Review 2026-10-07 dead-code / duplicate-definition batch: N39, N65, N67, N69, N70, N71.
proj <- function(...) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, ...)
    if (file.exists(p)) return(normalizePath(p, winslash = "/"))
  }
  file.path(getwd(), "../..", ...)
}
src_of <- function(...) paste(readLines(proj(...), warn = FALSE), collapse = "\n")
count_defs <- function(name) {
  files <- c(list.files(proj("functions"), "[.]R$", full.names = TRUE),
             list.files(proj("modules"), "[.]R$", full.names = TRUE, recursive = TRUE),
             proj("utils.R"), proj("global.R"))
  sum(vapply(files, function(f) sum(startsWith(readLines(f, warn = FALSE), paste0(name, " <- function"))), integer(1)))
}

# ---- N39 -------------------------------------------------------------------
test_that("N39: get_countries_for_sea has one definition returning name_en records", {
  expect_equal(count_defs("get_countries_for_sea"), 1L)
  res <- get_countries_for_sea("baltic")
  expect_gte(length(res), 5L)
  expect_true(all(vapply(res, function(r) is.character(r$name_en) && nzchar(r$name_en), logical(1))))
  expect_identical(get_countries_for_sea(NULL), list())
  expect_identical(get_countries_for_sea(NA_character_), list())
})

test_that("N39: AI ISA country labels use name_en, not partial matching on $name", {
  s <- src_of("modules/ai_isa_assistant_module.R")
  expect_false(grepl("country$name,", s, fixed = TRUE))
  expect_false(grepl("country$name\n", s, fixed = TRUE))
  expect_false(grepl("function(c) c$name)", s, fixed = TRUE))
})

# ---- N65 -------------------------------------------------------------------
test_that("N65: one safe_scale; NA, all-NA, length-1 and constant input are safe", {
  expect_equal(count_defs("safe_scale"), 1L)
  expect_equal(safe_scale(c(NA, NA)), c(0, 0))
  expect_equal(safe_scale(5), 0)
  expect_equal(safe_scale(numeric(0)), numeric(0))
  expect_equal(safe_scale(c(3, 3, 3)), c(0, 0, 0))
  r <- safe_scale(c(1, NA, 3))
  expect_false(anyNA(r))
  expect_equal(r, c(-1 / sqrt(2), 0, 1 / sqrt(2)))
  expect_equal(safe_scale(1:5), as.numeric(scale(1:5)))
})

# ---- N67 -------------------------------------------------------------------
test_that("N67: dead entry points are gone and the leverage module uses the tested function", {
  for (fn in c("pims_stakeholders_ui", "pims_stakeholders_server",
               "local_storage_settings_ui", "generate_html_report", ".element_html_table")) {
    expect_equal(count_defs(fn), 0L, info = fn)
  }
  lev <- src_of("modules/analysis_leverage.R")
  expect_true(grepl("identify_leverage_points(g, top_n = igraph::vcount(g))", lev, fixed = TRUE))
  expect_false(grepl("safe_scale(", lev, fixed = TRUE))
})

test_that("N67: identify_leverage_points with top_n = all ranks every node", {
  nodes <- data.frame(id = c("a", "b", "c", "d"), label = c("A", "B", "C", "D"), stringsAsFactors = FALSE)
  edges <- data.frame(from = c("a", "b", "c", "a"), to = c("b", "c", "a", "d"),
                      polarity = "+", stringsAsFactors = FALSE)
  g <- create_igraph_from_data(nodes, edges)
  res <- identify_leverage_points(g, top_n = igraph::vcount(g))
  expect_equal(nrow(res), 4L)
  expect_false(is.unsorted(rev(res$Composite_Score)))
})

# ---- N69 -------------------------------------------------------------------
test_that("N69: files sourced twice are now exists()-guarded or sourced once", {
  g <- src_of("global.R")
  expect_true(grepl('if (!exists("safe_readRDS", mode = "function")) {\n  source("functions/utils.R"', g, fixed = TRUE))
  expect_true(grepl('if (!exists("connection_predictor")) {', g, fixed = TRUE))
  expect_true(grepl('if (!exists("load_ml_model", mode = "function")) {', g, fixed = TRUE))
  expect_false(grepl('"functions/ui_sidebar.R"', src_of("app.R"), fixed = TRUE))
  expect_true(grepl('if (!exists("clear_template_cache", mode = "function"))',
                    src_of("modules/template_ses_module.R"), fixed = TRUE))
})

# ---- N70 / N71 -------------------------------------------------------------
test_that("N70: the unreferenced server/session_management.R is gone", {
  expect_false(file.exists(proj("server", "session_management.R")))
  expect_false(grepl("session_management.R", src_of("app.R"), fixed = TRUE))
})

test_that("N71: no stale DEFERRED / read-only headers above implemented features", {
  expect_false(grepl("DEFERRED", src_of("functions/decision_lens.R"), fixed = TRUE))
  expect_false(grepl("DEFERRED", src_of("modules/analysis_decision_lens.R"), fixed = TRUE))
  expect_false(grepl("Adjacency matrix viewer (read-only)", src_of("modules/isa_data_entry_module.R"), fixed = TRUE))
})
