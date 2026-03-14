# tests/testthat/test-ses-dynamics.R
# Comprehensive unit tests for the SES Dynamics Engine (functions/ses_dynamics.R)

# Helper: ensure ses_dynamics functions are available
if (!exists("ses_make_matrix")) {
  tryCatch({
    source(file.path("..", "..", "functions", "ses_dynamics.R"), local = FALSE)
  }, error = function(e) {
    # If constants are missing, define minimal fallback
    if (!exists("DYNAMICS_WEIGHT_MAP")) {
      DYNAMICS_WEIGHT_MAP <<- list(
        "+strong" = 1.0, "+medium" = 0.5, "+weak" = 0.25,
        "-strong" = -1.0, "-medium" = -0.5, "-weak" = -0.25
      )
    }
    if (!exists("DYNAMICS_DEFAULT_ITER")) {
      DYNAMICS_DEFAULT_ITER <<- 500L
      DYNAMICS_MIN_ITER <<- 50L
      DYNAMICS_MAX_ITER <<- 5000L
      DYNAMICS_DEFAULT_GREED <<- 100L
      DYNAMICS_MAX_GREED <<- 2000L
      DYNAMICS_MAX_BOOLEAN_NODES <<- 25L
      DYNAMICS_DEFAULT_RF_TREES <<- 1000L
      DYNAMICS_DIVERGENCE_THRESHOLD <<- 1e10
    }
    tryCatch({
      source(file.path("..", "..", "functions", "ses_dynamics.R"), local = FALSE)
    }, error = function(e2) {
      skip(paste("Cannot load ses_dynamics.R:", e2$message))
    })
  })
}

# ============================================================================
# Helper fixtures
# ============================================================================

#' Create a simple 3-node test matrix (A -> B -> C -> A cycle)
make_cycle_3 <- function() {
  mat <- matrix(0, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  mat["A", "B"] <- 1
  mat["B", "C"] <- 1
  mat["C", "A"] <- 1
  mat
}

#' Create a 4-node star graph (center = A, spokes = B, C, D)
make_star_4 <- function() {
  mat <- matrix(0, 4, 4, dimnames = list(c("A", "B", "C", "D"),
                                          c("A", "B", "C", "D")))
  mat["A", "B"] <- 1
  mat["A", "C"] <- 1
  mat["A", "D"] <- 1
  mat
}

#' Create a disconnected 4-node graph (A->B and C->D, no cross-links)
make_disconnected_4 <- function() {
  mat <- matrix(0, 4, 4, dimnames = list(c("A", "B", "C", "D"),
                                          c("A", "B", "C", "D")))
  mat["A", "B"] <- 1
  mat["C", "D"] <- 1
  mat
}

#' Create a signed matrix with positive and negative edges
make_signed_3 <- function() {
  mat <- matrix(0, 3, 3, dimnames = list(c("X", "Y", "Z"), c("X", "Y", "Z")))
  mat["X", "Y"] <- 1
  mat["Y", "Z"] <- -1
  mat["Z", "X"] <- 0.5
  mat
}

#' Create a 1x1 single-node matrix
make_single_node <- function() {
  matrix(0.5, 1, 1, dimnames = list("Solo", "Solo"))
}


# ============================================================================
# 1. ADJACENCY MATRIX CONSTRUCTION: ses_make_matrix
# ============================================================================

test_that("ses_make_matrix builds correct matrix from vectors", {
  from   <- c("A", "B", "C")
  to     <- c("B", "C", "A")
  weight <- c(1.0, 0.5, -1.0)

  mat <- ses_make_matrix(from, to, weight)

  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 3)
  expect_equal(ncol(mat), 3)
  expect_equal(mat["A", "B"], 1.0)
  expect_equal(mat["B", "C"], 0.5)
  expect_equal(mat["C", "A"], -1.0)
  expect_equal(mat["A", "A"], 0)  # no self-loop
})

test_that("ses_make_matrix produces named rows and columns", {
  mat <- ses_make_matrix(c("X", "Y"), c("Y", "X"), c(1, -1))

  expect_true(!is.null(rownames(mat)))
  expect_true(!is.null(colnames(mat)))
  expect_true(all(c("X", "Y") %in% rownames(mat)))
  expect_true(all(c("X", "Y") %in% colnames(mat)))
})

test_that("ses_make_matrix handles weighted edges correctly", {
  from   <- c("A", "A", "B")
  to     <- c("B", "C", "C")
  weight <- c(0.25, 0.75, -0.5)

  mat <- ses_make_matrix(from, to, weight)

  expect_equal(mat["A", "B"], 0.25)
  expect_equal(mat["A", "C"], 0.75)
  expect_equal(mat["B", "C"], -0.5)
  # Unconnected entries should be zero
  expect_equal(mat["C", "A"], 0)
  expect_equal(mat["B", "A"], 0)
})

test_that("ses_make_matrix produces square matrix", {
  mat <- ses_make_matrix(c("A"), c("B"), c(1))
  expect_equal(nrow(mat), ncol(mat))
  expect_equal(nrow(mat), 2)
})

test_that("ses_make_matrix rejects mismatched lengths", {
  expect_error(ses_make_matrix(c("A", "B"), c("C"), c(1, 2)))
})

test_that("ses_make_matrix rejects non-numeric weights", {
  expect_error(ses_make_matrix(c("A"), c("B"), c("high")))
})

test_that("ses_make_matrix rejects non-character from/to", {
  expect_error(ses_make_matrix(c(1, 2), c(3, 4), c(1, 1)))
})

test_that("ses_make_matrix handles duplicate edges (last wins)", {
  from   <- c("A", "A")
  to     <- c("B", "B")
  weight <- c(1.0, 2.0)

  mat <- ses_make_matrix(from, to, weight)
  # Matrix indexing: second assignment overwrites the first
  expect_equal(mat["A", "B"], 2.0)
})


# ============================================================================
# 2. CLD TO NUMERIC MATRIX: cld_to_numeric_matrix
# ============================================================================

test_that("cld_to_numeric_matrix converts basic CLD data", {
  nodes <- data.frame(
    id = c("n1", "n2", "n3"),
    label = c("Driver", "Pressure", "State"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("n1", "n2"),
    to = c("n2", "n3"),
    polarity = c("+", "-"),
    strength = c("strong", "medium"),
    stringsAsFactors = FALSE
  )

  mat <- cld_to_numeric_matrix(nodes, edges)

  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 3)
  expect_equal(ncol(mat), 3)
  expect_equal(mat["Driver", "Pressure"], 1.0)
  expect_equal(mat["Pressure", "State"], -0.5)
})

test_that("cld_to_numeric_matrix returns NULL for empty nodes", {
  expect_null(cld_to_numeric_matrix(NULL, data.frame(from = "a", to = "b")))
  expect_null(cld_to_numeric_matrix(data.frame(), data.frame(from = "a", to = "b")))
})

test_that("cld_to_numeric_matrix returns NULL for empty edges", {
  nodes <- data.frame(id = c("n1", "n2"), stringsAsFactors = FALSE)
  expect_null(cld_to_numeric_matrix(nodes, NULL))
  expect_null(cld_to_numeric_matrix(nodes, data.frame()))
})

test_that("cld_to_numeric_matrix uses labels by default", {
  nodes <- data.frame(
    id = c("n1", "n2"),
    label = c("Fishing", "Stock"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("n1"), to = c("n2"),
    polarity = "+", strength = "medium",
    stringsAsFactors = FALSE
  )

  mat <- cld_to_numeric_matrix(nodes, edges, use_labels = TRUE)
  expect_true("Fishing" %in% rownames(mat))
  expect_true("Stock" %in% colnames(mat))
})

test_that("cld_to_numeric_matrix uses IDs when use_labels = FALSE", {
  nodes <- data.frame(
    id = c("n1", "n2"),
    label = c("Fishing", "Stock"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("n1"), to = c("n2"),
    polarity = "+", strength = "medium",
    stringsAsFactors = FALSE
  )

  mat <- cld_to_numeric_matrix(nodes, edges, use_labels = FALSE)
  expect_true("n1" %in% rownames(mat))
  expect_true("n2" %in% colnames(mat))
})

test_that("cld_to_numeric_matrix maps weight keys correctly", {
  nodes <- data.frame(id = c("a", "b", "c", "d", "e", "f", "g"),
                      label = paste0("N", 1:7),
                      stringsAsFactors = FALSE)
  edges <- data.frame(
    from     = c("a", "b", "c",  "d",  "e",  "f"),
    to       = c("b", "c", "d",  "e",  "f",  "g"),
    polarity = c("+", "+", "+",  "-",  "-",  "-"),
    strength = c("strong", "medium", "weak", "strong", "medium", "weak"),
    stringsAsFactors = FALSE
  )

  mat <- cld_to_numeric_matrix(nodes, edges)

  expect_equal(mat["N1", "N2"], 1.0)
  expect_equal(mat["N2", "N3"], 0.5)
  expect_equal(mat["N3", "N4"], 0.25)
  expect_equal(mat["N4", "N5"], -1.0)
  expect_equal(mat["N5", "N6"], -0.5)
  expect_equal(mat["N6", "N7"], -0.25)
})

test_that("cld_to_numeric_matrix applies confidence scaling", {
  nodes <- data.frame(id = c("a", "b"), label = c("A", "B"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(
    from = "a", to = "b",
    polarity = "+", strength = "strong",
    confidence = 2.5,
    stringsAsFactors = FALSE
  )

  mat_no_conf <- cld_to_numeric_matrix(nodes, edges, include_confidence = FALSE)
  mat_with_conf <- cld_to_numeric_matrix(nodes, edges, include_confidence = TRUE)

  # With confidence 2.5, weight should be 1.0 * (2.5/5) = 0.5
  expect_equal(mat_no_conf["A", "B"], 1.0)
  expect_equal(mat_with_conf["A", "B"], 0.5)
})

test_that("cld_to_numeric_matrix accepts custom weight_map", {
  nodes <- data.frame(id = c("a", "b"), label = c("A", "B"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(
    from = "a", to = "b",
    polarity = "+", strength = "strong",
    stringsAsFactors = FALSE
  )

  custom_map <- list("+strong" = 99.0)
  mat <- cld_to_numeric_matrix(nodes, edges, weight_map = custom_map)
  expect_equal(mat["A", "B"], 99.0)
})

test_that("cld_to_numeric_matrix handles missing polarity/strength columns", {
  nodes <- data.frame(id = c("a", "b"), label = c("A", "B"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(from = "a", to = "b", stringsAsFactors = FALSE)

  # Should use defaults: polarity = "+", strength = "medium" => 0.5
  mat <- cld_to_numeric_matrix(nodes, edges)
  expect_equal(mat["A", "B"], 0.5)
})

test_that("cld_to_numeric_matrix errors on missing required columns", {
  nodes <- data.frame(name = "a", stringsAsFactors = FALSE)
  edges <- data.frame(from = "a", to = "b", stringsAsFactors = FALSE)
  expect_error(cld_to_numeric_matrix(nodes, edges), "id")

  nodes2 <- data.frame(id = "a", stringsAsFactors = FALSE)
  edges2 <- data.frame(source = "a", destination = "b", stringsAsFactors = FALSE)
  expect_error(cld_to_numeric_matrix(nodes2, edges2), "from.*to")
})

test_that("cld_to_numeric_matrix handles duplicate labels", {
  nodes <- data.frame(
    id = c("a", "b", "c"),
    label = c("Fish", "Fish", "Stock"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(from = "a", to = "c", polarity = "+", strength = "medium",
                      stringsAsFactors = FALSE)

  mat <- cld_to_numeric_matrix(nodes, edges)
  # Should make names unique
  expect_equal(nrow(mat), 3)
  expect_false(anyDuplicated(rownames(mat)))
})


# ============================================================================
# 3. LAPLACIAN ANALYSIS: laplacian_eigenvalues
# ============================================================================

test_that("laplacian_eigenvalues computes eigenvalues for cycle graph", {
  mat <- make_cycle_3()
  result <- laplacian_eigenvalues(mat)

  expect_true(is.list(result))
  expect_true("eigenvalues" %in% names(result))
  expect_true("fiedler_value" %in% names(result))
  expect_true("n_components" %in% names(result))
  expect_true("direction" %in% names(result))
  expect_equal(length(result$eigenvalues), 3)
  expect_equal(result$direction, "cols")
})

test_that("laplacian_eigenvalues returns correct values for identity matrix", {
  # Identity matrix: L = diag(rowSums(I)) - I = I - I = 0
  # All eigenvalues should be zero
  mat <- diag(3)
  rownames(mat) <- colnames(mat) <- c("A", "B", "C")

  result <- laplacian_eigenvalues(mat)

  # L = diag(1,1,1) - I = 0, so all eigenvalues should be 0
  expect_true(all(abs(result$eigenvalues) < 1e-10))
})

test_that("laplacian_eigenvalues handles fully connected graph", {
  # Fully connected 3-node graph (all edges weight 1)
  mat <- matrix(1, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  diag(mat) <- 0

  result <- laplacian_eigenvalues(mat)

  # For undirected complete graph K3: eigenvalues are 0, 3, 3
  # Directed may differ, but should have at least one zero eigenvalue
  expect_true(any(abs(result$eigenvalues) < 1e-10))
  expect_equal(result$n_components, 1)
  expect_true(result$fiedler_value > 0)
})

test_that("laplacian_eigenvalues detects disconnected graph", {
  mat <- make_disconnected_4()
  result <- laplacian_eigenvalues(mat)

  # A disconnected graph should have more than one zero eigenvalue
  near_zero <- sum(abs(result$eigenvalues) < 1e-10)
  expect_true(near_zero >= 2)
  expect_true(result$n_components >= 2)
})

test_that("laplacian_eigenvalues supports direction parameter", {
  mat <- make_cycle_3()

  result_cols <- laplacian_eigenvalues(mat, direction = "cols")
  result_rows <- laplacian_eigenvalues(mat, direction = "rows")

  expect_equal(result_cols$direction, "cols")
  expect_equal(result_rows$direction, "rows")
  expect_equal(length(result_cols$eigenvalues), length(result_rows$eigenvalues))
})

test_that("laplacian_eigenvalues returns sorted eigenvalues", {
  mat <- make_cycle_3()
  result <- laplacian_eigenvalues(mat)

  expect_true(all(diff(result$eigenvalues) >= -1e-10))
})

test_that("laplacian_eigenvalues rejects NULL input", {
  expect_error(laplacian_eigenvalues(NULL), "NULL")
})

test_that("laplacian_eigenvalues rejects non-square matrix", {
  mat <- matrix(1, 2, 3)
  expect_error(laplacian_eigenvalues(mat), "square")
})

test_that("laplacian_eigenvalues works for single-node matrix", {
  mat <- make_single_node()
  result <- laplacian_eigenvalues(mat)

  expect_equal(length(result$eigenvalues), 1)
})

test_that("laplacian_eigenvalues star graph has known structure", {
  mat <- make_star_4()
  result <- laplacian_eigenvalues(mat)

  # Star with 4 nodes: center has out-degree 3, leaves have 0
  expect_equal(length(result$eigenvalues), 4)
  # At least one zero eigenvalue
  expect_true(any(abs(result$eigenvalues) < 1e-10))
})


# ============================================================================
# 4. LAPLACIAN STABILITY: laplacian_stability
# ============================================================================

test_that("laplacian_stability returns extended result", {
  mat <- make_cycle_3()
  result <- laplacian_stability(mat)

  expect_true("stability_class" %in% names(result))
  expect_true("interpretation" %in% names(result))
  expect_true("spectral_gap" %in% names(result))
  expect_true("max_eigenvalue" %in% names(result))
  expect_true(result$stability_class %in%
                c("disconnected", "fragmented", "weakly_connected", "strongly_connected"))
  expect_true(is.character(result$interpretation))
  expect_true(nchar(result$interpretation) > 0)
})

test_that("laplacian_stability classifies disconnected graph", {
  mat <- make_disconnected_4()
  result <- laplacian_stability(mat)

  expect_equal(result$stability_class, "disconnected")
  expect_true(grepl("disconnected", result$interpretation, ignore.case = TRUE))
})

test_that("laplacian_stability classifies strongly connected graph", {
  # Fully connected 3x3
  mat <- matrix(1, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  diag(mat) <- 0

  result <- laplacian_stability(mat)

  # Fiedler value = 3 for K3, so "strongly_connected"
  expect_equal(result$stability_class, "strongly_connected")
})

test_that("laplacian_stability classifies fragmented graph", {
  # Near-disconnected: very weak link
  mat <- matrix(0, 4, 4, dimnames = list(LETTERS[1:4], LETTERS[1:4]))
  mat["A", "B"] <- 1
  mat["C", "D"] <- 1
  mat["B", "C"] <- 0.001  # very weak bridge

  result <- laplacian_stability(mat)

  # Should be fragmented (fiedler < 0.01) or weakly_connected
  expect_true(result$stability_class %in% c("fragmented", "weakly_connected"))
})

test_that("laplacian_stability spectral_gap is non-negative", {
  mat <- make_cycle_3()
  result <- laplacian_stability(mat)
  expect_true(result$spectral_gap >= 0)
})

test_that("laplacian_stability max_eigenvalue is non-negative", {
  mat <- make_cycle_3()
  result <- laplacian_stability(mat)
  expect_true(result$max_eigenvalue >= 0)
})


# ============================================================================
# 5. BOOLEAN NETWORKS: ses_create_boolean_rules
# ============================================================================

test_that("ses_create_boolean_rules creates rules for simple matrix", {
  mat <- make_cycle_3()
  rules <- ses_create_boolean_rules(mat)

  expect_true(is.data.frame(rules))
  expect_true("targets" %in% names(rules))
  expect_true("factors" %in% names(rules))
  expect_equal(nrow(rules), 3)
})

test_that("ses_create_boolean_rules handles positive regulators", {
  mat <- matrix(0, 2, 2, dimnames = list(c("A", "B"), c("A", "B")))
  mat["A", "B"] <- 1  # A positively regulates B

  rules <- ses_create_boolean_rules(mat)

  # B's rule should reference A
  b_rule <- rules$factors[rules$targets == "B"]
  expect_true(grepl("A", b_rule))
  expect_false(grepl("!A", b_rule))
})

test_that("ses_create_boolean_rules handles negative regulators with !", {
  mat <- matrix(0, 2, 2, dimnames = list(c("A", "B"), c("A", "B")))
  mat["A", "B"] <- -1  # A negatively regulates B

  rules <- ses_create_boolean_rules(mat)

  b_rule <- rules$factors[rules$targets == "B"]
  expect_true(grepl("!A", b_rule))
})

test_that("ses_create_boolean_rules self-references unregulated nodes", {
  mat <- matrix(0, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  mat["A", "B"] <- 1
  # C has no incoming edges => self-referencing rule

  rules <- ses_create_boolean_rules(mat)

  c_rule <- rules$factors[rules$targets == "C"]
  expect_equal(c_rule, "C")
})

test_that("ses_create_boolean_rules uses OR logic for multiple regulators", {
  mat <- matrix(0, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))
  mat["A", "C"] <- 1
  mat["B", "C"] <- -1

  rules <- ses_create_boolean_rules(mat)

  c_rule <- rules$factors[rules$targets == "C"]
  expect_true(grepl("\\|", c_rule))  # OR operator present
  expect_true(grepl("A", c_rule))
  expect_true(grepl("!B", c_rule))
})

test_that("ses_create_boolean_rules cleans names for BoolNet compatibility", {
  mat <- matrix(0, 2, 2, dimnames = list(c("My Node", "Other-Node"),
                                          c("My Node", "Other-Node")))
  mat[1, 2] <- 1

  rules <- ses_create_boolean_rules(mat)

  # Names should be alphanumeric + underscore only
  expect_true(all(grepl("^[[:alnum:]_]+$", rules$targets)))
})

test_that("ses_create_boolean_rules rejects NULL input", {
  expect_error(ses_create_boolean_rules(NULL), "NULL")
})

test_that("ses_create_boolean_rules rejects non-square matrix", {
  mat <- matrix(1, 2, 3)
  expect_error(ses_create_boolean_rules(mat), "square")
})

test_that("ses_create_boolean_rules handles signed matrix correctly", {
  mat <- make_signed_3()
  rules <- ses_create_boolean_rules(mat)

  expect_equal(nrow(rules), 3)
  # Y is regulated by X (positive)
  y_rule <- rules$factors[rules$targets == "Y"]
  expect_true(grepl("X", y_rule))
  # Z is regulated by Y (negative)
  z_rule <- rules$factors[rules$targets == "Z"]
  expect_true(grepl("!Y", z_rule))
})


# ============================================================================
# 6. BOOLEAN ATTRACTORS: ses_boolean_attractors
# ============================================================================

test_that("ses_boolean_attractors requires BoolNet package", {
  skip_if_not_installed("BoolNet")

  mat <- make_cycle_3()
  rules <- ses_create_boolean_rules(mat)
  result <- ses_boolean_attractors(rules, max_nodes = 25)

  expect_true(is.list(result))
  expect_true("n_states" %in% names(result))
  expect_true("n_attractors" %in% names(result))
  expect_true("attractors" %in% names(result))
  expect_true("basins" %in% names(result))
  expect_true("n_genes" %in% names(result))
  expect_equal(result$n_genes, 3)
  expect_true(result$n_attractors >= 1)
})

test_that("ses_boolean_attractors rejects too many nodes", {
  skip_if_not_installed("BoolNet")

  rules <- data.frame(
    targets = paste0("N", 1:30),
    factors = paste0("N", 1:30),
    stringsAsFactors = FALSE
  )

  expect_error(ses_boolean_attractors(rules, max_nodes = 25), "exceeding the maximum")
})


# ============================================================================
# 7. BOOLEAN MODEL: boolean_model convenience wrapper
# ============================================================================

test_that("boolean_model returns rules even without BoolNet", {
  mat <- make_cycle_3()

  if (!requireNamespace("BoolNet", quietly = TRUE)) {
    # Without BoolNet, boolean_model should fail at the attractors step
    expect_error(boolean_model(mat))
  } else {
    result <- boolean_model(mat)
    expect_true(is.list(result))
    expect_true("rules" %in% names(result))
    expect_true("analysis" %in% names(result))
    expect_true("n_nodes" %in% names(result))
    expect_true("skipped" %in% names(result))
    expect_equal(result$n_nodes, 3)
    expect_false(result$skipped)
  }
})

test_that("boolean_model skips analysis when too many nodes", {
  skip_if_not_installed("BoolNet")

  # Create a 30-node matrix
  n <- 30
  mat <- matrix(0, n, n, dimnames = list(paste0("N", 1:n), paste0("N", 1:n)))
  for (i in 1:(n - 1)) mat[i, i + 1] <- 1

  result <- boolean_model(mat, max_nodes = 25)

  expect_true(result$skipped)
  expect_null(result$analysis)
  expect_true(is.data.frame(result$rules))
})

test_that("boolean_model rejects NULL matrix", {
  expect_error(boolean_model(NULL))
})


# ============================================================================
# 8. DETERMINISTIC SIMULATION: simulate_dynamics
# ============================================================================

test_that("simulate_dynamics returns correct output structure", {
  mat <- make_cycle_3()
  result <- simulate_dynamics(mat, n_iter = 100)

  expect_true(is.list(result))
  expect_true("time_series" %in% names(result))
  expect_true("n_iter" %in% names(result))
  expect_true("diverged" %in% names(result))
  expect_true("initial_state" %in% names(result))
  expect_true(is.matrix(result$time_series))
})

test_that("simulate_dynamics output shape matches parameters", {
  mat <- make_cycle_3()
  result <- simulate_dynamics(mat, n_iter = 100)

  expect_equal(nrow(result$time_series), 3)
  expect_equal(ncol(result$time_series), 100)
  expect_equal(result$n_iter, 100)
})

test_that("simulate_dynamics uses custom initial state", {
  mat <- make_cycle_3()
  init <- c(1.0, 0.0, 0.0)

  result <- simulate_dynamics(mat, n_iter = 50, initial_state = init)

  expect_equal(result$initial_state, init)
  expect_equal(result$time_series[, 1], init)
})

test_that("simulate_dynamics rejects wrong-length initial state", {
  mat <- make_cycle_3()
  expect_error(simulate_dynamics(mat, initial_state = c(1, 0)), "length")
})

test_that("simulate_dynamics detects divergence", {
  # Large eigenvalues will cause divergence
  mat <- matrix(c(10, 10, 10, 10), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))

  result <- simulate_dynamics(mat, n_iter = 200, detect_divergence = TRUE)

  expect_true(result$diverged)
  expect_true(!is.null(result$diverged_at))
  expect_true(result$diverged_at < 200)
  # Remaining entries after divergence should be NA
  if (result$diverged_at < 200) {
    expect_true(all(is.na(result$time_series[, result$diverged_at + 1])))
  }
})

test_that("simulate_dynamics does not diverge for zero matrix", {
  mat <- matrix(0, 3, 3, dimnames = list(c("A", "B", "C"), c("A", "B", "C")))

  result <- simulate_dynamics(mat, n_iter = 100, initial_state = c(1, 2, 3))

  expect_false(result$diverged)
  # Zero matrix: t(mat) %*% state = 0 for all t > 1
  expect_equal(result$time_series[, 1], c(1, 2, 3))
  expect_true(all(result$time_series[, 2] == 0))
})

test_that("simulate_dynamics clamps n_iter to valid range", {
  mat <- make_cycle_3()

  # Very small n_iter should be clamped to minimum (50)
  result <- simulate_dynamics(mat, n_iter = 1)
  expect_true(result$n_iter >= 50)

  # Very large n_iter should be clamped to maximum (5000)
  result2 <- simulate_dynamics(mat, n_iter = 999999)
  expect_true(result2$n_iter <= 5000)
})

test_that("simulate_dynamics rejects NULL matrix", {
  expect_error(simulate_dynamics(NULL), "NULL")
})

test_that("simulate_dynamics rejects non-square matrix", {
  mat <- matrix(1, 2, 3)
  expect_error(simulate_dynamics(mat), "square")
})

test_that("simulate_dynamics works with single-node matrix", {
  mat <- make_single_node()
  result <- simulate_dynamics(mat, n_iter = 50)

  expect_equal(nrow(result$time_series), 1)
  expect_equal(ncol(result$time_series), 50)
})

test_that("simulate_dynamics has named rows from matrix", {
  mat <- make_cycle_3()
  result <- simulate_dynamics(mat, n_iter = 50)

  expect_equal(rownames(result$time_series), c("A", "B", "C"))
})

test_that("simulate_dynamics converges for contracting matrix", {
  # Matrix with spectral radius < 1 should converge
  mat <- matrix(c(0.1, 0, 0, 0.1), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))

  result <- simulate_dynamics(mat, n_iter = 200, initial_state = c(10, 10))

  expect_false(result$diverged)
  # Values should decrease toward zero
  final <- result$time_series[, 200]
  expect_true(all(abs(final) < abs(result$initial_state)))
})


# ============================================================================
# 9. PARTICIPATION RATIO: participation_ratio
# ============================================================================

test_that("participation_ratio returns correct structure", {
  mat <- make_cycle_3()
  result <- participation_ratio(mat)

  expect_true(is.data.frame(result))
  expect_true("component" %in% names(result))
  expect_true("participation_ratio" %in% names(result))
  expect_true("eigenvalue_real" %in% names(result))
  expect_true("eigenvalue_imag" %in% names(result))
  expect_equal(nrow(result), 3)
})

test_that("participation_ratio values are in [0, 1]", {
  mat <- make_cycle_3()
  result <- participation_ratio(mat)

  expect_true(all(result$participation_ratio >= 0))
  expect_true(all(result$participation_ratio <= 1))
})

test_that("participation_ratio works for single node", {
  mat <- make_single_node()
  result <- participation_ratio(mat)

  expect_equal(nrow(result), 1)
  expect_true(result$participation_ratio >= 0)
  expect_true(result$participation_ratio <= 1)
})

test_that("participation_ratio has correct dimensions for 4-node graph", {
  mat <- make_star_4()
  result <- participation_ratio(mat)

  expect_equal(nrow(result), 4)
  expect_true(all(result$participation_ratio >= 0))
  expect_true(all(result$participation_ratio <= 1))
})

test_that("participation_ratio rejects NULL input", {
  expect_error(participation_ratio(NULL), "NULL")
})

test_that("participation_ratio rejects non-square matrix", {
  mat <- matrix(1, 2, 3)
  expect_error(participation_ratio(mat), "square")
})

test_that("participation_ratio returns real eigenvalue parts", {
  mat <- make_cycle_3()
  result <- participation_ratio(mat)

  expect_true(is.numeric(result$eigenvalue_real))
  expect_true(is.numeric(result$eigenvalue_imag))
  expect_false(any(is.na(result$eigenvalue_real)))
})

test_that("participation_ratio for identity-like matrix", {
  # Diagonal matrix: each eigenmode is localized to exactly one node
  mat <- diag(3)
  rownames(mat) <- colnames(mat) <- c("A", "B", "C")

  result <- participation_ratio(mat)
  expect_equal(nrow(result), 3)
  expect_true(all(result$participation_ratio >= 0))
  expect_true(all(result$participation_ratio <= 1))
})


# ============================================================================
# 10. MATRIX RANDOMIZATION: ses_randomize_matrix
# ============================================================================

test_that("ses_randomize_matrix preserves sign structure", {
  mat <- make_signed_3()
  set.seed(123)
  rand <- ses_randomize_matrix(mat, type = "uniform")

  # Signs should match where original is non-zero
  nonzero <- mat != 0
  expect_equal(sign(rand[nonzero]), sign(mat[nonzero]))
  # Zero entries should remain zero
  expect_true(all(rand[!nonzero] == 0))
})

test_that("ses_randomize_matrix preserves dimensions and names", {
  mat <- make_cycle_3()
  rand <- ses_randomize_matrix(mat)

  expect_equal(dim(rand), dim(mat))
  expect_equal(dimnames(rand), dimnames(mat))
})

test_that("ses_randomize_matrix ordinal type produces discrete values", {
  mat <- make_cycle_3()
  set.seed(42)
  rand <- ses_randomize_matrix(mat, type = "ordinal")

  # Non-zero entries should have absolute values from {0, 0.25, 0.5, 0.75, 1}
  nonzero_vals <- abs(rand[rand != 0])
  allowed <- c(0, 0.25, 0.5, 0.75, 1)
  expect_true(all(nonzero_vals %in% allowed))
})

test_that("ses_randomize_matrix uniform type produces continuous values", {
  mat <- make_cycle_3()
  set.seed(42)
  rand <- ses_randomize_matrix(mat, type = "uniform")

  nonzero_vals <- abs(rand[rand != 0])
  expect_true(all(nonzero_vals >= 0 & nonzero_vals <= 1))
})


# ============================================================================
# 11. MONTE CARLO STATE-SHIFT: state_shift_monte_carlo
# ============================================================================

test_that("state_shift_monte_carlo returns correct structure", {
  mat <- make_cycle_3()
  set.seed(42)
  result <- state_shift_monte_carlo(mat, n_simulations = 5, n_iter = 100)

  expect_true(is.list(result))
  expect_true("final_states" %in% names(result))
  expect_true("n_simulations" %in% names(result))
  expect_true("randomization_type" %in% names(result))
  expect_true("all_matrices" %in% names(result))
  expect_equal(result$n_simulations, 5)
  expect_true(is.matrix(result$final_states))
  expect_equal(nrow(result$final_states), 3)
  expect_equal(ncol(result$final_states), 5)
})

test_that("state_shift_monte_carlo is reproducible with set.seed", {
  mat <- make_cycle_3()

  set.seed(42)
  result1 <- state_shift_monte_carlo(mat, n_simulations = 3, n_iter = 100)

  set.seed(42)
  result2 <- state_shift_monte_carlo(mat, n_simulations = 3, n_iter = 100)

  expect_equal(result1$final_states, result2$final_states)
})

test_that("state_shift_monte_carlo computes success rate with target_nodes", {
  mat <- make_cycle_3()
  set.seed(42)
  result <- state_shift_monte_carlo(mat, n_simulations = 10, n_iter = 100,
                                     target_nodes = c("A"))

  expect_true(!is.null(result$success_rate))
  expect_true(result$success_rate >= 0 && result$success_rate <= 1)
  expect_true(!is.null(result$target_success))
  expect_equal(length(result$target_success), 10)
})

test_that("state_shift_monte_carlo stores all randomized matrices", {
  mat <- make_cycle_3()
  set.seed(42)
  result <- state_shift_monte_carlo(mat, n_simulations = 5, n_iter = 100)

  expect_equal(length(result$all_matrices), 5)
  expect_true(all(sapply(result$all_matrices, is.matrix)))
  expect_true(all(sapply(result$all_matrices, function(m) all(dim(m) == c(3, 3)))))
})

test_that("state_shift_monte_carlo without target_nodes has NULL success_rate", {
  mat <- make_cycle_3()
  set.seed(42)
  result <- state_shift_monte_carlo(mat, n_simulations = 3, n_iter = 100)

  expect_null(result$success_rate)
  expect_null(result$target_success)
})

test_that("state_shift_monte_carlo rejects NULL matrix", {
  expect_error(state_shift_monte_carlo(NULL), "NULL")
})

test_that("state_shift_monte_carlo works with small matrix", {
  mat <- matrix(c(0, 1, -1, 0), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))
  set.seed(42)
  result <- state_shift_monte_carlo(mat, n_simulations = 3, n_iter = 100)

  expect_equal(nrow(result$final_states), 2)
  expect_equal(ncol(result$final_states), 3)
})


# ============================================================================
# 12. INTERVENTION: ses_add_intervention
# ============================================================================

test_that("ses_add_intervention extends matrix dimensions", {
  mat <- make_cycle_3()
  set.seed(42)
  ext <- ses_add_intervention(mat, "Policy", c("A", "B"), c("C"))

  expect_equal(nrow(ext), 4)
  expect_equal(ncol(ext), 4)
  expect_true("Policy" %in% rownames(ext))
  expect_true("Policy" %in% colnames(ext))
})

test_that("ses_add_intervention preserves original matrix", {
  mat <- make_cycle_3()
  set.seed(42)
  ext <- ses_add_intervention(mat, "Policy", c("A"), c("B"))

  # Original 3x3 block should be unchanged
  expect_equal(ext[1:3, 1:3], mat)
})

test_that("ses_add_intervention sets affected node weights", {
  mat <- make_cycle_3()
  set.seed(42)
  ext <- ses_add_intervention(mat, "Policy", c("A", "B"), c("C"))

  # Intervention row should have non-zero entries for affected nodes
  expect_true(ext["Policy", "A"] != 0)
  expect_true(ext["Policy", "B"] != 0)
  # Non-affected nodes should be zero
  expect_equal(ext["Policy", "C"], 0)
})

test_that("ses_add_intervention sets indicator node weights", {
  mat <- make_cycle_3()
  set.seed(42)
  ext <- ses_add_intervention(mat, "Policy", c("A"), c("B", "C"))

  # Indicator column should have non-zero entries for indicator nodes
  expect_true(ext["B", "Policy"] != 0)
  expect_true(ext["C", "Policy"] != 0)
})

test_that("ses_add_intervention errors when no affected nodes exist", {
  mat <- make_cycle_3()
  expect_error(ses_add_intervention(mat, "Policy", c("X", "Y"), c("A")),
               "None of the specified affected nodes")
})

test_that("ses_add_intervention rejects NULL matrix", {
  expect_error(ses_add_intervention(NULL, "Policy", c("A"), c("B")), "NULL")
})

test_that("ses_add_intervention rejects empty name", {
  mat <- make_cycle_3()
  expect_error(ses_add_intervention(mat, "", c("A"), c("B")))
})


# ============================================================================
# 13. INTERVENTION COMPARISON: ses_compare_interventions
# ============================================================================

test_that("ses_compare_interventions returns correct structure", {
  mat <- make_cycle_3()
  set.seed(42)
  mat_int <- ses_add_intervention(mat, "Policy", c("A"), c("B"))

  comparison <- ses_compare_interventions(mat, mat_int, n_iter = 100)

  expect_true(is.data.frame(comparison))
  expect_true("node" %in% names(comparison))
  expect_true("state_original" %in% names(comparison))
  expect_true("state_intervention" %in% names(comparison))
  expect_true("delta" %in% names(comparison))
  expect_true("change_direction" %in% names(comparison))
  expect_equal(nrow(comparison), 3)  # original nodes only
})

test_that("ses_compare_interventions change_direction values are valid", {
  mat <- make_cycle_3()
  set.seed(42)
  mat_int <- ses_add_intervention(mat, "Policy", c("A", "B"), c("C"))

  comparison <- ses_compare_interventions(mat, mat_int, n_iter = 100)

  expect_true(all(comparison$change_direction %in%
                    c("Improved", "Worsened", "No change")))
})

test_that("ses_compare_interventions delta is consistent with states", {
  mat <- make_cycle_3()
  set.seed(42)
  mat_int <- ses_add_intervention(mat, "Policy", c("A"), c("B"))

  comparison <- ses_compare_interventions(mat, mat_int, n_iter = 100)

  expected_delta <- comparison$state_intervention - comparison$state_original
  expect_equal(comparison$delta, expected_delta)
})


# ============================================================================
# 14. FULL INTERVENTION SIMULATION: intervention_simulation
# ============================================================================

test_that("intervention_simulation returns complete result", {
  mat <- make_cycle_3()
  set.seed(42)
  result <- intervention_simulation(
    mat, "Policy", c("A", "B"), c("C"),
    n_iter = 100, run_monte_carlo = FALSE
  )

  expect_true(is.list(result))
  expect_true("intervention_matrix" %in% names(result))
  expect_true("comparison" %in% names(result))
  expect_true("monte_carlo_original" %in% names(result))
  expect_true("monte_carlo_intervention" %in% names(result))
  expect_null(result$monte_carlo_original)
  expect_null(result$monte_carlo_intervention)

  # Intervention matrix should be one dimension larger
  expect_equal(nrow(result$intervention_matrix), 4)
})

test_that("intervention_simulation with monte carlo", {
  mat <- make_cycle_3()
  set.seed(42)
  result <- intervention_simulation(
    mat, "Policy", c("A"), c("B"),
    n_iter = 100, run_monte_carlo = TRUE,
    n_simulations = 5, target_nodes = c("A")
  )

  expect_true(!is.null(result$monte_carlo_original))
  expect_true(!is.null(result$monte_carlo_intervention))
  expect_equal(result$monte_carlo_original$n_simulations, 5)
})

test_that("intervention_simulation rejects NULL matrix", {
  expect_error(intervention_simulation(NULL, "Policy", c("A"), c("B")), "NULL")
})


# ============================================================================
# 15. MATRIX VALIDATION (internal .validate_matrix)
# ============================================================================

test_that("validation rejects NULL matrix via public functions", {
  expect_error(laplacian_eigenvalues(NULL), "NULL")
  expect_error(simulate_dynamics(NULL), "NULL")
  expect_error(participation_ratio(NULL), "NULL")
})

test_that("validation rejects non-matrix input", {
  expect_error(laplacian_eigenvalues(data.frame(a = 1)), "matrix")
  expect_error(laplacian_eigenvalues(list(a = 1)), "matrix")
})

test_that("validation rejects non-numeric matrix", {
  mat <- matrix(c("a", "b", "c", "d"), 2, 2)
  expect_error(laplacian_eigenvalues(mat), "numeric")
})

test_that("validation rejects non-square matrix", {
  mat <- matrix(1:6, 2, 3)
  expect_error(laplacian_eigenvalues(mat), "square")
})

test_that("validation rejects empty matrix", {
  mat <- matrix(numeric(0), 0, 0)
  expect_error(laplacian_eigenvalues(mat), "empty")
})


# ============================================================================
# 16. ISA TO NUMERIC MATRIX: isa_to_numeric_matrix
# ============================================================================

test_that("isa_to_numeric_matrix returns NULL for NULL input", {
  expect_null(isa_to_numeric_matrix(NULL))
})

test_that("isa_to_numeric_matrix returns NULL for empty ISA data", {
  isa <- list(drivers = data.frame(), activities = data.frame())
  expect_null(isa_to_numeric_matrix(isa))
})

test_that("isa_to_numeric_matrix builds matrix from ISA structure", {
  isa <- list(
    drivers = data.frame(id = "d1", name = "Climate", stringsAsFactors = FALSE),
    activities = data.frame(id = "a1", name = "Fishing", stringsAsFactors = FALSE),
    pressures = data.frame(),
    marine_processes = data.frame(),
    ecosystem_services = data.frame(),
    goods_benefits = data.frame(),
    responses = data.frame(),
    adjacency_matrices = NULL
  )

  mat <- isa_to_numeric_matrix(isa)

  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 2)
  expect_equal(ncol(mat), 2)
  expect_true("Climate" %in% rownames(mat))
  expect_true("Fishing" %in% colnames(mat))
})


# ============================================================================
# 17. ALIAS FUNCTIONS
# ============================================================================

test_that("ses_laplacian_eigenvalues is an alias for laplacian_eigenvalues", {
  expect_identical(ses_laplacian_eigenvalues, laplacian_eigenvalues)
})

test_that("ses_simulate is an alias for simulate_dynamics", {
  expect_identical(ses_simulate, simulate_dynamics)
})

test_that("ses_participation_ratio is an alias for participation_ratio", {
  expect_identical(ses_participation_ratio, participation_ratio)
})

test_that("ses_state_shift is an alias for state_shift_monte_carlo", {
  expect_identical(ses_state_shift, state_shift_monte_carlo)
})

test_that("ses_rf_importance is an alias for random_forest_importance", {
  expect_identical(ses_rf_importance, random_forest_importance)
})


# ============================================================================
# 18. SES DYNAMICS SUMMARY: ses_dynamics_summary
# ============================================================================

test_that("ses_dynamics_summary returns full diagnostic result", {
  nodes <- data.frame(
    id = c("n1", "n2", "n3"),
    label = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    from = c("n1", "n2", "n3"),
    to = c("n2", "n3", "n1"),
    polarity = c("+", "+", "-"),
    strength = c("medium", "strong", "weak"),
    stringsAsFactors = FALSE
  )

  result <- ses_dynamics_summary(nodes, edges, n_iter = 100)

  expect_true(is.list(result))
  expect_true("matrix" %in% names(result))
  expect_true("laplacian" %in% names(result))
  expect_true("simulation" %in% names(result))
  expect_true("participation_ratio" %in% names(result))
  expect_equal(result$n_nodes, 3)
  expect_true(result$n_edges > 0)
})

test_that("ses_dynamics_summary errors on invalid CLD data", {
  expect_error(ses_dynamics_summary(NULL, NULL))
})


# ============================================================================
# 19. RANDOM FOREST IMPORTANCE: random_forest_importance
# ============================================================================

test_that("random_forest_importance requires randomForest package", {
  skip_if_not_installed("randomForest")

  mat <- make_cycle_3()
  set.seed(42)
  mc <- state_shift_monte_carlo(mat, n_simulations = 30, n_iter = 100,
                                 target_nodes = c("A"))

  # Only run if we have both success and failure outcomes
  if (length(unique(mc$target_success)) < 2) {
    skip("All simulations had same outcome - cannot train RF")
  }

  result <- random_forest_importance(mc, n_trees = 50)

  expect_true(is.list(result))
  expect_true("importance" %in% names(result))
  expect_true("top_variables" %in% names(result))
  expect_true("oob_error" %in% names(result))
  expect_true(is.data.frame(result$importance))
  expect_true(result$oob_error >= 0 && result$oob_error <= 1)
})

test_that("random_forest_importance errors without target_nodes", {
  skip_if_not_installed("randomForest")

  mat <- make_cycle_3()
  set.seed(42)
  mc <- state_shift_monte_carlo(mat, n_simulations = 5, n_iter = 100)

  expect_error(random_forest_importance(mc), "target_nodes")
})


# ============================================================================
# 20. EDGE CASES: Robustness tests
# ============================================================================

test_that("all analysis functions handle single-node graph", {
  mat <- make_single_node()

  lap <- laplacian_eigenvalues(mat)
  expect_equal(length(lap$eigenvalues), 1)

  stab <- laplacian_stability(mat)
  expect_true(stab$stability_class %in%
                c("disconnected", "fragmented", "weakly_connected", "strongly_connected"))

  sim <- simulate_dynamics(mat, n_iter = 50)
  expect_equal(nrow(sim$time_series), 1)

  pr <- participation_ratio(mat)
  expect_equal(nrow(pr), 1)
})

test_that("all analysis functions handle disconnected graph", {
  mat <- make_disconnected_4()

  lap <- laplacian_stability(mat)
  expect_equal(lap$stability_class, "disconnected")

  sim <- simulate_dynamics(mat, n_iter = 50)
  expect_equal(nrow(sim$time_series), 4)

  pr <- participation_ratio(mat)
  expect_equal(nrow(pr), 4)
  expect_true(all(pr$participation_ratio >= 0))
  expect_true(all(pr$participation_ratio <= 1))
})

test_that("simulation handles matrix with very large eigenvalues", {
  # Create a matrix that will definitely diverge
  mat <- matrix(c(100, 100, 100, 100), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))

  result <- simulate_dynamics(mat, n_iter = 200, detect_divergence = TRUE)
  expect_true(result$diverged)
})

test_that("simulation without divergence detection runs to completion", {
  mat <- matrix(c(10, 10, 10, 10), 2, 2,
                dimnames = list(c("A", "B"), c("A", "B")))

  result <- simulate_dynamics(mat, n_iter = 50, detect_divergence = FALSE)

  expect_false(result$diverged)
  # All columns should be filled (no early stopping)
  expect_false(any(is.na(result$time_series[, result$n_iter])))
})

test_that("ses_make_matrix handles self-loops", {
  from   <- c("A", "A")
  to     <- c("A", "B")
  weight <- c(0.5, 1.0)

  mat <- ses_make_matrix(from, to, weight)
  expect_equal(mat["A", "A"], 0.5)
  expect_equal(mat["A", "B"], 1.0)
})

test_that("cld_to_numeric_matrix skips edges with unknown node IDs", {
  nodes <- data.frame(id = c("a", "b"), label = c("A", "B"),
                      stringsAsFactors = FALSE)
  edges <- data.frame(
    from = c("a", "x"),
    to = c("b", "y"),
    polarity = c("+", "+"),
    strength = c("medium", "medium"),
    stringsAsFactors = FALSE
  )

  mat <- cld_to_numeric_matrix(nodes, edges)
  # Only the valid edge should be in the matrix
  expect_equal(mat["A", "B"], 0.5)
  # Matrix should still be 2x2 (only known nodes)
  expect_equal(nrow(mat), 2)
})
