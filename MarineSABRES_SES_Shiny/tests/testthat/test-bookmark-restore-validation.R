# tests/testthat/test-bookmark-restore-validation.R
# Review 2026-10-07 N81 / N82: onRestore copied values deserialised from the
# bookmark URL (`_values_`) into reactives and project metadata with only an
# is.null() check. A non-logical autosave flag crashed the session on the first
# flush; arbitrary metadata strings (any JSON type) were stored and later used
# in reports. sanitize_bookmark_values() admits only well-typed, allow-listed
# scalars.
source_for_test("server/bookmarking.R")

sites <- c("Tuscan Archipelago", "Arctic Northeast Atlantic", "Macaronesia")
sv <- function(values) sanitize_bookmark_values(values, da_sites = sites)

test_that("well-formed values pass through unchanged", {
  out <- sv(list(user_level = "expert", autosave_enabled = FALSE, active_tab = "cld_viz",
                 metadata_da_site = "Macaronesia", metadata_focal_issue = "Overfishing of cod\nin the lagoon"))
  expect_equal(out$user_level, "expert")
  expect_identical(out$autosave_enabled, FALSE)
  expect_equal(out$active_tab, "cld_viz")
  expect_equal(out$metadata_da_site, "Macaronesia")
  expect_equal(out$metadata_focal_issue, "Overfishing of cod\nin the lagoon")
  expect_equal(sv(list(metadata_da_site = ""))$metadata_da_site, "")   # the select's empty choice
})

test_that("N82: non-logical / non-scalar autosave flags are dropped (they used to crash the session)", {
  for (bad in list("yes", "TRUE", 1, c(TRUE, FALSE), logical(0), NA, list(TRUE))) {
    expect_null(sv(list(autosave_enabled = bad))$autosave_enabled, info = deparse(bad))
  }
})

test_that("N82: user level and active tab must be allow-listed scalars", {
  expect_null(sv(list(user_level = "admin"))$user_level)
  expect_null(sv(list(user_level = c("expert", "beginner")))$user_level)
  expect_null(sv(list(user_level = list("expert")))$user_level)
  expect_null(sv(list(active_tab = "cld_viz'); alert(1); ('"))$active_tab)
  expect_null(sv(list(active_tab = strrep("a", 65)))$active_tab)
  expect_null(sv(list(active_tab = 3))$active_tab)
})

test_that("N81: metadata must be a scalar string; da_site must be one of the PIMS choices", {
  expect_null(sv(list(metadata_da_site = "Atlantis"))$metadata_da_site)
  expect_null(sv(list(metadata_da_site = list("Macaronesia")))$metadata_da_site)
  expect_null(sv(list(metadata_focal_issue = list(a = 1)))$metadata_focal_issue)
  expect_null(sv(list(metadata_focal_issue = c("a", "b")))$metadata_focal_issue)
  expect_null(sv(list(metadata_focal_issue = strrep("x", 1001)))$metadata_focal_issue)
  expect_equal(sv(list(metadata_focal_issue = paste0("a", intToUtf8(7), "b\tc")))$metadata_focal_issue, "ab\tc")
})

test_that("non-list input and unknown fields yield nothing", {
  expect_equal(sanitize_bookmark_values(NULL), list())
  expect_equal(sanitize_bookmark_values("x"), list())
  expect_equal(names(sv(list(something_else = 1, user_level = "beginner"))), "user_level")
})

test_that("onRestore routes every restored value through the validator", {
  root <- if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd()
  src <- paste(readLines(file.path(root, "server", "bookmarking.R"), warn = FALSE), collapse = "\n")
  restore <- sub("(?s).*onRestore\\(function\\(state\\) \\{", "", src, perl = TRUE)
  restore <- sub("(?s)showNotification.*", "", restore, perl = TRUE)
  expect_match(restore, "sanitize_bookmark_values\\(state\\$values\\)")
  # after validation, no raw state$values field is read in the restore body
  expect_false(grepl("state\\$values\\$(user_level|autosave_enabled|active_tab|metadata_)", restore))
})
