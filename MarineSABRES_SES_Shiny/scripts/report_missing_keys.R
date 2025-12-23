library(jsonlite)
# Collect existing keys from all translation files under translations/
translation_files <- list.files('translations', pattern='\\.json$', full.names=TRUE, recursive=TRUE)
get_keys_from_file <- function(path) {
  j <- tryCatch(fromJSON(path, simplifyVector=FALSE), error=function(e) NULL)
  if (is.null(j)) return(character())
  if (!is.null(j$translation) && is.list(j$translation)) {
    # unified map-like translation object
    if (is.null(names(j$translation)) && length(j$translation)>0 && !is.null(j$translation[[1]]$key)) {
      # merged array-style
      return(sapply(j$translation, function(x) x$key))
    }
    return(names(j$translation))
  }
  # per-language top-level format with 'en', 'es', etc.
  if (is.list(j) && any(names(j) == 'en')) {
    return(names(j$en))
  }
  return(character())
}

existing <- unique(unlist(lapply(translation_files, get_keys_from_file)))
code_files <- c('app.R', list.files('modules', pattern='\\.R$', full.names=TRUE))
used <- character()
for (f in code_files) {
  if (!file.exists(f)) next
  txt <- paste(readLines(f, warn=FALSE), collapse='\n')
  matches <- gregexpr('i18n\\$t\\s*\\(\\s*"([^"]+)"', txt, perl=TRUE)
  if (matches[[1]][1] != -1) {
    for (start in matches[[1]]) {
      ml <- attr(matches[[1]], 'match.length')[which(matches[[1]] == start)]
      mt <- substr(txt, start, start + ml - 1)
      km <- regexpr('"([^"]+)"', mt, perl=TRUE)
      if (km != -1) {
        k <- gsub('"','', regmatches(mt, km))
        used <- c(used, k)
      }
    }
  }
}
used <- unique(used)
missing <- setdiff(used, existing)
cat('Used keys:', length(used), '\n')
cat('Existing keys:', length(existing), '\n')
cat('Missing keys:', length(missing), '\n')
if (length(missing) > 0) {
  cat('Samples of missing keys:', paste(head(missing, 50), collapse='\n'), '\n')
  write.csv(data.frame(missing=missing), file='missing_translation_keys.csv', row.names=FALSE)
  cat('Wrote missing_translation_keys.csv\n')
}
