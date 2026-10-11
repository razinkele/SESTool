# tests/testthat/test-dashboard-ecosystem-labels.R
# The dashboard's ecosystem-type dropdown showed English labels in every
# language (same gap as the regional-sea labels, review N64). Labels are now
# translation keys parallel to ECOSYSTEM_TYPE_CHOICES_DETAILED; the stored value
# stays the lowercase English name so saved projects and KB matching still work.
rc_file <- function(rel) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, rel); if (file.exists(p)) return(p)
  }
  stop("not found: ", rel)
}

test_that("one ecosystem label key per choice, in the same order", {
  s <- readLines(rc_file("server/dashboard.R"), warn = FALSE)
  keys <- regmatches(s, regexpr("modules[.]report_context[.]eco_[a-z_]+", s))
  expect_equal(length(keys), length(ECOSYSTEM_TYPE_CHOICES_DETAILED))
  expect_identical(sub("modules.report_context.eco_", "", keys, fixed = TRUE),
                   gsub(" ", "_", tolower(ECOSYSTEM_TYPE_CHOICES_DETAILED), fixed = TRUE))
  expect_true(any(grepl("vapply(ECOSYSTEM_TYPE_LABEL_KEYS", s, fixed = TRUE)))
  # stored values unchanged
  expect_true(any(grepl("setNames(tolower(ECOSYSTEM_TYPE_CHOICES_DETAILED),", s, fixed = TRUE)))
})

test_that("every ecosystem label key is translated in all 9 languages", {
  tr <- jsonlite::fromJSON(rc_file("translations/modules/report_context.json"),
                           simplifyVector = FALSE)$translation
  keys <- paste0("modules.report_context.eco_",
                 gsub(" ", "_", tolower(ECOSYSTEM_TYPE_CHOICES_DETAILED), fixed = TRUE))
  for (k in keys) {
    for (lang in c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")) {
      expect_true(nzchar(tr[[k]][[lang]] %||% ""), info = paste(k, lang))
    }
  }
  expect_identical(tr[["modules.report_context.eco_kelp_forest"]][["no"]], "Tareskog")
  expect_identical(tr[["modules.report_context.eco_coastal"]][["en"]], "Coastal")
})
