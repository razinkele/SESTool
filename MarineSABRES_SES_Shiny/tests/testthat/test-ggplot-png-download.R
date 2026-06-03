# tests/testthat/test-ggplot-png-download.R
# Regression for feedback #7 "Can't download tables" — chart downloads arrived as
# HTML. Cause: Shiny's downloadHandler passes content=function(file) an
# EXTENSION-LESS temp path, and ggsave() can't infer the device from it, so it
# errors and Shiny serves an HTML error page. save_ggplot_png() must force
# device = "png" so an extension-less path still produces a real PNG.
source_for_test("functions/export_functions.R")

test_that("save_ggplot_png writes a real PNG to an EXTENSION-LESS path (Shiny download condition)", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
    ggplot2::geom_col()

  f <- tempfile()                 # no extension — exactly what downloadHandler passes
  on.exit(unlink(f), add = TRUE)

  expect_error(save_ggplot_png(p, f, width = 10, height = 6, dpi = 150), NA)  # must NOT error
  expect_true(file.exists(f) && file.size(f) > 0)

  # PNG magic bytes: 89 50 4E 47 ("\x89PNG")
  sig <- readBin(f, what = "raw", n = 4)
  expect_equal(sig, as.raw(c(0x89, 0x50, 0x4E, 0x47)))
})
