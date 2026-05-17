# ==============================================================================
# Warm-Start Collaborative Filter from KB Templates + Connections
# ==============================================================================
#
# Same rationale as scripts/warm_start_response_bandit.R: until real user
# session data accumulates, treat each KB context (or each production
# template) as one synthetic "user" and the elements/connections it
# contains as that user's "items". This produces a usable 7-row × ~250-
# column user × item matrix.
#
# Output: data/ml_cf_state.rds containing the fitted SVD state.
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(jsonlite)

source("functions/ml_collaborative_filter.R")

set.seed(42)

CONFIG <- list(
  kb_files = c("data/ses_knowledge_db.json", "data/ses_knowledge_db_offshore_wind.json"),
  training_data = "data/ml_training_data.rds",
  out_path = "data/ml_cf_state.rds",
  rank = 12L
)

`%||%` <- function(x, y) if (is.null(x)) y else x

# Each KB context = one synthetic user. Items = element names appearing in that context.
collect_kb_users <- function(path) {
  if (!file.exists(path)) return(list())
  kb <- fromJSON(path, simplifyVector = FALSE)
  out <- list()
  for (ctx_name in names(kb$contexts)) {
    ctx <- kb$contexts[[ctx_name]]
    items <- c()
    for (fld in c("drivers", "activities", "pressures", "states", "impacts", "welfare", "responses")) {
      elements <- ctx[[fld]]
      if (!is.null(elements)) {
        for (e in elements) {
          if (is.list(e) && !is.null(e$name)) items <- c(items, e$name)
          else if (is.character(e)) items <- c(items, e)
        }
      }
    }
    if (length(items) >= 3L) {
      out[[length(out) + 1L]] <- list(user_id = ctx_name, items = unique(items))
    }
  }
  out
}

# Also include the 7 production templates as users (their training-data positives).
collect_template_users <- function(path) {
  if (!file.exists(path)) return(list())
  training <- readRDS(path)
  ex <- training$all_examples
  positives <- ex[ex$connection_exists == TRUE, ]
  if (nrow(positives) == 0L) return(list())
  out <- list()
  for (tpl in unique(positives$template)) {
    rows <- positives[positives$template == tpl, ]
    items <- unique(c(rows$source_name, rows$target_name))
    if (length(items) >= 3L) {
      out[[length(out) + 1L]] <- list(user_id = paste0("template/", tpl), items = items)
    }
  }
  out
}

records <- list()
for (p in CONFIG$kb_files) {
  rs <- collect_kb_users(p)
  records <- c(records, rs)
  cat(sprintf("Loaded %d users from %s\n", length(rs), basename(p)))
}
ts <- collect_template_users(CONFIG$training_data)
records <- c(records, ts)
cat(sprintf("Loaded %d users from training templates\n", length(ts)))
cat(sprintf("Total synthetic users: %d\n", length(records)))

mat_struct <- build_cf_matrix(records)
cat(sprintf("\nUser × item matrix: %d users × %d items\n",
            length(mat_struct$users), length(mat_struct$items)))
cat(sprintf("Density: %.2f%%\n", 100 * mean(mat_struct$matrix)))

state <- fit_cf_svd(mat_struct, rank = CONFIG$rank)
if (is.null(state)) stop("SVD fitting failed (likely too few users).")

save_cf_state(state, path = CONFIG$out_path)
cat(sprintf("\nCF state saved to %s (rank %d).\n", CONFIG$out_path, state$rank))

# Sanity check
cat("\nSanity check recommendations:\n")
seed_examples <- list(
  c("Demersal trawling for Baltic cod", "Overfishing of Eastern Baltic cod"),
  c("Tourist accommodation development", "Beach erosion from coastal development")
)
for (seed in seed_examples) {
  cat(sprintf("\nSeed items: %s\n", paste(seed, collapse = " + ")))
  recs <- recommend_cf_items(state, seed, k = 5L)
  if (nrow(recs) == 0L) {
    cat("  (no recommendations; seed items not in CF index)\n")
  } else {
    for (i in seq_len(nrow(recs))) {
      cat(sprintf("  -> %-50s  (score=%.3f)\n",
                  substr(recs$item[i], 1, 50), recs$score[i]))
    }
  }
}
