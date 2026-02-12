# Fix English placeholders that start with '[MISSING TRANSLATION]'
# Strategy:
# - For namespaced keys (like common.misc.error_saving_project), derive English text from last segment
# - For keys that appear to be literal English text, use the key itself
# - For merged array format, modify entries in-place

library(jsonlite)

placeholder_prefix <- "[MISSING TRANSLATION]"
translation_files <- list.files('translations', pattern='\\.json$', full.names=TRUE, recursive=TRUE)

humanize_key <- function(key) {
  # If key looks like a literal English sentence (contains spaces or punctuation), return as-is
  if (grepl('[[:space:]]|[,!\'\"]', key)) return(key)
  # Otherwise use last component after '.' and replace '_' with spaces and fix casing
  parts <- strsplit(key, '\\.')[[1]]
  last <- parts[length(parts)]
  txt <- gsub('_', ' ', last)
  # Sentence-case
  txt <- tolower(txt)
  substr(txt, 1, 1) <- toupper(substr(txt, 1, 1))
  return(txt)
}

for (f in translation_files) {
  cat('Processing', f, '\n')
  # backup
  backup <- paste0(f, '.backup.', format(Sys.time(), '%Y%m%d_%H%M%S'))
  file.copy(f, backup)

  j <- tryCatch(fromJSON(f, simplifyVector=FALSE), error=function(e) NULL)
  if (is.null(j)) next

  modified <- FALSE

  # unified format: map-like or array-style
  if (!is.null(j$translation) && is.list(j$translation)) {
    # object-based format
    if (!is.null(names(j$translation)) && length(names(j$translation))>0) {
      for (k in names(j$translation)) {
        en_val <- j$translation[[k]]$en
        if (!is.null(en_val) && startsWith(en_val, placeholder_prefix)) {
          new_en <- humanize_key(k)
          j$translation[[k]]$en <- new_en
          modified <- TRUE
          cat('  Fixed', k, '->', new_en, '\n')
        }
      }
    } else {
      # array-based format
      for (i in seq_along(j$translation)) {
        entry <- j$translation[[i]]
        if (!is.null(entry$en) && startsWith(entry$en, placeholder_prefix)) {
          k <- if (!is.null(entry$key)) entry$key else paste0('Entry#', i)
          new_en <- humanize_key(k)
          j$translation[[i]]$en <- new_en
          modified <- TRUE
          cat('  Fixed array entry', k, '->', new_en, '\n')
        }
      }
    }
    if (modified) write_json(j, f, pretty=TRUE, auto_unbox=TRUE)
  } else if (is.list(j) && any(names(j) == 'en')) {
    # per-language top-level format
    if (!is.null(j$en) && length(j$en) > 0) {
      for (k in names(j$en)) {
        en_val <- j$en[[k]]
        if (!is.null(en_val) && startsWith(en_val, placeholder_prefix)) {
          new_en <- humanize_key(k)
          j$en[[k]] <- new_en
          modified <- TRUE
          cat('  Fixed', k, '->', new_en, '\n')
        }
      }
    }
    if (modified) write_json(j, f, pretty=TRUE, auto_unbox=TRUE)
  }
}

cat('Done')
