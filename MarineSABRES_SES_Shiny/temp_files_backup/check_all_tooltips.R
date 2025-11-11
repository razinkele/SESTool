tooltips <- c(
  "Skip if you're not sure or want to see all options",
  "Proceed to identify your basic human needs",
  "Return to role selection",
  "Skip if multiple needs apply or you're unsure",
  "Proceed to specify activities and risks",
  "Return to basic needs",
  "Your role helps us recommend the most relevant tools and workflows for your marine management context.",
  "Understanding the fundamental human need behind your question helps identify relevant ecosystem services and management priorities.",
  "Select the human activities relevant to your marine management question. These represent the 'Drivers' and 'Activities' in the DAPSI(W)R(M) framework.",
  "Select the environmental pressures, risks, or hazards you're concerned about. These represent 'Pressures' and 'State changes' in the DAPSI(W)R(M) framework.",
  "Skip if you want to explore all activities and risks",
  "Proceed to select knowledge topics",
  "Select the knowledge domains and analytical approaches relevant to your question. This helps match you with appropriate analysis tools and frameworks.",
  "Return to activities and risks",
  "Skip to see all available tools",
  "Get personalized tool recommendations based on your pathway",
  "Your Pathway Summary"
)

for(i in seq_along(tooltips)) {
  cmd <- sprintf('grep -n "\\"%s\\"" translations/translation.json | awk -F: \'$1>=11 && $1<=2650 {print $1}\' | head -1', tooltips[i])
  line <- system(cmd, intern=TRUE)
  if(length(line) > 0) {
    cat(sprintf("✓ [%2d] Line %4s: %s...\n", i, line, substr(tooltips[i], 1, 50)))
  } else {
    cat(sprintf("✗ [%2d] MISSING: %s...\n", i, substr(tooltips[i], 1, 50)))
  }
}
