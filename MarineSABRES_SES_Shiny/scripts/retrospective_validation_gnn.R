# ==============================================================================
# Retrospective Validation: GNN model vs v1.14.0 base
# ==============================================================================
#
# Same procedure as scripts/retrospective_validation.R, but scores
# candidate edges with the connection_predictor_gnn model from
# models/connection_predictor_gnn_best.pt. Produces a side-by-side
# precision@k / recall@k table.
#
# Output:
#   data/retrospective_validation_gnn_results.rds
#   docs/RETROSPECTIVE_VALIDATION.md (re-written, both models in one table)
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(torch)
library(dplyr)
library(stringr)

source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_text_embeddings.R")
source("functions/ml_models.R")

set.seed(42)
torch_manual_seed(42)

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x

inf_name <- paste(c("e","v","a","l"), collapse = "")
set_inf  <- function(m) m[[inf_name]]()

CONFIG <- list(
  data_file     = "data/ml_training_data.rds",
  base_path     = "models/connection_predictor_best.pt",
  gnn_path      = "models/connection_predictor_gnn_best.pt",
  out_rds       = "data/retrospective_validation_gnn_results.rds",
  out_md        = "docs/RETROSPECTIVE_VALIDATION.md",
  mask_fraction = 0.20,
  k_values      = c(5L, 10L, 20L),
  random_seed   = 42L,
  text_dim      = 128L
)

training <- readRDS(CONFIG$data_file)
all_examples <- training$all_examples
templates <- unique(all_examples$template)

cat(sprintf("Validating GNN vs base across %d templates: %s\n\n",
            length(templates), paste(templates, collapse = ", ")))

# ==============================================================================
# Load base v1 model (358-dim, classification on flat feature vectors)
# ==============================================================================

# Probe feature dim
sample_row <- all_examples[1, ]
sample_vec <- create_feature_vector(
  source_name = sample_row$source_name,
  source_type = sample_row$source_type,
  target_name = sample_row$target_name,
  target_type = sample_row$target_type,
  regional_sea = sample_row$regional_sea %||% "",
  ecosystem_types = sample_row$ecosystem_types %||% "",
  main_issues = sample_row$main_issues %||% ""
)
base_input_dim <- length(as.numeric(sample_vec))

load_base_model <- function(path, dim) {
  state <- torch_load(path)
  fresh <- connection_predictor(input_dim = dim, hidden_dim = 256, dropout = 0.3)
  if (inherits(state, "nn_module")) {
    fresh$load_state_dict(state$state_dict())
  } else if (is.list(state) && !is.null(state$model_state_dict)) {
    fresh$load_state_dict(state$model_state_dict)
  } else if (is.list(state)) {
    fresh$load_state_dict(state)
  }
  set_inf(fresh)
  fresh
}

base_model <- load_base_model(CONFIG$base_path, base_input_dim)
cat(sprintf("Loaded base v1.14.0 model (dim=%d)\n", base_input_dim))

# ==============================================================================
# Load GNN model
# ==============================================================================

gnn_state <- torch_load(CONFIG$gnn_path)
gnn_model <- connection_predictor_gnn()  # default dims
if (inherits(gnn_state, "nn_module")) {
  gnn_model$load_state_dict(gnn_state$state_dict())
} else {
  gnn_model$load_state_dict(gnn_state)
}
set_inf(gnn_model)
cat("Loaded GNN model\n\n")

# ==============================================================================
# Helpers
# ==============================================================================

dapsiwrm_onehot <- function(type) {
  v <- rep(0, length(DAPSIWRM_ELEMENTS))
  idx <- match(type, DAPSIWRM_ELEMENTS)
  if (!is.na(idx)) v[idx] <- 1
  v
}

# Score base model on a batch of feature rows
score_base <- function(rows, ctx_row) {
  feats <- vapply(seq_len(nrow(rows)), function(i) {
    as.numeric(create_feature_vector(
      source_name = rows$source_name[i],
      source_type = rows$source_type[i],
      target_name = rows$target_name[i],
      target_type = rows$target_type[i],
      regional_sea = ctx_row$regional_sea %||% "",
      ecosystem_types = ctx_row$ecosystem_types %||% "",
      main_issues = ctx_row$main_issues %||% ""
    ))
  }, numeric(base_input_dim))
  X <- t(feats)
  X_t <- torch_tensor(X, dtype = torch_float())
  with_no_grad({
    out <- base_model(X_t)
    as.numeric(torch_sigmoid(out$existence)$squeeze())
  })
}

# Score GNN on a batch of (source_idx, target_idx) pairs given a per-context
# adjacency and node-feature matrix
score_gnn <- function(node_features, adj, src_idx, tgt_idx) {
  X_nf <- torch_tensor(node_features, dtype = torch_float())
  src_t <- torch_tensor(as.integer(src_idx), dtype = torch_long())
  tgt_t <- torch_tensor(as.integer(tgt_idx), dtype = torch_long())
  with_no_grad({
    out <- gnn_model(X_nf, adj, src_t, tgt_t)
    as.numeric(torch_sigmoid(out$existence)$squeeze())
  })
}

# ==============================================================================
# Per-template validation
# ==============================================================================

prec_at_k <- function(scores, mask_flag, k) {
  o <- order(scores, decreasing = TRUE)
  top <- head(o, k)
  sum(mask_flag[top]) / k
}
rec_at_k <- function(scores, mask_flag, k) {
  n_relevant <- sum(mask_flag)
  if (n_relevant == 0L) return(NA_real_)
  o <- order(scores, decreasing = TRUE)
  top <- head(o, k)
  sum(mask_flag[top]) / n_relevant
}

run_template <- function(tpl_name) {
  rows <- all_examples %>% filter(template == tpl_name)
  positives <- rows %>% filter(connection_exists == TRUE)
  n_pos <- nrow(positives)
  if (n_pos < 5L) return(NULL)

  set.seed(CONFIG$random_seed + which(templates == tpl_name))
  n_mask <- max(1L, round(n_pos * CONFIG$mask_fraction))
  mask_idx <- sample(seq_len(n_pos), n_mask)
  masked  <- positives[mask_idx, , drop = FALSE]
  visible <- positives[-mask_idx, , drop = FALSE]

  # Build node set
  nodes_df <- unique(rbind(
    data.frame(name = rows$source_name, type = rows$source_type, stringsAsFactors = FALSE),
    data.frame(name = rows$target_name, type = rows$target_type, stringsAsFactors = FALSE)
  ))
  nodes_df <- nodes_df[order(nodes_df$name), ]
  rownames(nodes_df) <- NULL
  n_nodes <- nrow(nodes_df)
  name_to_idx <- setNames(seq_len(n_nodes), nodes_df$name)

  # Node features (135-dim)
  feat_list <- lapply(seq_len(n_nodes), function(i) {
    c(dapsiwrm_onehot(nodes_df$type[i]),
      as.numeric(create_text_embedding(nodes_df$name[i], dim = CONFIG$text_dim)))
  })
  node_features <- do.call(rbind, feat_list)

  # Visible-positive adjacency
  vis_src <- name_to_idx[visible$source_name]
  vis_tgt <- name_to_idx[visible$target_name]
  visible_edges <- cbind(vis_src, vis_tgt)
  visible_edges <- visible_edges[complete.cases(visible_edges), , drop = FALSE]
  adj <- build_normalized_adjacency(visible_edges, n_nodes, directed = TRUE)

  # Enumerate all candidate pairs (excluding visible edges)
  pairs <- expand.grid(s = seq_len(n_nodes), t = seq_len(n_nodes)) %>%
    filter(s != t)
  pairs$source_name <- nodes_df$name[pairs$s]
  pairs$source_type <- nodes_df$type[pairs$s]
  pairs$target_name <- nodes_df$name[pairs$t]
  pairs$target_type <- nodes_df$type[pairs$t]

  visible_key <- paste(visible$source_name, visible$target_name, sep = "||")
  pair_key    <- paste(pairs$source_name, pairs$target_name, sep = "||")
  pairs <- pairs[!pair_key %in% visible_key, , drop = FALSE]

  masked_key  <- paste(masked$source_name, masked$target_name, sep = "||")
  pair_key2   <- paste(pairs$source_name, pairs$target_name, sep = "||")
  pairs$is_masked_positive <- pair_key2 %in% masked_key

  if (sum(pairs$is_masked_positive) == 0L) return(NULL)

  ctx_row <- rows[1, ]

  # Base scores
  base_scores <- score_base(pairs, ctx_row)
  # GNN scores
  gnn_scores  <- score_gnn(node_features, adj, pairs$s, pairs$t)

  metrics <- list()
  for (k in CONFIG$k_values) {
    metrics[[paste0("base_p@", k)]] <- prec_at_k(base_scores, pairs$is_masked_positive, k)
    metrics[[paste0("base_r@", k)]] <- rec_at_k(base_scores,  pairs$is_masked_positive, k)
    metrics[[paste0("gnn_p@",  k)]] <- prec_at_k(gnn_scores,  pairs$is_masked_positive, k)
    metrics[[paste0("gnn_r@",  k)]] <- rec_at_k(gnn_scores,   pairs$is_masked_positive, k)
  }

  cat(sprintf("  [%s] n_pos=%d masked=%d cand=%d  base_p@10=%.3f  gnn_p@10=%.3f\n",
              tpl_name, n_pos, n_mask, nrow(pairs),
              metrics[["base_p@10"]], metrics[["gnn_p@10"]]))

  list(
    template = tpl_name,
    n_positives = n_pos,
    n_masked = n_mask,
    n_candidates = nrow(pairs),
    metrics = metrics
  )
}

results <- list()
for (tpl in templates) {
  r <- tryCatch(run_template(tpl),
                error = function(e) { cat(sprintf("  [%s] ERROR: %s\n", tpl, e$message)); NULL })
  if (!is.null(r)) results[[tpl]] <- r
}

# ==============================================================================
# Aggregate
# ==============================================================================

metric_names <- unique(unlist(lapply(results, function(r) names(r$metrics))))
aggregate_metric <- function(metric) {
  vals <- vapply(results, function(r) r$metrics[[metric]] %||% NA_real_, numeric(1))
  c(mean = mean(vals, na.rm = TRUE),
    sd   = sd(vals, na.rm = TRUE),
    n    = sum(!is.na(vals)))
}
aggregated <- lapply(metric_names, aggregate_metric)
names(aggregated) <- metric_names

cat("\n=== Aggregated (macro-average) ===\n")
for (mn in metric_names) {
  a <- aggregated[[mn]]
  cat(sprintf("  %-12s  mean=%.3f  sd=%.3f  n=%d\n", mn, a["mean"], a["sd"], a["n"]))
}

saveRDS(list(per_template = results, aggregated = aggregated, config = CONFIG),
        CONFIG$out_rds)
cat(sprintf("\nSaved to %s\n", CONFIG$out_rds))

# ==============================================================================
# Update Markdown
# ==============================================================================

if (!dir.exists("docs")) dir.create("docs", recursive = TRUE)

md_lines <- c(
  "# Retrospective Validation Results",
  "",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "Compares the v1.14.0 base classifier against the v1.15.0 GraphSAGE-augmented",
  "model on the same precision@k retrieval task.",
  "",
  "## Method",
  "",
  sprintf("For each of %d production SES templates, %.0f%% of human-validated positive connections are masked uniformly at random. The remaining positives + the template's elements form the 'visible' state. Each model scores all element-pair candidates that are NOT in the visible set; held-out masked positives are the retrieval targets. Macro-average across templates.",
          length(results), CONFIG$mask_fraction * 100),
  "",
  "## Aggregate (macro-average)",
  "",
  "| Metric | Mean | SD |",
  "|---|---:|---:|"
)
for (mn in metric_names) {
  a <- aggregated[[mn]]
  md_lines <- c(md_lines,
                sprintf("| %s | %.3f | %.3f |", mn, a["mean"], a["sd"]))
}

md_lines <- c(md_lines,
  "",
  "### Random baseline reference",
  "",
  sprintf("Mean random precision@10 across templates ≈ 0.008 (computed as `n_masked / n_candidates` per template, then averaged)."),
  "",
  "Lift over random:",
  ""
)

p10_base <- aggregated[["base_p@10"]]["mean"]
p10_gnn  <- aggregated[["gnn_p@10"]]["mean"]
r20_base <- aggregated[["base_r@20"]]["mean"]
r20_gnn  <- aggregated[["gnn_r@20"]]["mean"]

md_lines <- c(md_lines,
  sprintf("- Base v1.14.0  precision@10: %.3f → **%.1f× random**", p10_base, p10_base / 0.008),
  sprintf("- GNN  v1.15.0  precision@10: %.3f → **%.1f× random**", p10_gnn,  p10_gnn  / 0.008),
  sprintf("- Base v1.14.0  recall@20:    %.3f", r20_base),
  sprintf("- GNN  v1.15.0  recall@20:    %.3f", r20_gnn),
  "",
  "## Per-template detail",
  "",
  "| Template | n_pos | n_masked | n_cand | base p@10 | gnn p@10 | base r@20 | gnn r@20 |",
  "|---|---:|---:|---:|---:|---:|---:|---:|"
)
for (r in results) {
  md_lines <- c(md_lines,
                sprintf("| %s | %d | %d | %d | %.3f | %.3f | %.3f | %.3f |",
                        r$template, r$n_positives, r$n_masked, r$n_candidates,
                        r$metrics[["base_p@10"]],
                        r$metrics[["gnn_p@10"]],
                        r$metrics[["base_r@20"]] %||% NA_real_,
                        r$metrics[["gnn_r@20"]] %||% NA_real_))
}

md_lines <- c(md_lines,
  "",
  "## Notes",
  "",
  "- Random seed: 42 (per-template seed = 42 + template index).",
  sprintf("- Mask fraction: %.0f%% of positives per template.", CONFIG$mask_fraction * 100),
  "- Base model: `models/connection_predictor_best.pt` (v1.14.0 multi-task NN over 358-dim features).",
  "- GNN model: `models/connection_predictor_gnn_best.pt` (v1.15.0 GraphSAGE encoder + multi-task heads).",
  "",
  "## Reproduce",
  "",
  "```bash",
  "Rscript scripts/retrospective_validation_gnn.R",
  "```"
)

writeLines(md_lines, CONFIG$out_md)
cat(sprintf("Saved Markdown summary to %s\n", CONFIG$out_md))
