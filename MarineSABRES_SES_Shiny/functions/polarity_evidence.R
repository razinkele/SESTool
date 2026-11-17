# functions/polarity_evidence.R
# Evidenced polarity: a connection's sign is pre-filled only when it is backed
# by evidence; otherwise the user must pick it (shared sign picker below).

#' Evidence-backed sign for a connection
#'
#' Evidence is an exact knowledge-base match carrying a non-empty citation.
#' Synonym matches, heuristics and defaults are never evidence.
#' @return list(polarity = "+"|"-"|NA_character_, source = character(1)|NA_character_)
evidenced_polarity <- function(from_name, from_type, to_name, to_type) {
  none <- list(polarity = NA_character_, source = NA_character_)
  if (!exists("lookup_knowledge_base", mode = "function")) return(none)
  kb <- tryCatch(lookup_knowledge_base(from_name, from_type, to_name, to_type),
                 error = function(e) NULL)
  if (is.null(kb) || !identical(kb$match_quality, "exact")) return(none)
  src <- kb$source
  if (is.null(src) || length(src) != 1L || is.na(src) || !nzchar(trimws(src))) return(none)
  if (!(length(kb$polarity) == 1L && kb$polarity %in% c("+", "-"))) return(none)
  list(polarity = kb$polarity, source = src)
}

#' Indices of connections that carry a sign (the only ones that can be approved)
connections_with_sign <- function(conns) {
  which(vapply(conns, function(cn) !is.na(read_polarity_pick(cn$polarity)), logical(1)))
}

#' Map a picker input value to a sign ("+", "-" or NA_character_)
read_polarity_pick <- function(x) {
  if (is.null(x) || length(x) != 1L || is.na(x)) return(NA_character_)
  x <- as.character(x)
  if (x %in% c("+", "-")) x else NA_character_
}

#' Shared sign picker: Reinforcing (+) / Opposing (-), nothing selected when unset
#' @param selected "+", "-" or NA (unset)
#' @param evidence_source citation shown as "from: <source>" when given
polarity_picker_input <- function(inputId, i18n, selected = NA_character_,
                                  evidence_source = NA_character_) {
  sel <- read_polarity_pick(selected)
  has_src <- length(evidence_source) == 1L && !is.na(evidence_source) &&
    nzchar(trimws(evidence_source))
  choices <- c("+", "-")
  names(choices) <- c(i18n$t("common.choices.polarity_reinforcing"),
                      i18n$t("common.choices.polarity_opposing"))
  tags$div(
    class = "polarity-picker",
    shinyWidgets::radioGroupButtons(
      inputId = inputId,
      label = NULL,
      choices = choices,
      selected = if (is.na(sel)) character(0) else sel,
      status = "outline-primary",
      size = "sm"
    ),
    # Always rendered; the stylesheet hides it while a sign button is active
    tags$div(class = "polarity-picker-prompt text-warning small",
             i18n$t("common.polarity.choose_sign")),
    if (has_src) {
      tags$div(id = paste0(inputId, "_source"),
               class = "polarity-picker-source text-muted small",
               paste(i18n$t("common.polarity.from_source"), evidence_source))
    }
  )
}
