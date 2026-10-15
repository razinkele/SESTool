root <- function() { td <- getwd(); if (basename(td) == "testthat") dirname(dirname(td)) else td }
langs <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")

test_that("designer translations cover every key in 9 languages", {
  tr <- jsonlite::fromJSON(file.path(root(), "translations", "modules", "intervention_designer.json"),
                           simplifyVector = FALSE)$translation
  expect_gt(length(tr), 100L)
  for (k in names(tr)) {
    expect_setequal(names(tr[[k]]), langs)
    expect_true(all(nzchar(unlist(tr[[k]]))), info = k)
  }
})

test_that("every intervention type and group in the ops table has a label", {
  tr <- jsonlite::fromJSON(file.path(root(), "translations", "modules", "intervention_designer.json"),
                           simplifyVector = FALSE)$translation
  ops <- jsonlite::fromJSON(file.path(root(), "data", "wp5_intervention_ops.json"), simplifyVector = FALSE)
  ids <- unique(vapply(ops$interventions, function(r) r$id, character(1)))
  groups <- unique(vapply(ops$interventions, function(r) r$group, character(1)))
  expect_true(all(paste0("modules.intervention_designer.type.", ids) %in% names(tr)))
  expect_true(all(paste0("modules.intervention_designer.group.", groups) %in% names(tr)))
})
