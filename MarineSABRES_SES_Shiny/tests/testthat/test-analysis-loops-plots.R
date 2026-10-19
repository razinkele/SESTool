# test-analysis-loops-plots.R
# User feedback 2026-10-13 (suggestion, final meeting CM UNIPI): "the plot of
# loop strength analysis remains blank; sometimes the margins of plots are too
# small or cut the figure; possibility to download plots".
# loop_strength_plot, reinforcing_dist and balancing_dist had a plotOutput but
# never a renderer.

library(testthat)
library(shiny)

source_for_test(c("functions/network_analysis.R", "modules/analysis_loops.R"))
real_analysis_loops_server <- get("analysis_loops_server", envir = .GlobalEnv)

loops_df <- function() {
  data.frame(
    LoopID = c("L1", "L2", "L3"),
    Type = c("Reinforcing", "Balancing", "Reinforcing"),
    Length = c(3L, 4L, 5L),
    Elements = c("Fishing → Fish stock → Catch",
                 "Tourism demand → Visitors → Beach litter → Attractiveness",
                 "A very long element name for margins → B → C → D → E"),
    stringsAsFactors = FALSE
  )
}

with_loops <- function(code) {
  testServer(real_analysis_loops_server,
             args = list(project_data_reactive = reactiveVal(list(data = list())),
                         i18n = make_test_i18n()), {
    loop_data$loops <- loops_df()
    session$flushReact()
    eval(code)   # `code` is a quote() written in this file, run inside the server scope
  })
}

test_that("the strength and distribution plots render", {
  with_loops(quote({
    for (id in c("loop_strength_plot", "reinforcing_dist", "balancing_dist",
                 "element_participation_plot", "loop_type_plot")) {
      out <- output[[id]]
      expect_true(is.list(out) && nzchar(out$src %||% ""), info = paste(id, "did not render"))
    }
  }))
})

test_that("each loop plot can be downloaded as PNG", {
  skip_if_not(exists("loops_plot_png", mode = "function"), "loops_plot_png not available")
  df <- loops_df()
  for (which in c("strength", "participation", "type")) {
    f <- tempfile(fileext = ".png")
    loops_plot_png(which, df, make_test_i18n(), f)
    expect_gt(file.size(f), 1000, label = paste(which, "PNG size"))
  }
})
