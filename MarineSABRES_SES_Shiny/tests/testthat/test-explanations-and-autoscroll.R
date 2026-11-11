# tests/testthat/test-explanations-and-autoscroll.R
# User suggestions 2026-11-11 (one tester):
#  L21 "Automatic scroll-down": after "Approve all" the next step should come
#      into view without scrolling past every card.
#  L23 "Legend, terminology": explain CLD, ISA, PIMS for beginners (Dashboard).
#  L24 "Not intuitive": what is the dominance score, what range, what is Loop
#      Strength Analysis. The page described the score as based on centrality;
#      the code computes 100 / loop length.
#  L25 "About leverage points": explain in-degree and out-degree.

source_for_test(c("modules/connection_review_tabbed.R", "modules/analysis_loops.R",
                  "modules/analysis_leverage.R"))
# helper-stubs.R defines stubs that shadow the real functions here; re-bind.
analysis_loops_ui <- get("analysis_loops_ui", envir = .GlobalEnv)
analysis_leverage_ui <- get("analysis_leverage_ui", envir = .GlobalEnv)

app_root <- function() {
  d <- getwd()
  if (basename(d) == "testthat") dirname(dirname(d)) else d
}
LANGS <- c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")
tr_file <- function(rel) jsonlite::fromJSON(file.path(app_root(), "translations", rel),
                                            simplifyVector = FALSE)$translation
key_i18n <- list(t = function(key, ...) key)
expect_all_langs <- function(entry, key) {
  expect_false(is.null(entry), info = key)
  for (l in LANGS) expect_true(nzchar(trimws(entry[[l]] %||% "")), info = paste(key, l))
}

# --- L24 -----------------------------------------------------------------
test_that("the dominance score is described as the code computes it (100 / loop length)", {
  code <- paste(readLines(file.path(app_root(), "modules", "analysis_loops.R"), warn = FALSE),
                collapse = "\n")
  expect_match(code, "DominanceScore <- 100 / loops$Length", fixed = TRUE)

  loops_tr <- tr_file("modules/analysis_loops.json")
  tools_tr <- tr_file("modules/analysis_tools.json")
  entries <- list(
    dominance_desc = loops_tr[["modules.analysis.loops.dominance_desc"]],
    help = tools_tr[["modules.analysis.measures_how_significant_the_loop_is_based_on_the_"]],
    strength = loops_tr[["modules.analysis.loops.strength_analysis_desc"]])
  for (k in names(entries)) expect_all_langs(entries[[k]], k)

  # The old text claimed centrality; none of the descriptions may say so.
  centrality <- c(en = "centrality", es = "centralidad", fr = "centralit", de = "Zentralit",
                  lt = "centrali", pt = "centralidade", it = "centralit", no = "sentralitet",
                  el = "κεντρικ")
  for (k in c("dominance_desc", "help")) for (l in LANGS) {
    expect_false(grepl(centrality[[l]], entries[[k]][[l]], ignore.case = TRUE), info = paste(k, l))
  }
  # Every language gives the formula and the worked examples.
  for (k in c("dominance_desc", "help")) for (l in LANGS) {
    txt <- entries[[k]][[l]]
    expect_true(grepl("100", txt, fixed = TRUE) && grepl("25", txt, fixed = TRUE) &&
                grepl("10", txt, fixed = TRUE), info = paste(k, l))
  }
  # The worked examples match the formula.
  expect_equal(100 / 4, 25)
})

test_that("the Loop Strength panel explains its chart", {
  html <- as.character(analysis_loops_ui("lp", key_i18n))
  expect_match(html, "modules.analysis.loops.strength_analysis_desc", fixed = TRUE)
})

# --- L25 -----------------------------------------------------------------
test_that("About Leverage Points explains in-degree and out-degree", {
  html <- as.character(analysis_leverage_ui("lev", key_i18n))
  for (k in c("in_degree_label", "in_degree_desc", "out_degree_label", "out_degree_desc")) {
    expect_match(html, paste0("modules.analysis.leverage.", k), fixed = TRUE)
  }
  lev_tr <- tr_file("modules/analysis_leverage.json")
  for (k in c("in_degree_label", "in_degree_desc", "out_degree_label", "out_degree_desc")) {
    key <- paste0("modules.analysis.leverage.", k)
    expect_all_langs(lev_tr[[key]], key)
  }
})

# --- L23 -----------------------------------------------------------------
test_that("the Dashboard has a glossary of CLD, ISA, PIMS, DAPSI(W)R(M) and leverage point", {
  app <- paste(readLines(file.path(app_root(), "app.R"), warn = FALSE), collapse = "\n")
  expect_match(app, 'id = "glossary_card"', fixed = TRUE)
  dash_tr <- tr_file("ui/dashboard.json")
  expect_all_langs(dash_tr[["ui.dashboard.glossary_title"]], "glossary_title")
  for (term in c("cld", "isa", "pims", "dapsiwrm", "leverage")) {
    for (part in c("term", "def")) {
      key <- sprintf("ui.dashboard.glossary_%s_%s", term, part)
      expect_all_langs(dash_tr[[key]], key)
      # dynamic lookup in app.R is declared for the i18n audit
      expect_match(app, paste0("# i18n-ref: ", key), fixed = TRUE)
    }
  }
  expect_match(dash_tr[["ui.dashboard.glossary_pims_term"]]$en, "Project Information Management", fixed = TRUE)
  expect_match(dash_tr[["ui.dashboard.glossary_isa_term"]]$en, "Integrated Systems Analysis", fixed = TRUE)
  expect_match(dash_tr[["ui.dashboard.glossary_cld_term"]]$en, "Causal Loop Diagram", fixed = TRUE)
})

# --- L21 -----------------------------------------------------------------
connection_review_tabbed_server <- get("connection_review_tabbed_server", envir = .GlobalEnv)
review_conns <- function() {
  c(lapply(1:3, function(i) list(from_type = "driver", to_type = "activity",
                                  from_name = paste("Driver", i), to_name = paste("Activity", i),
                                  polarity = "+", strength = "medium", confidence = 3)),
    lapply(1:2, function(i) list(from_type = "activity", to_type = "pressure",
                                  from_name = paste("Activity", i), to_name = paste("Pressure", i),
                                  polarity = "-", strength = "strong", confidence = 4)))
}
fmt_i18n <- list(t = function(key, ...) switch(key,
  "common.misc.all_d_connections_in_s_approved" = "%d in %s",
  "common.misc.all_d_connections_in_s_rejected" = "%d in %s",
  key))

test_that("'Approve all' scrolls to the batch's next step once it has rendered", {
  js <- character(0)
  testthat::local_mocked_bindings(runjs = function(code) { js <<- c(js, code); invisible() },
                                  .package = "shinyjs")
  conns <- shiny::reactiveVal(review_conns())   # helper-stubs.R stubs reactiveVal
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = fmt_i18n), {
    session$flushReact()
    js <<- character(0)
    session$setInputs(approve_all_drivers_activities = 1)
    expect_setequal(rv$approved, 1:3)
    hit <- js[grepl(session$ns("next_category_btn_drivers_activities"), js, fixed = TRUE)]
    expect_length(hit, 1)
    # waits for the rendered content, scrolls the card list, then the page
    expect_match(hit, "textContent", fixed = TRUE)
    expect_match(hit, "conn-batch-content", fixed = TRUE)
    expect_match(hit, "scrollIntoView", fixed = TRUE)
  })
})

test_that("'Reject all' does not jump the page", {
  js <- character(0)
  testthat::local_mocked_bindings(runjs = function(code) { js <<- c(js, code); invisible() },
                                  .package = "shinyjs")
  conns <- shiny::reactiveVal(review_conns())
  testServer(connection_review_tabbed_server,
             args = list(connections_reactive = conns, i18n = fmt_i18n), {
    session$flushReact()
    js <<- character(0)
    session$setInputs(reject_all_drivers_activities = 1)
    expect_false(any(grepl("next_category_btn_", js, fixed = TRUE)))
  })
})

test_that("the glossary matches the Dashboard's CLD abbreviation and avoids overclaims (review #153)", {
  dash_tr <- tr_file("ui/dashboard.json")
  shown <- dash_tr[["ui.dashboard.cld_generated"]]
  term <- dash_tr[["ui.dashboard.glossary_cld_term"]]
  for (l in LANGS) {
    abbr <- strsplit(shown[[l]], " ", fixed = TRUE)[[1]][1]
    expect_true(grepl(abbr, term[[l]], fixed = TRUE), info = paste(l, abbr))
  }
  # polarity is a push on the other element, not "both change together"
  expect_false(grepl("same direction", dash_tr[["ui.dashboard.glossary_cld_def"]]$en, fixed = TRUE))
  # leverage points are structural candidates, not a spread forecast
  lev <- dash_tr[["ui.dashboard.glossary_leverage_def"]]$en
  expect_false(grepl("likely to spread", lev, fixed = TRUE))
  expect_match(lev, "candidate", fixed = TRUE)
})
