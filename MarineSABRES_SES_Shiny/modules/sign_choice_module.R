# modules/sign_choice_module.R
# "Choose the sign for new connections" dialog (evidenced polarity, Task 6).
#
# Shared by Standard Entry saves, Standard Entry loads/imports and the sidebar
# Import Data menu: links that arrive without a sign (new LinkedX ticks, or
# LinkedX-only workbooks) are listed one per row with the shared sign picker.
# Confirm is enabled only once every row is signed; Cancel hands back NULL so
# the caller can leave those links out.
#
# Server-only: the dialog is a modalDialog built server-side, so no static UI.

#' Sign-choice dialog server
#'
#' @param id module id
#' @param i18n translator
#' @return list(open = function(links, labels, on_done), pending = function())
#'   `open()` shows the dialog for an unsigned-link record (data.frame with
#'   src_id, tgt_id, transposed; see rebuild_matrix_from_linked()). `labels`
#'   maps element ids to names for display. `on_done(signs)` receives a named
#'   chr vector ("<src_id>|<tgt_id>" -> "+"/"-") on Confirm, or NULL on Cancel.
#'   `pending()` returns NULL when no dialog is open, else
#'   list(input_ids, keys) for the open dialog (used by tests).
sign_choice_server <- function(id, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    state <- reactiveValues(gen = 0L, input_ids = NULL, keys = NULL)
    on_done_cb <- NULL

    row_label <- function(links, k, labels) {
      lab <- function(x) {
        v <- if (!is.null(labels) && x %in% names(labels)) unname(labels[[x]]) else NA_character_
        if (is.na(v) || !nzchar(v)) x else v
      }
      src <- as.character(links$src_id[k]); tgt <- as.character(links$tgt_id[k])
      # gb_r is recorded R|GB (rebuild orientation) but the link runs GB -> R
      if (isTRUE(links$transposed[k])) paste(lab(tgt), "→", lab(src))
      else paste(lab(src), "→", lab(tgt))
    }

    open <- function(links, labels, on_done) {
      if (!is.data.frame(links) || nrow(links) == 0) return(invisible(FALSE))
      gen <- isolate(state$gen) + 1L
      # ids carry the open's generation so a new dialog never inherits the
      # picks of an earlier one (inputs persist server-side once set)
      input_ids <- paste0("sign_", gen, "_", seq_len(nrow(links)))
      keys <- paste0(links$src_id, "|", links$tgt_id)
      state$gen <- gen
      state$input_ids <- input_ids
      state$keys <- keys
      on_done_cb <<- on_done
      rows <- lapply(seq_len(nrow(links)), function(k) {
        div(class = "sign-choice-row d-flex align-items-center gap-3 mb-2",
            div(class = "sign-choice-label flex-grow-1", row_label(links, k, labels)),
            polarity_picker_input(ns(input_ids[k]), i18n))
      })
      showModal(modalDialog(
        title = i18n$t("common.polarity.sign_dialog_title"),
        do.call(tagList, rows),
        footer = tagList(
          actionButton(ns("cancel"), i18n$t("common.buttons.cancel")),
          uiOutput(ns("confirm_ui"), inline = TRUE)
        ),
        easyClose = FALSE, size = "m"
      ))
      invisible(TRUE)
    }

    current_signs <- function() {
      ids <- state$input_ids
      if (length(ids) == 0) return(character(0))
      s <- vapply(ids, function(i) read_polarity_pick(input[[i]]), character(1))
      setNames(s, state$keys)
    }

    output$confirm_ui <- renderUI({
      s <- current_signs()
      ready <- length(s) > 0 && !anyNA(s)
      btn <- actionButton(ns("confirm"), i18n$t("common.buttons.confirm"), class = "btn-primary")
      if (!ready) btn <- tagAppendAttributes(btn, disabled = "disabled")
      btn
    })

    finish <- function(signs) {
      cb <- on_done_cb
      on_done_cb <<- NULL
      state$input_ids <- NULL
      state$keys <- NULL
      removeModal()
      if (is.function(cb)) cb(signs)
    }

    observeEvent(input$confirm, {
      s <- current_signs()
      if (length(s) == 0 || anyNA(s)) return()   # server-side guard for the disabled button
      finish(s)
    })

    observeEvent(input$cancel, {
      if (is.null(isolate(state$input_ids))) return()
      finish(NULL)
    })

    pending <- function() {
      ids <- isolate(state$input_ids)
      if (is.null(ids)) return(NULL)
      list(input_ids = ids, keys = isolate(state$keys))
    }

    list(open = open, pending = pending)
  })
}
