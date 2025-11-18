# Test Caribbean Template Loading
# Tests connection extraction and adjacency matrix building

# Load dependencies
source("functions/template_loader.R")

# Load Caribbean template
cat("Loading Caribbean template...\n")
caribbean <- load_template_from_json("data/Caribbean_SES_Template.json")

if (is.null(caribbean)) {
  stop("Failed to load Caribbean template!")
}

cat("\n=== CARIBBEAN TEMPLATE SUMMARY ===\n")
cat("Template Name:", caribbean$name_key, "\n")
cat("Category:", caribbean$category_key, "\n\n")

# Check element counts
cat("=== ELEMENT COUNTS ===\n")
cat("Drivers:", nrow(caribbean$drivers), "\n")
cat("Activities:", nrow(caribbean$activities), "\n")
cat("Pressures:", nrow(caribbean$pressures), "\n")
cat("Marine Processes (States):", nrow(caribbean$marine_processes), "\n")
cat("Ecosystem Services (Impacts):", nrow(caribbean$ecosystem_services), "\n")
cat("Goods & Benefits (Welfare):", nrow(caribbean$goods_benefits), "\n")
cat("Responses:", nrow(caribbean$responses), "\n")
cat("Measures:", nrow(caribbean$measures), "\n\n")

# Check adjacency matrices
cat("=== ADJACENCY MATRICES ===\n")
if (!is.null(caribbean$adjacency_matrices)) {
  for (mat_name in names(caribbean$adjacency_matrices)) {
    mat <- caribbean$adjacency_matrices[[mat_name]]
    connection_count <- sum(mat != "" & !is.na(mat))
    cat(sprintf("%-10s: %3dx%-3d = %3d connections\n", 
                mat_name, 
                nrow(mat), 
                ncol(mat), 
                connection_count))
  }
  
  total_connections <- sum(sapply(caribbean$adjacency_matrices, function(m) sum(m != "" & !is.na(m))))
  cat("\nTOTAL CONNECTIONS:", total_connections, "\n")
} else {
  cat("No adjacency matrices found!\n")
}

# Sample some connections
cat("\n=== SAMPLE CONNECTIONS ===\n")
if (!is.null(caribbean$adjacency_matrices$d_a)) {
  mat <- caribbean$adjacency_matrices$d_a
  for (i in 1:min(3, nrow(mat))) {
    for (j in 1:ncol(mat)) {
      if (mat[i, j] != "" && !is.na(mat[i, j])) {
        cat(sprintf("%s → %s: %s\n", rownames(mat)[i], colnames(mat)[j], mat[i, j]))
      }
    }
  }
}

cat("\n✓ Test complete!\n")
