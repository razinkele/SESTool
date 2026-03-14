# SES Knowledge Base Improvement Plan

**Version:** 1.0
**Date:** 2026-03-15
**Current State:** 30 contexts, 402 connections, avg 13.4 connections/context
**Target State:** 30+ contexts, 600+ connections, avg 20+ connections/context

---

## Phase 1: Connection Density (Target: 600+ total connections)

### Priority: CRITICAL — All contexts below 15 connections

| Context | Current | Target | Gap | Connections to Add |
|---------|---------|--------|-----|-------------------|
| baltic_open_coast | 10 | 18 | +8 | Seal population→tourism, coastal erosion→property, climate→sea trout, eutrophication→beach quality, responses→pressures |
| north_sea_estuary | 10 | 18 | +8 | Port dredging→benthic, eel migration→fishery, flood defence→habitat, contamination→shellfish, WFD→water quality |
| north_sea_offshore | 11 | 18 | +7 | Wind farm→seabird, sandeel→seabird food web, aggregate→benthic, trawling→cod, MSP→spatial conflict |
| mediterranean_seagrass | 11 | 18 | +7 | Anchor→meadow, epiphyte→light, nursery→fishery, Caulerpa→native, restoration→coverage |
| atlantic_offshore | 12 | 18 | +6 | Tuna quota→stock, bycatch→seabird, seamount trawl→coral, acidification→shell, ICCAT→fleet |

### Priority: HIGH — All contexts at 12-15 connections

| Context | Current | Target | Gap |
|---------|---------|--------|-----|
| All 6 island contexts | 14-16 | 20 | +4-6 each |
| baltic_lagoon | 14 | 18 | +4 |
| baltic_estuary | 13 | 18 | +5 |
| baltic_archipelago | 12 | 18 | +6 |
| caribbean_seagrass | 13 | 18 | +5 |
| tropical_mangrove | 13 | 18 | +5 |
| arctic_fjord | 12 | 18 | +6 |
| arctic_sea_ice | 12 | 18 | +6 |

**Estimated new connections: ~200**

---

## Phase 2: Cross-Ecosystem Connectivity

### 2.1 Mangrove-Seagrass-Reef Triad

Add explicit connections showing how these three habitats are functionally linked:

**tropical_mangrove additions:**
- Mangrove nursery output → Reef fish recruitment (cross-context reference)
- Mangrove deforestation → Increased sedimentation on seagrass beds
- Mangrove carbon export → Seagrass epiphyte community fuel

**caribbean_seagrass additions:**
- Seagrass nursery function → Reef fish juvenile survival
- Seagrass loss → Reduced reef fish recruitment (80% commercial reef fish use seagrass nurseries)
- Seagrass sediment stabilization → Reef water clarity maintenance

**caribbean_coral_reef / indian_ocean_coral_reef additions:**
- Reef structural complexity → Mangrove-origin juvenile fish habitat
- Reef degradation → Loss of coastal protection for mangrove/seagrass

**Implementation:** Add `cross_context_links` field to JSON schema:
```json
"cross_context_links": [
  {
    "target_context": "caribbean_coral_reef",
    "from_element": "Mangrove nursery function",
    "to_element": "Reef fish recruitment",
    "polarity": "+",
    "rationale": "80% of commercial reef fish use mangrove/seagrass nurseries"
  }
]
```

### 2.2 Estuary-River Upstream Connectivity

Add catchment-scale drivers to all estuary contexts:
- Upstream dam regulation → Altered flow regime → Salinity gradient change
- Agricultural intensification in catchment → Nutrient loading → Eutrophication
- Industrial legacy in river basin → Chronic contamination → Bioaccumulation

### 2.3 Coastal-Offshore Exchange

- Lagoon/estuary larval export → Offshore juvenile fish recruitment
- Offshore nutrient upwelling → Coastal algal bloom events
- Offshore wind farm → Artificial reef effect on coastal fish

**Estimated new connections: ~30 cross-context**

---

## Phase 3: Terminology Standardization

### 3.1 Nutrient Enrichment (15 variants → 3 standard forms)

**Standard terms to adopt:**
1. `Nutrient enrichment from agricultural sources` (land-based diffuse)
2. `Nutrient enrichment from sewage and wastewater` (point source)
3. `Nutrient enrichment from aquaculture waste` (marine point source)

**Action:** Search-and-replace across all contexts in ses_knowledge_db.json, ses_connection_knowledge_base.R, and ai_isa_knowledge_base.R

### 3.2 Coral Thermal Stress (13 variants → 3 standard forms)

**Standard terms:**
1. `Marine thermal stress from ocean warming` (climate-driven pressure)
2. `Thermal pollution from industrial cooling discharge` (anthropogenic)
3. `Coral bleaching event` (consequence, listed as state not pressure)

### 3.3 Plastic Pollution (14 variants → structured hierarchy)

**Standard terms:**
1. `Marine macroplastic litter accumulation` (>5mm, entanglement/ingestion)
2. `Microplastic contamination in sediments and food webs` (<5mm, bioaccumulation)
3. `Beach litter accumulation` (aesthetic/tourism impact)

### 3.4 Invasive Species (standardize template)

**Standard pattern:** `[Species] ([Scientific name]) invasion and impact on [target]`
- Example: "Lionfish (Pterois volitans/miles) invasion and predation on reef fish"
- Example: "Mnemiopsis leidyi invasion and competition with fish larvae"

**Estimated changes: ~80 term replacements**

---

## Phase 4: Missing Ecological Processes

### 4.1 Pressure→Pressure Cascades (add to all contexts)

Every context should have at least 2 pressure amplification chains:
- Eutrophication → Algal bloom → Hypoxia → Fish kill
- Overfishing → Predator loss → Prey explosion → Trophic cascade
- Climate warming → Species range shift → Invasive establishment
- Habitat loss → Fragmentation → Edge effects → Biodiversity decline

### 4.2 State→State Tipping Points (add to all contexts)

Critical ecological regime shifts to represent:
- Coral reef: Coral dominance → Macroalgal dominance (parrotfish threshold)
- Seagrass: Clear water → Turbid/epiphyte-dominated (nutrient threshold)
- Baltic: Oxygenated → Hypoxic (nutrient loading threshold)
- Arctic: Ice-covered → Ice-free (temperature threshold)
- Estuary: Freshwater-dominated → Saline intrusion (flow threshold)

### 4.3 Response→Activity Behavior Change (add to all contexts)

Show how management interventions change human behavior:
- Fishing ban → Shift to alternative livelihood → Reduced fishing pressure
- MPA designation → Spillover effect → Increased catch outside MPA
- Nutrient regulation → Agricultural practice change → Reduced runoff
- Tourism quotas → Visitor redistribution → Reduced local pressure

**Estimated new connections: ~120**

---

## Phase 5: Island-Specific Enhancements

### 5.1 Invasive Predator Pressure (add to all 8 island contexts)

All island contexts need:
- **Pressure:** "Invasive mammalian predators (rats, cats, mongoose) on native wildlife"
- **State:** "Native seabird colony breeding success"
- **Response:** "Invasive predator eradication and biosecurity programmes"
- **Connection:** Invasive predators → Seabird colony decline (- strong)
- **Connection:** Eradication programme → Predator population (- strong)

### 5.2 Island Freshwater Security (add to atoll and small island contexts)

- **State:** "Freshwater lens integrity and volume"
- **Pressure:** "Saltwater intrusion from sea level rise"
- **Connection:** Sea level rise → Freshwater lens contamination (- strong)

### 5.3 Island Waste Management (add to all island contexts)

- **Pressure:** "Limited waste disposal capacity and illegal dumping"
- **Connection:** Tourism population surge → Waste generation exceeding capacity (+ strong)

**Estimated new connections: ~50**

---

## Phase 6: Metadata Enrichment

### 6.1 Add References to Original 14 Contexts

The first 14 contexts have connections WITHOUT references, temporal_lag, reversibility.
The newer 16 contexts have these fields. Backfill the originals.

**Estimated: ~230 connections need metadata backfill**

### 6.2 Add MSFD Descriptor Tags

Tag elements with EU MSFD descriptor codes where applicable:
- D1 (Biodiversity) → Species population states
- D3 (Commercial fish) → Fish stock states
- D5 (Eutrophication) → Nutrient pressures
- D10 (Marine litter) → Plastic pressures
- D11 (Noise) → Acoustic pressures

```json
"msfd_descriptors": ["D1", "D3"]
```

### 6.3 Add CICES Codes to Ecosystem Service Impacts

Tag impact elements with CICES V5.1 codes:
- Fish provisioning → CICES 1.1.1.1
- Storm protection → CICES 2.2.1.1
- Recreation/tourism → CICES 3.1.1.2
- Carbon sequestration → CICES 2.2.6.1

---

## Implementation Timeline

```
Week 1:  Phase 1 - Connection density (200 new connections)
         Focus on contexts below 15 connections first

Week 2:  Phase 2 - Cross-ecosystem connectivity (30 connections)
         Phase 3 - Terminology standardization (80 replacements)

Week 3:  Phase 4 - Missing ecological processes (120 connections)
         Phase 5 - Island enhancements (50 connections)

Week 4:  Phase 6 - Metadata backfill (230 connections enriched)
         Final validation and ecological review
```

---

## Success Metrics

| Metric | Current | Target | Improvement |
|--------|---------|--------|-------------|
| Total contexts | 30 | 30+ | Maintained |
| Total connections | 402 | 600+ | +50% |
| Min connections/context | 7 | 15+ | +114% |
| Avg connections/context | 13.4 | 20+ | +49% |
| Contexts with metadata | 16/30 | 30/30 | 100% |
| Cross-context links | 0 | 15+ | New feature |
| Terminology variants | 50+ | 15 | -70% |
| MSFD-tagged elements | 0 | 200+ | New feature |

---

## Files Affected

- `data/ses_knowledge_db.json` — Primary knowledge database
- `data/ses_connection_knowledge_base.R` — Connection pattern rules
- `modules/ai_isa_knowledge_base.R` — Hardcoded suggestion fallbacks
- `functions/ses_knowledge_db_loader.R` — Loader (if schema changes)
- `modules/ai_isa/connection_generator.R` — Connection scoring
- `translations/` — Any new i18n keys for standardized terms
