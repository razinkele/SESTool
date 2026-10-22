# tests/testthat/test-connection-review-rerender.R
# User feedback 2026-10-21 "Bug when approving connections": approving a
# connection rebuilt the whole tab bar and the card list, so the review jumped
# between sections. Approving now only updates the counts and the card's class.
source_for_test("modules/connection_review_tabbed.R")
connection_review_tabbed_server <- get("connection_review_tabbed_server", envir = .GlobalEnv)

review_conns <- function() {
  c(lapply(1:3, function(i) list(from_type = "driver", to_type = "activity",
                                  from_name = paste("Driver", i), to_name = paste("Activity", i),
                                  polarity = "+", strength = "medium", confidence = 3)),
    lapply(1:2, function(i) list(from_type = "activity", to_type = "pressure",
                                  from_name = paste("Activity", i), to_name = paste("Pressure", i),
                                  polarity = "-", strength = "strong", confidence = 4)))
}
html_of <- function(x) as.character(x$html %||% x)
fake_i18n_rr <- list(t = function(key, ...) switch(key,
  "common.misc.all_d_connections_in_s_approved" = "%d in %s",
  "common.misc.all_d_connections_in_s_rejected" = "%d in %s",
  key))

test_that("approving a connection leaves the tab bar and the card list as they are", {
  conns <- shiny::reactiveVal(review_conns())   # helper-stubs.R stubs reactiveVal
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = fake_i18n_rr), {
    session$flushReact()
    tabs_before <- html_of(output$dynamic_tabs)
    cards_before <- html_of(output$batch_connections_drivers_activities)
    session$setInputs(batch_tabs = "drivers_activities")
    session$setInputs(strength_1 = 3, confidence_1 = 3, polarity_switch_1 = TRUE)
    session$setInputs(approve_1 = 1)
    expect_equal(rv$approved, 1L)
    expect_identical(html_of(output$dynamic_tabs), tabs_before)
    expect_identical(html_of(output$batch_connections_drivers_activities), cards_before)
    # The badge still shows the progress.
    expect_match(html_of(output$tab_badge_drivers_activities), "1/3", fixed = TRUE)
  })
})

test_that("an amendment written back by the parent does not rebuild the review", {
  conns <- shiny::reactiveVal(review_conns())   # helper-stubs.R stubs reactiveVal
  amend <- function(index, polarity, strength, confidence, delay = NA_character_, delay_years = NA_real_) {
    x <- conns(); x[[index]]$strength <- strength; x[[index]]$delay <- delay; conns(x)
  }
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = fake_i18n_rr, on_amend = amend), {
    session$flushReact()
    batches_before <- batched_connections()
    session$setInputs(strength_2 = 5, confidence_2 = 3, polarity_switch_2 = TRUE)
    session$setInputs(approve_2 = 1)
    expect_equal(connections_reactive()[[2]]$strength, "very strong")   # the parent did change its list
    expect_identical(batched_connections(), batches_before)
  })
})

test_that("a structural change (new connections) still rebuilds the review", {
  conns <- shiny::reactiveVal(review_conns())   # helper-stubs.R stubs reactiveVal
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = fake_i18n_rr), {
    session$flushReact()
    expect_equal(batched_connections()$total, 5)
    connections_reactive(review_conns()[1:2])
    session$flushReact()
    expect_equal(batched_connections()$total, 2)
  })
})
