# Leverage analysis (1.36.3): computing leverage points used to overwrite the
# project's stored CLD with a freshly built full network, which discarded a
# saved simplification and every saved node position. The scores are now added
# to the stored CLD nodes; the full network is written only when no CLD exists.

source_for_test(c("modules/analysis_leverage.R"))
if (exists("analysis_leverage_server", envir = .GlobalEnv)) {
  analysis_leverage_server <- get("analysis_leverage_server", envir = .GlobalEnv)
}

.lev_isa <- function() {
  el <- function(ids, names) data.frame(ID = ids, Name = names, stringsAsFactors = FALSE)
  d <- el(c("D001", "D002", "D003"), c("Food demand", "Jobs", "Tourism demand"))
  a <- el(c("A001", "A002"), c("Trawling", "Recreation"))
  p <- el(c("P001", "P002"), c("Bycatch", "Litter"))
  d_a <- matrix("", 3, 2, dimnames = list(d$ID, a$ID))
  d_a["D001", "A001"] <- "+strong:4"; d_a["D002", "A001"] <- "+medium:3"
  d_a["D003", "A002"] <- "+medium:3"
  a_p <- matrix("", 2, 2, dimnames = list(a$ID, p$ID))
  a_p["A001", "P001"] <- "+strong:4"; a_p["A002", "P002"] <- "+weak:2"; a_p["A001", "P002"] <- "-weak:2"
  list(drivers = d, activities = a, pressures = p,
       adjacency_matrices = list(d_a = d_a, a_p = a_p))
}

.lev_run <- function(project, check) {
  had <- exists("showNotification", envir = .GlobalEnv, inherits = FALSE)
  old <- if (had) get("showNotification", envir = .GlobalEnv)
  assign("showNotification", function(...) invisible(NULL), envir = .GlobalEnv)
  on.exit(if (had) assign("showNotification", old, envir = .GlobalEnv)
          else rm("showNotification", envir = .GlobalEnv), add = TRUE)
  pd <- shiny::reactiveVal(project)
  shiny::testServer(analysis_leverage_server,
    args = list(project_data_reactive = pd, i18n = list(t = function(k, ...) k)), {
      session$setInputs(top_n = 5)
      session$setInputs(calculate_leverage = 1)
      check(pd)
    })
}

test_that("leverage scores are added to a saved simplification instead of replacing it", {
  isa <- .lev_isa()
  full <- create_nodes_df(isa)
  kept <- full[full$label != "Tourism demand", ]          # a simplification without one driver
  kept$x <- seq_len(nrow(kept)) * 10; kept$y <- seq_len(nrow(kept)) * -5
  stored_edges <- create_edges_df(isa, isa$adjacency_matrices)
  stored_edges <- stored_edges[stored_edges$from %in% kept$id & stored_edges$to %in% kept$id, ]
  p <- init_session_data()
  p$data$isa_data <- isa
  p$data$cld <- list(nodes = kept, edges = stored_edges, original_nodes = full)

  .lev_run(p, function(pd) {
    cld <- pd()$data$cld
    expect_identical(as.character(cld$nodes$id), as.character(kept$id))   # still the simplified set
    expect_equal(cld$nodes$x, kept$x)                                      # positions kept
    expect_equal(cld$nodes$y, kept$y)
    expect_true("leverage_score" %in% names(cld$nodes))
    expect_true(any(!is.na(cld$nodes$leverage_score)))
    expect_equal(nrow(cld$edges), nrow(stored_edges))                      # stored edges untouched
    expect_equal(nrow(cld$original_nodes), nrow(full))
  })
})

test_that("without a stored CLD the full network is written with its scores, as before", {
  isa <- .lev_isa()
  p <- init_session_data()
  p$data$isa_data <- isa
  .lev_run(p, function(pd) {
    cld <- pd()$data$cld
    expect_equal(nrow(cld$nodes), nrow(create_nodes_df(isa)))
    expect_true(any(!is.na(cld$nodes$leverage_score)))
    expect_gt(nrow(cld$edges), 0)
  })
})
