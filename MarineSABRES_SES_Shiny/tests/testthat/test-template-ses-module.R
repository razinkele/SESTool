# test-template-ses-module.R
# Unit tests for modules/template_ses_module.R

library(testthat)
library(shiny)

# Source the module under test (modules/ are not auto-loaded by global.R).
# Using sys.source(envir = .GlobalEnv) to override any outdated stub in
# helper-stubs.R (see also: test-entry-point-module.R commit 2757e05).
source_for_test("modules/template_ses_module.R")
i18n <- list(t = function(key) key)

# source_for_test() writes the real module to .GlobalEnv, but helper-stubs.R
# defines a stub template_ses_server in testthat's helper env which SHADOWS it
# during lookup. Re-bind the real server here so testServer() drives the real
# module, not the stub (see feedback_testserver_stub_shadowing).
if (exists("template_ses_server", envir = .GlobalEnv)) {
  template_ses_server <- get("template_ses_server", envir = .GlobalEnv)
}

# ============================================================================
# UI FUNCTION TESTS
# ============================================================================

test_that("template_ses_ui function exists", {
  skip_if_not(exists("template_ses_ui", mode = "function"),
              "template_ses_ui not available")
  expect_true(is.function(template_ses_ui))
})

test_that("template_ses_ui returns valid shiny tags", {
  skip_if_not(exists("template_ses_ui", mode = "function"),
              "template_ses_ui not available")
  params <- names(formals(template_ses_ui))
  ui <- if ("i18n" %in% params) template_ses_ui("test_tss", i18n) else template_ses_ui("test_tss")
  expect_true(
    inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"),
    info = "template_ses_ui must return shiny.tag or shiny.tag.list"
  )
})

# ============================================================================
# SERVER FUNCTION TESTS
# ============================================================================

test_that("template_ses_server function exists", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  expect_true(is.function(template_ses_server))
})

test_that("template_ses_server signature includes all required params", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  params <- names(formals(template_ses_server))
  for (p in c("id", "project_data_reactive", "i18n", "event_bus", "parent_session", "user_level_reactive")) {
    expect_true(p %in% params, info = paste0("Missing parameter: ", p))
  }
})

test_that("template_ses_server event_bus defaults to NULL", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  default <- formals(template_ses_server)$event_bus
  expect_true(is.null(default) || identical(as.character(default), "NULL"),
              info = "event_bus must default to NULL for backward compatibility")
})

test_that("template_ses_server optional params default to NULL", {
  skip_if_not(exists("template_ses_server", mode = "function"),
              "template_ses_server not available")
  fmls <- formals(template_ses_server)
    if ("parent_session" %in% names(fmls)) {
      default <- fmls[["parent_session"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("parent_session should default to NULL for optional use"))
    }
    if ("user_level_reactive" %in% names(fmls)) {
      default <- fmls[["user_level_reactive"]]
      expect_true(is.null(default) || identical(as.character(default), "NULL"),
                  info = paste0("user_level_reactive should default to NULL for optional use"))
    }
})

# ============================================================================
# SERVER BEHAVIOR TESTS
# These drive observers and assert observable effects, so they FAIL if the
# server body is replaced with NULL (unlike the signature checks above).
# ============================================================================

# paste(as.character(...), collapse="") flattens a shiny tag / NULL to one
# string so emptiness and content checks are robust to length.
.render_chr <- function(x) paste(as.character(x), collapse = "")

test_that("selecting a template flips template_actions from empty to rendered", {
  testServer(template_ses_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    before <- .render_chr(output$template_actions)
    expect_false(nzchar(before))                 # nothing selected -> renderUI is empty

    session$setInputs(template_selected = "fisheries")

    after <- .render_chr(output$template_actions)
    expect_true(nzchar(after))                   # selection observer set rv$selected_template
    expect_match(after, "well", info = "actions panel (wellPanel) now rendered")
  })
})

test_that("template_cards renders a card per available template", {
  testServer(template_ses_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    cards <- .render_chr(output$template_cards)
    expect_true(nzchar(cards))
    # build_entry style: each template renders a div with class 'template-card'
    n_cards <- length(gregexpr("template-card\"", cards, fixed = TRUE)[[1]])
    expect_gt(n_cards, 0)
  })
})

test_that("approving a connection does not re-render the template's review section", {
  # User feedback 2026-10-21 "Bug when approving connections": on_amend writes
  # each approval back into rv$template_connections; the section must not
  # rebuild the review (tabs and cards) because of it.
  real_ui <- get("connection_review_tabbed_ui", envir = .GlobalEnv)
  builds <- 0L
  assign("connection_review_tabbed_ui", function(...) { builds <<- builds + 1L; real_ui(...) },
         envir = .GlobalEnv)
  on.exit(assign("connection_review_tabbed_ui", real_ui, envir = .GlobalEnv), add = TRUE)

  testServer(template_ses_server,
             args = list(project_data_reactive = reactiveVal(init_session_data()),
                         i18n = i18n), {
    session$setInputs(template_selected = "fisheries")
    session$setInputs(review_connections = 1)
    expect_match(.render_chr(output$connection_review_section), "template_conn_review", fixed = TRUE)
    expect_equal(builds, 1L)
    session$setInputs(`template_conn_review-strength_1` = 5,
                      `template_conn_review-confidence_1` = 3,
                      `template_conn_review-polarity_switch_1` = TRUE)
    session$setInputs(`template_conn_review-approve_1` = 1)
    expect_equal(rv$template_connections[[1]]$strength, "very strong")   # amendment reached the parent
    .render_chr(output$connection_review_section)
    expect_equal(builds, 1L)
  })
})

# ---- Final review I1: template finalize applies no stale amendment ----------
.tpl_pick_id <- function(status, idx) {
  gen <- status$generation
  stopifnot(length(gen) == 1)
  paste0("template_conn_review-polarity_pick_", gen, "_", idx)
}

test_that("a sign picked while reviewing one template is not applied to another", {
  pdr <- reactiveVal(init_session_data())
  testServer(template_ses_server,
             args = list(project_data_reactive = pdr, i18n = i18n), {
    # Template B: note its first connection's sign, then leave
    session$setInputs(template_selected = "tourism")
    session$setInputs(review_connections = 1)
    b1 <- rv$template_connections[[1]]
    expect_true(b1$polarity %in% c("+", "-"))
    flipped <- if (b1$polarity == "+") "-" else "+"
    session$setInputs(cancel_review = 1)
    # Template A: pick the opposite sign on card 1, then leave
    session$setInputs(template_selected = "fisheries")
    session$setInputs(review_connections = 2)
    do.call(session$setInputs, stats::setNames(list(flipped), .tpl_pick_id(review_status(), 1)))
    session$setInputs(cancel_review = 2)
    # Template B again: finalize untouched
    session$setInputs(template_selected = "tourism")
    session$setInputs(review_connections = 3)
    expect_length(review_status()$amended_data, 0)
    session$setInputs(finalize_template = 1)
    mats <- pdr()$data$isa_data$adjacency_matrices
    cell <- NULL
    for (m in mats) {
      if (b1$from_id %in% rownames(m) && b1$to_id %in% colnames(m)) { cell <- m[b1$from_id, b1$to_id]; break }
    }
    expect_false(is.null(cell))
    expect_equal(substr(cell, 1, 1), b1$polarity)   # the template's own sign, not A's pick
  })
})

# Final review M3: template finalize skips (and logs) a connection without a sign
test_that("template finalize writes no cell for a connection without a sign", {
  pdr <- reactiveVal(init_session_data())
  testServer(template_ses_server,
             args = list(project_data_reactive = pdr, i18n = i18n), {
    session$setInputs(template_selected = "fisheries")
    session$setInputs(review_connections = 1)
    n <- length(rv$template_connections)
    c1 <- rv$template_connections[[1]]
    rv$template_connections[[1]]$polarity <- NA_character_
    session$setInputs(finalize_template = 1)
    mats <- pdr()$data$isa_data$adjacency_matrices
    cells <- unlist(lapply(mats, function(m) m[m != ""]))
    expect_false(any(startsWith(cells, "NA")))
    expect_true(all(substr(cells, 1, 1) %in% c("+", "-")))
    for (m in mats) {
      if (c1$from_id %in% rownames(m) && c1$to_id %in% colnames(m)) expect_equal(m[c1$from_id, c1$to_id], "")
    }
    expect_equal(pdr()$data$metadata$connections_count, length(cells))
  })
})

# Re-review (bundled with N1): template finalize applied swaps by original
# index to the list filtered by approvals, so the wrong connection was reversed
test_that("a swap is applied to the swapped connection when only some are approved", {
  pdr <- reactiveVal(init_session_data())
  testServer(template_ses_server,
             args = list(project_data_reactive = pdr, i18n = i18n), {
    session$setInputs(template_selected = "fisheries")
    session$setInputs(review_connections = 1)
    c3 <- rv$template_connections[[3]]
    c4 <- rv$template_connections[[4]]
    session$setInputs(`template_conn_review-swap_direction_3` = 1)
    session$setInputs(`template_conn_review-approve_1` = 1)
    session$setInputs(`template_conn_review-approve_3` = 1)
    session$setInputs(`template_conn_review-approve_4` = 1)
    expect_setequal(review_status()$approved, c(1L, 3L, 4L))
    expect_equal(review_status()$swapped, 3L)
    session$setInputs(finalize_template = 1)
    mats <- pdr()$data$isa_data$adjacency_matrices
    cell_of <- function(from, to) {
      for (m in mats) if (from %in% rownames(m) && to %in% colnames(m)) return(m[from, to])
      NA_character_
    }
    # connection 4 was not swapped: it keeps its own direction
    expect_true(nzchar(cell_of(c4$from_id, c4$to_id)))
    # connection 3 was swapped: it is not written in its original direction
    expect_false(isTRUE(nzchar(cell_of(c3$from_id, c3$to_id))))
  })
})

# A template load must not keep the CLD of whatever was there before: other
# loaders (import, SES Models, AI assistant) replace or clear data$cld, but a
# template load replaced only isa_data, so an edited CLD survived a reload of
# the same template (re-review I-r12 / I-r13, parked for 1.36.0).
.stale_cld_project <- function() {
  p <- init_session_data()
  p$data$cld <- list(
    nodes = data.frame(id = c("A_1", "X_9"), label = c("Edited", "Added in the CLD"),
                       group = c("Activities", "Drivers"), stringsAsFactors = FALSE),
    edges = data.frame(from = "X_9", to = "A_1", polarity = "+", stringsAsFactors = FALSE),
    original_nodes = data.frame(id = "A_1", stringsAsFactors = FALSE))
  p
}

test_that("loading a template directly clears the previous CLD", {
  pdr <- reactiveVal(.stale_cld_project())
  testServer(template_ses_server,
             args = list(project_data_reactive = pdr, i18n = i18n), {
    session$setInputs(template_selected = "fisheries")
    session$setInputs(load_template = 1)
    expect_gt(NROW(pdr()$data$isa_data$drivers), 0)
    cld <- pdr()$data$cld
    expect_equal(NROW(cld$nodes), 0L)
    expect_equal(NROW(cld$edges), 0L)
    expect_null(cld$original_nodes)
  })
})

test_that("finalizing a reviewed template clears the previous CLD", {
  pdr <- reactiveVal(.stale_cld_project())
  testServer(template_ses_server,
             args = list(project_data_reactive = pdr, i18n = i18n), {
    session$setInputs(template_selected = "fisheries")
    session$setInputs(review_connections = 1)
    session$setInputs(finalize_template = 1)
    expect_gt(NROW(pdr()$data$isa_data$drivers), 0)
    cld <- pdr()$data$cld
    expect_equal(NROW(cld$nodes), 0L)
    expect_equal(NROW(cld$edges), 0L)
    expect_null(cld$original_nodes)
  })
})
