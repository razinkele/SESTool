# tests/testthat/test-stable-element-ids.R
# Red->green anchor for the stable-element-ID fix (feedback #2/#3/#4).
# Element IDs must NOT be positional: a survivor keeps its ID after a mid-list
# removal, and a subsequent add never reuses a number.
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/data_structure.R"))

# source_for_test() writes to .GlobalEnv, but helper-stubs.R defines a stub
# isa_data_entry_server in testthat's helper environment, which SHADOWS
# .GlobalEnv during name lookup. Re-bind the real implementation into this
# file's env so testServer() drives the real module, not the stub.
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

test_that("survivor keeps its stable ID after a mid-list removal; adds never reuse", {
  i18n <- make_test_i18n()
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = reactiveVal(NULL),
                         i18n = i18n, event_bus = NULL), {
    # The module returns reactive({ isa_data }); session$getReturned() yields
    # that reactive, so call it to reach the live isa_data reactiveValues. Read
    # trackers off it rather than the module-private local (testServer does not
    # expose locals here — see test-entry-point-module.R).
    isa <- function() session$getReturned()()

    session$setInputs(add_es = 1); session$setInputs(add_es = 2); session$setInputs(add_es = 3)
    expect_equal(isa()$es_panel_ids, c("ES001", "ES002", "ES003"))

    # Panel remove button id is built as paste0(prefix, "_remove_", current_id).
    session$setInputs(es_remove_ES001 = 1)
    expect_equal(isa()$es_panel_ids, c("ES002", "ES003"))  # no renumber

    session$setInputs(add_es = 4)
    expect_equal(isa()$es_panel_ids, c("ES002", "ES003", "ES004"))
  })
})

test_that("loading a corrupted project (duplicate ids) repairs without crashing and adopts panel ids", {
  i18n <- make_test_i18n()
  # project_id present so the load observer (keyed on project_id) fires.
  pdr <- reactiveVal(list(project_id = "p1", data = list(isa_data = list(
    ecosystem_services = data.frame(ID = c("ES001", "ES001"), Name = c("a", "b"),
                                    LinkedGB = c("GB001", "GB001"), stringsAsFactors = FALSE),
    goods_benefits = data.frame(ID = "GB001", Name = "x", stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list()
  ))))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pdr, i18n = i18n, event_bus = NULL), {
    isa <- function() session$getReturned()()
    session$flushReact()

    expect_equal(anyDuplicated(isa()$ecosystem_services$ID), 0)        # dup repaired
    expect_true(all(nzchar(isa()$ecosystem_services$ID)))
    expect_equal(isa()$es_panel_ids, isa()$ecosystem_services$ID)      # adopted as tracker

    # An add after a repaired load must not collide with an existing id.
    session$setInputs(add_es = 1)
    last <- tail(isa()$es_panel_ids, 1)
    expect_false(last %in% head(isa()$es_panel_ids, -1))
  })
})
