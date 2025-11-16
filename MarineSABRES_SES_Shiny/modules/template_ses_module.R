library(shiny)
library(shinyjs)

# modules/template_ses_module.R
# Template-Based SES Creation Module
# Purpose: Allow users to start from pre-built SES templates

# Source connection review modules
source("modules/connection_review_unified.R", local = TRUE)
source("modules/connection_review_tabbed.R", local = TRUE)

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
      ), nrow = 2, ncol = 2, byrow = TRUE,
      dimnames = list(c("Food Security", "Fisher Livelihoods"), c("Fish Provision", "Marine Biodiversity"))),

      # Ecosystem Services (rows) → Marine Processes (cols)
      es_mpf = matrix(c(
        "-strong:5", "",          # Fish Provision ← Stock Decline (very high confidence), Disruption
        "", "-medium:4"           # Biodiversity ← Stock Decline, Disruption (high confidence)
      ), nrow = 2, ncol = 2, byrow = TRUE,
      dimnames = list(c("Fish Provision", "Marine Biodiversity"), c("Fish Stock Decline", "Ecosystem Disruption"))),

      # Marine Processes (rows) → Pressures (cols)
      mpf_p = matrix(c(
        "-strong:5", "-weak:3",   # Stock Decline ← Overfishing (very high), Bycatch (medium)
        "-medium:4", "-medium:3"  # Disruption ← Overfishing (high), Bycatch (medium)
      ), nrow = 2, ncol = 2, byrow = TRUE,
      dimnames = list(c("Fish Stock Decline", "Ecosystem Disruption"), c("Overfishing", "Bycatch"))),

      # Pressures (rows) → Activities (cols)
      p_a = matrix(c(
        "+strong:5", "+weak:4",   # Overfishing ← Commercial (very high), Recreational (high)
        "+medium:4", ""           # Bycatch ← Commercial (high), Recreational
      ), nrow = 2, ncol = 2, byrow = TRUE,
      dimnames = list(c("Overfishing", "Bycatch"), c("Commercial Fishing", "Recreational Fishing"))),

      # Activities (rows) → Drivers (cols)
      a_d = matrix(c(
        "+strong:4", "+strong:4", "+medium:5",  # Commercial ← Population, Economic, Market
        "", "+weak:3", "+weak:3"                # Recreational ← Population, Economic, Market
      ), nrow = 2, ncol = 3, byrow = TRUE,
      dimnames = list(c("Commercial Fishing", "Recreational Fishing"), c("Population Growth", "Economic Development", "Market Demand"))),

      # Drivers (rows) → Goods & Benefits (cols)
      d_gb = matrix(c(
        "+medium:3", "",          # Population → Food Security (medium), Livelihoods
        "+weak:3", "+medium:4",   # Economic → Food Security (medium), Livelihoods (high)
        "+weak:5", "+weak:4"      # Market → Food Security (very high), Livelihoods (high)
      ), nrow = 3, ncol = 2, byrow = TRUE,
      dimnames = list(c("Population Growth", "Economic Development", "Market Demand"), c("Food Security", "Fisher Livelihoods")))
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
      ), nrow = 2, ncol = 3, byrow = TRUE,
      dimnames = list(c("Tourism Revenue", "Quality of Life"), c("Recreation Opportunities", "Coastal Protection", "Aesthetic Value"))),
      es_mpf = matrix(c(
        "-medium:4", "-weak:3",           # Recreation ← Beach Degradation, Habitat Loss
        "", "-strong:5",                  # Protection ← Beach Degradation, Habitat Loss
        "-weak:3", "-medium:4"            # Aesthetic ← Beach Degradation, Habitat Loss
      ), nrow = 3, ncol = 2, byrow = TRUE,
      dimnames = list(c("Recreation Opportunities", "Coastal Protection", "Aesthetic Value"), c("Beach Degradation", "Marine Habitat Loss"))),
      mpf_p = matrix(c(
        "-weak:3", "-strong:5", "",       # Beach Degradation ← Pollution, Destruction, Noise
        "", "-strong:5", "-weak:3"        # Habitat Loss ← Pollution, Destruction, Noise
      ), nrow = 2, ncol = 3, byrow = TRUE,
      dimnames = list(c("Beach Degradation", "Marine Habitat Loss"), c("Coastal Pollution", "Habitat Destruction", "Noise Disturbance"))),
      p_a = matrix(c(
        "+medium:4", "+weak:3", "",       # Pollution ← Beach Tourism, Water Sports, Development
        "", "", "+strong:5",              # Destruction ← Beach Tourism, Water Sports, Development
        "+weak:3", "+medium:4", ""        # Noise ← Beach Tourism, Water Sports, Development
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Coastal Pollution", "Habitat Destruction", "Noise Disturbance"), c("Beach Tourism", "Water Sports", "Coastal Development"))),
      a_d = matrix(c(
        "+strong:5", "", "",              # Beach Tourism ← Demand, Infrastructure, Climate
        "+medium:4", "", "+weak:3",       # Water Sports ← Demand, Infrastructure, Climate
        "", "+strong:5", ""               # Development ← Demand, Infrastructure, Climate
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Beach Tourism", "Water Sports", "Coastal Development"), c("Tourism Demand", "Infrastructure Development", "Climate Amenity"))),
      d_gb = matrix(c(
        "+medium:4", "",                  # Demand → Revenue, Quality
        "+strong:5", "+weak:3",           # Infrastructure → Revenue, Quality
        "+weak:3", "+medium:4"            # Climate → Revenue, Quality
      ), nrow = 3, ncol = 2, byrow = TRUE,
      dimnames = list(c("Tourism Demand", "Infrastructure Development", "Climate Amenity"), c("Tourism Revenue", "Quality of Life")))
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
      ), nrow = 2, ncol = 2, byrow = TRUE,
      dimnames = list(c("Food Supply", "Employment"), c("Seafood Production", "Genetic Diversity"))),
      es_mpf = matrix(c(
        "-strong:5", "-medium:4",         # Seafood Production ← Benthic Degradation, Wild Stock Impact
        "", "-strong:4"                   # Diversity ← Benthic Degradation, Wild Stock Impact
      ), nrow = 2, ncol = 2, byrow = TRUE,
      dimnames = list(c("Seafood Production", "Genetic Diversity"), c("Benthic Degradation", "Wild Stock Impact"))),
      mpf_p = matrix(c(
        "-strong:5", "", "",              # Benthic Degradation ← Enrichment, Disease, Escapes
        "", "-medium:3", "-weak:3"        # Wild Stock Impact ← Enrichment, Disease, Escapes
      ), nrow = 2, ncol = 3, byrow = TRUE,
      dimnames = list(c("Benthic Degradation", "Wild Stock Impact"), c("Organic Enrichment", "Disease Transfer", "Escaped Farmed Fish"))),
      p_a = matrix(c(
        "+strong:5", "+weak:3",           # Enrichment ← Fish Farming, Shellfish Farming
        "+medium:4", "",                  # Disease ← Fish Farming, Shellfish Farming
        "+weak:4", ""                     # Escapes ← Fish Farming, Shellfish Farming
      ), nrow = 3, ncol = 2, byrow = TRUE,
      dimnames = list(c("Organic Enrichment", "Disease Transfer", "Escaped Farmed Fish"), c("Fish Farming", "Shellfish Farming"))),
      a_d = matrix(c(
        "+strong:5", "+medium:4", "+weak:3",   # Fish Farming ← Food Demand, Technology, Policy
        "+medium:4", "+weak:3", "+weak:3"      # Shellfish Farming ← Food Demand, Technology, Policy
      ), nrow = 2, ncol = 3, byrow = TRUE,
      dimnames = list(c("Fish Farming", "Shellfish Farming"), c("Food Demand", "Technology Advancement", "Policy Support"))),
      d_gb = matrix(c(
        "+strong:5", "",                  # Food Demand → Food Supply, Employment
        "", "+medium:4",                  # Technology → Food Supply, Employment
        "+weak:4", "+strong:5"            # Policy → Food Supply, Employment
      ), nrow = 3, ncol = 2, byrow = TRUE,
      dimnames = list(c("Food Demand", "Technology Advancement", "Policy Support"), c("Food Supply", "Employment")))
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
      ), nrow = 2, ncol = 3, byrow = TRUE,
      dimnames = list(c("Public Health", "Ecosystem Health"), c("Water Quality", "Seafood Safety", "Marine Biodiversity"))),
      es_mpf = matrix(c(
        "-strong:5", "-medium:4", "-weak:3",    # Water Quality ← Eutrophication, Toxicity, Contamination
        "", "-strong:5", "-medium:4",           # Seafood Safety ← Eutrophication, Toxicity, Contamination
        "-weak:3", "-medium:4", "-strong:5"     # Biodiversity ← Eutrophication, Toxicity, Contamination
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Water Quality", "Seafood Safety", "Marine Biodiversity"), c("Eutrophication", "Toxicity Effects", "Habitat Contamination"))),
      mpf_p = matrix(c(
        "", "-strong:5", "",              # Eutrophication ← Chemical, Nutrient, Plastic
        "-strong:5", "", "",              # Toxicity ← Chemical, Nutrient, Plastic
        "", "", "-medium:4"               # Contamination ← Chemical, Nutrient, Plastic
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Eutrophication", "Toxicity Effects", "Habitat Contamination"), c("Chemical Pollution", "Nutrient Enrichment", "Plastic Pollution"))),
      p_a = matrix(c(
        "+strong:5", "", "",              # Chemical ← Industrial, Agricultural, Waste
        "", "+strong:5", "",              # Nutrient ← Industrial, Agricultural, Waste
        "+weak:3", "", "+medium:4"        # Plastic ← Industrial, Agricultural, Waste
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Chemical Pollution", "Nutrient Enrichment", "Plastic Pollution"), c("Industrial Discharge", "Agricultural Practices", "Waste Management"))),
      a_d = matrix(c(
        "+strong:5", "", "",              # Industrial ← Industrial Activity, Ag Runoff, Urban Dev
        "", "+strong:5", "",              # Agricultural ← Industrial Activity, Ag Runoff, Urban Dev
        "", "", "+strong:5"               # Waste ← Industrial Activity, Ag Runoff, Urban Dev
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Industrial Discharge", "Agricultural Practices", "Waste Management"), c("Industrial Activity", "Agricultural Runoff", "Urban Development"))),
      d_gb = matrix(c(
        "+weak:3", "+strong:4",           # Industrial Activity → Public Health, Ecosystem Health
        "+weak:3", "+medium:4",           # Ag Runoff → Public Health, Ecosystem Health
        "+medium:3", "+weak:3"            # Urban Dev → Public Health, Ecosystem Health
      ), nrow = 3, ncol = 2, byrow = TRUE,
      dimnames = list(c("Industrial Activity", "Agricultural Runoff", "Urban Development"), c("Public Health", "Ecosystem Health")))
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
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Climate Stability", "Coastal Safety", "Ecosystem Resilience"), c("Climate Regulation", "Coastal Protection", "Biodiversity"))),
      es_mpf = matrix(c(
        "-weak:3", "-medium:4", "-strong:5",  # Climate Regulation ← Species Shifts, Bleaching, Erosion
        "", "-weak:3", "-strong:5",           # Protection ← Species Shifts, Bleaching, Erosion
        "-strong:5", "-strong:5", "-weak:3"   # Biodiversity ← Species Shifts, Bleaching, Erosion
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Climate Regulation", "Coastal Protection", "Biodiversity"), c("Species Distribution Shifts", "Coral Bleaching", "Coastal Erosion"))),
      mpf_p = matrix(c(
        "-strong:5", "-weak:3", "", "",       # Species Shifts ← Warming, Acidification, Sea Level, Storms
        "", "-strong:5", "", "",              # Bleaching ← Warming, Acidification, Sea Level, Storms
        "", "", "-strong:5", "-medium:4"      # Erosion ← Warming, Acidification, Sea Level, Storms
      ), nrow = 3, ncol = 4, byrow = TRUE,
      dimnames = list(c("Species Distribution Shifts", "Coral Bleaching", "Coastal Erosion"), c("Ocean Warming", "Ocean Acidification", "Sea Level Rise", "Storm Intensity"))),
      p_a = matrix(c(
        "+strong:5", "+weak:3", "+medium:4",  # Warming ← Fossil Fuels, Industrial, Transport
        "+strong:5", "+medium:4", "+weak:3",  # Acidification ← Fossil Fuels, Industrial, Transport
        "+medium:4", "+weak:3", "+weak:3",    # Sea Level ← Fossil Fuels, Industrial, Transport
        "+weak:3", "", "+weak:3"              # Storms ← Fossil Fuels, Industrial, Transport
      ), nrow = 4, ncol = 3, byrow = TRUE,
      dimnames = list(c("Ocean Warming", "Ocean Acidification", "Sea Level Rise", "Storm Intensity"), c("Fossil Fuel Use", "Industrial Production", "Transportation"))),
      a_d = matrix(c(
        "+strong:5", "", "+strong:5",         # Fossil Fuels ← GHG Emissions, Land Use, Energy
        "", "+strong:4", "+medium:4",         # Industrial ← GHG Emissions, Land Use, Energy
        "", "", "+strong:5"                   # Transport ← GHG Emissions, Land Use, Energy
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("Fossil Fuel Use", "Industrial Production", "Transportation"), c("GHG Emissions", "Land Use Change", "Energy Demand"))),
      d_gb = matrix(c(
        "+medium:4", "", "+weak:3",           # GHG Emissions → Climate Stability, Coastal Safety, Resilience
        "", "+weak:3", "+weak:3",             # Land Use → Climate Stability, Coastal Safety, Resilience
        "+strong:5", "+medium:4", "+medium:4" # Energy → Climate Stability, Coastal Safety, Resilience
      ), nrow = 3, ncol = 3, byrow = TRUE,
      dimnames = list(c("GHG Emissions", "Land Use Change", "Energy Demand"), c("Climate Stability", "Coastal Safety", "Ecosystem Resilience")))
    )
  ),

  caribbean = list(
    name_key = "Caribbean Island",
    description_key = "Multi-stress Caribbean island system: Sargassum blooms, coral bleaching, contamination, overfishing",
    icon = "globe-americas",
    category_key = "Multi-Stressor",
    drivers = data.frame(
      ID = c("D001", "D002", "D003", "D004", "D005"),
      Name = c("Tourism Demand", "Food Security", "Economic Development", "Agricultural Production", "Climate Adaptation"),
      Type = c("Driver", "Driver", "Driver", "Driver", "Driver"),
      Description = c("Global beach vacation demand", "Seafood consumption needs", "Employment & income needs", "Banana & crop production", "Adaptation to climate change"),
      Stakeholder = c("", "", "", "", ""),
      Importance = c("", "", "", "", ""),
      Trend = c("", "", "", "", ""),
      stringsAsFactors = FALSE
    ),
    activities = data.frame(
      ID = c("A001", "A002", "A003", "A004", "A005", "A006"),
      Name = c("Beach Tourism", "Artisanal Fishing", "Coastal Development", "Agricultural Runoff", "Wastewater Discharge", "Diving & Snorkeling"),
      Type = c("Activity", "Activity", "Activity", "Activity", "Activity", "Activity"),
      Description = c("Tourist arrivals & beach use", "Small-scale fishing effort", "Urbanization & construction", "Pesticide & nutrient runoff", "Sewage discharge", "Underwater tourism"),
      Stakeholder = c("", "", "", "", "", ""),
      Importance = c("", "", "", "", "", ""),
      Trend = c("", "", "", "", "", ""),
      stringsAsFactors = FALSE
    ),
    pressures = data.frame(
      ID = c("P001", "P002", "P003", "P004", "P005", "P006"),
      Name = c("Nutrient Enrichment", "Chlordecone Contamination", "Elevated Sea Temperature", "Overfishing Pressure", "Habitat Destruction", "Sedimentation"),
      Type = c("EnMP", "EnMP", "EnMP", "EnMP", "EnMP", "EnMP"),
      Description = c("Eutrophication from runoff", "Persistent pesticide pollution", "Ocean warming from climate change", "Excessive fish removal", "Physical damage to habitats", "Suspended sediments"),
      Stakeholder = c("", "", "", "", "", ""),
      Importance = c("", "", "", "", "", ""),
      Trend = c("", "", "", "", "", ""),
      stringsAsFactors = FALSE
    ),
    marine_processes = data.frame(
      ID = c("MPF001", "MPF002", "MPF003", "MPF004", "MPF005"),
      Name = c("Sargassum Blooms", "Coral Bleaching", "Contaminated Sediments", "Fish Stock Depletion", "Mangrove Loss"),
      Type = c("State Change", "State Change", "State Change", "State Change", "State Change"),
      Description = c("Massive seaweed accumulation", "Widespread coral mortality", "Toxic sediment contamination", "Declining fish populations", "Mangrove area reduction"),
      Stakeholder = c("", "", "", "", ""),
      Importance = c("", "", "", "", ""),
      Trend = c("", "", "", "", ""),
      stringsAsFactors = FALSE
    ),
    ecosystem_services = data.frame(
      ID = c("ES001", "ES002", "ES003", "ES004", "ES005"),
      Name = c("Fish Provision", "Beach Recreation", "Coastal Protection", "Diving Quality", "Water Purification"),
      Type = c("Provisioning", "Cultural", "Regulating", "Cultural", "Regulating"),
      Description = c("Fish & seafood supply", "Beach amenity value", "Storm buffering capacity", "Underwater tourism quality", "Natural water filtering"),
      Stakeholder = c("", "", "", "", ""),
      Importance = c("", "", "", "", ""),
      Trend = c("", "", "", "", ""),
      stringsAsFactors = FALSE
    ),
    goods_benefits = data.frame(
      ID = c("GB001", "GB002", "GB003", "GB004"),
      Name = c("Tourism Revenue", "Fisher Livelihoods", "Public Health", "Coastal Safety"),
      Type = c("Welfare", "Welfare", "Welfare", "Welfare"),
      Description = c("Tourism income & employment", "Fishing income & food security", "Seafood safety & respiratory health", "Flood protection & property safety"),
      Stakeholder = c("", "", "", ""),
      Importance = c("", "", "", ""),
      Trend = c("", "", "", ""),
      stringsAsFactors = FALSE
    ),
    adjacency_matrices = list(
      # Goods & Benefits → Ecosystem Services
      gb_es = matrix(c(
        "", "+strong:5", "", "+medium:4", "",     # Tourism Revenue ← Beach Recreation, Diving Quality
        "+strong:5", "", "", "", "",               # Fisher Livelihoods ← Fish Provision
        "+medium:4", "", "", "", "+weak:3",        # Public Health ← Fish Provision (contamination), Water Purification
        "", "", "+strong:5", "", ""                # Coastal Safety ← Coastal Protection
      ), nrow = 4, ncol = 5, byrow = TRUE,
      dimnames = list(c("Tourism Revenue", "Fisher Livelihoods", "Public Health", "Coastal Safety"),
                      c("Fish Provision", "Beach Recreation", "Coastal Protection", "Diving Quality", "Water Purification"))),

      # Ecosystem Services → Marine Processes
      es_mpf = matrix(c(
        "-strong:5", "", "-medium:4", "-strong:5", "",     # Fish Provision ← Coral Bleaching (habitat), Contamination, Fish Depletion
        "-strong:5", "", "", "", "",                       # Beach Recreation ← Sargassum Blooms
        "", "-medium:4", "", "", "-strong:5",              # Coastal Protection ← Coral Bleaching, Mangrove Loss
        "", "-strong:5", "", "-medium:3", "",              # Diving Quality ← Coral Bleaching, Fish Depletion
        "", "", "", "", "-medium:4"                        # Water Purification ← Mangrove Loss
      ), nrow = 5, ncol = 5, byrow = TRUE,
      dimnames = list(c("Fish Provision", "Beach Recreation", "Coastal Protection", "Diving Quality", "Water Purification"),
                      c("Sargassum Blooms", "Coral Bleaching", "Contaminated Sediments", "Fish Stock Depletion", "Mangrove Loss"))),

      # Marine Processes → Pressures
      mpf_p = matrix(c(
        "-strong:5", "", "", "", "", "",                   # Sargassum Blooms ← Nutrient Enrichment
        "", "", "-strong:5", "", "", "",                   # Coral Bleaching ← Elevated Temperature
        "", "-strong:5", "", "", "", "",                   # Contaminated Sediments ← Chlordecone
        "", "", "", "-strong:5", "", "",                   # Fish Stock Depletion ← Overfishing
        "", "", "", "", "-strong:5", "-medium:4"           # Mangrove Loss ← Habitat Destruction, Sedimentation
      ), nrow = 5, ncol = 6, byrow = TRUE,
      dimnames = list(c("Sargassum Blooms", "Coral Bleaching", "Contaminated Sediments", "Fish Stock Depletion", "Mangrove Loss"),
                      c("Nutrient Enrichment", "Chlordecone Contamination", "Elevated Sea Temperature", "Overfishing Pressure", "Habitat Destruction", "Sedimentation"))),

      # Pressures → Activities
      p_a = matrix(c(
        "", "", "", "+strong:5", "+strong:5", "",          # Nutrient Enrichment ← Agricultural Runoff, Wastewater
        "", "", "", "+strong:5", "", "",                   # Chlordecone ← Agricultural Runoff (historical)
        "", "", "", "", "", "",                            # Elevated Temperature (global, not local activity)
        "", "+strong:5", "", "", "", "",                   # Overfishing ← Artisanal Fishing
        "", "", "+strong:5", "", "", "+weak:3",            # Habitat Destruction ← Coastal Development, Diving
        "", "", "+medium:4", "+medium:4", "", ""           # Sedimentation ← Coastal Development, Agricultural Runoff
      ), nrow = 6, ncol = 6, byrow = TRUE,
      dimnames = list(c("Nutrient Enrichment", "Chlordecone Contamination", "Elevated Sea Temperature", "Overfishing Pressure", "Habitat Destruction", "Sedimentation"),
                      c("Beach Tourism", "Artisanal Fishing", "Coastal Development", "Agricultural Runoff", "Wastewater Discharge", "Diving & Snorkeling"))),

      # Activities → Drivers
      a_d = matrix(c(
        "+strong:5", "", "", "", "",                       # Beach Tourism ← Tourism Demand
        "", "+strong:5", "+medium:4", "", "",              # Artisanal Fishing ← Food Security, Economic Development
        "", "", "+strong:5", "", "",                       # Coastal Development ← Economic Development
        "", "", "", "+strong:5", "",                       # Agricultural Runoff ← Agricultural Production
        "", "+weak:3", "+weak:3", "", "",                  # Wastewater ← Food Security, Economic Development (population)
        "+medium:4", "", "", "", ""                        # Diving ← Tourism Demand
      ), nrow = 6, ncol = 5, byrow = TRUE,
      dimnames = list(c("Beach Tourism", "Artisanal Fishing", "Coastal Development", "Agricultural Runoff", "Wastewater Discharge", "Diving & Snorkeling"),
                      c("Tourism Demand", "Food Security", "Economic Development", "Agricultural Production", "Climate Adaptation"))),

      # Drivers → Goods & Benefits (feedback loops)
      d_gb = matrix(c(
        "+strong:5", "", "-weak:3", "",                    # Tourism Demand → Tourism Revenue (but can harm health, safety)
        "", "+medium:4", "+weak:3", "",                    # Food Security → Fisher Livelihoods, Public Health
        "+medium:4", "+weak:3", "", "",                    # Economic Development → Tourism, Fishing
        "", "", "-medium:4", "",                           # Agricultural Production → Public Health (contamination)
        "", "", "", "+weak:3"                              # Climate Adaptation → Coastal Safety
      ), nrow = 5, ncol = 4, byrow = TRUE,
      dimnames = list(c("Tourism Demand", "Food Security", "Economic Development", "Agricultural Production", "Climate Adaptation"),
                      c("Tourism Revenue", "Fisher Livelihoods", "Public Health", "Coastal Safety")))
    )
  )
)

# ============================================================================
# UI FUNCTION
# ============================================================================

template_ses_ui <- function(id, i18n) {
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
          padding: 15px;
          margin: 10px 0;
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
          font-size: 32px;
          color: #667eea;
          text-align: center;
          margin-bottom: 10px;
        }
        .template-card.selected .template-icon-large {
          color: #27ae60;
        }
        .template-name {
          font-size: 18px;
          font-weight: 700;
          color: #2c3e50;
          margin-bottom: 8px;
        }
        .template-description {
          color: #34495e;
          font-size: 13px;
          line-height: 1.5;
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
      uiOutput(ns("template_header")),

      # Three-column layout: Template cards + Preview/Actions + Connection review
      fluidRow(
        # Column 1: Template cards (3 columns)
        column(3,
          uiOutput(ns("templates_heading")),
          uiOutput(ns("template_cards"))
        ),

        # Column 2: Template preview and action buttons (2 columns)
        column(2,
          uiOutput(ns("template_actions"))
        ),

        # Column 3: Connection review (7 columns)
        column(7,
          uiOutput(ns("connection_review_section"))
        )
      )
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

template_ses_server <- function(id, project_data_reactive, parent_session = NULL, event_bus = NULL, i18n) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      selected_template = NULL,
      show_connection_review = FALSE,
      template_connections = NULL,
      review_mode = NULL,  # "use" or "customize"
      pending_template_switch = NULL  # Stores template ID when awaiting confirmation to switch
    )

    # Render header
    output$template_header <- renderUI({
      create_module_header(
        ns = ns,
        title_key = "Template-Based SES Creation",
        subtitle_key = "Choose a pre-built template that matches your scenario and customize it to your needs",
        help_id = "help_template_ses",
        i18n = i18n
      )
    })

    # Render templates heading
    output$templates_heading <- renderUI({
      h4(icon("folder-open"), " ", i18n$t("Available Templates"))
    })

    # Render template actions
    output$template_actions <- renderUI({
      if (!is.null(rv$selected_template)) {
        div(
          wellPanel(
            style = "padding: 15px; margin-top: 0;",
            h6(icon("eye"), " ", i18n$t("Preview"), style = "margin-bottom: 10px; font-weight: bold;"),
            uiOutput(ns("template_preview_compact"))
          ),
          wellPanel(
            style = "padding: 15px;",
            h6(icon("cog"), " ", i18n$t("Actions"), style = "margin-bottom: 10px; font-weight: bold;"),
            tags$div(
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              title = i18n$t("Preview all template connections before loading. Review connections to understand the causal links in the SES model."),
              actionButton(ns("review_connections"),
                           i18n$t("Review"),
                           icon = icon("search"),
                           class = "btn btn-info btn-block",
                           style = "margin-bottom: 8px; font-size: 13px; padding: 8px;")
            ),
            tags$div(
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              title = i18n$t("Load the template as-is without reviewing connections. All predefined connections will be imported directly into your project."),
              actionButton(ns("load_template"),
                           i18n$t("Load"),
                           icon = icon("download"),
                           class = "btn btn-success btn-block",
                           style = "margin-bottom: 8px; font-size: 13px; padding: 8px;")
            ),
            tags$div(
              `data-toggle` = "tooltip",
              `data-placement` = "right",
              title = i18n$t("Review and customize template connections. Approve, reject, or modify individual connections before loading into your project."),
              actionButton(ns("customize_template"),
                           i18n$t("Customize"),
                           icon = icon("edit"),
                           class = "btn btn-primary btn-block",
                           style = "font-size: 13px; padding: 8px;")
            )
          )
        )
      }
    })

    # Render template cards
    output$template_cards <- renderUI({
      lapply(names(ses_templates), function(template_id) {
        template <- ses_templates[[template_id]]

        div(class = "template-card", id = ns(paste0("card_", template_id)),
            onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'})",
                            ns("template_selected"), template_id),
          fluidRow(
            column(3,
              div(class = "template-icon-large",
                icon(template$icon)
              )
            ),
            column(9,
              div(style = "display: flex; justify-content: space-between; align-items: center;",
                div(class = "template-name", i18n$t(template$name_key)),
                actionButton(ns(paste0("preview_", template_id)),
                            NULL,
                            icon = icon("eye"),
                            class = "btn btn-link btn-sm",
                            style = "padding: 2px 8px; color: #666;",
                            title = i18n$t("View detailed preview"),
                            onclick = "event.stopPropagation();")
              ),
              div(class = "template-description", i18n$t(template$description_key)),
              span(class = "template-category-badge", i18n$t(template$category_key))
            )
          )
        )
      })
    })

    # Track template selection with warning if switching templates
    observeEvent(input$template_selected, {
      new_template <- input$template_selected

      # Check if user is switching from an existing template with work in progress
      if (!is.null(rv$selected_template) &&
          rv$selected_template != new_template &&
          !is.null(rv$template_connections) &&
          length(rv$template_connections) > 0) {

        # Show confirmation modal
        showModal(modalDialog(
          title = tags$h4(icon("exclamation-triangle"), " ", i18n$t("Switch Template?")),
          size = "m",
          easyClose = FALSE,

          tags$div(
            style = "padding: 15px;",
            tags$p(
              tags$strong(i18n$t("Warning:")), " ",
              i18n$t("You are about to switch to a different template.")
            ),
            tags$p(
              i18n$t("All work on the current template will be lost, including:"),
              tags$ul(
                tags$li(i18n$t("Connection reviews and amendments")),
                tags$li(i18n$t("Approved and rejected connections")),
                tags$li(i18n$t("Any customizations made"))
              )
            ),
            tags$p(
              style = "color: #d9534f; font-weight: bold;",
              i18n$t("This action cannot be undone.")
            ),
            tags$p(
              i18n$t("Are you sure you want to start from scratch with the new template?")
            )
          ),

          footer = tagList(
            actionButton(ns("cancel_template_switch"),
                        i18n$t("Cancel"),
                        class = "btn-default"),
            actionButton(ns("confirm_template_switch"),
                        i18n$t("Yes, Switch Template"),
                        class = "btn-danger",
                        icon = icon("exchange-alt"))
          )
        ))

        # Store the pending template selection
        rv$pending_template_switch <- new_template

      } else {
        # No work in progress, switch immediately
        rv$selected_template <- new_template

        # Update card styling
        shinyjs::runjs(sprintf("
          $('.template-card').removeClass('selected');
          $('#%s').addClass('selected');
        ", ns(paste0("card_", new_template))))
      }
    })

    # Handle template switch confirmation
    observeEvent(input$confirm_template_switch, {
      # Clear all work in progress
      rv$template_connections <- NULL
      rv$show_connection_review <- FALSE
      rv$review_mode <- NULL

      # Switch to new template
      rv$selected_template <- rv$pending_template_switch
      rv$pending_template_switch <- NULL

      # Update card styling
      shinyjs::runjs(sprintf("
        $('.template-card').removeClass('selected');
        $('#%s').addClass('selected');
      ", ns(paste0("card_", rv$selected_template))))

      removeModal()

      showNotification(
        i18n$t("Template switched. Starting fresh."),
        type = "warning",
        duration = 3
      )
    })

    # Handle template switch cancellation
    observeEvent(input$cancel_template_switch, {
      rv$pending_template_switch <- NULL
      removeModal()
    })

    # Preview button observers for each template
    lapply(names(ses_templates), function(template_id) {
      observeEvent(input[[paste0("preview_", template_id)]], {
        template <- ses_templates[[template_id]]

        # Show detailed preview modal
        showModal(modalDialog(
          title = tags$h3(icon(template$icon), " ", i18n$t(template$name_key)),
          size = "l",
          easyClose = TRUE,

          tags$div(
            style = "padding: 20px;",

            # Description
            tags$div(
              style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
              tags$p(
                style = "font-size: 15px; margin: 0;",
                tags$strong(i18n$t("Description:")), " ",
                i18n$t(template$description_key)
              ),
              tags$p(
                style = "font-size: 13px; margin: 10px 0 0 0; color: #666;",
                tags$span(class = "badge", style = "background: #667eea; color: white;",
                          i18n$t(template$category_key))
              )
            ),

            # Template contents in columns
            fluidRow(
              column(6,
                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("arrow-down"), " ", i18n$t("Drivers"), " (", nrow(template$drivers), ")",
                          style = "color: #667eea; margin-top: 0;"),
                  if (nrow(template$drivers) > 0) {
                    lapply(1:min(5, nrow(template$drivers)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$drivers$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$drivers$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$drivers) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$drivers) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("exclamation-triangle"), " ", i18n$t("Pressures"), " (", nrow(template$pressures), ")",
                          style = "color: #dc3545; margin-top: 0;"),
                  if (nrow(template$pressures) > 0) {
                    lapply(1:min(5, nrow(template$pressures)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$pressures$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$pressures$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$pressures) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$pressures) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("leaf"), " ", i18n$t("Ecosystem Services"), " (", nrow(template$ecosystem_services), ")",
                          style = "color: #28a745; margin-top: 0;"),
                  if (nrow(template$ecosystem_services) > 0) {
                    lapply(1:min(5, nrow(template$ecosystem_services)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$ecosystem_services$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$ecosystem_services$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$ecosystem_services) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$ecosystem_services) - 5))
                  }
                )
              ),

              column(6,
                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 15px;",
                  tags$h5(icon("running"), " ", i18n$t("Activities"), " (", nrow(template$activities), ")",
                          style = "color: #ffc107; margin-top: 0;"),
                  if (nrow(template$activities) > 0) {
                    lapply(1:min(5, nrow(template$activities)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$activities$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$activities$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$activities) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$activities) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("fish"), " ", i18n$t("Marine Processes and Functions"), " (", nrow(template$marine_processes), ")",
                          style = "color: #17a2b8; margin-top: 0;"),
                  if (nrow(template$marine_processes) > 0) {
                    lapply(1:min(5, nrow(template$marine_processes)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$marine_processes$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$marine_processes$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$marine_processes) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$marine_processes) - 5))
                  }
                ),

                tags$div(
                  style = "background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px;",
                  tags$h5(icon("heart"), " ", i18n$t("Welfare"), " (", nrow(template$goods_benefits), ")",
                          style = "color: #e83e8c; margin-top: 0;"),
                  if (nrow(template$goods_benefits) > 0) {
                    lapply(1:min(5, nrow(template$goods_benefits)), function(i) {
                      tags$div(
                        style = "padding: 5px 0; border-bottom: 1px solid #f0f0f0;",
                        tags$strong(template$goods_benefits$Name[i]),
                        tags$br(),
                        tags$small(style = "color: #666;", template$goods_benefits$Description[i])
                      )
                    })
                  } else {
                    tags$p(style = "color: #999; font-style: italic;", i18n$t("None defined"))
                  },
                  if (nrow(template$goods_benefits) > 5) {
                    tags$small(style = "color: #666; font-style: italic;",
                              sprintf(i18n$t("... and %d more"), nrow(template$goods_benefits) - 5))
                  }
                )
              )
            ),

            # Connection statistics
            tags$div(
              style = "background: #e3f2fd; padding: 15px; border-radius: 8px; margin-top: 20px;",
              tags$h5(icon("link"), " ", i18n$t("Connections"), style = "margin-top: 0; color: #1976d2;"),
              tags$p(
                style = "margin: 0;",
                sprintf(i18n$t("This template includes %d predefined connections between elements."),
                        length(parse_template_connections(template)))
              )
            )
          ),

          footer = tagList(
            actionButton(ns(paste0("select_from_preview_", template_id)),
                        i18n$t("Select This Template"),
                        class = "btn-primary",
                        icon = icon("check")),
            tags$button(
              type = "button",
              class = "btn btn-default",
              `data-dismiss` = "modal",
              i18n$t("Close")
            )
          )
        ))
      })

      # Handle selection from preview modal
      observeEvent(input[[paste0("select_from_preview_", template_id)]], {
        rv$selected_template <- template_id
        removeModal()

        # Update card styling
        shinyjs::runjs(sprintf("
          $('.template-card').removeClass('selected');
          $('#%s').addClass('selected');
        ", ns(paste0("card_", template_id))))

        showNotification(
          sprintf(i18n$t("Template '%s' selected"), i18n$t(ses_templates[[template_id]]$name_key)),
          type = "message",
          duration = 2
        )
      })
    })

    # Template preview (full version - not used in current layout)
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

    # Compact template preview (used in side column)
    output$template_preview_compact <- renderUI({
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      div(style = "font-size: 11px;",
        div(style = "margin-bottom: 5px;",
          strong(icon("arrow-down"), " ", i18n$t("Drivers"), ": "), nrow(template$drivers)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("running"), " ", i18n$t("Activities"), ": "), nrow(template$activities)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("exclamation-triangle"), " ", i18n$t("Pressures"), ": "), nrow(template$pressures)
        ),
        div(style = "margin-bottom: 5px;",
          strong(icon("leaf"), " ", i18n$t("ES"), ": "), nrow(template$ecosystem_services)
        ),
        div(style = "margin-bottom: 0;",
          strong(icon("gift"), " ", i18n$t("G&B"), ": "), nrow(template$goods_benefits)
        )
      )
    })

    # Help Modal ----
    create_help_observer(
      input, "help_template_ses", "template_ses_guide_title",
      tagList(
        h4(i18n$t("template_ses_guide_what_is_title")),
        p(i18n$t("template_ses_guide_what_is_p1")),
        h4(i18n$t("template_ses_guide_how_to_use_title")),
        tags$ol(
          tags$li(i18n$t("template_ses_guide_step1")),
          tags$li(i18n$t("template_ses_guide_step2")),
          tags$li(i18n$t("template_ses_guide_step3"))
        )
      ),
      i18n
    )

    # Helper function to parse template adjacency matrices into connections
    parse_template_connections <- function(template) {
      connections <- list()

      if (is.null(template$adjacency_matrices)) return(connections)

      # Map matrix names to connection types
      # Matrix naming convention: [from]_[to] (e.g., a_d means Activity → Driver)
      matrix_type_map <- list(
        # Activities ↔ Drivers
        a_d = list(from = "activity", to = "driver"),
        d_a = list(from = "driver", to = "activity"),

        # Pressures ↔ Activities
        p_a = list(from = "pressure", to = "activity"),
        a_p = list(from = "activity", to = "pressure"),

        # Marine Processes ↔ Pressures
        mpf_p = list(from = "marine_process", to = "pressure"),
        p_mpf = list(from = "pressure", to = "marine_process"),

        # Ecosystem Services ↔ Marine Processes
        es_mpf = list(from = "ecosystem_service", to = "marine_process"),
        mpf_es = list(from = "marine_process", to = "ecosystem_service"),

        # Goods & Benefits ↔ Ecosystem Services
        gb_es = list(from = "goods_benefit", to = "ecosystem_service"),
        es_gb = list(from = "ecosystem_service", to = "goods_benefit"),

        # Drivers ↔ Goods & Benefits (feedback loops)
        d_gb = list(from = "driver", to = "goods_benefit"),
        gb_d = list(from = "goods_benefit", to = "driver"),

        # Responses
        r_d = list(from = "response", to = "driver"),
        r_a = list(from = "response", to = "activity"),
        r_p = list(from = "response", to = "pressure")
      )

      # Process each adjacency matrix
      for (matrix_name in names(template$adjacency_matrices)) {
        mat <- template$adjacency_matrices[[matrix_name]]

        # Get connection types for this matrix
        type_info <- matrix_type_map[[matrix_name]]
        if (is.null(type_info)) {
          # Unknown matrix type, skip or use generic
          next
        }

        # Get row and column names
        from_names <- rownames(mat)
        to_names <- colnames(mat)

        # Parse each non-empty cell
        for (i in seq_len(nrow(mat))) {
          for (j in seq_len(ncol(mat))) {
            cell_value <- mat[i, j]

            # Skip empty cells
            if (is.na(cell_value) || cell_value == "") next

            # Parse format: "+strength:confidence" or "-strength:confidence"
            polarity <- substr(cell_value, 1, 1)
            rest <- substr(cell_value, 2, nchar(cell_value))
            parts <- strsplit(rest, ":")[[1]]

            strength <- if (length(parts) >= 1) parts[1] else "medium"
            confidence <- if (length(parts) >= 2) as.integer(parts[2]) else 3

            # Create rationale based on polarity
            rationale <- if (polarity == "+") "drives/increases" else "affects/reduces"

            # Add connection with type information
            connections[[length(connections) + 1]] <- list(
              from_type = type_info$from,
              to_type = type_info$to,
              from_name = from_names[i],
              to_name = to_names[j],
              polarity = polarity,
              strength = strength,
              confidence = confidence,
              rationale = paste(from_names[i], rationale, to_names[j])
            )
          }
        }
      }

      return(connections)
    }

    # Review connections button - shows connection review pane
    observeEvent(input$review_connections, {
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      # Parse connections for review
      rv$template_connections <- parse_template_connections(template)
      rv$review_mode <- "review"
      rv$show_connection_review <- TRUE

      debug_log(sprintf("Parsed %d connections for review", length(rv$template_connections)), "TEMPLATE")
    })

    # Load template button - loads template as-is without review
    observeEvent(input$load_template, {
      req(rv$selected_template)

      debug_log("Load button clicked", "TEMPLATE")

      template <- ses_templates[[rv$selected_template]]

      # Load template data directly into project without review
      project_data <- isolate(project_data_reactive())

      debug_log("Got project data", "TEMPLATE")

      # Populate ISA data with template
      project_data$data$isa_data$drivers <- template$drivers
      project_data$data$isa_data$activities <- template$activities
      project_data$data$isa_data$pressures <- template$pressures
      project_data$data$isa_data$marine_processes <- template$marine_processes
      project_data$data$isa_data$ecosystem_services <- template$ecosystem_services
      project_data$data$isa_data$goods_benefits <- template$goods_benefits
      project_data$data$isa_data$adjacency_matrices <- template$adjacency_matrices

      # Update metadata
      project_data$data$metadata$template_used <- i18n$t(template$name_key)
      project_data$data$metadata$connections_reviewed <- FALSE
      project_data$data$metadata$source <- "template_direct_load"  # Flag to prevent AI ISA auto-save overwrite
      project_data$last_modified <- Sys.time()

      debug_log("Updated project data", "TEMPLATE")

      # Save the modified data back to the reactive value
      project_data_reactive(project_data)

      debug_log("Saved project data", "TEMPLATE")

      # Emit ISA change event to trigger CLD regeneration
      if (!is.null(event_bus)) {
        event_bus$emit_isa_change()
        debug_log("Emitted ISA change event for direct load", "TEMPLATE")
      }

      # Show success message
      showNotification(
        sprintf(i18n$t("Template %s loaded!"), i18n$t(template$name_key)),
        type = "message",
               duration = 5
      )

      debug_log("Notification shown", "TEMPLATE")

      # Navigate to dashboard
      if (!is.null(parent_session)) {
        debug_log("Navigating to dashboard", "TEMPLATE")
        updateTabItems(parent_session, "sidebar_menu", "dashboard")
      }

      debug_log("Load complete", "TEMPLATE")
    }, ignoreInit = TRUE, ignoreNULL = TRUE)

    # Customize template button - now shows connection review
    observeEvent(input$customize_template, {
      req(rv$selected_template)

      template <- ses_templates[[rv$selected_template]]

      # Parse connections for review
      rv$template_connections <- parse_template_connections(template)
      rv$review_mode <- "customize"
      rv$show_connection_review <- TRUE

      debug_log(sprintf("Parsed %d connections for customization review", length(rv$template_connections)), "TEMPLATE")
    })

    # Connection review section (displayed in right column)
    output$connection_review_section <- renderUI({
      if (!rv$show_connection_review) {
        return(
          div(style = "padding: 40px; text-align: center; color: #999;",
            icon("arrow-left", style = "font-size: 48px; margin-bottom: 20px;"),
            h5(i18n$t("Select a template and click 'Review' to preview connections")),
            p(i18n$t("Or click 'Load' to load it as-is without review"))
          )
        )
      }

      req(rv$selected_template)
      template <- ses_templates[[rv$selected_template]]

      div(
        # Compact header matching card width
        div(
          style = "max-width: 600px; padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 8px; margin-bottom: 15px;",
          h5(icon("link"), " ", i18n$t("Connection Review"), style = "margin: 0; font-weight: bold;"),
          p(style = "margin: 5px 0 0 0; font-size: 12px;",
            sprintf(i18n$t("%d connections from %s template"),
                    length(rv$template_connections),
                    i18n$t(template$name_key)))
        ),

        # Tabbed connection review component (organized by DAPSI(W)R(M) stages)
        connection_review_tabbed_ui(ns("template_conn_review"), i18n),

        br(),
        # Action buttons matching card width
        div(style = "max-width: 600px;",
          fluidRow(
            column(6,
              actionButton(ns("cancel_review"),
                          i18n$t("Cancel"),
                          icon = icon("times"),
                          class = "btn-secondary btn-lg btn-block")
            ),
            column(6,
              actionButton(ns("finalize_template"),
                          if (rv$review_mode == "customize") i18n$t("Customize Template") else i18n$t("Load Template"),
                          icon = icon("check-circle"),
                          class = "btn-success btn-lg btn-block")
            )
          )
        )
      )
    })

    # Connection review server (tabbed by DAPSI(W)R(M) stages)
    review_status <- connection_review_tabbed_server(
      "template_conn_review",
      connections_reactive = reactive({ rv$template_connections }),
      i18n = i18n,
      on_amend = function(idx, polarity, strength, confidence) {
        # Update the connection when user amends it
        debug_log(sprintf("Connection #%d amended: %s, %s, %d", idx, polarity, strength, confidence), "TEMPLATE")
        rv$template_connections[[idx]]$polarity <- polarity
        rv$template_connections[[idx]]$strength <- strength
        rv$template_connections[[idx]]$confidence <- confidence

        # Update rationale
        rationale <- if (polarity == "+") "drives/increases" else "affects/reduces"
        rv$template_connections[[idx]]$rationale <- paste(
          rv$template_connections[[idx]]$from_name,
          rationale,
          rv$template_connections[[idx]]$to_name
        )
      }
    )

    # Cancel review button
    observeEvent(input$cancel_review, {
      rv$show_connection_review <- FALSE
      rv$template_connections <- NULL
      rv$review_mode <- NULL
    })

    # Finalize template button
    observeEvent(input$finalize_template, {
      req(rv$selected_template, rv$template_connections)

      template <- ses_templates[[rv$selected_template]]

      # Get review status
      status <- review_status()
      approved_idx <- status$approved
      rejected_idx <- status$rejected
      amended_data <- status$amended_data

      # Filter connections: keep only approved (or non-rejected if nothing explicitly approved)
      if (length(approved_idx) > 0) {
        # User explicitly approved some - use only those
        final_connections <- rv$template_connections[approved_idx]
      } else if (length(rejected_idx) > 0) {
        # User rejected some but didn't approve others - keep non-rejected
        keep_idx <- setdiff(seq_along(rv$template_connections), rejected_idx)
        final_connections <- rv$template_connections[keep_idx]
      } else {
        # No approvals or rejections - keep all
        final_connections <- rv$template_connections
      }

      debug_log(sprintf("Finalizing with %d of %d connections (rejected: %d)",
                  length(final_connections),
                  length(rv$template_connections),
                  length(rejected_idx)), "TEMPLATE")

      # Load template data into project
      project_data <- project_data_reactive()

      # Populate ISA data with template
      project_data$data$isa_data$drivers <- template$drivers
      project_data$data$isa_data$activities <- template$activities
      project_data$data$isa_data$pressures <- template$pressures
      project_data$data$isa_data$marine_processes <- template$marine_processes
      project_data$data$isa_data$ecosystem_services <- template$ecosystem_services
      project_data$data$isa_data$goods_benefits <- template$goods_benefits

      # Rebuild adjacency matrices from approved connections
      # Initialize empty matrices
      adj_matrices <- list(
        gb_es = matrix("", nrow = nrow(template$goods_benefits), ncol = nrow(template$ecosystem_services),
                      dimnames = list(template$goods_benefits$Name, template$ecosystem_services$Name)),
        es_mpf = matrix("", nrow = nrow(template$ecosystem_services), ncol = nrow(template$marine_processes),
                       dimnames = list(template$ecosystem_services$Name, template$marine_processes$Name)),
        mpf_p = matrix("", nrow = nrow(template$marine_processes), ncol = nrow(template$pressures),
                      dimnames = list(template$marine_processes$Name, template$pressures$Name)),
        p_a = matrix("", nrow = nrow(template$pressures), ncol = nrow(template$activities),
                    dimnames = list(template$pressures$Name, template$activities$Name)),
        a_d = matrix("", nrow = nrow(template$activities), ncol = nrow(template$drivers),
                    dimnames = list(template$activities$Name, template$drivers$Name)),
        d_gb = matrix("", nrow = nrow(template$drivers), ncol = nrow(template$goods_benefits),
                     dimnames = list(template$drivers$Name, template$goods_benefits$Name))
      )

      # Fill matrices with approved connections
      for (conn in final_connections) {
        from <- conn$from_name
        to <- conn$to_name
        value <- paste0(conn$polarity, conn$strength, ":", conn$confidence)

        # Find which matrix this connection belongs to
        for (matrix_name in names(adj_matrices)) {
          mat <- adj_matrices[[matrix_name]]
          if (from %in% rownames(mat) && to %in% colnames(mat)) {
            adj_matrices[[matrix_name]][from, to] <- value
            break
          }
        }
      }

      project_data$data$isa_data$adjacency_matrices <- adj_matrices

      # Update metadata
      project_data$data$metadata$template_used <- i18n$t(template$name_key)
      project_data$data$metadata$connections_reviewed <- TRUE
      project_data$data$metadata$connections_count <- length(final_connections)
      project_data$data$metadata$source <- "template_reviewed_load"  # Flag to prevent AI ISA auto-save overwrite
      project_data$last_modified <- Sys.time()

      # Save the modified data back to the reactive value
      project_data_reactive(project_data)

      # Emit ISA change event to trigger CLD regeneration
      if (!is.null(event_bus)) {
        event_bus$emit_isa_change()
        debug_log(sprintf("Emitted ISA change event with %d connections", length(final_connections)), "TEMPLATE")
      }

      # Show success message
      showNotification(
        sprintf(i18n$t("Template %s loaded with %d connections!"),
                i18n$t(template$name_key),
                length(final_connections)),
        type = "message",
        duration = 5
      )

      # Navigate based on mode (store mode before resetting)
      current_mode <- rv$review_mode

      # Reset review state
      rv$show_connection_review <- FALSE
      rv$template_connections <- NULL
      rv$review_mode <- NULL

      if (!is.null(parent_session)) {
        if (current_mode == "customize") {
          updateTabItems(parent_session, "sidebar_menu", "create_ses_standard")
        } else {
          updateTabItems(parent_session, "sidebar_menu", "dashboard")
        }
      }
    })
  })
}
