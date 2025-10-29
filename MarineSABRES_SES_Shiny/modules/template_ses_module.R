# modules/template_ses_module.R
# Template-Based SES Creation Module
# Purpose: Allow users to start from pre-built SES templates

# ============================================================================
# TEMPLATE LIBRARY
# ============================================================================

# Define available templates
# Note: Use i18n$t() for names/descriptions in renderUI, not here in data structure
# This data structure is initialized before i18n is available
ses_templates <- list(
  fisheries = list(
    name_key = "Fisheries Management",
    description_key = "Common fisheries management scenario with overfishing pressures",
    icon = "fish",
    category_key = "Extraction",
    drivers = data.frame(
      ID = c("D001", "D002", "D003"),
      Name = c("Population Growth", "Economic Development", "Market Demand"),
      Type = c("Driver", "Driver", "Driver"),
      Description = c("Population change rate", "GDP growth", "Fish price index"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001", "A002"),
      Name = c("Commercial Fishing", "Recreational Fishing"),
      Type = c("Activity", "Activity"),
      Description = c("Fishing effort (vessel-days)", "Angler-days"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P001", "P002"),
      Name = c("Overfishing", "Bycatch"),
      Type = c("EnMP", "EnMP"),
      Description = c("Fishing mortality", "Non-target species mortality"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MPF001", "MPF002"),
      Name = c("Fish Stock Decline", "Ecosystem Disruption"),
      Type = c("State Change", "State Change"),
      Description = c("Stock biomass", "Trophic level index"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES001", "ES002"),
      Name = c("Fish Provision", "Marine Biodiversity"),
      Type = c("Provisioning", "Supporting"),
      Description = c("Fish catch", "Species richness"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB001", "GB002"),
      Name = c("Food Security", "Fisher Livelihoods"),
      Type = c("Welfare", "Welfare"),
      Description = c("Fish consumption per capita", "Fishing income"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    # Example connections between elements
    # Format: "+strength:confidence" where confidence is 1-5 (1=Very Low, 5=Very High)
    adjacency_matrices = list(
      # Goods & Benefits (rows) → Ecosystem Services (cols)
      gb_es = matrix(c(
        "+strong:4", "",          # Food Security → Fish Provision (high confidence), Biodiversity
        "+medium:3", ""           # Fisher Livelihoods → Fish Provision (medium confidence), Biodiversity
      ), nrow = 2, ncol = 2, byrow = TRUE),

      # Ecosystem Services (rows) → Marine Processes (cols)
      es_mpf = matrix(c(
        "-strong:5", "",          # Fish Provision ← Stock Decline (very high confidence), Disruption
        "", "-medium:4"           # Biodiversity ← Stock Decline, Disruption (high confidence)
      ), nrow = 2, ncol = 2, byrow = TRUE),

      # Marine Processes (rows) → Pressures (cols)
      mpf_p = matrix(c(
        "-strong:5", "-weak:3",   # Stock Decline ← Overfishing (very high), Bycatch (medium)
        "-medium:4", "-medium:3"  # Disruption ← Overfishing (high), Bycatch (medium)
      ), nrow = 2, ncol = 2, byrow = TRUE),

      # Pressures (rows) → Activities (cols)
      p_a = matrix(c(
        "+strong:5", "+weak:4",   # Overfishing ← Commercial (very high), Recreational (high)
        "+medium:4", ""           # Bycatch ← Commercial (high), Recreational
      ), nrow = 2, ncol = 2, byrow = TRUE),

      # Activities (rows) → Drivers (cols)
      a_d = matrix(c(
        "+strong:4", "+strong:4", "+medium:5",  # Commercial ← Population, Economic, Market
        "", "+weak:3", "+weak:3"                # Recreational ← Population, Economic, Market
      ), nrow = 2, ncol = 3, byrow = TRUE),

      # Drivers (rows) → Goods & Benefits (cols)
      d_gb = matrix(c(
        "+medium:3", "",          # Population → Food Security (medium), Livelihoods
        "+weak:3", "+medium:4",   # Economic → Food Security (medium), Livelihoods (high)
        "+weak:5", "+weak:4"      # Market → Food Security (very high), Livelihoods (high)
      ), nrow = 3, ncol = 2, byrow = TRUE)
    )
  ),

  tourism = list(
    name_key = "Coastal Tourism",
    description_key = "Tourism development impacts on coastal ecosystems",
    icon = "umbrella-beach",
    category_key = "Recreation",
    drivers = data.frame(
      ID = c("D001", "D002", "D003"),
      Name = c("Tourism Demand", "Infrastructure Development", "Climate Amenity"),
      Type = c("Driver", "Driver", "Driver"),
      Description = c("Tourist arrivals", "Hotel capacity", "Beach quality index"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001", "A002", "A003"),
      Name = c("Beach Tourism", "Water Sports", "Coastal Development"),
      Type = c("Activity", "Activity", "Activity"),
      Description = c("Beach visitor-days", "Activity permits", "Building permits"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P001", "P002", "P003"),
      Name = c("Coastal Pollution", "Habitat Destruction", "Noise Disturbance"),
      Type = c("EnMP", "EnMP", "EnMP"),
      Description = c("Water quality", "Habitat loss", "Noise levels"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MPF001", "MPF002"),
      Name = c("Beach Degradation", "Marine Habitat Loss"),
      Type = c("State Change", "State Change"),
      Description = c("Beach width", "Habitat area"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES001", "ES002", "ES003"),
      Name = c("Recreation Opportunities", "Coastal Protection", "Aesthetic Value"),
      Type = c("Cultural", "Regulating", "Cultural"),
      Description = c("Beach accessibility", "Wave attenuation", "Scenic beauty rating"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB001", "GB002"),
      Name = c("Tourism Revenue", "Quality of Life"),
      Type = c("Welfare", "Welfare"),
      Description = c("Tourism expenditure", "Resident satisfaction"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    adjacency_matrices = list(
      gb_es = matrix(c(
        "+strong:4", "", "+medium:3",     # Revenue → Recreation, Protection, Aesthetic
        "", "", "+strong:4"               # Quality → Recreation, Protection, Aesthetic
      ), nrow = 2, ncol = 3, byrow = TRUE),
      es_mpf = matrix(c(
        "-medium:4", "-weak:3",           # Recreation ← Beach Degradation, Habitat Loss
        "", "-strong:5",                  # Protection ← Beach Degradation, Habitat Loss
        "-weak:3", "-medium:4"            # Aesthetic ← Beach Degradation, Habitat Loss
      ), nrow = 3, ncol = 2, byrow = TRUE),
      mpf_p = matrix(c(
        "-weak:3", "-strong:5", "",       # Beach Degradation ← Pollution, Destruction, Noise
        "", "-strong:5", "-weak:3"        # Habitat Loss ← Pollution, Destruction, Noise
      ), nrow = 2, ncol = 3, byrow = TRUE),
      p_a = matrix(c(
        "+medium:4", "+weak:3", "",       # Pollution ← Beach Tourism, Water Sports, Development
        "", "", "+strong:5",              # Destruction ← Beach Tourism, Water Sports, Development
        "+weak:3", "+medium:4", ""        # Noise ← Beach Tourism, Water Sports, Development
      ), nrow = 3, ncol = 3, byrow = TRUE),
      a_d = matrix(c(
        "+strong:5", "", "",              # Beach Tourism ← Demand, Infrastructure, Climate
        "+medium:4", "", "+weak:3",       # Water Sports ← Demand, Infrastructure, Climate
        "", "+strong:5", ""               # Development ← Demand, Infrastructure, Climate
      ), nrow = 3, ncol = 3, byrow = TRUE),
      d_gb = matrix(c(
        "+medium:4", "",                  # Demand → Revenue, Quality
        "+strong:5", "+weak:3",           # Infrastructure → Revenue, Quality
        "+weak:3", "+medium:4"            # Climate → Revenue, Quality
      ), nrow = 3, ncol = 2, byrow = TRUE)
    )
  ),

  aquaculture = list(
    name_key = "Aquaculture Development",
    description_key = "Marine aquaculture expansion and environmental impacts",
    icon = "water",
    category_key = "Production",
    drivers = data.frame(
      ID = c("D001", "D002", "D003"),
      Name = c("Food Demand", "Technology Advancement", "Policy Support"),
      Type = c("Driver", "Driver", "Driver"),
      Description = c("Seafood consumption", "Innovation index", "Subsidy level"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001", "A002"),
      Name = c("Fish Farming", "Shellfish Farming"),
      Type = c("Activity", "Activity"),
      Description = c("Production volume", "Farm area"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P001", "P002", "P003"),
      Name = c("Organic Enrichment", "Disease Transfer", "Escaped Farmed Fish"),
      Type = c("EnMP", "EnMP", "EnMP"),
      Description = c("Nutrient loading", "Disease prevalence", "Escape events"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MPF001", "MPF002"),
      Name = c("Benthic Degradation", "Wild Stock Impact"),
      Type = c("State Change", "State Change"),
      Description = c("Sediment quality", "Wild fish health"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES001", "ES002"),
      Name = c("Seafood Production", "Genetic Diversity"),
      Type = c("Provisioning", "Supporting"),
      Description = c("Farm output", "Stock genetic diversity"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB001", "GB002"),
      Name = c("Food Supply", "Employment"),
      Type = c("Welfare", "Welfare"),
      Description = c("Seafood availability", "Jobs created"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    adjacency_matrices = list(
      gb_es = matrix(c(
        "+strong:5", "",                  # Food Supply → Seafood Production, Diversity
        "", "+medium:4"                   # Employment → Seafood Production, Diversity
      ), nrow = 2, ncol = 2, byrow = TRUE),
      es_mpf = matrix(c(
        "-strong:5", "-medium:4",         # Seafood Production ← Benthic Degradation, Wild Stock Impact
        "", "-strong:4"                   # Diversity ← Benthic Degradation, Wild Stock Impact
      ), nrow = 2, ncol = 2, byrow = TRUE),
      mpf_p = matrix(c(
        "-strong:5", "", "",              # Benthic Degradation ← Enrichment, Disease, Escapes
        "", "-medium:3", "-weak:3"        # Wild Stock Impact ← Enrichment, Disease, Escapes
      ), nrow = 2, ncol = 3, byrow = TRUE),
      p_a = matrix(c(
        "+strong:5", "+weak:3",           # Enrichment ← Fish Farming, Shellfish Farming
        "+medium:4", "",                  # Disease ← Fish Farming, Shellfish Farming
        "+weak:4", ""                     # Escapes ← Fish Farming, Shellfish Farming
      ), nrow = 3, ncol = 2, byrow = TRUE),
      a_d = matrix(c(
        "+strong:5", "+medium:4", "+weak:3",   # Fish Farming ← Food Demand, Technology, Policy
        "+medium:4", "+weak:3", "+weak:3"      # Shellfish Farming ← Food Demand, Technology, Policy
      ), nrow = 2, ncol = 3, byrow = TRUE),
      d_gb = matrix(c(
        "+strong:5", "",                  # Food Demand → Food Supply, Employment
        "", "+medium:4",                  # Technology → Food Supply, Employment
        "+weak:4", "+strong:5"            # Policy → Food Supply, Employment
      ), nrow = 3, ncol = 2, byrow = TRUE)
    )
  ),

  pollution = list(
    name_key = "Marine Pollution",
    description_key = "Pollution impacts from land and sea-based sources",
    icon = "industry",
    category_key = "Environmental",
    drivers = data.frame(
      ID = c("D001", "D002", "D003"),
      Name = c("Industrial Activity", "Agricultural Runoff", "Urban Development"),
      Type = c("Driver", "Driver", "Driver"),
      Description = c("Industrial output", "Fertilizer use", "Urban area"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001", "A002", "A003"),
      Name = c("Industrial Discharge", "Agricultural Practices", "Waste Management"),
      Type = c("Activity", "Activity", "Activity"),
      Description = c("Discharge volume", "Farm area", "Waste treatment capacity"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P001", "P002", "P003"),
      Name = c("Chemical Pollution", "Nutrient Enrichment", "Plastic Pollution"),
      Type = c("EnMP", "EnMP", "EnMP"),
      Description = c("Contaminant levels", "Nitrogen concentration", "Plastic density"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MPF001", "MPF002", "MPF003"),
      Name = c("Eutrophication", "Toxicity Effects", "Habitat Contamination"),
      Type = c("State Change", "State Change", "State Change"),
      Description = c("Algal bloom frequency", "Organism health", "Sediment contamination"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES001", "ES002", "ES003"),
      Name = c("Water Quality", "Seafood Safety", "Marine Biodiversity"),
      Type = c("Regulating", "Provisioning", "Supporting"),
      Description = c("Water clarity", "Contaminant levels in seafood", "Species diversity"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB001", "GB002"),
      Name = c("Public Health", "Ecosystem Health"),
      Type = c("Welfare", "Welfare"),
      Description = c("Waterborne disease incidence", "Ecosystem status"),
      Stakeholder = c("", ""),
      Importance = c("", ""),
      Trend = c("", ""),
      stringsAsFactors = FALSE
    ),
    adjacency_matrices = list(
      gb_es = matrix(c(
        "+strong:5", "", "",              # Public Health → Water Quality, Seafood Safety, Biodiversity
        "", "+medium:4", "+strong:4"      # Ecosystem Health → Water Quality, Seafood Safety, Biodiversity
      ), nrow = 2, ncol = 3, byrow = TRUE),
      es_mpf = matrix(c(
        "-strong:5", "-medium:4", "-weak:3",    # Water Quality ← Eutrophication, Toxicity, Contamination
        "", "-strong:5", "-medium:4",           # Seafood Safety ← Eutrophication, Toxicity, Contamination
        "-weak:3", "-medium:4", "-strong:5"     # Biodiversity ← Eutrophication, Toxicity, Contamination
      ), nrow = 3, ncol = 3, byrow = TRUE),
      mpf_p = matrix(c(
        "", "-strong:5", "",              # Eutrophication ← Chemical, Nutrient, Plastic
        "-strong:5", "", "",              # Toxicity ← Chemical, Nutrient, Plastic
        "", "", "-medium:4"               # Contamination ← Chemical, Nutrient, Plastic
      ), nrow = 3, ncol = 3, byrow = TRUE),
      p_a = matrix(c(
        "+strong:5", "", "",              # Chemical ← Industrial, Agricultural, Waste
        "", "+strong:5", "",              # Nutrient ← Industrial, Agricultural, Waste
        "+weak:3", "", "+medium:4"        # Plastic ← Industrial, Agricultural, Waste
      ), nrow = 3, ncol = 3, byrow = TRUE),
      a_d = matrix(c(
        "+strong:5", "", "",              # Industrial ← Industrial Activity, Ag Runoff, Urban Dev
        "", "+strong:5", "",              # Agricultural ← Industrial Activity, Ag Runoff, Urban Dev
        "", "", "+strong:5"               # Waste ← Industrial Activity, Ag Runoff, Urban Dev
      ), nrow = 3, ncol = 3, byrow = TRUE),
      d_gb = matrix(c(
        "+weak:3", "+strong:4",           # Industrial Activity → Public Health, Ecosystem Health
        "+weak:3", "+medium:4",           # Ag Runoff → Public Health, Ecosystem Health
        "+medium:3", "+weak:3"            # Urban Dev → Public Health, Ecosystem Health
      ), nrow = 3, ncol = 2, byrow = TRUE)
    )
  ),

  climate_change = list(
    name_key = "Climate Change Impacts",
    description_key = "Climate change effects on marine ecosystems",
    icon = "temperature-high",
    category_key = "Climate",
    drivers = data.frame(
      ID = c("D001", "D002", "D003"),
      Name = c("Greenhouse Gas Emissions", "Land Use Change", "Energy Consumption"),
      Type = c("Driver", "Driver", "Driver"),
      Description = c("CO2 emissions", "Deforestation rate", "Energy use"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001", "A002", "A003"),
      Name = c("Fossil Fuel Use", "Industrial Production", "Transportation"),
      Type = c("Activity", "Activity", "Activity"),
      Description = c("Fuel consumption", "Production output", "Vehicle-km"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P001", "P002", "P003", "P004"),
      Name = c("Ocean Warming", "Ocean Acidification", "Sea Level Rise", "Storm Intensity"),
      Type = c("ExP", "ExP", "ExP", "ExP"),
      Description = c("Sea surface temperature", "pH level", "Sea level change", "Storm frequency"),
      Stakeholder = c("", "", "", ""),
      Importance = c("", "", "", ""),
      Trend = c("", "", "", ""),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MPF001", "MPF002", "MPF003"),
      Name = c("Species Distribution Shifts", "Coral Bleaching", "Coastal Erosion"),
      Type = c("State Change", "State Change", "State Change"),
      Description = c("Range shift distance", "Bleaching extent", "Erosion rate"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES001", "ES002", "ES003"),
      Name = c("Climate Regulation", "Coastal Protection", "Biodiversity"),
      Type = c("Regulating", "Regulating", "Supporting"),
      Description = c("Carbon sequestration", "Storm protection", "Species richness"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB001", "GB002", "GB003"),
      Name = c("Climate Stability", "Coastal Safety", "Ecosystem Resilience"),
      Type = c("Welfare", "Welfare", "Welfare"),
      Description = c("Temperature stability", "Flood risk", "Resilience index"),
      Stakeholder = c("", "", ""),
      Importance = c("", "", ""),
      Trend = c("", "", ""),
      stringsAsFactors = FALSE
    ),
    adjacency_matrices = list(
      gb_es = matrix(c(
        "+strong:5", "", "",              # Climate Stability → Climate Regulation, Protection, Biodiversity
        "", "+strong:5", "",              # Coastal Safety → Climate Regulation, Protection, Biodiversity
        "+medium:4", "+weak:3", "+strong:5"  # Ecosystem Resilience → Climate Regulation, Protection, Biodiversity
      ), nrow = 3, ncol = 3, byrow = TRUE),
      es_mpf = matrix(c(
        "-weak:3", "-medium:4", "-strong:5",  # Climate Regulation ← Species Shifts, Bleaching, Erosion
        "", "-weak:3", "-strong:5",           # Protection ← Species Shifts, Bleaching, Erosion
        "-strong:5", "-strong:5", "-weak:3"   # Biodiversity ← Species Shifts, Bleaching, Erosion
      ), nrow = 3, ncol = 3, byrow = TRUE),
      mpf_p = matrix(c(
        "-strong:5", "-weak:3", "", "",       # Species Shifts ← Warming, Acidification, Sea Level, Storms
        "", "-strong:5", "", "",              # Bleaching ← Warming, Acidification, Sea Level, Storms
        "", "", "-strong:5", "-medium:4"      # Erosion ← Warming, Acidification, Sea Level, Storms
      ), nrow = 3, ncol = 4, byrow = TRUE),
      p_a = matrix(c(
        "+strong:5", "+weak:3", "+medium:4",  # Warming ← Fossil Fuels, Industrial, Transport
        "+strong:5", "+medium:4", "+weak:3",  # Acidification ← Fossil Fuels, Industrial, Transport
        "+medium:4", "+weak:3", "+weak:3",    # Sea Level ← Fossil Fuels, Industrial, Transport
        "+weak:3", "", "+weak:3"              # Storms ← Fossil Fuels, Industrial, Transport
      ), nrow = 4, ncol = 3, byrow = TRUE),
      a_d = matrix(c(
        "+strong:5", "", "+strong:5",         # Fossil Fuels ← GHG Emissions, Land Use, Energy
        "", "+strong:4", "+medium:4",         # Industrial ← GHG Emissions, Land Use, Energy
        "", "", "+strong:5"                   # Transport ← GHG Emissions, Land Use, Energy
      ), nrow = 3, ncol = 3, byrow = TRUE),
      d_gb = matrix(c(
        "+medium:4", "", "+weak:3",           # GHG Emissions → Climate Stability, Coastal Safety, Resilience
        "", "+weak:3", "+weak:3",             # Land Use → Climate Stability, Coastal Safety, Resilience
        "+strong:5", "+medium:4", "+medium:4" # Energy → Climate Stability, Coastal Safety, Resilience
      ), nrow = 3, ncol = 3, byrow = TRUE)
    )
  )
)

# ============================================================================
# UI FUNCTION
# ============================================================================

template_ses_ui <- function(id) {
  ns <- NS(id)

  fluidPage(
    useShinyjs(),
    shiny.i18n::usei18n(i18n),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .template-container {
          max-width: 1400px;
          margin: 0 auto;
          padding: 20px;
        }
        .template-card {
          background: white;
          border: 2px solid #e0e0e0;
          border-radius: 12px;
          padding: 25px;
          margin: 15px 0;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .template-card:hover {
          border-color: #667eea;
          box-shadow: 0 6px 16px rgba(102,126,234,0.2);
          transform: translateY(-3px);
        }
        .template-card.selected {
          border-color: #27ae60;
          background: linear-gradient(135deg, #f8fff9 0%, #e8f8f0 100%);
          box-shadow: 0 6px 20px rgba(39,174,96,0.3);
        }
        .template-icon-large {
          font-size: 48px;
          color: #667eea;
          text-align: center;
          margin-bottom: 15px;
        }
        .template-card.selected .template-icon-large {
          color: #27ae60;
        }
        .template-name {
          font-size: 22px;
          font-weight: 700;
          color: #2c3e50;
          margin-bottom: 10px;
        }
        .template-description {
          color: #34495e;
          font-size: 14px;
          line-height: 1.6;
        }
        .template-category-badge {
          display: inline-block;
          background: #667eea;
          color: white;
          padding: 4px 12px;
          border-radius: 12px;
          font-size: 11px;
          font-weight: 600;
          margin-top: 10px;
        }
        .template-preview {
          background: #f8f9fa;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        .preview-section {
          margin: 15px 0;
        }
        .preview-section h6 {
          color: #667eea;
          font-weight: 700;
          margin-bottom: 10px;
        }
        .element-tag {
          display: inline-block;
          background: white;
          border: 1px solid #ddd;
          padding: 5px 12px;
          border-radius: 15px;
          margin: 3px;
          font-size: 12px;
        }
      "))
    ),

    div(class = "template-container",
      # Header
      fluidRow(
        column(12,
          div(style = "text-align: center; padding: 30px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 15px; color: white; margin-bottom: 30px;",
            h2(icon("clone"), " ", i18n$t("Template-Based SES Creation")),
            p(style = "font-size: 16px;", i18n$t("Choose a pre-built template that matches your scenario and customize it to your needs"))
          )
        )
      ),

      # Template selection
      fluidRow(
        column(8,
          h4(icon("folder-open"), " ", i18n$t("Available Templates")),
          uiOutput(ns("template_cards"))
        ),

        column(4,
          conditionalPanel(
            condition = sprintf("input['%s'] != null", ns("template_selected")),
            wellPanel(
              style = "position: sticky; top: 20px;",
              h5(icon("eye"), " ", i18n$t("Template Preview")),
              uiOutput(ns("template_preview")),
              hr(),
              actionButton(ns("use_template"),
                           i18n$t("Use This Template"),
                           icon = icon("check"),
                           class = "btn btn-success btn-block btn-lg"),
              br(),
              actionButton(ns("customize_template"),
                           i18n$t("Customize Before Using"),
                           icon = icon("edit"),
                           class = "btn btn-primary btn-block")
            )
          )
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

template_ses_server <- function(id, project_data_reactive, parent_session = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      selected_template = NULL
    )

    # Render template cards
    output$template_cards <- renderUI({
      lapply(names(ses_templates), function(template_id) {
        template <- ses_templates[[template_id]]

        div(class = "template-card", id = ns(paste0("card_", template_id)),
            onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                            ns("template_selected"), template_id),
          fluidRow(
            column(2,
              div(class = "template-icon-large",
                icon(template$icon, class = "fa-2x")
              )
            ),
            column(10,
              div(class = "template-name", i18n$t(template$name_key)),
              div(class = "template-description", i18n$t(template$description_key)),
              span(class = "template-category-badge", i18n$t(template$category_key))
            )
          )
        )
      })
    })

    # Track template selection
    observeEvent(input$template_selected, {
      rv$selected_template <- input$template_selected

      # Update card styling
      shinyjs::runjs(sprintf("
        $('.template-card').removeClass('selected');
        $('#%s').addClass('selected');
      ", ns(paste0("card_", input$template_selected))))
    })

    # Template preview
    output$template_preview <- renderUI({
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      div(class = "template-preview",
        div(class = "preview-section",
          h6(icon("arrow-down"), " ", i18n$t("Drivers"), " (", nrow(template$drivers), ")"),
          lapply(template$drivers$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("running"), " ", i18n$t("Activities"), " (", nrow(template$activities), ")"),
          lapply(template$activities$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("exclamation-triangle"), " ", i18n$t("Pressures"), " (", nrow(template$pressures), ")"),
          lapply(template$pressures$Name, function(name) {
            span(class = "element-tag", name)
          })
        ),
        div(class = "preview-section",
          h6(icon("leaf"), " ", i18n$t("Ecosystem Services"), " (", nrow(template$ecosystem_services), ")"),
          lapply(template$ecosystem_services$Name, function(name) {
            span(class = "element-tag", name)
          })
        )
      )
    })

    # Use template button
    observeEvent(input$use_template, {
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      # Load template data into project
      project_data <- project_data_reactive()

      # Populate ISA data with template
      project_data$data$isa_data$drivers <- template$drivers
      project_data$data$isa_data$activities <- template$activities
      project_data$data$isa_data$pressures <- template$pressures
      project_data$data$isa_data$marine_processes <- template$marine_processes
      project_data$data$isa_data$ecosystem_services <- template$ecosystem_services
      project_data$data$isa_data$goods_benefits <- template$goods_benefits

      # Load adjacency matrices (with example connections)
      if (is.null(template$adjacency_matrices)) {
        # Fallback: create empty matrices if template doesn't include them
        project_data$data$isa_data$adjacency_matrices <- list(
          gb_es = matrix("", nrow = nrow(template$ecosystem_services), ncol = nrow(template$goods_benefits)),
          es_mpf = matrix("", nrow = nrow(template$marine_processes), ncol = nrow(template$ecosystem_services)),
          mpf_p = matrix("", nrow = nrow(template$pressures), ncol = nrow(template$marine_processes)),
          p_a = matrix("", nrow = nrow(template$activities), ncol = nrow(template$pressures)),
          a_d = matrix("", nrow = nrow(template$drivers), ncol = nrow(template$activities)),
          d_gb = matrix("", nrow = nrow(template$goods_benefits), ncol = nrow(template$drivers))
        )
      } else {
        project_data$data$isa_data$adjacency_matrices <- template$adjacency_matrices
      }

      # Update metadata
      project_data$data$metadata$template_used <- i18n$t(template$name_key)
      project_data$last_modified <- Sys.time()

      # Save the modified data back to the reactive value
      project_data_reactive(project_data)

      # Show success message
      showNotification(
        paste(i18n$t("Template"), i18n$t(template$name_key), i18n$t("loaded successfully with example connections!")),
        type = "message",
        duration = 5
      )

      # Navigate to Dashboard
      if (!is.null(parent_session)) {
        updateTabItems(parent_session, "sidebar_menu", "dashboard")
      }
    })

    # Customize template button
    observeEvent(input$customize_template, {
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      # Load template data
      project_data <- project_data_reactive()
      project_data$data$isa_data$drivers <- template$drivers
      project_data$data$isa_data$activities <- template$activities
      project_data$data$isa_data$pressures <- template$pressures
      project_data$data$isa_data$marine_processes <- template$marine_processes
      project_data$data$isa_data$ecosystem_services <- template$ecosystem_services
      project_data$data$isa_data$goods_benefits <- template$goods_benefits

      # Create empty adjacency matrices if template doesn't include them
      if (is.null(template$adjacency_matrices)) {
        project_data$data$isa_data$adjacency_matrices <- list(
          gb_es = matrix("", nrow = nrow(template$ecosystem_services), ncol = nrow(template$goods_benefits)),
          es_mpf = matrix("", nrow = nrow(template$marine_processes), ncol = nrow(template$ecosystem_services)),
          mpf_p = matrix("", nrow = nrow(template$pressures), ncol = nrow(template$marine_processes)),
          p_a = matrix("", nrow = nrow(template$activities), ncol = nrow(template$pressures)),
          a_d = matrix("", nrow = nrow(template$drivers), ncol = nrow(template$activities)),
          d_gb = matrix("", nrow = nrow(template$goods_benefits), ncol = nrow(template$drivers))
        )
      } else {
        project_data$data$isa_data$adjacency_matrices <- template$adjacency_matrices
      }

      project_data$data$metadata$template_used <- i18n$t(template$name_key)
      project_data$last_modified <- Sys.time()

      # CRITICAL: Save the modified data back to the reactive value
      project_data_reactive(project_data)

      # Navigate to ISA entry for customization
      if (!is.null(parent_session)) {
        updateTabItems(parent_session, "sidebar_menu", "create_ses_standard")
      }
    })
  })
}
