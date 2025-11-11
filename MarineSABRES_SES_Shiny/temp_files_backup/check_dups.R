library(jsonlite)
trans <- fromJSON('translations/translation.json')
df <- trans$translation
dups <- df[duplicated(df$en) | duplicated(df$en, fromLast=TRUE), 'en']
cat('Duplicate keys found:', length(unique(dups)), '\n')
if(length(dups) > 0) {
  cat('\nDuplicate keys:\n')
  print(unique(dups))
}
