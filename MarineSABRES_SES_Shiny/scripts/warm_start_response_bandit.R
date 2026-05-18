# ==============================================================================
# Warm-Start Response Bandit from KB-Derived Synthetic Feedback
# ==============================================================================
#
# The real ml_feedback_log.csv is empty (header only) because the toolbox
# has only been live since v1.14.0 (2026-05-17). To give the LinUCB bandit
# a usable starting point, we synthesize feedback from the validated
# knowledge base: for each KB connection involving a Response, the
# "ground truth" priority is derived from confidence + strength as
# encoded by the consortium. We then replay those decisions as
# pseudo-observations.
#
# This is clearly labelled as synthetic warm-start. Real user feedback
# will overwrite these effects within a few hundred genuine interactions.
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(jsonlite)
library(dplyr)

source("constants.R")
source("functions/ml_response_bandit.R")

set.seed(42)

CONFIG <- list(
  kb_files = c("data/ses_knowledge_db.json", "data/ses_knowledge_db_offshore_wind.json"),
  out_path = "data/ml_response_bandit_state.rds",
  passes   = 3L
)

# ==============================================================================
# Load KB
# ==============================================================================

load_kb_connections_with_response <- function(path) {
  if (!file.exists(path)) return(NULL)
  kb <- fromJSON(path, simplifyVector = FALSE)
  out <- list()
  for (ctx_name in names(kb$contexts)) {
    ctx <- kb$contexts[[ctx_name]]
    conns <- ctx$connections %||% list()
    for (conn in conns) {
      from_t <- tolower(conn$from_type %||% "")
      to_t   <- tolower(conn$to_type   %||% "")
      if (from_t == "responses" || to_t == "responses") {
        out[[length(out) + 1L]] <- list(
          context = ctx_name,
          regional_sea = ctx$regional_sea %||% "other",
          habitat = ctx$habitat %||% "",
          from_type = conn$from_type,
          to_type   = conn$to_type,
          strength  = tolower(conn$strength %||% "medium"),
          confidence = as.numeric(conn$confidence %||% 3),
          polarity = conn$polarity %||% "+"
        )
      }
    }
  }
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("Loading KB connections involving Responses...\n")
all_responses <- list()
for (kb_path in CONFIG$kb_files) {
  rs <- load_kb_connections_with_response(kb_path)
  if (!is.null(rs)) {
    all_responses <- c(all_responses, rs)
    cat(sprintf("  %s -> %d connections\n", kb_path, length(rs)))
  }
}
cat(sprintf("Total: %d response-related connections\n\n", length(all_responses)))

# ==============================================================================
# Map KB attributes to (priority arm, reward) tuples
# ==============================================================================

# Heuristic for "ground truth" priority (v1.16.1):
#
#   Polarity is NOT a signal of priority. In the DAPSI(W)R(M) framework, a
#   response with polarity '-' *reduces* its target — e.g. an MPA reduces
#   overfishing pressure, a nutrient-reduction policy reduces eutrophication.
#   Those are typically HIGH-priority responses. The previous heuristic
#   (which sent every polarity='-' connection to "low") was ecologically
#   backward: it systematically downweighted the most consequential
#   responses, biasing the bandit to recommend "low priority" for MPAs,
#   quotas, and emission caps. See P1-1 in docs/CODEBASE_REVIEW_2026-05-18.md.
#
# v1.16.1 heuristic uses ONLY strength × confidence:
#   strong  + confidence >= 4  -> high
#   weak    OR confidence <= 2 -> low
#   otherwise                  -> medium
ground_truth_priority <- function(conn) {
  s <- conn$strength
  c <- conn$confidence
  if (identical(s, "strong") && !is.na(c) && c >= 4) return("high")
  if (identical(s, "weak")   || (!is.na(c) && c <= 2)) return("low")
  "medium"
}

# Map a connection to a coarse main_issue based on its habitat / context name
infer_main_issue <- function(conn) {
  h <- tolower(paste(conn$habitat, conn$context, sep = " "))
  if (grepl("fish",  h, fixed = TRUE)) return("fisheries")
  if (grepl("eutroph|nutrient|nitr", h)) return("eutrophication")
  if (grepl("pollut|contam|chem",   h)) return("pollution")
  if (grepl("climate|warming",       h)) return("climate")
  if (grepl("mpa|protected",         h)) return("mpa")
  if (grepl("tour",                  h)) return("tourism")
  if (grepl("biodiv|species",        h)) return("biodiversity")
  "other"
}

# ==============================================================================
# Build per-event contexts and feed the bandit
# ==============================================================================

state <- init_response_bandit()
n_updates <- 0L

for (pass in seq_len(CONFIG$passes)) {
  set.seed(42 + pass)
  shuffled <- sample(all_responses)
  for (conn in shuffled) {
    truth_arm <- ground_truth_priority(conn)
    # Pseudo-context features derived from this KB record
    ctx_vec <- build_response_context(
      target_type           = conn$to_type %||% "Responses",
      effectiveness         = conn$strength,
      feasibility           = if (conn$confidence >= 4) "high" else if (conn$confidence <= 2) "low" else "medium",
      stakeholder_engagement = 0.5,
      n_elements            = 25L,           # placeholder average
      n_connections         = 30L,           # placeholder average
      regional_sea          = conn$regional_sea,
      main_issue            = infer_main_issue(conn)
    )

    # LinUCB warm-start semantics: only update the arm that the consortium
    # *would have chosen* (the ground-truth priority) with reward = 1.
    # Other arms stay at their priors so they will still be explored when
    # the context warrants. (Updating non-truth arms with reward=0 biases
    # them all toward predicting "no" and collapses the policy.)
    state <- update_response_bandit(state, truth_arm, ctx_vec, 1)
    n_updates <- n_updates + 1L
  }
  cat(sprintf("Pass %d done (%d total updates).\n", pass, n_updates))
}

save_response_bandit(state, path = CONFIG$out_path)
cat(sprintf("\nWarm-started bandit saved to %s\n", CONFIG$out_path))
cat(sprintf("Updates per arm: high=%d  medium=%d  low=%d\n",
            state$n_updates[["high"]], state$n_updates[["medium"]], state$n_updates[["low"]]))

# ==============================================================================
# Quick sanity check: predict on a few held-out-style contexts
# ==============================================================================

cat("\nSanity check predictions:\n")
test_cases <- list(
  list(name = "Strong, high-conf, fisheries response",
       ctx = build_response_context("Responses", "high", "high", 0.7, 30L, 35L, "Baltic", "fisheries")),
  list(name = "Weak, low-conf, climate response",
       ctx = build_response_context("Responses", "low", "low", 0.3, 20L, 22L, "Atlantic", "climate")),
  list(name = "Medium / medium pollution response",
       ctx = build_response_context("Responses", "medium", "medium", 0.5, 25L, 28L, "Mediterranean", "pollution"))
)
for (tc in test_cases) {
  pred <- predict_response_priority(state, tc$ctx)
  cat(sprintf("%s\n  -> %s\n  Expected: high=%.3f  medium=%.3f  low=%.3f\n\n",
              tc$name, pred$arm,
              pred$expected_per_arm[["high"]],
              pred$expected_per_arm[["medium"]],
              pred$expected_per_arm[["low"]]))
}
