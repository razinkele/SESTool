# test-functions-sourced-in-app.R
#
# Prevents the v1.13.1 class of bug: a new file under functions/ that the
# tests source directly (passing in CI) but global.R never sources (failing
# in production with "could not find function 'X'").
#
# Rule: every functions/*.R is either
#   (a) sourced in global.R, OR
#   (b) listed in app.R critical_sources, OR
#   (c) explicitly listed in INTENTIONAL_EXCLUSIONS below, with a reason.
#
# If you intentionally do NOT want a functions/*.R loaded by the app, add it
# to INTENTIONAL_EXCLUSIONS with a comment explaining why. Otherwise: add the
# source() line to global.R.

# Files that are intentionally NOT loaded by the running app. Each entry MUST
# have a comment explaining why — future readers (and reviewers) need to know
# this is a conscious choice, not an oversight. Currently empty: every
# functions/*.R is reachable via direct source() or get_project_file().
INTENTIONAL_EXCLUSIONS <- character(0)

repo_root <- function() {
  # tests/testthat → tests → repo
  here <- normalizePath(getwd(), winslash = "/")
  if (basename(here) == "testthat") here <- dirname(dirname(here))
  here
}

read_sources_of <- function(path) {
  # Extract function-file basenames sourced by either pattern this codebase uses:
  #   (a) direct:   source("functions/X.R", ...)
  #   (b) indirect: source(get_project_file("functions", "X.R"), ...)
  # Comments are stripped first so commented-out source lines don't count.
  lines <- readLines(path, warn = FALSE)
  lines <- sub("#.*$", "", lines)

  direct <- regmatches(
    lines,
    regexpr("source\\s*\\(\\s*[\"']functions/[^\"']+\\.R[\"']", lines)
  )
  direct <- basename(sub(".*[\"']functions/([^\"']+\\.R)[\"'].*", "\\1",
                        direct[nzchar(direct)]))

  indirect <- regmatches(
    lines,
    regexpr(
      "get_project_file\\s*\\(\\s*[\"']functions[\"']\\s*,\\s*[\"'][^\"']+\\.R[\"']",
      lines
    )
  )
  indirect <- sub(
    ".*get_project_file\\s*\\(\\s*[\"']functions[\"']\\s*,\\s*[\"']([^\"']+\\.R)[\"'].*",
    "\\1",
    indirect[nzchar(indirect)]
  )

  unique(c(direct, indirect))
}

read_critical_sources <- function(app_r_path) {
  src <- paste(readLines(app_r_path, warn = FALSE), collapse = "\n")
  # critical_sources <- c( ... ) — capture the c() body
  m <- regmatches(src, regexpr("critical_sources\\s*<-\\s*c\\([^)]*\\)", src))
  if (!length(m)) return(character(0))
  paths <- regmatches(m, gregexpr("[\"']functions/[^\"']+\\.R[\"']", m))[[1]]
  basename(sub(".*[\"']functions/([^\"']+\\.R)[\"'].*", "\\1", paths))
}

test_that("every functions/*.R is reachable from the app entry chain", {
  root <- repo_root()
  functions_dir <- file.path(root, "functions")
  skip_if_not(dir.exists(functions_dir), "functions/ dir not found from test cwd")

  all_function_files <- basename(list.files(
    functions_dir,
    pattern = "\\.R$",
    recursive = FALSE
  ))

  sourced_in_global <- read_sources_of(file.path(root, "global.R"))
  sourced_in_app    <- read_critical_sources(file.path(root, "app.R"))
  reachable         <- unique(c(sourced_in_global, sourced_in_app, INTENTIONAL_EXCLUSIONS))

  missing <- setdiff(all_function_files, reachable)

  expect_equal(
    missing,
    character(0),
    info = paste0(
      "These functions/*.R files are not sourced by global.R, not in app.R ",
      "critical_sources, and not in INTENTIONAL_EXCLUSIONS:\n  - ",
      paste(missing, collapse = "\n  - "),
      "\nFix: add `source(\"functions/<file>.R\", local = FALSE)` to global.R, ",
      "OR add the file to INTENTIONAL_EXCLUSIONS at the top of this test ",
      "with a comment explaining why."
    )
  )
})

test_that("INTENTIONAL_EXCLUSIONS entries actually exist on disk", {
  # Catches stale allowlist entries (file renamed/deleted but exclusion not updated).
  root <- repo_root()
  for (f in INTENTIONAL_EXCLUSIONS) {
    expect_true(
      file.exists(file.path(root, "functions", f)),
      info = sprintf(
        "INTENTIONAL_EXCLUSIONS lists '%s' but functions/%s does not exist. ",
        f, f
      )
    )
  }
})
