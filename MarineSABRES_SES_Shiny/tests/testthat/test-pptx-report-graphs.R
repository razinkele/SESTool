# tests/testthat/test-pptx-report-graphs.R
# Live feedback 2026-11-12, L30 "Graphs in the powerpoint report": the
# PowerPoint report should carry the graphs of the analyses and the main
# network. It was text only, ignored the "cld" section, and its loop slide
# counted the elements of list(loop_info, all_loops), so it always said
# "Total Loops: 2" with 0 reinforcing and 0 balancing.

skip_if_not_installed("officer")
source_for_test(c("functions/network_analysis.R", "modules/analysis_loops.R",
                  "modules/prepare_report_module.R"))

cld_nodes <- function() {
  data.frame(
    id = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
    label = c("Food\ndemand", "Fishing", "Bycatch", "Fish stock", "Food provision", "Income"),
    name_raw = c("Food demand", "Fishing", "Bycatch", "Fish stock", "Food provision", "Income"),
    group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning",
              "Ecosystem Services", "Goods & Benefits"),
    level = c(5, 4, 3, 2, 1, 0),
    color = c(NA, "#5abc67", "#fec05a", "#bce2ee", "#313695", "#fff1a2"),
    leverage_score = c(0.9, 0.7, 0, 0.4, NA, 0.2),
    stringsAsFactors = FALSE
  )
}
cld_edges <- function() {
  data.frame(from = c("D_1", "A_1", "P_1", "MPF_1", "ES_1", "GB_1"),
             to   = c("A_1", "P_1", "MPF_1", "ES_1", "GB_1", "D_1"),
             polarity = c("+", "+", "-", "+", "+", "+"),
             stringsAsFactors = FALSE)
}
loop_info <- function() {
  data.frame(LoopID = c("L1", "L2", "L3"),
             Type = c("Reinforcing", "Balancing", "Reinforcing"),
             Length = c(3L, 4L, 6L),
             Elements = c("A → B → C", "A → B → C → D", "A → B → C → D → E → F"),
             stringsAsFactors = FALSE)
}
report_data <- function() {
  list(data = list(
    metadata = list(project_name = "Test"),
    isa_data = list(),
    cld = list(nodes = cld_nodes(), edges = cld_edges()),
    analysis = list(loops = list(loop_info = loop_info(), all_loops = list(1, 2, 3)))
  ))
}
pptx_images <- function(file) {
  s <- officer::pptx_summary(officer::read_pptx(file))
  s[s$content_type == "image", , drop = FALSE]
}
pptx_text <- function(file) {
  s <- officer::pptx_summary(officer::read_pptx(file))
  paste(s$text[!is.na(s$text)], collapse = "\n")
}

test_that("the network diagram renders to PNG, Drivers without a colour included", {
  f <- tempfile(fileext = ".png")
  expect_true(report_network_png(cld_nodes(), cld_edges(), f))
  expect_gt(file.size(f), 5000)
})

test_that("the network helper declines an empty network instead of failing", {
  f <- tempfile(fileext = ".png")
  expect_false(report_network_png(cld_nodes()[0, ], cld_edges()[0, ], f))
  expect_false(report_network_png(NULL, NULL, f))
})

test_that("the leverage chart renders the scored nodes and declines when none are scored", {
  f <- tempfile(fileext = ".png")
  expect_true(report_leverage_png(cld_nodes(), f))
  expect_gt(file.size(f), 1000)
  n <- cld_nodes(); n$leverage_score <- 0
  expect_false(report_leverage_png(n, tempfile(fileext = ".png")))
  expect_false(report_leverage_png(cld_nodes()[, names(cld_nodes()) != "leverage_score"],
                                   tempfile(fileext = ".png")))
})

test_that("the PowerPoint report carries the network, loop and leverage graphs", {
  out <- tempfile(fileext = ".pptx")
  generate_ppt_report(report_data(), "T", "A", c("cld", "loops", "leverage"), out)
  imgs <- pptx_images(out)
  # network + loop strength + loop types + leverage
  expect_gte(nrow(imgs), 4)
  txt <- pptx_text(out)
  expect_match(txt, "Network Diagram", fixed = TRUE)
  expect_match(txt, "Loop Strength", fixed = TRUE)
})

test_that("the loop slide counts the detected loops, not the stored list's two parts", {
  out <- tempfile(fileext = ".pptx")
  generate_ppt_report(report_data(), "T", "A", c("loops"), out)
  txt <- pptx_text(out)
  expect_match(txt, "Total Loops: 3", fixed = TRUE)
  expect_match(txt, "Reinforcing: 2", fixed = TRUE)
  expect_match(txt, "Balancing: 1", fixed = TRUE)
})

test_that("unselected sections add no graphs and missing data does not fail", {
  out <- tempfile(fileext = ".pptx")
  generate_ppt_report(report_data(), "T", "A", c("summary"), out)
  expect_equal(nrow(pptx_images(out)), 0)

  empty <- list(data = list(metadata = list(), isa_data = list(),
                            analysis = list(loops = list(loop_info = data.frame(),
                                                         all_loops = list(),
                                                         detection_complete = TRUE))))
  out2 <- tempfile(fileext = ".pptx")
  expect_no_error(generate_ppt_report(empty, "T", "", c("cld", "loops", "leverage"), out2))
  expect_equal(nrow(pptx_images(out2)), 0)
})
