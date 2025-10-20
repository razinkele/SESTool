# Demo script for Loop Network Generator Plugin
# Run this to test the plugin functionality outside of the Shiny app

# Load the plugin
source("loop_generator.R")

# Demo 1: Generate a simple marine network
cat("Demo 1: Simple Marine Ecosystem Network\n")
cat("=======================================\n")

simple_net <- generate_loop_network(
  template = "simple_marine",
  size = 8,
  complexity = 2,
  add_noise = TRUE
)

cat("Generated network with", nrow(simple_net$nodes), "nodes and", nrow(simple_net$edges), "edges\n")
cat("Actual loops created:", simple_net$actual_loops, "\n")
cat("Template:", simple_net$template_name, "\n\n")

# Show nodes and their groups
cat("Nodes and SES Groups:\n")
print(simple_net$nodes[, c("id", "group")])
cat("\n")

# Demo 2: Complex fisheries system
cat("Demo 2: Complex Fisheries System\n")
cat("================================\n")

complex_net <- generate_loop_network(
  template = "complex_fisheries",
  size = 12,
  complexity = 3,
  add_noise = TRUE
)

cat("Generated network with", nrow(complex_net$nodes), "nodes and", nrow(complex_net$edges), "edges\n")
cat("Actual loops created:", complex_net$actual_loops, "\n\n")

# Show edge types
edge_types <- table(complex_net$edges$loop_type)
cat("Edge types:\n")
print(edge_types)
cat("\n")

# Demo 3: Show template information
cat("Demo 3: Available Templates\n")
cat("===========================\n")

template_info <- get_template_info()
print(template_info)
cat("\n")

# Demo 4: Add random loop to existing network
cat("Demo 4: Adding Random Loop\n")
cat("==========================\n")

# Start with simple network
test_net <- generate_loop_network("coastal_tourism", size = 6, complexity = 1)
original_edges <- nrow(test_net$edges)

# Add a random loop
updated_edges <- add_random_loop(test_net$nodes, test_net$edges, loop_size = 4)
new_edges <- nrow(updated_edges)

cat("Original edges:", original_edges, "\n")
cat("After adding loop:", new_edges, "\n")
cat("Edges added:", new_edges - original_edges, "\n\n")

# Demo 5: Network structure analysis
cat("Demo 5: Network Analysis\n")
cat("========================\n")

analysis <- analyze_network_structure(updated_edges, test_net$nodes)
cat(analysis$summary)
cat("\n")

cat("Metrics summary:\n")
print(str(analysis$metrics))

cat("\n🎯 Loop Generator Plugin Demo Complete!\n")
cat("Now use these functions in the SES Tool Shiny app for interactive network generation.\n")
