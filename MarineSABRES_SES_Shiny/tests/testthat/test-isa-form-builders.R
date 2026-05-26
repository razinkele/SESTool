# tests/testthat/test-isa-form-builders.R
# Behavior contracts for ISA form-builder helpers in functions/isa_form_builders.R.
#
# Regression tests pinned to the 2026-05-20 "Save Exercise" / DataTables ajax-error
# incident: pressing Save Exercise 1 (G&B) produced a DT ajax-error warning, the
# G&B table glitched, and Next/Back navigation became unresponsive. Root-cause
# investigation traced this to two defects:
#
#   1. validate_and_collect_gb() builds its row data.frame with
#      `Importance = importance_val` / `Trend = trend_val` taken straight from
#      Shiny input without null-guarding. When the gb_importance_X /
#      gb_trend_X selectInputs have not yet reported their value to the
#      server (race between insertUI render and a quick Save click), those
#      reads return NULL, and `data.frame(..., x = NULL)` silently drops the
#      column. The returned df then has 5 columns instead of the 7-column
#      schema isa_data$goods_benefits was initialized with at
#      modules/isa_data_entry_module.R:58-67. Assigning the 5-column df
#      changes the schema of the reactive, and the next DT AJAX poll fails
#      (DT's server-side processing assumes column stability).
#
#   2. isa_fields_gb() defines the importance / trend fields as
#      selectInputs without explicit `selected =` defaults. Shiny normally
#      defaults to the first choice on the client side, but for a brief
#      tick after insertUI the server-side `input[[...]]` returns NULL,
#      reopening defect 1's race window.
#
# Both tests below MUST FAIL on the unpatched code. The fixes live in
# functions/isa_form_builders.R: (a) null-coalesce Importance/Trend with
# `%||% ""` at the row-construction site, (b) add explicit `selected =`
# defaults to every select-type field in isa_fields_gb (and parallel
# isa_fields_* helpers — out of scope for this test file).

source_for_test(c(
  "constants.R",
  "functions/data_structure.R",
  "functions/module_validation_helpers.R",
  "functions/matrix_from_linked.R",
  "functions/isa_form_builders.R"
))

test_that("validate_and_collect_gb preserves all 7 columns when importance/trend inputs are NULL", {
  # Simulate a Shiny input where the user filled in the text/select fields
  # the validator owns, but the importance/trend selectInputs are still
  # NULL — exactly the race condition that triggers the DT ajax-error bug.
  fake_input <- list(
    gb_name_1        = "Fish catch",
    gb_type_1        = "Provisioning",
    gb_desc_1        = "Wild-caught fisheries",
    gb_stakeholder_1 = "Fishers"
    # gb_importance_1 and gb_trend_1 deliberately absent → NULL
  )
  fake_i18n <- list(t = function(key) key)

  result <- validate_and_collect_gb(
    input   = fake_input,
    counter = 1L,
    session = NULL,
    i18n    = fake_i18n
  )

  # Validator should not error and should still classify the row as valid:
  # name/type/desc/stakeholder were all provided correctly.
  expect_true(is.list(result))
  expect_equal(result$n_rows, 1L)
  expect_length(result$errors, 0)

  # The returned df MUST match the 7-column schema initialised at
  # modules/isa_data_entry_module.R:58-67. Dropping columns here corrupts
  # the downstream renderDT and produces the DataTables ajax error.
  expect_true(is.data.frame(result$df))
  expect_equal(nrow(result$df), 1L)
  expect_equal(
    ncol(result$df),
    7L,
    info = "5-column df indicates Importance/Trend were dropped because data.frame() silently drops NULL columns"
  )
  expect_setequal(
    colnames(result$df),
    c("ID", "Name", "Type", "Description", "Stakeholder", "Importance", "Trend")
  )

  # Importance/Trend must be present as columns even when input was NULL —
  # the value can legitimately be "" (treated as 'unspecified' downstream)
  # but the column itself must exist so the DT schema stays stable.
  expect_true("Importance" %in% colnames(result$df))
  expect_true("Trend"      %in% colnames(result$df))
})

test_that("generate_element_id with scalar n returns a single ID, not a sequence", {
  # Regression test for 2026-05-20 duplicate-rows bug. The function had:
  #   if (length(n) == 1 && n >= 1) n <- seq_len(n)
  # which silently expanded scalar n=2 into c(1,2), producing
  # c("GB001","GB002"). When fed into data.frame() alongside scalar Name,
  # R recycled Name to length 2, producing duplicate rows per Add+Save.
  source_for_test(c("constants.R", "functions/data_structure.R"))

  expect_equal(generate_element_id("GB", 1), "GB001")
  expect_equal(generate_element_id("GB", 2), "GB002",
               info = "scalar n=2 must return ONE ID 'GB002', not c('GB001','GB002')")
  expect_equal(generate_element_id("GB", 5), "GB005")
  expect_length(generate_element_id("GB", 7), 1)

  # Bulk-generation use case (used by ai_isa/data_persistence.R:94) must
  # still work: passing a vector produces a vector of the same length.
  expect_equal(generate_element_id("GB", c(1, 2, 3)),
               c("GB001", "GB002", "GB003"))
  expect_length(generate_element_id("GB", seq_len(5)), 5)
})

test_that("validate_and_collect_es preserves all 7 columns when linkedgb/confidence inputs are NULL", {
  # Same bug class as 2026-05-20 G&B incident. validate_and_collect_es at
  # functions/isa_form_builders.R:502,504 writes LinkedGB and Confidence
  # directly from input without null-coalesce. When the ES selectInputs
  # have not yet reported back, the resulting data.frame() crashes with
  # "arguments imply differing number of rows: 1, 0" — same DT ajax error
  # the user reported for GB, just on the ES tab.
  fake_input <- list(
    es_name_1      = "Fish provisioning",
    es_type_1      = "Provisioning",
    es_desc_1      = "Wild-caught fish biomass",
    es_mechanism_1 = "Stock dynamics"
    # es_linkedgb_1 and es_confidence_1 deliberately absent → NULL
  )
  fake_i18n <- list(t = function(key) key)

  result <- validate_and_collect_es(
    input   = fake_input,
    counter = 1L,
    session = NULL,
    i18n    = fake_i18n
  )

  expect_true(is.list(result))
  expect_equal(result$n_rows, 1L)
  expect_length(result$errors, 0)
  expect_true(is.data.frame(result$df))
  expect_equal(nrow(result$df), 1L)
  expect_equal(
    ncol(result$df), 7L,
    info = "ES df must preserve 7-column schema even when LinkedGB/Confidence inputs are NULL"
  )
  expect_setequal(
    colnames(result$df),
    c("ID", "Name", "Type", "Description", "LinkedGB", "Mechanism", "Confidence")
  )
  expect_true("LinkedGB"   %in% colnames(result$df))
  expect_true("Confidence" %in% colnames(result$df))
})

test_that("isa_fields_es declares explicit selected defaults for every select-type field", {
  fake_i18n <- list(t = function(key) key)
  # isa_fields_es requires linked_choices (dynamic GB list)
  fields <- isa_fields_es(fake_i18n, linked_choices = c("", "GB001: Wild fish"))
  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  expect_gt(length(select_fields), 0L)
  for (f in select_fields) {
    expect_true("selected" %in% names(f),
      info = sprintf("isa_fields_es field '%s' must declare 'selected'", f$id))
    expect_true(!is.null(f$selected),
      info = sprintf("isa_fields_es field '%s' selected must be non-null", f$id))
    expect_true(f$selected %in% f$choices,
      info = sprintf("isa_fields_es field '%s' selected='%s' must be in choices", f$id, f$selected))
  }
})

test_that("isa_fields_mpf declares explicit selected defaults for every select-type field", {
  fake_i18n <- list(t = function(key) key)
  fields <- isa_fields_mpf(fake_i18n, linked_choices = c("", "ES001: Fish prov"))
  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  expect_gt(length(select_fields), 0L)
  for (f in select_fields) {
    expect_true("selected" %in% names(f),
      info = sprintf("isa_fields_mpf field '%s' must declare 'selected'", f$id))
    expect_true(!is.null(f$selected),
      info = sprintf("isa_fields_mpf field '%s' selected must be non-null", f$id))
    expect_true(f$selected %in% f$choices,
      info = sprintf("isa_fields_mpf field '%s' selected='%s' must be in choices", f$id, f$selected))
  }
})

test_that("isa_fields_p declares explicit selected defaults for every select-type field", {
  fake_i18n <- list(t = function(key) key)
  fields <- isa_fields_p(fake_i18n, linked_choices = c("", "MPF001: Stock"))
  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  expect_gt(length(select_fields), 0L)
  for (f in select_fields) {
    expect_true("selected" %in% names(f),
      info = sprintf("isa_fields_p field '%s' must declare 'selected'", f$id))
    expect_true(!is.null(f$selected),
      info = sprintf("isa_fields_p field '%s' selected must be non-null", f$id))
    expect_true(f$selected %in% f$choices,
      info = sprintf("isa_fields_p field '%s' selected='%s' must be in choices", f$id, f$selected))
  }
})

test_that("isa_fields_a declares explicit selected defaults for every select-type field", {
  fake_i18n <- list(t = function(key) key)
  fields <- isa_fields_a(fake_i18n, linked_choices = c("", "P001: Overfishing"))
  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  expect_gt(length(select_fields), 0L)
  for (f in select_fields) {
    expect_true("selected" %in% names(f),
      info = sprintf("isa_fields_a field '%s' must declare 'selected'", f$id))
    expect_true(!is.null(f$selected),
      info = sprintf("isa_fields_a field '%s' selected must be non-null", f$id))
    expect_true(f$selected %in% f$choices,
      info = sprintf("isa_fields_a field '%s' selected='%s' must be in choices", f$id, f$selected))
  }
})

test_that("isa_fields_d declares explicit selected defaults for every select-type field", {
  fake_i18n <- list(t = function(key) key)
  fields <- isa_fields_d(fake_i18n, linked_choices = c("", "A001: Fishing"))
  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  expect_gt(length(select_fields), 0L)
  for (f in select_fields) {
    expect_true("selected" %in% names(f),
      info = sprintf("isa_fields_d field '%s' must declare 'selected'", f$id))
    expect_true(!is.null(f$selected),
      info = sprintf("isa_fields_d field '%s' selected must be non-null", f$id))
    expect_true(f$selected %in% f$choices,
      info = sprintf("isa_fields_d field '%s' selected='%s' must be in choices", f$id, f$selected))
  }
})

test_that("build_entry_panel_ui forwards selected= to selectInput so the rendered <option> is marked selected", {
  # Without this, the explicit `selected = ...` defaults in isa_fields_*
  # are inert — Shiny renders the first choice as default. That means a
  # user filling out an entry sees "High"/"Increasing" instead of the
  # intended "Medium"/"Unknown" UX defaults, AND the race-window
  # protection (server reads NULL before client reports) only works
  # because of the null-coalesce in validate_and_collect_*, not because
  # the form pre-fills a valid default.
  fake_i18n <- list(t = function(key) key)
  fake_ns <- function(x) paste0("ns-", x)
  fields <- isa_fields_gb(fake_i18n)
  panel <- build_entry_panel_ui(
    ns = fake_ns, prefix = "gb", current_id = 1L,
    fields = fields, i18n = fake_i18n
  )
  html <- as.character(panel)

  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  for (f in select_fields) {
    pat <- sprintf(
      '<option[^>]*value="%s"[^>]*selected[^>]*>',
      f$selected
    )
    expect_match(
      html, pat, perl = TRUE,
      info = sprintf(
        "build_field must pass selected='%s' for field '%s' so the rendered <option> has the `selected` HTML attribute",
        f$selected, f$id
      )
    )
  }
})

test_that("save_ex0/1/2a/2b/3/4/5/6 observers are wrapped in tryCatch + format_user_error", {
  # CLAUDE.md mandates tryCatch + format_user_error(context_key=...) for all
  # user-visible operations. save_ex1 was wrapped after the 2026-05-20 G&B
  # incident; save_ex2a..5 were wrapped in the same sweep. save_ex0
  # (Complexity) and save_ex6 (Closing Loop) were missed — both still
  # silently die on any unexpected throw (matrix construction, validate_all
  # internal errors). Same incident shape: uncaught throw corrupts the
  # websocket state. Closed during Phase C v2 follow-up 2026-05-22.
  #
  # Per-observer check via block extraction: locate the input$<name> line,
  # take all lines up to (but not including) the next observeEvent, and
  # assert that slice contains tryCatch + format_user_error. Avoids the
  # greedy-regex cross-observer match flaw that hid this gap originally.
  td <- getwd()
  root <- if (basename(td) == "testthat") dirname(dirname(td)) else td
  src <- readLines(file.path(root, "modules", "isa_data_entry_module.R"), warn = FALSE)

  observer_starts <- grep("observeEvent\\(input\\$save_ex[0-9a-z]+", src)

  extract_block <- function(name) {
    start_idx <- grep(sprintf("observeEvent\\(input\\$%s\\b", name), src, perl = TRUE)[1]
    if (is.na(start_idx)) return(NULL)
    next_starts <- observer_starts[observer_starts > start_idx]
    end_idx <- if (length(next_starts) > 0) next_starts[1] - 1 else length(src)
    paste(src[start_idx:end_idx], collapse = "\n")
  }

  for (ex in c("save_ex0", "save_ex1", "save_ex2a", "save_ex2b", "save_ex3", "save_ex4", "save_ex5", "save_ex6")) {
    block <- extract_block(ex)
    expect_false(is.null(block),
      info = sprintf("Observer %s must exist in modules/isa_data_entry_module.R", ex))
    expect_true(
      grepl("tryCatch", block, fixed = TRUE) && grepl("format_user_error", block, fixed = TRUE),
      info = sprintf(
        "Observer %s block must contain tryCatch AND format_user_error(context_key=...). Block first 200 chars: %s",
        ex, substr(block, 1, 200)
      )
    )
  }
})

test_that("isa_fields_gb declares explicit selected defaults for every select-type field", {
  fake_i18n <- list(t = function(key) key)
  fields <- isa_fields_gb(fake_i18n)

  select_fields <- Filter(function(f) identical(f$type, "select"), fields)
  expect_gt(
    length(select_fields), 0L,
    label = "isa_fields_gb should define at least one select-type field"
  )

  for (f in select_fields) {
    expect_true(
      "selected" %in% names(f),
      info = sprintf(
        "Select field '%s' must declare 'selected' to close the Shiny race window where input[[...]] reads NULL before the client reports its initial value",
        f$id
      )
    )
    expect_true(
      !is.null(f$selected) && nzchar(f$selected),
      info = sprintf("Select field '%s' must have a non-empty 'selected' default", f$id)
    )
    expect_true(
      f$selected %in% f$choices,
      info = sprintf(
        "Select field '%s' default '%s' must be one of its declared choices (%s)",
        f$id, f$selected, paste(f$choices, collapse = ", ")
      )
    )
  }
})

test_that("build_field renders type='select_multi' as selectizeInput with multiple=TRUE", {
  fake_i18n <- list(t = function(key) key)
  fake_ns <- function(x) paste0("test-", x)
  fields <- list(
    list(id = "name", type = "text", label = "Name", width = 3),
    list(id = "type", type = "text", label = "Type", width = 3),
    list(id = "desc", type = "text", label = "Description", width = 6),
    list(
      id = "linkedgb", type = "select_multi",
      label = "Linked GBs", width = 3,
      choices = c("GB001", "GB002", "GB003"),
      selected = character(0)
    )
  )
  ui <- build_entry_panel_ui(
    ns = fake_ns, prefix = "es", current_id = 1,
    fields = fields, i18n = fake_i18n
  )
  html <- as.character(ui)
  expect_match(html, "multiple=\"multiple\"",
               info = "select_multi must render as <select multiple>")
  expect_match(html, "test-es_linkedgb_1",
               info = "input id must follow prefix_id_counter pattern")
})

test_that("All 5 isa_fields_* builders use type='select_multi' for their linked* field with empty default", {
  fake_i18n <- list(t = function(key) key)
  cases <- list(
    list(fn = isa_fields_es,  arg = c("GB001","GB002"), id = "linkedgb"),
    list(fn = isa_fields_mpf, arg = c("ES001","ES002"), id = "linkedes"),
    list(fn = isa_fields_p,   arg = c("MPF001","MPF002"), id = "linkedmpf"),
    list(fn = isa_fields_a,   arg = c("P001","P002"),   id = "linkedp"),
    list(fn = isa_fields_d,   arg = c("A001","A002"),   id = "linkeda")
  )
  for (case in cases) {
    fields <- case$fn(i18n = fake_i18n, linked_choices = case$arg)
    linked <- Filter(function(f) identical(f$id, case$id), fields)[[1]]
    expect_identical(linked$type, "select_multi",
      info = sprintf("Field '%s' must be type='select_multi'", case$id))
    expect_identical(linked$selected, character(0),
      info = sprintf("Field '%s' default must be empty character(0)", case$id))
  }
})

# Task 4 tests: serialize_linked for multi-value LinkedGB
test_that("validate_and_collect_es serializes multi-value LinkedGB via serialize_linked", {
  fake_i18n <- list(t = function(key) key)
  fake_input <- list(
    es_name_1 = "Fish production", es_type_1 = "Provisioning",
    es_desc_1 = "Edible biomass output",
    es_linkedgb_1 = c("GB001", "GB003"),
    es_mechanism_1 = "Catch", es_confidence_1 = "High"
  )
  result <- validate_and_collect_es(fake_input, 1L, NULL, fake_i18n)
  expect_equal(result$n_rows, 1L)
  expect_equal(result$df$LinkedGB[1], "GB001|GB003",
    info = "multi-value LinkedGB must be serialized as 'GB001|GB003'")
})

test_that("validate_and_collect_es handles single-value LinkedGB (backward compat)", {
  fake_i18n <- list(t = function(key) key)
  fake_input <- list(
    es_name_1 = "Fish", es_type_1 = "Provisioning", es_desc_1 = "",
    es_linkedgb_1 = "GB001",
    es_mechanism_1 = "", es_confidence_1 = "High"
  )
  result <- validate_and_collect_es(fake_input, 1L, NULL, fake_i18n)
  expect_equal(result$df$LinkedGB[1], "GB001",
    info = "single-value LinkedGB must remain as 'GB001'")
})

test_that("validate_and_collect_es filters empty strings (no trailing pipe)", {
  fake_i18n <- list(t = function(key) key)
  fake_input <- list(
    es_name_1 = "Fish", es_type_1 = "Provisioning", es_desc_1 = "",
    es_linkedgb_1 = c("GB001", "", "GB003"),
    es_mechanism_1 = "", es_confidence_1 = "High"
  )
  result <- validate_and_collect_es(fake_input, 1L, NULL, fake_i18n)
  expect_equal(result$df$LinkedGB[1], "GB001|GB003",
    info = "empty strings in LinkedGB vector must be filtered out")
})

test_that("validate_and_collect_{mpf,p,a,d} all use serialize_linked for their Linked* column", {
  source_for_test(c("constants.R", "functions/matrix_from_linked.R",
                    "functions/isa_form_builders.R"))
  fake_i18n <- list(t = function(key) key)
  cases <- list(
    list(fn = validate_and_collect_mpf, inputs = list(
      mpf_name_1 = "Primary production", mpf_type_1 = "Biological",
      mpf_desc_1 = "", mpf_linkedes_1 = c("ES001","ES002"),
      mpf_mechanism_1 = "", mpf_spatial_1 = "Coastal"
    ), col = "LinkedES"),
    list(fn = validate_and_collect_p, inputs = list(
      p_name_1 = "Nutrient enrichment", p_type_1 = "Chemical",
      p_desc_1 = "", p_linkedmpf_1 = c("MPF001","MPF002"),
      p_intensity_1 = "High", p_spatial_1 = "Coastal", p_temporal_1 = "Year-round"
    ), col = "LinkedMPF"),
    list(fn = validate_and_collect_a, inputs = list(
      a_name_1 = "Commercial fishing", a_sector_1 = "Fisheries",
      a_desc_1 = "", a_linkedp_1 = c("P001","P002"),
      a_scale_1 = "Regional", a_frequency_1 = "Continuous"
    ), col = "LinkedP"),
    list(fn = validate_and_collect_d, inputs = list(
      d_name_1 = "Economic growth", d_type_1 = "Economic",
      d_desc_1 = "", d_linkeda_1 = c("A001","A002"),
      d_trend_1 = "Increasing", d_control_1 = "Low"
    ), col = "LinkedA")
  )
  for (case in cases) {
    result <- case$fn(case$inputs, 1L, NULL, fake_i18n)
    expect_equal(result$n_rows, 1L,
                 info = sprintf("Function should produce 1 row for %s", case$col))
    linked_input_name <- grep("_linked", names(case$inputs), value = TRUE)[1]
    expected_val <- paste(case$inputs[[linked_input_name]], collapse = "|")
    expect_equal(result$df[[case$col]][1], expected_val,
                 info = sprintf("%s should be '|'-joined", case$col))
  }
})
