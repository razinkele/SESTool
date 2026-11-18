# Saved node positions (1.36.3). The drag handler used to store only the
# dragged node's position, and the render turned the layout off as soon as any
# node had one, so after a reload every other node landed at a random place.

source_for_test(c("functions/cld_interaction_helpers.R"))

.pos_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") dirname(dirname(wd)) else wd
}

test_that("positions count as saved only when every node has both coordinates", {
  n <- data.frame(id = c("a", "b", "c"), stringsAsFactors = FALSE)
  expect_false(cld_has_complete_positions(n))                       # no columns
  n$x <- c(1, NA, 3); n$y <- c(1, 2, 3)
  expect_false(cld_has_complete_positions(n))                       # one node only partly placed
  n$x <- c(1, 2, 3); n$y <- c(1, NA, 3)
  expect_false(cld_has_complete_positions(n))
  n$y <- c(1, 2, 3)
  expect_true(cld_has_complete_positions(n))
  expect_false(cld_has_complete_positions(n[0, ]))                  # an empty table
  expect_false(cld_has_complete_positions(NULL))
})

test_that("the render keeps saved positions only when they are complete", {
  src <- paste(readLines(file.path(.pos_root(), "modules", "cld_visualization_module.R"),
                         warn = FALSE), collapse = "\n")
  expect_true(grepl("has_saved_positions <- cld_has_complete_positions(nodes)", src, fixed = TRUE))
})

test_that("a drag stores the position of every node, not only the dragged one", {
  src <- paste(readLines(file.path(.pos_root(), "modules", "cld_visualization_module.R"),
                         warn = FALSE), collapse = "\n")
  expect_false(grepl("this.getPositions(params.nodes)", src, fixed = TRUE))
  expect_true(grepl("this.getPositions()", src, fixed = TRUE))
})
