# tests/testthat/test-dead-code-ai-isa.R
# Review 2026-10-07 N66 / N68: dead helpers removed; keep them from coming back
# as silent duplicates of live code.
proj <- function(...) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, ...); if (file.exists(p)) return(p)
  }
  file.path(getwd(), "../..", ...)
}
defs_of <- function(name) {
  files <- c(list.files(proj("functions"), "[.]R$", full.names = TRUE),
             list.files(proj("modules"), "[.]R$", full.names = TRUE, recursive = TRUE))
  sum(vapply(files, function(f) sum(grepl(paste0("^\\s*", name, " <- function"), readLines(f, warn = FALSE))), integer(1)))
}

test_that("N66: unused AI ISA sub-module copies are gone; live copies remain once", {
  for (fn in c("setup_session_initialization", "setup_auto_save", "setup_save_load_handlers",
               "setup_breadcrumb_navigation", "setup_progress_outputs", "setup_preview_modal",
               "setup_start_over_modal", "setup_element_viewer_modals",
               "get_ai_isa_css", "get_ai_isa_js", "setup_ui_outputs")) {
    expect_equal(defs_of(fn), 0L, info = fn)
  }
  expect_equal(defs_of("process_answer"), 1L)      # the live inline one
  expect_equal(defs_of("highlight_keywords"), 1L)  # the live inline one
  expect_equal(defs_of("define_question_flow"), 1L)
  expect_equal(defs_of("render_element_summary_ui"), 1L)
  expect_false(file.exists(proj("modules", "ai_isa", "answer_processor.R")))
})

test_that("N66: the live process_answer kept the input validation of the removed copy", {
  s <- paste(readLines(proj("modules", "ai_isa_assistant_module.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("process_answer: invalid answer", s, fixed = TRUE))
  expect_true(grepl("process_answer: invalid step_info", s, fixed = TRUE))
  expect_false(grepl("ai_isa/answer_processor.R\", local", s, fixed = TRUE))
})

test_that("N68: uncalled, untested helpers are gone", {
  for (fn in c("create_undo_reactive", "add_inferred_types", "analyze_type_inference",
               "predict_connection_enhanced", "run_with_progress", "has_async_support")) {
    expect_equal(defs_of(fn), 0L, info = fn)
  }
  expect_false(file.exists(proj("functions", "async_helpers.R")))
})
