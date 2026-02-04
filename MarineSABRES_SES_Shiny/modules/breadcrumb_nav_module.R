# modules/breadcrumb_nav_module.R
# Breadcrumb navigation component to show user's location and enable easy navigation
# Addresses user feedback: "unclear how to go back or correct entries"

# UI Component - Breadcrumb Trail
breadcrumb_ui <- function(id) {
  ns <- NS(id)

  tags$div(
    id = ns("breadcrumb_container"),
    class = "breadcrumb-navigation",

    # CSS for breadcrumbs
    tags$style(HTML("
      .breadcrumb-navigation {
        background: #f8f9fa;
        border-bottom: 1px solid #dee2e6;
        padding: 12px 20px;
        margin: -15px -15px 20px -15px;
        font-size: 14px;
      }

      .breadcrumb-trail {
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        margin: 0;
        padding: 0;
        list-style: none;
      }

      .breadcrumb-item {
        display: flex;
        align-items: center;
        color: #6c757d;
      }

      .breadcrumb-item.active {
        color: #495057;
        font-weight: 600;
      }

      .breadcrumb-link {
        color: #007bff;
        text-decoration: none;
        cursor: pointer;
        transition: color 0.2s;
      }

      .breadcrumb-link:hover {
        color: #0056b3;
        text-decoration: underline;
      }

      .breadcrumb-separator {
        margin: 0 10px;
        color: #6c757d;
      }

      .breadcrumb-icon {
        margin-right: 6px;
        color: #6c757d;
      }

      .breadcrumb-home {
        color: #007bff;
        cursor: pointer;
        font-size: 16px;
        transition: color 0.2s;
      }

      .breadcrumb-home:hover {
        color: #0056b3;
      }
    ")),

    # Breadcrumb content (will be updated dynamically)
    uiOutput(ns("breadcrumb_trail"))
  )
}

# Server Function
breadcrumb_server <- function(id, i18n, parent_session = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values for breadcrumb state
    breadcrumb_state <- reactiveValues(
      current_page = "home",
      history = list(),
      page_titles = list()
    )

    # Define page hierarchy and titles
    page_structure <- list(
      home = list(
        title_key = "Home",
        icon = "home",
        parent = NULL
      ),
      entry_point = list(
        title_key = "Entry Point",
        icon = "compass",
        parent = "home"
      ),
      create_ses = list(
        title_key = "Create SES",
        icon = "layer-group",
        parent = "home"
      ),
      create_ses_choose = list(
        title_key = "Choose Method",
        icon = "hand-pointer",
        parent = "create_ses"
      ),
      create_ses_standard = list(
        title_key = "Standard Entry",
        icon = "edit",
        parent = "create_ses_choose"
      ),
      create_ses_ai = list(
        title_key = "AI Assistant",
        icon = "robot",
        parent = "create_ses_choose"
      ),
      create_ses_template = list(
        title_key = "Template-Based",
        icon = "file-alt",
        parent = "create_ses_choose"
      ),
      cld_visualization = list(
        title_key = "Visualize CLD",
        icon = "project-diagram",
        parent = "home"
      ),
      analysis_tools = list(
        title_key = "Analysis Tools",
        icon = "chart-line",
        parent = "home"
      ),
      response_measures = list(
        title_key = "Response Measures",
        icon = "lightbulb",
        parent = "home"
      ),
      response_scenarios = list(
        title_key = "Scenario Builder",
        icon = "sitemap",
        parent = "home"
      ),
      response_validation = list(
        title_key = "Validation",
        icon = "check-circle",
        parent = "home"
      )
    )

    # Function to build breadcrumb trail for a page
    build_trail <- function(page_id) {
      if (!page_id %in% names(page_structure)) {
        return(list())
      }

      trail <- list()
      current <- page_id

      # Build trail from current page back to root
      while (!is.null(current)) {
        page_info <- page_structure[[current]]
        trail <- c(list(list(
          id = current,
          title = i18n$t(page_info$title_key),
          icon = page_info$icon
        )), trail)
        current <- page_info$parent
      }

      return(trail)
    }

    # Render breadcrumb trail
    output$breadcrumb_trail <- renderUI({
      trail <- build_trail(breadcrumb_state$current_page)

      if (length(trail) == 0) {
        return(NULL)
      }

      # Build breadcrumb items
      items <- lapply(seq_along(trail), function(i) {
        item <- trail[[i]]
        is_last <- (i == length(trail))

        # Create the item element
        item_content <- tags$div(
          class = paste0("breadcrumb-item", if (is_last) " active" else ""),

          if (i == 1) {
            # Home icon (always clickable unless it's the only item)
            if (!is_last) {
              actionLink(
                ns(paste0("nav_", item$id)),
                icon(item$icon),
                class = "breadcrumb-home"
              )
            } else {
              icon(item$icon, class = "breadcrumb-icon")
            }
          } else {
            # Regular breadcrumb item
            if (!is_last) {
              actionLink(
                ns(paste0("nav_", item$id)),
                item$title,
                class = "breadcrumb-link"
              )
            } else {
              span(
                icon(item$icon, class = "breadcrumb-icon"),
                item$title
              )
            }
          }
        )

        # Add separator if not last item
        if (!is_last) {
          list(
            item_content,
            tags$span(
              class = "breadcrumb-separator",
              "›"
            )
          )
        } else {
          item_content
        }
      })

      tags$nav(
        class = "breadcrumb-trail",
        items
      )
    })

    # Create observers for all navigation links
    lapply(names(page_structure), function(page_id) {
      observeEvent(input[[paste0("nav_", page_id)]], {
        # Navigate to the clicked page
        if (!is.null(parent_session)) {
          updateTabItems(parent_session, "sidebar_menu", page_id)
        }

        # Update current page
        breadcrumb_state$current_page <- page_id

        # Log navigation
        debug_log(sprintf("Navigated to: %s", page_id), "BREADCRUMB-NAV")
      })
    })

    # Return control functions
    list(
      set_current_page = function(page_id) {
        breadcrumb_state$current_page <- page_id
      },
      get_current_page = function() {
        breadcrumb_state$current_page
      },
      add_page = function(page_id, title_key, icon, parent = "home") {
        page_structure[[page_id]] <<- list(
          title_key = title_key,
          icon = icon,
          parent = parent
        )
      }
    )
  })
}

# Helper function to create breadcrumb translations
breadcrumb_translations <- function() {
  list(
    list(
      en = "Home",
      es = "Inicio",
      fr = "Accueil",
      de = "Startseite",
      lt = "Pradžia",
      pt = "Início",
      it = "Home"
    ),
    list(
      en = "Entry Point",
      es = "Punto de Entrada",
      fr = "Point d'Entrée",
      de = "Einstiegspunkt",
      lt = "Įėjimo Taškas",
      pt = "Ponto de Entrada",
      it = "Punto di Ingresso"
    ),
    list(
      en = "Choose Method",
      es = "Elegir Método",
      fr = "Choisir la Méthode",
      de = "Methode Wählen",
      lt = "Pasirinkti Metodą",
      pt = "Escolher Método",
      it = "Scegli Metodo"
    ),
    list(
      en = "Standard Entry",
      es = "Entrada Estándar",
      fr = "Entrée Standard",
      de = "Standard-Eingabe",
      lt = "Standartinis Įrašas",
      pt = "Entrada Padrão",
      it = "Inserimento Standard"
    ),
    list(
      en = "AI Assistant",
      es = "Asistente IA",
      fr = "Assistant IA",
      de = "KI-Assistent",
      lt = "DI Asistentas",
      pt = "Assistente IA",
      it = "Assistente IA"
    ),
    list(
      en = "Template-Based",
      es = "Basado en Plantilla",
      fr = "Basé sur un Modèle",
      de = "Vorlagenbasiert",
      lt = "Pagal Šabloną",
      pt = "Baseado em Modelo",
      it = "Basato su Modello"
    ),
    list(
      en = "Visualize CLD",
      es = "Visualizar DCL",
      fr = "Visualiser le DCL",
      de = "CLD Visualisieren",
      lt = "Vizualizuoti CLD",
      pt = "Visualizar DCL",
      it = "Visualizza DCL"
    ),
    list(
      en = "Analysis Tools",
      es = "Herramientas de Análisis",
      fr = "Outils d'Analyse",
      de = "Analysewerkzeuge",
      lt = "Analizės Įrankiai",
      pt = "Ferramentas de Análise",
      it = "Strumenti di Analisi"
    ),
    list(
      en = "Response Measures",
      es = "Medidas de Respuesta",
      fr = "Mesures de Réponse",
      de = "Reaktionsmaßnahmen",
      lt = "Atsako Priemonės",
      pt = "Medidas de Resposta",
      it = "Misure di Risposta"
    ),
    list(
      en = "Scenario Builder",
      es = "Constructor de Escenarios",
      fr = "Constructeur de Scénarios",
      de = "Szenario-Builder",
      lt = "Scenarijų Kūrimas",
      pt = "Construtor de Cenários",
      it = "Costruttore di Scenari"
    ),
    list(
      en = "Validation",
      es = "Validación",
      fr = "Validation",
      de = "Validierung",
      lt = "Patvirtinimas",
      pt = "Validação",
      it = "Validazione"
    )
  )
}
