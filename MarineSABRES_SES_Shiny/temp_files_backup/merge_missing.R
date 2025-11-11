library(jsonlite)

# Load existing
trans <- fromJSON("translations/translation.json", simplifyVector = FALSE)
cat("Current translations:", length(trans$translation), "\n")

# Load new
new_trans <- fromJSON("add_missing_translations.json", simplifyVector = FALSE)
cat("New translations:", length(new_trans), "\n")

# Merge
trans$translation <- c(trans$translation, new_trans)
cat("After merge:", length(trans$translation), "\n")

# Write
write(toJSON(trans, pretty = FALSE, auto_unbox = TRUE), "translations/translation.json")
cat("✓ Merged successfully!\n")
