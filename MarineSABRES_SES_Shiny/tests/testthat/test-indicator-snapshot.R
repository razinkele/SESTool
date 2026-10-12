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

# ---- Task 5: drift ----------------------------------------------------------
cur_rev <- as.character(get_indicator("F_01")$revision)
isa_drift <- function(ver = "0", reg = "F_01") list(
  activities = data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                          Indicator = c("Tuna share", ""), Indicator_Unit = c("%", ""), Data_Source = c("", ""),
                          Registry_Id = c(reg, ""), Registry_Version = c(ver, ""), stringsAsFactors = FALSE))

test_that("an older registry revision is reported as drift with the value diff; current is not", {
  d <- indicator_drift(isa_drift("0"))
  expect_equal(d$element_id, "A001")
  expect_equal(d$status, "updated")
  expect_equal(d$current_revision, cur_rev)
  expect_equal(d$element_indicator, "Tuna share")                   # roadmap §7.6: snapshot value ...
  expect_equal(d$registry_indicator, get_indicator("F_01")$name)    # ... vs current registry value
  expect_equal(d$registry_unit, get_indicator("F_01")$unit)
  expect_equal(nrow(indicator_drift(isa_drift(cur_rev))), 0L)
})

test_that("missing registry ids are reported, not updated", {
  d <- indicator_drift(isa_drift("1", reg = "GONE_99"))
  expect_equal(d$status, "missing")
  df <- apply_registry_resnapshot(isa_drift("1", reg = "GONE_99")$activities, "A001")
  expect_equal(df$Indicator[1], "Tuna share")                      # untouched
})

test_that("an unavailable registry reports no drift (nothing is flagged missing)", {
  expect_warning(load_indicator_registry(path = tempfile(fileext = ".json"), force_reload = TRUE), "registry")
  expect_equal(nrow(indicator_drift(isa_drift("0"))), 0L)
  load_indicator_registry(force_reload = TRUE)                     # restore
  expect_equal(nrow(indicator_drift(isa_drift("0"))), 1L)
})

test_that("re-snapshot overwrites only the chosen rows and clears their drift", {
  isa <- isa_drift("0")
  isa$activities <- apply_registry_resnapshot(isa$activities, "A001")
  expect_equal(isa$activities$Indicator[1], get_indicator("F_01")$name)
  expect_equal(isa$activities$Registry_Version[1], cur_rev)
  expect_equal(nrow(indicator_drift(isa)), 0L)
})

test_that("drift reads lowercased columns after JSON load", {
  isa <- isa_drift("0"); names(isa$activities) <- tolower(names(isa$activities))
  expect_equal(indicator_drift(isa)$element_id, "A001")
})

test_that("empty or indicator-free projects give zero drift without error", {
  expect_equal(nrow(indicator_drift(list())), 0L)
  expect_equal(nrow(indicator_drift(list(drivers = data.frame(ID = "D001", Name = "x")))), 0L)
  expect_equal(indicator_drift_keys(indicator_drift(list())), character(0))
})

proj_with_snapshot <- function(ver, pid = "p1", reg = "F_01") list(project_id = pid, data = list(isa_data = list(
  activities = data.frame(ID = "A001", Name = "Fishing", Sector = "", Description = "", LinkedP = "",
                          Scale = "", Frequency = "", Indicator = "Tuna share", Indicator_Unit = "%",
                          Data_Source = "", Registry_Id = reg, Registry_Version = ver, stringsAsFactors = FALSE),
  adjacency_matrices = list(), user_edited_matrices = list())))

test_that("loading a stale snapshot notifies once, shows the review link; re-snapshot via the modal clears it", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("0"))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    expect_equal(drift_state$last, "activities:A001")
    expect_match(as.character(output$indicator_drift_bar$html), "indicator_drift_open", fixed = TRUE)
    pdr(modifyList(pdr(), list(metadata = list(saved_at = 2)))); session$flushReact()
    expect_equal(drift_state$notified, 1L)                         # same findings: silent
    session$setInputs(indicator_drift_open = 1)                     # persistent link opens the modal
    session$setInputs(indicator_drift_ids = "activities:A001")
    session$setInputs(indicator_drift_apply = 1)
    expect_equal(indicator_col(isa_data$activities, "Registry_Version"), cur_rev)
    expect_equal(indicator_col(isa_data$activities, "Indicator"), get_indicator("F_01")$name)
    expect_length(drift_state$last, 0)
    expect_equal(nrow(drift_rv()), 0L)                              # link disappears
  })
})

test_that("a missing-only drift review opens and applies without error and changes nothing", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("1", reg = "GONE_99"))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$findings$status, "missing")
    expect_no_error(session$setInputs(indicator_drift_open = 1))
    expect_no_error(session$setInputs(indicator_drift_ids = ":", indicator_drift_apply = 1))   # bogus pick
    expect_equal(indicator_col(isa_data$activities, "Registry_Id"), "GONE_99")
    expect_equal(indicator_col(isa_data$activities, "Indicator"), "Tuna share")
    expect_equal(indicator_col(isa_data$activities, "Registry_Version"), "1")
  })
})

test_that("dismissing keeps the data and the review link; same-project writes stay silent; a new session re-notifies", {
  pdr <- shiny::reactiveVal(proj_with_snapshot("0"))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    session$setInputs(indicator_drift_open = 1)                     # open, then close without applying
    pdr(modifyList(pdr(), list(metadata = list(saved_at = 3)))); session$flushReact()
    expect_equal(drift_state$notified, 1L)
    expect_equal(indicator_col(isa_data$activities, "Registry_Version"), "0")
    expect_equal(drift_state$findings$element_id, "A001")
    expect_match(as.character(output$indicator_drift_bar$html), "indicator_drift_open", fixed = TRUE)
  })
  pdr2 <- shiny::reactiveVal(proj_with_snapshot("0"))               # next load (new session)
  testServer(isa_data_entry_server, args = srv_args(pdr2), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
  })
})

test_that("a current snapshot records no drift; switching project resets the dedup", {
  pdr <- shiny::reactiveVal(proj_with_snapshot(cur_rev))
  testServer(isa_data_entry_server, args = srv_args(pdr), {
    session$flushReact()
    expect_equal(drift_state$notified, 0L)
  })
  # Same stale element ID in two projects: only the project-change reset of
  # drift_state$last lets p2 notify again (this fails without that line).
  pdr2 <- shiny::reactiveVal(proj_with_snapshot("0", pid = "p1"))
  testServer(isa_data_entry_server, args = srv_args(pdr2), {
    session$flushReact()
    expect_equal(drift_state$notified, 1L)
    pdr2(proj_with_snapshot("0", pid = "p2")); session$flushReact()
    expect_equal(drift_state$notified, 2L)
  })
})

test_that("every indicator-registry and badge key used in code exists in all 9 languages, defined once", {
  langs <- c("en","es","fr","de","lt","pt","it","no","el")
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "indicator_registry.json"),
                           simplifyVector = FALSE)$translation
  mech <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "wp5_mechanisms.json"),
                             simplifyVector = FALSE)$translation
  keys <- c("picker_none", "picker_label", "picker_help", "picker_group_suggested", "picker_group_other",
            "field_indicator", "field_unit", "field_data_source", "da.macaronesia", "da.tuscan", "da.arctic",
            "stub_marker", "drift_found", "drift_found_missing", "drift_review", "drift_link", "drift_title",
            "drift_explain", "drift_missing_explain", "drift_apply", "drift_status_updated", "drift_status_missing",
            "drift_col_field", "drift_col_element", "drift_col_registry")
  for (k in paste0("modules.indicator_registry.", keys)) {
    expect_false(is.null(tr[[k]]), info = k)
    for (l in langs) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (k in paste0("modules.wp5_mechanisms.provenance.", c("wp5_derived", "toolbox_extension", "provisional"))) {
    expect_false(is.null(mech[[k]]), info = k)
    expect_null(tr[[k]])                                            # defined in wp5_mechanisms.json only
    for (l in langs) expect_true(nzchar(mech[[k]][[l]] %||% ""), info = paste(k, l))
  }
  for (k in c("drift_found", "drift_found_missing"))
    for (l in langs)
      expect_true(grepl("%1$d", tr[[paste0("modules.indicator_registry.", k)]][[l]], fixed = TRUE), info = paste(k, l))
  ui <- paste(readLines(file.path(PROJECT_ROOT, "functions", "ui_components.R"), warn = FALSE), collapse = "\n")
  for (p in c("toolbox_extension", "provisional"))
    expect_match(ui, paste0("# i18n-ref: modules.wp5_mechanisms.provenance.", p), fixed = TRUE)
})

# ---- Final review fixes -------------------------------------------------------
test_that("mixed number/text values in one column across rows do not drop the category", {
  # review #1: dplyr::bind_rows refuses <double> + <character> in one column; the
  # tryCatch then turned the whole category into NULL (hand-edited / foreign JSON).
  js <- '{"data":{"isa_data":{"drivers":[{"ID":"D1","Name":"a","Importance":3},{"ID":"D2","Name":"b","Importance":"High"}]}}}'
  out <- normalize_json_project_data(jsonlite::fromJSON(js, simplifyVector = FALSE))
  d <- out$data$isa_data$drivers
  expect_equal(nrow(d), 2L)
  expect_equal(indicator_col(d, "Importance"), c("3", "High"))
})

test_that("the picker fills blank or previously-picked values and keeps the user's own text", {
  # review #2: one rule for picking and switching; typed text is never replaced.
  f1 <- get_indicator("F_01"); t1 <- get_indicator("T_01")
  src <- function(e) paste(unlist(e$data_sources), collapse = "; ")
  up <- indicator_picker_updates(list(indicator = "", indunit = "my unit", datasource = ""), "", "F_01")
  expect_equal(up, list(indicator = f1$name, datasource = src(f1)))
  cur <- list(indicator = f1$name, indunit = f1$unit, datasource = "My survey")
  expect_equal(indicator_picker_updates(cur, "F_01", "T_01"), list(indicator = t1$name, indunit = t1$unit))
  expect_equal(indicator_picker_updates(cur, "F_01", ""), list(indicator = "", indunit = ""))
  expect_match(paste(deparse(register_indicator_picker_observer), collapse = "\n"), "indicator_picker_updates",
               fixed = TRUE)
})
