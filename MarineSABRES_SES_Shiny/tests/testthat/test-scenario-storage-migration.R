# tests/testthat/test-scenario-storage-migration.R
# WS-0: scenarios live at project$data$analysis$scenarios (functions/data_structure.R
# create_empty_project). The scenario builder historically wrote project$data$scenarios.
library(testthat)

sc <- function(id, name = id) list(id = id, name = name, modifications = list())

test_that("legacy-only scenarios move to analysis$scenarios", {
  p <- list(data = list(scenarios = list(sc("s1"), sc("s2")), analysis = list()))
  out <- migrate_legacy_scenarios(p)
  expect_null(out$data$scenarios)
  expect_equal(vapply(out$data$analysis$scenarios, `[[`, "", "id"), c("s1", "s2"))
})

test_that("both locations merge by id; canonical wins; no duplicates", {
  p <- list(data = list(
    scenarios = list(sc("s1", "legacy name"), sc("s3")),
    analysis  = list(scenarios = list(sc("s1", "canonical name"), sc("s2")))))
  out <- migrate_legacy_scenarios(p)
  ids <- vapply(out$data$analysis$scenarios, `[[`, "", "id")
  expect_equal(ids, c("s1", "s2", "s3"))
  expect_equal(out$data$analysis$scenarios[[1]]$name, "canonical name")
})

test_that("malformed legacy values do not crash and are dropped", {
  p1 <- list(data = list(scenarios = "garbage", analysis = list(scenarios = list(sc("a")))))
  out1 <- migrate_legacy_scenarios(p1)
  expect_null(out1$data$scenarios)
  expect_equal(length(out1$data$analysis$scenarios), 1L)

  p2 <- list(data = list(scenarios = list(sc("b"), "not-a-scenario", 42)))
  out2 <- migrate_legacy_scenarios(p2)
  expect_equal(vapply(out2$data$analysis$scenarios, `[[`, "", "id"), "b")

  p3 <- list(data = list(scenarios = data.frame(id = "x", name = "y")))
  expect_no_error(out3 <- migrate_legacy_scenarios(p3))
  expect_null(out3$data$scenarios)
})

test_that("no legacy key, NULL data, non-list project: unchanged, no error", {
  p <- list(data = list(analysis = list(scenarios = list(sc("s1")))))
  expect_identical(migrate_legacy_scenarios(p), p)
  expect_identical(migrate_legacy_scenarios(list(data = NULL)), list(data = NULL))
  expect_identical(migrate_legacy_scenarios("x"), "x")
})

test_that("migration is idempotent", {
  p <- list(data = list(scenarios = list(sc("s1")), analysis = list()))
  once <- migrate_legacy_scenarios(p)
  expect_identical(migrate_legacy_scenarios(once), once)
})

test_that("normalize_and_reconcile_project applies the migration", {
  p <- create_empty_project("t")
  p$data$scenarios <- list(sc("legacy1"))
  out <- normalize_and_reconcile_project(p)
  expect_null(out$data$scenarios)
  expect_equal(vapply(out$data$analysis$scenarios, `[[`, "", "id"), "legacy1")
})

test_that("stamp_min_app_version only ever raises the version", {
  p <- list(min_app_version = "1.12.0")
  expect_equal(stamp_min_app_version(p, "1.22.0")$min_app_version, "1.22.0")
  expect_equal(stamp_min_app_version(list(min_app_version = "1.24.0"), "1.22.0")$min_app_version, "1.24.0")
  expect_equal(stamp_min_app_version(list(), "1.22.0")$min_app_version, "1.22.0")
  expect_equal(stamp_min_app_version(list(min_app_version = "garbage"), "1.22.0")$min_app_version, "1.22.0")
  expect_equal(stamp_min_app_version(list(min_app_version = "1.22.0"), "1.22.0")$min_app_version, "1.22.0")
})

test_that("stamp_min_app_version rejects an invalid target version", {
  expect_error(stamp_min_app_version(list(), "not-a-version"), "invalid version")
  expect_identical(stamp_min_app_version("x", "1.22.0"), "x")
})
