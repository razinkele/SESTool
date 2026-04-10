#!/usr/bin/env python3
"""
Build an offshore wind parks SES knowledge base from BibTeX export.
Parses the 187 papers and maps them to DAPSIWRM elements.

DAPSIWRM mapping to JSON keys (matching main KB convention):
  drivers    = Drivers (D)
  activities = Activities (A)
  pressures  = Pressures (P)
  states     = Components / State (C/S)
  impacts    = Ecosystem Services (ES) — NOT "impacts" in the common sense
  welfare    = Goods & Benefits + Human Wellbeing (GB/W/HW combined)
  responses  = Responses + Measures (R/M combined)

Valid transitions (matching main KB):
  drivers->activities, activities->pressures, pressures->states,
  states->impacts, impacts->welfare, welfare->drivers  (primary chain + feedback)
  pressures->pressures, states->states  (interactions)
  responses->activities, responses->pressures, responses->drivers  (interventions)

Output: data/ses_knowledge_db_offshore_wind.json
"""

import re
import json
from pathlib import Path

# === Parse BibTeX ===

def parse_bibtex(bib_path):
    """Parse BibTeX file into list of dicts."""
    text = Path(bib_path).read_text(encoding="utf-8")
    entries = []
    raw_entries = re.split(r'\n@\w+\{', text)
    for raw in raw_entries:
        if not raw.strip():
            continue
        entry = {}
        m = re.search(r'year\s*=\s*\{(\d{4})\}', raw)
        if m:
            entry['year'] = int(m.group(1))
        m = re.search(r'title\s*=\s*\{\{(.+?)\}\}', raw, re.DOTALL)
        if m:
            entry['title'] = re.sub(r'\s+', ' ', m.group(1).strip())
        m = re.search(r'author\s*=\s*\{(.+?)\}(?:\s*,\s*\n|\s*\n)', raw, re.DOTALL)
        if m:
            entry['authors'] = re.sub(r'\s+', ' ', m.group(1).strip())
        m = re.search(r'journal\s*=\s*\{(.+?)\}', raw)
        if m:
            entry['journal'] = m.group(1).strip()
        m = re.search(r'doi\s*=\s*\{(.+?)\}', raw)
        if m:
            entry['doi'] = m.group(1).strip()
        m = re.search(r'abstract\s*=\s*\{\{(.+?)\}\}', raw, re.DOTALL)
        if m:
            entry['abstract'] = re.sub(r'\s+', ' ', m.group(1).strip())
        if entry.get('title'):
            entries.append(entry)
    return entries


def format_citation(entry):
    """Format short citation: 'FirstAuthor et al. YYYY'"""
    authors = entry.get('authors', 'Unknown')
    first = authors.split(' and ')[0].split(',')[0].strip()
    # Fix garbled single-letter surnames (e.g., "C, O. Mauricio Hernandez")
    if len(first) <= 2:
        parts = authors.split(' and ')[0].split(',')
        if len(parts) > 1:
            first = parts[1].strip().split()[-1]  # Take last word of given names
        if len(first) <= 2:
            first = authors.split(' and ')[0].replace(',', ' ').strip()
    year = entry.get('year', '????')
    n_authors = len(authors.split(' and '))
    if n_authors > 2:
        return f"{first} et al. {year}"
    elif n_authors == 2:
        second = authors.split(' and ')[1].split(',')[0].strip()
        return f"{first} & {second} {year}"
    return f"{first} {year}"


def classify_paper(entry):
    """Classify paper into DAPSIWRM-relevant themes based on title + abstract."""
    text = (entry.get('title', '') + ' ' + entry.get('abstract', '')).lower()
    tags = set()

    # --- Drivers ---
    if any(w in text for w in ['energy demand', 'renewable energy target', 'decarboni',
                                'carbon neutral', 'climate target', 'energy transition',
                                'energy security', 'energy policy', 'net zero',
                                'climate mitigation', 'green deal', 'paris agreement']):
        tags.add('driver_energy_transition')
    if any(w in text for w in ['economic growth', 'job creation', 'employment',
                                'economic development', 'blue economy', 'blue growth',
                                'industriali', 'regional development']):
        tags.add('driver_economic')
    if any(w in text for w in ['food security', 'protein demand', 'fish demand',
                                'seafood', 'aquaculture demand']):
        tags.add('driver_food_security')
    if any(w in text for w in ['population growth', 'urbanis', 'coastal population']):
        tags.add('driver_population')
    if any(w in text for w in ['climate change', 'global warming', 'sea level rise',
                                'ocean warming', 'climate variab']):
        tags.add('driver_climate_change')

    # --- Activities ---
    if any(w in text for w in ['offshore wind farm', 'wind turbine', 'wind energy',
                                'wind power', 'owf', 'owe', 'offshore wind']):
        tags.add('activity_offshore_wind')
    if any(w in text for w in ['fishing', 'fishery', 'fisheries', 'trawl', 'angling',
                                'recreational fish']):
        tags.add('activity_fishing')
    if any(w in text for w in ['aquaculture', 'mariculture', 'fish farm', 'mussel',
                                'seaweed', 'kelp farm']):
        tags.add('activity_aquaculture')
    if any(w in text for w in ['shipping', 'navigation', 'vessel traffic', 'maritime transport']):
        tags.add('activity_shipping')
    if any(w in text for w in ['tourism', 'recreation', 'leisure', 'whale watch']):
        tags.add('activity_tourism')
    if any(w in text for w in ['multi-use', 'multi use', 'co-location', 'colocation',
                                'coexistence', 'co-exist']):
        tags.add('activity_multi_use')
    if any(w in text for w in ['decommission', 'end-of-life', 'repurpos']):
        tags.add('activity_decommissioning')
    if any(w in text for w in ['cable', 'grid connect', 'transmission', 'substation']):
        tags.add('activity_grid_infrastructure')

    # --- Pressures ---
    if any(w in text for w in ['noise pollution', 'underwater noise', 'pile driving',
                                'acoustic', 'noise impact']):
        tags.add('pressure_noise')
    if any(w in text for w in ['habitat loss', 'habitat alter', 'seabed disturb',
                                'benthic impact', 'sediment', 'scour']):
        tags.add('pressure_habitat')
    if any(w in text for w in ['collision', 'bird strike', 'avian mortality',
                                'seabird', 'bird', 'bat']):
        tags.add('pressure_bird_collision')
    if any(w in text for w in ['electromagnetic', 'emf', 'electric field', 'magnetic field']):
        tags.add('pressure_emf')
    if any(w in text for w in ['visual impact', 'landscape', 'seascape', 'viewshed',
                                'aesthetic']):
        tags.add('pressure_visual')
    if any(w in text for w in ['displacement', 'exclusion', 'access restrict',
                                'fishing ground', 'spatial conflict', 'space compet']):
        tags.add('pressure_displacement')
    if any(w in text for w in ['barrier', 'migration', 'movement', 'connectivity']):
        tags.add('pressure_barrier')

    # --- State / Components ---
    if any(w in text for w in ['biodiversity', 'species richness', 'community composition',
                                'ecosystem', 'ecological']):
        tags.add('state_biodiversity')
    if any(w in text for w in ['marine mammal', 'cetacean', 'seal', 'porpoise',
                                'dolphin', 'whale']):
        tags.add('state_marine_mammals')
    if any(w in text for w in ['fish population', 'fish stock', 'fish communit',
                                'demersal', 'pelagic', 'cod', 'herring']):
        tags.add('state_fish')
    if any(w in text for w in ['benthic', 'benthos', 'invertebrate', 'mussel bed',
                                'reef effect', 'artificial reef', 'fouling',
                                'colonisation', 'colonization']):
        tags.add('state_benthos')
    if any(w in text for w in ['food web', 'trophic', 'predator', 'prey']):
        tags.add('state_food_web')
    if any(w in text for w in ['seabird', 'bird population', 'avian', 'gannet',
                                'tern', 'gull']):
        tags.add('state_seabirds')

    # --- Ecosystem Services (= "impacts" in JSON) ---
    if any(w in text for w in ['ecosystem service', 'provisioning', 'regulating',
                                'cultural service', 'supporting service']):
        tags.add('es_ecosystem_services')
    if any(w in text for w in ['carbon sequestration', 'carbon storage', 'blue carbon',
                                'carbon capture']):
        tags.add('es_carbon')
    if any(w in text for w in ['fish production', 'fishery production', 'catch',
                                'landings', 'spillover']):
        tags.add('es_fish_production')

    # --- Goods & Benefits / Welfare (= "welfare" in JSON) ---
    if any(w in text for w in ['electricity', 'energy production', 'power generation',
                                'energy output', 'capacity factor', 'megawatt', 'gigawatt']):
        tags.add('gb_energy')
    if any(w in text for w in ['revenue', 'profit', 'income', 'economic benefit',
                                'cost-benefit', 'cost benefit', 'lcoe']):
        tags.add('gb_economic')
    if any(w in text for w in ['employment', 'job', 'workforce', 'skill',
                                'supply chain', 'local econom']):
        tags.add('gb_employment')
    if any(w in text for w in ['social accept', 'public perception', 'attitude',
                                'nimby', 'not in my back', 'community support',
                                'social license', 'willingness to pay']):
        tags.add('hw_social_acceptance')
    if any(w in text for w in ['livelihood', 'wellbeing', 'well-being', 'welfare',
                                'quality of life', 'health']):
        tags.add('hw_wellbeing')
    if any(w in text for w in ['justice', 'equity', 'just transition', 'distribut',
                                'procedural', 'fairness']):
        tags.add('hw_justice')
    if any(w in text for w in ['cultural heritage', 'identity', 'sense of place',
                                'cultural value']):
        tags.add('hw_cultural')
    if any(w in text for w in ['conflict', 'dispute', 'tension', 'opposition',
                                'protest', 'resistance']):
        tags.add('hw_conflict')

    # --- Responses ---
    if any(w in text for w in ['marine spatial planning', 'msp', 'spatial plan',
                                'zoning', 'maritime spatial']):
        tags.add('response_msp')
    if any(w in text for w in ['environmental impact assessment', 'eia', 'impact assessment',
                                'strategic environmental assessment', 'sea ']):
        tags.add('response_eia')
    if any(w in text for w in ['stakeholder', 'participat', 'engagement', 'consultation',
                                'governance', 'co-management']):
        tags.add('response_stakeholder')
    if any(w in text for w in ['mitigation', 'compensat', 'offset', 'nature positive',
                                'biodiversity net gain', 'nature inclusive']):
        tags.add('response_mitigation')
    if any(w in text for w in ['regulation', 'policy', 'legislation', 'directive',
                                'permit', 'licensing']):
        tags.add('response_regulation')
    if any(w in text for w in ['monitor', 'survey', 'indicator', 'baseline',
                                'assessment framework']):
        tags.add('response_monitoring')
    if any(w in text for w in ['subsid', 'incentive', 'auction', 'feed-in',
                                'contract for difference', 'cfd']):
        tags.add('response_subsidy')
    if any(w in text for w in ['bubble curtain', 'noise mitigation', 'soft start',
                                'deterrent', 'pinger']):
        tags.add('measure_noise_mitigation')
    if any(w in text for w in ['closed area', 'exclusion zone', 'buffer zone',
                                'no-take', 'protected area', 'mpa']):
        tags.add('measure_spatial')
    if any(w in text for w in ['seasonal restrict', 'timing restrict', 'construction window']):
        tags.add('measure_temporal')
    if any(w in text for w in ['artificial reef', 'reef', 'habitat enhance',
                                'nature inclusive design', 'eco-design']):
        tags.add('measure_habitat_enhancement')

    return tags


# === Build the KB ===

def build_kb(papers):
    """Build the offshore wind parks SES knowledge base with correct DAPSIWRM mappings."""

    paper_tags = []
    for p in papers:
        tags = classify_paper(p)
        citation = format_citation(p)
        paper_tags.append({'entry': p, 'tags': tags, 'citation': citation})

    # Print tag statistics
    all_tags = {}
    for pt in paper_tags:
        for t in pt['tags']:
            all_tags[t] = all_tags.get(t, 0) + 1

    print(f"\nParsed {len(papers)} papers")
    print(f"Tag distribution ({len(all_tags)} unique tags):")
    for tag, count in sorted(all_tags.items(), key=lambda x: -x[1])[:20]:
        print(f"  {tag}: {count}")

    def refs_for_tags(tag_list):
        refs = []
        for pt in paper_tags:
            if pt['tags'] & set(tag_list):
                refs.append(pt['citation'])
        return sorted(set(refs))[:6]

    def refs_for_connection(from_tags, to_tags):
        """Get citations for papers matching BOTH from and to tag sets."""
        refs = []
        for pt in paper_tags:
            if pt['tags'] & set(from_tags) and pt['tags'] & set(to_tags):
                refs.append(pt['citation'])
        if len(refs) < 2:
            for pt in paper_tags:
                if pt['tags'] & (set(from_tags) | set(to_tags)):
                    refs.append(pt['citation'])
        return sorted(set(refs))[:6]

    kb = {
        "version": "1.1",
        "description": "Offshore Wind Parks SES DAPSIWRM knowledge database. Context-specific element and connection suggestions derived from 187 peer-reviewed papers. All connections follow valid DAPSIWRM transitions matching the main ses_knowledge_db.json schema.",
        "last_updated": "2026-04-09",
        "source_list": "https://lists.papersapp.com/Ys2NEa2TA8Ji",
        "n_papers": len(papers),
        "contexts": {}
    }

    # =========================================================================
    # CONTEXT 1: North Sea Fixed-Bottom Offshore Wind
    # =========================================================================
    kb["contexts"]["north_sea_offshore_wind"] = {
        "regional_sea": "north_sea",
        "habitat": "offshore_wind_farm",
        "description": "North Sea offshore wind farms (e.g., Dogger Bank, Horns Rev, Borssele). High-energy, shallow continental shelf with sandy/gravel seabeds, major shipping lanes, productive fisheries, and dense OWF development.",

        # ----- DRIVERS (D) -----
        # Root causes and fundamental needs motivating human activities
        "drivers": [
            {"name": "Renewable energy targets and climate policy (EU Green Deal, national NDCs)", "relevance": 0.98},
            {"name": "Energy security and fossil fuel independence", "relevance": 0.95},
            {"name": "Electricity demand from industry and households", "relevance": 0.90},
            {"name": "Economic growth and blue economy development", "relevance": 0.85},
            {"name": "Climate change and ocean warming", "relevance": 0.80},
            {"name": "Food security from North Sea fisheries", "relevance": 0.75},
            {"name": "Regional employment and industrial transition needs", "relevance": 0.80},
            # From main KB north_sea_offshore:
            {"name": "Sand and gravel resource demand for construction", "relevance": 0.55},
            {"name": "International shipping and trade growth", "relevance": 0.70},
        ],

        # ----- ACTIVITIES (A) -----
        # Human actions undertaken to meet driver needs
        "activities": [
            {"name": "Fixed-bottom offshore wind farm construction and operation", "relevance": 0.98},
            {"name": "Submarine cable laying and grid connection", "relevance": 0.90},
            {"name": "Turbine maintenance and vessel operations", "relevance": 0.85},
            {"name": "Wind farm decommissioning", "relevance": 0.60},
            {"name": "Commercial demersal trawl fisheries (sole, plaice, cod)", "relevance": 0.90},
            {"name": "Recreational angling near wind farms", "relevance": 0.70},
            {"name": "Offshore aquaculture and mariculture co-location", "relevance": 0.60},
            {"name": "Maritime shipping and navigation", "relevance": 0.80},
            {"name": "Seabed surveys and environmental monitoring", "relevance": 0.75},
            # From main KB north_sea_offshore:
            {"name": "Oil and gas platform operation and decommissioning", "relevance": 0.55},
            {"name": "Marine aggregate (sand/gravel) dredging", "relevance": 0.50},
        ],

        # ----- PRESSURES (P) -----
        # Environmental stressors created by activities
        "pressures": [
            {"name": "Underwater noise from pile driving during construction", "relevance": 0.95},
            {"name": "Seabed disturbance and habitat alteration from foundations and scour protection", "relevance": 0.90},
            {"name": "Exclusion of fishing vessels from wind farm safety zones", "relevance": 0.92},
            {"name": "Seabird collision risk and displacement from foraging areas", "relevance": 0.88},
            {"name": "Electromagnetic fields from submarine power cables", "relevance": 0.60},
            {"name": "Visual impact on coastal seascapes", "relevance": 0.70},
            {"name": "Barrier effects on marine mammal and fish migration routes", "relevance": 0.72},
            {"name": "Sediment plume and turbidity during construction", "relevance": 0.68},
            {"name": "Competition for marine space between wind, shipping and fishing", "relevance": 0.90},
            # From main KB north_sea_offshore:
            {"name": "Seabed disturbance from beam trawling", "relevance": 0.75},
            {"name": "Chronic hydrocarbon contamination from platforms", "relevance": 0.45},
        ],

        # ----- STATES / COMPONENTS (C) -----
        # Ecosystem elements affected by pressures
        "states": [
            {"name": "Marine mammal populations (harbour porpoise, harbour seal)", "relevance": 0.90},
            {"name": "Demersal fish community composition (cod, plaice, sole)", "relevance": 0.88},
            {"name": "Benthic epifaunal colonisation on turbine foundations", "relevance": 0.85},
            {"name": "Seabird populations (gannet, kittiwake, terns)", "relevance": 0.88},
            {"name": "Pelagic fish aggregation around structures", "relevance": 0.72},
            {"name": "Seabed sediment characteristics and soft-bottom infauna", "relevance": 0.78},
            {"name": "Food web structure and trophic interactions", "relevance": 0.68},
            {"name": "Reef effect communities on hard substrates (mussels, crabs, lobsters)", "relevance": 0.82},
            # From main KB north_sea_offshore:
            {"name": "Sandeel stock abundance and distribution", "relevance": 0.70},
            {"name": "North Sea herring stock biomass", "relevance": 0.65},
        ],

        # ----- ECOSYSTEM SERVICES (ES) = "impacts" in JSON -----
        # Benefits and functions provided by ecosystem components
        # C/S → ES: ecosystem state determines service provision
        "impacts": [
            {"name": "Fish stock provisioning for human consumption and fisheries", "relevance": 0.85},
            {"name": "Carbon emission avoidance through wind energy generation", "relevance": 0.92},
            {"name": "Reef habitat provision and enhanced local biodiversity (artificial reef effect)", "relevance": 0.78},
            {"name": "De facto marine refuge function (reduced fishing pressure)", "relevance": 0.72},
            {"name": "Coastal flood and wave energy regulation", "relevance": 0.48},
            {"name": "Cultural ecosystem services (seascape aesthetics, recreation)", "relevance": 0.62},
            # From main KB north_sea_offshore:
            {"name": "Seabird conservation value (public concern and stewardship)", "relevance": 0.60},
        ],

        # ----- GOODS & BENEFITS + HUMAN WELLBEING (GB/W/HW) = "welfare" in JSON -----
        # Tangible products, human welfare outcomes, and quality of life effects
        "welfare": [
            {"name": "Clean electricity supply to households and industry", "relevance": 0.95},
            {"name": "Employment in wind farm construction, operation and maintenance", "relevance": 0.90},
            {"name": "Fishing industry revenue and employment", "relevance": 0.85},
            {"name": "Fisher household income and livelihood security", "relevance": 0.88},
            {"name": "Coastal community economic diversification", "relevance": 0.75},
            {"name": "Energy affordability and price stability", "relevance": 0.78},
            {"name": "Tourism and recreation opportunities near coastal wind farms", "relevance": 0.58},
            {"name": "Cultural identity and heritage of fishing communities", "relevance": 0.70},
            {"name": "Property values and coastal aesthetics perception", "relevance": 0.52},
            {"name": "Social acceptance and public trust in wind energy", "relevance": 0.72},
            # From main KB north_sea_offshore:
            {"name": "Shipping and trade route services", "relevance": 0.65},
        ],

        # ----- RESPONSES + MEASURES (R/M) = "responses" in JSON -----
        # Policy responses, regulations, and concrete implementation actions
        "responses": [
            {"name": "Marine Spatial Planning and wind farm zoning", "relevance": 0.95},
            {"name": "Environmental Impact Assessment requirements", "relevance": 0.92},
            {"name": "Stakeholder engagement and fisheries consultation processes", "relevance": 0.90},
            {"name": "Compensation and mitigation funds for displaced fishers", "relevance": 0.85},
            {"name": "Nature-inclusive design requirements for foundations", "relevance": 0.78},
            {"name": "Biodiversity monitoring programmes (pre- and post-construction)", "relevance": 0.85},
            {"name": "EU Renewable Energy Directive and national energy targets", "relevance": 0.90},
            {"name": "Fisheries co-management and access agreements within wind farms", "relevance": 0.72},
            {"name": "Decommissioning regulations and liability frameworks", "relevance": 0.65},
            # From main KB north_sea_offshore — measures:
            {"name": "Underwater noise mitigation measures (bubble curtains, soft start)", "relevance": 0.85},
            {"name": "Seasonal construction windows for marine mammal protection", "relevance": 0.72},
            # From main KB north_sea_offshore:
            {"name": "Sandeel fishery closure zones (UK, Denmark)", "relevance": 0.60},
        ],

        # ----- CONNECTIONS -----
        # All follow valid DAPSIWRM transitions
        "connections": [

            # ==========================================
            # D → A: Drivers motivate Activities
            # ==========================================
            {
                "from": "Renewable energy targets and climate policy (EU Green Deal, national NDCs)",
                "from_type": "drivers",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "National and EU renewable energy targets directly drive the planning, consenting and construction of large-scale offshore wind farms",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "Energy security and fossil fuel independence",
                "from_type": "drivers",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Geopolitical concerns about fossil fuel dependence accelerate offshore wind deployment as a domestically controlled energy source",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "Regional employment and industrial transition needs",
                "from_type": "drivers",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Regions seek offshore wind investment for job creation and economic revitalisation of coastal and post-industrial areas",
                "references": refs_for_connection(['driver_economic', 'gb_employment'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Food security from North Sea fisheries",
                "from_type": "drivers",
                "to": "Commercial demersal trawl fisheries (sole, plaice, cod)",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Demand for seafood sustains commercial fishing effort in North Sea waters that overlap with wind farm zones",
                "references": refs_for_connection(['driver_food_security'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Electricity demand from industry and households",
                "from_type": "drivers",
                "to": "Submarine cable laying and grid connection",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Growing electricity demand requires grid infrastructure to connect offshore generation to onshore load centres",
                "references": refs_for_connection(['driver_energy_transition', 'gb_energy'], ['activity_grid_infrastructure']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "International shipping and trade growth",
                "from_type": "drivers",
                "to": "Maritime shipping and navigation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Increasing global trade volumes maintain dense shipping traffic through the North Sea, creating spatial conflicts with wind farm zones",
                "references": refs_for_connection(['activity_shipping'], ['pressure_displacement']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Economic growth and blue economy development",
                "from_type": "drivers",
                "to": "Offshore aquaculture and mariculture co-location",
                "to_type": "activities",
                "polarity": "+", "strength": "weak", "confidence": 3,
                "rationale": "Blue economy policies encourage multi-use of marine space, promoting aquaculture co-location within wind farm areas",
                "references": refs_for_connection(['driver_economic', 'activity_multi_use'], ['activity_aquaculture']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },

            # ==========================================
            # A → P: Activities cause Pressures
            # ==========================================
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Underwater noise from pile driving during construction",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Pile driving for monopile foundations produces high-intensity impulsive noise propagating tens of kilometres, affecting marine mammals and fish",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_noise']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Seabed disturbance and habitat alteration from foundations and scour protection",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Foundation installation and scour protection replace soft-bottom sediment with hard substrate, altering local habitat characteristics",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Exclusion of fishing vessels from wind farm safety zones",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Safety zones and operational restrictions exclude or limit fishing within wind farm boundaries, displacing effort to adjacent areas",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_displacement']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Seabird collision risk and displacement from foraging areas",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Rotating turbine blades pose collision risk to seabirds; operational turbines also displace birds from foraging habitat",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_bird_collision']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Submarine cable laying and grid connection",
                "from_type": "activities",
                "to": "Electromagnetic fields from submarine power cables",
                "to_type": "pressures",
                "polarity": "+", "strength": "weak", "confidence": 3,
                "rationale": "Subsea power cables emit electromagnetic fields that may affect electro-sensitive species such as elasmobranchs and some crustaceans",
                "references": refs_for_connection(['activity_grid_infrastructure'], ['pressure_emf']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Visual impact on coastal seascapes",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Turbines visible from shore alter seascapes and affect coastal residents' landscape perception",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_visual']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Competition for marine space between wind, shipping and fishing",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Wind farms occupy significant marine areas, intensifying spatial competition with established maritime sectors",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_displacement']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Sediment plume and turbidity during construction",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Foundation installation disturbs seabed sediments, creating turbidity plumes that affect water column light and sedimentation",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Barrier effects on marine mammal and fish migration routes",
                "to_type": "pressures",
                "polarity": "+", "strength": "weak", "confidence": 3,
                "rationale": "Large wind farm arrays may create physical or behavioural barriers to marine mammal and fish migration corridors",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_barrier', 'state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Commercial demersal trawl fisheries (sole, plaice, cod)",
                "from_type": "activities",
                "to": "Seabed disturbance from beam trawling",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Bottom trawling physically disturbs seabed sediments and benthic communities outside wind farm zones",
                "references": refs_for_connection(['activity_fishing'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },

            # ==========================================
            # P → P: Pressure interactions
            # ==========================================
            {
                "from": "Sediment plume and turbidity during construction",
                "from_type": "pressures",
                "to": "Seabed sediment characteristics and soft-bottom infauna",
                "to_type": "states",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Suspended sediments resettle beyond the direct construction footprint, smothering soft-bottom infauna and temporarily reducing benthic biomass",
                "references": refs_for_connection(['pressure_habitat'], ['state_benthos']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Exclusion of fishing vessels from wind farm safety zones",
                "from_type": "pressures",
                "to": "Competition for marine space between wind, shipping and fishing",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Fishing exclusion from wind farm areas concentrates displaced effort in remaining space, intensifying spatial competition with other users",
                "references": refs_for_connection(['pressure_displacement'], ['activity_fishing', 'activity_shipping']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },

            # ==========================================
            # P → C/S: Pressures affect State/Components
            # ==========================================
            {
                "from": "Underwater noise from pile driving during construction",
                "from_type": "pressures",
                "to": "Marine mammal populations (harbour porpoise, harbour seal)",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 4,
                "rationale": "Construction noise causes temporary threshold shifts in hearing, behavioural disturbance, and displacement of harbour porpoises from construction zones",
                "references": refs_for_connection(['pressure_noise'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Seabed disturbance and habitat alteration from foundations and scour protection",
                "from_type": "pressures",
                "to": "Benthic epifaunal colonisation on turbine foundations",
                "to_type": "states",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Introduction of hard substrate in sandy environments creates new habitat, enabling colonisation by epifaunal communities (mussels, anemones, crustaceans)",
                "references": refs_for_connection(['pressure_habitat'], ['state_benthos']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Seabed disturbance and habitat alteration from foundations and scour protection",
                "from_type": "pressures",
                "to": "Seabed sediment characteristics and soft-bottom infauna",
                "to_type": "states",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Foundation installation and cable trenching destroy existing soft-bottom infaunal communities within the direct footprint",
                "references": refs_for_connection(['pressure_habitat'], ['state_biodiversity']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Seabed disturbance and habitat alteration from foundations and scour protection",
                "from_type": "pressures",
                "to": "Reef effect communities on hard substrates (mussels, crabs, lobsters)",
                "to_type": "states",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Foundation structures and scour protection create artificial reef habitat, supporting edible crab, lobster and juvenile fish",
                "references": refs_for_connection(['pressure_habitat'], ['state_benthos', 'measure_habitat_enhancement']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Seabird collision risk and displacement from foraging areas",
                "from_type": "pressures",
                "to": "Seabird populations (gannet, kittiwake, terns)",
                "to_type": "states",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Cumulative collision mortality and displacement from foraging areas may cause population-level declines in sensitive species like kittiwake",
                "references": refs_for_connection(['pressure_bird_collision'], ['state_seabirds']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Exclusion of fishing vessels from wind farm safety zones",
                "from_type": "pressures",
                "to": "Demersal fish community composition (cod, plaice, sole)",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Reduced fishing pressure inside wind farms allows fish populations to recover, creating de facto refugia with spillover potential",
                "references": refs_for_connection(['pressure_displacement'], ['state_fish']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Barrier effects on marine mammal and fish migration routes",
                "from_type": "pressures",
                "to": "Marine mammal populations (harbour porpoise, harbour seal)",
                "to_type": "states",
                "polarity": "-", "strength": "weak", "confidence": 2,
                "rationale": "Large-scale wind farm arrays may disrupt movement corridors for harbour porpoise and seals between feeding and breeding areas",
                "references": refs_for_connection(['pressure_barrier'], ['state_marine_mammals']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Electromagnetic fields from submarine power cables",
                "from_type": "pressures",
                "to": "Demersal fish community composition (cod, plaice, sole)",
                "to_type": "states",
                "polarity": "-", "strength": "weak", "confidence": 2,
                "rationale": "EMF from cables may affect behaviour of electro-sensitive species, though population-level effects remain poorly documented",
                "references": refs_for_connection(['pressure_emf'], ['state_fish']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Seabed disturbance from beam trawling",
                "from_type": "pressures",
                "to": "Seabed sediment characteristics and soft-bottom infauna",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Beam trawling physically disrupts seabed structure and reduces benthic biomass and species diversity",
                "references": refs_for_connection(['activity_fishing', 'pressure_habitat'], ['state_biodiversity']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },

            # ==========================================
            # C/S → C/S: State-to-State interactions
            # ==========================================
            {
                "from": "Reef effect communities on hard substrates (mussels, crabs, lobsters)",
                "from_type": "states",
                "to": "Food web structure and trophic interactions",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "New reef communities provide prey resources and habitat complexity, enriching local food web structure around foundations",
                "references": refs_for_connection(['state_benthos', 'state_food_web'], ['es_ecosystem_services']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Benthic epifaunal colonisation on turbine foundations",
                "from_type": "states",
                "to": "Pelagic fish aggregation around structures",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Epifaunal communities on foundations attract pelagic fish through increased prey availability (FAD effect)",
                "references": refs_for_connection(['state_benthos'], ['state_fish']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Sandeel stock abundance and distribution",
                "from_type": "states",
                "to": "Seabird populations (gannet, kittiwake, terns)",
                "to_type": "states",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Sandeel availability is the primary driver of seabird breeding success for kittiwake, puffin and terns in the North Sea",
                "references": refs_for_connection(['state_fish'], ['state_seabirds']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Demersal fish community composition (cod, plaice, sole)",
                "from_type": "states",
                "to": "Food web structure and trophic interactions",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Demersal fish are key trophic links connecting benthic production to higher predators (seabirds, marine mammals)",
                "references": refs_for_connection(['state_fish'], ['state_food_web']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # ==========================================
            # C/S → ES: State provides Ecosystem Services
            # ==========================================
            {
                "from": "Demersal fish community composition (cod, plaice, sole)",
                "from_type": "states",
                "to": "Fish stock provisioning for human consumption and fisheries",
                "to_type": "impacts",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Healthy demersal fish populations sustain commercial fishery yields and food provision from the North Sea",
                "references": refs_for_connection(['state_fish'], ['es_fish_production']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Benthic epifaunal colonisation on turbine foundations",
                "from_type": "states",
                "to": "Reef habitat provision and enhanced local biodiversity (artificial reef effect)",
                "to_type": "impacts",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Established epifaunal communities on foundations provide reef ecosystem services including habitat provision and enhanced local productivity",
                "references": refs_for_connection(['state_benthos'], ['es_ecosystem_services']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Reef effect communities on hard substrates (mussels, crabs, lobsters)",
                "from_type": "states",
                "to": "De facto marine refuge function (reduced fishing pressure)",
                "to_type": "impacts",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Hard-substrate communities within exclusion zones function as marine refugia, supporting biodiversity without fishing disturbance",
                "references": refs_for_connection(['state_benthos', 'measure_spatial'], ['es_ecosystem_services']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Seabird populations (gannet, kittiwake, terns)",
                "from_type": "states",
                "to": "Seabird conservation value (public concern and stewardship)",
                "to_type": "impacts",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Seabird population status drives public conservation concern and willingness to support marine stewardship measures",
                "references": refs_for_connection(['state_seabirds'], ['es_ecosystem_services', 'hw_social_acceptance']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Pelagic fish aggregation around structures",
                "from_type": "states",
                "to": "Fish stock provisioning for human consumption and fisheries",
                "to_type": "impacts",
                "polarity": "+", "strength": "weak", "confidence": 2,
                "rationale": "Fish aggregation around wind farm structures may enhance local productivity but evidence of net fishery benefit through spillover is limited",
                "references": refs_for_connection(['state_fish'], ['es_fish_production']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },

            # ==========================================
            # ES → GB/W: Services supply Goods, Benefits, Welfare
            # ==========================================
            {
                "from": "Fish stock provisioning for human consumption and fisheries",
                "from_type": "impacts",
                "to": "Fishing industry revenue and employment",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Productive fish stocks directly sustain fishing industry catches, revenue and employment in North Sea ports",
                "references": refs_for_connection(['es_fish_production'], ['gb_economic', 'gb_employment']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Fish stock provisioning for human consumption and fisheries",
                "from_type": "impacts",
                "to": "Fisher household income and livelihood security",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Fishery productivity determines catch volumes and thus individual fisher incomes and household livelihood security",
                "references": refs_for_connection(['es_fish_production'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission avoidance through wind energy generation",
                "from_type": "impacts",
                "to": "Clean electricity supply to households and industry",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Each GW of offshore wind capacity displaces fossil fuel generation, providing clean electricity and reducing emissions",
                "references": refs_for_connection(['es_carbon', 'gb_energy'], ['hw_wellbeing']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission avoidance through wind energy generation",
                "from_type": "impacts",
                "to": "Employment in wind farm construction, operation and maintenance",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Wind energy generation sustains a supply chain of manufacturing, installation, and O&M jobs in coastal communities",
                "references": refs_for_connection(['gb_energy', 'gb_employment'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Cultural ecosystem services (seascape aesthetics, recreation)",
                "from_type": "impacts",
                "to": "Tourism and recreation opportunities near coastal wind farms",
                "to_type": "welfare",
                "polarity": "+", "strength": "weak", "confidence": 3,
                "rationale": "Wind farm tourism (boat trips, visitor centres) can create recreation opportunities, though seascape alteration may reduce other tourism appeal",
                "references": refs_for_connection(['es_ecosystem_services', 'activity_tourism'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Seabird conservation value (public concern and stewardship)",
                "from_type": "impacts",
                "to": "Social acceptance and public trust in wind energy",
                "to_type": "welfare",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Public concern over seabird collision and displacement can reduce social acceptance of wind farm projects",
                "references": refs_for_connection(['state_seabirds', 'hw_social_acceptance'], ['response_eia']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # ==========================================
            # W → D: Welfare feeds back to Drivers (completes loop)
            # ==========================================
            {
                "from": "Fisher household income and livelihood security",
                "from_type": "welfare",
                "to": "Food security from North Sea fisheries",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Fisher livelihood security reinforces community investment in and political demand for maintaining fishing access and food production from the North Sea",
                "references": refs_for_connection(['hw_wellbeing', 'gb_economic'], ['driver_food_security']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Clean electricity supply to households and industry",
                "from_type": "welfare",
                "to": "Renewable energy targets and climate policy (EU Green Deal, national NDCs)",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Demonstrated success of offshore wind reinforces policy ambition and public support for higher renewable energy targets",
                "references": refs_for_connection(['gb_energy', 'driver_energy_transition'], ['hw_social_acceptance']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Employment in wind farm construction, operation and maintenance",
                "from_type": "welfare",
                "to": "Regional employment and industrial transition needs",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Wind industry employment demonstrates economic potential, reinforcing regional demand for further offshore wind investment",
                "references": refs_for_connection(['gb_employment'], ['driver_economic']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Cultural identity and heritage of fishing communities",
                "from_type": "welfare",
                "to": "Food security from North Sea fisheries",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Cultural attachment to fishing heritage reinforces community advocacy for maintaining fisheries access against competing spatial claims",
                "references": refs_for_connection(['hw_cultural', 'hw_conflict'], ['driver_food_security']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },

            # ==========================================
            # R → A: Responses regulate Activities
            # ==========================================
            {
                "from": "Marine Spatial Planning and wind farm zoning",
                "from_type": "responses",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "MSP designates wind energy areas, enabling development while attempting to minimise conflicts with other sea uses",
                "references": refs_for_connection(['response_msp'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Fisheries co-management and access agreements within wind farms",
                "from_type": "responses",
                "to": "Commercial demersal trawl fisheries (sole, plaice, cod)",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Co-management arrangements allow certain fishing methods to continue within wind farm areas under agreed conditions, maintaining fishing activity",
                "references": refs_for_connection(['response_stakeholder'], ['activity_fishing', 'activity_multi_use']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Sandeel fishery closure zones (UK, Denmark)",
                "from_type": "responses",
                "to": "Commercial demersal trawl fisheries (sole, plaice, cod)",
                "to_type": "activities",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Sandeel closures restrict industrial fishing effort, protecting key prey species for seabirds and marine mammals",
                "references": refs_for_connection(['measure_spatial'], ['activity_fishing', 'state_seabirds']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "EU Renewable Energy Directive and national energy targets",
                "from_type": "responses",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Binding renewable energy targets and support mechanisms (CfD, auctions) directly accelerate wind farm development",
                "references": refs_for_connection(['response_regulation', 'response_subsidy'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },

            # ==========================================
            # R → P: Responses mitigate Pressures
            # ==========================================
            {
                "from": "Underwater noise mitigation measures (bubble curtains, soft start)",
                "from_type": "responses",
                "to": "Underwater noise from pile driving during construction",
                "to_type": "pressures",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Bubble curtains and soft-start procedures reduce peak sound pressure levels by 10-20 dB, significantly lowering noise exposure for marine mammals",
                "references": refs_for_connection(['measure_noise_mitigation'], ['pressure_noise']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Compensation and mitigation funds for displaced fishers",
                "from_type": "responses",
                "to": "Commercial demersal trawl fisheries (sole, plaice, cod)",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Financial compensation and mitigation funds support continued fishing fleet viability, enabling fishers to adapt to displacement by investing in gear, fuel and alternative grounds",
                "references": refs_for_connection(['response_mitigation', 'response_stakeholder'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Nature-inclusive design requirements for foundations",
                "from_type": "responses",
                "to": "Seabed disturbance and habitat alteration from foundations and scour protection",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Nature-inclusive design features (textured surfaces, reef elements) transform habitat alteration pressure into an ecological opportunity by promoting colonisation",
                "references": refs_for_connection(['response_mitigation', 'measure_habitat_enhancement'], ['pressure_habitat']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Seasonal construction windows for marine mammal protection",
                "from_type": "responses",
                "to": "Underwater noise from pile driving during construction",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Restricting pile driving to periods of low marine mammal abundance reduces noise exposure during critical breeding and nursing seasons",
                "references": refs_for_connection(['measure_temporal'], ['pressure_noise', 'state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Environmental Impact Assessment requirements",
                "from_type": "responses",
                "to": "Visual impact on coastal seascapes",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "EIA visual impact assessment requirements influence turbine siting and distance from shore, reducing landscape impacts",
                "references": refs_for_connection(['response_eia'], ['pressure_visual']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },

            # ==========================================
            # R → C: Responses restore/protect State
            # ==========================================
            {
                "from": "Nature-inclusive design requirements for foundations",
                "from_type": "responses",
                "to": "Benthic epifaunal colonisation on turbine foundations",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Nature-inclusive design features (textured surfaces, reef elements) enhance epifaunal colonisation and biodiversity on foundation structures",
                "references": refs_for_connection(['response_mitigation', 'measure_habitat_enhancement'], ['state_benthos']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Biodiversity monitoring programmes (pre- and post-construction)",
                "from_type": "responses",
                "to": "Seabird populations (gannet, kittiwake, terns)",
                "to_type": "states",
                "polarity": "+", "strength": "weak", "confidence": 3,
                "rationale": "Monitoring programmes enable adaptive management (e.g., turbine curtailment) that reduces seabird collision mortality and displacement",
                "references": refs_for_connection(['response_monitoring'], ['state_seabirds', 'pressure_bird_collision']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },

            # ==========================================
            # R → D: Responses influence Drivers
            # ==========================================
            {
                "from": "EU Renewable Energy Directive and national energy targets",
                "from_type": "responses",
                "to": "Renewable energy targets and climate policy (EU Green Deal, national NDCs)",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Policy instruments translate climate commitments into binding targets that reinforce and amplify the energy transition driver",
                "references": refs_for_connection(['response_regulation'], ['driver_energy_transition']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
        ]
    }

    # =========================================================================
    # CONTEXT 2: Atlantic / Mediterranean Floating Offshore Wind
    # =========================================================================
    kb["contexts"]["atlantic_floating_wind"] = {
        "regional_sea": "atlantic",
        "habitat": "deep_water_offshore_wind",
        "description": "Atlantic and Mediterranean floating offshore wind developments (e.g., Utsira Nord, Celtic Sea, Canary Islands, Gulf of Lion). Deep-water sites with high wind resources, pelagic fisheries, and cetacean populations requiring floating foundation technology.",

        "drivers": [
            {"name": "National renewable energy and net-zero targets", "relevance": 0.98},
            {"name": "Deep-water wind resource exploitation beyond fixed-bottom limits", "relevance": 0.95},
            {"name": "Energy security through domestic generation", "relevance": 0.90},
            {"name": "Coastal economic regeneration and just transition needs", "relevance": 0.82},
            {"name": "Climate change mitigation obligations (Paris Agreement)", "relevance": 0.88},
            {"name": "Technological maturation of floating platform concepts", "relevance": 0.85},
        ],

        "activities": [
            {"name": "Floating offshore wind farm deployment and operation", "relevance": 0.98},
            {"name": "Dynamic cable installation and maintenance", "relevance": 0.85},
            {"name": "Pelagic and demersal fisheries in deep waters", "relevance": 0.85},
            {"name": "Cetacean watching and marine ecotourism", "relevance": 0.60},
            {"name": "Port development and supply chain logistics", "relevance": 0.80},
            {"name": "Environmental baseline and monitoring surveys", "relevance": 0.75},
        ],

        "pressures": [
            {"name": "Mooring system entanglement risk for marine mammals and sea turtles", "relevance": 0.72},
            {"name": "Displacement of pelagic fishing effort from wind farm zones", "relevance": 0.85},
            {"name": "Operational noise from floating platform motion and mooring", "relevance": 0.65},
            {"name": "Seabird collision risk at deep-water sites", "relevance": 0.78},
            {"name": "Anchor and mooring seabed disturbance", "relevance": 0.62},
            {"name": "Visual impact from floating structures", "relevance": 0.50},
        ],

        "states": [
            {"name": "Cetacean populations (dolphins, fin whales, sperm whales)", "relevance": 0.88},
            {"name": "Pelagic fish stocks (mackerel, horse mackerel, tuna)", "relevance": 0.82},
            {"name": "Deep-sea benthic communities at anchor points", "relevance": 0.60},
            {"name": "Seabird foraging ecology (shearwaters, petrels, storm-petrels)", "relevance": 0.78},
            {"name": "Biofouling communities on floating structures and mooring lines", "relevance": 0.68},
        ],

        "impacts": [
            {"name": "Carbon emission reduction from floating wind generation", "relevance": 0.95},
            {"name": "Pelagic fish aggregation around floating structures (FAD effect)", "relevance": 0.58},
            {"name": "Stepping-stone habitat for non-native biofouling species", "relevance": 0.52},
            {"name": "Pelagic fishery provisioning from deep waters", "relevance": 0.75},
        ],

        "welfare": [
            {"name": "Clean energy from deep-water wind resources", "relevance": 0.95},
            {"name": "Port community employment and skills development", "relevance": 0.88},
            {"name": "Deep-water fishers' livelihood security", "relevance": 0.80},
            {"name": "Regional supply chain development and economic diversification", "relevance": 0.82},
            {"name": "Energy price stability for consumers", "relevance": 0.72},
            {"name": "Social acceptance in coastal communities", "relevance": 0.68},
        ],

        "responses": [
            {"name": "Marine Spatial Planning for floating wind zones", "relevance": 0.92},
            {"name": "Floating wind environmental consenting frameworks", "relevance": 0.88},
            {"name": "Fisheries displacement assessment and compensation schemes", "relevance": 0.85},
            {"name": "Adaptive management and monitoring protocols", "relevance": 0.80},
            {"name": "Just transition and community benefit funds", "relevance": 0.78},
            {"name": "International cooperation on transboundary environmental effects", "relevance": 0.62},
            {"name": "Entanglement risk mitigation for mooring systems", "relevance": 0.65},
        ],

        "connections": [
            # D → A
            {
                "from": "National renewable energy and net-zero targets",
                "from_type": "drivers",
                "to": "Floating offshore wind farm deployment and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Deep-water wind resources accessed through floating technology are essential to meet ambitious national renewable energy targets where shallow waters are exhausted",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "Coastal economic regeneration and just transition needs",
                "from_type": "drivers",
                "to": "Port development and supply chain logistics",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Regional economic development ambitions drive port infrastructure investment and supply chain localisation for floating wind",
                "references": refs_for_connection(['driver_economic', 'gb_employment'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Technological maturation of floating platform concepts",
                "from_type": "drivers",
                "to": "Floating offshore wind farm deployment and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Demonstration projects (Hywind, WindFloat) have de-risked floating technology, enabling commercial-scale deployment",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "short-term", "reversibility": "irreversible"
            },

            # A → P
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Displacement of pelagic fishing effort from wind farm zones",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Floating wind installations in deep waters overlap with pelagic fishing grounds, causing spatial displacement of fishing fleets",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_displacement', 'activity_fishing']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Seabird collision risk at deep-water sites",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Floating turbines in pelagic waters may pose collision risk to shearwaters and petrels with different flight behaviours than nearshore species",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_bird_collision', 'state_seabirds']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Mooring system entanglement risk for marine mammals and sea turtles",
                "to_type": "pressures",
                "polarity": "+", "strength": "weak", "confidence": 2,
                "rationale": "Dynamic mooring lines and inter-array cables present potential entanglement hazards for cetaceans, though documented incidents are rare",
                "references": refs_for_connection(['activity_offshore_wind'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Anchor and mooring seabed disturbance",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Drag anchors and suction caissons disturb deep-sea benthic habitats at anchor points and along mooring chain sweeps",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },

            # P → C
            {
                "from": "Displacement of pelagic fishing effort from wind farm zones",
                "from_type": "pressures",
                "to": "Pelagic fish stocks (mackerel, horse mackerel, tuna)",
                "to_type": "states",
                "polarity": "+", "strength": "weak", "confidence": 2,
                "rationale": "Reduced fishing pressure within floating wind zones may allow localised recovery of pelagic stocks, though migratory species benefit less from spatial closures",
                "references": refs_for_connection(['pressure_displacement'], ['state_fish']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Seabird collision risk at deep-water sites",
                "from_type": "pressures",
                "to": "Seabird foraging ecology (shearwaters, petrels, storm-petrels)",
                "to_type": "states",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Collision mortality and displacement from foraging areas may affect pelagic seabird populations, particularly for species with low reproductive rates",
                "references": refs_for_connection(['pressure_bird_collision'], ['state_seabirds']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Mooring system entanglement risk for marine mammals and sea turtles",
                "from_type": "pressures",
                "to": "Cetacean populations (dolphins, fin whales, sperm whales)",
                "to_type": "states",
                "polarity": "-", "strength": "weak", "confidence": 2,
                "rationale": "Entanglement risk from mooring systems is poorly quantified but could affect individual cetaceans, particularly large baleen whales",
                "references": refs_for_connection(['state_marine_mammals'], ['pressure_barrier']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },

            # C → ES
            {
                "from": "Pelagic fish stocks (mackerel, horse mackerel, tuna)",
                "from_type": "states",
                "to": "Pelagic fishery provisioning from deep waters",
                "to_type": "impacts",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Healthy pelagic stocks sustain commercial fishery catches and food provisioning from Atlantic waters",
                "references": refs_for_connection(['state_fish'], ['es_fish_production']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # ES → W
            {
                "from": "Carbon emission reduction from floating wind generation",
                "from_type": "impacts",
                "to": "Clean energy from deep-water wind resources",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Floating wind generation displaces fossil fuels, providing clean electricity from previously inaccessible deep-water resources",
                "references": refs_for_connection(['gb_energy'], ['driver_energy_transition']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Pelagic fishery provisioning from deep waters",
                "from_type": "impacts",
                "to": "Deep-water fishers' livelihood security",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Pelagic fishery productivity determines deep-water fleet catches, revenues and fisher livelihood security",
                "references": refs_for_connection(['es_fish_production'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission reduction from floating wind generation",
                "from_type": "impacts",
                "to": "Port community employment and skills development",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Floating wind energy supply chain creates jobs in port assembly, O&M, and specialised skills development",
                "references": refs_for_connection(['gb_employment'], ['gb_energy']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },

            # W → D (feedback)
            {
                "from": "Deep-water fishers' livelihood security",
                "from_type": "welfare",
                "to": "Coastal economic regeneration and just transition needs",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Threatened fisher livelihoods amplify community demand for just transition policies and economic regeneration support",
                "references": refs_for_connection(['hw_wellbeing', 'hw_justice'], ['driver_economic']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Clean energy from deep-water wind resources",
                "from_type": "welfare",
                "to": "National renewable energy and net-zero targets",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Successful floating wind deployment demonstrates viability, reinforcing political ambition for higher renewable targets",
                "references": refs_for_connection(['gb_energy', 'driver_energy_transition'], ['hw_social_acceptance']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Port community employment and skills development",
                "from_type": "welfare",
                "to": "Coastal economic regeneration and just transition needs",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Wind industry employment success reinforces regional demand for further renewable energy investment and port development",
                "references": refs_for_connection(['gb_employment'], ['driver_economic']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },

            # R → A
            {
                "from": "Marine Spatial Planning for floating wind zones",
                "from_type": "responses",
                "to": "Floating offshore wind farm deployment and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "MSP designation of deep-water wind energy areas enables floating wind development while managing spatial conflicts",
                "references": refs_for_connection(['response_msp'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Fisheries displacement assessment and compensation schemes",
                "from_type": "responses",
                "to": "Pelagic and demersal fisheries in deep waters",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Displacement assessments and compensation support continued fishing viability by formalising mitigation for lost grounds",
                "references": refs_for_connection(['response_stakeholder', 'response_mitigation'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # R → P
            {
                "from": "Entanglement risk mitigation for mooring systems",
                "from_type": "responses",
                "to": "Mooring system entanglement risk for marine mammals and sea turtles",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Design modifications to mooring configurations and use of whale-safe materials can reduce entanglement probability",
                "references": refs_for_connection(['response_mitigation'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Adaptive management and monitoring protocols",
                "from_type": "responses",
                "to": "Seabird collision risk at deep-water sites",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Adaptive management enables turbine curtailment during peak seabird migration and real-time collision monitoring to reduce mortality",
                "references": refs_for_connection(['response_monitoring'], ['pressure_bird_collision']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
        ]
    }

    # =========================================================================
    # CONTEXT 3: Baltic Sea Offshore Wind
    # =========================================================================
    kb["contexts"]["baltic_offshore_wind"] = {
        "regional_sea": "baltic",
        "habitat": "offshore_wind_farm",
        "description": "Baltic Sea offshore wind farms (e.g., Kriegers Flak, Arkona Basin, Gotland, Lithuanian EEZ). Semi-enclosed, brackish sea with permanent halocline, deep-water hypoxia, declining cod stocks, dense shipping traffic, and rapid OWF expansion under HELCOM and EU targets.",

        "drivers": [
            {"name": "EU and national renewable energy targets for Baltic states", "relevance": 0.95},
            {"name": "Energy security and independence from Russian gas", "relevance": 0.92},
            {"name": "Demand for Baltic cod, herring and sprat fisheries", "relevance": 0.85},
            {"name": "Climate change mitigation goals (HELCOM, EU)", "relevance": 0.80},
            {"name": "Maritime shipping route demand through Baltic", "relevance": 0.78},
            {"name": "Regional employment in coastal communities", "relevance": 0.75},
            # From main KB baltic_offshore:
            {"name": "Sand and aggregate resource needs", "relevance": 0.50},
        ],

        "activities": [
            {"name": "Fixed-bottom offshore wind farm construction and operation", "relevance": 0.95},
            {"name": "Submarine cable laying and grid interconnection", "relevance": 0.88},
            {"name": "Demersal trawling for Baltic cod", "relevance": 0.85},
            {"name": "Pelagic fishing for herring and sprat", "relevance": 0.88},
            {"name": "Merchant shipping and ferry traffic", "relevance": 0.80},
            {"name": "Environmental monitoring and baseline surveys", "relevance": 0.72},
            {"name": "Turbine maintenance and service vessel operations", "relevance": 0.80},
            # From main KB baltic_offshore:
            {"name": "Submarine cable and pipeline installation", "relevance": 0.60},
        ],

        "pressures": [
            {"name": "Underwater noise from pile driving during construction", "relevance": 0.95},
            {"name": "Seabed disturbance and habitat alteration from foundations", "relevance": 0.88},
            {"name": "Exclusion of fishing vessels from wind farm safety zones", "relevance": 0.90},
            {"name": "Bycatch risk for harbour porpoise and seabirds in displaced fisheries", "relevance": 0.82},
            {"name": "Seabird collision risk and displacement (long-tailed duck, divers)", "relevance": 0.85},
            {"name": "Electromagnetic fields from submarine cables", "relevance": 0.58},
            {"name": "Competition for marine space with shipping lanes", "relevance": 0.85},
            {"name": "Sediment plume and turbidity during construction", "relevance": 0.65},
            # From main KB baltic_offshore:
            {"name": "Overfishing of Eastern Baltic cod", "relevance": 0.82},
            {"name": "Seabed disturbance from bottom trawling", "relevance": 0.78},
            {"name": "Contamination from dumped munitions legacy", "relevance": 0.48},
        ],

        "states": [
            {"name": "Baltic harbour porpoise population (critically low in Baltic Proper)", "relevance": 0.92},
            {"name": "Eastern Baltic cod stock biomass", "relevance": 0.90},
            {"name": "Central Baltic herring recruitment", "relevance": 0.82},
            {"name": "Seabird populations (long-tailed duck, red-throated diver, common scoter)", "relevance": 0.85},
            {"name": "Benthic community colonisation on foundations in brackish water", "relevance": 0.75},
            {"name": "Seabed sediment and soft-bottom infauna", "relevance": 0.72},
            # From main KB baltic_offshore:
            {"name": "Deep-water hypoxia extent (dead zones)", "relevance": 0.80},
            {"name": "Halocline dynamics and deep-water renewal", "relevance": 0.68},
            {"name": "Benthic macrofauna in deep basins", "relevance": 0.65},
        ],

        "impacts": [
            {"name": "Commercial fish stock provision (cod, herring, sprat)", "relevance": 0.90},
            {"name": "Carbon emission avoidance through Baltic wind energy", "relevance": 0.90},
            {"name": "Reef habitat creation on foundations in sediment-dominated sea", "relevance": 0.70},
            {"name": "De facto marine refuge in wind farm exclusion zones", "relevance": 0.68},
            # From main KB baltic_offshore:
            {"name": "Climate regulation through carbon cycling", "relevance": 0.55},
        ],

        "welfare": [
            {"name": "Baltic fishing fleet economic viability", "relevance": 0.88},
            {"name": "Energy security from Baltic offshore wind farms", "relevance": 0.92},
            {"name": "Fisher household income and livelihood security", "relevance": 0.85},
            {"name": "Employment in wind farm construction and O&M", "relevance": 0.88},
            {"name": "Renewable electricity generation capacity", "relevance": 0.90},
            {"name": "Coastal community economic diversification", "relevance": 0.72},
            # From main KB baltic_offshore:
            {"name": "Fish processing industry employment", "relevance": 0.68},
            {"name": "Maritime trade revenue", "relevance": 0.62},
        ],

        "responses": [
            {"name": "Maritime spatial planning for wind and fisheries (HELCOM/VASAB)", "relevance": 0.95},
            {"name": "Environmental Impact Assessment with cumulative effects", "relevance": 0.90},
            {"name": "Harbour porpoise bycatch mitigation (pingers, acoustic deterrents)", "relevance": 0.85},
            {"name": "Underwater noise mitigation requirements (bubble curtains)", "relevance": 0.88},
            {"name": "Seasonal construction restrictions for porpoise and bird protection", "relevance": 0.80},
            {"name": "Fisheries compensation and co-existence agreements", "relevance": 0.82},
            {"name": "HELCOM Baltic Sea Action Plan", "relevance": 0.85},
            {"name": "EU Renewable Energy Directive Baltic implementation", "relevance": 0.88},
            # From main KB baltic_offshore:
            {"name": "Baltic cod fishing quota reductions (EU TAC)", "relevance": 0.82},
            {"name": "Trawling closure zones in spawning areas", "relevance": 0.75},
        ],

        "connections": [
            # D → A
            {
                "from": "EU and national renewable energy targets for Baltic states",
                "from_type": "drivers",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Baltic states' binding renewable targets under EU RED drive rapid offshore wind development in shallow Baltic waters",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "Energy security and independence from Russian gas",
                "from_type": "drivers",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Post-2022 geopolitical shift accelerated Baltic offshore wind as domestic energy alternative to Russian pipeline gas",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "short-term", "reversibility": "irreversible"
            },
            {
                "from": "Demand for Baltic cod, herring and sprat fisheries",
                "from_type": "drivers",
                "to": "Demersal trawling for Baltic cod",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Market demand sustains commercial fishing effort despite declining cod stocks and spatial competition from wind farms",
                "references": refs_for_connection(['driver_food_security'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Demand for Baltic cod, herring and sprat fisheries",
                "from_type": "drivers",
                "to": "Pelagic fishing for herring and sprat",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Herring and sprat remain economically important Baltic fisheries sustaining fleet viability",
                "references": refs_for_connection(['driver_food_security'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Maritime shipping route demand through Baltic",
                "from_type": "drivers",
                "to": "Merchant shipping and ferry traffic",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Increasing Baltic trade and passenger ferry traffic creates spatial competition with wind farm zones",
                "references": refs_for_connection(['activity_shipping'], ['pressure_displacement']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # A → P
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Underwater noise from pile driving during construction",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Pile driving in the shallow Baltic propagates noise efficiently through the water column, critically affecting the small Baltic harbour porpoise population",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_noise']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Seabed disturbance and habitat alteration from foundations",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Foundation installation alters Baltic sandy/muddy seabed, introducing hard substrate in a sea with naturally limited hard bottom habitat",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Exclusion of fishing vessels from wind farm safety zones",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Wind farm safety zones in the relatively shallow Baltic exclude fishing from significant areas of traditional grounds",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_displacement']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Seabird collision risk and displacement (long-tailed duck, divers)",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Baltic wintering seabirds (long-tailed duck, scoters, divers) are particularly sensitive to wind farm displacement from foraging areas",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_bird_collision', 'state_seabirds']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Demersal trawling for Baltic cod",
                "from_type": "activities",
                "to": "Overfishing of Eastern Baltic cod",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Continued trawling effort on the collapsed Eastern Baltic cod stock maintains fishing mortality above sustainable levels",
                "references": refs_for_connection(['activity_fishing'], ['state_fish']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Demersal trawling for Baltic cod",
                "from_type": "activities",
                "to": "Seabed disturbance from bottom trawling",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Bottom trawling physically disturbs Baltic seabed sediments and benthic communities",
                "references": refs_for_connection(['activity_fishing'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Fixed-bottom offshore wind farm construction and operation",
                "from_type": "activities",
                "to": "Competition for marine space with shipping lanes",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Wind farms in the narrow, heavily trafficked Baltic Sea create significant routing constraints for merchant vessels and ferries",
                "references": refs_for_connection(['activity_offshore_wind', 'activity_shipping'], ['pressure_displacement']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },

            # P → P
            {
                "from": "Exclusion of fishing vessels from wind farm safety zones",
                "from_type": "pressures",
                "to": "Bycatch risk for harbour porpoise and seabirds in displaced fisheries",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Fishing effort displaced from wind farms may concentrate gillnet activity in areas used by harbour porpoise, increasing bycatch risk",
                "references": refs_for_connection(['pressure_displacement'], ['state_marine_mammals', 'state_seabirds']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # P → C
            {
                "from": "Underwater noise from pile driving during construction",
                "from_type": "pressures",
                "to": "Baltic harbour porpoise population (critically low in Baltic Proper)",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "The Baltic Proper harbour porpoise population (~500 individuals) is critically endangered; construction noise causes displacement and hearing damage at population-significant scales",
                "references": refs_for_connection(['pressure_noise'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Seabed disturbance and habitat alteration from foundations",
                "from_type": "pressures",
                "to": "Benthic community colonisation on foundations in brackish water",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Hard substrate introduction enables epifaunal colonisation, though Baltic brackish conditions limit diversity compared to marine environments",
                "references": refs_for_connection(['pressure_habitat'], ['state_benthos']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Seabird collision risk and displacement (long-tailed duck, divers)",
                "from_type": "pressures",
                "to": "Seabird populations (long-tailed duck, red-throated diver, common scoter)",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 4,
                "rationale": "Millions of wintering seabirds in the Baltic are displaced from wind farm areas; long-tailed duck show near-complete avoidance of turbine arrays",
                "references": refs_for_connection(['pressure_bird_collision'], ['state_seabirds']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Overfishing of Eastern Baltic cod",
                "from_type": "pressures",
                "to": "Eastern Baltic cod stock biomass",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Decades of overfishing combined with poor environmental conditions have driven Eastern Baltic cod to near-collapse",
                "references": refs_for_connection(['activity_fishing'], ['state_fish']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Exclusion of fishing vessels from wind farm safety zones",
                "from_type": "pressures",
                "to": "Eastern Baltic cod stock biomass",
                "to_type": "states",
                "polarity": "+", "strength": "weak", "confidence": 2,
                "rationale": "Fishing exclusion within wind farms may provide limited refuge for cod, though stock recovery depends on broader environmental conditions (hypoxia, salinity)",
                "references": refs_for_connection(['pressure_displacement'], ['state_fish']),
                "temporal_lag": "long-term", "reversibility": "reversible"
            },
            {
                "from": "Bycatch risk for harbour porpoise and seabirds in displaced fisheries",
                "from_type": "pressures",
                "to": "Baltic harbour porpoise population (critically low in Baltic Proper)",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 4,
                "rationale": "Even low levels of gillnet bycatch are significant for the critically small Baltic Proper porpoise population",
                "references": refs_for_connection(['state_marine_mammals'], ['response_mitigation']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Seabed disturbance from bottom trawling",
                "from_type": "pressures",
                "to": "Seabed sediment and soft-bottom infauna",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Repeated trawling reduces benthic biomass and shifts community composition toward opportunistic species",
                "references": refs_for_connection(['activity_fishing', 'pressure_habitat'], ['state_biodiversity']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },

            # C → C
            {
                "from": "Deep-water hypoxia extent (dead zones)",
                "from_type": "states",
                "to": "Eastern Baltic cod stock biomass",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Expanding hypoxic zones reduce cod spawning habitat and egg survival, compounding the effects of overfishing on stock recovery",
                "references": refs_for_connection(['driver_climate_change'], ['state_fish']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Eastern Baltic cod stock biomass",
                "from_type": "states",
                "to": "Central Baltic herring recruitment",
                "to_type": "states",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Cod collapse may release herring and sprat from predation, altering pelagic community balance (trophic cascade)",
                "references": refs_for_connection(['state_fish'], ['state_food_web']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },

            # C → ES
            {
                "from": "Eastern Baltic cod stock biomass",
                "from_type": "states",
                "to": "Commercial fish stock provision (cod, herring, sprat)",
                "to_type": "impacts",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Cod stock status directly determines allowable catch and fishery provisioning from the Baltic",
                "references": refs_for_connection(['state_fish'], ['es_fish_production']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Central Baltic herring recruitment",
                "from_type": "states",
                "to": "Commercial fish stock provision (cod, herring, sprat)",
                "to_type": "impacts",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Herring and sprat are the most valuable remaining Baltic fisheries, with stock status governing quota allocation",
                "references": refs_for_connection(['state_fish'], ['es_fish_production']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Benthic community colonisation on foundations in brackish water",
                "from_type": "states",
                "to": "Reef habitat creation on foundations in sediment-dominated sea",
                "to_type": "impacts",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Epifaunal communities on Baltic wind farm foundations provide rare hard-substrate habitat in a sea naturally dominated by soft sediments",
                "references": refs_for_connection(['state_benthos'], ['es_ecosystem_services']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },

            # ES → W
            {
                "from": "Commercial fish stock provision (cod, herring, sprat)",
                "from_type": "impacts",
                "to": "Baltic fishing fleet economic viability",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Fish stock productivity determines quota levels, catch volumes and fishing fleet revenue across Baltic states",
                "references": refs_for_connection(['es_fish_production'], ['gb_economic']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Commercial fish stock provision (cod, herring, sprat)",
                "from_type": "impacts",
                "to": "Fisher household income and livelihood security",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Fisher incomes depend directly on catch volumes enabled by stock productivity",
                "references": refs_for_connection(['es_fish_production'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission avoidance through Baltic wind energy",
                "from_type": "impacts",
                "to": "Energy security from Baltic offshore wind farms",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Baltic offshore wind provides domestically generated clean electricity, enhancing energy security for Baltic states",
                "references": refs_for_connection(['gb_energy'], ['driver_energy_transition']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission avoidance through Baltic wind energy",
                "from_type": "impacts",
                "to": "Employment in wind farm construction and O&M",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Baltic wind energy supply chain creates manufacturing, installation and maintenance jobs in coastal communities",
                "references": refs_for_connection(['gb_energy', 'gb_employment'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },

            # W → D (feedback loops)
            {
                "from": "Baltic fishing fleet economic viability",
                "from_type": "welfare",
                "to": "Demand for Baltic cod, herring and sprat fisheries",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Fleet viability maintains political and economic demand for continued Baltic fisheries access despite spatial competition",
                "references": refs_for_connection(['gb_economic'], ['driver_food_security']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Energy security from Baltic offshore wind farms",
                "from_type": "welfare",
                "to": "EU and national renewable energy targets for Baltic states",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Demonstrated energy security benefits reinforce political ambition for higher Baltic offshore wind targets",
                "references": refs_for_connection(['gb_energy'], ['driver_energy_transition']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Fisher household income and livelihood security",
                "from_type": "welfare",
                "to": "Demand for Baltic cod, herring and sprat fisheries",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Fisher livelihood pressures reinforce community advocacy for maintaining fishing access against competing wind farm claims",
                "references": refs_for_connection(['hw_wellbeing', 'hw_conflict'], ['driver_food_security']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # R → A
            {
                "from": "Maritime spatial planning for wind and fisheries (HELCOM/VASAB)",
                "from_type": "responses",
                "to": "Fixed-bottom offshore wind farm construction and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "HELCOM/VASAB cross-border MSP designates wind energy zones in the Baltic, enabling coordinated multinational development",
                "references": refs_for_connection(['response_msp'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Baltic cod fishing quota reductions (EU TAC)",
                "from_type": "responses",
                "to": "Demersal trawling for Baltic cod",
                "to_type": "activities",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "EU TAC reductions and fishing moratoria directly constrain Baltic cod fishing effort",
                "references": refs_for_connection(['response_regulation'], ['activity_fishing']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Trawling closure zones in spawning areas",
                "from_type": "responses",
                "to": "Demersal trawling for Baltic cod",
                "to_type": "activities",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Spatial closures in cod spawning areas restrict trawling, complementing wind farm exclusion zones in reducing fishing pressure",
                "references": refs_for_connection(['measure_spatial'], ['activity_fishing']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },

            # R → P
            {
                "from": "Underwater noise mitigation requirements (bubble curtains)",
                "from_type": "responses",
                "to": "Underwater noise from pile driving during construction",
                "to_type": "pressures",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Germany and Denmark mandate bubble curtain noise thresholds for Baltic construction, critical for harbour porpoise protection",
                "references": refs_for_connection(['measure_noise_mitigation'], ['pressure_noise']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Harbour porpoise bycatch mitigation (pingers, acoustic deterrents)",
                "from_type": "responses",
                "to": "Bycatch risk for harbour porpoise and seabirds in displaced fisheries",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Acoustic deterrents on gillnets reduce harbour porpoise bycatch in areas receiving displaced fishing effort",
                "references": refs_for_connection(['response_mitigation'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Seasonal construction restrictions for porpoise and bird protection",
                "from_type": "responses",
                "to": "Underwater noise from pile driving during construction",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "Seasonal windows restrict pile driving during harbour porpoise calving (May-Aug) and seabird wintering periods",
                "references": refs_for_connection(['measure_temporal'], ['pressure_noise', 'state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Fisheries compensation and co-existence agreements",
                "from_type": "responses",
                "to": "Exclusion of fishing vessels from wind farm safety zones",
                "to_type": "pressures",
                "polarity": "-", "strength": "weak", "confidence": 3,
                "rationale": "Co-existence agreements may allow passive gear fishing within Baltic wind farms, reducing effective exclusion area",
                "references": refs_for_connection(['response_stakeholder', 'response_mitigation'], ['pressure_displacement']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # R → C: Responses restore/protect State
            {
                "from": "Harbour porpoise bycatch mitigation (pingers, acoustic deterrents)",
                "from_type": "responses",
                "to": "Baltic harbour porpoise population (critically low in Baltic Proper)",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Acoustic deterrents on gillnets directly reduce harbour porpoise bycatch mortality, critical for the ~500-individual Baltic Proper population",
                "references": refs_for_connection(['response_mitigation'], ['state_marine_mammals']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # R → D: Responses influence Drivers
            {
                "from": "EU Renewable Energy Directive Baltic implementation",
                "from_type": "responses",
                "to": "EU and national renewable energy targets for Baltic states",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "EU RED transposition into national law translates EU climate commitments into binding Baltic state targets that accelerate wind deployment",
                "references": refs_for_connection(['response_regulation'], ['driver_energy_transition']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
        ]
    }

    # =========================================================================
    # CONTEXT 4: Mediterranean Floating Offshore Wind
    # =========================================================================
    kb["contexts"]["mediterranean_floating_wind"] = {
        "regional_sea": "mediterranean",
        "habitat": "deep_water_floating_wind",
        "description": "Mediterranean floating offshore wind developments (e.g., Gulf of Lion, Strait of Sicily, Aegean, Sardinia Channel). Deep bathymetry close to shore necessitates floating technology. High wind resources, intense artisanal fisheries, Posidonia meadows, cetacean habitats, mass tourism, and complex multi-country governance.",

        "drivers": [
            {"name": "EU and national renewable energy targets (REPowerEU, PNIEC)", "relevance": 0.95},
            {"name": "Mediterranean energy import dependence (gas, oil)", "relevance": 0.90},
            {"name": "Deep-water wind resource potential close to Mediterranean coasts", "relevance": 0.92},
            {"name": "Climate change mitigation under Paris Agreement", "relevance": 0.85},
            {"name": "Artisanal fishing tradition and livelihood needs", "relevance": 0.78},
            {"name": "Mass coastal tourism demand", "relevance": 0.80},
            {"name": "Coastal economic development and employment needs", "relevance": 0.75},
        ],

        "activities": [
            {"name": "Floating offshore wind farm deployment and operation", "relevance": 0.98},
            {"name": "Dynamic cable installation and grid connection", "relevance": 0.85},
            {"name": "Small-scale artisanal fishing (trammel net, longline, purse seine)", "relevance": 0.88},
            {"name": "Pelagic longline fishing for tuna and swordfish", "relevance": 0.72},
            {"name": "Coastal and maritime tourism (beach, cruise, diving)", "relevance": 0.82},
            {"name": "Environmental monitoring and baseline surveys", "relevance": 0.70},
            {"name": "Port logistics and floating platform assembly", "relevance": 0.75},
        ],

        "pressures": [
            {"name": "Displacement of artisanal fishers from wind farm zones", "relevance": 0.90},
            {"name": "Mooring and anchor disturbance to deep-sea habitats", "relevance": 0.68},
            {"name": "Seabird collision risk (Scopoli's shearwater, Yelkouan shearwater)", "relevance": 0.78},
            {"name": "Visual impact on coastal tourism seascapes", "relevance": 0.82},
            {"name": "Underwater noise from floating platform operation and installation", "relevance": 0.62},
            {"name": "Entanglement risk from mooring lines for cetaceans and turtles", "relevance": 0.65},
            {"name": "Competition for marine space with shipping, fishing and tourism", "relevance": 0.88},
            # From main KB mediterranean_open_coast:
            {"name": "Anchor damage to Posidonia oceanica meadows from cable routes", "relevance": 0.72},
            {"name": "Overfishing pressure on demersal and reef fish", "relevance": 0.75},
        ],

        "states": [
            {"name": "Mediterranean cetacean populations (fin whale, sperm whale, bottlenose dolphin)", "relevance": 0.85},
            {"name": "Demersal and reef fish assemblages (hake, red mullet, grouper)", "relevance": 0.82},
            {"name": "Pelagic fish stocks (bluefin tuna, swordfish, anchovy)", "relevance": 0.75},
            {"name": "Posidonia oceanica meadow extent near cable landfall sites", "relevance": 0.78},
            {"name": "Seabird breeding colonies (shearwaters, storm-petrels)", "relevance": 0.80},
            {"name": "Loggerhead sea turtle (Caretta caretta) population", "relevance": 0.72},
            {"name": "Biofouling communities on floating structures", "relevance": 0.60},
            # From main KB mediterranean_open_coast:
            {"name": "Coastal water quality and bathing water standards", "relevance": 0.65},
        ],

        "impacts": [
            {"name": "Carbon emission reduction from Mediterranean floating wind", "relevance": 0.95},
            {"name": "Artisanal fishery provisioning from coastal waters", "relevance": 0.82},
            {"name": "De facto marine refuge from fishing exclusion zones", "relevance": 0.65},
            {"name": "Tourism and recreation seascape value", "relevance": 0.75},
            {"name": "Pelagic fish aggregation around floating structures (FAD effect)", "relevance": 0.55},
            # From main KB mediterranean_open_coast:
            {"name": "Coastal protection by Posidonia banquettes and meadows", "relevance": 0.60},
        ],

        "welfare": [
            {"name": "Clean energy supply reducing Mediterranean import dependence", "relevance": 0.95},
            {"name": "Employment in floating wind manufacturing and port operations", "relevance": 0.88},
            {"name": "Artisanal fisher household income and livelihood security", "relevance": 0.85},
            {"name": "Coastal tourism industry revenue and employment", "relevance": 0.82},
            {"name": "Energy affordability for Mediterranean island communities", "relevance": 0.72},
            {"name": "Cultural identity of Mediterranean fishing communities", "relevance": 0.70},
            {"name": "Social acceptance and public perception of offshore wind", "relevance": 0.75},
            # From main KB mediterranean_open_coast:
            {"name": "Coastal property values and aesthetic perception", "relevance": 0.58},
        ],

        "responses": [
            {"name": "Mediterranean maritime spatial planning (Barcelona Convention, WESTMED)", "relevance": 0.90},
            {"name": "Environmental Impact Assessment with Posidonia protection", "relevance": 0.88},
            {"name": "Artisanal fisheries compensation and co-existence frameworks", "relevance": 0.85},
            {"name": "Stakeholder engagement with fishing and tourism sectors", "relevance": 0.85},
            {"name": "Floating wind environmental consenting (national frameworks)", "relevance": 0.82},
            {"name": "Nature-inclusive mooring design for cetacean and turtle safety", "relevance": 0.68},
            {"name": "Adaptive management and post-construction monitoring", "relevance": 0.78},
            # From main KB mediterranean_open_coast:
            {"name": "Posidonia protection legislation (EU Habitats Directive)", "relevance": 0.75},
            {"name": "Marine Protected Areas and no-take zones", "relevance": 0.72},
        ],

        "connections": [
            # D → A
            {
                "from": "EU and national renewable energy targets (REPowerEU, PNIEC)",
                "from_type": "drivers",
                "to": "Floating offshore wind farm deployment and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Italy, France, Spain and Greece have ambitious floating wind targets in their National Energy and Climate Plans (PNIECs)",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "Mediterranean energy import dependence (gas, oil)",
                "from_type": "drivers",
                "to": "Floating offshore wind farm deployment and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Mediterranean countries rely heavily on imported fossil fuels; floating wind offers domestic generation from abundant wind resources",
                "references": refs_for_connection(['driver_energy_transition'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "irreversible"
            },
            {
                "from": "Artisanal fishing tradition and livelihood needs",
                "from_type": "drivers",
                "to": "Small-scale artisanal fishing (trammel net, longline, purse seine)",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Deep-rooted artisanal fishing traditions sustain tens of thousands of small-scale fishers across the Mediterranean coast",
                "references": refs_for_connection(['driver_food_security'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Mass coastal tourism demand",
                "from_type": "drivers",
                "to": "Coastal and maritime tourism (beach, cruise, diving)",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "The Mediterranean receives >300 million tourists annually, creating intense coastal tourism pressure and seascape sensitivity",
                "references": refs_for_connection(['activity_tourism'], ['pressure_visual']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Coastal economic development and employment needs",
                "from_type": "drivers",
                "to": "Port logistics and floating platform assembly",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Floating wind assembly requires major port upgrades, creating industrial development opportunities for Mediterranean ports",
                "references": refs_for_connection(['driver_economic', 'gb_employment'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },

            # A → P
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Displacement of artisanal fishers from wind farm zones",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Floating wind installations overlap with traditional artisanal fishing grounds, displacing small-scale fishers with limited alternative areas",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_displacement', 'activity_fishing']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Seabird collision risk (Scopoli's shearwater, Yelkouan shearwater)",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Mediterranean endemic shearwaters have nocturnal flight behaviour that may increase collision risk with floating turbines near breeding colonies",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_bird_collision', 'state_seabirds']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Visual impact on coastal tourism seascapes",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Mediterranean deep water close to shore means floating turbines may be visible from tourism beaches, creating high social sensitivity",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_visual']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Mooring and anchor disturbance to deep-sea habitats",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Anchor systems and mooring chain sweeps disturb deep Mediterranean benthic habitats at installation points",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Entanglement risk from mooring lines for cetaceans and turtles",
                "to_type": "pressures",
                "polarity": "+", "strength": "weak", "confidence": 2,
                "rationale": "Dynamic mooring lines in the Mediterranean may pose entanglement risk for fin whales, sperm whales and loggerhead turtles",
                "references": refs_for_connection(['activity_offshore_wind'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Floating offshore wind farm deployment and operation",
                "from_type": "activities",
                "to": "Competition for marine space with shipping, fishing and tourism",
                "to_type": "pressures",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "The Mediterranean is one of the most congested seas in the world; floating wind adds another competing spatial claim",
                "references": refs_for_connection(['activity_offshore_wind'], ['pressure_displacement']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Dynamic cable installation and grid connection",
                "from_type": "activities",
                "to": "Anchor damage to Posidonia oceanica meadows from cable routes",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Cable landfall routes and nearshore sections risk damaging protected Posidonia meadows if not carefully routed",
                "references": refs_for_connection(['activity_grid_infrastructure'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "irreversible"
            },

            # P → P
            {
                "from": "Displacement of artisanal fishers from wind farm zones",
                "from_type": "pressures",
                "to": "Overfishing pressure on demersal and reef fish",
                "to_type": "pressures",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Displaced artisanal fishing effort concentrates in remaining coastal grounds, intensifying localised overfishing pressure",
                "references": refs_for_connection(['pressure_displacement'], ['activity_fishing', 'state_fish']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # P → C
            {
                "from": "Displacement of artisanal fishers from wind farm zones",
                "from_type": "pressures",
                "to": "Demersal and reef fish assemblages (hake, red mullet, grouper)",
                "to_type": "states",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Fishing exclusion within wind farm areas may allow localised recovery of demersal fish assemblages through reduced fishing mortality",
                "references": refs_for_connection(['pressure_displacement'], ['state_fish']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Seabird collision risk (Scopoli's shearwater, Yelkouan shearwater)",
                "from_type": "pressures",
                "to": "Seabird breeding colonies (shearwaters, storm-petrels)",
                "to_type": "states",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Mediterranean shearwaters have very low reproductive rates; even modest collision mortality may affect colony viability",
                "references": refs_for_connection(['pressure_bird_collision'], ['state_seabirds']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Entanglement risk from mooring lines for cetaceans and turtles",
                "from_type": "pressures",
                "to": "Mediterranean cetacean populations (fin whale, sperm whale, bottlenose dolphin)",
                "to_type": "states",
                "polarity": "-", "strength": "weak", "confidence": 2,
                "rationale": "Mediterranean cetacean populations are already under pressure; mooring entanglement adds a novel risk, especially in the ACCOBAMS area",
                "references": refs_for_connection(['state_marine_mammals'], ['response_mitigation']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Anchor damage to Posidonia oceanica meadows from cable routes",
                "from_type": "pressures",
                "to": "Posidonia oceanica meadow extent near cable landfall sites",
                "to_type": "states",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "Posidonia meadows are extremely slow to recover (centuries); cable-related damage at landfall sites causes effectively irreversible loss",
                "references": refs_for_connection(['pressure_habitat'], ['state_biodiversity']),
                "temporal_lag": "immediate", "reversibility": "irreversible"
            },
            {
                "from": "Underwater noise from floating platform operation and installation",
                "from_type": "pressures",
                "to": "Mediterranean cetacean populations (fin whale, sperm whale, bottlenose dolphin)",
                "to_type": "states",
                "polarity": "-", "strength": "weak", "confidence": 2,
                "rationale": "Continuous low-frequency operational noise from floating platforms and mooring chain may cause chronic disturbance to cetaceans in the vicinity",
                "references": refs_for_connection(['pressure_noise'], ['state_marine_mammals']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Mooring and anchor disturbance to deep-sea habitats",
                "from_type": "pressures",
                "to": "Biofouling communities on floating structures",
                "to_type": "states",
                "polarity": "+", "strength": "weak", "confidence": 2,
                "rationale": "Floating structures and moorings provide novel hard substrate in deep Mediterranean waters, enabling biofouling colonisation",
                "references": refs_for_connection(['pressure_habitat'], ['state_benthos']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # C → C
            {
                "from": "Posidonia oceanica meadow extent near cable landfall sites",
                "from_type": "states",
                "to": "Demersal and reef fish assemblages (hake, red mullet, grouper)",
                "to_type": "states",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Posidonia meadows provide critical nursery and feeding habitat for Mediterranean fish assemblages",
                "references": refs_for_connection(['state_biodiversity'], ['state_fish']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },

            # C → ES
            {
                "from": "Demersal and reef fish assemblages (hake, red mullet, grouper)",
                "from_type": "states",
                "to": "Artisanal fishery provisioning from coastal waters",
                "to_type": "impacts",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Mediterranean artisanal fishery catches depend directly on the health of demersal and reef fish assemblages",
                "references": refs_for_connection(['state_fish'], ['es_fish_production']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Posidonia oceanica meadow extent near cable landfall sites",
                "from_type": "states",
                "to": "Coastal protection by Posidonia banquettes and meadows",
                "to_type": "impacts",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Posidonia meadows attenuate wave energy and banquettes protect beaches from erosion — a critical ES for Mediterranean tourism coasts",
                "references": refs_for_connection(['state_biodiversity'], ['es_ecosystem_services']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Seabird breeding colonies (shearwaters, storm-petrels)",
                "from_type": "states",
                "to": "Tourism and recreation seascape value",
                "to_type": "impacts",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Mediterranean seabird colonies contribute to the natural and cultural heritage value of island landscapes that attract ecotourism",
                "references": refs_for_connection(['state_seabirds'], ['es_ecosystem_services', 'activity_tourism']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # ES → W
            {
                "from": "Carbon emission reduction from Mediterranean floating wind",
                "from_type": "impacts",
                "to": "Clean energy supply reducing Mediterranean import dependence",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Floating wind generation in the Mediterranean displaces imported gas and oil, providing domestic clean electricity",
                "references": refs_for_connection(['gb_energy'], ['driver_energy_transition']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission reduction from Mediterranean floating wind",
                "from_type": "impacts",
                "to": "Employment in floating wind manufacturing and port operations",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Floating wind supply chain (platform assembly, cable, O&M) creates jobs in Mediterranean port cities",
                "references": refs_for_connection(['gb_employment', 'gb_energy'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Artisanal fishery provisioning from coastal waters",
                "from_type": "impacts",
                "to": "Artisanal fisher household income and livelihood security",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Artisanal catch volumes directly determine fisher household incomes across Mediterranean coastal communities",
                "references": refs_for_connection(['es_fish_production'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Tourism and recreation seascape value",
                "from_type": "impacts",
                "to": "Coastal tourism industry revenue and employment",
                "to_type": "welfare",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Seascape aesthetics and marine environmental quality underpin Mediterranean tourism revenue, which dominates many coastal economies",
                "references": refs_for_connection(['es_ecosystem_services', 'activity_tourism'], ['gb_economic']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Carbon emission reduction from Mediterranean floating wind",
                "from_type": "impacts",
                "to": "Energy affordability for Mediterranean island communities",
                "to_type": "welfare",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Floating wind near islands can displace expensive diesel generation, reducing energy costs for isolated communities",
                "references": refs_for_connection(['gb_energy'], ['hw_wellbeing']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },

            # W → D (feedback loops)
            {
                "from": "Artisanal fisher household income and livelihood security",
                "from_type": "welfare",
                "to": "Artisanal fishing tradition and livelihood needs",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Fisher livelihood security reinforces cultural and economic demand for maintaining artisanal fishing access in the Mediterranean",
                "references": refs_for_connection(['hw_wellbeing', 'hw_cultural'], ['driver_food_security']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Clean energy supply reducing Mediterranean import dependence",
                "from_type": "welfare",
                "to": "EU and national renewable energy targets (REPowerEU, PNIEC)",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Demonstrated success of floating wind reinforces political ambition and public support for higher Mediterranean renewable targets",
                "references": refs_for_connection(['gb_energy'], ['driver_energy_transition']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },
            {
                "from": "Coastal tourism industry revenue and employment",
                "from_type": "welfare",
                "to": "Mass coastal tourism demand",
                "to_type": "drivers",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "Tourism industry success reinforces investment and marketing that sustains Mediterranean mass tourism demand",
                "references": refs_for_connection(['gb_economic', 'activity_tourism'], ['hw_wellbeing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Cultural identity of Mediterranean fishing communities",
                "from_type": "welfare",
                "to": "Artisanal fishing tradition and livelihood needs",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Cultural identity tied to fishing heritage reinforces community resistance to spatial displacement and advocacy for fishing rights",
                "references": refs_for_connection(['hw_cultural', 'hw_conflict'], ['driver_food_security']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },

            # R → A
            {
                "from": "Mediterranean maritime spatial planning (Barcelona Convention, WESTMED)",
                "from_type": "responses",
                "to": "Floating offshore wind farm deployment and operation",
                "to_type": "activities",
                "polarity": "+", "strength": "strong", "confidence": 4,
                "rationale": "Barcelona Convention and WESTMED initiative coordinate Mediterranean MSP, designating floating wind zones across national boundaries",
                "references": refs_for_connection(['response_msp'], ['activity_offshore_wind']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Artisanal fisheries compensation and co-existence frameworks",
                "from_type": "responses",
                "to": "Small-scale artisanal fishing (trammel net, longline, purse seine)",
                "to_type": "activities",
                "polarity": "+", "strength": "medium", "confidence": 3,
                "rationale": "Compensation and co-existence frameworks support continued artisanal fishing viability through mitigation for lost grounds",
                "references": refs_for_connection(['response_stakeholder', 'response_mitigation'], ['activity_fishing']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },
            {
                "from": "Marine Protected Areas and no-take zones",
                "from_type": "responses",
                "to": "Small-scale artisanal fishing (trammel net, longline, purse seine)",
                "to_type": "activities",
                "polarity": "-", "strength": "medium", "confidence": 4,
                "rationale": "MPAs restrict fishing in designated areas, complementing wind farm exclusion in creating a network of reduced-pressure zones",
                "references": refs_for_connection(['measure_spatial'], ['activity_fishing']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },

            # R → P
            {
                "from": "Environmental Impact Assessment with Posidonia protection",
                "from_type": "responses",
                "to": "Anchor damage to Posidonia oceanica meadows from cable routes",
                "to_type": "pressures",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "EIA requirements mandate cable route alternatives and horizontal directional drilling to avoid Posidonia meadows",
                "references": refs_for_connection(['response_eia'], ['pressure_habitat']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Nature-inclusive mooring design for cetacean and turtle safety",
                "from_type": "responses",
                "to": "Entanglement risk from mooring lines for cetaceans and turtles",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Modified mooring configurations and whale-safe materials reduce entanglement probability for Mediterranean megafauna",
                "references": refs_for_connection(['response_mitigation'], ['state_marine_mammals']),
                "temporal_lag": "immediate", "reversibility": "reversible"
            },
            {
                "from": "Posidonia protection legislation (EU Habitats Directive)",
                "from_type": "responses",
                "to": "Anchor damage to Posidonia oceanica meadows from cable routes",
                "to_type": "pressures",
                "polarity": "-", "strength": "strong", "confidence": 5,
                "rationale": "EU Habitats Directive strictly protects Posidonia as priority habitat (1120*), requiring avoidance of cable damage through routing constraints",
                "references": refs_for_connection(['response_regulation'], ['pressure_habitat']),
                "temporal_lag": "immediate", "reversibility": "partially_reversible"
            },
            {
                "from": "Adaptive management and post-construction monitoring",
                "from_type": "responses",
                "to": "Seabird collision risk (Scopoli's shearwater, Yelkouan shearwater)",
                "to_type": "pressures",
                "polarity": "-", "strength": "medium", "confidence": 3,
                "rationale": "Post-construction monitoring enables turbine curtailment during peak shearwater migration and collision detection to adapt operations",
                "references": refs_for_connection(['response_monitoring'], ['pressure_bird_collision']),
                "temporal_lag": "short-term", "reversibility": "reversible"
            },

            # R → C: Responses restore/protect State
            {
                "from": "Posidonia protection legislation (EU Habitats Directive)",
                "from_type": "responses",
                "to": "Posidonia oceanica meadow extent near cable landfall sites",
                "to_type": "states",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "EU Habitats Directive priority habitat 1120* designation mandates Posidonia conservation, requiring cable route avoidance and horizontal directional drilling at landfall",
                "references": refs_for_connection(['response_regulation'], ['state_biodiversity']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
            {
                "from": "Marine Protected Areas and no-take zones",
                "from_type": "responses",
                "to": "Demersal and reef fish assemblages (hake, red mullet, grouper)",
                "to_type": "states",
                "polarity": "+", "strength": "strong", "confidence": 5,
                "rationale": "No-take MPAs in the Mediterranean allow fish assemblage recovery, complementing wind farm exclusion zones as a refuge network",
                "references": refs_for_connection(['measure_spatial'], ['state_fish']),
                "temporal_lag": "medium-term", "reversibility": "reversible"
            },

            # R → D: Responses influence Drivers
            {
                "from": "Floating wind environmental consenting (national frameworks)",
                "from_type": "responses",
                "to": "EU and national renewable energy targets (REPowerEU, PNIEC)",
                "to_type": "drivers",
                "polarity": "+", "strength": "medium", "confidence": 4,
                "rationale": "Streamlined consenting frameworks remove barriers to floating wind deployment, enabling achievement of REPowerEU Mediterranean targets",
                "references": refs_for_connection(['response_regulation'], ['driver_energy_transition']),
                "temporal_lag": "medium-term", "reversibility": "partially_reversible"
            },
        ]
    }

    return kb


# === Main ===
if __name__ == "__main__":
    bib_path = Path(r"C:\Users\arturas.baziukas\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\.playwright-mcp\export-2026-4-9.bib")

    papers = parse_bibtex(bib_path)
    print(f"Parsed {len(papers)} papers from BibTeX")

    kb = build_kb(papers)

    out_path = Path(r"C:\Users\arturas.baziukas\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\data\ses_knowledge_db_offshore_wind.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(kb, f, indent=2, ensure_ascii=False)

    print(f"\nKB written to {out_path}")
    print(f"Contexts: {list(kb['contexts'].keys())}")
    for ctx_name, ctx in kb['contexts'].items():
        n_conn = len(ctx.get('connections', []))
        n_elem = sum(len(ctx.get(k, [])) for k in ['drivers', 'activities', 'pressures', 'states', 'impacts', 'welfare', 'responses'])
        print(f"  {ctx_name}: {n_elem} elements, {n_conn} connections")

    # Validate transitions
    VALID_TRANSITIONS = {
        'drivers->activities', 'activities->pressures', 'pressures->states',
        'states->impacts', 'impacts->welfare', 'welfare->drivers',
        'pressures->pressures', 'states->states',
        'responses->activities', 'responses->pressures', 'responses->drivers',
        'responses->states',  # restoration/protection
    }
    print("\nTransition validation:")
    for ctx_name, ctx in kb['contexts'].items():
        invalid = []
        for c in ctx.get('connections', []):
            t = f"{c['from_type']}->{c['to_type']}"
            if t not in VALID_TRANSITIONS:
                invalid.append(t)
        if invalid:
            print(f"  {ctx_name}: INVALID transitions: {set(invalid)}")
        else:
            print(f"  {ctx_name}: All {len(ctx['connections'])} connections valid ✓")
