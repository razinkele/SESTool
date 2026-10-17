# tests/testthat/test-wp5-governance-context-module.R
library(testthat)
source_for_test(c("functions/stakeholder_schema.R", "functions/wp5_governance.R",
                  "modules/wp5_governance_context_module.R", "modules/response_module.R"))
real_ctx_server <- get("wp5_governance_context_server", envir = .GlobalEnv)
real_rm_ui <- get("response_measures_ui", envir = .GlobalEnv)        # helper-stubs.R shadows it
real_rm_server <- get("response_measures_server", envir = .GlobalEnv)
i18n_echo <- make_test_i18n()
tus <- wp5_gov_profile_for_site(load_wp5_governance_profiles(), "Tuscan Archipelago")

proj_da <- function(site) { p <- create_empty_project("t", da_site = site); p$project_id <- "p1"; p }
fake_register <- function() {
  store <- shiny::reactiveVal(normalize_response_measures(NULL))
  list(measures = function() store(),
       add = function(fields) {
         id <- sprintf("RM%03d", nrow(store()) + 1L)
         store(rbind(store(), normalize_response_measures(as.data.frame(c(list(ID = id), fields), stringsAsFactors = FALSE))))
         id
       },
       store = store)
}

test_that("UI contract and the Response module tab", {
  ui <- as.character(wp5_governance_context_ui("g", i18n_echo))
  expect_match(ui, "g-dimension", fixed = TRUE)
  expect_true(all(c("id", "project_data_reactive", "i18n", "event_bus", "register") %in%
                  names(formals(wp5_governance_context_server))))
  html <- as.character(real_rm_ui("rm", i18n_echo))
  expect_match(html, "modules.wp5_governance.context_tab", fixed = TRUE)
  expect_match(html, "rm-gov_ctx-dimension", fixed = TRUE)
})

test_that("project DA drives the cards; filters narrow them", {
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da("Tuscan Archipelago")),
                                          i18n = i18n_echo, register = fake_register()), {
    session$flushReact()
    html <- as.character(output$body$html)
    expect_match(html, "<h6 class=\"mt-3\">knowledge</h6>", fixed = TRUE)   # echo i18n: wp5_vocab_label falls back to the code
    expect_match(html, tus$cards[[1]]$source_ref, fixed = TRUE)
    session$setInputs(polarity = "barrier")
    html <- as.character(output$body$html)
    expect_false(grepl("modules.wp5_governance.polarity.enabler", html, fixed = TRUE))
    expect_match(html, "modules.wp5_governance.polarity.barrier", fixed = TRUE)
  })
})

test_that("no DA: hint; choosing a DA shows it (review focus 1)", {
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da(NULL)),
                                          i18n = i18n_echo, register = fake_register()), {
    session$flushReact()
    expect_match(as.character(output$body$html), "modules.wp5_governance.no_da_hint", fixed = TRUE)
    session$setInputs(da = "Macaronesia")
    expect_match(as.character(output$body$html), "modules.wp5_governance.cards_title", fixed = TRUE)
  })
})

test_that("Add to register writes one measure; a second click does not (review focus 5)", {
  reg <- fake_register()
  rec <- tus$recommendations[[1]]
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da("Tuscan Archipelago")),
                                          i18n = i18n_echo, register = reg), {
    session$flushReact()
    expect_match(as.character(output$recommendations$html), "modules.wp5_governance.add_to_register", fixed = TRUE)
    session$setInputs(add_rec = rec$id)
    m <- shiny::isolate(reg$store())
    expect_equal(nrow(m), 1L)
    expect_equal(c(m$Name, m$Kind, m$Status, m$EbmCode), c(rec$title, "instrument", "proposed", rec$ebm_code))
    session$setInputs(add_rec = rec$id)
    expect_equal(nrow(shiny::isolate(reg$store())), 1L)
    expect_match(as.character(output$recommendations$html), "modules.wp5_governance.already_in_register", fixed = TRUE)
  })
})

test_that("missing reference data shows the notice", {
  old <- get("load_wp5_governance_profiles", envir = .GlobalEnv)
  assign("load_wp5_governance_profiles", function(...) NULL, envir = .GlobalEnv)
  withr::defer(assign("load_wp5_governance_profiles", old, envir = .GlobalEnv))
  testServer(real_ctx_server, args = list(project_data_reactive = shiny::reactiveVal(proj_da("Tuscan Archipelago")),
                                          i18n = i18n_echo, register = fake_register()), {
    session$flushReact()
    expect_match(as.character(output$body$html), "modules.wp5_governance.unavailable", fixed = TRUE)
  })
})

test_that("inside the Response module, Add to register lands in the register and the project", {
  pd <- shiny::reactiveVal(proj_da("Tuscan Archipelago"))
  rec <- tus$recommendations[[1]]
  testServer(real_rm_server, args = list(project_data_reactive = pd, i18n = i18n_echo), {
    session$flushReact()
    do.call(session$setInputs, stats::setNames(list(rec$id), "gov_ctx-add_rec"))
    expect_equal(nrow(response_data$measures), 1L)
    expect_equal(response_data$measures$ID, "RM001")
    expect_equal(pd()$data$response_measures$measures$Name, rec$title)
  })
})
