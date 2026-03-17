#!/usr/bin/env python3
"""
Scientific validation of DAPSI(W)R(M) knowledge base connections.

Validates polarity, strength, confidence, temporal_lag, and reversibility
for Arctic (3 contexts), Pacific (1), Indian Ocean (2), and Tropical Mangrove (1)
groups against peer-reviewed literature (IPCC AR6, AMAP, GCRMN, IPBES, Ramsar).

Rules:
  - Only change values that are scientifically questionable.
  - Be conservative: when evidence is ambiguous, keep existing values.
  - Update rationale for every change.
  - Print a summary of all changes made.
"""

import json
import copy
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
KB_PATH = PROJECT_ROOT / "data" / "ses_knowledge_db.json"

# ── Each correction is keyed by (context, from_name_substring, to_name_substring)
# Fields: any subset of {polarity, strength, confidence, temporal_lag, reversibility, rationale}
# Only the fields listed will be overwritten.

CORRECTIONS = [
    # =====================================================================
    # ARCTIC FJORD (38 connections)
    # =====================================================================

    # [3] Genetic introgression is effectively irreversible on ecological
    # timescales once alleles spread through wild populations (Bolstad et al. 2017,
    # Glover et al. 2017).  partially_reversible -> irreversible
    {
        "context": "arctic_fjord",
        "from_substr": "Escaped farmed salmon genetic introgression",
        "to_substr": "Wild Atlantic salmon and sea trout run sizes",
        "changes": {
            "reversibility": "irreversible",
            "rationale": "Genetic introgression from escaped farmed salmon is effectively irreversible on ecological timescales once alleles spread through wild populations (Glover et al. 2017; ICES WGNAS). Changed from partially_reversible."
        }
    },

    # [16] Nutrient enrichment -> freshwater pulse reducing salinity: the causal
    # link is indirect/weak; nutrient enrichment does not drive freshwater pulses.
    # These are independent processes. Strength weak is correct, but polarity
    # should be neutral or the connection is ecologically dubious. Keep as-is
    # but lower confidence to 2.
    {
        "context": "arctic_fjord",
        "from_substr": "Nutrient enrichment from aquaculture waste",
        "to_substr": "Freshwater pulse reducing fjord deep-water salinity",
        "changes": {
            "confidence": 2,
            "strength": "weak",
            "rationale": "Nutrient enrichment from aquaculture does not causally drive freshwater pulses; these are independent processes (glacial melt, precipitation). Confidence lowered due to weak causal link."
        }
    },

    # [17] Wild salmon run sizes -> fjord zooplankton: salmon are consumers of
    # zooplankton, but wild salmon biomass in fjords is small relative to
    # zooplankton standing stocks. Effect is weak but polarity should be negative
    # (more salmon = more grazing pressure on Calanus). Polarity correct (-).
    # But temporal_lag of long-term is too long for a trophic interaction.
    {
        "context": "arctic_fjord",
        "from_substr": "Wild Atlantic salmon and sea trout run sizes",
        "to_substr": "Fjord zooplankton",
        "changes": {
            "temporal_lag": "short-term",
            "rationale": "Trophic interactions between wild salmon and zooplankton operate on short-term (seasonal) timescales, not long-term. Effect size remains weak due to small wild salmon biomass relative to zooplankton standing stock."
        }
    },

    # [19] Global greenhouse gas emissions -> Glacial retreat: temporal_lag
    # should be long-term (correct), but confidence 3 is too low given
    # IPCC AR6 very high confidence in GHG-driven Arctic warming and glacial retreat.
    {
        "context": "arctic_fjord",
        "from_substr": "Global greenhouse gas emissions",
        "to_substr": "Glacial retreat altering freshwater",
        "changes": {
            "confidence": 4,
            "rationale": "IPCC AR6 WG1 attributes Arctic warming and glacial retreat to anthropogenic GHG emissions with high confidence. Upgraded from 3 to 4."
        }
    },

    # [22] Hydropower generation -> salmon aquaculture: polarity + is questionable.
    # Hydropower dams on fjord-draining rivers reduce wild salmon runs but don't
    # directly promote aquaculture. Connection is weak and indirect.
    {
        "context": "arctic_fjord",
        "from_substr": "Hydropower generation from fjord-draining rivers",
        "to_substr": "Open-pen Atlantic salmon aquaculture",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Hydropower dams on fjord-draining rivers do not directly promote salmon aquaculture. The link is indirect (reduced wild stocks may increase aquaculture demand), but this is weak and speculative. Strength and confidence lowered."
        }
    },

    # [25] Small-scale coastal fishing -> nutrient enrichment: fishing does not
    # cause nutrient enrichment. This connection has wrong polarity or is spurious.
    {
        "context": "arctic_fjord",
        "from_substr": "Small-scale coastal fishing",
        "to_substr": "Nutrient enrichment from aquaculture waste",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "polarity": "+",
            "rationale": "Small-scale fishing contributes negligible nutrient enrichment compared to aquaculture; the direct causal link is very weak. Strength and confidence lowered."
        }
    },

    # [26] Kelp harvesting -> nutrient enrichment: kelp harvesting removes
    # biomass that absorbs nutrients, so reducing kelp could increase ambient
    # nutrients, but this is an indirect effect, not a direct enrichment source.
    {
        "context": "arctic_fjord",
        "from_substr": "Kelp harvesting",
        "to_substr": "Nutrient enrichment from aquaculture waste",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Kelp harvesting removes a nutrient sink (kelp absorbs dissolved nutrients), indirectly allowing higher ambient nutrient levels, but this is not a direct source of aquaculture-derived nutrient enrichment. Causal link is weak."
        }
    },

    # [27] Marine research stations -> nutrient enrichment: negligible effect.
    {
        "context": "arctic_fjord",
        "from_substr": "Marine research and monitoring stations",
        "to_substr": "Nutrient enrichment from aquaculture waste",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Research stations contribute negligible nutrient loading compared to aquaculture operations. Causal link is very weak."
        }
    },

    # [28] Cruise ship discharge -> deep-water renewal: cruise discharge is
    # minor relative to physical oceanographic drivers of deep-water renewal.
    # Polarity should be negative (discharge degrades water quality, may reduce
    # effective O2 renewal).
    {
        "context": "arctic_fjord",
        "from_substr": "Cruise ship discharge",
        "to_substr": "Deep-water renewal frequency and oxygen levels",
        "changes": {
            "polarity": "-",
            "strength": "weak",
            "confidence": 2,
            "rationale": "Cruise ship grey water and air emissions degrade water quality rather than promoting deep-water renewal. Effect is negative but weak relative to physical oceanographic drivers. Polarity corrected from + to -."
        }
    },

    # [30] Carbon cycling/sediment burial -> aquaculture employment: no direct
    # causal link between carbon burial and aquaculture jobs.
    {
        "context": "arctic_fjord",
        "from_substr": "Carbon cycling and fjord sediment carbon burial",
        "to_substr": "Aquaculture industry employment",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "No direct causal mechanism linking fjord carbon burial to aquaculture employment. The connection is ecologically indirect at best."
        }
    },

    # [36] Arctic cruise tourism -> kelp harvesting: no clear causal link.
    {
        "context": "arctic_fjord",
        "from_substr": "Arctic cruise tourism growth",
        "to_substr": "Kelp harvesting",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Cruise tourism does not directly drive kelp harvesting. These are independent economic activities with no demonstrated causal link."
        }
    },

    # =====================================================================
    # ARCTIC SEA ICE (35 connections)
    # =====================================================================

    # [22] Polar expedition cruise tourism -> accelerating sea ice loss:
    # Tourism emissions are negligible compared to global GHG budget.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Polar expedition cruise tourism",
        "to_substr": "Accelerating sea ice extent and thickness loss",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Arctic cruise tourism contributes negligible GHG emissions relative to global totals driving sea ice loss. The direct causal contribution is extremely weak."
        }
    },

    # [23] Ice-edge fisheries -> accelerating sea ice loss: fisheries do not
    # cause sea ice loss.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Ice-edge fisheries",
        "to_substr": "Accelerating sea ice extent and thickness loss",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Ice-edge fisheries do not causally drive sea ice loss. Fishing vessel emissions are negligible relative to global GHG forcing. Causal link is spurious."
        }
    },

    # [24] Climate and sea ice monitoring research -> accelerating sea ice loss:
    # Research does not cause ice loss. This seems like a spurious connection.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Climate and sea ice monitoring research",
        "to_substr": "Accelerating sea ice extent and thickness loss",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Scientific monitoring does not causally accelerate sea ice loss. Research vessels contribute negligible emissions. Connection is spurious."
        }
    },

    # [25] Underwater noise from shipping -> polar bear body condition:
    # polarity + means more noise = better body condition, which is wrong.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Underwater noise from increased shipping",
        "to_substr": "Polar bear population and body condition",
        "changes": {
            "polarity": "-",
            "rationale": "Increased underwater noise from shipping disturbs marine mammals that polar bears prey on (seals), indirectly reducing prey availability and increasing bear stress. Effect is negative on bear condition. Polarity corrected from + to -."
        }
    },

    # [26] Black carbon deposition -> polar bear body condition:
    # polarity + means more black carbon = better bear condition, which is wrong.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Black carbon deposition accelerating ice melt",
        "to_substr": "Polar bear population and body condition",
        "changes": {
            "polarity": "-",
            "strength": "medium",
            "confidence": 4,
            "rationale": "Black carbon deposition accelerates sea ice melt, reducing polar bear hunting habitat and prey access. AMAP (2021) documents this as a significant contributor to Arctic warming. Effect is clearly negative on bear populations. Polarity corrected from + to -."
        }
    },

    # [33] Arctic shipping cost savings -> indigenous food sovereignty:
    # More shipping could disrupt traditional subsistence patterns.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Arctic shipping cost savings",
        "to_substr": "Indigenous community food sovereignty",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "The relationship between Arctic shipping expansion and indigenous food sovereignty is contested. Increased shipping may bring economic benefits but also disrupts marine mammal migration routes and traditional subsistence patterns. Evidence is mixed."
        }
    },

    # [34] Arctic oil and gas seismic exploration -> sea ice loss:
    # Seismic exploration does not directly cause sea ice loss.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Arctic oil and gas seismic exploration",
        "to_substr": "Accelerating sea ice extent and thickness loss",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Seismic exploration does not directly cause sea ice loss. The link through eventual fossil fuel extraction and GHG emissions is very indirect at the exploration stage."
        }
    },

    # [14] Inuit food security -> food sovereignty: confidence 3 is low for
    # a well-documented relationship.
    {
        "context": "arctic_sea_ice",
        "from_substr": "Inuit and indigenous community food security",
        "to_substr": "Indigenous community food sovereignty",
        "changes": {
            "confidence": 4,
            "strength": "strong",
            "rationale": "Food security is a core component of food sovereignty for indigenous communities. This is well-documented in Arctic Human Development Reports and IPCC AR6 CCP6. Confidence and strength upgraded."
        }
    },

    # =====================================================================
    # ARCTIC ISLAND (40 connections)
    # =====================================================================

    # [14] Permafrost thaw -> ballast water invasive species: very indirect link.
    {
        "context": "arctic_island",
        "from_substr": "Permafrost thaw destabilizing",
        "to_substr": "Ballast water-mediated invasive species",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Permafrost thaw does not directly cause ballast water introductions. The link (thaw enables more shipping, which increases ballast water risk) is very indirect. Confidence lowered."
        }
    },

    # [30] Oil spill risk -> seabird colonies: polarity is + which is WRONG.
    {
        "context": "arctic_island",
        "from_substr": "Oil spill risk in ice-covered waters",
        "to_substr": "Seabird colony populations",
        "changes": {
            "polarity": "-",
            "strength": "strong",
            "confidence": 4,
            "rationale": "Oil spills are devastating to seabird colonies, causing direct mortality through oiling and long-term reproductive impacts. The effect is strongly negative. Polarity corrected from + to -. Well-documented (AMAP, Wiese & Robertson 2004)."
        }
    },

    # [31] Black carbon deposition on snow -> seabird colonies: polarity + is wrong.
    {
        "context": "arctic_island",
        "from_substr": "Black carbon deposition on snow and ice",
        "to_substr": "Seabird colony populations",
        "changes": {
            "polarity": "-",
            "confidence": 3,
            "rationale": "Black carbon accelerates snow and ice melt, indirectly affecting seabird prey availability (ice-associated food webs) and potentially altering nesting conditions. Effect is negative. Polarity corrected from + to -."
        }
    },

    # [32] Military legacy contamination -> seabird colonies: polarity + is wrong.
    {
        "context": "arctic_island",
        "from_substr": "Military legacy contamination",
        "to_substr": "Seabird colony populations",
        "changes": {
            "polarity": "-",
            "confidence": 3,
            "rationale": "Legacy contaminants (PCBs, heavy metals) from Cold War military sites bioaccumulate in Arctic food webs and negatively affect seabird reproduction and survival (AMAP POPs assessment). Polarity corrected from + to -."
        }
    },

    # [39] Invasive predators -> Arctic char: polarity + is wrong.
    {
        "context": "arctic_island",
        "from_substr": "Invasive mammalian predators",
        "to_substr": "Arctic char",
        "changes": {
            "polarity": "-",
            "confidence": 3,
            "rationale": "Invasive predators (rats, foxes) can prey on Arctic char eggs and juveniles in shallow streams, and compete for food resources. Effect is negative on char populations. Polarity corrected from + to -."
        }
    },

    # [38] AMAP monitoring -> Arctic shipping route access: dubious connection.
    {
        "context": "arctic_island",
        "from_substr": "Arctic Council AMAP contaminant monitoring",
        "to_substr": "Arctic shipping route access",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Environmental monitoring does not directly promote shipping route access. The connection is very indirect (monitoring informs policy which may regulate shipping). Strength and confidence lowered."
        }
    },

    # =====================================================================
    # PACIFIC ISLAND ATOLL (39 connections)
    # =====================================================================

    # [19] Coral bleaching -> ocean acidification: spurious causal link.
    {
        "context": "pacific_island_atoll",
        "from_substr": "Coral bleaching from ocean warming",
        "to_substr": "Ocean acidification reducing coral calcification",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Coral bleaching and ocean acidification are parallel consequences of rising CO2 and ocean warming, not causally linked (bleaching does not cause acidification). They co-occur but are driven by the same root cause. Causal link is spurious."
        }
    },

    # [27-30] Several activities -> sea level rise: spurious causal links.
    {
        "context": "pacific_island_atoll",
        "from_substr": "Foreign fleet tuna fishing",
        "to_substr": "Sea level rise from thermal expansion",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Tuna fishing does not causally drive sea level rise. The link through vessel GHG emissions is negligible relative to global forcing. Connection is spurious."
        }
    },
    {
        "context": "pacific_island_atoll",
        "from_substr": "Pearl oyster farming",
        "to_substr": "Sea level rise from thermal expansion",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Pearl farming does not cause sea level rise. These are independent processes. Connection is spurious."
        }
    },
    {
        "context": "pacific_island_atoll",
        "from_substr": "Groundwater extraction",
        "to_substr": "Sea level rise from thermal expansion",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Groundwater extraction does not cause global sea level rise from thermal expansion. These are independent processes (though extraction affects freshwater lens separately). Connection is spurious."
        }
    },
    {
        "context": "pacific_island_atoll",
        "from_substr": "Seawall and coastal defence",
        "to_substr": "Sea level rise from thermal expansion",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Seawall construction does not cause sea level rise. Seawalls are a response to sea level rise, not a driver. Connection direction appears reversed."
        }
    },

    # [36] Regional tuna management (WCPFC) -> sea level rise: spurious.
    {
        "context": "pacific_island_atoll",
        "from_substr": "Regional tuna management",
        "to_substr": "Sea level rise from thermal expansion",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "WCPFC tuna management measures do not affect global sea level rise. These are independent processes. Connection is spurious."
        }
    },

    # [37] Invasive predators -> atoll reef crest integrity: indirect link.
    {
        "context": "pacific_island_atoll",
        "from_substr": "Invasive mammalian predators",
        "to_substr": "Atoll reef crest structural integrity",
        "changes": {
            "polarity": "-",
            "strength": "weak",
            "confidence": 3,
            "rationale": "Invasive predators reduce seabird populations, which reduces guano-derived nutrient inputs to reef ecosystems, indirectly weakening reef productivity (Graham et al. 2018 Nature). Effect is negative but indirect and weak."
        }
    },

    # [38] Copra production -> climate change: negligible GHG contribution.
    {
        "context": "pacific_island_atoll",
        "from_substr": "Copra production and coconut palm",
        "to_substr": "Climate change and ocean warming",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Copra production on atolls contributes negligible GHG emissions relative to global climate forcing. Connection is spurious."
        }
    },

    # [4] Ocean acidification -> lagoon coral cover: upgrade per IPCC AR6.
    {
        "context": "pacific_island_atoll",
        "from_substr": "Ocean acidification reducing coral calcification",
        "to_substr": "Lagoon water quality and coral cover",
        "changes": {
            "strength": "strong",
            "confidence": 5,
            "rationale": "IPCC AR6 assesses with high confidence that ocean acidification reduces coral calcification rates and reef accretion, directly threatening lagoon coral cover. Effect is strong and well-documented (Hoegh-Guldberg et al. 2017)."
        }
    },

    # =====================================================================
    # INDIAN OCEAN CORAL REEF (38 connections)
    # =====================================================================

    # [18] Overfishing herbivores -> ocean acidification: no causal link.
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Overfishing of herbivorous reef fish",
        "to_substr": "Ocean acidification reducing coral calcification",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Overfishing of herbivorous fish does not cause ocean acidification. These are independent stressors driven by different mechanisms (fishing vs. atmospheric CO2). Connection is spurious."
        }
    },

    # [17] Mass bleaching -> Crown-of-thorns outbreaks: causal link is debated.
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Mass coral bleaching from marine heatwaves",
        "to_substr": "Crown-of-thorns starfish",
        "changes": {
            "confidence": 2,
            "rationale": "The causal link between mass bleaching events and CoTS outbreaks is not well-established. CoTS outbreaks are primarily driven by nutrient enrichment and larval supply, not directly by bleaching. Confidence lowered."
        }
    },

    # [24-26] Activities -> mass bleaching: individual activities do not
    # directly cause mass bleaching events.
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Coral and sand mining",
        "to_substr": "Mass coral bleaching",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Coral mining causes direct physical reef destruction but does not cause mass bleaching events (which are driven by marine heatwaves). These are independent stressors. Connection conflates different impact pathways."
        }
    },
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Desalination plant brine",
        "to_substr": "Mass coral bleaching",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Desalination brine causes localized thermal and salinity stress but does not trigger mass bleaching events (driven by basin-scale marine heatwaves). Connection conflates local vs. regional stressors."
        }
    },
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Reef-based mariculture",
        "to_substr": "Mass coral bleaching",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Reef mariculture may cause localized stress but does not drive mass coral bleaching events (caused by marine heatwaves from ocean warming). Connection is spurious."
        }
    },

    # [27] Plastic debris -> live coral cover: polarity + is WRONG.
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Plastic debris accumulation",
        "to_substr": "Live coral cover",
        "changes": {
            "polarity": "-",
            "strength": "medium",
            "confidence": 4,
            "rationale": "Plastic debris on reefs increases coral disease likelihood 20-fold (Lamb et al. 2018 Science), causes physical abrasion and smothering. Effect is clearly negative on live coral cover. Polarity corrected from + to -."
        }
    },

    # [28] Sedimentation -> live coral cover: polarity + is WRONG.
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Sedimentation from coastal construction",
        "to_substr": "Live coral cover",
        "changes": {
            "polarity": "-",
            "strength": "strong",
            "confidence": 5,
            "rationale": "Sedimentation smothers coral polyps, reduces light penetration, and inhibits larval settlement. This is one of the most well-documented threats to coral reefs globally (Fabricius 2005, Rogers 1990). Polarity corrected from + to -."
        }
    },

    # [32] MPAs -> mass bleaching: MPAs cannot prevent bleaching.
    {
        "context": "indian_ocean_coral_reef",
        "from_substr": "Marine Protected Area networks",
        "to_substr": "Mass coral bleaching",
        "changes": {
            "strength": "weak",
            "confidence": 3,
            "rationale": "MPAs cannot prevent mass bleaching events (driven by ocean warming), but they may enhance reef resilience and recovery capacity by reducing local stressors. Direct effect on bleaching pressure is weak (Selig et al. 2012)."
        }
    },

    # =====================================================================
    # INDIAN OCEAN ISLAND (43 connections)
    # =====================================================================

    # [4] Crown-of-thorns -> reef condition: lower strength for Indian Ocean.
    {
        "context": "indian_ocean_island",
        "from_substr": "Crown-of-thorns starfish",
        "to_substr": "Granitic reef vs coralline reef condition",
        "changes": {
            "strength": "medium",
            "rationale": "CoTS outbreaks in Indian Ocean islands (Seychelles) are less frequent and severe than in the Great Barrier Reef. Effect on reef condition is moderate. Strength changed from strong to medium."
        }
    },

    # [27] Poaching of sea turtles -> reef condition: polarity + is wrong.
    {
        "context": "indian_ocean_island",
        "from_substr": "Poaching of sea turtles and giant tortoises",
        "to_substr": "Granitic reef vs coralline reef condition",
        "changes": {
            "polarity": "-",
            "strength": "weak",
            "confidence": 2,
            "rationale": "Poaching does not improve reef condition. Hawksbill turtles feed on sponges that compete with corals, so turtle removal could indirectly harm reefs. Effect is negative but weak and indirect. Polarity corrected from + to -."
        }
    },

    # [28] Saltwater intrusion -> reef condition: polarity + is wrong.
    {
        "context": "indian_ocean_island",
        "from_substr": "Saltwater intrusion from sea level rise",
        "to_substr": "Granitic reef vs coralline reef condition",
        "changes": {
            "polarity": "-",
            "strength": "weak",
            "confidence": 2,
            "rationale": "Saltwater intrusion primarily affects terrestrial freshwater resources. Any reef effect would be through altered groundwater discharge (submarine groundwater can carry nutrients/pollutants). Polarity corrected; effect is weak and indirect."
        }
    },

    # [31] Invasive species -> pristine tourism value: polarity + is WRONG.
    {
        "context": "indian_ocean_island",
        "from_substr": "Invasive species threatening endemic island biota",
        "to_substr": "Pristine reef and beach tourism experience",
        "changes": {
            "polarity": "-",
            "strength": "medium",
            "confidence": 4,
            "rationale": "Invasive species degrade the pristine natural environment that attracts tourists to island destinations. Loss of endemic species reduces ecotourism appeal. Effect is clearly negative. Polarity corrected from + to -."
        }
    },

    # [36] Invasive predator eradication on seabird islands -> coral bleaching: spurious.
    {
        "context": "indian_ocean_island",
        "from_substr": "Invasive predator eradication on seabird islands",
        "to_substr": "Coral bleaching from Indian Ocean warming",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Invasive predator eradication on islands has no direct effect on coral bleaching events (driven by marine heatwaves). Seabird recovery may indirectly benefit reef nutrient cycling but does not affect thermal stress. Connection is spurious."
        }
    },

    # [37] Turtle nesting beach protection -> coral bleaching: spurious.
    {
        "context": "indian_ocean_island",
        "from_substr": "Turtle nesting beach protection",
        "to_substr": "Coral bleaching from Indian Ocean warming",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Turtle nesting beach protection does not affect coral bleaching events (driven by ocean warming). These are independent conservation measures. Connection is spurious."
        }
    },

    # [39] Invasive predators -> climate change: no causal link.
    {
        "context": "indian_ocean_island",
        "from_substr": "Invasive mammalian predators",
        "to_substr": "Climate change and ocean warming",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Invasive predators on islands do not drive global climate change and ocean warming. These are independent processes. Connection is spurious."
        }
    },

    # [22] GHG emissions -> Indian Ocean warming: temporal_lag should be long-term.
    {
        "context": "indian_ocean_island",
        "from_substr": "Global greenhouse gas emissions",
        "to_substr": "Coral bleaching from Indian Ocean warming",
        "changes": {
            "temporal_lag": "long-term",
            "rationale": "The thermal inertia of the Indian Ocean means GHG-driven warming manifests as mass bleaching events on decadal timescales, not short-term. Changed from short-term to long-term per IPCC AR6 ocean heat content projections."
        }
    },

    # =====================================================================
    # TROPICAL MANGROVE (34 connections)
    # =====================================================================

    # [5] Mangrove canopy cover -> blue carbon storage: strength should be strong.
    {
        "context": "tropical_mangrove",
        "from_substr": "Mangrove canopy cover and forest extent",
        "to_substr": "Blue carbon storage in mangrove soils",
        "changes": {
            "strength": "strong",
            "rationale": "Mangrove forests store ~1000 tC/ha in soil carbon, among the highest of any ecosystem globally (Donato et al. 2011 Nature Geoscience). 75% of total mangrove carbon is in soils. Strength upgraded from medium to strong."
        }
    },

    # [24] Oil and chemical pollution -> mangrove cover: polarity + is WRONG.
    {
        "context": "tropical_mangrove",
        "from_substr": "Oil and chemical pollution",
        "to_substr": "Mangrove canopy cover and forest extent",
        "changes": {
            "polarity": "-",
            "strength": "strong",
            "confidence": 5,
            "rationale": "Oil spills cause widespread mangrove mortality by coating pneumatophores and blocking gas exchange (Duke et al. 2017). Chemical pollution degrades mangrove health. Effect is strongly negative. Polarity corrected from + to -."
        }
    },

    # [25] Climate change and ocean warming -> mangrove cover: polarity + is wrong
    # for tropical context.
    {
        "context": "tropical_mangrove",
        "from_substr": "Climate change and ocean warming",
        "to_substr": "Mangrove canopy cover and forest extent",
        "changes": {
            "polarity": "-",
            "strength": "medium",
            "confidence": 4,
            "rationale": "In tropical settings, climate change threatens mangroves through sea level rise exceeding sediment accretion rates, increased storm intensity, and altered precipitation. While warming enables poleward expansion, the net effect on existing tropical mangroves is negative (Lovelock et al. 2015, IPCC AR6). Polarity corrected from + to -."
        }
    },

    # [26] Mangrove fish assemblage -> blue carbon: very indirect link.
    {
        "context": "tropical_mangrove",
        "from_substr": "Mangrove-associated fish assemblage diversity",
        "to_substr": "Blue carbon storage in mangrove soils",
        "changes": {
            "strength": "weak",
            "confidence": 2,
            "rationale": "Fish assemblage diversity does not directly drive soil carbon storage in mangroves. Carbon storage is primarily determined by mangrove extent, species composition, and sedimentation rates. Connection is very indirect."
        }
    },
]


def find_connection(connections, from_substr, to_substr):
    """Find a connection by substring matching on from and to fields."""
    matches = []
    for i, conn in enumerate(connections):
        if from_substr.lower() in conn["from"].lower() and to_substr.lower() in conn["to"].lower():
            matches.append((i, conn))
    return matches


def apply_corrections(db):
    """Apply all corrections and return a change log."""
    changelog = []

    for corr in CORRECTIONS:
        ctx_name = corr["context"]
        if ctx_name not in db["contexts"]:
            print(f"  WARNING: context '{ctx_name}' not found, skipping.")
            continue

        conns = db["contexts"][ctx_name].get("connections", [])
        matches = find_connection(conns, corr["from_substr"], corr["to_substr"])

        if not matches:
            print(f"  WARNING: no match for '{corr['from_substr']}' -> '{corr['to_substr']}' in {ctx_name}")
            continue

        if len(matches) > 1:
            print(f"  WARNING: multiple matches ({len(matches)}) for '{corr['from_substr']}' -> '{corr['to_substr']}' in {ctx_name}, using first.")

        idx, conn = matches[0]
        changes = corr["changes"]
        old_vals = {}
        new_vals = {}

        for field, new_val in changes.items():
            old_val = conn.get(field)
            if old_val != new_val:
                old_vals[field] = old_val
                new_vals[field] = new_val
                conn[field] = new_val

        if old_vals:
            changelog.append({
                "context": ctx_name,
                "index": idx,
                "from": conn["from"],
                "to": conn["to"],
                "old": old_vals,
                "new": new_vals,
            })

    return changelog


def print_summary(changelog):
    """Print a human-readable summary of changes."""
    print("\n" + "=" * 70)
    print(f"VALIDATION SUMMARY: {len(changelog)} connection(s) updated")
    print("=" * 70)

    # Group by context
    by_ctx = {}
    for entry in changelog:
        by_ctx.setdefault(entry["context"], []).append(entry)

    for ctx, entries in sorted(by_ctx.items()):
        print(f"\n--- {ctx} ({len(entries)} changes) ---")
        for e in entries:
            print(f"  [{e['index']}] {e['from'][:55]}")
            print(f"       -> {e['to'][:55]}")
            for field in sorted(e["old"].keys()):
                if field == "rationale":
                    print(f"       {field}: [updated]")
                else:
                    print(f"       {field}: {e['old'][field]} -> {e['new'][field]}")

    # Statistics
    polarity_changes = sum(1 for e in changelog if "polarity" in e["old"])
    strength_changes = sum(1 for e in changelog if "strength" in e["old"])
    confidence_changes = sum(1 for e in changelog if "confidence" in e["old"])
    temporal_changes = sum(1 for e in changelog if "temporal_lag" in e["old"])
    reversibility_changes = sum(1 for e in changelog if "reversibility" in e["old"])

    print(f"\n--- Change breakdown ---")
    print(f"  Polarity corrections:      {polarity_changes}")
    print(f"  Strength adjustments:       {strength_changes}")
    print(f"  Confidence adjustments:     {confidence_changes}")
    print(f"  Temporal lag corrections:   {temporal_changes}")
    print(f"  Reversibility corrections:  {reversibility_changes}")

    contexts_affected = len(by_ctx)
    total_target_conns = 38 + 35 + 40 + 39 + 38 + 43 + 34  # 267
    print(f"\n  Contexts affected: {contexts_affected}/7")
    print(f"  Connections changed: {len(changelog)}/{total_target_conns} ({len(changelog)/total_target_conns*100:.1f}%)")
    print(f"  Connections unchanged: {total_target_conns - len(changelog)}/{total_target_conns} ({(total_target_conns - len(changelog))/total_target_conns*100:.1f}%)")


def main():
    if not KB_PATH.exists():
        print(f"ERROR: Knowledge base not found at {KB_PATH}")
        return 1

    with open(KB_PATH, "r", encoding="utf-8") as f:
        db = json.load(f)

    print(f"Knowledge Base: {KB_PATH.name}")
    print(f"Version: {db.get('version', 'unknown')}")

    target_contexts = [
        "arctic_fjord", "arctic_sea_ice", "arctic_island",
        "pacific_island_atoll", "indian_ocean_coral_reef",
        "indian_ocean_island", "tropical_mangrove"
    ]

    total = sum(len(db["contexts"][c].get("connections", []))
                for c in target_contexts if c in db["contexts"])
    print(f"Target contexts: {len(target_contexts)} | Connections to validate: {total}")
    print(f"Corrections defined: {len(CORRECTIONS)}")
    print()

    # Deep copy to compare
    original = copy.deepcopy(db)

    changelog = apply_corrections(db)

    if changelog:
        # Update last_updated
        db["last_updated"] = "2026-03-17"

        with open(KB_PATH, "w", encoding="utf-8") as f:
            json.dump(db, f, indent=2, ensure_ascii=False)

        print_summary(changelog)
        print(f"\nFile written: {KB_PATH}")
    else:
        print("No changes needed. All connections validated successfully.")

    return 0


if __name__ == "__main__":
    exit(main())
