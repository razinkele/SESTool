# tests/testthat/test-i18n-key-arguments.R
# Translation keys passed as helper arguments (title_key = "...",
# subtitle_key = "...", context_key = "...", ...) are invisible to the CI
# audit, which only scans i18n$t("...") calls. The Leverage Point Analysis
# page shipped with raw "modules.analysis.leverage.title" as its heading
# because of that gap. Every such literal must resolve in translations/.
proj <- function(...) {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, ...); if (file.exists(p)) return(p)
  }
  file.path(getwd(), "../..", ...)
}

known_keys <- function() {
  files <- list.files(proj("translations"), "[.]json$", full.names = TRUE, recursive = TRUE)
  files <- files[!startsWith(basename(files), "_merged")]
  unlist(lapply(files, function(f) {
    d <- tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE), error = function(e) NULL)
    names(d$translation)
  }), use.names = FALSE)
}

key_argument_literals <- function() {
  files <- c(proj("app.R"),
             list.files(proj("modules"), "[.]R$", full.names = TRUE, recursive = TRUE),
             list.files(proj("server"), "[.]R$", full.names = TRUE),
             list.files(proj("functions"), "[.]R$", full.names = TRUE))
  pat <- "[a-z_]+_key[[:space:]]*=[[:space:]]*\"((modules|common|ui|data)[.][a-z0-9_.]+)\""
  out <- list()
  for (f in files) {
    lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
    for (i in seq_along(lines)) {
      code <- sub("#.*$", "", lines[i])
      m <- regmatches(code, gregexpr(pat, code))[[1]]
      for (hit in m) {
        key <- sub(pat, "\\1", hit)
        out[[length(out) + 1]] <- data.frame(key = key, where = paste0(basename(f), ":", i))
      }
    }
  }
  do.call(rbind, out)
}

test_that("the scan finds the helper key arguments (non-vacuous)", {
  refs <- key_argument_literals()
  expect_gt(nrow(refs), 50)
  expect_true("modules.analysis.leverage.title" %in% refs$key)
})

test_that("every *_key = \"...\" literal resolves to a translation key", {
  refs <- key_argument_literals()
  missing <- refs[!refs$key %in% known_keys(), , drop = FALSE]
  expect_equal(nrow(missing), 0L,
               info = paste(missing$key, missing$where, sep = " @ ", collapse = "\n"))
})

test_that("Leverage page title matches the sidebar label in every language", {
  lev <- jsonlite::fromJSON(proj("translations", "modules", "analysis_leverage.json"),
                            simplifyVector = FALSE)$translation
  side <- jsonlite::fromJSON(proj("translations", "ui", "sidebar.json"),
                             simplifyVector = FALSE)$translation
  for (lang in c("en", "es", "fr", "de", "lt", "pt", "it", "no", "el")) {
    expect_identical(lev[["modules.analysis.leverage.title"]][[lang]],
                     side[["ui.sidebar.leverage_point_analysis"]][[lang]], info = lang)
    expect_true(nzchar(lev[["modules.analysis.leverage.subtitle"]][[lang]] %||% ""), info = lang)
    expect_true(nzchar(lev[["modules.analysis.leverage.help_title"]][[lang]] %||% ""), info = lang)
  }
})
