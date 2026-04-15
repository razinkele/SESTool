# Tests for remaining fix plan (TDD)
# These tests verify fixes for navigation, constants, session isolation, and sidebar ID

# ============================================================================
# CLUSTER 1: Navigation & Dashboard Rendering
# ============================================================================

test_that("event_bus_setup uses correct sidebar_menu ID", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "server", "event_bus_setup.R"))
  update_lines <- grep("updateTabItems", source_lines, value = TRUE)
  
  # All updateTabItems calls should use "sidebar_menu", not "sidebar"
  for (line in update_lines) {
    expect_true(
      grepl('"sidebar_menu"', line),
      info = paste("Found incorrect sidebar ID in:", trimws(line))
    )
  }
})

test_that("project_io navigates to dashboard after load", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "server", "project_io.R"))
  source_text <- paste(source_lines, collapse = "\n")
  
  # After project_data(loaded_data), there should be an updateTabItems call
  # to navigate to dashboard
  expect_true(
    grepl('updateTabItems.*"sidebar_menu".*"dashboard"', source_text),
    info = "project_io.R should navigate to dashboard after loading a project"
  )
})

test_that("dashboard value boxes have suspendWhenHidden = FALSE", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "server", "dashboard.R"))
  source_text <- paste(source_lines, collapse = "\n")
  
  expected_outputs <- c(
    "total_elements_box",
    "total_connections_box",
    "loops_detected_box",
    "completion_box"
  )
  
  for (output_id in expected_outputs) {
    expect_true(
      grepl(paste0('outputOptions.*"', output_id, '".*suspendWhenHidden.*FALSE'), source_text) ||
        grepl(paste0('"', output_id, '".*suspendWhenHidden\\s*=\\s*FALSE'), source_text),
      info = paste("Missing suspendWhenHidden=FALSE for:", output_id)
    )
  }
})

# ============================================================================
# CLUSTER 2: Hardcoded DAPSIWRM Lists → Use Constants
# ============================================================================

test_that("ml_feature_engineering uses DAPSIWRM_ELEMENTS constant", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "functions", "ml_feature_engineering.R"))
  
  # Should reference DAPSIWRM_ELEMENTS, not hardcode the list
  has_constant <- any(grepl("DAPSIWRM_ELEMENTS", source_lines))
  has_hardcoded <- any(grepl('DAPSIWRM_TYPES\\s*<-\\s*c\\(', source_lines))
  
  expect_true(has_constant, info = "Should use DAPSIWRM_ELEMENTS constant")
  expect_false(has_hardcoded, info = "Should not hardcode DAPSIWRM_TYPES with c()")
})

test_that("cld_visualization_module uses DAPSIWRM_ELEMENTS for choices", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "modules", "cld_visualization_module.R"))
  
  # Find the new_node_type selectInput choices area
  type_choice_lines <- grep("Drivers.*=.*Drivers", source_lines)
  
  # Should either use DAPSIWRM_ELEMENTS or not have hardcoded choices
  has_constant <- any(grepl("DAPSIWRM_ELEMENTS", source_lines[200:250]))
  
  expect_true(
    has_constant || length(type_choice_lines) == 0,
    info = "CLD viz module should use DAPSIWRM_ELEMENTS for element type choices"
  )
})

test_that("graphical_ses_network_builder uses DAPSIWRM_ELEMENTS", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "modules", "graphical_ses_network_builder.R"))
  
  # Check for all_dapsiwrm_types and ideal_chain references
  hardcoded_types <- grep('all_dapsiwrm_types\\s*<-\\s*c\\(', source_lines)
  hardcoded_chain <- grep('ideal_chain\\s*<-\\s*c\\(', source_lines)
  
  expect_equal(length(hardcoded_types), 0,
    info = "all_dapsiwrm_types should use DAPSIWRM_ELEMENTS, not c()")
  expect_equal(length(hardcoded_chain), 0,
    info = "ideal_chain should use DAPSIWRM_ELEMENTS, not c()")
})

test_that("ml_graph_features uses DAPSIWRM_ELEMENTS for type_mapping", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "functions", "ml_graph_features.R"))
  
  # The type_mapping in calculate_dapsiwrm_distance should derive from DAPSIWRM_ELEMENTS
  has_constant <- any(grepl("DAPSIWRM_ELEMENTS", source_lines[45:60]))
  
  expect_true(has_constant,
    info = "ml_graph_features should derive type_mapping from DAPSIWRM_ELEMENTS")
})

test_that("visnetwork_helpers derives levels from DAPSIWRM_ELEMENTS", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "functions", "visnetwork_helpers.R"))
  
  # get_dapsiwrm_level should reference DAPSIWRM_ELEMENTS
  func_start <- grep("^get_dapsiwrm_level\\s*<-\\s*function", source_lines)[1]
  if (!is.na(func_start)) {
    func_region <- source_lines[func_start:min(func_start + 15, length(source_lines))]
    has_constant <- any(grepl("DAPSIWRM_ELEMENTS", func_region))
    expect_true(has_constant,
      info = "get_dapsiwrm_level should derive levels from DAPSIWRM_ELEMENTS")
  }
})

# ============================================================================
# CLUSTER 3: Session Isolation
# ============================================================================

test_that("isa_export_helpers uses unique temp directory", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "functions", "isa_export_helpers.R"))
  
  # Should NOT use tempdir() (shared) for Kumu export
  kumu_func_start <- grep("create_kumu_export_zip", source_lines)[1]
  if (!is.na(kumu_func_start)) {
    func_region <- source_lines[kumu_func_start:min(kumu_func_start + 10, length(source_lines))]
    uses_shared_tempdir <- any(grepl("temp_dir\\s*<-\\s*tempdir\\(\\)", func_region))
    expect_false(uses_shared_tempdir,
      info = "create_kumu_export_zip should not use shared tempdir()")
  }
})

test_that("analysis_loops uses unique temp directory for export", {
  source_lines <- readLines(file.path(PROJECT_ROOT, "modules", "analysis_loops.R"))
  
  # Find the download handler content function area
  tempdir_lines <- grep("tmp_dir\\s*<-\\s*tempdir\\(\\)", source_lines)
  
  expect_equal(length(tempdir_lines), 0,
    info = "analysis_loops should not use shared tempdir() for loop diagram export")
})

# ============================================================================
# CLUSTER 5: KB Orphan Validation (test the main KB orphan fix)
# ============================================================================

test_that("baltic_open_coast has no orphan elements in main KB", {
  skip_if(!file.exists(file.path(PROJECT_ROOT, "data", "ses_knowledge_db.json")),
          "Main KB not found")
  
  kb <- jsonlite::fromJSON(
    file.path(PROJECT_ROOT, "data", "ses_knowledge_db.json"),
    simplifyVector = FALSE
  )
  
  ctx <- kb$contexts$baltic_open_coast
  skip_if(is.null(ctx), "baltic_open_coast context not found")
  
  # Collect all element names from DAPSIWRM categories
  cat_names <- c("drivers", "activities", "pressures", "states", "impacts", "welfare", "responses")
  all_elements <- character()
  for (cat_name in cat_names) {
    if (!is.null(ctx[[cat_name]])) {
      for (elem in ctx[[cat_name]]) {
        all_elements <- c(all_elements, elem$name)
      }
    }
  }
  
  # Collect all elements referenced in connections
  connected <- character()
  if (!is.null(ctx$connections) && length(ctx$connections) > 0) {
    for (conn in ctx$connections) {
      connected <- c(connected, conn$from, conn$to)
    }
  }
  connected <- unique(connected)
  
  orphans <- setdiff(all_elements, connected)
  expect_equal(length(orphans), 0,
    info = paste("Orphan elements found:", paste(orphans, collapse = ", ")))
})
