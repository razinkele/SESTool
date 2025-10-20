# data/example_isa_data.R
# Example ISA data for testing and demonstration

# Create example ISA data structure
example_isa_data <- list(
  
  # Goods & Benefits
  goods_benefits = data.frame(
    id = c("GB_1", "GB_2", "GB_3"),
    name = c("Commercial Fish Catch", "Tourism Revenue", "Coastal Protection"),
    indicator = c("Tonnes of fish landed per year", 
                 "Number of tourists per year",
                 "Coastal erosion rate (m/year)"),
    indicator_unit = c("tonnes/year", "persons/year", "m/year"),
    data_source = c("National Fisheries Database", 
                   "Tourism Statistics Office",
                   "Coastal Monitoring Programme"),
    time_horizon_start = as.Date(c("2010-01-01", "2010-01-01", "2010-01-01")),
    time_horizon_end = as.Date(c("2023-12-31", "2023-12-31", "2023-12-31")),
    baseline_value = c(10000, 50000, 2.5),
    current_value = c(8500, 75000, 1.8),
    notes = c("Declining trend", "Increasing trend", "Improved protection"),
    stringsAsFactors = FALSE
  ),
  
  # Ecosystem Services
  ecosystem_services = data.frame(
    id = c("ES_1", "ES_2", "ES_3", "ES_4"),
    name = c("Fish Provisioning", "Aesthetic Value", "Wave Attenuation", "Nutrient Cycling"),
    indicator = c("Fish stock biomass", "Scenic quality index", 
                 "Wave height reduction", "Nitrogen processing rate"),
    indicator_unit = c("tonnes", "index 0-100", "percentage", "kg/ha/year"),
    category = c("Provisioning", "Cultural", "Regulating", "Supporting"),
    data_source = c("Stock Assessment", "Visitor Surveys", 
                   "Hydrodynamic Models", "Nutrient Studies"),
    time_horizon_start = as.Date(c("2010-01-01", "2015-01-01", "2012-01-01", "2010-01-01")),
    time_horizon_end = as.Date(c("2023-12-31", "2023-12-31", "2023-12-31", "2023-12-31")),
    baseline_value = c(50000, 75, 40, 120),
    current_value = c(42000, 82, 55, 110),
    notes = c("Declining stocks", "Improving", "Enhanced by seagrass", "Stable"),
    stringsAsFactors = FALSE
  ),
  
  # Marine Processes & Functioning
  marine_processes = data.frame(
    id = c("MPF_1", "MPF_2", "MPF_3", "MPF_4"),
    name = c("Seagrass Meadow Health", "Water Quality", "Biodiversity", "Sediment Stability"),
    indicator = c("Seagrass coverage area", "Turbidity", 
                 "Shannon diversity index", "Erosion rate"),
    indicator_unit = c("hectares", "NTU", "index", "cm/year"),
    process_type = c("Habitat", "Water column", "Community", "Physical"),
    data_source = c("Remote Sensing", "Water Monitoring", 
                   "Biodiversity Surveys", "Sediment Studies"),
    time_horizon_start = as.Date(c("2010-01-01", "2010-01-01", "2012-01-01", "2010-01-01")),
    time_horizon_end = as.Date(c("2023-12-31", "2023-12-31", "2023-12-31", "2023-12-31")),
    baseline_value = c(500, 15, 2.8, 5),
    current_value = c(450, 12, 3.1, 3),
    notes = c("Declining coverage", "Improving", "Increasing", "Stabilizing"),
    stringsAsFactors = FALSE
  ),
  
  # Pressures
  pressures = data.frame(
    id = c("P_1", "P_2", "P_3", "P_4"),
    name = c("Physical Disturbance from Anchoring", "Nutrient Pollution", 
            "Climate Change", "Overfishing"),
    indicator = c("Number of boat moorings", "Nitrogen concentration", 
                 "Sea surface temperature", "Fishing effort"),
    indicator_unit = c("moorings/year", "mg/L", "°C", "vessel-days"),
    type = c("Endogenic Managed (EnMP)", "Endogenic Managed (EnMP)", 
            "Exogenic (ExP)", "Endogenic Managed (EnMP)"),
    spatial_scale = c("Local", "Regional", "International", "National"),
    relevant_policies = c("Marine Spatial Planning Act", 
                         "Water Framework Directive",
                         "Paris Agreement",
                         "Common Fisheries Policy"),
    data_source = c("Port Authority", "Water Agency", 
                   "Climate Models", "Fisheries Control"),
    time_horizon_start = as.Date(c("2010-01-01", "2010-01-01", "2010-01-01", "2010-01-01")),
    time_horizon_end = as.Date(c("2023-12-31", "2023-12-31", "2023-12-31", "2023-12-31")),
    baseline_value = c(500, 1.5, 17.5, 1000),
    current_value = c(800, 1.2, 18.2, 750),
    notes = c("Increasing pressure", "Decreasing", "Rising temperature", "Reduced effort"),
    stringsAsFactors = FALSE
  ),
  
  # Activities
  activities = data.frame(
    id = c("A_1", "A_2", "A_3", "A_4"),
    name = c("Recreational Boating", "Wastewater Treatment", 
            "Fossil Fuel Combustion", "Commercial Fishing"),
    indicator = c("Number of recreational boats", "Treatment capacity", 
                 "CO2 emissions", "Fishing fleet size"),
    indicator_unit = c("boats", "m³/day", "tonnes CO2/year", "number of vessels"),
    scale = c("Group/Sector", "Regional", "International", "Group/Sector"),
    relevant_policies = c("Marine Recreation Act", "Urban Wastewater Directive",
                         "Climate Agreements", "Fisheries Regulations"),
    implementation_quality = c("Medium", "Good", "Poor", "Good"),
    data_source = c("Marina Records", "Wastewater Authority", 
                   "Emissions Database", "Vessel Registry"),
    time_horizon_start = as.Date(c("2010-01-01", "2010-01-01", "2010-01-01", "2010-01-01")),
    time_horizon_end = as.Date(c("2023-12-31", "2023-12-31", "2023-12-31", "2023-12-31")),
    baseline_value = c(1000, 50000, 500000, 50),
    current_value = c(1500, 75000, 520000, 35),
    notes = c("Growing", "Expanded capacity", "Still rising", "Fleet reduction"),
    stringsAsFactors = FALSE
  ),
  
  # Drivers
  drivers = data.frame(
    id = c("D_1", "D_2", "D_3", "D_4"),
    name = c("Recreation Demand", "Clean Water Need", 
            "Energy Demand", "Food Security"),
    indicator = c("Population with access to coast", "Population served", 
                 "Energy consumption", "Fish demand"),
    indicator_unit = c("persons", "persons", "TWh/year", "tonnes/year"),
    needs_category = c("Leisure/Recreation", "Safety/Health", 
                      "Basic Needs", "Basic Needs"),
    trends = c("Increasing urbanization", "Growing population",
              "Rising consumption", "Population growth"),
    data_source = c("Census", "Water Authority", 
                   "Energy Statistics", "Food Statistics"),
    time_horizon_start = as.Date(c("2010-01-01", "2010-01-01", "2010-01-01", "2010-01-01")),
    time_horizon_end = as.Date(c("2023-12-31", "2023-12-31", "2023-12-31", "2023-12-31")),
    baseline_value = c(100000, 150000, 100, 12000),
    current_value = c(125000, 180000, 115, 14000),
    notes = c("Growing coastal population", "Expansion", "Rising demand", "Increasing"),
    stringsAsFactors = FALSE
  ),
  
  # Adjacency Matrices (simplified examples)
  adjacency_matrices = list(
    # Ecosystem Services -> Goods & Benefits
    gb_es = matrix(
      c("+strong", "", "",           # ES_1 -> GB_1, GB_2, GB_3
        "", "+medium", "",            # ES_2 -> GB_1, GB_2, GB_3
        "", "", "+strong",            # ES_3 -> GB_1, GB_2, GB_3
        "", "", ""),                  # ES_4 -> GB_1, GB_2, GB_3
      nrow = 4, ncol = 3, byrow = TRUE,
      dimnames = list(
        c("Fish Provisioning", "Aesthetic Value", "Wave Attenuation", "Nutrient Cycling"),
        c("Commercial Fish Catch", "Tourism Revenue", "Coastal Protection")
      )
    ),
    
    # Marine Processes -> Ecosystem Services
    es_mpf = matrix(
      c("+strong", "", "+medium", "",      # MPF_1 -> ES_1,2,3,4
        "", "", "", "+medium",              # MPF_2 -> ES_1,2,3,4
        "+medium", "+weak", "", "+strong",  # MPF_3 -> ES_1,2,3,4
        "", "", "+weak", ""),               # MPF_4 -> ES_1,2,3,4
      nrow = 4, ncol = 4, byrow = TRUE,
      dimnames = list(
        c("Seagrass Meadow Health", "Water Quality", "Biodiversity", "Sediment Stability"),
        c("Fish Provisioning", "Aesthetic Value", "Wave Attenuation", "Nutrient Cycling")
      )
    ),
    
    # Pressures -> Marine Processes
    mpf_p = matrix(
      c("-strong", "", "", "",          # P_1 -> MPF_1,2,3,4
        "", "-medium", "-weak", "",     # P_2 -> MPF_1,2,3,4
        "-weak", "-medium", "-weak", "-weak",  # P_3 -> MPF_1,2,3,4
        "-medium", "", "-strong", ""),  # P_4 -> MPF_1,2,3,4
      nrow = 4, ncol = 4, byrow = TRUE,
      dimnames = list(
        c("Physical Disturbance", "Nutrient Pollution", "Climate Change", "Overfishing"),
        c("Seagrass Meadow Health", "Water Quality", "Biodiversity", "Sediment Stability")
      )
    ),
    
    # Activities -> Pressures
    p_a = matrix(
      c("+strong", "", "", "",          # A_1 -> P_1,2,3,4
        "", "-strong", "", "",           # A_2 -> P_1,2,3,4
        "", "", "+strong", "",           # A_3 -> P_1,2,3,4
        "", "", "", "+strong"),          # A_4 -> P_1,2,3,4
      nrow = 4, ncol = 4, byrow = TRUE,
      dimnames = list(
        c("Recreational Boating", "Wastewater Treatment", "Fossil Fuel Combustion", "Commercial Fishing"),
        c("Physical Disturbance", "Nutrient Pollution", "Climate Change", "Overfishing")
      )
    ),
    
    # Drivers -> Activities
    a_d = matrix(
      c("+strong", "", "", "",          # D_1 -> A_1,2,3,4
        "", "+strong", "", "",           # D_2 -> A_1,2,3,4
        "", "", "+strong", "",           # D_3 -> A_1,2,3,4
        "", "", "", "+strong"),          # D_4 -> A_1,2,3,4
      nrow = 4, ncol = 4, byrow = TRUE,
      dimnames = list(
        c("Recreation Demand", "Clean Water Need", "Energy Demand", "Food Security"),
        c("Recreational Boating", "Wastewater Treatment", "Fossil Fuel Combustion", "Commercial Fishing")
      )
    ),
    
    # Goods & Benefits -> Drivers (closing the loop)
    d_gb = matrix(
      c("", "+weak", "",          # GB_1 -> D_1,2,3,4
        "+medium", "", "+weak",    # GB_2 -> D_1,2,3,4
        "", "", ""),               # GB_3 -> D_1,2,3,4
      nrow = 3, ncol = 4, byrow = TRUE,
      dimnames = list(
        c("Commercial Fish Catch", "Tourism Revenue", "Coastal Protection"),
        c("Recreation Demand", "Clean Water Need", "Energy Demand", "Food Security")
      )
    )
  )
)

# Make example data available
log_message("Example ISA data loaded")
