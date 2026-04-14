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

  expect_true(length(feedback) >= 3,
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
test_that("Baltic coastal KB contexts mention seagrass habitat", {
  kb <- load_kb()
  # Only coastal/island contexts — lagoons, estuaries, and offshore excluded
  # because Z. marina requires >5 PSU and shallow subtidal substrate
  baltic_ctxs <- c("baltic_open_coast", "baltic_archipelago", "baltic_island",
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

test_that("Mediterranean lagoon KB context mentions lagoon seagrass species", {
  kb <- load_kb()
  ctx <- kb$contexts$mediterranean_lagoon
  text <- tolower(jsonlite::toJSON(ctx, auto_unbox = TRUE))
  # Cymodocea nodosa and Zostera noltei are the correct lagoon species
  # Posidonia oceanica excluded — stenohaline, not a lagoon species
  expect_true(grepl("cymodocea|zostera", text),
    info = "mediterranean_lagoon should reference Cymodocea nodosa or Zostera noltei")
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

# ==============================================================================
# 3. Template structure validation
# ==============================================================================
test_that("All rebuilt templates load with complete DAPSIWRM categories", {
  templates <- c("Fisheries", "Aquaculture", "Pollution", "Tourism",
                 "ClimateChange", "OffshoreWind")
  for (tpl_name in templates) {
    d <- load_template(tpl_name)
    fw <- d$dapsiwrm_framework
    expect_true(!is.null(fw), info = paste(tpl_name, "missing dapsiwrm_framework"))
    for (cat in c("drivers", "activities", "pressures", "marine_processes",
                  "ecosystem_services", "goods_benefits", "responses")) {
      expect_true(length(fw[[cat]]) >= 2,
        info = paste(tpl_name, "has <2 elements in", cat))
    }
  }
})

test_that("All rebuilt templates have no orphan elements", {
  templates <- c("Fisheries", "Aquaculture", "Pollution", "Tourism",
                 "ClimateChange", "OffshoreWind")
  for (tpl_name in templates) {
    d <- load_template(tpl_name)
    fw <- d$dapsiwrm_framework
    all_ids <- unlist(lapply(fw, function(arr) {
      if (is.list(arr)) sapply(arr, function(e) e[["id"]]) else NULL
    }))
    conn_ids <- unique(c(
      sapply(d$connections, function(c) c[["from_id"]]),
      sapply(d$connections, function(c) c[["to_id"]])
    ))
    orphans <- setdiff(all_ids, conn_ids)
    expect_equal(length(orphans), 0,
      info = paste(tpl_name, "has orphans:", paste(orphans, collapse = ", ")))
  }
})

test_that("All rebuilt templates have feedback loops", {
  templates <- c("Fisheries", "Aquaculture", "Pollution", "Tourism",
                 "ClimateChange", "OffshoreWind")
  for (tpl_name in templates) {
    d <- load_template(tpl_name)
    feedback <- Filter(function(conn) {
      ft <- tolower(conn$from_type %||% "")
      tt <- tolower(conn$to_type %||% "")
      grepl("welfare", ft) && grepl("driver", tt)
    }, d$connections)
    expect_true(length(feedback) >= 1,
      info = paste(tpl_name, "has no welfare->driver feedback"))
  }
})

test_that("All rebuilt templates have measures", {
  templates <- c("Fisheries", "Aquaculture", "Pollution", "Tourism",
                 "ClimateChange", "OffshoreWind")
  for (tpl_name in templates) {
    d <- load_template(tpl_name)
    fw <- d$dapsiwrm_framework
    expect_true(!is.null(fw$measures) && length(fw$measures) >= 1,
      info = paste(tpl_name, "missing measures section"))
  }
})

test_that("Caribbean template has polarity on all connections", {
  d <- load_template("Caribbean")
  missing <- Filter(function(conn) is.null(conn$polarity), d$connections)
  expect_equal(length(missing), 0,
    info = paste(length(missing), "Caribbean connections still missing polarity"))
})
