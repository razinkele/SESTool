# translation_helpers.R
# Helper functions for improved translation management and usage
# Part of the MarineSABRES SES Toolbox translation framework optimization

# ============================================================================
# TRANSLATION HELPER FUNCTIONS
# ============================================================================

#' Translate with module prefix
#'
#' Automatically prefixes translation key with module name for namespacing
#'
#' @param key Translation key (will be prefixed with module name)
#' @param module Module name (e.g., "dashboard", "entry_point", "pims")
#' @param ... Additional parameters for interpolation
#' @return Translated string
#'
#' @examples
#' t_module("title", "dashboard")
#' # Translates: "dashboard.title"
t_module <- function(key, module, ...) {
  full_key <- paste0(module, ".", key)
  i18n$t(full_key, ...)
}

#' Translate common UI element
#'
#' Shortcut for translating common elements like buttons, status messages, etc.
#'
#' @param category Category (button, status, message, label, etc.)
#' @param key Element key
#' @return Translated string
#'
#' @examples
#' t_common("button", "save")      # → "common.button.save"
#' t_common("status", "complete")  # → "common.status.complete"
t_common <- function(category, key) {
  i18n$t(paste0("common.", category, ".", key))
}

#' Translate with fallback
#'
#' Attempts translation but returns fallback text if translation is missing
#' Useful for graceful degradation
#'
#' @param key Translation key
#' @param fallback Fallback text if translation missing (defaults to key)
#' @return Translated string or fallback
#'
#' @examples
#' t_safe("missing.key", "Default Text")
t_safe <- function(key, fallback = key) {
  tryCatch({
    result <- i18n$t(key)
    # If translation returns the key itself, it's probably missing
    if (is.null(result) || result == key || result == "") {
      return(fallback)
    }
    result
  }, error = function(e) {
    fallback
  })
}

#' Translate with parameters (string interpolation)
#'
#' Translates a key and replaces placeholders with provided parameters
#' Placeholders in translation strings should use {param_name} format
#'
#' @param key Translation key
#' @param ... Named parameters for interpolation
#' @return Translated string with interpolated values
#'
#' @examples
#' # Translation: "Welcome, {user}!"
#' t_params("welcome.message", user = "John")
#' # Returns: "Welcome, John!"
#'
#' # Translation: "Found {count} results in {time}ms"
#' t_params("search.results", count = 42, time = 156)
#' # Returns: "Found 42 results in 156ms"
t_params <- function(key, ...) {
  template <- i18n$t(key)
  params <- list(...)

  for (name in names(params)) {
    placeholder <- paste0("{", name, "}")
    template <- gsub(placeholder, params[[name]], template, fixed = TRUE)
  }

  template
}

#' Pluralization helper
#'
#' Selects appropriate translation based on count (singular vs plural)
#'
#' @param count Number to determine singular/plural
#' @param key_singular Translation key for singular form
#' @param key_plural Translation key for plural form
#' @return Translated string with count
#'
#' @examples
#' # Translations: "item" and "{count} items"
#' t_plural(1, "item.singular", "item.plural")  # → "1 item"
#' t_plural(5, "item.singular", "item.plural")  # → "5 items"
t_plural <- function(count, key_singular, key_plural) {
  key <- if (count == 1) key_singular else key_plural
  t_params(key, count = count)
}

#' Date translation helper
#'
#' Formats and translates date components based on current language
#'
#' @param date Date object
#' @param format_key Key for date format pattern (default: "common.date_format")
#' @return Formatted date string in current language
#'
#' @examples
#' t_date(Sys.Date())
t_date <- function(date, format_key = "common.date_format") {
  format_pattern <- t_safe(format_key, "%Y-%m-%d")
  format(as.Date(date), format_pattern)
}

#' Tooltip translation helper
#'
#' Creates a tooltip with translated text
#' Useful for consistent tooltip styling
#'
#' @param key Translation key for tooltip text
#' @param placement Tooltip placement ("top", "bottom", "left", "right")
#' @return HTML attributes for tooltip
#'
#' @examples
#' actionButton("btn", "Click", t_tooltip("button.help"))
t_tooltip <- function(key, placement = "top") {
  list(
    `data-toggle` = "tooltip",
    `data-placement` = placement,
    title = i18n$t(key)
  )
}

# ============================================================================
# TRANSLATION CACHE MANAGEMENT
# ============================================================================

# Initialize translation cache environment
.translation_cache <- new.env(parent = emptyenv())

#' Cached translation lookup
#'
#' Caches translated strings to improve performance
#' Automatically cleared when language changes
#'
#' @param key Translation key
#' @param ... Additional parameters
#' @return Cached translated string
t_cached <- function(key, ...) {
  lang <- i18n$get_translation_language()
  cache_key <- paste(key, lang, sep = "_")

  if (exists(cache_key, envir = .translation_cache)) {
    return(get(cache_key, envir = .translation_cache))
  }

  result <- i18n$t(key, ...)
  assign(cache_key, result, envir = .translation_cache)
  result
}

#' Clear translation cache
#'
#' Call this when language changes to force re-translation
clear_translation_cache <- function() {
  rm(list = ls(.translation_cache), envir = .translation_cache)
}

# ============================================================================
# TRANSLATION VALIDATION UTILITIES
# ============================================================================

#' Find all translation keys used in code
#'
#' Scans R files to find all i18n$t() calls
#'
#' @param dirs Directories to scan (default: current, modules, functions)
#' @return Vector of unique translation keys found in code
find_used_translation_keys <- function(dirs = c(".", "modules", "functions")) {
  r_files <- list.files(dirs, pattern = "\\.R$",
                        full.names = TRUE, recursive = TRUE)

  all_keys <- character()

  for (file in r_files) {
    content <- readLines(file, warn = FALSE)
    # Find patterns like i18n$t("key") or i18n$t('key')
    matches <- regmatches(content, gregexpr('i18n\\$t\\(["\']([^"\']+)["\']',
                                           content, perl = TRUE))
    keys <- unlist(lapply(matches, function(m) {
      if (length(m) > 0) {
        sub('i18n\\$t\\(["\']([^"\']+)["\'].*', '\\1', m)
      } else {
        character()
      }
    }))
    all_keys <- c(all_keys, keys)
  }

  unique(all_keys)
}

#' Check for missing translations
#'
#' Compares keys used in code with keys defined in translation file
#'
#' @param translation_file Path to translation JSON file
#' @return List with 'missing_in_file' and 'unused_in_code'
check_translation_completeness <- function(
    translation_file = "translations/translation.json") {

  # Get keys used in code
  used_keys <- find_used_translation_keys()

  # Get keys defined in translation file
  if (file.exists(translation_file)) {
    trans <- jsonlite::fromJSON(translation_file)
    defined_keys <- sapply(trans$translation, function(t) t$en)
  } else {
    defined_keys <- character()
  }

  list(
    missing_in_file = setdiff(used_keys, defined_keys),
    unused_in_code = setdiff(defined_keys, used_keys)
  )
}

#' Validate translation encoding
#'
#' Checks for encoding issues (e.g., Lithuanian characters in pt/it)
#'
#' @param translation_file Path to translation JSON file
#' @return Data frame with encoding issues
validate_translation_encoding <- function(
    translation_file = "translations/translation.json") {

  if (!file.exists(translation_file)) {
    return(data.frame(language = character(), key = character(),
                     issue = character()))
  }

  trans <- jsonlite::fromJSON(translation_file)
  issues <- data.frame(language = character(), key = character(),
                      issue = character(), stringsAsFactors = FALSE)

  for (i in seq_along(trans$translation)) {
    entry <- trans$translation[[i]]
    key <- entry$en

    # Check Portuguese for Lithuanian characters
    if (!is.null(entry$pt) && grepl("[ĄČĖŠįųž]", entry$pt)) {
      issues <- rbind(issues, data.frame(
        language = "pt",
        key = key,
        issue = "Contains Lithuanian characters",
        stringsAsFactors = FALSE
      ))
    }

    # Check Italian for Lithuanian characters
    if (!is.null(entry$it) && grepl("[ĄČĖŠįųž]", entry$it)) {
      issues <- rbind(issues, data.frame(
        language = "it",
        key = key,
        issue = "Contains Lithuanian characters",
        stringsAsFactors = FALSE
      ))
    }
  }

  issues
}

#' Generate translation report
#'
#' Creates a comprehensive report on translation status
#'
#' @param translation_file Path to translation JSON file
#' @return Character vector with report lines
generate_translation_report <- function(
    translation_file = "translations/translation.json") {

  report <- c(
    "# Translation Status Report",
    paste("Generated:", Sys.time()),
    paste("File:", translation_file),
    ""
  )

  if (!file.exists(translation_file)) {
    return(c(report, "ERROR: Translation file not found!"))
  }

  trans <- jsonlite::fromJSON(translation_file)

  # Overall statistics
  report <- c(report,
    "## Overall Statistics",
    paste("- Total entries:", length(trans$translation)),
    paste("- Languages:", paste(trans$languages, collapse = ", ")),
    ""
  )

  # Completeness check
  completeness <- check_translation_completeness(translation_file)
  report <- c(report,
    "## Completeness",
    paste("- Keys used in code:", length(find_used_translation_keys())),
    paste("- Missing in file:", length(completeness$missing_in_file)),
    paste("- Unused in code:", length(completeness$unused_in_code)),
    ""
  )

  if (length(completeness$missing_in_file) > 0) {
    report <- c(report,
      "### Missing translations:",
      paste("-", head(completeness$missing_in_file, 10)),
      if (length(completeness$missing_in_file) > 10)
        paste("... and", length(completeness$missing_in_file) - 10, "more"),
      ""
    )
  }

  # Encoding issues
  encoding_issues <- validate_translation_encoding(translation_file)
  report <- c(report,
    "## Encoding Issues",
    paste("- Total issues found:", nrow(encoding_issues)),
    ""
  )

  if (nrow(encoding_issues) > 0) {
    report <- c(report,
      "### Issues by language:",
      paste("-", encoding_issues$language, ":",
            substr(encoding_issues$key, 1, 50), "...",
            "(", encoding_issues$issue, ")")
    )
  }

  report
}

# ============================================================================
# INITIALIZATION MESSAGE
# ============================================================================

message("[INFO] Translation helper functions loaded successfully")
