# tests/testthat/test-i18n-english-fallback.R
# Review 2026-10-07 N48: keys whose non-English values are the English text
# verbatim pass the completeness check (all 9 slots are filled), so a whole
# pane (WP5 mechanisms) shipped in English in every language unnoticed.
# Short identical values are often legitimate ("Fjord", "Mangrove"), so this
# looks at sentences only (>= 30 characters with a space).
LANGS <- c("es", "fr", "de", "lt", "pt", "it", "no", "el")

tr_root <- function() {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, "translations"); if (dir.exists(p)) return(p)
  }
  stop("translations/ not found")
}

long_fallbacks <- function() {
  files <- list.files(tr_root(), "[.]json$", full.names = TRUE, recursive = TRUE)
  files <- files[!startsWith(basename(files), "_merged")]
  out <- character(0)
  for (f in files) {
    tr <- tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE)$translation, error = function(e) NULL)
    for (k in names(tr)) {
      en <- tr[[k]][["en"]]
      if (!is.character(en) || nchar(en) < 30 || !grepl(" ", en, fixed = TRUE)) next
      if (any(vapply(LANGS, function(l) identical(tr[[k]][[l]], en), logical(1)))) {
        out <- c(out, paste0(basename(f), ": ", k))
      }
    }
  }
  out
}

test_that("WP5 mechanism pane strings are translated (no English sentences in other languages)", {
  hits <- long_fallbacks()
  wp5 <- hits[startsWith(hits, "wp5_mechanisms.json")]
  expect_length(wp5, 0)
})

test_that("untranslated English sentences do not grow (ratchet)", {
  # 42 on 2026-10-11, after the WP5 pane was translated (mostly analysis_bot,
  # response_measures, scenario_builder). Lower this number when you translate
  # some; never raise it.
  hits <- long_fallbacks()
  expect_lte(length(hits), 42L)
  expect_gt(length(hits), 0L)   # the scan is not vacuous while the backlog exists
})
