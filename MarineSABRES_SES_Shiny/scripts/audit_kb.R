#!/usr/bin/env Rscript
# KB Audit Script - checks all connections for validity
library(jsonlite)

db <- fromJSON("data/ses_knowledge_db.json", simplifyVector = FALSE)
contexts <- db$contexts

cat("=== SES Knowledge Database Audit ===\n\n")
cat(sprintf("Version: %s, Last updated: %s\n", db$version, db$last_updated))
cat(sprintf("Total contexts: %d\n\n", length(contexts)))

valid_types <- c("drivers", "activities", "pressures", "states", "impacts", "welfare", "responses")

valid_flows <- c(
  "drivers -> activities", "activities -> pressures", "pressures -> states",
  "states -> impacts", "impacts -> welfare", "welfare -> drivers",
  "welfare -> responses", "responses -> drivers", "responses -> activities",
  "responses -> pressures", "pressures -> pressures", "states -> states"
)

total_connections <- 0L
issues <- character(0)

for (ctx_name in names(contexts)) {
  ctx <- contexts[[ctx_name]]
  conns <- ctx$connections
  if (is.null(conns) || length(conns) == 0) next

  elem_names <- list()
  for (typ in valid_types) {
    if (!is.null(ctx[[typ]])) {
      elem_names[[typ]] <- vapply(ctx[[typ]], function(e) e$name, character(1))
    } else {
      elem_names[[typ]] <- character(0)
    }
  }

  conn_keys <- character(length(conns))
  for (i in seq_along(conns)) {
    conn <- conns[[i]]
    total_connections <- total_connections + 1L
    from_type <- conn$from_type
    to_type <- conn$to_type
    conn_keys[i] <- paste(conn$from, "->", conn$to)
    flow_check <- paste(from_type, "->", to_type)

    if (!from_type %in% valid_types)
      issues <- c(issues, sprintf("[%s] INVALID from_type '%s': %s -> %s", ctx_name, from_type, conn$from, conn$to))
    if (!to_type %in% valid_types)
      issues <- c(issues, sprintf("[%s] INVALID to_type '%s': %s -> %s", ctx_name, to_type, conn$from, conn$to))
    if (!flow_check %in% valid_flows)
      issues <- c(issues, sprintf("[%s] INVALID FLOW %s: %s -> %s", ctx_name, flow_check, conn$from, conn$to))
    if (length(elem_names[[from_type]]) > 0 && !conn$from %in% elem_names[[from_type]])
      issues <- c(issues, sprintf("[%s] ORPHAN FROM: '%s' not in %s list", ctx_name, conn$from, from_type))
    if (length(elem_names[[to_type]]) > 0 && !conn$to %in% elem_names[[to_type]])
      issues <- c(issues, sprintf("[%s] ORPHAN TO: '%s' not in %s list", ctx_name, conn$to, to_type))
    if (!conn$polarity %in% c("+", "-"))
      issues <- c(issues, sprintf("[%s] INVALID POLARITY '%s': %s -> %s", ctx_name, conn$polarity, conn$from, conn$to))
    if (!conn$strength %in% c("weak", "medium", "strong"))
      issues <- c(issues, sprintf("[%s] INVALID STRENGTH '%s': %s -> %s", ctx_name, conn$strength, conn$from, conn$to))
    conf <- conn$confidence
    if (is.null(conf) || !is.numeric(conf) || conf < 1 || conf > 5)
      issues <- c(issues, sprintf("[%s] INVALID CONFIDENCE %s: %s -> %s", ctx_name, as.character(conf), conn$from, conn$to))
    if (is.null(conn$rationale) || nchar(conn$rationale) < 10)
      issues <- c(issues, sprintf("[%s] MISSING RATIONALE: %s -> %s", ctx_name, conn$from, conn$to))
    if (is.null(conn$references) || length(conn$references) == 0)
      issues <- c(issues, sprintf("[%s] NO REFERENCES: %s -> %s", ctx_name, conn$from, conn$to))
    if (from_type == "responses" && to_type == "pressures" && conn$polarity == "+")
      issues <- c(issues, sprintf("[%s] SUSPECT: Response INCREASES pressure: '%s' -> '%s'", ctx_name, conn$from, conn$to))
    if (from_type == "responses" && to_type == "activities" && conn$polarity == "+" &&
        !grepl("promot|incentiv|support|subsid|fund|enhanc|encourag", tolower(conn$from)))
      issues <- c(issues, sprintf("[%s] SUSPECT: Response INCREASES activity: '%s' -> '%s'", ctx_name, conn$from, conn$to))
    if (conn$from == conn$to)
      issues <- c(issues, sprintf("[%s] SELF-REF: '%s'", ctx_name, conn$from))

    # Semantic polarity checks
    # Activities -> Pressures should generally be positive (activities cause pressures)
    if (from_type == "activities" && to_type == "pressures" && conn$polarity == "-")
      issues <- c(issues, sprintf("[%s] UNUSUAL A->P negative: '%s' -> '%s' (activities usually cause pressures, polarity should be +)", ctx_name, conn$from, conn$to))
    # Pressures -> States should generally be negative (pressures degrade state)
    if (from_type == "pressures" && to_type == "states" && conn$polarity == "+" &&
        !grepl("bloom|invasive|algal|eutrophic|sediment.*accum|warm", tolower(conn$to)))
      issues <- c(issues, sprintf("[%s] CHECK P->S positive: '%s' -> '%s' (pressures usually degrade state)", ctx_name, conn$from, conn$to))
  }

  # Duplicates
  dupes <- conn_keys[duplicated(conn_keys)]
  for (d in unique(dupes))
    issues <- c(issues, sprintf("[%s] DUPLICATE: %s", ctx_name, d))
}

cat(sprintf("Total connections audited: %d\n", total_connections))
cat(sprintf("Total issues found: %d\n\n", length(issues)))

if (length(issues) > 0) {
  # Categorize
  cats <- list(
    "INVALID FLOW" = grep("INVALID FLOW", issues, value = TRUE),
    "ORPHAN" = grep("ORPHAN", issues, value = TRUE),
    "SUSPECT POLARITY" = grep("SUSPECT|UNUSUAL|CHECK", issues, value = TRUE),
    "DUPLICATE" = grep("DUPLICATE", issues, value = TRUE),
    "DATA QUALITY" = grep("INVALID (CONFIDENCE|STRENGTH|POLARITY)|MISSING|NO REF|SELF-REF", issues, value = TRUE),
    "OTHER" = character(0)
  )
  categorized <- unlist(cats)
  cats[["OTHER"]] <- setdiff(issues, categorized)

  for (cat_name in names(cats)) {
    cat_issues <- cats[[cat_name]]
    if (length(cat_issues) > 0) {
      cat(sprintf("\n=== %s (%d) ===\n", cat_name, length(cat_issues)))
      for (iss in cat_issues) cat(iss, "\n")
    }
  }
}

# Also audit R KB
cat("\n\n=== R Knowledge Base (SES_CONNECTION_DB) Audit ===\n")
source("data/ses_connection_knowledge_base.R")
cat(sprintf("Total R KB connections: %d\n", length(SES_CONNECTION_DB)))
r_issues <- character(0)
for (i in seq_along(SES_CONNECTION_DB)) {
  e <- SES_CONNECTION_DB[[i]]
  flow <- paste(e$from_type, "->", e$to_type)
  if (!flow %in% valid_flows)
    r_issues <- c(r_issues, sprintf("Entry %d: INVALID FLOW %s (pattern: %s -> %s)", i, flow, e$from_pattern, e$to_pattern))
  if (e$probability < 0 || e$probability > 1)
    r_issues <- c(r_issues, sprintf("Entry %d: INVALID PROBABILITY %.2f", i, e$probability))
  if (!e$polarity %in% c("+", "-"))
    r_issues <- c(r_issues, sprintf("Entry %d: INVALID POLARITY '%s'", i, e$polarity))
  if (!e$strength %in% c("weak", "medium", "strong"))
    r_issues <- c(r_issues, sprintf("Entry %d: INVALID STRENGTH '%s'", i, e$strength))
  # Check if regex patterns are valid
  tryCatch(grepl(e$from_pattern, "test"), error = function(err)
    r_issues <<- c(r_issues, sprintf("Entry %d: BAD REGEX from_pattern: %s", i, e$from_pattern)))
  tryCatch(grepl(e$to_pattern, "test"), error = function(err)
    r_issues <<- c(r_issues, sprintf("Entry %d: BAD REGEX to_pattern: %s", i, e$to_pattern)))
}
cat(sprintf("R KB issues found: %d\n", length(r_issues)))
if (length(r_issues) > 0) for (iss in r_issues) cat(iss, "\n")
