# test-analysis-plot-downloads.R
# Follow-up to PR #128 (user feedback 2026-10-13: "possibility of download
# plots"): the decision lens factor plot and the simplification impact chart
# get a PNG download built from the same plot object as the page, and the
# network views get visNetwork's PNG export button.

library(testthat)
library(shiny)

source_for_test(c("modules/analysis_decision_lens.R", "modules/analysis_simplify.R"))
real_dl_server <- get("analysis_decision_lens_server", envir = .GlobalEnv)
real_simplify_server <- get("analysis_simplify_server", envir = .GlobalEnv)

png_bytes <- function(plot) {
  f <- tempfile(fileext = ".png")
  ggplot2::ggsave(f, plot, width = 9, height = 6, dpi = 72, bg = "white")
  file.size(f)
}

test_that("decision lens: the factor plot can be saved as PNG", {
  nodes <- data.frame(id = c("D_1", "A_1", "P_1", "MPF_1"),
                      label = c("Driver", "Activity", "Pressure", "State"),
                      group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "A_1", "P_1", "MPF_1"), to = c("A_1", "P_1", "MPF_1", "D_1"),
                      polarity = c("+", "+", "-", "+"), stringsAsFactors = FALSE)
  testServer(real_dl_server, args = list(project_data_reactive = reactiveVal(list(data = list())),
                                         i18n = make_test_i18n()), {
    rv$factors <- classify_factors_micmac(nodes, edges)
    p <- factors_plot_obj()
    expect_s3_class(p, "ggplot")
    expect_gt(png_bytes(p), 1000)
  })
})

test_that("simplify: the impact chart can be saved as PNG, and networks offer PNG export", {
  n <- data.frame(id = c("D_1", "A_1", "P_1"), label = c("D", "A", "P"),
                  group = c("Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE)
  e <- data.frame(from = c("D_1", "A_1"), to = c("A_1", "P_1"), stringsAsFactors = FALSE)
  testServer(real_simplify_server, args = list(project_data_reactive = reactiveVal(list(data = list())),
                                               i18n = make_test_i18n()), {
    rv$original_nodes <- n; rv$original_edges <- e
    rv$simplified_nodes <- n[1:2, ]; rv$simplified_edges <- e[1, , drop = FALSE]
    rv$has_simplified <- TRUE
    p <- impact_plot_obj()
    expect_s3_class(p, "ggplot")
    expect_gt(png_bytes(p), 1000)
    expect_match(output$original_network, '"export"', fixed = TRUE)
  })
})
