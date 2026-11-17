# Excel/Kumu import keeps file signs and asks for the rest (evidenced polarity, Task 5)
source_for_test("functions/excel_import_helpers.R")
source_for_test("functions/isa_export_helpers.R")
source_for_test("modules/connection_review_tabbed.R")
source_for_test("modules/import_data_module.R")
import_data_server <- get("import_data_server", envir = .GlobalEnv)
import_label_polarity <- get("import_label_polarity", envir = .GlobalEnv)
convert_excel_to_isa <- get("convert_excel_to_isa", envir = .GlobalEnv)

pi_i18n <- list(t = function(key, ...) switch(key,
  "common.polarity.direct_import_blocked" = "%d connections in the file have no sign.",
  key))
pi_elements <- data.frame(Label = c("Demand", "Fishing", "Pollution"),
                          type = c("Driver", "Activity", "Pressure"),
                          stringsAsFactors = FALSE)
pi_cells <- function(res) {
  unlist(lapply(res$adjacency_matrices, function(m) m[m != ""]))
}

test_that("import_label_polarity reads only a leading sign", {
  expect_equal(import_label_polarity(c("+", "-strong", " -", "+medium:3")), c("+", "-", "-", "+"))
  expect_identical(import_label_polarity(c(NA, "", "medium:3", "x", "1", "negative")),
                   rep(NA_character_, 6))
})

test_that("conversion writes no cell for an unsigned row and reports it", {
  res <- convert_excel_to_isa(pi_elements,
    data.frame(From = c("Demand", "Fishing"), To = c("Fishing", "Pollution"),
               Label = c("+", ""), stringsAsFactors = FALSE))
  expect_equal(nrow(res$unsigned), 1)
  expect_equal(res$unsigned$From, "Fishing")
  expect_equal(res$unsigned$To, "Pollution")
  cells <- pi_cells(res)
  expect_length(cells, 1)
  expect_true(startsWith(unname(cells), "+"))
})

test_that("conversion reports no unsigned rows when all carry a sign", {
  res <- convert_excel_to_isa(pi_elements,
    data.frame(From = "Demand", To = "Fishing", Label = "-", stringsAsFactors = FALSE))
  expect_equal(nrow(res$unsigned), 0)
  expect_true(startsWith(unname(pi_cells(res)), "-"))
})

pi_load <- function(rv) {
  rv$elements_data <- pi_elements
  rv$connections_data <- data.frame(
    From = c("Demand", "Fishing"), To = c("Fishing", "Pollution"),
    Label = c("", "+"), stringsAsFactors = FALSE)
  rv$file_loaded <- TRUE
}

test_that("a sign amended in the import review survives finalize", {
  pdr <- reactiveVal(init_session_data())
  testServer(import_data_server,
    args = list(project_data_reactive = pdr, i18n = pi_i18n, parent_session = NULL, event_bus = NULL), {
      pi_load(rv)
      session$setInputs(review_btn = 1)
      session$flushReact()
      expect_true(is.na(rv$parsed_connections[[1]]$polarity))
      expect_equal(rv$parsed_connections[[2]]$polarity, "+")
      session$setInputs(`conn_review-polarity_pick_1` = "-", `conn_review-approve_1` = 1,
                        `conn_review-approve_2` = 1)
      session$setInputs(finalize_import_btn = 1)
      session$flushReact()
      mats <- pdr()$data$isa_data$adjacency_matrices
      cells <- unlist(lapply(mats, function(m) m[m != ""]))
      expect_length(cells, 2)
      expect_setequal(substr(cells, 1, 1), c("+", "-"))
      expect_null(pdr()$data$isa_data$unsigned)
  })
})

test_that("direct import is blocked when a row has no sign", {
  pdr <- reactiveVal(init_session_data())
  testServer(import_data_server,
    args = list(project_data_reactive = pdr, i18n = pi_i18n, parent_session = NULL, event_bus = NULL), {
      pi_load(rv)
      session$setInputs(import_direct_btn = 1)
      session$flushReact()
      gb <- pdr()$data$isa_data
      expect_null(gb$adjacency_matrices)
      expect_false(isTRUE(rv$import_success))
  })
})

test_that("direct import goes ahead when every row has a sign", {
  pdr <- reactiveVal(init_session_data())
  testServer(import_data_server,
    args = list(project_data_reactive = pdr, i18n = pi_i18n, parent_session = NULL, event_bus = NULL), {
      pi_load(rv)
      rv$connections_data$Label <- c("-", "+")
      session$setInputs(import_direct_btn = 1)
      session$flushReact()
      cells <- unlist(lapply(pdr()$data$isa_data$adjacency_matrices, function(m) m[m != ""]))
      expect_setequal(substr(cells, 1, 1), c("+", "-"))
  })
})
