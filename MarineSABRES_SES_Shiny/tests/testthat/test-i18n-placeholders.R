# tests/testthat/test-i18n-placeholders.R
# About 410 keys shipped with literal placeholder values such as
# "[DE] Scenario Confirm Delete Message" in six languages (stakeholder module,
# scenario builder, analysis tools, ISA help, ...). The completeness check
# passes them because every language slot is filled. Fail on any such value.
tr_root <- function() {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, "translations"); if (dir.exists(p)) return(p)
  }
  stop("translations/ not found")
}

placeholder_hits <- function() {
  files <- list.files(tr_root(), "[.]json$", full.names = TRUE, recursive = TRUE)
  files <- files[!startsWith(basename(files), "_merged")]
  out <- character(0)
  for (f in files) {
    tr <- tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE)$translation, error = function(e) NULL)
    for (k in names(tr)) {
      vals <- unlist(tr[[k]], use.names = TRUE)
      bad <- names(vals)[grepl("^\\[(ES|FR|DE|LT|PT|IT|NO|EL)\\] ", vals)]
      if (length(bad)) out <- c(out, sprintf("%s: %s [%s]", basename(f), k, paste(bad, collapse = ",")))
    }
  }
  out
}

test_that("no translation value is a '[XX] English' placeholder", {
  hits <- placeholder_hits()
  expect_length(hits, 0)
  if (length(hits)) message(paste(head(hits, 20), collapse = "\n"))
})

test_that("the placeholder pattern is detected (non-vacuous)", {
  expect_true(grepl("^\\[(ES|FR|DE|LT|PT|IT|NO|EL)\\] ", "[DE] Key Interests"))
  expect_false(grepl("^\\[(ES|FR|DE|LT|PT|IT|NO|EL)\\] ", "[Optional] note"))
})
