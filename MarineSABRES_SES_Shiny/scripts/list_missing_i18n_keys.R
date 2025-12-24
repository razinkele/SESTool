# scripts/list_missing_i18n_keys.R
source("functions/translation_loader.R")
res <- load_translations("translations", debug = FALSE)
all_keys <- names(res$translation)

code_files <- c(
  "app.R",
  list.files("modules", pattern = "\\.R$", full.names = TRUE)
)
code_files <- code_files[!grepl("backup|old|\\.bak", code_files, ignore.case = TRUE)]

used_keys <- character()
for (f in code_files) {
  if (!file.exists(f)) next
  content <- paste(readLines(f, warn = FALSE), collapse = "\n")
  matches <- gregexpr('i18n\\$t\\s*\\(\\s*"([^\"]+)"', content, perl = TRUE)
  if (matches[[1]][1] != -1) {
    for (match_start in matches[[1]]) {
      match_length <- attr(matches[[1]], "match.length")[which(matches[[1]] == match_start)]
      match_text <- substr(content, match_start, match_start + match_length - 1)
      key_match <- regexpr('"([^\"]+)"', match_text, perl = TRUE)
      if (key_match != -1) {
        key <- gsub('"', '', regmatches(match_text, key_match))
        used_keys <- c(used_keys, key)
      }
    }
  }
}
used_keys <- unique(used_keys)
missing_keys <- setdiff(used_keys, all_keys)
cat(sprintf("Found %d missing translation keys:\n", length(missing_keys)))
if (length(missing_keys) > 0) {
  cat(paste(head(missing_keys, 200), collapse = "\n"), "\n")
}
# Exit with non-zero if missing found
if (length(missing_keys) > 0) quit(status = 1) else quit(status = 0)
