# tests/testthat/test-i18n-duplicate-keys.R
# load_translations() merges every translation file into one list, and when a
# key appears in two files the file loaded LAST silently wins. On 2026-10-11 47
# keys were defined twice, and in several the copies meant different things:
# the ISA "Stakeholder" field label showed "Define your project goals,
# stakeholders, and timeline", and "All %d connections in %s approved" lost its
# %d, so the count was printed where the category name belonged.
source_for_test("functions/translation_loader.R")

tr_root <- function() {
  for (root in c(file.path(getwd(), "../.."), getwd())) {
    p <- file.path(root, "translations"); if (dir.exists(p)) return(p)
  }
  stop("translations/ not found")
}

# Same file selection as load_translations().
loaded_files <- function(base) {
  f <- list.files(base, "\\.json$", full.names = TRUE, recursive = TRUE)
  f <- f[!grepl("backup|translation\\.json$|_merged_translations\\.json$", f, ignore.case = TRUE)]
  f <- f[!grepl("ui_flat_keys\\.json$", f, ignore.case = TRUE)]
  f[grepl("(_[a-z]+\\.json$|/common/|/modules/|/ui/|/data/)", f)]
}

test_that("no translation key is defined in more than one file", {
  owners <- list()
  for (f in loaded_files(tr_root())) {
    for (k in names(jsonlite::fromJSON(f, simplifyVector = FALSE)$translation)) {
      owners[[k]] <- c(owners[[k]], basename(f))
    }
  }
  dups <- Filter(function(x) length(x) > 1, owners)
  expect_length(dups, 0)
  if (length(dups)) {
    message(paste(sprintf("%s: %s", names(dups), vapply(dups, paste, "", collapse = ", ")), collapse = "\n"))
  }
})

test_that("labels that collided now resolve to their own text", {
  tr <- load_translations(tr_root())$translation
  expect_identical(tr[["modules.isa.data_entry.common.stakeholder"]]$en, "Stakeholder")
  expect_identical(tr[["modules.isa.data_entry.common.documentation"]]$en, "Documentation")
  expect_identical(tr[["modules.entry_point.role"]]$en, "Role:")
  expect_identical(tr[["common.labels.driver_type"]]$lt, "Varomosios jėgos tipas")
})

test_that("the batch approve/reject messages take a count and a category in every language", {
  # connection_review_tabbed.R calls sprintf(msg, n_connections, category_label)
  tr <- load_translations(tr_root())$translation
  for (k in c("common.misc.all_d_connections_in_s_approved", "common.misc.all_d_connections_in_s_rejected")) {
    for (lang in names(tr[[k]])) {
      out <- sprintf(tr[[k]][[lang]], 7L, "Drivers")
      expect_true(grepl("7", out, fixed = TRUE) && grepl("Drivers", out, fixed = TRUE), info = paste(k, lang))
    }
  }
})
