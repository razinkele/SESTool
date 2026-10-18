# tests/testthat/test-wp5-workshop-integration.R
# WS-10 follow-up: the REAL Response register module and the REAL workshop page on one shared
# project, wired as app.R does (register api returned by response_measures_server).
library(testthat)
source_for_test(c("functions/wp5_readiness.R", "functions/wp5_workshop.R",
                  "modules/response_module.R", "modules/wp5_workshop_module.R"))
real_resp <- get("response_measures_server", envir = .GlobalEnv)   # helper-stubs.R shadows the modules
real_ws <- get("wp5_workshop_server", envir = .GlobalEnv)
i18n_echo <- make_test_i18n()

test_that("integration: apply and undo go through the real register and survive later register edits", {
  p <- create_empty_project("t"); p$project_id <- "p1"
  pd <- shiny::reactiveVal(p)
  app_server <- function(input, output, session) {
    reg <- real_resp("resp", pd, i18n_echo)
    real_ws("ws", pd, i18n_echo, register = reg)
  }
  testServer(app_server, {
    session$flushReact()
    session$setInputs(`resp-rm_name` = "Quota", `resp-rm_type` = "regulatory", `resp-add_response` = 1)
    expect_equal(pd()$data$response_measures$measures$ID, "RM001")
    session$setInputs(`ws-new` = 1)
    session$setInputs(`ws-workshop` = "W001", `ws-title` = "A", `ws-date` = "2026-10-18", `ws-note` = "",
                      `ws-interventions` = "RM001", `ws-scale` = "pm5", `ws-criteria` = "importance",
                      `ws-tenets_on` = TRUE, `ws-save_setup` = 1)
    session$setInputs(`ws-consent` = TRUE)
    for (i in 1:3) session$setInputs(`ws-a_tenet__RM001__ecol_effective` = "agree", `ws-save_participant` = i)
    expect_equal(nrow(pd()$data$pims$workshops$items[[1]]$respondents), 3L)

    session$setInputs(`ws-apply_measure` = "RM001")
    m <- pd()$data$response_measures$measures
    expect_equal(m$Tenet_ecol_effective, "full")
    expect_equal(m$TenetSource, "modules.wp5_workshop.source_template")      # echo i18n returns the key
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 1)

    # a later edit in the Response module re-syncs ITS state into the project: the applied values
    # must still be there (proves register$update changed the module's state, not just the project)
    session$setInputs(`resp-rm_name` = "Label", `resp-rm_type` = "economic", `resp-add_response` = 2)
    m <- pd()$data$response_measures$measures
    expect_equal(m$ID, c("RM001", "RM002"))
    expect_equal(m$Tenet_ecol_effective[1], "full")
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 1)              # workshop record kept too

    session$setInputs(`ws-undo_measure` = "RM001")
    m <- pd()$data$response_measures$measures
    expect_equal(c(m$Tenet_ecol_effective[1], m$TenetSource[1]), c("", ""))
    expect_length(pd()$data$pims$workshops$items[[1]]$applied, 0)
    session$setInputs(`resp-rm_name` = "Third", `resp-rm_type` = "economic", `resp-add_response` = 3)
    expect_equal(pd()$data$response_measures$measures$Tenet_ecol_effective[1], "")
  })
})
