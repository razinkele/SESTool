# test-ai-isa-recovery-loop.R
# Regression test for the 2026-10-13 production hang (laguna, v1.24.0).
#
# Root cause (found with a gdb stack dump of the wedged R worker): the
# "recovered data" observer in ai_isa_assistant_server() reads
# rv$elements$drivers / rv$elements$activities OUTSIDE isolate() as its guard,
# then (inside isolate) rewrites rv$elements with fresh Sys.time() timestamps.
# When the project holds elements in other categories but no drivers and no
# activities, the guard stays TRUE, every run stores a non-identical value,
# the observer re-invalidates itself and Shiny's flush loop never empties.
# One R process serves every user on open-source Shiny Server, so a single
# session in that state took the whole site down (HTTP 502 for ~15 minutes
# until restart.txt; the old worker spun at 100% CPU for hours).
#
# Test approach: drive the REAL server via testServer() with a project that
# has pressures only, and count the observer's entries through debug_log()
# (called at the top of the observer, outside its tryCatch). More than a
# handful of entries during one flush is the loop.

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

# Project with ISA elements in a non-D/A category only (what a user ends up
# with after deleting or never entering Drivers and Activities).
make_pressures_only_project <- function() {
  reactiveVal(list(
    project_id = "test_proj",
    name = "Pressures only",
    data = list(
      isa_data = list(
        drivers = data.frame(),
        activities = data.frame(),
        pressures = data.frame(
          id = c("P001", "P002"),
          name = c("Nutrient loading", "Bottom trawling disturbance"),
          description = c("", ""),
          stringsAsFactors = FALSE
        ),
        adjacency_matrices = list()
      ),
      metadata = list()
    )
  ))
}

# Counts entries into the recovery observer via its first debug_log() call
# and aborts the flush once the loop is evident, so the test cannot hang.
with_observer_counter <- function(limit, expr) {
  counter <- new.env()
  counter$n <- 0L
  had_old <- exists("debug_log", envir = .GlobalEnv, inherits = FALSE)
  old <- if (had_old) get("debug_log", envir = .GlobalEnv) else NULL
  assign("debug_log", function(msg, ...) {
    if (is.character(msg) && length(msg) == 1L && grepl("[AI ISA] Observer triggered", msg, fixed = TRUE)) {
      counter$n <- counter$n + 1L
      if (counter$n >= limit) stop("reactive loop detected: recovery observer re-ran ", counter$n, " times")
    }
    invisible(NULL)
  }, envir = .GlobalEnv)
  on.exit({
    if (had_old) assign("debug_log", old, envir = .GlobalEnv) else rm("debug_log", envir = .GlobalEnv)
  }, add = TRUE)
  result <- tryCatch(expr, error = function(e) e)
  list(result = result, n = counter$n)
}

test_that("recovery observer does not loop when the project has no drivers and no activities", {
  skip_if_not(
    exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
    "ai_isa_assistant_server not available"
  )

  pd <- make_pressures_only_project()
  runs <- NULL

  testServer(
    ai_isa_assistant_server,
    args = list(project_data_reactive = pd, i18n = i18n),
    {
      runs <<- with_observer_counter(50L, session$flushReact())
    }
  )

  expect_false(inherits(runs$result, "error"),
               label = paste("flush completed without the loop guard firing:",
                             if (inherits(runs$result, "error")) conditionMessage(runs$result) else "ok"))
  expect_lte(runs$n, 3L)
})

test_that("recovery observer still restores elements once for a normal project", {
  skip_if_not(
    exists("ai_isa_assistant_server", envir = .GlobalEnv, mode = "function"),
    "ai_isa_assistant_server not available"
  )

  pd <- reactiveVal(list(
    project_id = "test_proj",
    name = "Normal",
    data = list(
      isa_data = list(
        drivers = data.frame(id = "D001", name = "Food demand", description = "", stringsAsFactors = FALSE),
        activities = data.frame(id = "A001", name = "Fishing", description = "", stringsAsFactors = FALSE),
        pressures = data.frame(id = "P001", name = "Extraction", description = "", stringsAsFactors = FALSE),
        adjacency_matrices = list()
      ),
      metadata = list()
    )
  ))

  n_drivers <- NULL
  runs <- NULL
  testServer(
    ai_isa_assistant_server,
    args = list(project_data_reactive = pd, i18n = i18n),
    {
      runs <<- with_observer_counter(50L, session$flushReact())
      n_drivers <<- length(rv$elements$drivers)
    }
  )

  expect_false(inherits(runs$result, "error"))
  expect_equal(n_drivers, 1L)
  expect_lte(runs$n, 3L)
})
