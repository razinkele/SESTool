# Standard Entry and LinkedX recovery ask for new links' signs (evidenced polarity, Task 6)
source_for_test(c("functions/data_structure.R",
                  "functions/polarity_evidence.R",
                  "functions/matrix_from_linked.R",
                  "functions/standard_entry_excel_import.R",
                  "functions/isa_form_builders.R",
                  "modules/sign_choice_module.R",
                  "modules/isa_data_entry_module.R"))
isa_data_entry_server <- get("isa_data_entry_server", envir = .GlobalEnv)

se_i18n <- list(t = function(x, ...) x)

test_that("a new declared cell is written only with a chosen sign", {
  df <- data.frame(ID = "D1", LinkedA = "A1|A2", Confidence = "3")
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"), chosen_signs = c("D1|A1" = "-"))
  expect_equal(r$matrix["D1", "A1"], "-medium:3")
  expect_equal(r$matrix["D1", "A2"], "")
  expect_equal(r$unsigned_links[, c("src_id", "tgt_id")], data.frame(src_id = "D1", tgt_id = "A2"))
  expect_equal(r$unsigned_links$linked_col, "LinkedA")
  expect_equal(r$unsigned_links$suffix, "medium:3")
  expect_false(r$unsigned_links$transposed)
})

test_that("existing cells keep their sign and are never reported unsigned", {
  ex <- matrix(c("-strong:4", ""), 1, dimnames = list("D1", c("A1", "A2")))
  df <- data.frame(ID = "D1", LinkedA = "A1", Confidence = "3")
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"), existing_matrix = ex)
  expect_equal(substr(r$matrix["D1", "A1"], 1, 1), "-"); expect_equal(nrow(r$unsigned_links), 0)
})

test_that("an existing cell without a sign is blanked and reported, never kept", {
  ex <- matrix("medium:3", 1, dimnames = list("D1", "A1"))
  df <- data.frame(ID = "D1", LinkedA = "A1", Confidence = "3")
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", "A1", existing_matrix = ex)
  expect_equal(r$matrix["D1", "A1"], "")
  expect_equal(nrow(r$unsigned_links), 1)
})

test_that("rebuild_forward_matrix_by_name writes only chosen signs and reports the rest", {
  src <- data.frame(ID = "P1", Name = "Overfishing", LinkedMPF = "M1: Fish|M2: Seagrass",
                    stringsAsFactors = FALSE)
  tgt <- data.frame(ID = c("M1", "M2"), Name = c("Fish", "Seagrass"), stringsAsFactors = FALSE)
  m <- rebuild_forward_matrix_by_name(src, "LinkedMPF", tgt, chosen_signs = c("P1|M2" = "-"))
  expect_equal(m["P1", "M1"], "")
  expect_equal(m["P1", "M2"], "-medium:3")
  ul <- attr(m, "unsigned_links")
  expect_equal(ul$src_id, "P1"); expect_equal(ul$tgt_id, "M1")
})

gb_r_isa <- function() {
  list(
    goods_benefits = data.frame(ID = "GB1", Name = "Food", stringsAsFactors = FALSE),
    responses = data.frame(ID = "R1", Name = "MPA", LinkedGB = "GB1", LinkedD = "",
                           stringsAsFactors = FALSE),
    drivers = data.frame(ID = "D1", Name = "Demand", stringsAsFactors = FALSE),
    adjacency_matrices = list(), user_edited_matrices = list()
  )
}

test_that("gb_r unsigned links are transposed and apply to the stored orientation", {
  out <- build_response_matrices(gb_r_isa())
  ul <- out$unsigned_links
  expect_equal(nrow(ul), 1)
  expect_equal(ul$matrix_key, "gb_r")
  expect_true(ul$transposed)
  expect_equal(ul$src_id, "R1"); expect_equal(ul$tgt_id, "GB1")
  expect_equal(out$adjacency_matrices$gb_r["GB1", "R1"], "")
  am <- apply_chosen_signs(out$adjacency_matrices, ul, signs = c("R1|GB1" = "+"))
  expect_equal(am$gb_r["GB1", "R1"], "+medium:3")
})

test_that("apply_chosen_signs writes only links that have a sign", {
  am <- list(d_a = matrix("", 1, 2, dimnames = list("D1", c("A1", "A2"))))
  links <- data.frame(matrix_key = "d_a", src_id = "D1", tgt_id = c("A1", "A2"),
                      linked_col = "LinkedA", suffix = "medium:3", transposed = FALSE,
                      stringsAsFactors = FALSE)
  am2 <- apply_chosen_signs(am, links, c("D1|A2" = "-"))
  expect_equal(am2$d_a["D1", "A1"], "")
  expect_equal(am2$d_a["D1", "A2"], "-medium:3")
})

test_that("untick_linked removes only that target", {
  df <- data.frame(ID = c("D1", "D2"), LinkedA = c("A1|A2", "A2"))
  expect_equal(untick_linked(df, "D1", "LinkedA", "A2")$LinkedA, c(serialize_linked("A1"), "A2"))
})

test_that("untick_linked removes a label-form segment resolved by name", {
  df <- data.frame(ID = "D1", LinkedA = "A9: Fishing|A2: Tourism", stringsAsFactors = FALSE)
  tgt <- data.frame(ID = c("A1", "A2"), Name = c("Fishing", "Tourism"), stringsAsFactors = FALSE)
  expect_equal(untick_linked(df, "D1", "LinkedA", "A1", target_df = tgt)$LinkedA, "A2: Tourism")
})

test_that("rule-default helpers are gone", {
  expect_false(exists("default_polarity_for_matrix"))
})

linked_only_saved <- function() {
  list(
    drivers = data.frame(ID = "D001", Name = "Demand", LinkedA = "A001: Fishing|A002: Tourism",
                         stringsAsFactors = FALSE),
    activities = data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                            stringsAsFactors = FALSE),
    adjacency_matrices = list(d_a = matrix("", 1, 2, dimnames = list("D001", c("A001", "A002"))))
  )
}

test_that("recovering a LinkedX-only workbook asks for signs", {
  rec <- recover_isa_data(linked_only_saved())
  expect_equal(nrow(rec$unsigned_links), 2)
  expect_equal(unique(rec$unsigned_links$matrix_key), "d_a")
  expect_true(all(rec$adjacency_matrices$d_a == ""))
  expect_false(isTRUE(rec$fell_back))
  # a cancel unticks them; a second recovery then has nothing to ask
  saved <- linked_only_saved()
  for (k in seq_len(nrow(rec$unsigned_links))) {
    saved$drivers <- untick_linked(saved$drivers, rec$unsigned_links$src_id[k], "LinkedA",
                                   rec$unsigned_links$tgt_id[k], target_df = saved$activities)
  }
  expect_equal(nrow(recover_isa_data(saved)$unsigned_links), 0)
})

test_that("sign_choice_server confirms only when every row is signed", {
  links <- data.frame(matrix_key = "d_a", src_id = "D1", tgt_id = c("A1", "A2"),
                      linked_col = "LinkedA", suffix = "medium:3", transposed = FALSE,
                      stringsAsFactors = FALSE)
  got <- "untouched"
  testServer(sign_choice_server, args = list(i18n = se_i18n), {
    res <- session$returned
    res$open(links, c(D1 = "Demand", A1 = "Fishing", A2 = "Tourism"), function(s) got <<- s)
    ids <- res$pending()$input_ids
    expect_length(ids, 2)
    do.call(session$setInputs, setNames(list("-"), ids[1]))
    session$setInputs(confirm = 1)
    expect_identical(got, "untouched")              # one row still unsigned
    do.call(session$setInputs, setNames(list("+"), ids[2]))
    session$setInputs(confirm = 2)
    expect_equal(got, c("D1|A1" = "-", "D1|A2" = "+"))
    expect_null(res$pending())
    # a second open uses fresh inputs (earlier picks are not inherited)
    res$open(links[1, ], c(), function(s) got <<- s)
    ids2 <- res$pending()$input_ids
    expect_false(any(ids2 %in% ids))
    session$setInputs(cancel = 1)
    expect_null(got)
  })
})

test_that("Standard Entry: second save with no new ticks opens no dialog; cancel unticks", {
  calls <- list()
  fake <- function(id, i18n) {
    list(open = function(links, labels, on_done) {
      calls[[length(calls) + 1]] <<- list(links = links, labels = labels, on_done = on_done)
    }, pending = function() NULL)
  }
  real <- get("sign_choice_server", envir = .GlobalEnv)
  assign("sign_choice_server", fake, envir = .GlobalEnv)
  on.exit(assign("sign_choice_server", real, envir = .GlobalEnv), add = TRUE)

  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")   # first flush: load observer runs once
    isa_data$activities <- data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                                      stringsAsFactors = FALSE)
    session$setInputs(add_d = 1)
    did <- isa_data$d_panel_ids[[1]]
    do.call(session$setInputs, setNames(list("Demand", "A002: Tourism"),
                                        paste0(c("d_name_", "d_linkeda_"), did)))
    session$setInputs(save_ex5 = 1)
    expect_length(calls, 1)
    expect_equal(nrow(calls[[1]]$links), 1)
    expect_equal(calls[[1]]$links$tgt_id, "A002")
    expect_equal(calls[[1]]$links$matrix_key, "d_a")
    expect_equal(unname(calls[[1]]$labels["A002"]), "Tourism")
    expect_equal(isa_data$adjacency_matrices$d_a[did, "A002"], "")
    calls[[1]]$on_done(NULL)
    expect_false("A002" %in% parse_linked(isa_data$drivers$LinkedA[1]))
    expect_false("A002" %in% parse_linked(pd()$data$isa_data$drivers$LinkedA[1]))
    # the live select was unticked too; mirror it (testServer does not echo updates)
    do.call(session$setInputs, setNames(list(""), paste0("d_linkeda_", did)))
    session$setInputs(save_ex5 = 2)
    expect_length(calls, 1)
  })
})

test_that("Standard Entry: confirming the dialog writes the chosen sign and syncs", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$activities <- data.frame(ID = "A001", Name = "Fishing", stringsAsFactors = FALSE)
    session$setInputs(add_d = 1)
    did <- isa_data$d_panel_ids[[1]]
    do.call(session$setInputs, setNames(list("Demand", "A001: Fishing"),
                                        paste0(c("d_name_", "d_linkeda_"), did)))
    session$setInputs(save_ex5 = 1)
    ids <- sign_choice$pending()$input_ids
    expect_length(ids, 1)
    do.call(session$setInputs, setNames(list("-"), paste0("sign_choice-", ids)))
    session$setInputs(`sign_choice-confirm` = 1)
    expect_equal(isa_data$adjacency_matrices$d_a[did, "A001"], "-medium:3")
    expect_equal(pd()$data$isa_data$adjacency_matrices$d_a[did, "A001"], "-medium:3")
  })
})

test_that("loop builder effect starts unset", {
  src <- readLines(test_path("../../modules/isa_data_entry_module.R"), warn = FALSE)
  at <- grep('selectInput(ns("loop_effect")', src, fixed = TRUE)
  expect_length(at, 1)
  expect_true(grepl('setNames(c("", "+", "-")', src[at + 1], fixed = TRUE))
  # and the add-loop handler refuses an unset effect
  expect_true(any(grepl('req(input$loop_effect %in% c("+", "-"))', src, fixed = TRUE)))
})
