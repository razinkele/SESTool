# tests/testthat/test-kb-audit-fixes.R
# Validation tests for KB audit fixes (2026-04-08)
# Tests feedback loops and habitat coverage.

library(testthat)

# --- Null-coalesce operator (not in base R) ---
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(a, b) if (!is.null(a)) a else b
}

# --- Helpers ---
.kb_root <- function() {
  wd <- getwd()
  if (basename(wd) == "testthat") return(dirname(dirname(wd)))
  if (file.exists(file.path(wd, "data/ses_knowledge_db.json"))) return(wd)
  candidate <- dirname(dirname(wd))
  if (file.exists(file.path(candidate, "data/ses_knowledge_db.json"))) return(candidate)
  return(wd)
}

ROOT <- .kb_root()

load_template <- function(name) {
  path <- file.path(ROOT, "data", paste0(name, "_SES_Template.json"))
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

load_kb <- function() {
  path <- file.path(ROOT, "data", "ses_knowledge_db.json")
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# ==============================================================================
# 1. Caribbean feedback loops: welfare -> driver connections must exist
# ==============================================================================
test_that("Caribbean template has welfare->driver feedback connections", {
  d <- load_template("Caribbean")
  feedback <- Filter(function(conn) {
    ft <- tolower(conn$from_type %||% "")
    tt <- tolower(conn$to_type %||% "")
    grepl("welfare", ft) && grepl("driver", tt)
  }, d$connections)

  expect_gte(length(feedback), 3,
    info = "Caribbean should have at least 3 welfare->driver feedback connections")
})

test_that("Caribbean feedback loops have reinforcing (+) polarity", {
  d <- load_template("Caribbean")
  feedback <- Filter(function(conn) {
    ft <- tolower(conn$from_type %||% "")
    tt <- tolower(conn$to_type %||% "")
    grepl("welfare", ft) && grepl("driver", tt)
  }, d$connections)

  for (conn in feedback) {
    expect_equal(conn$polarity, "+",
      info = paste("Feedback", conn$from_id, "->", conn$to_id,
                   "should be reinforcing (+) per DAPSIWRM primary cycle"))
  }
})

# ==============================================================================
# 2. KB habitat coverage
# ==============================================================================
test_that("Baltic KB contexts mention seagrass habitat", {
  kb <- load_kb()
  baltic_ctxs <- c("baltic_lagoon", "baltic_estuary", "baltic_offshore",
                    "baltic_open_coast", "baltic_archipelago", "baltic_island",
                    "baltic_rocky_coast")
  for (ctx_name in baltic_ctxs) {
    ctx <- kb$contexts[[ctx_name]]
    if (is.null(ctx)) next
    text <- tolower(jsonlite::toJSON(ctx, auto_unbox = TRUE))
    has_seagrass <- grepl("seagrass|zostera|eelgrass", text)
    expect_true(has_seagrass,
      info = paste(ctx_name, "should reference seagrass/Zostera habitat"))
  }
})

test_that("Mediterranean lagoon KB context mentions seagrass habitat", {
  kb <- load_kb()
  ctx <- kb$contexts$mediterranean_lagoon
  text <- tolower(jsonlite::toJSON(ctx, auto_unbox = TRUE))
  # Cymodocea nodosa or Zostera noltei are the correct lagoon species
  # Posidonia oceanica is stenohaline and only at well-flushed lagoon-sea connections
  expect_true(grepl("cymodocea|posidonia|seagrass|zostera", text),
    info = "mediterranean_lagoon should reference lagoon seagrass habitat")
})

test_that("Caribbean coral reef KB context mentions mangrove and seagrass", {
  kb <- load_kb()
  ctx <- kb$contexts$caribbean_coral_reef
  text <- tolower(jsonlite::toJSON(ctx, auto_unbox = TRUE))
  expect_true(grepl("mangrove", text),
    info = "caribbean_coral_reef should reference mangrove habitat")
  expect_true(grepl("seagrass", text),
    info = "caribbean_coral_reef should reference seagrass habitat")
})

test_that("Caribbean seagrass KB context mentions mangrove connectivity", {
  kb <- load_kb()
  ctx <- kb$contexts$caribbean_seagrass
  text <- tolower(jsonlite::toJSON(ctx, auto_unbox = TRUE))
  expect_true(grepl("mangrove", text),
    info = "caribbean_seagrass should reference mangrove connectivity")
})
