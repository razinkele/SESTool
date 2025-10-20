# Example SES Dataset: Baltic Sea Commercial Fisheries
# A comprehensive example demonstrating the MarineSABRES SES Tool
# Case Study: Decline of cod stocks and ecosystem-based fisheries management

# This file can be loaded to populate the application with example data

create_baltic_sea_example <- function() {

  example_data <- list()

  # ============================================================================
  # CASE STUDY CONTEXT (Exercise 0)
  # ============================================================================

  example_data$case_info <- list(
    name = "Baltic Sea Commercial Fisheries",
    description = "Analysis of declining cod stocks and ecosystem-based management in the Baltic Sea, focusing on the interaction between commercial fishing, ecosystem health, and socio-economic welfare of coastal communities.",
    geographic_scope = "Baltic Sea (ICES subdivisions 24-32)",
    temporal_scope = "2000-2024",
    welfare_impacts = "Declining fish catch revenues, loss of fishing jobs, reduced food security, cultural heritage impacts, ecosystem degradation, eutrophication effects on tourism",
    key_stakeholders = "Commercial fishers, coastal communities, fish processors, EU policy makers, national fisheries agencies (Denmark, Sweden, Poland, Germany, Finland), environmental NGOs (WWF, Baltic Sea Action Group), marine scientists, recreational fishers, tourism operators"
  )

  # ============================================================================
  # GOODS & BENEFITS (Exercise 1)
  # ============================================================================

  example_data$goods_benefits <- data.frame(
    ID = c("GB001", "GB002", "GB003", "GB004", "GB005", "GB006"),
    Name = c(
      "Commercial cod catch",
      "Commercial herring catch",
      "Recreational fishing",
      "Coastal tourism revenue",
      "Cultural heritage (fishing traditions)",
      "Food security (local fish supply)"
    ),
    Type = c("Provisioning", "Provisioning", "Cultural", "Cultural", "Cultural", "Provisioning"),
    Description = c(
      "Annual cod landings for commercial sale",
      "Annual herring landings for commercial sale and processing",
      "Recreational fishing opportunities and catch",
      "Revenue from coastal tourism dependent on clean waters and marine life",
      "Traditional fishing practices and coastal community identity",
      "Local supply of fresh fish for regional consumption"
    ),
    Stakeholder = c(
      "Commercial fishers, processors",
      "Commercial fishers, processors",
      "Recreational fishers, tourists",
      "Tourism operators, coastal businesses",
      "Fishing communities, cultural organizations",
      "Local consumers, restaurants"
    ),
    Importance = c("High", "High", "Medium", "High", "Medium", "Medium"),
    Trend = c("Decreasing", "Stable", "Decreasing", "Increasing", "Decreasing", "Decreasing"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # ECOSYSTEM SERVICES (Exercise 2a)
  # ============================================================================

  example_data$ecosystem_services <- data.frame(
    ID = c("ES001", "ES002", "ES003", "ES004", "ES005", "ES006"),
    Name = c(
      "Cod stock productivity",
      "Herring stock productivity",
      "Nutrient cycling by fish",
      "Water quality maintenance",
      "Biodiversity for recreation",
      "Carbon sequestration"
    ),
    Type = c("Provisioning", "Provisioning", "Regulating", "Regulating", "Cultural", "Regulating"),
    Description = c(
      "Capacity of cod population to reproduce and maintain fishable biomass",
      "Capacity of herring stocks to sustain harvest",
      "Fish contribute to nutrient cycling through feeding and excretion",
      "Ecosystem maintains water clarity and quality",
      "Healthy ecosystem supports diverse marine life for viewing and fishing",
      "Marine vegetation and sediments sequester carbon"
    ),
    LinkedGB = c("GB001: Commercial cod catch", "GB002: Commercial herring catch",
                "GB004: Coastal tourism revenue", "GB004: Coastal tourism revenue",
                "GB003: Recreational fishing", ""),
    Mechanism = c(
      "Spawning success and recruitment generates fishable adult stock",
      "Population dynamics maintain harvestable biomass",
      "Fish predation and waste contribute to nutrient balance",
      "Biological filtration and nutrient uptake maintain clarity",
      "Species diversity attracts recreational users",
      "Photosynthesis in seagrass and algae captures CO2"
    ),
    Confidence = c("High", "High", "Medium", "Medium", "High", "Medium"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # MARINE PROCESSES & FUNCTIONING (Exercise 2b)
  # ============================================================================

  example_data$marine_processes <- data.frame(
    ID = c("MPF001", "MPF002", "MPF003", "MPF004", "MPF005", "MPF006"),
    Name = c(
      "Cod spawning aggregations",
      "Planktonic food web",
      "Benthic habitat structure",
      "Seagrass and macroalgae growth",
      "Oxygen dynamics",
      "Salinity stratification"
    ),
    Type = c("Biological", "Biological", "Ecological", "Biological", "Chemical", "Physical"),
    Description = c(
      "Cod congregate in specific areas for spawning behavior",
      "Phytoplankton-zooplankton-fish interactions",
      "Seabed communities provide habitat complexity",
      "Primary production by marine vegetation",
      "Oxygen production and consumption in water column",
      "Freshwater inflow creates salinity gradients"
    ),
    LinkedES = c("ES001: Cod stock productivity", "ES001: Cod stock productivity",
                "ES004: Water quality maintenance", "ES004: Water quality maintenance",
                "ES001: Cod stock productivity", "ES001: Cod stock productivity"),
    Mechanism = c(
      "Successful spawning leads to larval production and recruitment",
      "Food web supports cod growth and survival",
      "Habitat provides refuge and feeding grounds for fish",
      "Photosynthesis produces oxygen and removes nutrients",
      "Adequate oxygen necessary for fish survival",
      "Salinity affects cod egg buoyancy and survival"
    ),
    Spatial = c("Bornholm Basin", "Basin-wide", "Coastal zones", "Coastal zones",
                "Deep basins", "Basin-wide"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # PRESSURES (Exercise 3)
  # ============================================================================

  example_data$pressures <- data.frame(
    ID = c("P001", "P002", "P003", "P004", "P005", "P006"),
    Name = c(
      "Overfishing of cod",
      "Bottom trawling disturbance",
      "Nutrient enrichment (eutrophication)",
      "Hypoxia (low oxygen zones)",
      "Removal of predatory fish",
      "Climate change warming"
    ),
    Type = c("Biological", "Physical", "Chemical", "Chemical", "Biological", "Multiple"),
    Description = c(
      "Fishing mortality exceeds sustainable levels",
      "Physical disturbance of seabed by trawl gear",
      "Excessive nitrogen and phosphorus loading",
      "Oxygen depletion in deep waters",
      "Removal of large predators alters food web",
      "Increasing water temperatures affect species distribution"
    ),
    LinkedMPF = c("MPF001: Cod spawning aggregations", "MPF003: Benthic habitat structure",
                 "MPF004: Seagrass and macroalgae growth", "MPF005: Oxygen dynamics",
                 "MPF002: Planktonic food web", "MPF006: Salinity stratification"),
    Intensity = c("High", "High", "High", "High", "Medium", "Medium"),
    Spatial = c("Fishing grounds", "Trawling areas", "Entire Baltic",
                "Deep basins", "Fishing grounds", "Entire Baltic"),
    Temporal = c("Continuous", "Seasonal", "Continuous", "Seasonal (summer)",
                "Continuous", "Long-term trend"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # ACTIVITIES (Exercise 4)
  # ============================================================================

  example_data$activities <- data.frame(
    ID = c("A001", "A002", "A003", "A004", "A005", "A006"),
    Name = c(
      "Commercial bottom trawl fishing",
      "Commercial gillnet fishing",
      "Agricultural nutrient runoff",
      "Municipal wastewater discharge",
      "Coastal development",
      "Shipping and transport"
    ),
    Sector = c("Fisheries", "Fisheries", "Agriculture", "Other", "Other", "Shipping"),
    Description = c(
      "Bottom trawling for cod and flatfish",
      "Gillnet fishing for cod and salmon",
      "Fertilizer application on farmland leading to runoff",
      "Urban sewage discharge into coastal waters",
      "Construction and urbanization of coastal areas",
      "Commercial shipping traffic through the Baltic"
    ),
    LinkedP = c("P001: Overfishing of cod", "P001: Overfishing of cod",
               "P003: Nutrient enrichment (eutrophication)", "P003: Nutrient enrichment (eutrophication)",
               "P002: Bottom trawling disturbance", "P006: Climate change warming"),
    Scale = c("Regional", "Regional", "National", "Local", "Local", "International"),
    Frequency = c("Continuous", "Seasonal", "Seasonal", "Continuous", "Occasional", "Continuous"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # DRIVERS (Exercise 5)
  # ============================================================================

  example_data$drivers <- data.frame(
    ID = c("D001", "D002", "D003", "D004", "D005", "D006", "D007"),
    Name = c(
      "Global seafood demand",
      "EU Common Fisheries Policy",
      "Agricultural intensification",
      "Population growth in coastal areas",
      "Economic development pressure",
      "Climate change",
      "Fishing fleet overcapacity"
    ),
    Type = c("Economic", "Political", "Economic", "Demographic", "Economic", "Environmental", "Economic"),
    Description = c(
      "High global demand for cod and other fish products drives fishing effort",
      "EU regulations on fishing quotas and management measures",
      "Demand for agricultural products leads to intensive farming practices",
      "Urbanization of coastal zones increases wastewater loads",
      "Economic growth drives development and resource use",
      "Global greenhouse gas emissions causing ocean warming",
      "Too many vessels competing for declining fish stocks"
    ),
    LinkedA = c("A001: Commercial bottom trawl fishing", "A001: Commercial bottom trawl fishing",
               "A003: Agricultural nutrient runoff", "A004: Municipal wastewater discharge",
               "A005: Coastal development", "A006: Shipping and transport",
               "A002: Commercial gillnet fishing"),
    Trend = c("Increasing", "Stable", "Increasing", "Increasing", "Increasing",
             "Increasing", "Decreasing"),
    Controllability = c("Low", "High", "Medium", "High", "Medium", "Low", "High"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # STAKEHOLDERS (PIMS)
  # ============================================================================

  example_data$stakeholders <- data.frame(
    ID = c("SH001", "SH002", "SH003", "SH004", "SH005", "SH006", "SH007", "SH008"),
    Name = c(
      "Baltic Sea Fishers Association",
      "WWF Baltic Sea Programme",
      "European Commission DG MARE",
      "ICES (International Council for Exploration of the Sea)",
      "Polish Ministry of Maritime Economy",
      "Coastal Tourism Board",
      "Local Fishing Communities (Kaliningrad)",
      "Helsinki Commission (HELCOM)"
    ),
    Type = c("Resource Users", "NGO/Civil Society", "Government/Regulators", "Scientific/Academic",
            "Government/Regulators", "Industry/Business", "Local Communities", "Government/Regulators"),
    Sector = c("Fisheries", "Conservation", "Policy/Management", "Research", "Policy/Management",
              "Tourism", "Fisheries", "Policy/Management"),
    Contact = c("info@balticfishers.org", "baltic@wwf.org", "MARE@ec.europa.eu",
               "info@ices.dk", "contact@mgm.gov.pl", "tourism@baltic-coast.eu",
               "community@kaliningrad.ru", "helcom@helcom.fi"),
    Interests = c(
      "Sustainable livelihoods, fair quota allocation, market access",
      "Ecosystem protection, biodiversity conservation, pollution reduction",
      "Sustainable fisheries management, EU policy implementation, compliance",
      "Scientific assessment, data collection, stock evaluation",
      "National fishing industry support, employment, food security",
      "Clean waters for tourism, coastal amenities, visitor experience",
      "Traditional fishing rights, cultural heritage, local economy",
      "Regional cooperation, pollution control, ecosystem health"
    ),
    Role = c(
      "Fishing industry representative and advocate",
      "Environmental advocacy and conservation projects",
      "Policy maker and regulator at EU level",
      "Scientific advice provider for fisheries management",
      "National policy implementation and enforcement",
      "Tourism industry representative",
      "Affected community and resource users",
      "Intergovernmental coordination body"
    ),
    Power = c("Medium", "Medium", "High", "High", "High", "Low", "Low", "High"),
    Interest = c("High", "High", "High", "High", "High", "Medium", "High", "High"),
    Attitude = c("Resistant", "Supportive", "Neutral", "Neutral", "Supportive",
                "Supportive", "Resistant", "Supportive"),
    EngagementLevel = c("Collaborate", "Collaborate", "Empower", "Consult", "Collaborate",
                       "Inform", "Involve", "Collaborate"),
    DateAdded = rep(as.character(Sys.Date()), 8),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # BOT (Behaviour Over Time) DATA
  # ============================================================================

  example_data$bot_data <- data.frame(
    ElementType = c(
      rep("gb", 10), rep("gb", 10), rep("p", 10), rep("d", 10)
    ),
    ElementID = c(
      rep("GB001", 10), rep("GB004", 10), rep("P003", 10), rep("D001", 10)
    ),
    Year = c(
      2014:2023, 2014:2023, 2014:2023, 2014:2023
    ),
    Value = c(
      # Commercial cod catch (declining)
      c(45000, 42000, 38000, 35000, 30000, 28000, 25000, 22000, 20000, 18000),
      # Tourism revenue (increasing)
      c(120, 135, 145, 160, 175, 190, 210, 230, 250, 270),
      # Nutrient loading (slowly declining)
      c(650, 640, 630, 620, 610, 605, 600, 595, 590, 585),
      # Seafood demand (increasing)
      c(100, 105, 108, 112, 118, 125, 132, 140, 148, 156)
    ),
    Unit = c(
      rep("tonnes", 10), rep("million EUR", 10), rep("thousand tonnes N", 10),
      rep("index (2014=100)", 10)
    ),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # LOOP CONNECTIONS (Exercise 6)
  # ============================================================================

  example_data$loop_connections <- data.frame(
    DriverID = c("D001", "D007", "D002"),
    GBID = c("GB001", "GB001", "GB001"),
    Effect = c("Negative", "Negative", "Positive"),
    Mechanism = c(
      "High demand leads to overfishing which depletes stocks reducing catch",
      "Overcapacity increases competition and fishing pressure reducing stocks",
      "Improved regulations can help restore stocks improving future catches"
    ),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # ENGAGEMENT ACTIVITIES
  # ============================================================================

  example_data$engagements <- data.frame(
    ID = c("ENG001", "ENG002", "ENG003", "ENG004"),
    StakeholderID = c("SH001", "SH002", "SH004", "SH007"),
    StakeholderName = c("Baltic Sea Fishers Association", "WWF Baltic Sea Programme",
                        "ICES (International Council for Exploration of the Sea)",
                        "Local Fishing Communities (Kaliningrad)"),
    Method = c("Workshop", "Interview", "Advisory Committee", "Focus Group"),
    Date = c("2024-03-15", "2024-04-10", "2024-05-20", "2024-06-05"),
    Objectives = c(
      "Discuss quota allocations and fishers' perspectives on stock decline",
      "Understand conservation priorities and ecosystem restoration options",
      "Review latest stock assessments and scientific recommendations",
      "Gather community concerns and traditional ecological knowledge"
    ),
    Outcomes = c(
      "Agreement to pilot selective fishing gear; concerns about economic impacts",
      "Partnership on marine protected area design and monitoring",
      "Updated stock status confirms need for reduced fishing pressure",
      "Identified cultural heritage sites and seasonal fishing patterns"
    ),
    Status = c("Completed", "Completed", "Completed", "Completed"),
    Facilitator = c("Project Team", "Dr. Anna Kowalski", "ICES Secretariat", "Local NGO"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # COMMUNICATIONS
  # ============================================================================

  example_data$communications <- data.frame(
    ID = c("COMM001", "COMM002", "COMM003"),
    Audience = c("All Stakeholders", "Government", "Scientific Community"),
    Type = c("Newsletter", "Report", "Presentation"),
    Date = c("2024-07-01", "2024-08-15", "2024-09-10"),
    Frequency = c("Quarterly", "Annual", "One-time"),
    Message = c(
      "Project update on ISA analysis progress, stakeholder engagement summary, next steps",
      "Comprehensive SES analysis results and policy recommendations for Baltic cod recovery",
      "Presentation of Causal Loop Diagram and key feedback loops at marine science conference"
    ),
    Responsible = c("Communications Officer", "Project Lead", "Lead Scientist"),
    stringsAsFactors = FALSE
  )

  # ============================================================================
  # ADJACENCY MATRICES (Exercise 2c) - Connections between DAPSI(W)R(M) levels
  # ============================================================================

  # ES → GB (6 ES x 6 GB)
  example_data$adjacency_matrices <- list()
  example_data$adjacency_matrices$gb_es <- matrix(
    c("+strong", "",        "",         "",        "",        "",
      "",        "+strong", "",         "",        "",        "",
      "",        "",        "",         "",        "+medium", "",
      "",        "",        "+medium",  "+medium", "",        "",
      "",        "",        "",         "",        "+medium", "",
      "",        "",        "",         "",        "",        "+weak"),
    nrow = 6, ncol = 6, byrow = TRUE,
    dimnames = list(
      example_data$ecosystem_services$Name,
      example_data$goods_benefits$Name
    )
  )

  # MPF → ES (6 MPF x 6 ES)
  example_data$adjacency_matrices$es_mpf <- matrix(
    c("+strong", "",        "",        "",        "",        "",
      "",        "+strong", "",        "",        "",        "",
      "+medium", "+medium", "",        "",        "",        "",
      "",        "",        "+strong", "",        "",        "",
      "",        "",        "",        "+medium", "+medium", "",
      "",        "",        "+medium", "",        "",        "+strong"),
    nrow = 6, ncol = 6, byrow = TRUE,
    dimnames = list(
      example_data$marine_processes$Name,
      example_data$ecosystem_services$Name
    )
  )

  # P → MPF (6 P x 6 MPF)
  example_data$adjacency_matrices$mpf_p <- matrix(
    c("-strong", "",        "",        "",        "",        "",
      "",        "-strong", "",        "",        "",        "",
      "",        "",        "-medium", "-medium", "",        "",
      "-medium", "",        "",        "-strong", "",        "",
      "",        "-weak",   "",        "",        "-medium", "",
      "",        "",        "",        "",        "",        "-medium"),
    nrow = 6, ncol = 6, byrow = TRUE,
    dimnames = list(
      example_data$pressures$Name,
      example_data$marine_processes$Name
    )
  )

  # A → P (6 A x 6 P)
  example_data$adjacency_matrices$p_a <- matrix(
    c("+strong", "",        "",        "",        "",        "",
      "",        "+medium", "+medium", "",        "",        "",
      "",        "",        "",        "+strong", "",        "",
      "",        "+weak",   "",        "",        "+medium", "",
      "",        "",        "+medium", "",        "",        "+strong",
      "",        "",        "",        "+weak",   "+weak",   ""),
    nrow = 6, ncol = 6, byrow = TRUE,
    dimnames = list(
      example_data$activities$Name,
      example_data$pressures$Name
    )
  )

  # D → A (7 D x 6 A)
  example_data$adjacency_matrices$a_d <- matrix(
    c("+strong", "",        "",        "",        "",        "",
      "+medium", "+strong", "",        "",        "",        "",
      "",        "",        "+strong", "",        "",        "",
      "",        "+medium", "",        "+strong", "",        "",
      "",        "",        "",        "",        "+medium", "+medium",
      "",        "",        "+weak",   "",        "+weak",   "",
      "",        "+weak",   "",        "+weak",   "",        "+weak"),
    nrow = 7, ncol = 6, byrow = TRUE,
    dimnames = list(
      example_data$drivers$Name,
      example_data$activities$Name
    )
  )

  # Feedback: D → GB (optional - creates feedback loops)
  example_data$adjacency_matrices$d_gb <- matrix(
    "", nrow = 6, ncol = 7, byrow = TRUE,
    dimnames = list(
      example_data$goods_benefits$Name,
      example_data$drivers$Name
    )
  )
  # Add some feedback connections
  example_data$adjacency_matrices$d_gb[1, 1] <- "-weak"   # Commercial cod catch → Market demand
  example_data$adjacency_matrices$d_gb[6, 3] <- "+weak"   # Food security → Population growth

  # ============================================================================
  # METADATA
  # ============================================================================

  example_data$metadata <- list(
    title = "Baltic Sea Commercial Fisheries SES Analysis",
    version = "1.0",
    created_date = Sys.Date(),
    created_by = "MarineSABRES Example Dataset",
    description = "Example dataset demonstrating a complete ISA analysis for Baltic Sea cod fisheries, including DAPSI(W)R(M) elements, stakeholders, BOT data, and engagement activities.",
    case_study_region = "Baltic Sea",
    primary_issue = "Declining cod stocks and ecosystem-based fisheries management",
    data_sources = "Simulated data based on real Baltic Sea conditions and peer-reviewed literature",
    notes = "This is an example dataset for demonstration and testing purposes. Real projects should use actual data from stakeholder engagement and scientific monitoring."
  )

  return(example_data)
}

# Create the example data
baltic_sea_data <- create_baltic_sea_example()

# Wrap in proper project_data structure to match app expectations
# This structure matches init_session_data() in global.R
project_data <- list(
  project_id = "PROJ_BALTIC_SEA_EXAMPLE",
  project_name = "Baltic Sea Commercial Fisheries",
  created_at = as.POSIXct("2024-01-15 10:00:00"),
  last_modified = as.POSIXct("2024-01-15 10:00:00"),
  user = "example_user",
  version = "1.0",
  data = list(
    metadata = list(
      da_site = baltic_sea_data$case_info$name,
      focal_issue = "Declining cod stocks and ecosystem-based fisheries management",
      geographic_scope = baltic_sea_data$case_info$geographic_scope,
      temporal_scope = baltic_sea_data$case_info$temporal_scope,
      welfare_impacts = baltic_sea_data$case_info$welfare_impacts,
      stakeholders = baltic_sea_data$case_info$key_stakeholders,
      description = baltic_sea_data$case_info$description
    ),
    isa_data = list(
      goods_benefits = baltic_sea_data$goods_benefits,
      ecosystem_services = baltic_sea_data$ecosystem_services,
      marine_processes = baltic_sea_data$marine_processes,
      pressures = baltic_sea_data$pressures,
      activities = baltic_sea_data$activities,
      drivers = baltic_sea_data$drivers,
      adjacency_matrices = baltic_sea_data$adjacency_matrices
    ),
    cld = list(
      nodes = data.frame(),
      edges = data.frame(),
      loops = data.frame()
    ),
    pims = list(
      stakeholders = data.frame(),
      interests = data.frame(),
      management_options = data.frame()
    ),
    responses = list()
  )
)

# Save as RDS file for easy loading
saveRDS(project_data,
        file = "data/example_baltic_sea_fisheries.rds")

# Also save as Excel workbook for external use
library(openxlsx)

wb <- createWorkbook()

# Add metadata sheet
addWorksheet(wb, "Metadata")
metadata_df <- data.frame(
  Field = names(project_data$data$metadata),
  Value = unlist(project_data$data$metadata),
  stringsAsFactors = FALSE
)
writeData(wb, "Metadata", metadata_df)

# Add case info
addWorksheet(wb, "Case_Info")
case_df <- data.frame(
  Field = names(baltic_sea_data$case_info),
  Value = unlist(baltic_sea_data$case_info),
  stringsAsFactors = FALSE
)
writeData(wb, "Case_Info", case_df)

# Add all data tables
addWorksheet(wb, "Goods_Benefits")
writeData(wb, "Goods_Benefits", project_data$data$isa_data$goods_benefits)

addWorksheet(wb, "Ecosystem_Services")
writeData(wb, "Ecosystem_Services", project_data$data$isa_data$ecosystem_services)

addWorksheet(wb, "Marine_Processes")
writeData(wb, "Marine_Processes", project_data$data$isa_data$marine_processes)

addWorksheet(wb, "Pressures")
writeData(wb, "Pressures", project_data$data$isa_data$pressures)

addWorksheet(wb, "Activities")
writeData(wb, "Activities", project_data$data$isa_data$activities)

addWorksheet(wb, "Drivers")
writeData(wb, "Drivers", project_data$data$isa_data$drivers)

addWorksheet(wb, "Loop_Connections")
writeData(wb, "Loop_Connections", baltic_sea_data$loop_connections)

addWorksheet(wb, "Stakeholders")
writeData(wb, "Stakeholders", baltic_sea_data$stakeholders)

addWorksheet(wb, "Engagements")
writeData(wb, "Engagements", baltic_sea_data$engagements)

addWorksheet(wb, "Communications")
writeData(wb, "Communications", baltic_sea_data$communications)

addWorksheet(wb, "BOT_Data")
writeData(wb, "BOT_Data", baltic_sea_data$bot_data)

# Save workbook
saveWorkbook(wb, "data/example_baltic_sea_fisheries.xlsx", overwrite = TRUE)

cat("Example Baltic Sea Fisheries SES dataset created successfully!\n")
cat("Files saved:\n")
cat("  - data/example_baltic_sea_fisheries.rds\n")
cat("  - data/example_baltic_sea_fisheries.xlsx\n")
cat("\nThis example includes:\n")
cat("  - 6 Goods & Benefits\n")
cat("  - 6 Ecosystem Services\n")
cat("  - 6 Marine Processes\n")
cat("  - 6 Pressures\n")
cat("  - 6 Activities\n")
cat("  - 7 Drivers\n")
cat("  - 8 Stakeholders\n")
cat("  - 4 Engagement activities\n")
cat("  - 3 Communications\n")
cat("  - 40 BOT data points\n")
cat("  - 3 Loop connections\n")
cat("\nCase Study: Baltic Sea Commercial Fisheries\n")
cat("Focus: Declining cod stocks and ecosystem-based management\n")
