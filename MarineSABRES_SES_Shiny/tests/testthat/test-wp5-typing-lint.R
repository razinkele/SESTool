# tests/testthat/test-wp5-typing-lint.R
# WS-3b: flag likely mistyped interventions (L1) and Responses without feedback (L2). Never edits data.
library(testthat)
source_for_test(c("functions/visnetwork_helpers.R", "functions/template_loader.R", "functions/wp5_typing_lint.R"))

nd <- function(id, name, group) data.frame(id = id, label = name, name_raw = name, group = group, stringsAsFactors = FALSE)
eg <- function(from, to) data.frame(from = from, to = to, stringsAsFactors = FALSE)

test_that("L1 flags instrument/measure terms on D/A/ES nodes, in several languages", {
  nodes <- rbind(nd("A_1", "Fishing quota agreements", "Activities"),
                 nd("A_2", "Žvejybos kvotos", "Activities"),
                 nd("D_1", "Μέτρα απαγόρευσης αλιείας", "Drivers"),
                 nd("ES_1", "Marine protected area", "Ecosystem Services"),
                 nd("P_1", "Mooring damage", "Pressures"))          # pressures are not linted by L1
  out <- wp5_typing_lint(nodes, eg(character(), character()))
  l1 <- out[out$rule == "L1", ]
  expect_setequal(l1$node_id, c("A_1", "A_2", "D_1", "ES_1"))
  expect_true(all(nzchar(l1$matched)))
})

test_that("L1 does not match terms inside other words", {
  nodes <- rbind(nd("A_1", "Urban development", "Activities"), nd("A_2", "Taxa richness survey", "Activities"),
                 nd("A_3", "Banner fishing", "Activities"), nd("D_1", "Labour market", "Drivers"),
                 nd("A_4", "Coastal tourism", "Activities"))
  expect_equal(nrow(wp5_typing_lint(nodes, eg(character(), character()))), 0L)
})

test_that("L2 flags Responses with no feedback link from MPF/ES/GB only", {
  nodes <- rbind(nd("R_1", "Quota", "Responses"), nd("R_2", "Eco-label", "Responses"),
                 nd("GB_1", "Fish catch", "Goods & Benefits"), nd("D_1", "Food demand", "Drivers"))
  edges <- rbind(eg("GB_1", "R_1"), eg("D_1", "R_2"))             # D->R is not feedback
  out <- wp5_typing_lint(nodes, edges)
  expect_equal(out$node_id[out$rule == "L2"], "R_2")
})

test_that("empty inputs give zero findings without error", {
  e <- wp5_typing_lint(nd("x", "x", "Drivers")[0, ], eg(character(), character()))
  expect_equal(nrow(e), 0L)
  expect_equal(names(e), c("node_id", "name", "group", "rule", "matched"))
  expect_equal(nrow(typing_lint_from_isa(list())), 0L)
  expect_equal(nrow(wp5_typing_lint(NULL, NULL)), 0L)
})

test_that("synonym file is toolbox-authored and covers all 9 languages", {
  syn <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "data", "wp5_rm_synonyms.json"), simplifyVector = FALSE)
  expect_equal(syn$provenance, "toolbox_extension")
  expect_setequal(names(syn$patterns), c("en","es","fr","de","lt","pt","it","no","el"))
  for (p in unlist(syn$patterns)) expect_no_error(grepl(paste0("(*UCP)(?<!\\p{L})(", p, ")(?!\\p{L})"), "x", perl = TRUE))
})

test_that("all seven shipped templates lint without error (counts recorded)", {
  for (nm in c("Aquaculture", "Caribbean", "ClimateChange", "Fisheries", "OffshoreWind", "Pollution", "Tourism")) {
    p <- file.path(PROJECT_ROOT, "data", paste0(nm, "_SES_Template.json"))
    tpl <- load_template_from_json(p, use_cache = FALSE)
    isa <- list(drivers = tpl$drivers, activities = tpl$activities, pressures = tpl$pressures,
                marine_processes = tpl$marine_processes, ecosystem_services = tpl$ecosystem_services,
                goods_benefits = tpl$goods_benefits, responses = tpl$responses,
                adjacency_matrices = tpl$adjacency_matrices)
    out <- typing_lint_from_isa(isa)
    expect_s3_class(out, "data.frame")
    message(sprintf("[typing-lint] %s: L1=%d L2=%d", nm, sum(out$rule == "L1"), sum(out$rule == "L2")))
  }
})

test_that("ecosystem-service 'regulation' vocabulary is not flagged (climate/water regulation)", {
  nodes <- rbind(nd("ES_1", "Arctic climate regulation", "Ecosystem Services"),
                 nd("ES_2", "Regulación climática", "Ecosystem Services"),
                 nd("ES_3", "Ρύθμιση του κλίματος", "Ecosystem Services"))
  expect_equal(nrow(wp5_typing_lint(nodes, eg(character(), character()))), 0L)
})

# ---- review fix I5: realistic false positives (activities/drivers/services, not instruments) ----
test_that("realistic SES names are not flagged (moorings activity, rates, catering, insurance, ES senses)", {
  fp <- list(
    c("Tax revenue", "Drivers"), c("Fee-paying diving", "Activities"), c("Protected areas tourism", "Activities"),
    c("Nursery habitat in protected areas", "Ecosystem Services"), c("Recreational boat mooring", "Activities"),
    c("Anchoring and mooring of leisure boats", "Activities"), c("Tasa de desempleo", "Drivers"),
    c("Tasa de crecimiento poblacional", "Drivers"), c("Hébergement et restauration", "Activities"),
    c("Arbeitslosenquote", "Drivers"), c("Überlebensquote", "Ecosystem Services"),
    c("Sauerstoffabgabe durch Seegras", "Ecosystem Services"), c("Regulierung des Wasserhaushalts", "Ecosystem Services"),
    c("Regulering av klima", "Ecosystem Services"), c("Kulturskatt", "Ecosystem Services"),
    c("Laivų draudimas", "Activities"), c("Draudimo paslaugos", "Activities"),
    c("Fondeo de embarcaciones", "Activities"), c("Mouillage des plaisanciers", "Activities"),
    c("Ormeggio delle barche", "Activities"))
  nodes <- do.call(rbind, lapply(seq_along(fp), function(i) nd(paste0("X_", i), fp[[i]][1], fp[[i]][2])))
  out <- wp5_typing_lint(nodes, eg(character(), character()))
  expect_equal(nrow(out), 0L, info = paste(out$name, collapse = " | "))
})

test_that("instrument/measure names are still flagged, incl. Greek capitals and unaccented Greek (I6)", {
  tp <- c("Fishing quota agreements", "Žvejybos kvotos", "ΑΠΑΓΟΡΕΥΣΗ ΑΛΙΕΙΑΣ", "απαγορευση αλιειας",
          "Μέτρα απαγόρευσης αλιείας", "Fangquoten", "Žvejybos draudimas", "Restauration écologique",
          "Quota di pesca", "Landing fees", "Carbon tax", "Mooring buoy fields", "Marine protected area")
  nodes <- do.call(rbind, lapply(seq_along(tp), function(i) nd(paste0("A_", i), tp[i], "Activities")))
  out <- wp5_typing_lint(nodes, eg(character(), character()))
  expect_setequal(out$name, tp)
})

# ---- review fix I3: lint reads ISA data directly (no CLD build), keyed by stable element IDs ----
isa_shape <- function() list(
  goods_benefits = data.frame(ID = "GB001", Name = "Fish catch", stringsAsFactors = FALSE),
  responses = data.frame(ID = c("R001", "R002"), Name = c("Quota", "Eco-label"), stringsAsFactors = FALSE),
  activities = data.frame(ID = c("A001", "A002"), Name = c("Coastal tourism", "Fishing quota agreements"),
                          stringsAsFactors = FALSE),
  adjacency_matrices = list(gb_r = matrix(c("-Medium:Medium", ""), nrow = 1,
                                          dimnames = list("GB001", c("R001", "R002")))))

test_that("typing_lint_from_isa works on ISA-module data with stable element IDs and gb_r feedback", {
  out <- typing_lint_from_isa(isa_shape())
  expect_equal(out$node_id[out$rule == "L2"], "R002")
  expect_equal(out$node_id[out$rule == "L1"], "A002")
  expect_false(any(grepl("create_edges_df|create_nodes_df", deparse(typing_lint_from_isa))))
})

test_that("typing_lint_from_isa still lints when there are no feedback matrices at all", {
  isa <- isa_shape()
  isa$adjacency_matrices <- list()
  out <- typing_lint_from_isa(isa)
  expect_equal(out$node_id[out$rule == "L1"], "A002")
  expect_setequal(out$node_id[out$rule == "L2"], c("R001", "R002"))
})

# ---- Task 2 + review fixes I1/I2/I4: ISA module notifications ------------------------------
source_for_test(c("modules/isa_data_entry_module.R", "functions/isa_form_builders.R",
                  "functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/project_transactions.R"))
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

project_with_activity <- function(act_name, pid = "p1", extra = NULL) {
  acts <- data.frame(ID = c("A001", extra$ID), Name = c(act_name, extra$Name), Sector = "", Description = "",
                     LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE)
  list(project_id = pid, data = list(isa_data = list(activities = acts,
       adjacency_matrices = list(), user_edited_matrices = list())))
}

test_that("a mistyped activity notifies once; equivalent re-saves and unrelated edits do not re-notify", {
  pdr <- shiny::reactiveVal(project_with_activity("Fishing quota agreements"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_true("L1:A001" %in% typing_state$last)
    expect_equal(typing_state$notified, 1L)
    pdr(modifyList(pdr(), list(metadata = list(saved_at = 2))))   # different object, same findings
    session$flushReact()
    expect_equal(typing_state$notified, 1L)
    p2 <- project_with_activity("Fishing quota agreements", extra = list(ID = "A000", Name = "Coastal tourism"))
    pdr(p2); session$flushReact()                                  # unrelated insertion shifts rows
    expect_equal(typing_state$notified, 1L)
  })
})

test_that("switching to another project resets the dedup state", {
  pdr <- shiny::reactiveVal(project_with_activity("Fishing quota agreements", pid = "p1"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_equal(typing_state$notified, 1L)
    pdr(project_with_activity("Fishing quota agreements", pid = "p2")); session$flushReact()
    expect_equal(typing_state$notified, 2L)
  })
})

test_that("a clean model records no finding", {
  pdr <- shiny::reactiveVal(project_with_activity("Coastal tourism"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_length(typing_state$last, 0)
    expect_equal(typing_state$notified, 0L)
  })
})

test_that("lint is wired after the alignment warning; L1 and L2 messages translated with positional args", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "isa_data_entry_module.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("warn_if_matrices_misaligned()\n        warn_if_mistyped()", s, fixed = TRUE))
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "isa_data_entry.json"),
                           simplifyVector = FALSE)$translation
  f1 <- tr[["modules.isa.data_entry.common.typing_lint_found"]]
  f2 <- tr[["modules.isa.data_entry.common.typing_lint_l2_count"]]
  for (l in c("en","es","fr","de","lt","pt","it","no","el")) {
    expect_true(grepl("%1$d", f1[[l]], fixed = TRUE) && grepl("%2$s", f1[[l]], fixed = TRUE), info = l)
    expect_true(grepl("%1$d", f2[[l]], fixed = TRUE), info = l)
  }
  expect_null(tr[["modules.isa.data_entry.common.typing_lint_l1"]])
  expect_null(tr[["modules.isa.data_entry.common.typing_lint_l2"]])
})

