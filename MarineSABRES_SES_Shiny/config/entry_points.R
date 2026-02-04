# config/entry_points.R
# Entry Point System Constants (Marine Management DSS & Toolbox)
# Based on: Elliott, M. - Discussion Document V3.0
#
# Extracted from global.R for maintainability.
# These constants define the guided entry point system for the SES Toolbox.

# EP0: Marine Manager Typology (Who am I?)
EP0_MANAGER_ROLES <- list(
  list(
    id = "policy_creator",
    label = "Policy Creator",
    description = "Someone creating marine management policies",
    icon = "landmark",
    typical_tasks = c("Policy development", "Strategic planning", "Legislation design")
  ),
  list(
    id = "policy_implementer",
    label = "Policy Implementer (Regulator)",
    description = "Someone implementing and enforcing policies",
    icon = "gavel",
    typical_tasks = c("Compliance monitoring", "Enforcement", "Permitting")
  ),
  list(
    id = "policy_advisor",
    label = "Policy Advisor",
    description = "Someone advising those who create and implement policies",
    icon = "user-tie",
    typical_tasks = c("Scientific advice", "Evidence synthesis", "Impact assessment")
  ),
  list(
    id = "activity_manager",
    label = "Activity Manager (Regulator)",
    description = "Manager of specific marine activities",
    icon = "tasks",
    typical_tasks = c("Operations management", "Resource allocation", "Activity coordination")
  ),
  list(
    id = "activity_advisor",
    label = "Activity Advisor",
    description = "Advisor to managers of marine activities",
    icon = "hands-helping",
    typical_tasks = c("Technical consulting", "Best practice guidance", "Training")
  ),
  list(
    id = "engo_worker",
    label = "eNGO Worker",
    description = "Environmental NGO worker influencing or lobbying decisions",
    icon = "leaf",
    typical_tasks = c("Advocacy", "Public campaigns", "Policy influence")
  ),
  list(
    id = "fisher",
    label = "Fisher (Influencer)",
    description = "Fishers as industry influencers",
    icon = "fish",
    typical_tasks = c("Fishing operations", "Industry representation", "Traditional knowledge")
  ),
  list(
    id = "other_industry",
    label = "Other Industry (Influencer)",
    description = "Non-fishing industry stakeholders",
    icon = "industry",
    typical_tasks = c("Industry operations", "Business advocacy", "Economic development")
  ),
  list(
    id = "sme",
    label = "SME (Influencer)",
    description = "Small/medium enterprise influencers",
    icon = "store",
    typical_tasks = c("Business operations", "Local development", "Innovation")
  ),
  list(
    id = "educator_researcher",
    label = "Educator/Researcher",
    description = "Educators and researchers as influencers",
    icon = "graduation-cap",
    typical_tasks = c("Research", "Education", "Knowledge generation")
  )
)

# EP1: Drivers (Basic Human Needs) (Why do I care?)
EP1_BASIC_NEEDS <- list(
  list(
    id = "welfare",
    label = "Welfare",
    subtitle = "Safety, Health, Security",
    description = "Ensuring safety, health, and security of coastal communities",
    icon = "shield-alt",
    color = "#3498db",
    examples = c("Coastal protection", "Water quality", "Food safety", "Disaster preparedness")
  ),
  list(
    id = "resource_provision",
    label = "Resource Provision",
    subtitle = "Space, Food, Water",
    description = "Providing essential resources from the marine environment",
    icon = "box-open",
    color = "#27ae60",
    examples = c("Fishing grounds", "Aquaculture sites", "Renewable energy space", "Water resources")
  ),
  list(
    id = "employment",
    label = "Employment & Resource Use",
    subtitle = "Livelihoods, Jobs",
    description = "Supporting employment and sustainable resource use",
    icon = "briefcase",
    color = "#f39c12",
    examples = c("Fishing jobs", "Tourism employment", "Marine industries", "Blue economy")
  ),
  list(
    id = "enjoyment",
    label = "Relaxation & Enjoyment",
    subtitle = "Satisfaction, Culture, Aesthetics",
    description = "Enabling recreation, cultural connection, and aesthetic appreciation",
    icon = "umbrella-beach",
    color = "#9b59b6",
    examples = c("Beach access", "Marine parks", "Cultural heritage", "Scenic beauty")
  )
)

# EP2: Activity Sectors / MSFD Themes (What activities?)
EP2_ACTIVITY_SECTORS <- list(
  list(
    id = "physical_restructuring",
    label = "Physical Restructuring",
    description = "Rivers, coastline, seabed restructuring; water management",
    icon = "tractor",
    msfd_descriptor = "D6, D7",
    examples = c("Coastal engineering", "Dredging", "Land reclamation", "Water diversion")
  ),
  list(
    id = "nonliving_extraction",
    label = "Non-Living Resource Extraction",
    description = "Aggregates, minerals, oil, gas extraction",
    icon = "gem",
    msfd_descriptor = "D3, D11",
    examples = c("Sand/gravel extraction", "Oil/gas production", "Mineral mining")
  ),
  list(
    id = "energy_production",
    label = "Energy Production",
    description = "Offshore wind, tidal, wave, oil/gas energy",
    icon = "bolt",
    msfd_descriptor = "D11",
    examples = c("Offshore wind farms", "Tidal energy", "Wave power", "Oil platforms")
  ),
  list(
    id = "living_extraction",
    label = "Living Resource Extraction",
    description = "Fishing, whaling, seaweed harvesting",
    icon = "fish",
    msfd_descriptor = "D3, D4",
    examples = c("Commercial fishing", "Recreational fishing", "Seaweed collection")
  ),
  list(
    id = "cultivation",
    label = "Living Resource Cultivation",
    description = "Aquaculture, mariculture operations",
    icon = "seedling",
    msfd_descriptor = "D5",
    examples = c("Fish farming", "Shellfish cultivation", "Seaweed farming")
  ),
  list(
    id = "transport",
    label = "Transport",
    description = "Shipping, ports, navigation",
    icon = "ship",
    msfd_descriptor = "D11",
    examples = c("Commercial shipping", "Ferry services", "Port operations", "Navigation routes")
  ),
  list(
    id = "urban_industrial",
    label = "Urban & Industrial Uses",
    description = "Coastal development, carbon storage",
    icon = "city",
    msfd_descriptor = "D8, D9",
    examples = c("Coastal infrastructure", "Industrial facilities", "Carbon capture and storage")
  ),
  list(
    id = "tourism_leisure",
    label = "Tourism & Leisure",
    description = "Recreation, diving, yachting",
    icon = "umbrella-beach",
    msfd_descriptor = "D11",
    examples = c("Beach tourism", "Diving", "Sailing", "Coastal recreation")
  ),
  list(
    id = "security_defense",
    label = "Security/Defense",
    description = "Military operations, surveillance",
    icon = "shield-alt",
    msfd_descriptor = "D11",
    examples = c("Naval operations", "Coastal surveillance", "Defense installations")
  ),
  list(
    id = "education_research",
    label = "Education & Research",
    description = "Monitoring, scientific studies",
    icon = "flask",
    msfd_descriptor = "All",
    examples = c("Marine research", "Environmental monitoring", "Educational programs")
  ),
  list(
    id = "conservation_restoration",
    label = "Conservation & Restoration",
    description = "Protected areas, habitat restoration",
    icon = "tree",
    msfd_descriptor = "D1, D4, D6",
    examples = c("Marine protected areas", "Habitat restoration", "Species conservation")
  ),
  list(
    id = "mixed_use",
    label = "Multiple/Mixed Use",
    description = "Areas with multiple overlapping activities",
    icon = "layer-group",
    msfd_descriptor = "All",
    examples = c("Multi-use zones", "Spatial conflicts", "Integrated management")
  )
)

# EP3: Risks & Hazards (What threats?)
EP3_RISKS_HAZARDS <- list(
  # Natural Hazards
  list(
    id = "hydro_flood",
    label = "Flooding & Storm Surge",
    category = "Natural",
    temporal = "Acute",
    description = "Flooding, storm surge, tsunamis",
    icon = "water",
    severity = "High"
  ),
  list(
    id = "physio_natural_chronic",
    label = "Coastal Erosion",
    category = "Natural",
    temporal = "Chronic",
    description = "Coastal erosion, long-term sediment changes",
    icon = "mountain",
    severity = "Medium"
  ),
  list(
    id = "physio_human_chronic",
    label = "Coastal Development Impacts",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Land reclamation, space removal",
    icon = "bulldozer",
    severity = "High"
  ),
  list(
    id = "physio_acute",
    label = "Landslides & Cliff Failures",
    category = "Natural",
    temporal = "Acute",
    description = "Cliff failure, landslides",
    icon = "exclamation-triangle",
    severity = "High"
  ),
  list(
    id = "climate_acute",
    label = "Extreme Weather Events",
    category = "Natural",
    temporal = "Acute",
    description = "Extreme storms, heat waves",
    icon = "cloud-showers-heavy",
    severity = "High"
  ),
  list(
    id = "climate_chronic",
    label = "Climate Change (Sea-level, Acidification)",
    category = "Natural",
    temporal = "Chronic",
    description = "Sea-level rise, NAO changes, ocean acidification",
    icon = "temperature-high",
    severity = "Critical"
  ),
  list(
    id = "tectonic_acute",
    label = "Earthquakes",
    category = "Natural",
    temporal = "Acute",
    description = "Earthquakes, land slips",
    icon = "frown",
    severity = "High"
  ),
  list(
    id = "tectonic_chronic",
    label = "Land Subsidence",
    category = "Natural",
    temporal = "Chronic",
    description = "Subsidence, isostatic rebound",
    icon = "arrows-alt-v",
    severity = "Medium"
  ),
  list(
    id = "bio_micro",
    label = "Pollution & Pathogens",
    category = "Anthropogenic",
    temporal = "Both",
    description = "Sewage pollution, pathogens",
    icon = "bacterium",
    severity = "Medium"
  ),
  list(
    id = "bio_macro",
    label = "Invasive Species & Harmful Blooms",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Non-indigenous species, harmful algal blooms",
    icon = "dna",
    severity = "High"
  ),
  list(
    id = "tech_introduced",
    label = "Infrastructure & Dredging Impacts",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Infrastructure, dredging, sediment disposal",
    icon = "cogs",
    severity = "Medium"
  ),
  list(
    id = "tech_extractive",
    label = "Fishing & Resource Extraction",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Fishing impacts, aggregate extraction",
    icon = "industry",
    severity = "High"
  ),
  list(
    id = "chem_acute",
    label = "Oil Spills & Chemical Accidents",
    category = "Anthropogenic",
    temporal = "Acute",
    description = "Oil spills, chemical accidents",
    icon = "oil-can",
    severity = "Critical"
  ),
  list(
    id = "chem_chronic",
    label = "Chronic Pollution",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Diffuse pollution, point-source contaminants",
    icon = "flask-poison",
    severity = "High"
  ),
  list(
    id = "geopolitical_acute",
    label = "Conflicts & Civil Unrest",
    category = "Anthropogenic",
    temporal = "Acute",
    description = "Wars, terrorism, civil unrest",
    icon = "bomb",
    severity = "Critical"
  ),
  list(
    id = "geopolitical_chronic",
    label = "Migration & Social Displacement",
    category = "Anthropogenic",
    temporal = "Chronic",
    description = "Human migrations, refugee crises, conflicts",
    icon = "users",
    severity = "High"
  ),
  # Social & Economic Risks
  list(
    id = "social_inequality",
    label = "Social Inequality & Injustice",
    category = "Social",
    temporal = "Chronic",
    description = "Poverty, inequality, lack of access to resources",
    icon = "balance-scale",
    severity = "High"
  ),
  list(
    id = "food_insecurity",
    label = "Food & Livelihood Security",
    category = "Social",
    temporal = "Both",
    description = "Threats to food security, livelihoods, employment",
    icon = "utensils",
    severity = "High"
  ),
  list(
    id = "health_wellbeing",
    label = "Public Health & Wellbeing",
    category = "Social",
    temporal = "Both",
    description = "Health risks, disease, mental health impacts",
    icon = "heartbeat",
    severity = "High"
  ),
  list(
    id = "cultural_heritage",
    label = "Cultural Heritage Loss",
    category = "Social",
    temporal = "Chronic",
    description = "Loss of traditional practices, cultural identity, heritage sites",
    icon = "landmark",
    severity = "Medium"
  )
)

# EP4: Topics (What knowledge domain?)
EP4_TOPICS <- list(
  # Foundation
  list(id = "basic_concepts", label = "Basic Concepts & Fundamental Understanding", domain = "Foundation", icon = "book"),
  list(id = "ecosystem_structure", label = "Ecosystem Structure & Functioning", domain = "Natural", icon = "project-diagram"),

  # Natural Domain
  list(id = "ecosystem_services", label = "Ecosystem Services (natural domain)", domain = "Natural", icon = "leaf"),
  list(id = "biodiversity", label = "Biodiversity Loss (habitats & species)", domain = "Natural", icon = "dove"),
  list(id = "nis", label = "Non-Indigenous Species", domain = "Natural", icon = "bug"),
  list(id = "climate", label = "Climate Change", domain = "Natural", icon = "temperature-high"),
  list(id = "anthropogenic_effects", label = "Other Anthropogenic Effects", domain = "Natural", icon = "smog"),
  list(id = "recovery", label = "Ecosystem Recovery & Remediation", domain = "Natural", icon = "medkit"),

  # Economic Domain
  list(id = "fisheries_econ", label = "Fisheries - Economics Aspects", domain = "Economic", icon = "coins"),
  list(id = "resource_econ", label = "Other Resource Extraction (energy, space)", domain = "Economic", icon = "battery-full"),
  list(id = "goods_benefits", label = "Economic Aspects - Societal Goods & Benefits", domain = "Economic", icon = "hand-holding-usd"),

  # Governance
  list(id = "governance", label = "Governance & Management", domain = "Governance", icon = "balance-scale"),
  list(id = "policy_derivation", label = "Policy Derivation", domain = "Governance", icon = "file-signature"),
  list(id = "policy_implementation", label = "Policy Implementation", domain = "Governance", icon = "tasks"),
  list(id = "conservation", label = "Marine Conservation", domain = "Governance", icon = "shield-alt"),
  list(id = "planning", label = "Marine Planning", domain = "Governance", icon = "map-marked-alt"),

  # Social
  list(id = "societal", label = "Societal & Cultural Considerations", domain = "Social", icon = "users"),
  list(id = "citizenship", label = "Marine Citizenship", domain = "Social", icon = "user-check"),

  # Methodological
  list(id = "skills_data", label = "Scientific Skills, Mapping, Evidence & Data", domain = "Methodological", icon = "database"),
  list(id = "methods", label = "Methods, Techniques, Tools", domain = "Methodological", icon = "wrench")
)

# EP5: Management Solutions (10 Tenets) (How to solve?)
EP5_MANAGEMENT_TENETS <- list(
  list(
    id = "ecological",
    label = "Ecologically Sustainable",
    description = "Maintain ecosystem integrity and function",
    icon = "leaf",
    color = "#27ae60",
    principle = "Ecology, natural environment"
  ),
  list(
    id = "technological",
    label = "Technologically Feasible",
    description = "Solutions must be practically achievable",
    icon = "cogs",
    color = "#3498db",
    principle = "Technology, techniques"
  ),
  list(
    id = "economic",
    label = "Economically Viable",
    description = "Cost-effective and financially sustainable",
    icon = "coins",
    color = "#f39c12",
    principle = "Economics, valuation"
  ),
  list(
    id = "social",
    label = "Socially Desirable/Tolerable",
    description = "Acceptable to affected communities",
    icon = "users",
    color = "#9b59b6",
    principle = "Society, stakeholders"
  ),
  list(
    id = "legal",
    label = "Legally Permissible",
    description = "Compliant with legal frameworks",
    icon = "gavel",
    color = "#34495e",
    principle = "Laws, agreements, regulations"
  ),
  list(
    id = "administrative",
    label = "Administratively Achievable",
    description = "Within institutional capabilities",
    icon = "building",
    color = "#16a085",
    principle = "Authorities, agencies, capacity"
  ),
  list(
    id = "political",
    label = "Politically Expedient",
    description = "Aligned with political priorities",
    icon = "landmark",
    color = "#c0392b",
    principle = "Politics, policies, timing"
  ),
  list(
    id = "ethical",
    label = "Ethically Defensible/Morally Correct",
    description = "Consistent with ethical principles",
    icon = "hands-helping",
    color = "#8e44ad",
    principle = "Ethics, morals, values"
  ),
  list(
    id = "cultural",
    label = "Culturally Inclusive",
    description = "Respects cultural diversity",
    icon = "globe",
    color = "#d35400",
    principle = "Culture, aesthetics, heritage"
  ),
  list(
    id = "communicable",
    label = "Effectively Communicable",
    description = "Can be clearly explained to stakeholders",
    icon = "comments",
    color = "#2980b9",
    principle = "Communication, literacy, transparency"
  )
)
