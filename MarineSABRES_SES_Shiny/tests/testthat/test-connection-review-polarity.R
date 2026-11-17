# Review cards require a sign (evidenced polarity, Task 4)
source_for_test("modules/connection_review_tabbed.R")
connection_review_tabbed_server <- get("connection_review_tabbed_server", envir = .GlobalEnv)
render_connection_card <- get("render_connection_card", envir = .GlobalEnv)

pol_i18n <- list(t = function(key, ...) switch(key,
  "common.misc.all_d_connections_in_s_approved" = "%d in %s",
  "common.polarity.needs_sign_count" = "%d need a sign",
  key))
pol_conn <- function(polarity = NA_character_, polarity_source = NA_character_, i = 1) {
  list(from_type = "driver", to_type = "activity",
       from_name = paste("Driver", i), to_name = paste("Activity", i),
       polarity = polarity, polarity_source = polarity_source,
       strength = "medium", confidence = 3)
}
pol_signs <- function(pols) lapply(seq_along(pols), function(i) pol_conn(pols[i], i = i))

test_that("approve is blocked while the sign is unset", {
  conns <- shiny::reactiveVal(list(pol_conn(NA_character_)))
  approved <- c()
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n,
                         on_approve = function(i, c) approved <<- c(approved, i)), {
    session$flushReact()
    session$setInputs(approve_1 = 1)
    expect_false(1 %in% rv$approved)
    expect_length(approved, 0)
    session$setInputs(polarity_pick_1_1 = "-", approve_1 = 2)
    expect_true(1 %in% rv$approved)
    expect_equal(rv$amended_data[["1"]]$polarity, "-")
    expect_equal(approved, 1)
  })
})

test_that("approve all skips unsigned and approves nothing when none are signed", {
  conns <- shiny::reactiveVal(pol_signs(c(NA, "+", NA)))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(approve_all_drivers_activities = 1)
    expect_equal(rv$approved, 2L)
  })
  conns2 <- shiny::reactiveVal(pol_signs(c(NA, NA)))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns2, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(approve_all_drivers_activities = 1)
    expect_length(rv$approved, 0)
  })
})

test_that("approve all uses a live pick for a card whose sign was unset", {
  conns <- shiny::reactiveVal(pol_signs(c(NA, "+")))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(polarity_pick_1_1 = "-")
    session$setInputs(approve_all_drivers_activities = 1)
    expect_setequal(rv$approved, c(1L, 2L))
    expect_equal(rv$amended_data[["1"]]$polarity, "-")
  })
})

test_that("swap clears an evidenced sign but keeps a user-chosen one", {
  conns <- shiny::reactiveVal(list(pol_conn("-", "Smith 2020")))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    expect_equal(current_sign(1L), "-")
    session$setInputs(swap_direction_1 = 1)
    expect_true(is.na(current_sign(1L)))
    session$setInputs(polarity_pick_1_1 = "+")
    expect_equal(current_sign(1L), "+")
    rv$last_action_time <- NULL   # the swap handler debounces for 500 ms
    session$setInputs(swap_direction_1 = 2)
    expect_equal(current_sign(1L), "+")
  })
})

test_that("swap keeps a sign that has no citation", {
  # a sign without a source is not evidence, so it is kept by the swap
  conns <- shiny::reactiveVal(list(pol_conn("+", NA_character_)))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(swap_direction_1 = 1)
    expect_equal(current_sign(1L), "+")
  })
})

test_that("a user-chosen sign equal to the evidenced one survives the swap (flip back)", {
  conns <- shiny::reactiveVal(list(pol_conn("-", "S")))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(polarity_pick_1_1 = "+")
    session$setInputs(polarity_pick_1_1 = "-")
    expect_equal(current_sign(1L), "-")
    session$setInputs(swap_direction_1 = 1)
    expect_equal(current_sign(1L), "-")
  })
})

test_that("approving an evidenced card untouched does not make it a user choice; swap un-approves it", {
  conns <- shiny::reactiveVal(list(pol_conn("-", "S")))
  amended <- list()
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n,
                         on_amend = function(index, polarity, ...) amended[[length(amended) + 1L]] <<- polarity), {
    session$flushReact()
    session$setInputs(approve_1 = 1)
    expect_true(1 %in% rv$approved)
    rv$last_action_time <- NULL
    session$setInputs(swap_direction_1 = 1)
    expect_true(is.na(current_sign(1L)))
    expect_false(1 %in% rv$approved)
    expect_null(rv$amended_data[["1"]]$polarity)
    expect_true(is.na(amended[[length(amended)]]))   # the parent was told the sign is gone
    session$setInputs(approve_1 = 2)                  # and it cannot be approved unsigned
    expect_false(1 %in% rv$approved)
  })
})

test_that("a re-render after a swap-clear keeps the sign unset", {
  conns <- shiny::reactiveVal(list(pol_conn("-", "Smith 2020")))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(batch_tabs = "drivers_activities")
    session$setInputs(swap_direction_1 = 1)
    session$setInputs(show_delay_toggle = TRUE)
    session$flushReact()
    html <- paste(as.character(output$batch_connections_drivers_activities$html), collapse = "")
    expect_match(html, "polarity_pick_1_1", fixed = TRUE)   # the card did re-render
    expect_false(grepl("Smith 2020", html, fixed = TRUE))
    expect_true(is.na(current_sign(1L)))
    expect_false(1 %in% rv$user_signed)
  })
})

test_that("approve_blocked and needs_sign_count notifications fire with the right count", {
  seen <- character()
  assign("showNotification", function(ui, ...) { seen <<- c(seen, ui); invisible(NULL) }, envir = .GlobalEnv)
  on.exit(rm("showNotification", envir = .GlobalEnv), add = TRUE)
  conns <- shiny::reactiveVal(pol_signs(c(NA, "+", NA)))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(approve_1 = 1)
    expect_true("common.polarity.approve_blocked" %in% seen)
    session$setInputs(approve_all_drivers_activities = 1)
    expect_true("2 need a sign" %in% seen)
  })
})

test_that("connections_with_sign lists only signed connections", {
  expect_equal(connections_with_sign(pol_signs(c(NA, "+", "-", NA))), c(2L, 3L))
  expect_length(connections_with_sign(pol_signs(c(NA, NA))), 0)
})

test_that("flipping an evidenced sign is what gets approved", {
  conns <- shiny::reactiveVal(list(pol_conn("-", "S")))
  got <- NULL
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n,
                         on_amend = function(index, polarity, strength, confidence, delay = NA, delay_years = NA) got <<- polarity), {
    session$flushReact()
    session$setInputs(polarity_pick_1_1 = "+")
    session$setInputs(approve_1 = 1)
    expect_true(1 %in% rv$approved)
    expect_equal(got, "+")
    expect_equal(rv$amended_data[["1"]]$polarity, "+")
  })
})

test_that("an evidenced sign can be approved untouched", {
  conns <- shiny::reactiveVal(list(pol_conn("-", "S")))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    session$setInputs(approve_1 = 1)
    expect_equal(rv$amended_data[["1"]]$polarity, "-")
  })
})

test_that("the card renders the picker, with the from: line only for an evidenced sign", {
  rv <- shiny::reactiveValues(approved = c(), rejected = c(), amended_data = list(), sign_cleared = c())
  ns <- function(x) paste0("m-", x)
  html_ev <- as.character(shiny::isolate(render_connection_card(pol_conn("-", "Smith 2020"), 1, ns, pol_i18n, rv)))
  expect_match(html_ev, "m-polarity_pick_0_1", fixed = TRUE)
  expect_false(grepl("polarity_switch", html_ev, fixed = TRUE))
  expect_match(html_ev, "Smith 2020", fixed = TRUE)
  html_none <- as.character(shiny::isolate(render_connection_card(pol_conn(NA_character_), 1, ns, pol_i18n, rv)))
  expect_match(html_none, "common.polarity.choose_sign", fixed = TRUE)
  shiny::isolate(rv$amended_data[["1"]] <- list(polarity = "+"))
  html_am <- as.character(shiny::isolate(render_connection_card(pol_conn("-", "Smith 2020"), 1, ns, pol_i18n, rv)))
  expect_false(grepl("Smith 2020", html_am, fixed = TRUE))
  shiny::isolate({ rv$amended_data[["1"]] <- NULL; rv$sign_cleared <- 1L })
  html_cl <- as.character(shiny::isolate(render_connection_card(pol_conn("-", "Smith 2020"), 1, ns, pol_i18n, rv)))
  expect_false(grepl("Smith 2020", html_cl, fixed = TRUE))
  expect_false(grepl("active", html_cl, fixed = TRUE))   # no button selected after a clear
  expect_match(html_cl, "common.polarity.choose_sign", fixed = TRUE)
})

test_that("the picker prompt carries the class the stylesheet hides once a sign is chosen", {
  html <- as.character(polarity_picker_input("p", pol_i18n))
  expect_match(html, 'class="polarity-picker-prompt', fixed = TRUE)
  expect_match(html, 'class="polarity-picker"', fixed = TRUE)
  css <- paste(readLines(file.path(
    if (basename(getwd()) == "testthat") "../../www" else "www", "custom.css")), collapse = "\n")
  expect_match(css, ".polarity-picker:has(.active) .polarity-picker-prompt", fixed = TRUE)
})

# ---- Final review I1: a new connection set starts a fresh review ------------
# The picker id of card `idx` in the review's current generation.
crp_pick <- function(status, idx) {
  gen <- status$generation
  stopifnot(length(gen) == 1)
  paste0("polarity_pick_", gen, "_", idx)
}
crp_set <- function(session, id, value) do.call(session$setInputs, stats::setNames(list(value), id))

test_that("a new connection set does not inherit the previous set's pick or approval", {
  conns <- shiny::reactiveVal(list(pol_conn(NA_character_, i = 1)))
  amended <- list()
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n,
                         on_amend = function(index, polarity, ...) amended[[length(amended) + 1L]] <<- polarity), {
    session$flushReact()
    old_id <- crp_pick(session$getReturned()(), 1)
    crp_set(session, old_id, "-")
    session$setInputs(approve_1 = 1)
    expect_true(1 %in% rv$approved)
    # A different unsigned connection replaces the set
    connections_reactive(list(pol_conn(NA_character_, i = 7)))
    session$flushReact()
    expect_true(is.na(current_sign(1L)))
    expect_length(rv$approved, 0)
    expect_length(rv$amended_data, 0)
    expect_length(rv$user_signed, 0)
    expect_false(identical(crp_pick(session$getReturned()(), 1), old_id))
    n_before <- length(amended)
    session$setInputs(approve_1 = 2)
    expect_false(1 %in% rv$approved)           # approve is blocked: nothing picked
    expect_equal(length(amended), n_before)    # and the parent is not given the old sign
  })
})

test_that("the same set coming back after a reset (cancel, reload) starts fresh too", {
  conns <- shiny::reactiveVal(list(pol_conn(NA_character_, i = 1)))
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = pol_i18n), {
    session$flushReact()
    old_id <- crp_pick(session$getReturned()(), 1)
    crp_set(session, old_id, "+")
    session$setInputs(swap_direction_1 = 1)
    expect_equal(current_sign(1L), "+")
    connections_reactive(NULL)
    session$flushReact()
    connections_reactive(list(pol_conn(NA_character_, i = 1)))
    session$flushReact()
    expect_true(is.na(current_sign(1L)))
    expect_length(rv$swapped, 0)
    expect_false(identical(crp_pick(session$getReturned()(), 1), old_id))
  })
})
