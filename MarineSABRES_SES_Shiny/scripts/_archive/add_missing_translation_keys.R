# Add missing i18n keys to _merged_translations.json as English placeholders
library(jsonlite)

merged_path <- "translations/_merged_translations.json"
backup_path <- paste0(merged_path, ".backup.", format(Sys.time(), "%Y%m%d_%H%M%S"))
file.copy(merged_path, backup_path)
cat("Backed up merged translations to", backup_path, "\n")

merged <- fromJSON(merged_path, simplifyVector = FALSE)
existing_keys <- sapply(merged$translation, function(x) x$key)

# Gather used keys from code
code_files <- c("app.R", list.files("modules", pattern = "\\.R$", full.names = TRUE))
used_keys <- character()
for (f in code_files) {
  if (!file.exists(f)) next
  txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
  matches <- gregexpr('i18n\\$t\\s*\\(\\s*"([^"]+)"', txt, perl = TRUE)
  if (matches[[1]][1] != -1) {
    for (start in matches[[1]]) {
      ml <- attr(matches[[1]], "match.length")[which(matches[[1]] == start)]
      mt <- substr(txt, start, start + ml - 1)
      km <- regexpr('"([^"]+)"', mt, perl = TRUE)
      if (km != -1) {
        k <- gsub('"', '', regmatches(mt, km))
        used_keys <- c(used_keys, k)
      }
    }
  }
}
used_keys <- unique(used_keys)
missing_keys <- setdiff(used_keys, existing_keys)
cat(length(missing_keys), "missing keys found\n")

if (length(missing_keys) > 0) {
  # Add placeholders
  for (k in missing_keys) {
    new_entry <- list(
      key = k,
      en = sprintf("[MISSING TRANSLATION] %s", k)
    )
    # Set other languages to empty strings
    langs <- merged$languages
    for (lang in langs) {
      if (!lang %in% names(new_entry)) new_entry[[lang]] <- ifelse(lang == "en", new_entry$en, "")
    }
    merged$translation[[length(merged$translation) + 1]] <- new_entry
  }
  # Write back
  write_json(merged, merged_path, pretty = TRUE, auto_unbox = TRUE)
  cat("Appended", length(missing_keys), "keys to", merged_path, "\n")
} else {
  cat("No missing keys to add\n")
}
