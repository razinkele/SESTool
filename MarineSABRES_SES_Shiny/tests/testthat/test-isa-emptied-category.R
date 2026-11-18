# A CLD delete that empties an element category must stay deleted. Standard
# Entry used to refresh a category from the project only while it still had
# rows, so it kept its stale copy, and the next unrelated save (here Exercise 0)
# wrote the deleted elements back with matrices that no longer matched them.

source_for_test(c("functions/polarity_evidence.R", "functions/cld_interaction_helpers.R",
                  "modules/sign_choice_module.R", "modules/isa_data_entry_module.R"))

.ec_project <- function() {
  nodes <- data.frame(id = c("D_1", "D_2", "A_1", "P_1"),
                      label = c("Demand", "Jobs", "Trawling", "Damage"),
                      group = c("Drivers", "Drivers", "Activities", "Pressures"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "D_2", "A_1"), to = c("A_1", "A_1", "P_1"),
                      label = c("+", "-", "-"), polarity = c("+", "-", "-"),
                      stringsAsFactors = FALSE)
  sync_cld_to_isa_data(list(project_id = "t", project_name = "T",
    data = list(cld = list(nodes = nodes, edges = edges), isa_data = list())))
}

# the node-delete sync the CLD editor runs
.ec_cld_delete <- function(p, node_ids) {
  p$data$cld$nodes <- p$data$cld$nodes[!p$data$cld$nodes$id %in% node_ids, ]
  e <- p$data$cld$edges
  p$data$cld$edges <- e[!(e$from %in% node_ids | e$to %in% node_ids), ]
  sync_cld_to_isa_data(p)
}

.ec_save_ex0 <- function(session) {
  session$setInputs(case_name = "Test case", case_description = "A description long enough",
                    geographic_scope = "Baltic", temporal_scope = "2020-2025",
                    welfare_impacts = "", key_stakeholders = "")
  session$setInputs(save_ex0 = 1)
  session$flushReact()
}

.ec_run <- function(delete_ids, check) {
  had <- exists("showNotification", envir = .GlobalEnv, inherits = FALSE)
  old <- if (had) get("showNotification", envir = .GlobalEnv)
  assign("showNotification", function(...) invisible(NULL), envir = .GlobalEnv)
  on.exit(if (had) assign("showNotification", old, envir = .GlobalEnv)
          else rm("showNotification", envir = .GlobalEnv), add = TRUE)
  pd <- shiny::reactiveVal(.ec_project())
  shiny::testServer(get("isa_data_entry_server", envir = .GlobalEnv),
    args = list(project_data_reactive = pd, i18n = list(t = function(k, ...) k)), {
      session$flushReact()
      pd(.ec_cld_delete(pd(), delete_ids))
      session$flushReact()
      check(isa_data, pd, session)
    })
}

test_that("elements deleted in the CLD that empty a category stay deleted after a Standard Entry save", {
  .ec_run(c("D_1", "D_2"), function(isa_data, pd, session) {
    expect_equal(NROW(isa_data$drivers), 0L)          # Standard Entry's own copy follows the project
    .ec_save_ex0(session)
    isa <- pd()$data$isa_data
    expect_equal(NROW(isa$drivers), 0L)
    expect_identical(validate_matrix_alignment(isa), character(0))
  })
})

test_that("emptying a category other than drivers behaves the same", {
  .ec_run("P_1", function(isa_data, pd, session) {
    expect_equal(NROW(isa_data$pressures), 0L)
    .ec_save_ex0(session)
    isa <- pd()$data$isa_data
    expect_equal(NROW(isa$pressures), 0L)
    expect_equal(NROW(isa$drivers), 2L)                # untouched categories are kept
    expect_identical(validate_matrix_alignment(isa), character(0))
  })
})

test_that("a partial delete still keeps the remaining elements", {
  .ec_run("D_1", function(isa_data, pd, session) {
    .ec_save_ex0(session)
    isa <- pd()$data$isa_data
    expect_equal(NROW(isa$drivers), 1L)
    expect_identical(validate_matrix_alignment(isa), character(0))
  })
})
