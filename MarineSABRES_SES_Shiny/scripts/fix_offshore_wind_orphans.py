#!/usr/bin/env python3
"""
Add connections for all orphan elements in the offshore wind KB.

Each orphan element gets at least one scientifically valid DAPSIWRM connection.
Valid transitions: D→A, A→P, P→S, S→I, I→W, W→D (feedback),
                   P→P, S→S (interactions), R→A, R→P, R→D, R→S (interventions)

Run: python scripts/fix_offshore_wind_orphans.py
"""

import json
from pathlib import Path

def make_conn(from_name, from_type, to_name, to_type, polarity, strength,
              confidence, rationale, references, temporal_lag="short-term",
              reversibility="partially_reversible"):
    return {
        "from": from_name,
        "from_type": from_type,
        "to": to_name,
        "to_type": to_type,
        "polarity": polarity,
        "strength": strength,
        "confidence": confidence,
        "rationale": rationale,
        "references": references,
        "temporal_lag": temporal_lag,
        "reversibility": reversibility
    }

# References commonly used across the NID4OCEAN KB
REFS_GENERAL = ["Abramic et al. 2022", "Baulaz et al. 2023"]
REFS_DECOM = ["Topham & McMillan 2017", "Smyth et al. 2015"]
REFS_REEF = ["Coates et al. 2014", "Degraer et al. 2020"]
REFS_NOISE = ["Madsen et al. 2006", "Bailey et al. 2014"]
REFS_FISH = ["Methratta & Dardick 2019", "Reubens et al. 2014"]
REFS_CLIMATE = ["IPCC 2023", "Hoegh-Guldberg et al. 2018"]
REFS_MSP = ["Ehler & Douvere 2009", "Zaucha & Gee 2019"]
REFS_BALTIC = ["HELCOM 2021", "Korpinen et al. 2012"]
REFS_MED = ["Coll et al. 2010", "Micheli et al. 2013"]
REFS_FLOAT = ["Bento & Fontes 2019", "Castro-Santos et al. 2022"]


def north_sea_connections():
    """17 orphan connections for north_sea_offshore_wind."""
    return [
        # 1. Chronic hydrocarbon contamination from platforms
        make_conn(
            "Oil and gas platform operation and decommissioning", "activities",
            "Chronic hydrocarbon contamination from platforms", "pressures",
            "+", "medium", 4,
            "Oil and gas operations release chronic low-level hydrocarbons through produced water discharge, minor spills, and legacy contamination around platforms",
            ["Bakke et al. 2013", "Cordes et al. 2016"],
            "long-term", "partially_reversible"
        ),
        # 2. Climate change and ocean warming
        make_conn(
            "Climate change and ocean warming", "drivers",
            "Commercial demersal trawl fisheries (sole, plaice, cod)", "activities",
            "+/-", "medium", 4,
            "Ocean warming shifts fish species distributions northward, altering fishing patterns and target species availability for North Sea demersal fleets",
            REFS_CLIMATE + ["Perry et al. 2005", "Pinsky et al. 2013"],
            "long-term", "irreversible"
        ),
        # 3. Coastal community economic diversification
        make_conn(
            "Employment in wind farm construction, operation and maintenance", "welfare",
            "Regional employment and industrial transition needs", "drivers",
            "-", "medium", 4,
            "As coastal communities diversify economically through wind farm employment, the urgency of industrial transition drivers decreases through feedback",
            ["Bidwell et al. 2022", "Dawley 2014"],
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "Cultural ecosystem services (seascape aesthetics, recreation)", "impacts",
            "Coastal community economic diversification", "welfare",
            "+", "medium", 3,
            "Recreation and tourism ecosystem services contribute to coastal economic diversification beyond traditional fishing and energy sectors",
            ["Jobstvogt et al. 2014", "Börger et al. 2014"],
            "medium-term", "partially_reversible"
        ),
        # 4. Coastal flood and wave energy regulation
        make_conn(
            "Seabed sediment characteristics and soft-bottom infauna", "states",
            "Coastal flood and wave energy regulation", "impacts",
            "+", "medium", 3,
            "Healthy seabed sediment systems and associated biogenic structures contribute to wave attenuation and coastal flood regulation",
            ["Spalding et al. 2014", "Möller et al. 2014"],
            "long-term", "partially_reversible"
        ),
        # 5. Decommissioning regulations and liability frameworks
        make_conn(
            "Decommissioning regulations and liability frameworks", "responses",
            "Wind farm decommissioning", "activities",
            "+", "strong", 5,
            "Regulatory requirements for decommissioning (OSPAR Decision 98/3, national regulations) mandate removal of foundations and cables at end of operational life",
            REFS_DECOM + ["OSPAR Commission 2006"],
            "long-term", "irreversible"
        ),
        # 6. Energy affordability and price stability
        make_conn(
            "Carbon emission avoidance through wind energy generation", "impacts",
            "Energy affordability and price stability", "welfare",
            "+", "medium", 4,
            "Wind energy displaces volatile fossil fuel pricing, contributing to energy price stability for consumers and industry",
            ["Hirth 2013", "Wiser et al. 2016"],
            "medium-term", "partially_reversible"
        ),
        # 7. Marine aggregate dredging
        make_conn(
            "Sand and gravel resource demand for construction", "drivers",
            "Marine aggregate (sand/gravel) dredging", "activities",
            "+", "strong", 5,
            "Construction demand for sand and gravel directly drives marine aggregate extraction from licensed dredging areas in the North Sea",
            ["Van Lancker et al. 2010", "ICES 2019"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Marine aggregate (sand/gravel) dredging", "activities",
            "Seabed disturbance and habitat alteration from foundations and scour protection", "pressures",
            "+", "strong", 5,
            "Aggregate dredging directly disturbs seabed habitats, removing surface sediment and altering benthic community structure",
            ["Desprez 2000", "Cooper et al. 2007"],
            "short-term", "partially_reversible"
        ),
        # 8. North Sea herring stock biomass
        make_conn(
            "Barrier effects on marine mammal and fish migration routes", "pressures",
            "North Sea herring stock biomass", "states",
            "-", "weak", 3,
            "Offshore wind farm arrays may create barrier effects for herring migration between spawning and feeding grounds, though evidence is still emerging",
            ["Slabbekoorn et al. 2010", "Gill & Bartlett 2010"],
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "North Sea herring stock biomass", "states",
            "Fish stock provisioning for human consumption and fisheries", "impacts",
            "+", "strong", 5,
            "North Sea herring is a major commercial fish stock; its biomass directly determines the provisioning service for human consumption",
            ["ICES 2023", "Dickey-Collas et al. 2010"],
            "short-term", "partially_reversible"
        ),
        # 9. Oil and gas platform operation
        make_conn(
            "Economic growth and blue economy development", "drivers",
            "Oil and gas platform operation and decommissioning", "activities",
            "+", "strong", 5,
            "Economic growth and energy demand drive continued oil and gas operations, while aging infrastructure drives decommissioning activity",
            ["Cordes et al. 2016", "Fowler et al. 2018"],
            "long-term", "irreversible"
        ),
        # 10. Property values and coastal aesthetics
        make_conn(
            "Cultural ecosystem services (seascape aesthetics, recreation)", "impacts",
            "Property values and coastal aesthetics perception", "welfare",
            "+", "medium", 4,
            "Coastal seascape aesthetics directly influence property values and community perception of coastal living quality",
            ["Gibbons 2015", "Hevia-Koch & Ladenburg 2019"],
            "medium-term", "partially_reversible"
        ),
        # 11. Recreational angling near wind farms
        make_conn(
            "Food security from North Sea fisheries", "drivers",
            "Recreational angling near wind farms", "activities",
            "+", "medium", 4,
            "Demand for fish and recreational fishing opportunities drives angling activity near wind farms where fish aggregate around structures",
            REFS_FISH + ["Hooper et al. 2017"],
            "short-term", "partially_reversible"
        ),
        # 12. Sand and gravel resource demand — already connected via #7 (Marine aggregate dredging)
        # Add second connection to construction activity
        make_conn(
            "Sand and gravel resource demand for construction", "drivers",
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "+", "weak", 3,
            "Wind farm construction requires seabed preparation and scour protection materials, contributing to aggregate resource demand",
            ["Van Lancker et al. 2010", "ICES 2019"],
            "medium-term", "partially_reversible"
        ),
        # 13. Seabed surveys and environmental monitoring
        make_conn(
            "Environmental Impact Assessment requirements", "responses",
            "Seabed surveys and environmental monitoring", "activities",
            "+", "strong", 5,
            "EIA regulations mandate pre- and post-construction environmental surveys including seabed characterisation, marine mammal monitoring, and bird surveys",
            ["BSH 2013", REFS_MSP[0]],
            "short-term", "partially_reversible"
        ),
        # 14. Shipping and trade route services
        make_conn(
            "Fish stock provisioning for human consumption and fisheries", "impacts",
            "Shipping and trade route services", "welfare",
            "+", "medium", 3,
            "Fishery products require shipping and trade infrastructure, and safe navigation routes through the North Sea underpin broader trade services",
            REFS_GENERAL,
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Shipping and trade route services", "welfare",
            "International shipping and trade growth", "drivers",
            "+", "strong", 5,
            "Revenue from shipping services reinforces demand for trade growth, creating a feedback loop between maritime trade welfare and economic drivers",
            REFS_GENERAL + ["Tournadre 2014"],
            "short-term", "partially_reversible"
        ),
        # 15. Stakeholder engagement and fisheries consultation
        make_conn(
            "Stakeholder engagement and fisheries consultation processes", "responses",
            "Exclusion of fishing vessels from wind farm safety zones", "pressures",
            "-", "medium", 4,
            "Effective stakeholder engagement and consultation can lead to fisheries co-existence agreements that reduce the displacement impact of safety zones",
            ["de Groot et al. 2014", "Breen et al. 2015"],
            "short-term", "partially_reversible"
        ),
        # 16. Turbine maintenance and vessel operations
        make_conn(
            "Renewable energy targets and climate policy (EU Green Deal, national NDCs)", "drivers",
            "Turbine maintenance and vessel operations", "activities",
            "+", "strong", 5,
            "Operational wind farms require ongoing turbine maintenance and crew transfer vessel operations throughout their 25-30 year lifespan",
            REFS_GENERAL + ["Carroll et al. 2016"],
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "Turbine maintenance and vessel operations", "activities",
            "Competition for marine space between wind, shipping and fishing", "pressures",
            "+", "medium", 3,
            "Maintenance vessel traffic adds to marine spatial competition around wind farm sites, affecting other sea users",
            REFS_MSP,
            "short-term", "partially_reversible"
        ),
        # 17. Wind farm decommissioning (already linked from #5 Decommissioning regs)
        # Add activity→pressure link
        make_conn(
            "Wind farm decommissioning", "activities",
            "Seabed disturbance and habitat alteration from foundations and scour protection", "pressures",
            "+", "strong", 4,
            "Decommissioning involves removal of foundations and scour protection, causing temporary but significant seabed disturbance and resuspension of sediments",
            REFS_DECOM,
            "short-term", "partially_reversible"
        ),
    ]


def atlantic_connections():
    """17 orphan connections for atlantic_floating_wind."""
    return [
        # 1. Biofouling communities on floating structures
        make_conn(
            "Anchor and mooring seabed disturbance", "pressures",
            "Biofouling communities on floating structures and mooring lines", "states",
            "+", "medium", 3,
            "Floating structures and mooring lines provide novel hard substrate in the pelagic zone, rapidly colonised by biofouling organisms including mussels, barnacles, and hydroids",
            ["Langhamer 2012", "De Mesel et al. 2015"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Biofouling communities on floating structures and mooring lines", "states",
            "Stepping-stone habitat for non-native biofouling species", "impacts",
            "+", "medium", 3,
            "Biofouling communities on floating structures can serve as stepping stones for non-native species dispersal across previously unconnected deep-water habitats",
            ["Adams et al. 2014", "Mineur et al. 2012"],
            "long-term", "partially_reversible"
        ),
        # 2. Cetacean watching and marine ecotourism
        make_conn(
            "Coastal economic regeneration and just transition needs", "drivers",
            "Cetacean watching and marine ecotourism", "activities",
            "+", "medium", 4,
            "Demand for coastal economic diversification drives cetacean watching and marine ecotourism as alternative livelihood activities",
            ["Hoyt 2001", "O'Connor et al. 2009"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Cetacean watching and marine ecotourism", "activities",
            "Displacement of pelagic fishing effort from wind farm zones", "pressures",
            "+", "weak", 2,
            "Increased marine ecotourism vessel traffic contributes to spatial competition with fishing activities in the same offshore areas",
            ["Parsons 2012"],
            "short-term", "partially_reversible"
        ),
        # 3. Climate change mitigation obligations (Paris Agreement)
        make_conn(
            "Climate change mitigation obligations (Paris Agreement)", "drivers",
            "Floating offshore wind farm deployment and operation", "activities",
            "+", "strong", 5,
            "International climate commitments under the Paris Agreement are a primary driver of floating wind deployment to access deep-water wind resources",
            ["IRENA 2019", "IEA 2019"],
            "medium-term", "irreversible"
        ),
        # 4. Deep-sea benthic communities at anchor points
        make_conn(
            "Anchor and mooring seabed disturbance", "pressures",
            "Deep-sea benthic communities at anchor points", "states",
            "-", "medium", 3,
            "Anchor installation and chain sweep zones physically disturb deep-sea benthic communities, which are slow to recover due to low temperatures and limited larval supply",
            ["Ramirez-Llodra et al. 2011", "Clark et al. 2016"],
            "long-term", "slowly_reversible"
        ),
        # 5. Deep-water wind resource exploitation
        make_conn(
            "Deep-water wind resource exploitation beyond fixed-bottom limits", "drivers",
            "Floating offshore wind farm deployment and operation", "activities",
            "+", "strong", 5,
            "The availability of high-quality deep-water wind resources (>60m depth) that cannot be accessed by fixed-bottom foundations drives floating wind technology development and deployment",
            REFS_FLOAT + ["IRENA 2019"],
            "medium-term", "irreversible"
        ),
        # 6. Dynamic cable installation and maintenance
        make_conn(
            "National renewable energy and net-zero targets", "drivers",
            "Dynamic cable installation and maintenance", "activities",
            "+", "strong", 5,
            "Grid connection of floating wind farms requires dynamic cable systems, driven by national energy targets and the need to export generated electricity",
            REFS_FLOAT,
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "Dynamic cable installation and maintenance", "activities",
            "Anchor and mooring seabed disturbance", "pressures",
            "+", "medium", 3,
            "Dynamic cable installation involves seabed interaction at cable touchdown points and may require additional anchor points, causing localised disturbance",
            REFS_FLOAT,
            "short-term", "partially_reversible"
        ),
        # 7. Energy price stability for consumers
        make_conn(
            "Carbon emission reduction from floating wind generation", "impacts",
            "Energy price stability for consumers", "welfare",
            "+", "medium", 4,
            "Floating wind energy displaces volatile fossil fuel imports, contributing to long-term energy price stability through fixed-price power purchase agreements",
            ["Hirth 2013", "IRENA 2019"],
            "medium-term", "partially_reversible"
        ),
        # 8. Energy security through domestic generation
        make_conn(
            "Energy security through domestic generation", "drivers",
            "Floating offshore wind farm deployment and operation", "activities",
            "+", "strong", 5,
            "National energy security concerns drive floating wind deployment to reduce dependence on imported fossil fuels and diversify the domestic energy mix",
            ["IRENA 2019", "IEA 2019"],
            "medium-term", "irreversible"
        ),
        # 9. Environmental baseline and monitoring surveys
        make_conn(
            "Adaptive management and monitoring protocols", "responses",
            "Environmental baseline and monitoring surveys", "activities",
            "+", "strong", 5,
            "Adaptive management frameworks mandate environmental baseline surveys and ongoing monitoring to assess floating wind farm impacts on marine ecosystems",
            REFS_MSP + ["Lindeboom et al. 2011"],
            "short-term", "partially_reversible"
        ),
        # 10. International cooperation on transboundary effects
        make_conn(
            "International cooperation on transboundary environmental effects", "responses",
            "Floating offshore wind farm deployment and operation", "activities",
            "+/-", "medium", 3,
            "International cooperation frameworks (OSPAR, EU MSP Directive) both enable and constrain floating wind deployment through coordinated environmental assessment requirements",
            ["OSPAR Commission 2006", REFS_MSP[0]],
            "medium-term", "partially_reversible"
        ),
        # 11. Just transition and community benefit funds
        make_conn(
            "Just transition and community benefit funds", "responses",
            "Coastal economic regeneration and just transition needs", "drivers",
            "-", "medium", 4,
            "Community benefit funds and just transition policies address the socioeconomic driver of coastal regeneration by providing direct financial support to affected communities",
            ["Heffron & McCauley 2018", "Sovacool et al. 2019"],
            "medium-term", "partially_reversible"
        ),
        # 12. Operational noise from floating platform motion
        make_conn(
            "Floating offshore wind farm deployment and operation", "activities",
            "Operational noise from floating platform motion and mooring", "pressures",
            "+", "medium", 3,
            "Floating platforms generate operational noise from wave-induced motion, mooring line tension changes, and mechanical vibration transmitted through the water column",
            REFS_FLOAT + REFS_NOISE,
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Operational noise from floating platform motion and mooring", "pressures",
            "Cetacean populations (dolphins, fin whales, sperm whales)", "states",
            "-", "weak", 3,
            "Chronic low-frequency noise from floating platform operation may cause behavioural disturbance and displacement in cetaceans, particularly deep-diving species sensitive to acoustic habitat degradation",
            REFS_NOISE + ["Erbe et al. 2019"],
            "long-term", "partially_reversible"
        ),
        # 13. Pelagic fish aggregation (FAD effect)
        make_conn(
            "Pelagic fish stocks (mackerel, horse mackerel, tuna)", "states",
            "Pelagic fish aggregation around floating structures (FAD effect)", "impacts",
            "+", "medium", 3,
            "Floating structures act as fish aggregation devices (FADs), concentrating pelagic species around the submerged mooring and platform structures",
            ["Dempster & Taquet 2004", "Methratta & Dardick 2019"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Pelagic fish aggregation around floating structures (FAD effect)", "impacts",
            "Deep-water fishers' livelihood security", "welfare",
            "+", "medium", 3,
            "Fish aggregation around floating wind structures may enhance local catch rates for fishers, potentially benefiting livelihood security if co-existence access is granted",
            REFS_FISH + ["Hooper et al. 2017"],
            "short-term", "partially_reversible"
        ),
        # 14. Regional supply chain development
        make_conn(
            "Pelagic fishery provisioning from deep waters", "impacts",
            "Regional supply chain development and economic diversification", "welfare",
            "+", "medium", 3,
            "Pelagic fisheries provisioning and wind farm supply chain development together contribute to regional economic diversification in coastal port communities",
            ["Bidwell et al. 2022"],
            "medium-term", "partially_reversible"
        ),
        # 15. Social acceptance in coastal communities
        make_conn(
            "Carbon emission reduction from floating wind generation", "impacts",
            "Social acceptance in coastal communities", "welfare",
            "+", "medium", 4,
            "Demonstrated climate benefits from floating wind contribute to public acceptance, though visual impact and fisheries displacement may reduce it",
            ["Firestone et al. 2012", "Hevia-Koch & Ladenburg 2019"],
            "medium-term", "partially_reversible"
        ),
        # 16. Stepping-stone habitat (already connected from biofouling #1)
        # Add impact→welfare link
        make_conn(
            "Stepping-stone habitat for non-native biofouling species", "impacts",
            "Clean energy from deep-water wind resources", "welfare",
            "-", "weak", 2,
            "Invasive species introduction through stepping-stone habitats may trigger regulatory delays and additional environmental mitigation costs, indirectly affecting the clean energy value proposition",
            ["Adams et al. 2014"],
            "long-term", "partially_reversible"
        ),
        # 17. Visual impact from floating structures
        make_conn(
            "Floating offshore wind farm deployment and operation", "activities",
            "Visual impact from floating structures", "pressures",
            "+", "medium", 4,
            "Floating wind structures are visible from shore at distances up to 30-40 km, particularly in clear Atlantic conditions, creating visual impact on coastal seascapes",
            ["Bishop 2002", "Hevia-Koch & Ladenburg 2019"],
            "long-term", "partially_reversible"
        ),
        make_conn(
            "Visual impact from floating structures", "pressures",
            "Seabird foraging ecology (shearwaters, petrels, storm-petrels)", "states",
            "-", "weak", 2,
            "Visible structures may cause seabird displacement from foraging areas through avoidance behaviour, particularly for collision-sensitive species like shearwaters",
            ["Furness et al. 2013", "Dierschke et al. 2016"],
            "long-term", "partially_reversible"
        ),
    ]


def baltic_connections():
    """20 orphan connections for baltic_offshore_wind."""
    return [
        # 1. Benthic macrofauna in deep basins
        make_conn(
            "Seabed disturbance and habitat alteration from foundations", "pressures",
            "Benthic macrofauna in deep basins", "states",
            "-", "medium", 3,
            "Foundation installation in deep basins disturbs benthic macrofauna communities already stressed by periodic hypoxia in the Baltic Proper",
            REFS_BALTIC + ["Villnäs & Norkko 2011"],
            "medium-term", "slowly_reversible"
        ),
        # 2. Climate change mitigation goals (HELCOM, EU)
        make_conn(
            "Climate change mitigation goals (HELCOM, EU)", "drivers",
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "+", "strong", 5,
            "EU and HELCOM climate targets directly drive Baltic offshore wind development, with ambitious national deployment targets for 2030 and beyond",
            REFS_BALTIC + ["EU Commission 2020"],
            "medium-term", "irreversible"
        ),
        # 3. Climate regulation through carbon cycling
        make_conn(
            "Deep-water hypoxia extent (dead zones)", "states",
            "Climate regulation through carbon cycling", "impacts",
            "-", "medium", 3,
            "Expanding hypoxic dead zones in Baltic deep basins impair carbon sequestration and nutrient cycling, reducing the climate regulation ecosystem service",
            REFS_BALTIC + ["Carstensen et al. 2014"],
            "long-term", "slowly_reversible"
        ),
        # 4. Coastal community economic diversification
        make_conn(
            "Carbon emission avoidance through Baltic wind energy", "impacts",
            "Coastal community economic diversification", "welfare",
            "+", "medium", 4,
            "Wind farm development brings new economic opportunities to Baltic coastal communities through construction, operation, maintenance, and port services",
            ["Bidwell et al. 2022", "Dawley 2014"],
            "medium-term", "partially_reversible"
        ),
        # 5. Contamination from dumped munitions legacy
        make_conn(
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "Contamination from dumped munitions legacy", "pressures",
            "+", "medium", 4,
            "Wind farm construction in the Baltic may disturb dumped WWII munitions, releasing toxic compounds (TNT, mustard gas) into the marine environment during seabed preparation",
            REFS_BALTIC + ["Beldowski et al. 2016"],
            "short-term", "irreversible"
        ),
        make_conn(
            "Contamination from dumped munitions legacy", "pressures",
            "Seabed sediment and soft-bottom infauna", "states",
            "-", "medium", 3,
            "Toxic compounds leaking from corroding munitions contaminate sediments and accumulate in benthic organisms, degrading soft-bottom community health",
            ["Beldowski et al. 2016", "Maser & Strehse 2020"],
            "long-term", "irreversible"
        ),
        # 6. De facto marine refuge
        make_conn(
            "Exclusion of fishing vessels from wind farm safety zones", "pressures",
            "De facto marine refuge in wind farm exclusion zones", "states",
            "+", "strong", 4,
            "Fishing exclusion zones around Baltic wind farms create de facto marine refuges where fish stocks and benthic communities can recover from trawling pressure",
            REFS_FISH + ["Stelzenmüller et al. 2011"],
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "De facto marine refuge in wind farm exclusion zones", "states",
            "Commercial fish stock provision (cod, herring, sprat)", "impacts",
            "+", "medium", 3,
            "Marine refuges in wind farm exclusion zones may enhance fish stock recovery through spillover effects, benefiting adjacent fisheries",
            ["Stelzenmüller et al. 2011", REFS_FISH[0]],
            "long-term", "partially_reversible"
        ),
        # 7. Electromagnetic fields from submarine cables
        make_conn(
            "Submarine cable laying and grid interconnection", "activities",
            "Electromagnetic fields from submarine cables", "pressures",
            "+", "medium", 4,
            "AC and DC submarine power cables emit electromagnetic fields that can be detected by electrosensitive species such as elasmobranchs and flatfish",
            ["Gill et al. 2012", "Normandeau et al. 2011"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Electromagnetic fields from submarine cables", "pressures",
            "Eastern Baltic cod stock biomass", "states",
            "-", "weak", 2,
            "EMF from submarine cables may affect orientation and migration behaviour of Baltic cod, though field strength decreases rapidly with distance and population-level effects are uncertain",
            ["Gill et al. 2012", "Öhman et al. 2007"],
            "long-term", "partially_reversible"
        ),
        # 8. EIA with cumulative effects
        make_conn(
            "Environmental Impact Assessment with cumulative effects", "responses",
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "+/-", "strong", 5,
            "Cumulative effects EIA can both delay wind farm projects (through additional assessment requirements) and enable them (through consenting frameworks that address stakeholder concerns)",
            REFS_MSP + REFS_BALTIC,
            "medium-term", "partially_reversible"
        ),
        # 9. Environmental monitoring and baseline surveys
        make_conn(
            "Environmental Impact Assessment with cumulative effects", "responses",
            "Environmental monitoring and baseline surveys", "activities",
            "+", "strong", 5,
            "EIA regulations mandate comprehensive pre-construction environmental baseline surveys and post-construction monitoring programmes in the Baltic",
            REFS_BALTIC + REFS_MSP,
            "short-term", "partially_reversible"
        ),
        # 10. Fish processing industry employment
        make_conn(
            "Commercial fish stock provision (cod, herring, sprat)", "impacts",
            "Fish processing industry employment", "welfare",
            "+", "strong", 5,
            "Fish landings from Baltic fisheries directly sustain employment in onshore fish processing facilities across Baltic coastal communities",
            REFS_BALTIC + ["EU STECF 2021"],
            "short-term", "partially_reversible"
        ),
        # 11. HELCOM Baltic Sea Action Plan
        make_conn(
            "HELCOM Baltic Sea Action Plan", "responses",
            "Overfishing of Eastern Baltic cod", "pressures",
            "-", "medium", 4,
            "HELCOM BSAP sets targets for sustainable fisheries and ecosystem health that support measures to reduce overfishing of Baltic cod stocks",
            REFS_BALTIC,
            "medium-term", "partially_reversible"
        ),
        # 12. Halocline dynamics and deep-water renewal
        make_conn(
            "Seabed disturbance and habitat alteration from foundations", "pressures",
            "Halocline dynamics and deep-water renewal", "states",
            "-", "weak", 2,
            "Large-scale foundation arrays may locally alter bottom currents and mixing patterns near the halocline, though the effect relative to natural variability is uncertain",
            REFS_BALTIC + ["Meier et al. 2006"],
            "long-term", "partially_reversible"
        ),
        make_conn(
            "Halocline dynamics and deep-water renewal", "states",
            "Deep-water hypoxia extent (dead zones)", "states",
            "+", "strong", 5,
            "Halocline stability controls deep-water renewal in the Baltic Proper; persistent stratification prevents oxygenation of bottom waters, expanding hypoxic dead zones",
            ["Carstensen et al. 2014", "Meier et al. 2006"],
            "long-term", "irreversible"
        ),
        # 13. Maritime trade revenue
        make_conn(
            "Commercial fish stock provision (cod, herring, sprat)", "impacts",
            "Maritime trade revenue", "welfare",
            "+", "medium", 3,
            "Baltic fish exports and maritime shipping services generate trade revenue for Baltic coastal states",
            REFS_BALTIC,
            "short-term", "partially_reversible"
        ),
        # 14. Regional employment in coastal communities
        make_conn(
            "Regional employment in coastal communities", "drivers",
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "+", "medium", 4,
            "Demand for local employment and economic development in Baltic coastal communities drives support for offshore wind farm development",
            ["Bidwell et al. 2022", REFS_BALTIC[0]],
            "medium-term", "partially_reversible"
        ),
        # 15. Renewable electricity generation capacity
        make_conn(
            "Carbon emission avoidance through Baltic wind energy", "impacts",
            "Renewable electricity generation capacity", "welfare",
            "+", "strong", 5,
            "Each new Baltic wind farm directly increases installed renewable electricity generation capacity, displacing fossil fuel power",
            ["IRENA 2019", REFS_BALTIC[0]],
            "short-term", "partially_reversible"
        ),
        # 16. Sand and aggregate resource needs
        make_conn(
            "Sand and aggregate resource needs", "drivers",
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "+", "weak", 3,
            "Wind farm foundations require seabed preparation and scour protection materials, contributing indirectly to aggregate demand in the Baltic",
            ["Van Lancker et al. 2010"],
            "medium-term", "partially_reversible"
        ),
        # 17. Sediment plume and turbidity during construction
        make_conn(
            "Fixed-bottom offshore wind farm construction and operation", "activities",
            "Sediment plume and turbidity during construction", "pressures",
            "+", "strong", 5,
            "Pile driving and foundation installation resuspend fine sediments, creating turbidity plumes that can reduce light availability for primary producers and affect filter-feeding organisms",
            ["Baeye & Fettweis 2015", "Wilber & Clarke 2001"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Sediment plume and turbidity during construction", "pressures",
            "Central Baltic herring recruitment", "states",
            "-", "weak", 3,
            "Construction-phase turbidity plumes may temporarily affect herring larvae survival in shallow spawning areas through reduced feeding efficiency",
            ["Westerberg et al. 1996", REFS_BALTIC[0]],
            "short-term", "partially_reversible"
        ),
        # 18. Submarine cable and pipeline installation
        make_conn(
            "EU and national renewable energy targets for Baltic states", "drivers",
            "Submarine cable and pipeline installation", "activities",
            "+", "strong", 5,
            "Cross-border grid interconnection and wind farm export cables are driven by EU energy targets and Baltic energy market integration goals",
            REFS_BALTIC + ["EU Commission 2020"],
            "medium-term", "partially_reversible"
        ),
        # 19. Submarine cable laying and grid interconnection
        make_conn(
            "Submarine cable laying and grid interconnection", "activities",
            "Electromagnetic fields from submarine cables", "pressures",
            "+", "medium", 4,
            "Grid interconnection cables and wind farm export cables are major sources of EMF in the Baltic marine environment",
            ["Gill et al. 2012", "Normandeau et al. 2011"],
            "short-term", "partially_reversible"
        ),
        # 20. Turbine maintenance and service vessel operations
        make_conn(
            "EU and national renewable energy targets for Baltic states", "drivers",
            "Turbine maintenance and service vessel operations", "activities",
            "+", "strong", 5,
            "Ongoing turbine maintenance is required throughout the operational life of Baltic wind farms, generating continuous vessel traffic and maritime activity",
            REFS_GENERAL + ["Carroll et al. 2016"],
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "Turbine maintenance and service vessel operations", "activities",
            "Competition for marine space with shipping lanes", "pressures",
            "+", "medium", 3,
            "Service vessel operations add to marine traffic density in already congested Baltic shipping routes, increasing spatial competition",
            REFS_MSP + REFS_BALTIC,
            "short-term", "partially_reversible"
        ),
    ]


def mediterranean_connections():
    """13 orphan connections for mediterranean_floating_wind."""
    return [
        # 1. Biofouling communities on floating structures
        make_conn(
            "Mooring and anchor disturbance to deep-sea habitats", "pressures",
            "Biofouling communities on floating structures", "states",
            "+", "medium", 3,
            "Floating structures provide novel hard substrate for Mediterranean biofouling communities including invasive species that thrive in warm waters",
            ["Langhamer 2012", "Ferrario et al. 2017"],
            "short-term", "partially_reversible"
        ),
        # 2. Climate change mitigation under Paris Agreement
        make_conn(
            "Climate change mitigation under Paris Agreement", "drivers",
            "Floating offshore wind farm deployment and operation", "activities",
            "+", "strong", 5,
            "Mediterranean countries' Paris Agreement commitments and EU REPowerEU targets drive floating wind deployment to access deep-water resources close to demand centres",
            ["IRENA 2019", "EU Commission 2022"],
            "medium-term", "irreversible"
        ),
        # 3. Coastal property values and aesthetic perception
        make_conn(
            "Tourism and recreation seascape value", "impacts",
            "Coastal property values and aesthetic perception", "welfare",
            "+", "medium", 4,
            "Mediterranean coastal seascape aesthetics directly influence property values and tourism attractiveness, with wind farm visibility potentially reducing perceived value",
            ["Hevia-Koch & Ladenburg 2019", "Gibbons 2015"],
            "medium-term", "partially_reversible"
        ),
        # 4. Coastal water quality and bathing water standards
        make_conn(
            "Anchor damage to Posidonia oceanica meadows from cable routes", "pressures",
            "Coastal water quality and bathing water standards", "states",
            "-", "medium", 3,
            "Degradation of Posidonia meadows reduces their capacity for water filtration and sediment stabilisation, potentially affecting coastal bathing water quality",
            ["Boudouresque et al. 2012", REFS_MED[1]],
            "medium-term", "slowly_reversible"
        ),
        make_conn(
            "Coastal water quality and bathing water standards", "states",
            "Tourism and recreation seascape value", "impacts",
            "+", "strong", 5,
            "Clean coastal water quality is essential for Mediterranean beach tourism and directly determines bathing water classification under the EU Bathing Water Directive",
            ["Aragonés et al. 2016", REFS_MED[1]],
            "short-term", "partially_reversible"
        ),
        # 5. De facto marine refuge from fishing exclusion zones
        make_conn(
            "Displacement of artisanal fishers from wind farm zones", "pressures",
            "De facto marine refuge from fishing exclusion zones", "states",
            "+", "strong", 4,
            "Fishing exclusion in Mediterranean wind farm zones creates de facto marine refuges that allow overexploited demersal and reef fish populations to recover",
            ["Stelzenmüller et al. 2011", REFS_MED[0]],
            "medium-term", "partially_reversible"
        ),
        make_conn(
            "De facto marine refuge from fishing exclusion zones", "states",
            "Artisanal fishery provisioning from coastal waters", "impacts",
            "+", "medium", 3,
            "Marine refuge zones can produce spillover effects that benefit adjacent artisanal fisheries through increased fish abundance and biomass",
            ["Harmelin-Vivien et al. 2008", "Goñi et al. 2008"],
            "long-term", "partially_reversible"
        ),
        # 6. Deep-water wind resource potential
        make_conn(
            "Deep-water wind resource potential close to Mediterranean coasts", "drivers",
            "Floating offshore wind farm deployment and operation", "activities",
            "+", "strong", 5,
            "Mediterranean bathymetry drops steeply to >100m close to shore, making floating platforms the only viable technology to exploit excellent wind resources",
            REFS_FLOAT + ["IRENA 2019"],
            "medium-term", "irreversible"
        ),
        # 7. Environmental monitoring and baseline surveys
        make_conn(
            "Environmental Impact Assessment with Posidonia protection", "responses",
            "Environmental monitoring and baseline surveys", "activities",
            "+", "strong", 5,
            "Mediterranean EIA frameworks require comprehensive environmental baseline surveys including Posidonia mapping, cetacean monitoring, and seabird census before consenting",
            [REFS_MSP[0], REFS_MED[1]],
            "short-term", "partially_reversible"
        ),
        # 8. Loggerhead sea turtle (Caretta caretta) population
        make_conn(
            "Entanglement risk from mooring lines for cetaceans and turtles", "pressures",
            "Loggerhead sea turtle (Caretta caretta) population", "states",
            "-", "medium", 3,
            "Loggerhead sea turtles are vulnerable to entanglement in mooring lines and dynamic cables, particularly during migration through Mediterranean floating wind zones",
            ["Casale & Tucker 2017", "Nelms et al. 2016"],
            "long-term", "partially_reversible"
        ),
        # 9. Pelagic fish aggregation (FAD effect)
        make_conn(
            "Pelagic fish stocks (bluefin tuna, swordfish, anchovy)", "states",
            "Pelagic fish aggregation around floating structures (FAD effect)", "impacts",
            "+", "medium", 3,
            "Floating wind structures function as fish aggregation devices in the Mediterranean, attracting pelagic species including juvenile bluefin tuna and anchovy",
            ["Dempster & Taquet 2004", "Rountree 1990"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Pelagic fish aggregation around floating structures (FAD effect)", "impacts",
            "Artisanal fisher household income and livelihood security", "welfare",
            "+", "medium", 3,
            "Fish aggregation near floating structures may enhance catch rates for artisanal fishers if co-existence access agreements allow fishing in adjacent zones",
            REFS_FISH + ["Hooper et al. 2017"],
            "short-term", "partially_reversible"
        ),
        # 10. Pelagic fish stocks
        make_conn(
            "Overfishing pressure on demersal and reef fish", "pressures",
            "Pelagic fish stocks (bluefin tuna, swordfish, anchovy)", "states",
            "-", "medium", 4,
            "Overfishing of pelagic species (particularly bluefin tuna) combined with bycatch of juvenile pelagic fish in demersal fisheries reduces stock biomass",
            [REFS_MED[0], "ICCAT 2020"],
            "medium-term", "partially_reversible"
        ),
        # 11. Pelagic longline fishing for tuna and swordfish
        make_conn(
            "Artisanal fishing tradition and livelihood needs", "drivers",
            "Pelagic longline fishing for tuna and swordfish", "activities",
            "+", "strong", 5,
            "Mediterranean pelagic longline fishing for tuna and swordfish is driven by traditional livelihood needs and high market value of target species",
            [REFS_MED[0], "Tudela 2004"],
            "short-term", "partially_reversible"
        ),
        make_conn(
            "Pelagic longline fishing for tuna and swordfish", "activities",
            "Entanglement risk from mooring lines for cetaceans and turtles", "pressures",
            "+", "weak", 2,
            "Displaced longline fisheries operating near wind farm boundaries may increase interactions between fishing gear, mooring lines, cetaceans and turtles",
            ["Casale 2011", "Lewison et al. 2004"],
            "medium-term", "partially_reversible"
        ),
        # 12. Social acceptance and public perception
        make_conn(
            "Carbon emission reduction from Mediterranean floating wind", "impacts",
            "Social acceptance and public perception of offshore wind", "welfare",
            "+", "medium", 4,
            "Climate benefits of floating wind contribute to social acceptance, though visual impact, noise, and fisheries displacement can reduce public support",
            ["Firestone et al. 2012", "Hevia-Koch & Ladenburg 2019"],
            "medium-term", "partially_reversible"
        ),
        # 13. Stakeholder engagement with fishing and tourism sectors
        make_conn(
            "Stakeholder engagement with fishing and tourism sectors", "responses",
            "Displacement of artisanal fishers from wind farm zones", "pressures",
            "-", "medium", 4,
            "Effective stakeholder engagement with fishing and tourism sectors can mitigate displacement impacts through co-existence frameworks, compensation, and adaptive zoning",
            ["de Groot et al. 2014", REFS_MSP[0]],
            "short-term", "partially_reversible"
        ),
    ]


if __name__ == "__main__":
    kb_path = Path("data/ses_knowledge_db_offshore_wind.json")
    kb = json.loads(kb_path.read_text(encoding="utf-8"))

    new_connections = {
        "north_sea_offshore_wind": north_sea_connections(),
        "atlantic_floating_wind": atlantic_connections(),
        "baltic_offshore_wind": baltic_connections(),
        "mediterranean_floating_wind": mediterranean_connections(),
    }

    for ctx_name, conns in new_connections.items():
        ctx = kb["contexts"][ctx_name]
        existing = ctx.get("connections", [])
        ctx["connections"] = existing + conns
        print(f"{ctx_name}: added {len(conns)} connections (total: {len(ctx['connections'])})")

    # Validate: check for remaining orphans
    CATS = ['drivers', 'activities', 'pressures', 'states', 'impacts', 'welfare', 'responses']
    total_orphans = 0
    for ctx_name, ctx in kb['contexts'].items():
        all_elements = set()
        for cat in CATS:
            for elem in ctx.get(cat, []):
                all_elements.add(elem['name'])
        connected = set()
        for c in ctx.get('connections', []):
            connected.add(c['from'])
            connected.add(c['to'])
        orphans = all_elements - connected
        if orphans:
            print(f"\n  WARNING: {ctx_name} still has {len(orphans)} orphan(s): {sorted(orphans)}")
            total_orphans += len(orphans)

    if total_orphans == 0:
        print("\n✓ All elements have at least one connection — zero orphans!")

    # Validate transitions
    VALID_TRANSITIONS = {
        'drivers->activities', 'activities->pressures', 'pressures->states',
        'states->impacts', 'impacts->welfare', 'welfare->drivers',
        'pressures->pressures', 'states->states',
        'responses->activities', 'responses->pressures', 'responses->drivers',
        'responses->states',
    }
    print("\nTransition validation:")
    for ctx_name, ctx in kb['contexts'].items():
        invalid = []
        for c in ctx.get('connections', []):
            t = f"{c['from_type']}->{c['to_type']}"
            if t not in VALID_TRANSITIONS:
                invalid.append(f"{t} ({c['from']} → {c['to']})")
        if invalid:
            print(f"  {ctx_name}: {len(invalid)} INVALID: {invalid}")
        else:
            print(f"  {ctx_name}: All {len(ctx['connections'])} valid ✓")

    kb_path.write_text(json.dumps(kb, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nKB saved to {kb_path}")
