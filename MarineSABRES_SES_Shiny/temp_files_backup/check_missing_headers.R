library(jsonlite)
trans <- fromJSON('translations/translation.json', simplifyDataFrame=FALSE)
en_keys <- sapply(trans$translation, function(x) x$en)

strings_to_check <- c(
  "AI-Assisted ISA Creation",
  "Let me guide you step-by-step through building your DAPSI(W)R(M) model."
)

for (s in strings_to_check) {
  found <- s %in% en_keys
  cat(sprintf("%s: %s\n", ifelse(found, "FOUND", "MISSING"), s))
}
