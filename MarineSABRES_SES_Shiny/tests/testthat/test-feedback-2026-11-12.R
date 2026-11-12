# tests/testthat/test-feedback-2026-11-12.R
# Live feedback 2026-11-12 (one tester, v1.35.4):
#  L27 "Colours of the headlines": card titles in the blue card headers were
#      dark blue on blue. The global h1-h6 colour beat the white inherited
#      from .card-header.
#  L28 "Table of Loop Strength Analysis": the axis stopped before the longest
#      bars (barplot's default xlim ends at the data maximum, the last tick
#      below it), the legend covered the bottom bar, and the dominance table
#      showed raw scores such as 33.33333.
#  L29 "Feedback Loop report download": the button said PDF, the file is Word.

source_for_test(c("functions/network_analysis.R", "modules/analysis_loops.R"))
analysis_loops_ui <- get("analysis_loops_ui", envir = .GlobalEnv)

app_root <- function() {
  d <- getwd()
  if (basename(d) == "testthat") dirname(dirname(d)) else d
}
LANGS <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

loops_df <- function() {
  data.frame(
    LoopID = c("L1", "L2", "L3", "L4"),
    Type = c("Reinforcing", "Balancing", "Reinforcing", "Balancing"),
    Length = c(3L, 3L, 4L, 6L),
    Elements = c("A → B → C", "A → D → C", "A → B → C → D", "A → B → C → D → E → F"),
    stringsAsFactors = FALSE
  )
}

# --- L28 -----------------------------------------------------------------
test_that("the bar-chart axis reaches past the longest bar and ends on a tick", {
  expect_true(exists(".loops_axis_max", mode = "function"))
  for (vals in list(c(100 / 3, 25), c(7, 3, 1), c(50, 20), c(1), c(12.5, 10))) {
    top <- .loops_axis_max(vals)
    expect_gte(top, max(vals))
    expect_true(top %in% pretty(c(0, vals)), info = paste(vals, collapse = ","))
  }
})

test_that("the strength and participation charts set xlim from .loops_axis_max", {
  code <- paste(deparse(.loops_draw_strength), collapse = "\n")
  expect_match(code, ".loops_axis_max", fixed = TRUE)
  code <- paste(deparse(.loops_draw_participation), collapse = "\n")
  expect_match(code, ".loops_axis_max", fixed = TRUE)
})

test_that("the strength chart still renders to PNG", {
  f <- tempfile(fileext = ".png")
  loops_plot_png("strength", loops_df(), make_test_i18n(), f)
  expect_gt(file.size(f), 1000)
})

test_that("the dominance table shows scores rounded to one decimal", {
  expect_true(exists(".loops_dominance_table", mode = "function"))
  tab <- .loops_dominance_table(loops_df())
  expect_equal(names(tab), c("Rank", "LoopID", "Type", "Length", "DominanceScore", "Elements"))
  expect_equal(tab$DominanceScore, c(33.3, 33.3, 25, 16.7))
  expect_equal(tab$Rank, 1:4)
  expect_equal(tab$LoopID[4], "L4")
})

# --- L29 -----------------------------------------------------------------
test_that("the loop report button says Word, not PDF, in every language", {
  tr <- jsonlite::fromJSON(file.path(app_root(), "translations", "modules", "analysis_loops.json"),
                           simplifyVector = FALSE)$translation
  expect_null(tr[["modules.analysis.loops.download_pdf"]])
  entry <- tr[["modules.analysis.loops.download_report_word"]]
  expect_false(is.null(entry))
  for (l in LANGS) {
    expect_match(entry[[l]] %||% "", "(Word)", fixed = TRUE, info = l)
    expect_false(grepl("PDF", entry[[l]] %||% ""), info = l)
  }
})

test_that("the loop report button uses the Word label and still downloads .docx", {
  html <- as.character(analysis_loops_ui("loops", list(t = function(key, ...) key)))
  expect_match(html, "modules.analysis.loops.download_report_word", fixed = TRUE)
  expect_false(grepl("modules.analysis.loops.download_pdf", html, fixed = TRUE))
  code <- paste(readLines(file.path(app_root(), "modules", "analysis_loops.R"), warn = FALSE),
                collapse = "\n")
  expect_match(code, 'generate_export_filename("Loop_Analysis_Report", ".docx")', fixed = TRUE)
})

# --- L27 -----------------------------------------------------------------
test_that("headings inside card headers inherit the header's text colour", {
  css <- paste(readLines(file.path(app_root(), "www", "bs4dash-custom.css"), warn = FALSE),
               collapse = "\n")
  rule <- regmatches(css, regexpr("\\.card-header \\.card-title[^{]*\\{[^}]*\\}", css))
  expect_length(rule, 1)
  expect_match(rule, "color:\\s*inherit")
  # every heading level, so h4 FAQ titles and h3 box titles are both covered
  for (h in paste0("h", 1:6)) expect_match(rule, paste0(".card-header ", h), fixed = TRUE)
  # the warning header keeps its dark text: inherit, not a hard-coded white
  expect_false(grepl("#fff", rule, fixed = TRUE))
})
