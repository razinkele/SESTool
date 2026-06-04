# tests/testthat/test-stable-id-store-guardrail.R
# TDD guardrail: .warn_if_global_store_in_session warns when the process-global
# .stable_id_counters default is used while a Shiny reactive domain is active.
#
# Background (L24): the process-global default is only safe for unit tests /
# non-Shiny use. A future caller inside a live Shiny session without an explicit
# store= would silently share counters across concurrent users causing cross-
# session ID collisions. The warning surfaces this misuse early.

source_for_test("functions/data_structure.R")

# ── Assertion 1 ──────────────────────────────────────────────────────────────
# generate_stable_element_id() with global default INSIDE a session → warns
test_that("generate_stable_element_id warns when using global store inside a Shiny session", {
  sess <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(sess, {
    expect_warning(
      generate_stable_element_id("ES"),
      regexp = "session-local"
    )
  })
})

# ── Assertion 2 ──────────────────────────────────────────────────────────────
# generate_stable_element_id() with EXPLICIT session store inside a session → silent
test_that("generate_stable_element_id is silent when given an explicit session store inside a Shiny session", {
  sess <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(sess, {
    my_store <- new_stable_id_store()
    expect_silent(
      generate_stable_element_id("ES", store = my_store)
    )
  })
})

# ── Assertion 3 ──────────────────────────────────────────────────────────────
# Outside any reactive domain: global default is fine (no Shiny session active)
test_that("generate_stable_element_id is silent with global default OUTSIDE any reactive domain", {
  # getDefaultReactiveDomain() returns NULL here → no warning expected
  expect_silent(
    generate_stable_element_id("ES")
  )
})

# ── Assertion 4 ──────────────────────────────────────────────────────────────
# reconcile_loaded_element_ids() with global default INSIDE a session → warns ONCE
test_that("reconcile_loaded_element_ids warns once (not multiple times) when using global store inside a Shiny session", {
  sess <- shiny::MockShinySession$new()
  shiny::withReactiveDomain(sess, {
    df <- data.frame(ID = c("ES001", "ES001"), stringsAsFactors = FALSE)
    # Capture warnings — must have exactly one matching the guardrail message,
    # not multiple (the inner seed_/generate_ calls receive an explicit store so
    # missing() is FALSE there and they do NOT double-warn).
    w <- withCallingHandlers(
      {
        reconcile_loaded_element_ids(df, "ES")
        NULL
      },
      warning = function(cond) {
        invokeRestart("muffleWarning")
      }
    )
    # Use expect_warning which captures the warning count via tryCatch
    expect_warning(
      reconcile_loaded_element_ids(df, "ES"),
      regexp = "session-local"
    )

    # Confirm exactly ONE guardrail warning (not two from inner helpers)
    warnings_caught <- character(0)
    withCallingHandlers(
      reconcile_loaded_element_ids(df, "ES"),
      warning = function(cond) {
        warnings_caught <<- c(warnings_caught, conditionMessage(cond))
        invokeRestart("muffleWarning")
      }
    )
    guardrail_warnings <- warnings_caught[grepl("session-local", warnings_caught)]
    expect_equal(length(guardrail_warnings), 1L,
      info = "reconcile should warn exactly once (inner seed_/generate_ get explicit store)")
  })
})
