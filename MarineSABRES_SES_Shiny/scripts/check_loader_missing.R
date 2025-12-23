source('functions/translation_loader.R')
res <- load_translations('translations', debug=FALSE)
cat('Total merged entries:', length(res$translation), '\n')
cat('Languages:', paste(res$languages, collapse=', '), '\n')
# Gather used keys
used <- character()
files <- c('app.R', list.files('modules', pattern='\\.R$', full.names=TRUE))
for (f in files) {
  if (!file.exists(f)) next
  txt <- paste(readLines(f, warn=FALSE), collapse='\n')
  matches <- gregexpr('i18n\\$t\\s*\\(\\s*"([^\"]+)"', txt, perl=TRUE)
  if (matches[[1]][1] != -1) {
    for (start in matches[[1]]) {
      ml <- attr(matches[[1]], 'match.length')[which(matches[[1]] == start)]
      mt <- substr(txt, start, start + ml - 1)
      km <- regexpr('"([^\"]+)"', mt, perl=TRUE)
      if (km != -1) {
        k <- gsub('"','', regmatches(mt, km))
        used <- c(used, k)
      }
    }
  }
}
used <- unique(used)
cat('Used keys:', length(used), '\n')
all_keys <- names(res$translation)
cat('Loaded keys:', length(all_keys), '\n')
missing <- setdiff(used, all_keys)
cat('Missing keys:', length(missing), '\n')
if (length(missing) > 0) {
  cat('Sample missing keys:', paste(head(missing, 50), collapse='\n'), '\n')
}
write.csv(data.frame(missing=missing), file='missing_from_loader.csv', row.names=FALSE)
cat('Wrote missing_from_loader.csv\n')
