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

# ---- Task 2: surfaced in the ISA module (warn only; re-notify only on change) -----
source_for_test(c("modules/isa_data_entry_module.R", "functions/isa_form_builders.R",
                  "functions/data_structure.R", "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R", "functions/project_transactions.R"))
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

project_with_activity <- function(act_name, pid = "p1") list(project_id = pid, data = list(isa_data = list(
  activities = data.frame(ID = "A001", Name = act_name, Sector = "", Description = "",
                          LinkedP = "", Scale = "", Frequency = "", stringsAsFactors = FALSE),
  adjacency_matrices = list(), user_edited_matrices = list())))

test_that("a mistyped activity is recorded once; an unchanged re-save does not re-notify", {
  pdr <- shiny::reactiveVal(project_with_activity("Fishing quota agreements"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_true(any(startsWith(typing_state$last, "L1:")))
    first <- typing_state$last
    pdr(pdr()); session$flushReact()
    expect_identical(typing_state$last, first)
  })
})

test_that("a clean model records no typing finding", {
  pdr <- shiny::reactiveVal(project_with_activity("Coastal tourism"))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = make_test_i18n(), event_bus = NULL), {
    session$flushReact()
    expect_length(typing_state$last, 0)
  })
})

test_that("typing lint is wired after the alignment warning; messages translated in 9 languages", {
  s <- paste(readLines(file.path(PROJECT_ROOT, "modules", "isa_data_entry_module.R"), warn = FALSE), collapse = "\n")
  expect_true(grepl("warn_if_matrices_misaligned()\n        warn_if_mistyped()", s, fixed = TRUE))
  tr <- jsonlite::fromJSON(file.path(PROJECT_ROOT, "translations", "modules", "isa_data_entry.json"),
                           simplifyVector = FALSE)$translation
  for (k in paste0("modules.isa.data_entry.common.", c("typing_lint_found", "typing_lint_l1", "typing_lint_l2")))
    for (l in c("en","es","fr","de","lt","pt","it","no","el")) expect_true(nzchar(tr[[k]][[l]] %||% ""), info = paste(k, l))
  for (l in c("en","es","fr","de","lt","pt","it","no","el")) {
    f <- tr[["modules.isa.data_entry.common.typing_lint_found"]][[l]]
    expect_true(grepl("%d", f, fixed = TRUE) && grepl("%s", f, fixed = TRUE), info = l)
  }
})
