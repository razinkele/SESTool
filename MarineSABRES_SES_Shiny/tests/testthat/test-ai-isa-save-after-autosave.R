# test-ai-isa-save-after-autosave.R
# Regression tests for user feedback 2026-06-03 "where is isa entry data" and
# 2026-06-05 "Inconsistency (85 vs 90 connections)".
#
# Root cause: the AI assistant auto-saves when the user enters connection
# review and sets rv$auto_saved_step_10. The "Save" button then returned early
# whenever that flag was set, and the preview window's "Save" never saved at
# all, so approvals, rejections and edits made after the auto-save never
# reached the project (the dashboard kept the old count, the CLD did not change).

library(testthat)
library(shiny)

local({
  td   <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  old_wd <- setwd(root)
  on.exit(setwd(old_wd), add = TRUE)

  sub_modules <- c(
    "modules/ai_isa/connection_generator.R",
    "modules/ai_isa/ui_components.R",
    "modules/ai_isa/question_flow.R",
    "modules/ai_isa/data_persistence.R",
    "modules/ai_isa/ui_renderers.R",
    "modules/ai_isa/template_handlers.R",
    "modules/ai_isa/action_handlers.R",
    "modules/ai_isa/step_navigation.R"
  )
  for (sm in sub_modules) {
    tryCatch(
      sys.source(file.path(root, sm), envir = .GlobalEnv),
      error = function(e) message("source_for_test: could not source ", sm, ": ", e$message)
    )
  }
  tryCatch(
    sys.source(file.path(root, "modules/ai_isa_assistant_module.R"), envir = .GlobalEnv),
    error = function(e) message("source_for_test: could not source ai_isa_assistant_module.R: ", e$message)
  )
})

ai_isa_assistant_server <- get("ai_isa_assistant_server", envir = .GlobalEnv)

i18n <- list(
  t = function(key, ...) key,
  get_translation_language = function() "en"
)

empty_project <- function() {
  reactiveVal(list(project_id = "p", name = "AI", data = list(isa_data = list(), metadata = list())))
}

# Two drivers, one activity, and two suggested D->A connections, as the
# assistant holds them during connection review.
seed_review_state <- function(rv) {
  rv$elements$drivers    <- list(list(name = "Food demand", description = ""),
                                 list(name = "Tourism demand", description = ""))
  rv$elements$activities <- list(list(name = "Fishing", description = ""))
  rv$suggested_connections <- list(
    list(from_index = 1, to_index = 1, matrix = "d_a", polarity = "+", strength = "medium", confidence = 3),
    list(from_index = 2, to_index = 1, matrix = "d_a", polarity = "+", strength = "weak", confidence = 3)
  )
}

saved_cells <- function(pd) {
  m <- pd()$data$isa_data$adjacency_matrices$d_a
  if (is.null(m)) return(0L)
  sum(!is.na(m) & m != "")
}

test_that("Save stores approvals made after the auto-save", {
  skip_if_not(exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
              "ai_isa_assistant_server not available")
  pd <- empty_project()
  testServer(ai_isa_assistant_server, args = list(project_data_reactive = pd, i18n = i18n), {
    session$flushReact()
    seed_review_state(rv)
    rv$approved_connections <- 1L
    rv$auto_saved_step_10 <- TRUE          # the step-11 auto-save already ran

    rv$approved_connections <- c(1L, 2L)   # user approves a second connection
    session$setInputs(save_to_isa = 1)
    expect_equal(saved_cells(pd), 2L)

    rv$approved_connections <- 1L          # ... then rejects it again
    session$setInputs(save_to_isa = 2)
    expect_equal(saved_cells(pd), 1L)
  })
})

test_that("Save in the preview window saves the model", {
  skip_if_not(exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
              "ai_isa_assistant_server not available")
  pd <- empty_project()
  testServer(ai_isa_assistant_server, args = list(project_data_reactive = pd, i18n = i18n), {
    session$flushReact()
    seed_review_state(rv)
    rv$approved_connections <- c(1L, 2L)
    rv$auto_saved_step_10 <- TRUE
    session$setInputs(save_from_preview = 1)
    expect_equal(nrow(pd()$data$isa_data$drivers), 2L)
    expect_equal(saved_cells(pd), 2L)
  })
})

test_that("a swapped connection does not fill its reverse matrix with \"0\" cells", {
  skip_if_not(exists("build_adjacency_matrices", mode = "function"),
              "build_adjacency_matrices not available")
  elements <- list(drivers = list(list(name = "D1"), list(name = "D2")),
                   activities = list(list(name = "A1"), list(name = "A2")))
  conns <- list(list(from_index = 1, to_index = 2, matrix = "a_d", polarity = "+",
                     strength = "medium", confidence = 3))      # A1 -> D2 after a swap
  m <- build_adjacency_matrices(elements, conns, 1L, 3)$a_d
  expect_equal(sum(!is.na(m) & m != ""), 1L)
})
