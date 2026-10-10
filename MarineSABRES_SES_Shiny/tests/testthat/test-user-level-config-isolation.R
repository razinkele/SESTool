# tests/testthat/test-user-level-config-isolation.R
# Review 2026-10-07 N20: user-level overrides lived in ONE process-global
# environment, and every connecting session wrote it on connect (modals.R
# applies the browser's stored level / overrides), so the last browser to
# connect dictated menus and AI caps for everyone served by the same R process.
source_for_test("config/user_level_config.R")

key <- USER_LEVEL_CONFIG_KEYS[1]
other_value <- function(level) {
  v <- USER_LEVEL_DEFAULTS[[level]][[key]]
  if (is.logical(v)) !v else if (is.numeric(v)) v + 7 else paste0(v, "_x")
}

test_that("N20: one session's level and overrides do not leak into another session", {
  s1 <- shiny::MockShinySession$new()
  s2 <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(s1, set_active_level_config("expert", setNames(list(other_value("expert")), key)))
  shiny::withReactiveDomain(s2, set_active_level_config("beginner"))

  c1 <- shiny::withReactiveDomain(s1, get_level_config())
  c2 <- shiny::withReactiveDomain(s2, get_level_config())
  expect_identical(c1[[key]], other_value("expert"))                      # s1 keeps its override
  expect_identical(c2[[key]], USER_LEVEL_DEFAULTS[["beginner"]][[key]])   # s2 unaffected
  expect_identical(shiny::withReactiveDomain(s1, get_level_setting(key)), other_value("expert"))
})

test_that("N20: a session that never set anything gets defaults even after others did", {
  s1 <- shiny::MockShinySession$new(); s3 <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(s1, set_active_level_config("expert", setNames(list(other_value("expert")), key)))
  c3 <- shiny::withReactiveDomain(s3, get_level_config())
  expect_identical(c3, USER_LEVEL_DEFAULTS[["beginner"]])
})

test_that("N20: reset only touches the calling session", {
  s1 <- shiny::MockShinySession$new(); s2 <- shiny::MockShinySession$new()
  for (s in list(s1, s2)) shiny::withReactiveDomain(s, set_active_level_config("expert", setNames(list(other_value("expert")), key)))
  shiny::withReactiveDomain(s1, reset_level_config())
  expect_identical(shiny::withReactiveDomain(s1, get_level_config("expert"))[[key]], USER_LEVEL_DEFAULTS[["expert"]][[key]])
  expect_identical(shiny::withReactiveDomain(s2, get_level_config("expert"))[[key]], other_value("expert"))
})

test_that("N20: outside a session the process-level default store is used", {
  set_active_level_config("intermediate")
  expect_equal(.level_config_store()$active_level, "intermediate")
  expect_identical(.level_config_store(), .user_level_config_env)
  set_active_level_config("beginner")
})
