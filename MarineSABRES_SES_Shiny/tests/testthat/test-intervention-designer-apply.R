# tests/testthat/test-intervention-designer-apply.R
source_for_test(c("functions/network_analysis.R", "functions/scenario_network.R",
                  "functions/ses_dynamics.R", "functions/intervention_designer.R"))
LV <- c(-1, -0.5, -0.25, 0, 0.25, 0.5, 1)

cld <- function() {
  list(nodes = data.frame(id = c("D_1", "A_1", "P_1", "MPF_1"),
                          label = c("Demand", "Boating", "Anchoring", "Seagrass"),
                          group = c("Drivers", "Activities", "Pressures", "Marine Processes & Functioning"),
                          stringsAsFactors = FALSE),
       edges = data.frame(id = 1:3, from = c("D_1", "A_1", "P_1"), to = c("A_1", "P_1", "MPF_1"),
                          polarity = c("+", "+", "-"), strength = c("medium", "medium", "strong"),
                          stringsAsFactors = FALSE))
}
base_matrix <- function(c = cld()) {
  m <- cld_to_numeric_matrix(c$nodes, c$edges, use_labels = TRUE)
  dimnames(m) <- lapply(dimnames(m), unname)
  m
}
design <- function() {
  e <- data.frame(from = c("IV", "IV", "Seagrass", "Boating"),
                  to = c("Anchoring", "Seagrass", "Seagrass", "Anchoring"),
                  kind = c("intervention", "intervention", "context", "reweight"),
                  min_level = c(-1, 0, 0, -1), max_level = c(0, 1, 1, 1), stringsAsFactors = FALSE)
  ses_design_matrix(base_matrix(), list(new_node = "IV", edges = e), LV)
}
meta <- list(name = "IV - configuration #1", description = "d", intervention_type = "mpa_oecm",
             ebm_code = "3.1", now = as.POSIXct("2026-10-15 12:00:00", tz = "UTC"))

test_that("matrix names map to node ids positionally, duplicates made unique", {
  nodes <- data.frame(id = c("x1", "x2", "x3"), label = c("Same", "Same", ""), stringsAsFactors = FALSE)
  expect_equal(ses_matrix_node_ids(nodes), c(Same = "x1", Same_1 = "x2", x3 = "x3"))
})

test_that("configuration -> scenario follows the spec table", {
  # IV->Anchoring strong negative, IV->Seagrass 0 (skipped), self-loop weak, Boating->Anchoring strong (was medium)
  sc <- ses_config_to_scenario(design(), c(-1, 0, 0.25, 1), cld(), meta)
  m <- sc$modifications
  expect_equal(sc$source, "intervention_designer")
  expect_length(m$nodes_added, 1L)
  expect_equal(m$nodes_added[[1]]$label, "IV")
  expect_equal(m$nodes_added[[1]]$dapsi, "Responses")
  expect_length(m$links_added, 2L)                               # level-0 edge not written
  la <- m$links_added[[1]]
  expect_equal(c(la$from, la$to, la$polarity, la$strength), c(m$nodes_added[[1]]$id, "P_1", "-", "strong"))
  expect_equal(m$links_added[[2]][c("from", "to", "strength")], list(from = "MPF_1", to = "MPF_1", strength = "weak"))
  expect_false(identical(m$links_added[[1]]$id, m$links_added[[2]]$id))
  expect_length(m$links_modified, 1L)
  expect_equal(m$links_modified[[1]][c("from", "to", "strength", "previous_strength")],
               list(from = "A_1", to = "P_1", strength = "strong", previous_strength = "medium"))
  expect_equal(vapply(sc$ops, `[[`, "", "op"), c("new_node", "new_edge", "new_edge", "reweight_edge"))
  expect_true(is.na(sc$ops[[1]]$from))
  expect_equal(sc$ops[[4]][c("from", "to", "weight", "intervention_type", "ebm_code")],
               list(from = "Boating", to = "Anchoring", weight = 1, intervention_type = "mpa_oecm", ebm_code = "3.1"))
})

test_that("an unchanged re-weighted link writes nothing", {
  sc <- ses_config_to_scenario(design(), c(-1, 0, 0.25, 0.5), cld(), meta)
  expect_length(sc$modifications$links_modified, 0L)
  expect_false("reweight_edge" %in% vapply(sc$ops, `[[`, "", "op"))
})

test_that("unknown labels stop (Apply writes nothing)", {
  c2 <- cld(); c2$nodes$label[3] <- "Renamed"
  expect_error(ses_config_to_scenario(design(), c(-1, 0, 0.25, 1), c2, meta), "unknown node")
})

test_that("configured network rebuilds exactly the configuration matrix", {
  dm <- design(); lv <- c(-1, 0.5, 0.25, 1)
  net <- ses_config_network(dm, lv, cld(), meta$now)
  m <- cld_to_numeric_matrix(net$nodes, net$edges, use_labels = TRUE)
  dimnames(m) <- lapply(dimnames(m), unname)
  expected <- ses_apply_config(dm, lv)
  expect_equal(m[rownames(expected), colnames(expected)], expected)
})

test_that("scenario names are de-duplicated", {
  expect_equal(.scenario_unique_name("A", character(0)), "A")
  expect_equal(.scenario_unique_name("A", c("A", "A (2)")), "A (3)")
})

test_that("loop diff: rotation-independent keys, gained/lost/changed, truncation (review focus 5)", {
  expect_equal(ses_loop_key(c("C", "A", "B")), ses_loop_key(c("A", "B", "C")))
  b <- list(list(type = "Reinforcing", nodes = c("A", "B", "C")), list(type = "Balancing", nodes = c("B", "D")))
  cf <- list(list(type = "Balancing", nodes = c("C", "A", "B")), list(type = "Reinforcing", nodes = c("E", "F")))
  d <- ses_loop_diff(b, cf)
  expect_equal(d$gained, list(c("E", "F")))
  expect_equal(d$lost, list(c("B", "D")))
  expect_equal(d$changed, list(c("A", "B", "C")))
  expect_false(d$truncated)
  many <- replicate(500, list(type = "Reinforcing", nodes = c("A", "B")), simplify = FALSE)
  expect_true(ses_loop_diff(many, list())$truncated)
})

test_that("compare structure returns loops, leverage and attractors for both sides", {
  dm <- design(); lv <- c(-1, 0.5, 0.25, 1)
  p <- list(baseline = cld(), config = ses_config_network(dm, lv, cld(), meta$now),
            base_matrix = base_matrix(), config_matrix = ses_apply_config(dm, lv),
            objectives = "Seagrass", max_boolean_nodes = 20L)
  out <- ses_compare_structure(p)
  expect_named(out, c("loops", "loop_diff", "leverage", "attractors"))
  expect_true(is.data.frame(out$leverage$baseline))
  expect_true(out$attractors$config$status %in% c("passed", "topology_change_needed", "skipped", "unavailable"))
})
