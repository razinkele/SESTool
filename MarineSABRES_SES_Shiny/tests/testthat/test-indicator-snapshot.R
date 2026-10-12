# tests/testthat/test-indicator-snapshot.R
# WS-4: element indicator columns, registry snapshot, drift detection, module wiring.
library(testthat)
source_for_test(c("functions/isa_form_builders.R", "functions/ui_components.R",
                  "functions/indicator_registry.R", "functions/indicator_snapshot.R"))

gb_cols <- c("Name", "Type", "Description", "Stakeholder", "Importance", "Trend")

test_that("indicator columns of a carried-over (loaded) row survive an exercise save", {
  existing <- data.frame(ID = "GB001", Name = "Fish catch", Type = "Provisioning", Description = "",
                         Stakeholder = "", Importance = "High", Trend = "Stable",
                         Indicator = "Landings", Indicator_Unit = "t", Data_Source = "ISTAT",
                         Registry_Id = "", Registry_Version = "", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(existing, data.frame(), "GB001", character(0),
                                       c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(out$Indicator, "Landings")
  expect_equal(out$Indicator_Unit, "t")
  expect_equal(out$Data_Source, "ISTAT")
})

test_that("legacy lowercase indicator columns merge into the canonical ones (no duplicates)", {
  legacy <- data.frame(id = "GB001", name = "Fish catch", type = "Provisioning", indicator = "Landings",
                       indicator_unit = "t", data_source = "ISTAT", stringsAsFactors = FALSE)
  out <- merge_collected_with_existing(legacy, data.frame(), "GB001", character(0),
                                       c(gb_cols, ISA_INDICATOR_COLUMNS))
  expect_equal(sum(tolower(names(out)) == "indicator"), 1L)
  expect_equal(out$Indicator, "Landings")
  expect_equal(out$Registry_Id, "")
})

test_that("indicator_col reads case-insensitively and blanks NA", {
  df <- data.frame(registry_id = c("F_01", NA), stringsAsFactors = FALSE)
  expect_equal(indicator_col(df, "Registry_Id"), c("F_01", ""))
  expect_equal(indicator_col(df, "Indicator"), c("", ""))
  expect_equal(indicator_col(NULL, "Indicator"), character(0))
})

test_that("JSON normalisation does not add a second indicator column next to Indicator", {
  pd <- list(data = list(isa_data = list(goods_benefits = data.frame(
    ID = "GB001", Name = "Fish catch", Indicator = "Landings", stringsAsFactors = FALSE))))
  out <- normalize_json_project_data(pd)
  nm <- names(out$data$isa_data$goods_benefits)
  expect_equal(sum(tolower(nm) == "indicator"), 1L)
})

test_that("ragged list-of-lists rows (NA fields omitted by toJSON) do not drop the category", {
  # auto_save_module.R serialised without na = "null", so a row with an empty
  # Indicator omits the key. Before WS-4 this made do.call(rbind, ...) error at
  # data_structure.R:882 and the whole category became NULL (verified 2026-10-11).
  df <- data.frame(ID = c("D1", "D2"), Name = c("a", "b"), Indicator = c("x", NA),
                   stringsAsFactors = FALSE)
  js <- jsonlite::toJSON(list(data = list(isa_data = list(drivers = df))),
                         auto_unbox = TRUE, null = "null")          # no na = "null"
  out <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = FALSE))
  d <- out$data$isa_data$drivers
  expect_equal(nrow(d), 2L)
  expect_equal(indicator_col(d, "Indicator"), c("x", ""))
})

# ---- Task 4: picker + snapshot ---------------------------------------------
fake_input <- function(...) list(...)

test_that("the entry panel renders a third row with the indicator fields, picker and badge slot for element prefixes", {
  ui <- as.character(build_entry_panel_ui(shiny::NS("m"), "p", "P001",
                     isa_fields_p(make_test_i18n(), c("")), make_test_i18n()))
  for (id in c("m-p_indicator_P001", "m-p_indunit_P001", "m-p_datasource_P001", "m-p_registry_P001",
               "m-p_regbadge_P001"))
    expect_match(ui, id, fixed = TRUE)
  # Non-element prefix with a real field list (an empty list errors in existing code at
  # isa_form_builders.R:59, unrelated to WS-4): no third row.
  ui_z <- as.character(build_entry_panel_ui(shiny::NS("m"), "zz", "Z1",
                       isa_fields_gb(make_test_i18n()), make_test_i18n()))
  expect_false(grepl("zz_registry_Z1", ui_z, fixed = TRUE))
})

test_that("collect_indicator_inputs reads the four inputs for the given ids", {
  inp <- fake_input(p_indicator_P001 = "Anchorages", p_indunit_P001 = "n", p_datasource_P001 = "EMODnet",
                    p_registry_P001 = "TUS_A1_POTENTIAL_ANCHORAGES")
  out <- collect_indicator_inputs(inp, "p", c("P001", "P002"))
  expect_equal(nrow(out), 2L)
  expect_equal(out$Registry_Id, c("TUS_A1_POTENTIAL_ANCHORAGES", ""))
  expect_equal(out$Indicator_Unit, c("n", ""))
})

test_that("picking a registry entry fills blank fields and stamps the revision", {
  df <- data.frame(ID = "A001", Name = "Fishing", Indicator = "", Indicator_Unit = "", Data_Source = "",
                   Registry_Id = "F_01", Registry_Version = "", stringsAsFactors = FALSE)
  out <- apply_registry_snapshot(df, previous = NULL)
  f1 <- get_indicator("F_01")
  expect_equal(out$Indicator, f1$name)
  expect_equal(out$Indicator_Unit, f1$unit)
  expect_equal(out$Data_Source, paste(unlist(f1$data_sources), collapse = "; "))
  expect_equal(out$Registry_Version, as.character(f1$revision))
})

test_that("user edits after picking survive re-save", {
  df <- data.frame(ID = "A001", Name = "Fishing", Indicator = "My share", Indicator_Unit = "ratio",
                   Data_Source = "", Registry_Id = "F_01", Registry_Version = "", stringsAsFactors = FALSE)
  out1 <- apply_registry_snapshot(df, previous = NULL)
  expect_equal(out1$Indicator, "My share")
  expect_equal(out1$Indicator_Unit, "ratio")
  out2 <- apply_registry_snapshot(out1, previous = out1)
  expect_equal(out2$Indicator_Unit, "ratio")
})

test_that("an existing snapshot keeps its revision on re-save; clearing the pick clears the version", {
  prev <- data.frame(ID = "A001", Registry_Id = "F_01", Registry_Version = "0", stringsAsFactors = FALSE)
  df <- data.frame(ID = "A001", Indicator = "x", Indicator_Unit = "", Data_Source = "",
                   Registry_Id = "F_01", Registry_Version = "", stringsAsFactors = FALSE)
  expect_equal(apply_registry_snapshot(df, previous = prev)$Registry_Version, "0")   # older stays detectable
  df$Registry_Id <- ""
  expect_equal(apply_registry_snapshot(df, previous = prev)$Registry_Version, "")
})

test_that("the badge beside the picker shows the selected entry's provenance", {
  i18n <- make_test_i18n()
  pos <- as.character(indicator_provenance_ui("TUS_POS_SEAGRASS_SHOOT_DENSITY", i18n))
  expect_match(pos, "modules.wp5_mechanisms.provenance.wp5_derived", fixed = TRUE)
  expect_match(pos, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)   # toolbox classification
  f1 <- as.character(indicator_provenance_ui("F_01", i18n))
  expect_false(grepl("wp5_derived", f1, fixed = TRUE))
  expect_match(f1, "modules.wp5_mechanisms.provenance.toolbox_extension", fixed = TRUE)
  stub <- as.character(indicator_provenance_ui("C_02", i18n))
  expect_match(stub, "modules.indicator_registry.stub_marker", fixed = TRUE)
  expect_match(stub, "modules.wp5_mechanisms.provenance.provisional", fixed = TRUE)
  expect_null(indicator_provenance_ui("", i18n))
})

test_that("project_has_registry_snapshot looks at the six element frames only", {
  expect_false(project_has_registry_snapshot(list()))
  expect_false(project_has_registry_snapshot(list(activities = data.frame(ID = "A001", Registry_Id = ""))))
  expect_true(project_has_registry_snapshot(list(activities = data.frame(ID = "A001", registry_id = "F_01"))))
  expect_false(project_has_registry_snapshot(list(responses = data.frame(ID = "R001", Registry_Id = "F_01"))))
})

test_that("merge_saved runs the snapshot for element prefixes only and the save path stamps the version (module source)", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "isa_data_entry_module.R"), warn = FALSE), collapse = "\n")
  expect_match(s, "c(col_names, ISA_INDICATOR_COLUMNS)", fixed = TRUE)
  expect_match(s, "prefix %in% names(ISA_PREFIX_ELEMENT_KEY)", fixed = TRUE)
  expect_match(s, "apply_registry_snapshot(", fixed = TRUE)
  expect_match(s, "collect_indicator_inputs(input, prefix", fixed = TRUE)
  expect_match(s, "stamp_min_app_version(pd, WP5_INDICATOR_MIN_APP_VERSION)", fixed = TRUE)
  expect_equal(lengths(regmatches(s, gregexpr("register_indicator_picker_observer(input, output, session, ",
                                              s, fixed = TRUE))), 6L)
})

# ---- Task 4: module behaviour (testServer, real server) ----------------------
source_for_test(c("modules/isa_data_entry_module.R", "functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/project_transactions.R"))
# helper-stubs.R shadows the real server; re-bind it (P7 / test-isa-responses-entry.R pattern).
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

# setInputs for one panel's dynamically-suffixed inputs (setInputs does not
# interpolate names, so build them with paste0 + do.call).
set_panel <- function(session, prefix, sid, ...) {
  vals <- list(...)
  names(vals) <- paste0(prefix, "_", names(vals), "_", sid)
  do.call(session$setInputs, vals)
}
srv_args <- function(pdr) list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL)

test_that("picking in the panel saves the snapshot; hand edits survive save, reload and re-save", {
  f1 <- get_indicator("F_01"); rev1 <- as.character(f1$revision)
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    isa_data$pressures <- data.frame(ID = "P001", Name = "Overfishing", stringsAsFactors = FALSE)  # a_p target
    session$setInputs(add_a = 1)
    aid <- isa_data$a_panel_ids[[length(isa_data$a_panel_ids)]]
    set_panel(session, "a", aid, name = "Fishing", registry = "F_01")
    session$setInputs(save_ex4 = 1)
    a <- isa_data$activities
    expect_equal(indicator_col(a, "Registry_Id"), "F_01")
    expect_equal(indicator_col(a, "Registry_Version"), rev1)
    expect_equal(indicator_col(a, "Indicator"), f1$name)
    expect_equal(indicator_col(a, "Indicator_Unit"), f1$unit)
    expect_equal(indicator_col(pdr()$data$isa_data$activities, "Registry_Id"), "F_01")
    expect_equal(pdr()$min_app_version, WP5_INDICATOR_MIN_APP_VERSION)        # WS-0 stamp
    set_panel(session, "a", aid, indicator = "My share", indunit = "ratio")    # hand edits after the pick
    session$setInputs(save_ex4 = 2)
    a <- isa_data$activities
    expect_equal(indicator_col(a, "Indicator"), "My share")
    expect_equal(indicator_col(a, "Indicator_Unit"), "ratio")
    expect_equal(indicator_col(a, "Registry_Id"), "F_01")
    expect_equal(indicator_col(a, "Registry_Version"), rev1)
  })
  # save -> RDS -> load -> re-save in a fresh session: the row has no live panel and is carried over
  f <- tempfile(fileext = ".rds")
  saveRDS(shiny::isolate(pdr()), f)
  pdr2 <- shiny::reactiveVal(normalize_and_reconcile_project(readRDS(f)))
  testServer(isa_data_entry_server, args = srv_args(pdr2), {
    session$flushReact()
    session$setInputs(save_ex4 = 1)
    a <- isa_data$activities
    expect_equal(indicator_col(a, "Indicator"), "My share")
    expect_equal(indicator_col(a, "Indicator_Unit"), "ratio")
    expect_equal(indicator_col(a, "Registry_Id"), "F_01")
    expect_equal(indicator_col(a, "Registry_Version"), rev1)
  })
})

test_that("a save without a registry pick does not stamp min_app_version", {
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    isa_data$pressures <- data.frame(ID = "P001", Name = "Overfishing", stringsAsFactors = FALSE)  # a_p target
    session$setInputs(add_a = 1)
    aid <- isa_data$a_panel_ids[[length(isa_data$a_panel_ids)]]
    set_panel(session, "a", aid, name = "Fishing")
    session$setInputs(save_ex4 = 1)
    expect_equal(nrow(isa_data$activities), 1L)
    expect_null(pdr()$min_app_version)
  })
})

test_that("responses gain no indicator columns (ruling 9)", {
  pdr <- shiny::reactiveVal(list(project_id = "p1", data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    isa_data$goods_benefits <- data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE)
    isa_data$drivers <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)
    session$setInputs(add_response = 1)
    rid <- isa_data$r_panel_ids[[1]]
    set_panel(session, "r", rid, name = "MSP", linkedgb = "GB001", linkedd = "D001")
    session$setInputs(save_responses = 1)
    expect_equal(nrow(isa_data$responses), 1L)
    expect_false(any(tolower(names(isa_data$responses)) %in%
                     tolower(c("Indicator_Unit", "Data_Source", "Registry_Id", "Registry_Version"))))
  })
})
