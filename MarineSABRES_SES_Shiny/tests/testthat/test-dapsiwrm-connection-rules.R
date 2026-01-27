# tests/testthat/test-dapsiwrm-connection-rules.R
# Tests for DAPSIWRM Connection Rules
# ==============================================================================

library(testthat)

# Source the file under test
source("../../functions/dapsiwrm_connection_rules.R", chdir = TRUE)

# ==============================================================================
# Test: DAPSIWRM_ADJACENCY_RULES Structure
# ==============================================================================

test_that("DAPSIWRM_ADJACENCY_RULES exists and is a list", {
  expect_true(exists("DAPSIWRM_ADJACENCY_RULES"))
  expect_type(DAPSIWRM_ADJACENCY_RULES, "list")
})

test_that("All DAPSIWRM types are defined", {
  expected_types <- c(
    "Drivers", "Activities", "Pressures",
    "Marine Processes & Functioning", "Ecosystem Services",
    "Goods & Benefits", "Responses"
  )

  for (type in expected_types) {
    expect_true(type %in% names(DAPSIWRM_ADJACENCY_RULES),
                info = paste("Missing type:", type))
  }
})

test_that("Each type has required fields", {
  required_fields <- c("targets", "default_polarity", "allowed_polarities",
                       "description", "examples")

  for (type_name in names(DAPSIWRM_ADJACENCY_RULES)) {
    rule <- DAPSIWRM_ADJACENCY_RULES[[type_name]]

    for (field in required_fields) {
      expect_true(field %in% names(rule),
                  info = paste(type_name, "missing field:", field))
    }
  }
})

test_that("Default polarities are valid", {
  valid_polarities <- c("+", "-")

  for (type_name in names(DAPSIWRM_ADJACENCY_RULES)) {
    rule <- DAPSIWRM_ADJACENCY_RULES[[type_name]]
    expect_true(rule$default_polarity %in% valid_polarities,
                info = paste(type_name, "has invalid default polarity"))
  }
})

test_that("Examples have required fields", {
  example_fields <- c("from", "to", "polarity", "strength", "reasoning")

  for (type_name in names(DAPSIWRM_ADJACENCY_RULES)) {
    rule <- DAPSIWRM_ADJACENCY_RULES[[type_name]]

    for (i in seq_along(rule$examples)) {
      example <- rule$examples[[i]]
      for (field in example_fields) {
        expect_true(field %in% names(example),
                    info = paste(type_name, "example", i, "missing:", field))
      }
    }
  }
})

# ==============================================================================
# Test: get_allowed_targets
# ==============================================================================

test_that("get_allowed_targets returns correct targets for Drivers", {
  targets <- get_allowed_targets("Drivers")
  expect_equal(targets, c("Activities"))
})

test_that("get_allowed_targets returns correct targets for Activities", {
  targets <- get_allowed_targets("Activities")
  expect_equal(targets, c("Pressures"))
})

test_that("get_allowed_targets returns correct targets for Pressures", {
  targets <- get_allowed_targets("Pressures")
  expect_equal(targets, c("Marine Processes & Functioning"))
})

test_that("get_allowed_targets returns correct targets for Marine Processes", {
  targets <- get_allowed_targets("Marine Processes & Functioning")
  expect_equal(targets, c("Ecosystem Services"))
})

test_that("get_allowed_targets returns correct targets for Ecosystem Services", {
  targets <- get_allowed_targets("Ecosystem Services")
  expect_equal(targets, c("Goods & Benefits"))
})

test_that("get_allowed_targets returns correct targets for Goods & Benefits", {
  targets <- get_allowed_targets("Goods & Benefits")
  expect_equal(targets, c("Drivers", "Responses"))
})

test_that("get_allowed_targets returns multiple targets for Responses", {
  targets <- get_allowed_targets("Responses")
  expect_true("Drivers" %in% targets)
  expect_true("Activities" %in% targets)
  expect_true("Pressures" %in% targets)
  expect_true("Marine Processes & Functioning" %in% targets)
})

test_that("get_allowed_targets returns empty for unknown type", {
  # log_warning outputs to console, so we capture output instead of warning
  expect_output(
    targets <- get_allowed_targets("Unknown Type"),
    "Unknown DAPSIWRM type"
  )
  expect_equal(targets, character(0))
})

# ==============================================================================
# Test: infer_connection_polarity
# ==============================================================================

test_that("infer_connection_polarity returns + for Drivers to Activities", {
  pol <- infer_connection_polarity(
    "Food security need", "Commercial fishing",
    "Drivers", "Activities"
  )
  expect_equal(pol, "+")
})

test_that("infer_connection_polarity returns + for Activities to Pressures (default)", {
  pol <- infer_connection_polarity(
    "Trawl fishing", "Seabed disturbance",
    "Activities", "Pressures"
  )
  expect_equal(pol, "+")
})

test_that("infer_connection_polarity returns - for treatment Activities", {
  pol <- infer_connection_polarity(
    "Wastewater treatment", "Nutrient pollution",
    "Activities", "Pressures"
  )
  expect_equal(pol, "-")
})

test_that("infer_connection_polarity returns - for reduction Activities", {
  pol <- infer_connection_polarity(
    "Emission reduction", "Air pollution",
    "Activities", "Pressures"
  )
  expect_equal(pol, "-")
})

test_that("infer_connection_polarity handles Pressures to State (decline)", {
  pol <- infer_connection_polarity(
    "Overfishing", "Fish population decline",
    "Pressures", "Marine Processes & Functioning"
  )
  expect_equal(pol, "+")  # Pressure increases decline
})

test_that("infer_connection_polarity handles Pressures to State (quality)", {
  pol <- infer_connection_polarity(
    "Pollution", "Water quality",
    "Pressures", "Marine Processes & Functioning"
  )
  expect_equal(pol, "-")  # Pressure decreases quality
})

test_that("infer_connection_polarity returns - for Responses to Activities", {
  pol <- infer_connection_polarity(
    "Fishing quota", "Commercial fishing",
    "Responses", "Activities"
  )
  expect_equal(pol, "-")
})

test_that("infer_connection_polarity returns + for restoration Responses", {
  pol <- infer_connection_polarity(
    "Habitat restoration", "Seagrass habitat",
    "Responses", "Marine Processes & Functioning"
  )
  expect_equal(pol, "+")
})

test_that("infer_connection_polarity defaults to + for unknown types", {
  pol <- infer_connection_polarity(
    "Something", "Something else",
    "Unknown", "Activities"
  )
  expect_equal(pol, "+")
})

# ==============================================================================
# Test: infer_connection_strength
# ==============================================================================

test_that("infer_connection_strength returns valid strength values", {
  # Test that function returns valid strength values
  valid_strengths <- c("strong", "medium", "weak")

  strength1 <- infer_connection_strength(
    "Overfishing pressure",
    "Commercial fishing activity"
  )
  expect_true(strength1 %in% valid_strengths)

  strength2 <- infer_connection_strength(
    "Fish population health",
    "Fish population decline"
  )
  expect_true(strength2 %in% valid_strengths)
})

test_that("infer_connection_strength returns medium for single word overlap", {
  strength <- infer_connection_strength(
    "Commercial fishing",
    "Fish stock"
  )
  expect_equal(strength, "medium")
})

test_that("infer_connection_strength returns medium for no overlap", {
  strength <- infer_connection_strength(
    "Tourism demand",
    "Nutrient enrichment"
  )
  expect_equal(strength, "medium")
})

test_that("infer_connection_strength recognizes strong keyword pairs", {
  # Overfishing -> fishing
  strength <- infer_connection_strength(
    "Overfishing pressure",
    "Commercial fishing activity"
  )
  expect_equal(strength, "strong")
})

test_that("infer_connection_strength ignores stopwords", {
  strength <- infer_connection_strength(
    "The decline of the population",
    "A decline in the species"
  )
  # "decline" should match, "the", "of", "a", "in" are stopwords
  expect_true(strength %in% c("medium", "strong"))
})

# ==============================================================================
# Test: get_connection_confidence
# ==============================================================================

test_that("get_connection_confidence returns numeric", {
  from_element <- list(name = "Food demand", type = "Drivers")
  to_element <- list(name = "Commercial fishing", type = "Activities")

  confidence <- get_connection_confidence(from_element, to_element)

  expect_type(confidence, "double")
  expect_true(confidence >= 1 && confidence <= 5)
})

test_that("get_connection_confidence increases for valid DAPSIWRM connection", {
  # Valid connection: Drivers -> Activities
  from_element <- list(name = "Tourism demand", type = "Drivers")
  to_element <- list(name = "Recreational boating", type = "Activities")

  confidence <- get_connection_confidence(from_element, to_element)

  expect_gte(confidence, 3)
})

test_that("get_connection_confidence increases for strong keyword overlap", {
  from_element <- list(name = "Fish population", type = "Marine Processes & Functioning")
  to_element <- list(name = "Fish provision", type = "Ecosystem Services")

  confidence <- get_connection_confidence(from_element, to_element)

  expect_gte(confidence, 4)  # Should be high due to "fish" overlap and valid connection
})

test_that("get_connection_confidence decreases for unusual connections", {
  from_element <- list(name = "Seagrass habitat", type = "Marine Processes & Functioning")
  to_element <- list(name = "Tourism demand", type = "Drivers")

  confidence <- get_connection_confidence(from_element, to_element)

  expect_lte(confidence, 3)  # Should be lower for this unusual reverse connection
})

test_that("get_connection_confidence is bounded 1-5", {
  # Test lower bound
  from_element <- list(name = "Random thing", type = "Marine Processes & Functioning")
  to_element <- list(name = "Different thing", type = "Drivers")

  confidence <- get_connection_confidence(from_element, to_element)
  expect_gte(confidence, 1)
  expect_lte(confidence, 5)

  # Test upper bound
  from_element <- list(name = "Fish population health", type = "Drivers")
  to_element <- list(name = "Fish population fishing", type = "Activities")

  confidence <- get_connection_confidence(from_element, to_element)
  expect_gte(confidence, 1)
  expect_lte(confidence, 5)
})

# ==============================================================================
# Test: validate_connection
# ==============================================================================

test_that("validate_connection returns TRUE for standard connections", {
  expect_true(validate_connection("Drivers", "Activities"))
  expect_true(validate_connection("Activities", "Pressures"))
  expect_true(validate_connection("Pressures", "Marine Processes & Functioning"))
  expect_true(validate_connection("Marine Processes & Functioning", "Ecosystem Services"))
  expect_true(validate_connection("Ecosystem Services", "Goods & Benefits"))
  expect_true(validate_connection("Goods & Benefits", "Drivers"))
  expect_true(validate_connection("Goods & Benefits", "Responses"))
  expect_true(validate_connection("Responses", "Activities"))
  expect_true(validate_connection("Responses", "Pressures"))
})

test_that("validate_connection returns FALSE for invalid connections in strict mode", {
  # Drivers should not connect directly to Pressures
  expect_false(validate_connection("Drivers", "Pressures", strict = TRUE))

  # Activities should not connect to Ecosystem Services
  expect_false(validate_connection("Activities", "Ecosystem Services", strict = TRUE))
})

test_that("validate_connection returns TRUE for non-standard connections in permissive mode", {
  # Non-standard but allowed in permissive mode
  expect_true(validate_connection("Drivers", "Pressures", strict = FALSE))
  expect_true(validate_connection("Activities", "Ecosystem Services", strict = FALSE))
})

test_that("validate_connection handles unknown types", {
  # Unknown source type in permissive mode should return TRUE
  expect_true(validate_connection("Unknown", "Activities", strict = FALSE))

  # Unknown source type in strict mode should return FALSE
  expect_false(validate_connection("Unknown", "Activities", strict = TRUE))
})

# ==============================================================================
# Test: get_connection_description
# ==============================================================================

test_that("get_connection_description returns description for valid connection", {
  desc <- get_connection_description("Drivers", "Activities")
  expect_type(desc, "character")
  expect_true(nchar(desc) > 0)
  expect_true(grepl("demand|create|driver", desc, ignore.case = TRUE))
})

test_that("get_connection_description returns generic for unknown type", {
  desc <- get_connection_description("Unknown", "Activities")
  expect_equal(desc, "Related element")
})

test_that("get_connection_description returns generic for non-standard connection", {
  desc <- get_connection_description("Drivers", "Pressures")  # Not a standard connection
  expect_type(desc, "character")
  expect_true(grepl("affects", desc))
})

test_that("get_connection_description returns appropriate text for all types", {
  test_cases <- list(
    list(from = "Drivers", to = "Activities"),
    list(from = "Activities", to = "Pressures"),
    list(from = "Pressures", to = "Marine Processes & Functioning"),
    list(from = "Marine Processes & Functioning", to = "Ecosystem Services"),
    list(from = "Ecosystem Services", to = "Goods & Benefits"),
    list(from = "Responses", to = "Activities")
  )

  for (tc in test_cases) {
    desc <- get_connection_description(tc$from, tc$to)
    expect_type(desc, "character")
    expect_true(nchar(desc) > 5,
                info = paste("Empty description for", tc$from, "->", tc$to))
  }
})

# ==============================================================================
# Test: get_connection_examples
# ==============================================================================

test_that("get_connection_examples returns list", {
  examples <- get_connection_examples("Drivers", "Activities")
  expect_type(examples, "list")
})

test_that("get_connection_examples returns non-empty for valid connections", {
  examples <- get_connection_examples("Drivers", "Activities")
  expect_true(length(examples) > 0)
})

test_that("get_connection_examples returns empty for unknown type", {
  examples <- get_connection_examples("Unknown", "Activities")
  expect_equal(examples, list())
})

test_that("get_connection_examples returns empty for non-standard connection", {
  # Drivers -> Pressures is not a standard connection
  examples <- get_connection_examples("Drivers", "Pressures")
  expect_equal(examples, list())
})

test_that("get_connection_examples returns properly structured examples", {
  examples <- get_connection_examples("Activities", "Pressures")

  expect_true(length(examples) > 0)

  for (example in examples) {
    expect_true("from" %in% names(example))
    expect_true("to" %in% names(example))
    expect_true("polarity" %in% names(example))
    expect_true("strength" %in% names(example))
    expect_true("reasoning" %in% names(example))
  }
})

# ==============================================================================
# Test: DAPSIWRM Flow Validation
# ==============================================================================

test_that("DAPSIWRM flow is complete", {
  # Test the main flow: D -> A -> P -> S -> I -> W
  expect_true(validate_connection("Drivers", "Activities", strict = TRUE))
  expect_true(validate_connection("Activities", "Pressures", strict = TRUE))
  expect_true(validate_connection("Pressures", "Marine Processes & Functioning", strict = TRUE))
  expect_true(validate_connection("Marine Processes & Functioning", "Ecosystem Services", strict = TRUE))
  expect_true(validate_connection("Ecosystem Services", "Goods & Benefits", strict = TRUE))
})

test_that("Responses can affect multiple parts of the system", {
  expect_true(validate_connection("Responses", "Drivers", strict = TRUE))
  expect_true(validate_connection("Responses", "Activities", strict = TRUE))
  expect_true(validate_connection("Responses", "Pressures", strict = TRUE))
  expect_true(validate_connection("Responses", "Marine Processes & Functioning", strict = TRUE))
})

test_that("Goods & Benefits can trigger responses", {
  expect_true(validate_connection("Goods & Benefits", "Responses", strict = TRUE))
})

cat("\n", strrep("=", 70), "\n", sep = "")
cat("DAPSIWRM Connection Rules Tests Complete\n")
cat(strrep("=", 70), "\n")
