test_that("create_empty_project includes regional_sea and ecosystem_type in metadata", {
  skip_if_not(exists("create_empty_project", mode = "function"), "not available")
  proj <- create_empty_project("Test")
  expect_true("regional_sea" %in% names(proj$data$metadata),
              info = "Metadata must include regional_sea field")
  expect_true("ecosystem_type" %in% names(proj$data$metadata),
              info = "Metadata must include ecosystem_type field")
  expect_null(proj$data$metadata$regional_sea)
  expect_null(proj$data$metadata$ecosystem_type)
})

# ==============================================================================
# get_kb_context_for_report tests
# ==============================================================================

test_that("get_kb_context_for_report returns available=TRUE with description and top_elements for known context", {
  skip_if_not(exists("get_kb_context_for_report", mode = "function"), "not available")
  skip_if_not(exists("ses_knowledge_db_available", mode = "function") &&
                ses_knowledge_db_available(), "KB not loaded")

  result <- get_kb_context_for_report("baltic", "lagoon")

  expect_true(result$available,
              info = "Should find baltic/lagoon context in KB")
  expect_true(is.character(result$description) && nchar(result$description) > 0,
              info = "Description should be a non-empty string")
  expect_true(is.list(result$top_elements),
              info = "top_elements should be a list")
  expect_true(length(result$top_elements) > 0,
              info = "Should have at least one DAPSI(W)R(M) category with elements")
})

test_that("get_kb_context_for_report returns available=FALSE for unknown sea/habitat", {
  skip_if_not(exists("get_kb_context_for_report", mode = "function"), "not available")
  skip_if_not(exists("ses_knowledge_db_available", mode = "function") &&
                ses_knowledge_db_available(), "KB not loaded")

  result <- get_kb_context_for_report("nonexistent_sea", "nonexistent_habitat")

  expect_false(result$available,
               info = "Should return available=FALSE for unknown context")
  expect_true(is.character(result$description),
              info = "description should still be a character string")
  expect_true(is.list(result$top_elements),
              info = "top_elements should still be a list")
})

# ==============================================================================
# match_user_connections_to_kb tests
# ==============================================================================

test_that("match_user_connections_to_kb returns expected columns for known labels", {
  skip_if_not(exists("match_user_connections_to_kb", mode = "function"), "not available")
  skip_if_not(exists("ses_knowledge_db_available", mode = "function") &&
                ses_knowledge_db_available(), "KB not loaded")

  kb_conns <- get_context_connections("baltic", "lagoon")
  skip_if(length(kb_conns) == 0, "No KB connections available for baltic/lagoon")

  # Use first KB connection's from/to as user labels for a guaranteed match
  first_conn <- kb_conns[[1]]
  user_edges <- data.frame(
    from_label = first_conn$from,
    to_label   = first_conn$to,
    stringsAsFactors = FALSE
  )

  result <- match_user_connections_to_kb(user_edges, "baltic", "lagoon")

  expect_true(is.data.frame(result), info = "Result should be a data.frame")
  expected_cols <- c("user_from", "user_to", "kb_matched", "rationale",
                     "references", "temporal_lag", "reversibility", "kb_confidence")
  expect_true(all(expected_cols %in% names(result)),
              info = paste("Missing columns:", paste(setdiff(expected_cols, names(result)), collapse = ", ")))
  expect_equal(nrow(result), 1L, info = "Should have one row per user edge")
})

test_that("match_user_connections_to_kb returns kb_matched=FALSE for nonsense labels", {
  skip_if_not(exists("match_user_connections_to_kb", mode = "function"), "not available")
  skip_if_not(exists("ses_knowledge_db_available", mode = "function") &&
                ses_knowledge_db_available(), "KB not loaded")

  user_edges <- data.frame(
    from_label = "zxqwerty_nonsense_label_12345",
    to_label   = "zyxwvutsrqponm_nowhere_9876",
    stringsAsFactors = FALSE
  )

  result <- match_user_connections_to_kb(user_edges, "baltic", "lagoon")

  expect_true(is.data.frame(result), info = "Result should be a data.frame")
  expect_equal(nrow(result), 1L, info = "Should have one row")
  expect_false(result$kb_matched[1],
               info = "Nonsense labels should not match any KB connection")
})

# ==============================================================================
# get_governance_context tests
# ==============================================================================

test_that("get_governance_context returns available=TRUE with frameworks for known sea", {
  skip_if_not(exists("get_governance_context", mode = "function"), "not available")
  skip_if_not(exists("get_countries_for_sea", mode = "function"), "not available")

  countries <- get_countries_for_sea("baltic")
  skip_if(length(countries) == 0, "No country data for baltic sea")

  result <- get_governance_context("baltic")

  expect_true(result$available,
              info = "Should find governance context for baltic")
  expect_true(is.character(result$frameworks),
              info = "frameworks should be a character vector")
  expect_true(is.list(result$country_policies),
              info = "country_policies should be a list")
})

test_that("get_governance_context returns available=FALSE with empty frameworks for unknown sea", {
  skip_if_not(exists("get_governance_context", mode = "function"), "not available")

  result <- get_governance_context("nonexistent_sea_xyz")

  expect_false(result$available,
               info = "Should return available=FALSE for unknown sea")
  expect_equal(length(result$frameworks), 0L,
               info = "frameworks should be empty for unknown sea")
  expect_true(is.list(result$country_policies),
              info = "country_policies should still be a list")
})

# ==============================================================================
# format_kb_section_for_report tests
# ==============================================================================

test_that("format_kb_section_for_report returns non-empty markdown with key text for valid inputs", {
  skip_if_not(exists("format_kb_section_for_report", mode = "function"), "not available")

  kb_context <- list(
    available    = TRUE,
    description  = "Test Baltic lagoon ecosystem description.",
    top_elements = list(
      drivers    = c("Agricultural runoff", "Overfishing"),
      pressures  = c("Eutrophication", "Habitat loss")
    )
  )

  matched <- data.frame(
    user_from     = "Agricultural runoff",
    user_to       = "Eutrophication",
    kb_matched    = TRUE,
    rationale     = "Nutrient loading from agriculture drives eutrophication.",
    references    = "Smith et al. 2020",
    temporal_lag  = "months",
    reversibility = "partially reversible",
    kb_confidence = 0.9,
    stringsAsFactors = FALSE
  )

  governance <- list(
    available        = TRUE,
    frameworks       = c("HELCOM", "EU Water Framework Directive"),
    country_policies = list(LT = "EU member state")
  )

  result <- format_kb_section_for_report(kb_context, matched, governance, i18n = NULL)

  expect_true(is.character(result), info = "Result should be a character string")
  expect_true(nchar(result) > 0, info = "Result should be non-empty for valid inputs")
  expect_true(grepl("description", result, ignore.case = TRUE) ||
                grepl("Baltic lagoon", result, ignore.case = TRUE) ||
                grepl("Test Baltic", result),
              info = "Result should contain site description text")
  expect_true(grepl("Agricultural runoff", result),
              info = "Result should contain element names")
  expect_true(grepl("HELCOM", result) || grepl("Governance", result, ignore.case = TRUE),
              info = "Result should contain governance framework")
})

test_that("format_kb_section_for_report handles NULL/empty inputs without error", {
  skip_if_not(exists("format_kb_section_for_report", mode = "function"), "not available")

  result_null <- format_kb_section_for_report(NULL, NULL, NULL)
  expect_true(is.character(result_null),
              info = "Should return character string for NULL inputs")

  empty_kb <- list(available = FALSE, description = "", top_elements = list())
  empty_gov <- list(available = FALSE, frameworks = character(0), country_policies = list())
  empty_conn <- data.frame(
    user_from = character(0), user_to = character(0),
    kb_matched = logical(0), rationale = character(0),
    references = character(0), temporal_lag = character(0),
    reversibility = character(0), kb_confidence = numeric(0),
    stringsAsFactors = FALSE
  )

  result_empty <- format_kb_section_for_report(empty_kb, empty_conn, empty_gov)
  expect_true(is.character(result_empty),
              info = "Should return character string for empty/unavailable inputs")
})

test_that("generate_report_content includes regional context when metadata set", {
  skip_if_not(exists("generate_report_content", mode = "function"), "not available")
  skip_if_not(exists("ses_knowledge_db_available", mode = "function") && ses_knowledge_db_available(), "KB not loaded")
  proj <- create_empty_project("Test Project")
  proj$data$metadata$regional_sea <- "baltic"
  proj$data$metadata$ecosystem_type <- "lagoon"
  proj$data$isa_data <- list(
    drivers = data.frame(ID = "D1", Name = "Food demand", stringsAsFactors = FALSE),
    activities = data.frame(ID = "A1", Name = "Fishing", stringsAsFactors = FALSE)
  )
  content <- generate_report_content(proj, "full")
  expect_true(grepl("Regional Context", content),
              info = "Report must include Regional Context section when metadata is set")
})

test_that("generate_report_content works without regional metadata", {
  skip_if_not(exists("generate_report_content", mode = "function"), "not available")
  proj <- create_empty_project("Test Project")
  content <- generate_report_content(proj, "executive")
  expect_true(is.character(content))
  expect_true(nchar(content) > 0)
})

test_that("generate_strategic_recommendations does not crash with regional metadata", {
  skip_if_not(exists("generate_strategic_recommendations", mode = "function"), "not available")
  data <- create_empty_project("Test")
  data$data$metadata$regional_sea <- "baltic"
  data$data$metadata$ecosystem_type <- "lagoon"
  top_lev <- data.frame(label = "Fishing", leverage_score = 0.9,
                         in_degree = 3, out_degree = 5, stringsAsFactors = FALSE)
  recs <- generate_strategic_recommendations(data, top_lev, NULL, NULL, NULL, NULL)
  expect_true(is.character(recs))
})
