# tests/testthat/test-server-autosave-recovery.R
# Review 2026-10-07 N7: on the shared server the autosave lived only in the
# per-session temp dir, which is deleted when the session ends, so recovery
# could never fire. Each browser now sends a token and the autosave is also
# kept under <root>/<token>/latest_autosave.rds.
source_for_test(c("functions/persistent_storage.R", "modules/auto_save_module.R"))

tok_a <- strrep("a1", 16)
tok_b <- strrep("b2", 16)
project_with <- function(n) list(project_id = "p", data = list(isa_data = list(
  drivers = data.frame(ID = sprintf("D%03d", seq_len(n)), Name = paste("d", seq_len(n)), stringsAsFactors = FALSE))),
  metadata = list())

# ---------------------------------------------------------------------------
# Pure helpers
# ---------------------------------------------------------------------------
test_that("valid_browser_token accepts only 32 lowercase hex chars", {
  expect_true(valid_browser_token(tok_a))
  for (bad in list(NULL, NA_character_, "abc", toupper(tok_a), paste0(tok_a, "0"), "../../etc/passwd", c(tok_a, tok_b), 42))
    expect_false(valid_browser_token(bad), info = deparse(bad))
  expect_null(server_autosave_path("../x", root = tempdir()))
})

test_that("write_server_autosave round-trips and stays inside the root", {
  root <- tempfile("srvauto_")
  p <- write_server_autosave(project_with(2), tok_a, root = root)
  expect_true(file.exists(p))
  expect_equal(basename(dirname(p)), tok_a)
  expect_equal(normalizePath(dirname(dirname(p))), normalizePath(root))
  expect_equal(nrow(readRDS(p)$data$isa_data$drivers), 2)
  write_server_autosave(project_with(3), tok_a, root = root)           # overwrite in place
  expect_equal(nrow(readRDS(p)$data$isa_data$drivers), 3)
  expect_length(list.files(dirname(p)), 1)                             # no temp files left
  if (.Platform$OS.type == "unix") expect_equal(as.character(file.mode(dirname(p))), "700")
})

test_that("prune_server_autosaves removes only stale browser directories", {
  root <- tempfile("srvauto_")
  old <- write_server_autosave(project_with(1), tok_a, root = root)
  new <- write_server_autosave(project_with(1), tok_b, root = root)
  Sys.setFileTime(old, Sys.time() - 80 * 3600)
  expect_equal(prune_server_autosaves(root, max_age_hours = 72), 1L)
  expect_false(dir.exists(dirname(old)))
  expect_true(file.exists(new))
})

test_that("project_has_content detects elements or CLD nodes", {
  expect_false(project_has_content(list(data = list(isa_data = list(drivers = data.frame())))))
  expect_true(project_has_content(project_with(1)))
  expect_true(project_has_content(list(data = list(cld = list(nodes = data.frame(id = "D_1"))))))
})

# ---------------------------------------------------------------------------
# Module behaviour (real server, internals reachable inside testServer)
# ---------------------------------------------------------------------------
with_server_mode <- function(root, code) {
  # server mode = no local persistent autosave folder
  old <- get("get_persistent_autosave_path", envir = .GlobalEnv)
  assign("get_persistent_autosave_path", function(...) NULL, envir = .GlobalEnv)
  on.exit(assign("get_persistent_autosave_path", old, envir = .GlobalEnv), add = TRUE)
  withr::with_options(list(marinesabres.server_autosave_root = root), force(code))
}
i18n_echo <- list(t = function(k, ...) k)

test_that("N7: a new session with the same browser token is offered the server copy and can recover it", {
  root <- tempfile("srvauto_")
  saved <- write_server_autosave(project_with(4), tok_a, root = root)
  with_server_mode(root, {
    server <- get("auto_save_server", envir = .GlobalEnv)
    pdr <- shiny::reactiveVal(list(project_id = "fresh", data = list(isa_data = list()), metadata = list()))
    token <- shiny::reactiveVal(NULL)
    testServer(server, args = list(project_data_reactive = pdr, i18n = i18n_echo, browser_token_reactive = token), {
      session$flushReact()
      expect_false(isTRUE(auto_save$recovery_pending))          # nothing until the token arrives
      token(tok_a); session$flushReact()
      expect_true(auto_save$recovery_pending)
      expect_equal(normalizePath(auto_save$recovery_file), normalizePath(saved))
      session$setInputs(confirm_recovery = 1)
      expect_equal(nrow(pdr()$data$isa_data$drivers), 4)
      expect_false(auto_save$recovery_pending)
    })
  })
  # The recovered project is the session's first content, so (since N54 skips
  # the empty first-load save) it is autosaved at once: the server copy now
  # holds the recovered work again rather than the pre-recovery file.
  expect_true(file.exists(saved))
  expect_equal(nrow(readRDS(saved)$data$isa_data$drivers), 4)
})

test_that("N7: discarding removes the server copy", {
  root <- tempfile("srvauto_")
  saved <- write_server_autosave(project_with(2), tok_a, root = root)
  with_server_mode(root, {
    server <- get("auto_save_server", envir = .GlobalEnv)
    pdr <- shiny::reactiveVal(list(project_id = "fresh", data = list(isa_data = list()), metadata = list()))
    testServer(server, args = list(project_data_reactive = pdr, i18n = i18n_echo,
                                   browser_token_reactive = shiny::reactiveVal(tok_a)), {
      session$flushReact()
      expect_true(auto_save$recovery_pending)
      session$setInputs(discard_recovery = 1)
      expect_false(auto_save$recovery_pending)
    })
  })
  expect_false(file.exists(saved))
})

test_that("N7: autosaves write the server copy only after the check and never for an empty project", {
  root <- tempfile("srvauto_")
  with_server_mode(root, {
    server <- get("auto_save_server", envir = .GlobalEnv)
    pdr <- shiny::reactiveVal(list(project_id = "p", data = list(isa_data = list()), metadata = list()))
    token <- shiny::reactiveVal(NULL)
    testServer(server, args = list(project_data_reactive = pdr, i18n = i18n_echo, browser_token_reactive = token), {
      session$flushReact()
      path <- server_autosave_path(tok_b, create = FALSE)
      perform_auto_save()
      expect_false(file.exists(path))                              # no token yet
      token(tok_b); session$flushReact()
      expect_true(auto_save$server_recovery_checked)
      perform_auto_save()
      expect_false(file.exists(path))                              # empty project: not written
      pdr(project_with(3)); session$flushReact()
      perform_auto_save()
      expect_true(file.exists(path))
      expect_equal(nrow(readRDS(path)$data$isa_data$drivers), 3)
    })
  })
})

test_that("N7: app.R passes the browser token to the autosave module (source guard)", {
  root <- if (basename(getwd()) == "testthat") dirname(dirname(getwd())) else getwd()
  src <- paste(readLines(file.path(root, "app.R"), warn = FALSE), collapse = "\n")
  expect_match(src, "browser_token_reactive = reactive\\(input\\$marinesabres_browser_token\\)")
  js <- paste(readLines(file.path(root, "www", "custom.js"), warn = FALSE), collapse = "\n")
  expect_match(js, "Shiny.setInputValue('marinesabres_browser_token'", fixed = TRUE)
})
