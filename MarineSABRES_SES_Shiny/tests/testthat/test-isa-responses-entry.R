# tests/testthat/test-isa-responses-entry.R
source_for_test(c("modules/isa_data_entry_module.R",
                  "functions/isa_form_builders.R",
                  "functions/matrix_from_linked.R"))
# helper-stubs.R defines a no-op stub `isa_data_entry_server` that SHADOWS the
# real module during name lookup. Re-bind the real implementation into this
# file's env so testServer() drives the real module, not the stub.
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

# setInputs for the dynamically-suffixed inputs of one panel. Backtick/glue
# names like `r_name_{rid}` are NOT interpolated by setInputs, so build the
# names with paste0 + setNames + do.call.
set_panel_inputs <- function(session, rid, ...) {
  vals <- list(...)
  names(vals) <- paste0("r_", names(vals), "_", rid)
  do.call(session$setInputs, vals)
}

test_that("adding + saving a response builds r_d (-) and gb_r (+) and persists", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    isa_data$goods_benefits <- data.frame(ID = c("GB001","GB002"), Name = c("Food","Tourism"),
                                           stringsAsFactors = FALSE)
    isa_data$drivers <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)

    session$setInputs(add_response = 1)
    rid <- isa_data$r_panel_ids[[1]]
    set_panel_inputs(session, rid, name = "MSP", linkedgb = "GB002", linkedd = "D001")
    session$setInputs(save_responses = 1)

    expect_equal(nrow(isa_data$responses), 1L)
    expect_true(grepl("^R[0-9]{3}$", isa_data$responses$ID[1]))
    expect_equal(isa_data$adjacency_matrices$r_d["R001","D001"], "-medium:3")
    expect_equal(dim(isa_data$adjacency_matrices$gb_r), c(2L, 1L))
    expect_equal(isa_data$adjacency_matrices$gb_r["GB002","R001"], "+medium:3")
    expect_equal(nrow(pd()$data$isa_data$responses), 1L)
  })
})

test_that("import re-derives responses Linked* from Matrix_* so a re-save reproduces edges", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server,
             args = list(project_data_reactive = pd, i18n = list(t = function(x, ...) x)), {
    saved <- list(
      goods_benefits = data.frame(ID = c("GB001","GB002"), Name = c("Food","Tourism"), stringsAsFactors = FALSE),
      drivers   = data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE),
      responses = data.frame(ID = "R001", Name = "MSP", stringsAsFactors = FALSE),  # no Linked* cols
      adjacency_matrices = list(
        r_d  = matrix("-medium:3", 1, 1, dimnames = list("R001","D001")),
        gb_r = matrix(c("","+medium:3"), 2, 1, dimnames = list(c("GB001","GB002"),"R001"))
      )
    )
    apply_saved_isa(saved)
    expect_equal(isa_data$responses$LinkedD[1], "D001")
    expect_equal(isa_data$responses$LinkedGB[1], "GB002")
  })
})
