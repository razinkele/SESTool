# tests/testthat/test-analysis-bounding.R
# Review 2026-10-07 N16 / N17 (compute bounding on the single shared R process):
#   N16 Boolean attractor search was bounded only by the client-supplied
#       max_boolean_nodes (slider allowed 30, setInputValue anything); the
#       documented hard cap DYNAMICS_MAX_BOOLEAN_NODES was never enforced, and
#       an unused 2^n-vertex state graph was built on top.
#   N17 Limits-to-Growth detection emitted one record per (reinforcing x
#       balancing) loop pair -- tens of thousands on real projects -- each
#       rendered as its own panel.
source_for_test(c("functions/ses_dynamics.R", "functions/decision_lens.R",
                  "modules/analysis_boolean.R"))

hard_cap <- if (exists("DYNAMICS_MAX_BOOLEAN_NODES")) DYNAMICS_MAX_BOOLEAN_NODES else 20L

test_that("the Boolean hard cap is 20 nodes (2^20 states; lowered from 25 on 2026-10-10)", {
  expect_identical(DYNAMICS_MAX_BOOLEAN_NODES, 20L)
})

# ---------------------------------------------------------------------------
# N16
# ---------------------------------------------------------------------------
test_that("N16: clamp_boolean_max_nodes never exceeds the hard cap and survives junk input", {
  expect_equal(clamp_boolean_max_nodes(60), hard_cap)
  expect_equal(clamp_boolean_max_nodes(1e9), hard_cap)
  expect_equal(clamp_boolean_max_nodes(NULL), hard_cap)
  expect_equal(clamp_boolean_max_nodes(NA), hard_cap)
  expect_equal(clamp_boolean_max_nodes("abc"), hard_cap)
  expect_equal(clamp_boolean_max_nodes(c(10, 40)), hard_cap)     # non-scalar -> default
  expect_equal(clamp_boolean_max_nodes(10), 10L)
  expect_equal(clamp_boolean_max_nodes(0), 1L)
})

test_that("N16: ses_boolean_attractors enforces the hard cap even when the caller passes a larger limit", {
  rules <- data.frame(targets = paste0("x", seq_len(hard_cap + 5)),
                      factors = "x1", stringsAsFactors = FALSE)
  expect_error(ses_boolean_attractors(rules, max_nodes = 60),
               paste0("maximum of ", hard_cap))
})

test_that("N16: ses_boolean_attractors no longer builds the unused 2^n state graph", {
  skip_if_not_installed("BoolNet")
  rules <- data.frame(targets = c("A", "B", "C"),
                      factors = c("B", "!A", "A & B"), stringsAsFactors = FALSE)
  res <- ses_boolean_attractors(rules)
  expect_null(res$transition_graph)
  expect_gt(length(res$attractors), 0)
})

test_that("N16: the node-limit slider (rendered server-side) cannot be set above the hard cap", {
  # helper-stubs.R shadows module servers; drive the real one
  server <- get("analysis_boolean_server", envir = .GlobalEnv)
  i18n <- list(t = function(k, ...) k)
  nodes <- data.frame(id = c("D_1", "A_1", "P_1"), label = c("d", "a", "p"),
                      group = c("Drivers", "Activities", "Pressures"), stringsAsFactors = FALSE)
  edges <- data.frame(from = c("D_1", "A_1"), to = c("A_1", "P_1"), polarity = "+",
                      label = "+", stringsAsFactors = FALSE)
  pdr <- shiny::reactiveVal(list(project_id = "p", data = list(cld = list(nodes = nodes, edges = edges))))
  testServer(server, args = list(project_data_reactive = pdr, i18n = i18n), {
    html <- output$main_ui$html
    skip_if(is.null(html), "main_ui not rendered for this fixture (CLD gate)")
    slider <- regmatches(html, regexpr('<input[^>]*id="[^"]*max_boolean_nodes"[^>]*>', html))
    expect_length(slider, 1)
    expect_match(slider, paste0('data-max="', hard_cap, '"'), fixed = TRUE)
  })
})

# ---------------------------------------------------------------------------
# N17
# ---------------------------------------------------------------------------
many_pairs <- function(n_rein = 20, n_bal = 20) {
  # every reinforcing engine contains D/A and the shared P_1; every balancing
  # loop contains P_1 and one of two Responses -> n_rein * n_bal coupled pairs
  rein <- vapply(seq_len(n_rein), function(i) paste0("D_1,A_", i, ",P_1,MPF_1,ES_1,GB_1"), "")
  bal  <- vapply(seq_len(n_bal),  function(i) paste0("GB_1,R_", 1 + (i %% 2), ",P_1,MPF_", i + 1), "")
  data.frame(LoopID = seq_len(n_rein + n_bal),
             Type = c(rep("Reinforcing", n_rein), rep("Balancing", n_bal)),
             NodeIDs = c(rein, bal), stringsAsFactors = FALSE)
}

test_that("N17: Limits-to-Growth yields one record per leverage Response, not per loop pair", {
  res <- detect_archetypes(many_pairs())
  ltg <- Filter(function(a) a$archetype_key == "limits_to_growth", res)
  expect_length(ltg, 2)                                         # was 400
  expect_setequal(vapply(ltg, function(a) a$leverage_node_id, ""), c("R_1", "R_2"))
  r1 <- ltg[[which(vapply(ltg, function(a) a$leverage_node_id, "") == "R_1")]]
  expect_true(all(1:20 %in% r1$loop_ids))                         # every engine is listed
  expect_false(any(r1$loop_ids %in% c(21, 23)))                  # balancing loops of R_2 (odd i) are not
  expect_true("P_1" %in% r1$shared_node_ids)
})

test_that("N17: the original single-pair case is unchanged", {
  loop_info <- data.frame(
    LoopID = c(1L, 2L), Type = c("Reinforcing", "Balancing"),
    NodeIDs = c("D_1,A_1,P_1,MPF_1,ES_1,GB_1", "GB_1,R_1,P_1,MPF_1,ES_1"),
    stringsAsFactors = FALSE)
  ltg <- Filter(function(a) a$archetype_key == "limits_to_growth", detect_archetypes(loop_info))
  expect_length(ltg, 1)
  expect_equal(ltg[[1]]$leverage_node_id, "R_1")
  expect_setequal(ltg[[1]]$loop_ids, c(1L, 2L))
})

test_that("N17: format_loop_ids truncates long loop lists for display", {
  expect_equal(format_loop_ids(c(3, 1, 2)), "1, 2, 3")
  long <- format_loop_ids(1:300)
  expect_true(nchar(long) < 120)
  expect_match(long, "+280", fixed = TRUE)
})
