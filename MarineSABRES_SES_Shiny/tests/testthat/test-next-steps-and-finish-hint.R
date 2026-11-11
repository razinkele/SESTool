# tests/testthat/test-next-steps-and-finish-hint.R
# User feedback 2026-11-11 (two bugs from one tester):
#  - "Response measures": the Leverage page's next-step card "Response Measures"
#    did nothing when clicked. It pointed at Standard Entry (wrong page), which
#    is not in a beginner's sidebar, so updateTabItems() had nothing to switch
#    to. Same dead click for the Loops page's "Network Metrics" card.
#  - "No button": after the last connection category, the shared review said
#    "click 'Finish & Continue' below", a button only the AI assistant has.

source_for_test(c("functions/tool_recommendations.R", "functions/ui_sidebar.R"))

app_root <- function() {
  d <- getwd()
  if (basename(d) == "testthat") dirname(dirname(d)) else d
}
i18n_stub <- list(t = function(k) k)
tabs_for <- function(level) {
  s <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(s, {
    set_active_level_config(level)
    sidebar_tab_ids(level, i18n_stub)
  })
}

test_that("the 'Response Measures' next step opens the Response Measures page", {
  recs <- get_next_steps("analysis_leverage")
  resp <- Filter(function(r) r$label_key == "modules.tool_recommendations.leverage.responses_label", recs)
  expect_length(resp, 1)
  expect_identical(resp[[1]]$tab_id, "response_measures")
})

test_that("sidebar_tab_ids() lists exactly the pages in that level's sidebar", {
  beg <- tabs_for("beginner")
  exp <- tabs_for("expert")
  expect_true(all(c("analysis_loops", "analysis_leverage") %in% beg))
  expect_false(any(c("response_measures", "create_ses_standard", "analysis_metrics") %in% beg))
  expect_true(all(c("response_measures", "create_ses_standard", "analysis_metrics",
                    "analysis_leverage") %in% exp))
})

test_that("every next-step target is a real page for experts", {
  exp <- tabs_for("expert")
  for (m in c("analysis_loops", "analysis_leverage", "analysis_metrics", "analysis_decision_lens")) {
    for (r in get_next_steps(m)) expect_true(r$tab_id %in% exp, info = paste(m, r$tab_id))
  }
})

test_that("next-step cards for pages missing from the sidebar are hidden; link ids stay stable", {
  ns <- shiny::NS("lev")
  recs <- get_next_steps("analysis_leverage")
  avail <- setdiff(vapply(recs, `[[`, "", "tab_id"), "response_measures")
  html <- as.character(build_next_steps_ui("analysis_leverage", ns, i18n_stub, available_tabs = avail))
  idx <- which(vapply(recs, `[[`, "", "tab_id") == "response_measures")
  expect_false(grepl(sprintf('id="lev-next_step_%d"', idx), html, fixed = TRUE))
  for (i in setdiff(seq_along(recs), idx)) {
    expect_true(grepl(sprintf('id="lev-next_step_%d"', i), html, fixed = TRUE), info = i)
  }
  # no filter -> all cards (backwards compatible)
  all_html <- as.character(build_next_steps_ui("analysis_leverage", ns, i18n_stub))
  expect_true(grepl(sprintf('id="lev-next_step_%d"', idx), all_html, fixed = TRUE))
  # nothing reachable -> no panel
  expect_null(build_next_steps_ui("analysis_leverage", ns, i18n_stub, available_tabs = character(0)))
})

test_that("app.R gives the analysis pages with next steps the user level", {
  app <- paste(readLines(file.path(app_root(), "app.R"), warn = FALSE), collapse = "\n")
  for (fn in c("analysis_loops_server", "analysis_leverage_server", "analysis_decision_lens_server")) {
    expect_match(app, paste0(fn, "\\([^)]*user_level_reactive = user_level"), info = fn)
  }
})

test_that("the end-of-review hint names no host-specific button", {
  tr <- jsonlite::fromJSON(file.path(app_root(), "translations", "common", "misc.json"),
                           simplifyVector = FALSE)$translation
  entry <- tr[["common.misc.you_can_now_finish_and_continue"]]
  expect_false(is.null(entry))
  langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
  expect_setequal(intersect(names(entry), langs), langs)
  expect_false(grepl("Finish", entry$en, fixed = TRUE))
  # the old text quoted the AI assistant's button label in every language
  for (lang in langs) expect_false(grepl("'", entry[[lang]], fixed = TRUE), info = lang)
})
