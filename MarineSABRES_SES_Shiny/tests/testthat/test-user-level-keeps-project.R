# test-user-level-keeps-project.R
# Regression test for user feedback 2026-06-05 "The reload": changing the
# expertise level reloads the page and cleared all progress. The language
# change already stashes the project in sessionStorage before its reload
# (saveProjectDataBeforeReload); the level change did not.

library(testthat)
library(shiny)

source_for_test("server/modals.R")

# Runs the level-change handler in a mock session and records every custom
# message it sends, in order.
run_level_change <- function(project) {
  sent <- list()
  testServer(function(input, output, session) {
    session$sendCustomMessage <- function(type, message) {
      sent[[length(sent) + 1L]] <<- type
    }
    setup_user_level_modal_handlers(input, output, session, reactiveVal("beginner"),
                                    make_test_i18n(), project_data = project)
  }, {
    session$setInputs(user_level_selector = "expert", apply_user_level = 1)
    session$elapse(1000)
  })
  unlist(sent)
}

test_that("changing the user level stashes the project before the reload", {
  proj <- create_empty_project("Level test")
  sent <- run_level_change(reactiveVal(proj))
  expect_true("saveProjectDataBeforeReload" %in% sent)
  expect_true("save_user_level" %in% sent)
  expect_lt(match("saveProjectDataBeforeReload", sent), match("save_user_level", sent))
})

test_that("changing the user level still works without project data", {
  sent <- run_level_change(NULL)
  expect_true("save_user_level" %in% sent)
  expect_false("saveProjectDataBeforeReload" %in% sent)
})
