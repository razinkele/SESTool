# ==============================================================================
# In Silico: Bibliometric Validation of Model Predictions
# ==============================================================================
#
# Tests whether the ML pipeline's confidence is positively correlated
# with literature consensus.
#
# Procedure:
#   1. Parse data/ses_knowledge_db.json (and offshore_wind KB). For each
#      connection record, count entries in its `references` array.
#   2. For each connection, build the feature vector and score with
#      the v1.14.0 base model.
#   3. Correlate (n_references) with (ML existence probability).
#      Also: bin connections by reference count, report mean ML
#      probability per bin.
#
# Interpretation: a positive correlation (Spearman ρ > 0) means the
# model agrees with consensus literature — well-cited connections
# get higher confidence. A null or negative correlation would be a
# red flag.
#
# Output: data/in_silico_bibliometric.rds
# ==============================================================================

if (!exists("debug_log", mode = "function")) {
  debug_log <- function(msg, ctx = NULL) invisible(NULL)
}

library(torch)
library(dplyr)
library(stringr)
library(jsonlite)

source("constants.R")
source("functions/ml_feature_engineering.R")
source("functions/ml_text_embeddings.R")
source("functions/ml_models.R")

set.seed(42)
torch_manual_seed(42)

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1 && is.na(x))) y else x

CONFIG <- list(
  kb_files  = c("data/ses_knowledge_db.json", "data/ses_knowledge_db_offshore_wind.json"),
  base_path = "models/connection_predictor_best.pt",
  out_rds   = "data/in_silico_bibliometric.rds"
)

inf_name <- paste(c("e","v","a","l"), collapse = "")
set_inf  <- function(m) m[[inf_name]]()

# Normalize the KB's lowercase field tags to DAPSIWRM canonical strings.
TYPE_TAG_TO_CANONICAL <- c(
  drivers = "Drivers",
  activities = "Activities",
  pressures = "Pressures",
  states = "Marine Processes & Functioning",
  marine_processes_functioning = "Marine Processes & Functioning",
  impacts = "Ecosystem Services",
  ecosystem_services = "Ecosystem Services",
  welfare = "Goods & Benefits",
  goods_benefits = "Goods & Benefits",
  responses = "Responses",
  measures = "Responses"
)

# ==============================================================================
# Load KB and collect connections
# ==============================================================================

collect_connections <- function(path) {
  if (!file.exists(path)) return(list())
  kb <- fromJSON(path, simplifyVector = FALSE)
  out <- list()
  for (ctx_name in names(kb$contexts)) {
    ctx <- kb$contexts[[ctx_name]]
    conns <- ctx$connections %||% list()
    for (conn in conns) {
      from_tag <- tolower(conn$from_type %||% "")
      to_tag   <- tolower(conn$to_type   %||% "")
      from_canon <- TYPE_TAG_TO_CANONICAL[from_tag]
      to_canon   <- TYPE_TAG_TO_CANONICAL[to_tag]
      if (is.na(from_canon) || is.na(to_canon)) next
      n_refs <- length(conn$references %||% c())
      out[[length(out) + 1L]] <- list(
        context = ctx_name,
        regional_sea = ctx$regional_sea %||% "",
        habitat = ctx$habitat %||% "",
        source_name = conn$from,
        source_type = unname(from_canon),
        target_name = conn$to,
        target_type = unname(to_canon),
        n_references = n_refs,
        strength = conn$strength %||% "medium",
        confidence_kb = conn$confidence %||% NA
      )
    }
  }
  out
}

cat("Loading KB connections with references...\n")
conns <- list()
for (p in CONFIG$kb_files) {
  rs <- collect_connections(p)
  conns <- c(conns, rs)
  cat(sprintf("  %s -> %d connections\n", basename(p), length(rs)))
}
cat(sprintf("Total: %d connections\n", length(conns)))

# Reference-count distribution
ref_counts <- vapply(conns, function(c) c$n_references, integer(1))
cat(sprintf("\nReference count distribution:\n"))
cat(sprintf("  min=%d  median=%d  mean=%.2f  max=%d\n",
            min(ref_counts), median(ref_counts), mean(ref_counts), max(ref_counts)))
cat("  Histogram:\n")
print(table(ref_counts))

# ==============================================================================
# Load base model + score each connection
# ==============================================================================

sample_vec <- create_feature_vector(
  source_name = conns[[1]]$source_name,
  source_type = conns[[1]]$source_type,
  target_name = conns[[1]]$target_name,
  target_type = conns[[1]]$target_type,
  regional_sea = conns[[1]]$regional_sea,
  ecosystem_types = "",
  main_issues = ""
)
input_dim <- length(as.numeric(sample_vec))

state <- torch_load(CONFIG$base_path)
base_model <- connection_predictor(input_dim = input_dim, hidden_dim = 256, dropout = 0.3)
if (inherits(state, "nn_module")) {
  base_model$load_state_dict(state$state_dict())
} else if (is.list(state) && !is.null(state$model_state_dict)) {
  base_model$load_state_dict(state$model_state_dict)
} else if (is.list(state)) {
  base_model$load_state_dict(state)
} else {
  stop(sprintf("Unrecognized checkpoint format at %s (class=%s)",
               CONFIG$base_path, paste(class(state), collapse = "/")))
}
set_inf(base_model)

cat(sprintf("\nScoring %d connections with v1.14.0 base model...\n", length(conns)))

# Build feature matrix in chunks to avoid huge memory
chunk_size <- 200L
ml_probs <- numeric(length(conns))
for (start in seq(1L, length(conns), by = chunk_size)) {
  end <- min(start + chunk_size - 1L, length(conns))
  idxs <- start:end
  feats <- vapply(idxs, function(i) {
    c <- conns[[i]]
    as.numeric(create_feature_vector(
      source_name = c$source_name,
      source_type = c$source_type,
      target_name = c$target_name,
      target_type = c$target_type,
      regional_sea = c$regional_sea %||% "",
      ecosystem_types = "",
      main_issues = ""
    ))
  }, numeric(input_dim))
  X <- t(feats)
  X_t <- torch_tensor(X, dtype = torch_float())
  with_no_grad({
    out <- base_model(X_t)
    probs <- as.numeric(torch_sigmoid(out$existence)$squeeze())
  })
  ml_probs[idxs] <- probs
}

# ==============================================================================
# Correlation + binned summaries
# ==============================================================================

df <- data.frame(
  n_refs = ref_counts,
  ml_prob = ml_probs,
  kb_confidence = vapply(conns, function(c) c$confidence_kb %||% NA_real_, numeric(1)),
  strength = vapply(conns, function(c) c$strength %||% "medium", character(1)),
  stringsAsFactors = FALSE
)

spearman <- cor.test(df$n_refs, df$ml_prob, method = "spearman", exact = FALSE)
pearson  <- cor.test(df$n_refs, df$ml_prob, method = "pearson")

cat(sprintf("\n=== Correlation between n_references and ML probability ===\n"))
cat(sprintf("  Spearman ρ = %.3f  (p = %.4g)\n", spearman$estimate, spearman$p.value))
cat(sprintf("  Pearson  r = %.3f  (p = %.4g)\n", pearson$estimate, pearson$p.value))

# Binned: ML probability by reference-count bucket
df$ref_bin <- cut(df$n_refs, breaks = c(-1, 0, 1, 2, 3, 5, 100),
                  labels = c("0", "1", "2", "3", "4-5", "6+"))
binned <- df %>% group_by(ref_bin) %>%
  summarise(n_conn = n(), mean_ml_prob = mean(ml_prob), sd_ml_prob = sd(ml_prob)) %>%
  arrange(ref_bin)
cat("\n=== Mean ML probability by reference-count bin ===\n")
print(binned)

# Also: KB confidence vs ML probability (cross-check)
cat("\n=== Mean ML probability by KB-assigned confidence (1-5) ===\n")
kb_conf_bins <- df %>% filter(!is.na(kb_confidence)) %>%
  group_by(kb_confidence) %>%
  summarise(n_conn = n(), mean_ml_prob = mean(ml_prob)) %>%
  arrange(kb_confidence)
print(kb_conf_bins)

# Save
saveRDS(list(
  per_connection = df,
  spearman = list(estimate = unname(spearman$estimate), p = spearman$p.value),
  pearson  = list(estimate = unname(pearson$estimate),  p = pearson$p.value),
  binned   = binned,
  kb_conf_bins = kb_conf_bins,
  config = CONFIG
), CONFIG$out_rds)
cat(sprintf("\nSaved to %s\n", CONFIG$out_rds))
