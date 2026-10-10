# tests/testthat/test-autosave-ml-session.R
# Review 2026-10-07 autosave / ML / session batch: N29, N40, N53, N54, N55, N58, N59, N60.
source_for_test(c("functions/ml_feedback_logger.R", "functions/ml_response_bandit.R",
                  "functions/persistent_storage.R", "server/language_handling.R"))

proj_file <- function(...) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, ...); if (file.exists(p)) return(p)
  }
  stop("not found")
}
src_of <- function(...) paste(readLines(proj_file(...), warn = FALSE), collapse = "\n")

with_temp_feedback_log <- function(code) {
  d <- tempfile("fb"); dir.create(d)
  old <- list(rds = get("FEEDBACK_LOG_FILE", .GlobalEnv), csv = get("FEEDBACK_CSV_FILE", .GlobalEnv))
  assign("FEEDBACK_LOG_FILE", file.path(d, "log.rds"), .GlobalEnv)
  assign("FEEDBACK_CSV_FILE", file.path(d, "log.csv"), .GlobalEnv)
  .feedback_cache$data <- NULL; .feedback_cache$mtime <- NULL
  on.exit({
    assign("FEEDBACK_LOG_FILE", old$rds, .GlobalEnv); assign("FEEDBACK_CSV_FILE", old$csv, .GlobalEnv)
    .feedback_cache$data <- NULL; .feedback_cache$mtime <- NULL
    unlink(d, recursive = TRUE)
  })
  force(code)
  invisible(d)
}

clf_pred <- list(primary = list(type = "Pressures", confidence = 0.8))

# ---- N40 / N59 -------------------------------------------------------------
test_that("N40: a classification and a connection entry can both be logged", {
  with_temp_feedback_log({
    log_classification_feedback("Bycatch", clf_pred, "accepted", "Pressures", session_id = "s1")
    log_connection_feedback(list(name = "Fishing", type = "Activities"),
                            list(name = "Bycatch", type = "Pressures"),
                            list(existence_probability = 0.9, strength = "medium", confidence = 3, polarity = "+"),
                            "accepted", session_id = "s1")
    log <- readRDS(FEEDBACK_LOG_FILE)
    expect_equal(nrow(log), 2L)
    expect_setequal(log$prediction_type, c("classification", "connection"))
    expect_true(all(c("uncertainty_score", "was_reviewed") %in% names(log)))
  })
})

test_that("N40: append_feedback_entry aligns columns in both directions", {
  a <- data.frame(x = 1, y = "a", stringsAsFactors = FALSE)
  b <- data.frame(x = 2, z = TRUE, stringsAsFactors = FALSE)
  r <- append_feedback_entry(a, b)
  expect_equal(names(r), c("x", "y", "z"))
  expect_equal(nrow(r), 2L)
  expect_true(is.na(r$y[2]) && is.na(r$z[1]))
  expect_identical(append_feedback_entry(NULL, b), b)
})

test_that("N59: user_id no longer records the server OS account", {
  with_temp_feedback_log({
    e <- log_classification_feedback("X", clf_pred, "accepted", "Pressures")
    expect_true(is.na(e$user_id))
  })
  code_only <- gsub("#[^\n]*", "", src_of("functions/ml_feedback_logger.R"))
  expect_false(grepl('Sys.info()["user"]', code_only, fixed = TRUE))
})

test_that("N40: the creator module only thanks/counts when the feedback was stored", {
  s <- src_of("modules/graphical_ses_creator_module.R")
  guard <- regexpr("if (!logged) {", s, fixed = TRUE)
  counter <- regexpr("rv$ml_feedback_count <- rv$ml_feedback_count + 1", s, fixed = TRUE)
  expect_true(guard > 0 && guard < counter)
})

# ---- N58 -------------------------------------------------------------------
test_that("N58: a truncated feedback log is moved aside and logging recovers", {
  with_temp_feedback_log({
    writeBin(as.raw(c(0x1f, 0x8b, 0x08, 0x00)), FEEDBACK_LOG_FILE)    # truncated gzip
    expect_no_error(log_classification_feedback("X", clf_pred, "accepted", "Pressures"))
    expect_equal(nrow(readRDS(FEEDBACK_LOG_FILE)), 1L)
    expect_length(list.files(dirname(FEEDBACK_LOG_FILE), pattern = "corrupt"), 1L)
    expect_length(list.files(dirname(FEEDBACK_LOG_FILE), pattern = "[.]tmp"), 0L)
  })
})

# ---- N53 -------------------------------------------------------------------
test_that("N53: bandit context is read from the real project paths", {
  pd <- list(data = list(
    isa_data = list(drivers = data.frame(ID = c("D1", "D2")), activities = data.frame(ID = "A1"),
                    adjacency_matrices = list(d_a = matrix(c("+medium:3", ""), 2, 1))),
    metadata = list(regional_sea = "baltic"),
    cld = list(edges = data.frame(from = c("D1", "D2", "A1"), to = c("A1", "A1", "D1")))
  ))
  pd$data$isa_data$metadata <- list(main_issue = "eutrophication")
  ctx <- project_bandit_context(pd)
  expect_equal(ctx$n_elements, 3L)
  expect_equal(ctx$n_connections, 3L)
  expect_identical(ctx$regional_sea, "baltic")
  expect_identical(ctx$main_issue, "eutrophication")
  # no CLD: fall back to non-empty matrix cells
  pd$data$cld <- NULL
  expect_equal(project_bandit_context(pd)$n_connections, 1L)
  empty <- project_bandit_context(NULL)
  expect_equal(empty$n_elements, 0L)
  expect_identical(empty$regional_sea, "other")
  expect_false(grepl("pd$isa_data", src_of("modules/response_module.R"), fixed = TRUE))
})

# ---- N54 / N55 -------------------------------------------------------------
test_that("N54: old local autosaves are pruned, recent ones kept", {
  d <- tempfile("as"); dir.create(d); on.exit(unlink(d, recursive = TRUE))
  old <- file.path(d, "autosave_old.rds"); new <- file.path(d, "autosave_new.rds")
  other <- file.path(d, "keep_me.rds")
  for (f in c(old, new, other)) saveRDS(1, f)
  Sys.setFileTime(old, Sys.time() - 100 * 3600)
  Sys.setFileTime(other, Sys.time() - 100 * 3600)
  expect_equal(prune_persistent_autosaves(d, max_age_hours = 72), 1L)
  expect_false(file.exists(old))
  expect_true(file.exists(new))
  expect_true(file.exists(other))
})

test_that("N54/N55: no first-load save for an empty project; hash taken before metadata", {
  s <- src_of("modules/auto_save_module.R")
  expect_true(grepl("if (!project_has_content(data)) return()", s, fixed = TRUE))
  h <- regexpr("data_hash <- digest::digest(current_data)", s, fixed = TRUE)
  m <- regexpr("current_data$autosave_metadata <- list(", s, fixed = TRUE)
  expect_true(h > 0 && h < m)
  expect_true(grepl("auto_save$last_data_hash <- data_hash", s, fixed = TRUE))
  expect_false(project_has_content(list(data = list(isa_data = list()))))
})

# ---- N60 -------------------------------------------------------------------
test_that("N60: language-change restore notifies on an invalid payload", {
  notes <- list()
  local_mocked_bindings(showNotification = function(ui, ..., type = "default") {
    notes[[length(notes) + 1]] <<- list(ui = paste(as.character(ui), collapse = ""), type = type)
    invisible(NULL)
  }, .package = "shiny")
  i18n <- list(t = function(k, ...) k)
  srv <- function(input, output, session) {
    pd <- shiny::reactiveVal(NULL)
    setup_language_restore_handler(input, pd, i18n)
    session$userData$pd <- pd
  }
  shiny::testServer(srv, {
    session$setInputs(restore_project_data_from_lang_change = "warm-up")   # may be swallowed by ignoreInit
    notes <<- list()
    session$setInputs(restore_project_data_from_lang_change = "{not json")
    expect_null(session$userData$pd())
    expect_true(any(vapply(notes, function(n) identical(n$type, "error"), logical(1))))
  })
  expect_true(grepl("setup_language_restore_handler(input, project_data, session_i18n)", src_of("app.R"), fixed = TRUE))
  expect_false(grepl("observeEvent(input$restore_project_data_from_lang_change", src_of("app.R"), fixed = TRUE))
})

# ---- N29 -------------------------------------------------------------------
test_that("N29: feature-module load failures stop startup; the loaded list is tracked locally", {
  a <- src_of("app.R")
  expect_false(grepl("These features will be unavailable", a, fixed = TRUE))
  expect_true(grepl("Failed to load %d feature module(s)", a, fixed = TRUE))
  expect_false(grepl("LOADED_OPTIONAL_MODULES <<-", a, fixed = TRUE))
  expect_true(grepl('if (exists("feedback_admin_server", mode = "function")) {', a, fixed = TRUE))
})
