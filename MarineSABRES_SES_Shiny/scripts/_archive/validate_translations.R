# Validate translation JSON files
# Writes a CSV report with missing languages and empty values

required_langs <- c("en","es","fr","de","lt","pt","it")

if (!dir.exists("translations")) {
  stop("translations directory not found")
}

library(jsonlite)

files <- list.files("translations", pattern = "\\.json$", full.names = TRUE, recursive = TRUE)
report <- list()

for (f in files) {
  fname <- basename(f)
  ok <- TRUE
  info <- list(file = fname, missing_langs = NA_character_, empty_values = NA_character_, parse_error = NA_character_)
  j <- tryCatch(fromJSON(f), error = function(e) e)
  if (inherits(j, "error")) {
    info$parse_error <- j$message
    ok <- FALSE
  } else {
    # Expect top-level 'translation' or a map of languages
    # Try to detect languages present
    langs <- character(0)
    if (!is.null(j$languages) && length(j$languages) > 0) {
      langs <- j$languages
      translations <- j$translation
    } else if (!is.null(j$translation)) {
      # translation is a map of keys -> {lang: value}
      translations <- j$translation
      # infer languages from first translation entry
      first <- translations[[1]]
      if (!is.null(first) && is.list(first)) {
        langs <- names(first)
      } else {
        langs <- character(0)
      }
    } else if (is.list(j) && all(sapply(j, is.list))) {
      # maybe file is {"en": {...}, "es": {...}}
      langs <- names(j)
      translations <- j
    } else {
      # fallback: try everything
      translations <- j
      langs <- names(translations)
    }

    missing <- setdiff(required_langs, langs)
    if (length(missing) > 0) info$missing_langs <- paste(missing, collapse = ", ")

    # Check for empty values per language
    empties <- c()

    # translations is map: key -> list(lang -> text) OR lang -> list(key -> text)
    if (!is.null(j$translation)) {
      # iterate keys
      for (tk in names(translations)) {
        entry <- translations[[tk]]
        for (lang in intersect(names(entry), required_langs)) {
          val <- entry[[lang]]
          if (is.null(val) || (is.character(val) && nchar(trimws(val)) == 0) || (is.atomic(val) && length(val) != 1)) {
            empties <- c(empties, paste0(lang, ":", tk))
          }
        }
      }
    } else {
      # if translations is per-language mapping
      for (lang in intersect(names(translations), required_langs)) {
        vals <- unlist(translations[[lang]])
        empty_keys <- names(vals[which(is.na(vals) | as.character(vals) == "" | (lengths(vals) > 1))])
        if (length(empty_keys) > 0) {
          empties <- c(empties, paste0(lang, ":", paste(empty_keys, collapse = ";")))
        }
      }
    }
    if (length(empties) > 0) info$empty_values <- paste(empties, collapse = " | ")
  }
  report[[length(report) + 1]] <- info
}

# Output summary
rep_df <- do.call(rbind, lapply(report, as.data.frame, stringsAsFactors = FALSE))
write.csv(rep_df, file = "translation_report.csv", row.names = FALSE)
cat("Wrote translation_report.csv with", nrow(rep_df), "rows\n")

# Print a short summary of problematic files
problems <- rep_df[!is.na(rep_df$parse_error) | !is.na(rep_df$missing_langs) | !is.na(rep_df$empty_values), ]
if (nrow(problems) == 0) cat("No issues found\n") else print(problems)
