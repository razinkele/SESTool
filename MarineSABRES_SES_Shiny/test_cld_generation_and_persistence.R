# Test CLD generation and analysis persistence
library(jsonlite)
library(dplyr)
library(igraph)

# Source global to get all constants and functions
source("global.R", local = TRUE)

# Load example project
example_data <- readRDS("data/example_baltic_sea_fisheries.rds")

cat("=== INITIAL STATE ===\n")
cat("ISA elements:\n")
cat("  Drivers:", nrow(example_data$data$isa_data$drivers), "\n")
cat("  Activities:", nrow(example_data$data$isa_data$activities), "\n")
cat("  Pressures:", nrow(example_data$data$isa_data$pressures), "\n")
cat("  Marine Processes:", nrow(example_data$data$isa_data$marine_processes %||% data.frame()), "\n")
cat("  Ecosystem Services:", nrow(example_data$data$isa_data$ecosystem_services %||% data.frame()), "\n")
cat("  Goods/Benefits:", nrow(example_data$data$isa_data$goods_benefits %||% data.frame()), "\n")

cat("\nCLD before generation:\n")
cat("  Nodes:", nrow(example_data$data$cld$nodes %||% data.frame()), "\n")
cat("  Edges:", nrow(example_data$data$cld$edges %||% data.frame()), "\n")

# Generate CLD from ISA
cat("\n=== GENERATING CLD FROM ISA ===\n")
nodes <- create_nodes_df(example_data$data$isa_data)
edges <- create_edges_df(example_data$data$isa_data, example_data$data$isa_data$adjacency_matrices)

cat("Generated CLD:\n")
cat("  Nodes:", nrow(nodes), "\n")
cat("  Edges:", nrow(edges), "\n")

# Check leverage_score column
cat("\nNode columns:", paste(names(nodes), collapse=", "), "\n")
cat("Has leverage_score column:", "leverage_score" %in% names(nodes), "\n")
cat("Leverage scores: ", paste(head(nodes$leverage_score, 10), collapse=", "), "\n")

# Save to example_data
example_data$data$cld$nodes <- nodes
example_data$data$cld$edges <- edges

cat("\n=== RUNNING LEVERAGE POINT ANALYSIS ===\n")
# Calculate leverage points for all nodes
g <- graph_from_data_frame(
  edges %>% select(from, to, polarity),
  directed = TRUE,
  vertices = nodes %>% select(id, label, group)
)

all_centralities <- calculate_all_centralities(g)
all_centralities$Composite_Score <- safe_scale(all_centralities$Betweenness) +
                                     safe_scale(all_centralities$Eigenvector) +
                                     safe_scale(all_centralities$PageRank)

cat("Calculated centralities for", nrow(all_centralities), "nodes\n")
cat("Top 5 leverage points:\n")
print(head(all_centralities[order(-all_centralities$Composite_Score), c("Name", "Composite_Score")], 5))

# Update nodes with leverage scores
nodes$leverage_score <- NA_real_
for (i in 1:nrow(all_centralities)) {
  node_label <- all_centralities$Name[i]
  node_score <- all_centralities$Composite_Score[i]
  node_idx <- which(nodes$label == node_label)
  if (length(node_idx) > 0) {
    nodes$leverage_score[node_idx[1]] <- node_score
  }
}

# Count nodes with leverage scores
nodes_with_scores <- sum(!is.na(nodes$leverage_score) & nodes$leverage_score > 0)
cat("\nNodes with leverage scores >0:", nodes_with_scores, "\n")
cat("Leverage score range:", min(nodes$leverage_score, na.rm=TRUE), "to", max(nodes$leverage_score, na.rm=TRUE), "\n")

# Save updated nodes
example_data$data$cld$nodes <- nodes

cat("\n=== RUNNING LOOP DETECTION ===\n")
# Detect loops
loops_result <- detect_loops(nodes, edges)
cat("Detected", nrow(loops_result$loop_info), "loops\n")
if (nrow(loops_result$loop_info) > 0) {
  cat("Loop types:\n")
  print(table(loops_result$loop_info$Type))
}

# Save loop results
example_data$data$analysis$loops <- list(
  loop_info = loops_result$loop_info,
  all_loops = loops_result$all_loops
)

cat("\n=== FINAL STATE ===\n")
cat("CLD nodes:", nrow(example_data$data$cld$nodes), "\n")
cat("CLD edges:", nrow(example_data$data$cld$edges), "\n")
cat("Nodes with leverage scores:", sum(!is.na(example_data$data$cld$nodes$leverage_score) & example_data$data$cld$nodes$leverage_score > 0), "\n")
cat("Analysis loops stored:", !is.null(example_data$data$analysis$loops), "\n")
if (!is.null(example_data$data$analysis$loops)) {
  cat("  Loop count:", nrow(example_data$data$analysis$loops$loop_info), "\n")
}

# Save updated example data
saveRDS(example_data, "data/example_baltic_sea_fisheries_updated.rds")
cat("\nSaved updated project to example_baltic_sea_fisheries_updated.rds\n")
