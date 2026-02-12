# Add placeholder translations for missing keys into appropriate translation files
library(jsonlite)

csv_path <- 'missing_translation_keys.csv'
if (!file.exists(csv_path)) stop('missing_translation_keys.csv not found; run report_missing_keys.R first')
missing <- read.csv(csv_path, stringsAsFactors = FALSE)$missing
if (length(missing) == 0) {
  cat('No missing keys to process\n')
  quit(status = 0)
}

# Helper: find candidate files
translation_root <- 'translations'
files_list <- list.files(translation_root, pattern='\\.json$', full.names=TRUE, recursive=TRUE)

find_target_file <- function(key) {
  parts <- strsplit(key, '\\.')[[1]]
  # If key is a literal string (contains spaces or doesn't look namespaced) put it in common/misc
  if (!grepl('^[a-z]+\\.', key)) {
    candidate_common <- file.path(translation_root, 'common', 'misc.json')
    if (file.exists(candidate_common)) return(candidate_common)
  }
  # priority checks
  if (length(parts) >= 2) {
    # common.<file>
    candidate <- file.path(translation_root, parts[1], paste0(parts[2], '.json'))
    if (file.exists(candidate)) return(candidate)
  }
  # try translations/<parts[1]>.json
  candidate2 <- file.path(translation_root, paste0(parts[1], '.json'))
  if (file.exists(candidate2)) return(candidate2)
  # try scanning files for matching prefix
  pref <- paste0(parts[1], '.', ifelse(length(parts)>=2, parts[2], ''))
  for (f in files_list) {
    txt <- paste(readLines(f, warn=FALSE), collapse='\n')
    if (grepl(pref, txt, fixed=TRUE)) return(f)
  }
  # fallback to merged
  return(file.path(translation_root, '_merged_translations.json'))
}

# Load and modify files grouped by target
targets <- lapply(missing, find_target_file)
unique_targets <- unique(targets)

for (tg in unique_targets) {
  keys_for_file <- missing[targets == tg]
  cat('Processing', tg, 'with', length(keys_for_file), 'keys\n')
  file.copy(tg, paste0(tg, '.backup.', format(Sys.time(), '%Y%m%d_%H%M%S')))
  j <- fromJSON(tg, simplifyVector=FALSE)
  # If unified format (has 'translation' list and 'languages')
  if (!is.null(j$translation) && !is.null(j$languages)) {
    for (k in keys_for_file) {
      if (is.null(j$translation[[k]])) {
        entry <- list()
        for (lg in j$languages) {
          entry[[lg]] <- paste('[MISSING TRANSLATION]', k)
        }
        j$translation[[k]] <- entry
      } else {
        # Fill empty or NULL language values with placeholder
        for (lg in j$languages) {
          if (is.null(j$translation[[k]][[lg]]) || j$translation[[k]][[lg]] == "") {
            j$translation[[k]][[lg]] <- paste('[MISSING TRANSLATION]', k)
          }
        }
      }
    }
    write_json(j, tg, pretty=TRUE, auto_unbox=TRUE)
    cat('Wrote', length(keys_for_file), 'to', tg, '\n')
  } else if (is.list(j) && all(sapply(j, is.list)) && length(names(j))>0 && grepl('en', names(j))) {
    # per-language top-level format (e.g., en: {key:val})
    langs <- names(j)
    for (k in keys_for_file) {
      for (lg in langs) {
        if (is.null(j[[lg]][[k]]) || j[[lg]][[k]] == "") {
          j[[lg]][[k]] <- paste('[MISSING TRANSLATION]', k)
        }
      }
    }
    write_json(j, tg, pretty=TRUE, auto_unbox=TRUE)
    cat('Wrote', length(keys_for_file), 'to', tg, '\n')
  } else if (basename(tg) == '_merged_translations.json') {
    # fallback to merged array structure
    merged <- j
    langs <- merged$languages
    existing_keys <- sapply(merged$translation, function(x) x$key)
    for (k in keys_for_file) {
      if (k %in% existing_keys) {
        # find index and fill empty language values
        idx <- which(existing_keys == k)[1]
        for (lg in langs) {
          if (is.null(merged$translation[[idx]][[lg]]) || merged$translation[[idx]][[lg]] == "") {
            merged$translation[[idx]][[lg]] <- paste('[MISSING TRANSLATION]', k)
          }
        }
      } else {
        entry <- list(key=k)
        for (lg in langs) entry[[lg]] <- paste('[MISSING TRANSLATION]', k)
        merged$translation[[length(merged$translation)+1]] <- entry
      }
    }
    write_json(merged, tg, pretty=TRUE, auto_unbox=TRUE)
    cat('Appended', length(keys_for_file), 'to merged translations\n')
  } else {
    warning('Unrecognized format for ', tg, '; skipping')
  }
}

cat('Done processing all targets\n')
