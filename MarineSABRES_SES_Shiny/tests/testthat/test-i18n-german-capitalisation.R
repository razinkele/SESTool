# tests/testthat/test-i18n-german-capitalisation.R
# German feedback 2026-10-13: labels were Title-Cased from English ("Daten
# Exportieren", "Projekt Speichern"). In German only nouns are capitalised, so a
# verb after the first word is lowercase ("Daten exportieren"). Nominalised verbs
# keep the capital ("zum Speichern", "automatisches Speichern").
VERBS <- c("Laden", "Speichern", "Wiederherstellen", "Ablehnen", "Beginnen", "Hochladen",
           "Verwenden", "Hinzufügen", "Anzeigen", "Erkennen", "Herunterladen", "Löschen",
           "Vergleichen", "Interpretieren", "Berechnen", "Auswählen", "Bearbeiten",
           "Exportieren", "Erhalten", "Starten", "Erstellen", "Einbeziehen", "Suchen",
           "Markieren", "Anfangen", "Ändern", "Anwenden", "Aktivieren", "Bestätigen",
           "Zurücksetzen", "Vorbereiten", "Gefunden", "Abgeschlossen", "Erfüllt",
           "Verfügbar", "Unterstützt")
NOMINALISERS <- c("zum", "beim", "vom", "das", "lokales", "automatisches", "Automatisches", "für")

tr_root <- function() {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, "translations"); if (dir.exists(p)) return(p)
  }
  stop("translations/ not found")
}

capitalised_verbs <- function() {
  files <- list.files(tr_root(), "[.]json$", full.names = TRUE, recursive = TRUE)
  files <- files[!startsWith(basename(files), "_")]
  out <- character(0)
  for (f in files) {
    tr <- tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE)$translation, error = function(e) NULL)
    for (k in names(tr)) {
      de <- tr[[k]][["de"]]
      if (!is.character(de)) next
      w <- strsplit(de, " ", fixed = TRUE)[[1]]
      if (length(w) < 2 || length(w) > 8) next
      for (i in 2:length(w)) {
        prev <- sub("^[(]", "", w[i - 1])
        if (grepl("[!:.]$", prev) || prev %in% NOMINALISERS) next
        if (gsub("[(),]", "", w[i]) %in% VERBS) out <- c(out, paste0(k, ": ", de))
      }
    }
  }
  unique(out)
}

test_that("German labels do not capitalise verbs after the first word", {
  expect_equal(capitalised_verbs(), character(0))
})
