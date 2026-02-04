# modules/ai_isa/template_handlers.R
# AI ISA Assistant - Template Loading Handlers
# Purpose: Handle loading of pre-built DAPSI(W)R(M) scenario templates
#
# Extracted from ai_isa_assistant_module.R for better maintainability

#' Setup Template Handlers
#'
#' Registers observeEvent handlers for loading pre-built scenario templates
#' (overfishing, pollution, tourism, climate change)
#'
#' @param input Shiny input object
#' @param session Shiny session object
#' @param rv Reactive values containing AI ISA state
#' @param i18n i18n translator object
setup_template_handlers <- function(input, session, rv, i18n) {

  # Load template modal
  observeEvent(input$load_template, {
    showModal(modalDialog(
      title = i18n$t("modules.isa.ai_assistant.load_example_template"),
      h4(i18n$t("modules.isa.ai_assistant.choose_a_pre_built_scenario")),
      fluidRow(
        column(6,
          actionButton(session$ns("template_overfishing"), i18n$t("modules.isa.ai_assistant.overfishing_in_coastal_waters"),
                      class = "btn-primary btn-block", style = "margin: 5px;")
        ),
        column(6,
          actionButton(session$ns("template_pollution"), i18n$t("modules.isa.ai_assistant.marine_pollution_plastics"),
                      class = "btn-primary btn-block", style = "margin: 5px;")
        )
      ),
      fluidRow(
        column(6,
          actionButton(session$ns("template_tourism"), i18n$t("modules.isa.ai_assistant.coastal_tourism_impacts"),
                      class = "btn-primary btn-block", style = "margin: 5px;")
        ),
        column(6,
          actionButton(session$ns("template_climate"), i18n$t("modules.isa.ai_assistant.climate_change_coral_reefs"),
                      class = "btn-primary btn-block", style = "margin: 5px;")
        )
      ),
      footer = modalButton(i18n$t("common.buttons.cancel"))
    ))
  })

  # Template: Overfishing
  observeEvent(input$template_overfishing, {
    rv$context <- list(
      project_name = "Overfishing Management",
      ecosystem_type = "Coastal waters",
      main_issue = "Declining fish stocks due to overfishing"
    )
    rv$elements <- list(
      drivers = list(
        list(name = "Food security", description = "", timestamp = Sys.time()),
        list(name = "Economic development", description = "", timestamp = Sys.time())
      ),
      activities = list(
        list(name = "Commercial fishing", description = "", timestamp = Sys.time()),
        list(name = "Recreational fishing", description = "", timestamp = Sys.time())
      ),
      pressures = list(
        list(name = "Overfishing", description = "", timestamp = Sys.time()),
        list(name = "Bycatch of non-target species", description = "", timestamp = Sys.time())
      ),
      states = list(
        list(name = "Declining fish stocks", description = "", timestamp = Sys.time()),
        list(name = "Altered food webs", description = "", timestamp = Sys.time())
      ),
      impacts = list(
        list(name = "Reduced fish catch", description = "", timestamp = Sys.time()),
        list(name = "Loss of biodiversity value", description = "", timestamp = Sys.time())
      ),
      welfare = list(
        list(name = "Loss of livelihoods for fishers", description = "", timestamp = Sys.time()),
        list(name = "Food insecurity", description = "", timestamp = Sys.time())
      ),
      responses = list(
        list(name = "Fishing quotas and limits", description = "", timestamp = Sys.time()),
        list(name = "Marine protected areas", description = "", timestamp = Sys.time())
      )
    )

    rv$suggested_connections <- list(
      list(from = "Food security", to = "Commercial fishing", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
      list(from = "Economic development", to = "Commercial fishing", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 2, to_index = 1),
      list(from = "Economic development", to = "Recreational fishing", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 2),
      list(from = "Commercial fishing", to = "Overfishing", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 1),
      list(from = "Commercial fishing", to = "Bycatch of non-target species", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 2),
      list(from = "Recreational fishing", to = "Overfishing", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "weak", matrix = "p_a", from_index = 2, to_index = 1),
      list(from = "Overfishing", to = "Declining fish stocks", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
      list(from = "Overfishing", to = "Altered food webs", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 1, to_index = 2),
      list(from = "Bycatch of non-target species", to = "Altered food webs", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 2),
      list(from = "Declining fish stocks", to = "Reduced fish catch", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 1),
      list(from = "Altered food webs", to = "Loss of biodiversity value", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 2),
      list(from = "Reduced fish catch", to = "Loss of livelihoods for fishers", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 1, to_index = 1),
      list(from = "Reduced fish catch", to = "Food insecurity", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "medium", matrix = "gb_es", from_index = 1, to_index = 2),
      list(from = "Loss of biodiversity value", to = "Loss of livelihoods for fishers", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "weak", matrix = "gb_es", from_index = 2, to_index = 1)
    )

    rv$approved_connections <- seq_along(rv$suggested_connections)
    rv$current_step <- 10
    removeModal()
    showNotification(i18n$t("modules.isa.overfishing_template_loaded_with_example_connectio"), type = "message", duration = 5)
  })

  # Template: Marine Pollution
  observeEvent(input$template_pollution, {
    rv$context <- list(
      project_name = "Marine Plastic Pollution",
      ecosystem_type = "Coastal waters",
      main_issue = "Plastic pollution and marine litter"
    )
    rv$elements <- list(
      drivers = list(
        list(name = "Economic development", description = "", timestamp = Sys.time()),
        list(name = "Consumer demand", description = "", timestamp = Sys.time())
      ),
      activities = list(
        list(name = "Coastal development", description = "", timestamp = Sys.time()),
        list(name = "Tourism", description = "", timestamp = Sys.time()),
        list(name = "Shipping", description = "", timestamp = Sys.time())
      ),
      pressures = list(
        list(name = "Marine litter and plastics", description = "", timestamp = Sys.time()),
        list(name = "Chemical pollution", description = "", timestamp = Sys.time())
      ),
      states = list(
        list(name = "Water quality decline", description = "", timestamp = Sys.time()),
        list(name = "Habitat degradation", description = "", timestamp = Sys.time())
      ),
      impacts = list(
        list(name = "Loss of tourism revenue", description = "", timestamp = Sys.time()),
        list(name = "Reduced water quality for recreation", description = "", timestamp = Sys.time())
      ),
      welfare = list(
        list(name = "Health impacts from contamination", description = "", timestamp = Sys.time()),
        list(name = "Economic losses in tourism", description = "", timestamp = Sys.time())
      ),
      responses = list(
        list(name = "Pollution regulations", description = "", timestamp = Sys.time()),
        list(name = "Beach cleanup programs", description = "", timestamp = Sys.time())
      )
    )

    rv$suggested_connections <- list(
      list(from = "Economic development", to = "Coastal development", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
      list(from = "Economic development", to = "Tourism", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 2),
      list(from = "Consumer demand", to = "Tourism", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 2),
      list(from = "Economic development", to = "Shipping", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 3),
      list(from = "Coastal development", to = "Marine litter and plastics", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 1),
      list(from = "Tourism", to = "Marine litter and plastics", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "strong", matrix = "p_a", from_index = 2, to_index = 1),
      list(from = "Shipping", to = "Marine litter and plastics", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "medium", matrix = "p_a", from_index = 3, to_index = 1),
      list(from = "Coastal development", to = "Chemical pollution", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "weak", matrix = "p_a", from_index = 1, to_index = 2),
      list(from = "Marine litter and plastics", to = "Water quality decline", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
      list(from = "Marine litter and plastics", to = "Habitat degradation", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 1, to_index = 2),
      list(from = "Chemical pollution", to = "Water quality decline", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 2, to_index = 1),
      list(from = "Water quality decline", to = "Reduced water quality for recreation", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 2),
      list(from = "Habitat degradation", to = "Loss of tourism revenue", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "medium", matrix = "es_mpf", from_index = 2, to_index = 1),
      list(from = "Reduced water quality for recreation", to = "Health impacts from contamination", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 1),
      list(from = "Loss of tourism revenue", to = "Economic losses in tourism", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 1, to_index = 2)
    )

    rv$approved_connections <- seq_along(rv$suggested_connections)
    rv$current_step <- 10
    removeModal()
    showNotification(i18n$t("modules.isa.marine_pollution_template_loaded_with_example_conn"), type = "message", duration = 5)
  })

  # Template: Coastal Tourism
  observeEvent(input$template_tourism, {
    rv$context <- list(
      project_name = "Coastal Tourism Management",
      ecosystem_type = "Coastal waters",
      main_issue = "Tourism impacts on coastal ecosystems"
    )
    rv$elements <- list(
      drivers = list(
        list(name = "Recreation and leisure", description = "", timestamp = Sys.time()),
        list(name = "Economic development", description = "", timestamp = Sys.time())
      ),
      activities = list(
        list(name = "Tourism and recreation", description = "", timestamp = Sys.time()),
        list(name = "Coastal development (hotels, infrastructure)", description = "", timestamp = Sys.time())
      ),
      pressures = list(
        list(name = "Physical habitat damage", description = "", timestamp = Sys.time()),
        list(name = "Pollution from tourists", description = "", timestamp = Sys.time())
      ),
      states = list(
        list(name = "Habitat degradation", description = "", timestamp = Sys.time()),
        list(name = "Loss of biodiversity", description = "", timestamp = Sys.time())
      ),
      impacts = list(
        list(name = "Reduced coastal protection", description = "", timestamp = Sys.time()),
        list(name = "Loss of cultural and aesthetic value", description = "", timestamp = Sys.time())
      ),
      welfare = list(
        list(name = "Reduced quality of life for residents", description = "", timestamp = Sys.time()),
        list(name = "Loss of cultural identity", description = "", timestamp = Sys.time())
      ),
      responses = list(
        list(name = "Sustainable tourism practices", description = "", timestamp = Sys.time()),
        list(name = "Coastal zone management", description = "", timestamp = Sys.time())
      )
    )

    rv$suggested_connections <- list(
      list(from = "Recreation and leisure", to = "Tourism and recreation", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
      list(from = "Economic development", to = "Tourism and recreation", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 1),
      list(from = "Economic development", to = "Coastal development (hotels, infrastructure)", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 2, to_index = 2),
      list(from = "Tourism and recreation", to = "Physical habitat damage", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "medium", matrix = "p_a", from_index = 1, to_index = 1),
      list(from = "Tourism and recreation", to = "Pollution from tourists", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 2),
      list(from = "Coastal development (hotels, infrastructure)", to = "Physical habitat damage", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "strong", matrix = "p_a", from_index = 2, to_index = 1),
      list(from = "Physical habitat damage", to = "Habitat degradation", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
      list(from = "Physical habitat damage", to = "Loss of biodiversity", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 1, to_index = 2),
      list(from = "Pollution from tourists", to = "Habitat degradation", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 1),
      list(from = "Habitat degradation", to = "Reduced coastal protection", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 1),
      list(from = "Loss of biodiversity", to = "Loss of cultural and aesthetic value", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 2),
      list(from = "Reduced coastal protection", to = "Reduced quality of life for residents", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "medium", matrix = "gb_es", from_index = 1, to_index = 1),
      list(from = "Loss of cultural and aesthetic value", to = "Reduced quality of life for residents", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 1),
      list(from = "Loss of cultural and aesthetic value", to = "Loss of cultural identity", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 2)
    )

    rv$approved_connections <- seq_along(rv$suggested_connections)
    rv$current_step <- 10
    removeModal()
    showNotification(i18n$t("modules.isa.coastal_tourism_template_loaded_with_example_conne"), type = "message", duration = 5)
  })

  # Template: Climate Change
  observeEvent(input$template_climate, {
    rv$context <- list(
      project_name = "Climate Change Impacts on Coral Reefs",
      ecosystem_type = "Coral reefs",
      main_issue = "Coral bleaching from rising temperatures"
    )
    rv$elements <- list(
      drivers = list(
        list(name = "Energy needs", description = "", timestamp = Sys.time()),
        list(name = "Economic development", description = "", timestamp = Sys.time())
      ),
      activities = list(
        list(name = "Greenhouse gas emissions", description = "", timestamp = Sys.time()),
        list(name = "Coastal development", description = "", timestamp = Sys.time())
      ),
      pressures = list(
        list(name = "Ocean temperature rise", description = "", timestamp = Sys.time()),
        list(name = "Ocean acidification", description = "", timestamp = Sys.time())
      ),
      states = list(
        list(name = "Coral bleaching", description = "", timestamp = Sys.time()),
        list(name = "Loss of coral reef ecosystem", description = "", timestamp = Sys.time())
      ),
      impacts = list(
        list(name = "Loss of fisheries productivity", description = "", timestamp = Sys.time()),
        list(name = "Reduced coastal protection from storms", description = "", timestamp = Sys.time())
      ),
      welfare = list(
        list(name = "Loss of livelihoods for fishing communities", description = "", timestamp = Sys.time()),
        list(name = "Increased vulnerability to storms", description = "", timestamp = Sys.time())
      ),
      responses = list(
        list(name = "Climate change mitigation", description = "", timestamp = Sys.time()),
        list(name = "Coral reef restoration", description = "", timestamp = Sys.time())
      )
    )

    rv$suggested_connections <- list(
      list(from = "Energy needs", to = "Greenhouse gas emissions", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 1, to_index = 1),
      list(from = "Economic development", to = "Greenhouse gas emissions", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "strong", matrix = "a_d", from_index = 2, to_index = 1),
      list(from = "Economic development", to = "Coastal development", from_category = "drivers", to_category = "activities",
           polarity = "+", strength = "medium", matrix = "a_d", from_index = 2, to_index = 2),
      list(from = "Greenhouse gas emissions", to = "Ocean temperature rise", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 1),
      list(from = "Greenhouse gas emissions", to = "Ocean acidification", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "strong", matrix = "p_a", from_index = 1, to_index = 2),
      list(from = "Coastal development", to = "Ocean temperature rise", from_category = "activities", to_category = "pressures",
           polarity = "+", strength = "weak", matrix = "p_a", from_index = 2, to_index = 1),
      list(from = "Ocean temperature rise", to = "Coral bleaching", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 1),
      list(from = "Ocean temperature rise", to = "Loss of coral reef ecosystem", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "strong", matrix = "mpf_p", from_index = 1, to_index = 2),
      list(from = "Ocean acidification", to = "Coral bleaching", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 1),
      list(from = "Ocean acidification", to = "Loss of coral reef ecosystem", from_category = "pressures", to_category = "states",
           polarity = "-", strength = "medium", matrix = "mpf_p", from_index = 2, to_index = 2),
      list(from = "Coral bleaching", to = "Loss of fisheries productivity", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 1, to_index = 1),
      list(from = "Loss of coral reef ecosystem", to = "Loss of fisheries productivity", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 1),
      list(from = "Loss of coral reef ecosystem", to = "Reduced coastal protection from storms", from_category = "states", to_category = "impacts",
           polarity = "-", strength = "strong", matrix = "es_mpf", from_index = 2, to_index = 2),
      list(from = "Loss of fisheries productivity", to = "Loss of livelihoods for fishing communities", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 1, to_index = 1),
      list(from = "Reduced coastal protection from storms", to = "Increased vulnerability to storms", from_category = "impacts", to_category = "welfare",
           polarity = "-", strength = "strong", matrix = "gb_es", from_index = 2, to_index = 2)
    )

    rv$approved_connections <- seq_along(rv$suggested_connections)
    rv$current_step <- 10
    removeModal()
    showNotification(i18n$t("modules.isa.ai_assistant.climate_change_template_loaded_with_example_connections"), type = "message", duration = 5)
  })
}
