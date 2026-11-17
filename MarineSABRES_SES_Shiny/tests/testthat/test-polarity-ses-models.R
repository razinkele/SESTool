# SES Models library: unsigned rows are left out, counted and reported
# (final review I2, ruling R8). Three shipped models carry rows whose Label is
# "directed" or empty; the fixture mimics that shape.
source_for_test("functions/excel_import_helpers.R")
source_for_test("modules/ses_models_module.R")
import_ses_model_data <- get("import_ses_model_data", envir = .GlobalEnv)

sm_i18n <- list(t = function(key, ...) switch(key,
  "common.polarity.model_left_out_unsigned" = "%d left out of the model",
  "common.polarity.model_not_loaded_unsigned" = "model not loaded: %d unsigned",
  key))
sm_model <- function(labels) {
  list(
    file_name = "fixture.xlsx",
    elements = data.frame(
      Label = c("Demand", "Fishing", "Pollution", "Fish stock"),
      type = c("Driver", "Activity", "Pressure", "Marine Process and Function"),
      stringsAsFactors = FALSE),
    connections = data.frame(
      From = c("Demand", "Fishing", "Pollution"),
      To = c("Fishing", "Pollution", "Fish stock"),
      Label = labels, stringsAsFactors = FALSE)
  )
}
sm_cells <- function(isa) {
  unlist(lapply(isa$adjacency_matrices, function(m) m[!is.na(m) & m != ""]))
}
# Capture notifications: the module calls showNotification unqualified, so a
# GlobalEnv binding shadows shiny's; any earlier binding is restored.
sm_capture_toasts <- function(env = parent.frame()) {
  toasts <- new.env(); toasts$msgs <- character()
  had <- exists("showNotification", envir = .GlobalEnv, inherits = FALSE)
  old <- if (had) get("showNotification", envir = .GlobalEnv) else NULL
  assign("showNotification", function(ui, ...) toasts$msgs <- c(toasts$msgs, paste(as.character(ui), collapse = " ")),
         envir = .GlobalEnv)
  withr::defer({
    if (had) assign("showNotification", old, envir = .GlobalEnv)
    else rm("showNotification", envir = .GlobalEnv)
  }, envir = env)
  toasts
}

test_that("a partly unsigned model loads its signed rows, counts only those and warns", {
  toasts <- sm_capture_toasts()
  pdr <- shiny::reactiveVal(init_session_data())
  shiny::isolate(import_ses_model_data(sm_model(c("+", "directed", NA)), pdr, NULL, NULL, sm_i18n))
  isa <- shiny::isolate(pdr())$data$isa_data
  cells <- sm_cells(isa)
  expect_length(cells, 1)
  expect_true(startsWith(unname(cells), "+"))
  expect_null(isa$unsigned)
  expect_true("2 left out of the model" %in% toasts$msgs)
  success <- toasts$msgs[grepl("modules.ses_models.load_success", toasts$msgs, fixed = TRUE)]
  expect_length(success, 1)
  # the success toast counts the written connections (cells), not the file rows
  expect_match(success, paste("modules.ses_models.elements_and", length(cells),
                              "modules.ses_models.connections_imported"), fixed = TRUE)
})

test_that("a fully unsigned model is not loaded and the project stays untouched", {
  toasts <- sm_capture_toasts()
  pdr <- shiny::reactiveVal(init_session_data())
  before <- shiny::isolate(pdr())
  shiny::isolate(import_ses_model_data(sm_model(c("directed", "directed", "directed")), pdr, NULL, NULL, sm_i18n))
  expect_identical(shiny::isolate(pdr()), before)
  expect_true("model not loaded: 3 unsigned" %in% toasts$msgs)
  expect_false(any(grepl("modules.ses_models.load_success", toasts$msgs, fixed = TRUE)))
})

test_that("a fully signed model loads every row without a warning", {
  toasts <- sm_capture_toasts()
  pdr <- shiny::reactiveVal(init_session_data())
  shiny::isolate(import_ses_model_data(sm_model(c("+", "-", "+")), pdr, NULL, NULL, sm_i18n))
  expect_length(sm_cells(shiny::isolate(pdr())$data$isa_data), 3)
  expect_false(any(grepl("left out", toasts$msgs, fixed = TRUE)))
})
