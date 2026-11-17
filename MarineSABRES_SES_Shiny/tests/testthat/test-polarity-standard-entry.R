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

# --- Standard Entry behaviour tests ------------------------------------------
# Stubs bound in .GlobalEnv (where the module's free names resolve) for the
# duration of the calling test:
#  - stub_sign_opener(): a fake sign_choice_server recording open() calls
#  - stub_select_updates(): records updateSelectInput(selected = ...) calls
#  - stub_notifications(): records showNotification() texts
stub_global <- function(name, value, env = parent.frame()) {
  had <- exists(name, envir = .GlobalEnv, inherits = FALSE)
  old <- if (had) get(name, envir = .GlobalEnv) else NULL
  assign(name, value, envir = .GlobalEnv)
  withr::defer(if (had) assign(name, old, envir = .GlobalEnv) else rm(list = name, envir = .GlobalEnv),
               envir = env)
}
stub_sign_opener <- function(env = parent.frame()) {
  rec <- new.env(); rec$calls <- list()
  stub_global("sign_choice_server", function(id, i18n) {
    list(open = function(links, labels, on_done) {
      rec$calls[[length(rec$calls) + 1]] <- list(links = links, labels = labels, on_done = on_done)
    }, pending = function() NULL)
  }, env)
  rec
}
stub_select_updates <- function(env = parent.frame()) {
  rec <- new.env(); rec$sent <- list()
  real <- shiny::updateSelectInput
  stub_global("updateSelectInput", function(session, inputId, label = NULL, choices = NULL, selected = NULL) {
    rec$sent[[length(rec$sent) + 1]] <- list(id = inputId, selected = selected)
    real(session, inputId, label = label, choices = choices, selected = selected)
  }, env)
  rec
}
stub_notifications <- function(env = parent.frame()) {
  rec <- new.env(); rec$texts <- character(0)
  real <- shiny::showNotification
  stub_global("showNotification", function(ui, ...) {
    rec$texts <- c(rec$texts, paste(as.character(ui), collapse = " "))
    real(ui, ...)
  }, env)
  rec
}
last_update_for <- function(rec, id) {
  hits <- Filter(function(s) identical(s$id, id), rec$sent)
  if (length(hits) == 0) return(NULL)
  hits[[length(hits)]]$selected
}

test_that("Standard Entry: second save with no new ticks opens no dialog; cancel unticks", {
  op <- stub_sign_opener()
  upd <- stub_select_updates()
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")   # first flush: load observer runs once
    isa_data$activities <- data.frame(ID = c("A001", "A002"), Name = c("Fishing", "Tourism"),
                                      stringsAsFactors = FALSE)
    session$setInputs(add_d = 1)
    did <- isa_data$d_panel_ids[[1]]
    sel_id <- paste0("d_linkeda_", did)
    do.call(session$setInputs, setNames(list("Demand", "A002: Tourism"),
                                        c(paste0("d_name_", did), sel_id)))
    session$setInputs(save_ex5 = 1)
    expect_length(op$calls, 1)
    expect_equal(nrow(op$calls[[1]]$links), 1)
    expect_equal(op$calls[[1]]$links$tgt_id, "A002")
    expect_equal(op$calls[[1]]$links$matrix_key, "d_a")
    expect_equal(unname(op$calls[[1]]$labels["A002"]), "Tourism")
    expect_equal(isa_data$adjacency_matrices$d_a[did, "A002"], "")
    op$calls[[1]]$on_done(NULL)
    expect_false("A002" %in% parse_linked(isa_data$drivers$LinkedA[1]))
    expect_false("A002" %in% parse_linked(pd()$data$isa_data$drivers$LinkedA[1]))
    # the module told the live select to drop the tick; feed that update back
    # (testServer does not echo updateSelectInput into input)
    sent <- last_update_for(upd, sel_id)
    expect_equal(sent, "")
    do.call(session$setInputs, setNames(list(sent), sel_id))
    session$setInputs(save_ex5 = 2)
    expect_length(op$calls, 1)
  })
})

test_that("Standard Entry: cancelling several links of one element unticks them all in one select update", {
  op <- stub_sign_opener()
  upd <- stub_select_updates()
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$activities <- data.frame(ID = c("A001", "A002", "A003", "A004"),
                                      Name = c("F", "T", "S", "K"), stringsAsFactors = FALSE)
    session$setInputs(add_d = 1)
    did <- isa_data$d_panel_ids[[1]]
    sel_id <- paste0("d_linkeda_", did)
    # A004 already has a signed cell (kept); A001-A003 are new
    isa_data$adjacency_matrices <- list(d_a = matrix(c("", "", "", "+strong:4"), 1, 4,
                                        dimnames = list(did, c("A001", "A002", "A003", "A004"))))
    do.call(session$setInputs, setNames(list("Demand", c("A001: F", "A002: T", "A003: S", "A004: K")),
                                        c(paste0("d_name_", did), sel_id)))
    session$setInputs(save_ex5 = 1)
    expect_equal(nrow(op$calls[[1]]$links), 3)
    op$calls[[1]]$on_done(NULL)
    expect_equal(isa_data$drivers$LinkedA[1], "A004")
    upd_for_sel <- Filter(function(s) identical(s$id, sel_id), upd$sent)
    expect_length(upd_for_sel, 1)                 # ONE update for the select
    expect_equal(upd_for_sel[[1]]$selected, "A004: K")
    expect_false(any(grepl("^A00[123]", upd_for_sel[[1]]$selected)))
  })
})

test_that("Standard Entry: a sign dialog replaced by another modal does not stop later saves asking", {
  op <- stub_sign_opener()
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$activities <- data.frame(ID = c("A001", "A002"), Name = c("F", "T"), stringsAsFactors = FALSE)
    session$setInputs(add_d = 1)
    did <- isa_data$d_panel_ids[[1]]
    do.call(session$setInputs, setNames(list("Demand", "A001: F"),
                                        paste0(c("d_name_", "d_linkeda_"), did)))
    session$setInputs(save_ex5 = 1)
    expect_length(op$calls, 1)
    # ... the dialog is replaced by another modal: its on_done never runs.
    # A later save that adds a new link asks again, and still includes the
    # unanswered one.
    do.call(session$setInputs, setNames(list(c("A001: F", "A002: T")), paste0("d_linkeda_", did)))
    session$setInputs(save_ex5 = 2)
    expect_length(op$calls, 2)
    expect_setequal(op$calls[[2]]$links$tgt_id, c("A001", "A002"))
    op$calls[[2]]$on_done(c(setNames("+", paste0(did, "|A001")), setNames("-", paste0(did, "|A002"))))
    expect_equal(isa_data$adjacency_matrices$d_a[did, "A001"], "+medium:3")
    expect_equal(isa_data$adjacency_matrices$d_a[did, "A002"], "-medium:3")
  })
})

test_that("Standard Entry: the load observer does not re-ask a link set already pending", {
  op <- stub_sign_opener()
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    saved <- linked_only_saved()
    apply_saved_isa(saved, from_load = TRUE)
    apply_saved_isa(saved, from_load = TRUE)      # observer re-run on another project write
    expect_length(op$calls, 1)
    expect_equal(nrow(op$calls[[1]]$links), 2)
  })
})

test_that("Standard Entry: the saved toast waits for the sign dialog", {
  note <- stub_notifications()
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$activities <- data.frame(ID = "A001", Name = "Fishing", stringsAsFactors = FALSE)
    session$setInputs(add_d = 1)
    did <- isa_data$d_panel_ids[[1]]
    do.call(session$setInputs, setNames(list("Demand", "A001: Fishing"),
                                        paste0(c("d_name_", "d_linkeda_"), did)))
    session$setInputs(save_ex5 = 1)
    saved_toast <- function() any(grepl("exercise_5_saved", note$texts, fixed = TRUE))
    expect_false(saved_toast())
    expect_null(pd()$data$isa_data$drivers)          # nothing committed yet
    answer_sign_dialog(session, sign_choice$pending(), setNames("-", paste0(did, "|A001")))
    expect_true(saved_toast())
    expect_equal(pd()$data$isa_data$adjacency_matrices$d_a[did, "A001"], "-medium:3")
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
    expect_null(sign_choice$pending())
    # a second save with the same ticks asks nothing and keeps the chosen sign
    session$setInputs(save_ex5 = 2)
    expect_null(sign_choice$pending())
    expect_equal(isa_data$adjacency_matrices$d_a[did, "A001"], "-medium:3")
  })
})

# A LinkedX-only Standard Entry workbook for the in-page Import button
linked_only_workbook <- function() {
  skip_if_not_installed("openxlsx")
  source_for_test("functions/isa_export_helpers.R")
  isa <- list(
    goods_benefits = data.frame(ID = "GB001", Name = "Food", Type = "", Description = "",
                                Stakeholder = "", Importance = "", Trend = "", stringsAsFactors = FALSE),
    ecosystem_services = data.frame(ID = "ES001", Name = "Fish", Type = "", Description = "",
                                    LinkedGB = "GB001: Food", Mechanism = "", Confidence = "High",
                                    stringsAsFactors = FALSE),
    marine_processes = data.frame(ID = character(), Name = character()),
    pressures = data.frame(ID = character(), Name = character()),
    activities = data.frame(ID = character(), Name = character()),
    drivers = data.frame(ID = character(), Name = character()))
  wb <- openxlsx::createWorkbook(); write_isa_element_sheets(wb, isa, include_adjacency = FALSE)
  f <- tempfile(fileext = ".xlsx"); openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
  f
}

for (answer in c("confirm", "cancel")) local({
  answer <- answer
  test_that(paste("in-page import waits for the sign dialog before its result toast:", answer), {
    f <- linked_only_workbook()
    note <- stub_notifications()
    testServer(isa_data_entry_server,
               args = list(project_data_reactive = reactiveVal(init_session_data()),
                           i18n = se_i18n, parent_session = NULL), {
      session$setInputs(import_file = data.frame(name = "x.xlsx", size = 1, type = "",
                                                 datapath = f, stringsAsFactors = FALSE))
      session$setInputs(import_data = 1)
      session$flushReact()
      has <- function(key) any(grepl(key, note$texts, fixed = TRUE))
      p <- sign_choice$pending()
      expect_equal(p$keys, "ES001|GB001")
      expect_false(has("import_success"))
      expect_false(has("import_no_connections"))
      if (answer == "confirm") {
        answer_sign_dialog(session, p, c("ES001|GB001" = "+"))
        expect_true(has("import_success"))
        expect_false(has("import_no_connections"))
        expect_equal(isa_data$adjacency_matrices$es_gb["ES001", "GB001"], "+medium:5")
      } else {
        answer_sign_dialog(session, p, NULL)
        expect_true(has("import_no_connections"))   # nothing left: edgeless guard
        expect_false(has("import_success"))
        expect_equal(isa_data$ecosystem_services$LinkedGB[1], "")
      }
    })
  })
})

test_that("loop builder: an unset effect adds no loop; a chosen one does", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$drivers <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)
    isa_data$goods_benefits <- data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE)
    n0 <- NROW(isa_data$loop_connections)
    session$setInputs(loop_driver = "D001", loop_gb = "GB001", loop_effect = "",
                      loop_strength = "medium", loop_confidence = 3)
    session$setInputs(add_loop = 1)
    expect_equal(NROW(isa_data$loop_connections), n0)
    session$setInputs(loop_effect = "-")
    session$setInputs(add_loop = 2)
    expect_equal(NROW(isa_data$loop_connections), n0 + 1)
    expect_equal(as.character(isa_data$loop_connections$Effect[n0 + 1]), "-")
  })
})

test_that("a user-edited cell without a sign is blanked and reported, never kept unsigned", {
  ex <- matrix(c("strong:4", "medium:2"), 1, dimnames = list("D1", c("A1", "A2")))
  ue <- matrix(TRUE, 1, 2, dimnames = dimnames(ex))
  df <- data.frame(ID = "D1", LinkedA = "A1", Confidence = "3")   # A2 edited but not ticked
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"),
                                  existing_matrix = ex, user_edited_matrix = ue)
  expect_equal(unname(r$matrix["D1", ]), c("", ""))
  expect_setequal(r$unsigned_links$tgt_id, c("A1", "A2"))
  expect_equal(r$unsigned_links$suffix[r$unsigned_links$tgt_id == "A1"], "strong:4")  # keeps its own suffix
  r2 <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"),
                                   existing_matrix = ex, user_edited_matrix = ue,
                                   chosen_signs = c("D1|A1" = "-"))
  expect_equal(r2$matrix["D1", "A1"], "-strong:4")
})

test_that("a blanked unsigned user-edited cell loses its user-edited flag, so a ticked link stays reported", {
  ex <- matrix("strong:4", 1, dimnames = list("D1", "A1"))
  ue <- matrix(TRUE, 1, 1, dimnames = dimnames(ex))
  df <- data.frame(ID = "D1", LinkedA = "A1", Confidence = "3")
  r1 <- rebuild_matrix_from_linked(df, "LinkedA", "D1", "A1",
                                   existing_matrix = ex, user_edited_matrix = ue)
  expect_equal(r1$matrix["D1", "A1"], "")
  expect_false(r1$user_edited["D1", "A1"])
  # the next rebuild (dialog never answered, link still ticked) reports it again
  r2 <- rebuild_matrix_from_linked(df, "LinkedA", "D1", "A1",
                                   existing_matrix = r1$matrix, user_edited_matrix = r1$user_edited)
  expect_equal(r2$unsigned_links$tgt_id, "A1")
  expect_equal(r2$matrix["D1", "A1"], "")
})

test_that("a legacy unsigned marker in a user-edited cell is not kept as the suffix", {
  ex <- matrix(c("x", "1"), 1, dimnames = list("D1", c("A1", "A2")))
  ue <- matrix(TRUE, 1, 2, dimnames = dimnames(ex))
  df <- data.frame(ID = "D1", LinkedA = "A1|A2", Confidence = "3")
  r <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"),
                                  existing_matrix = ex, user_edited_matrix = ue)
  expect_equal(r$unsigned_links$suffix, c("medium:3", "medium:3"))
  am <- apply_chosen_signs(list(d_a = r$matrix), tag_unsigned_links(r$unsigned_links, "d_a"),
                           c("D1|A1" = "+", "D1|A2" = "-"))
  expect_equal(unname(am$d_a["D1", ]), c("+medium:3", "-medium:3"))
  r2 <- rebuild_matrix_from_linked(df, "LinkedA", "D1", c("A1", "A2"),
                                   existing_matrix = ex, user_edited_matrix = ue,
                                   chosen_signs = c("D1|A1" = "+"))
  expect_equal(r2$matrix["D1", "A1"], "+medium:3")
})

test_that("loop builder: Add with the effect unset says why (final review M4)", {
  toasts <- stub_notifications()
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$drivers <- data.frame(ID = "D001", Name = "Demand", stringsAsFactors = FALSE)
    isa_data$goods_benefits <- data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE)
    session$setInputs(loop_driver = "D001", loop_gb = "GB001", loop_effect = "",
                      loop_strength = "medium", loop_confidence = 3)
    session$setInputs(add_loop = 1)
    expect_true(any(grepl("approve_blocked", toasts$texts, fixed = TRUE)))
  })
})

test_that("Exercise 6 save writes no gb_d cell for a loop connection without a sign (final review M3)", {
  pd <- reactiveVal(list(data = list(isa_data = list())))
  testServer(isa_data_entry_server, args = list(project_data_reactive = pd, i18n = se_i18n), {
    session$setInputs(adj_matrix_select = "d_a")
    isa_data$drivers <- data.frame(ID = c("D001", "D002"), Name = c("Demand", "Jobs"), stringsAsFactors = FALSE)
    isa_data$goods_benefits <- data.frame(ID = "GB001", Name = "Food", stringsAsFactors = FALSE)
    # a legacy project / workbook Loop sheet with one empty Effect
    isa_data$loop_connections <- data.frame(
      DriverID = c("D001", "D002"), GBID = c("GB001", "GB001"), Effect = c("", "-"),
      Strength = c("medium", "strong"), Confidence = c(3, 4), Mechanism = c("", ""),
      stringsAsFactors = FALSE)
    session$setInputs(save_ex6 = 1)
    m <- isa_data$adjacency_matrices$gb_d
    expect_equal(m["GB001", "D001"], "")
    expect_equal(m["GB001", "D002"], "-strong:4")
  })
})
