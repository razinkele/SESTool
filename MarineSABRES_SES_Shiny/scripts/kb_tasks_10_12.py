#!/usr/bin/env python3
"""
Tasks 10-12: KB data quality fixes for ses_knowledge_db.json
  Task 10: Standardize reversibility and temporal_lag
  Task 11: Expand cross-ecosystem links (with dedup and validation)
  Task 12: Improve generic fallback section
"""

import json
from pathlib import Path
from collections import defaultdict

PROJECT_ROOT = Path(__file__).resolve().parent.parent
KB_PATH = PROJECT_ROOT / "data" / "ses_knowledge_db.json"

def load_kb():
    with open(KB_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

def save_kb(db):
    with open(KB_PATH, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2, ensure_ascii=False)
    print(f"Saved to {KB_PATH}")


# ── Task 10: Standardize reversibility and temporal_lag ──

REVERSIBILITY_MAP = {
    "poorly_reversible": "partially_reversible",
    "slowly_reversible": "partially_reversible",
    "moderate": "partially_reversible",
    "slow": "partially_reversible",
}

def numeric_to_temporal_lag(val):
    """Convert numeric value to categorical temporal_lag."""
    v = float(val)
    if v < 0.083:
        return "immediate"
    elif v < 0.5:
        return "short-term"
    elif v < 3:
        return "medium-term"
    else:
        return "long-term"

def is_numeric_string(val):
    if isinstance(val, (int, float)):
        return True
    if isinstance(val, str):
        try:
            float(val)
            return True
        except ValueError:
            return False
    return False

def task_10(db):
    print("=" * 70)
    print("TASK 10: Standardize reversibility and temporal_lag")
    print("=" * 70)

    rev_changes = defaultdict(int)
    lag_changes = defaultdict(int)

    # Process all connections in all contexts
    for ctx_name, ctx in db.get("contexts", {}).items():
        for conn in ctx.get("connections", []):
            # Reversibility
            rev = conn.get("reversibility")
            if rev in REVERSIBILITY_MAP:
                conn["reversibility"] = REVERSIBILITY_MAP[rev]
                rev_changes[rev] += 1

            # Temporal lag
            lag = conn.get("temporal_lag")
            if lag is not None and is_numeric_string(lag):
                new_val = numeric_to_temporal_lag(lag)
                lag_changes[f"{lag} -> {new_val}"] += 1
                conn["temporal_lag"] = new_val

    # Also process cross_ecosystem_links
    for link in db.get("cross_ecosystem_links", []):
        rev = link.get("reversibility")
        if rev in REVERSIBILITY_MAP:
            link["reversibility"] = REVERSIBILITY_MAP[rev]
            rev_changes[rev] += 1

        lag = link.get("temporal_lag")
        if lag is not None and is_numeric_string(lag):
            new_val = numeric_to_temporal_lag(lag)
            lag_changes[f"{lag} -> {new_val}"] += 1
            link["temporal_lag"] = new_val

    print("\nReversibility changes:")
    total_rev = 0
    for old_val, count in sorted(rev_changes.items()):
        print(f"  '{old_val}' -> 'partially_reversible': {count}")
        total_rev += count
    print(f"  Total: {total_rev}")

    print("\nTemporal lag changes:")
    total_lag = 0
    for change, count in sorted(lag_changes.items()):
        print(f"  {change}: {count}")
        total_lag += count
    print(f"  Total: {total_lag}")
    print()


# ── Task 11: Expand cross-ecosystem links ──

NEW_LINKS = [
    {
        "from_context": "north_sea_tidal_flat",
        "from_element": "Benthic invertebrate biomass (cockle, mussel, lugworm)",
        "to_context": "north_sea_offshore",
        "to_element": "North Sea herring stock biomass",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Tidal flat invertebrate productivity supports juvenile fish nursery function for North Sea offshore stocks.",
        "temporal_lag": "medium-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "north_sea_tidal_flat",
        "from_element": "Intertidal mudflat and sandflat extent",
        "to_context": "north_sea_estuary",
        "to_element": "Estuarine benthic invertebrate communities",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Wadden Sea tidal flats and estuarine mudflats share species pools and larval exchange.",
        "temporal_lag": "short-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "north_sea_estuary",
        "from_element": "Estuarine fish community (smelt, flounder, bass)",
        "to_context": "north_sea_offshore",
        "to_element": "North Sea herring stock biomass",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Estuaries serve as critical nursery habitats exporting juvenile fish to North Sea offshore populations.",
        "temporal_lag": "medium-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "mediterranean_seagrass",
        "from_element": "Posidonia oceanica meadow extent and density",
        "to_context": "mediterranean_rocky_shore",
        "to_element": "Infralittoral rocky reef algal assemblages",
        "polarity": "+",
        "strength": "weak",
        "rationale": "Posidonia leaf litter and detritus subsidize rocky shore food webs through wave-driven transport.",
        "temporal_lag": "short-term",
        "reversibility": "reversible"
    },
    {
        "from_context": "mediterranean_open_coast",
        "from_element": "Atlantic bluefin tuna stock recovery status",
        "to_context": "mediterranean_rocky_shore",
        "to_element": "Large predatory fish abundance (grouper, dentex)",
        "polarity": "+",
        "strength": "weak",
        "rationale": "Recovery of large pelagic predators influences trophic structure of rocky reef fish communities.",
        "temporal_lag": "long-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "baltic_lagoon",
        "from_element": "Pike-perch population dynamics",
        "to_context": "baltic_estuary",
        "to_element": "Estuarine fish community (smelt, flounder, bass)",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Baltic lagoon pike-perch populations exchange with estuarine fish communities through connected waterways.",
        "temporal_lag": "short-term",
        "reversibility": "reversible"
    },
    {
        "from_context": "arctic_fjord",
        "from_element": "Deep-water renewal frequency and oxygen levels",
        "to_context": "arctic_sea_ice",
        "to_element": "Multi-year ice coverage (critical habitat)",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Fjord deep-water renewal is driven by dense water formation linked to sea ice dynamics.",
        "temporal_lag": "medium-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "indian_ocean_coral_reef",
        "from_element": "Fringing coral reef live cover and structural complexity",
        "to_context": "indian_ocean_island",
        "to_element": "Lagoon water quality and coral cover",
        "polarity": "+",
        "strength": "strong",
        "rationale": "Fringing reef structural integrity directly protects island lagoon water quality and inner reef health.",
        "temporal_lag": "short-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "caribbean_coral_reef",
        "from_element": "Reef fish species diversity and biomass",
        "to_context": "caribbean_seagrass",
        "to_element": "Seagrass (Thalassia testudinum) bed coverage",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Reef herbivorous fish graze on seagrass epiphytes, improving seagrass health through cleaning mutualism.",
        "temporal_lag": "short-term",
        "reversibility": "reversible"
    },
    {
        "from_context": "atlantic_open_coast",
        "from_element": "Kelp forest (Laminaria hyperborea/digitata) canopy cover",
        "to_context": "atlantic_offshore",
        "to_element": "Mesopelagic fish biomass (biological carbon pump)",
        "polarity": "+",
        "strength": "weak",
        "rationale": "Kelp-derived particulate organic carbon contributes to offshore biological carbon pump through detrital export.",
        "temporal_lag": "medium-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "black_sea_open_coast",
        "from_element": "Anchovy and sprat stock biomass",
        "to_context": "mediterranean_open_coast",
        "to_element": "Atlantic bluefin tuna stock recovery status",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Black Sea small pelagics contribute to Mediterranean food web through Turkish Straits connectivity.",
        "temporal_lag": "medium-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "tropical_mangrove",
        "from_element": "Mangrove canopy cover and forest extent",
        "to_context": "indian_ocean_island",
        "to_element": "Mangrove fringe extent and condition",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Regional mangrove health influences propagule supply and genetic connectivity for island mangrove fringes.",
        "temporal_lag": "long-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "pacific_island_atoll",
        "from_element": "Atoll reef crest structural integrity",
        "to_context": "caribbean_coral_reef",
        "to_element": "Live coral cover percentage",
        "polarity": "+",
        "strength": "weak",
        "rationale": "Global coral reef health is interconnected through ocean-scale larval dispersal and shared climate stressors.",
        "temporal_lag": "long-term",
        "reversibility": "partially_reversible"
    },
    {
        "from_context": "baltic_archipelago",
        "from_element": "Herring and perch stock condition around islands",
        "to_context": "baltic_open_coast",
        "to_element": "Nearshore fish community (flounder, perch)",
        "polarity": "+",
        "strength": "medium",
        "rationale": "Archipelago fish populations exchange with open coast nearshore communities through seasonal migrations.",
        "temporal_lag": "short-term",
        "reversibility": "reversible"
    }
]


def get_all_elements_for_context(ctx):
    """Get all element names across all categories for a context."""
    categories = ["drivers", "activities", "pressures", "states", "impacts", "welfare", "responses"]
    elements = set()
    for cat in categories:
        for elem in ctx.get(cat, []):
            elements.add(elem["name"])
    return elements


def task_11(db):
    print("=" * 70)
    print("TASK 11: Expand cross-ecosystem links")
    print("=" * 70)

    cross_links = db.get("cross_ecosystem_links", [])
    original_count = len(cross_links)

    # Step 1: Remove duplicates
    seen = set()
    deduped = []
    dupes_removed = 0
    for link in cross_links:
        key = (link["from_context"], link["from_element"], link["to_context"], link["to_element"])
        if key in seen:
            dupes_removed += 1
            print(f"  Removed duplicate: {key[0]}/{key[1][:40]}... -> {key[2]}/{key[3][:40]}...")
        else:
            seen.add(key)
            deduped.append(link)

    cross_links = deduped
    print(f"\nDuplicates removed: {dupes_removed}")

    # Step 2: Build element index for validation
    contexts = db.get("contexts", {})
    context_elements = {}
    for ctx_name, ctx in contexts.items():
        context_elements[ctx_name] = get_all_elements_for_context(ctx)

    # Step 3: Add new links with validation
    added = 0
    skipped = 0
    for link in NEW_LINKS:
        fc = link["from_context"]
        fe = link["from_element"]
        tc = link["to_context"]
        te = link["to_element"]

        # Check from_context exists
        if fc not in context_elements:
            print(f"  WARNING: from_context '{fc}' not found in KB. Skipping link.")
            skipped += 1
            continue

        # Check to_context exists
        if tc not in context_elements:
            print(f"  WARNING: to_context '{tc}' not found in KB. Skipping link.")
            skipped += 1
            continue

        # Check from_element exists
        if fe not in context_elements[fc]:
            print(f"  WARNING: from_element '{fe}' not found in context '{fc}'. Skipping link.")
            skipped += 1
            continue

        # Check to_element exists
        if te not in context_elements[tc]:
            print(f"  WARNING: to_element '{te}' not found in context '{tc}'. Skipping link.")
            skipped += 1
            continue

        # Check not duplicate of existing
        key = (fc, fe, tc, te)
        if key in seen:
            print(f"  Skipping already-existing link: {fc} -> {tc}")
            skipped += 1
            continue

        seen.add(key)
        cross_links.append(link)
        added += 1

    db["cross_ecosystem_links"] = cross_links

    print(f"\nNew links added: {added}")
    print(f"Links skipped: {skipped}")
    print(f"Total cross-ecosystem links: {len(cross_links)}")
    print()


# ── Task 12: Improve generic fallback ──

def task_12(db):
    print("=" * 70)
    print("TASK 12: Improve generic fallback")
    print("=" * 70)

    fallback = db.get("generic_fallback", {})
    changes = []

    # 1. Add new impacts (ES section)
    new_impacts = [
        {"name": "Carbon sequestration and climate regulation", "relevance": 0.8},
        {"name": "Water purification and nutrient cycling", "relevance": 0.75},
        {"name": "Nursery habitat for commercial species", "relevance": 0.7},
    ]
    existing_impact_names = {e["name"] for e in fallback.get("impacts", [])}
    for item in new_impacts:
        if item["name"] not in existing_impact_names:
            fallback.setdefault("impacts", []).append(item)
            changes.append(f"  Added to impacts: '{item['name']}' (relevance {item['relevance']})")

    # 2. Add new welfare (GB section)
    new_welfare = [
        {"name": "Coastal community food security", "relevance": 0.85},
        {"name": "Cultural identity and sense of place", "relevance": 0.7},
        {"name": "Coastal property protection value", "relevance": 0.65},
    ]
    existing_welfare_names = {e["name"] for e in fallback.get("welfare", [])}
    for item in new_welfare:
        if item["name"] not in existing_welfare_names:
            fallback.setdefault("welfare", []).append(item)
            changes.append(f"  Added to welfare: '{item['name']}' (relevance {item['relevance']})")

    # 3. Differentiate existing relevance scores (wider range 0.5-0.9)
    # Apply differentiated scores based on reasonable judgment
    score_adjustments = {
        # Drivers - differentiate from uniform 0.7-0.8
        "Food security from marine resources": 0.85,
        "Economic development pressure": 0.75,
        "Recreational and tourism demand": 0.65,
        "Coastal protection needs": 0.7,
        "Climate change adaptation and resilience needs": 0.9,
        # Activities
        "Commercial fishing": 0.85,
        "Aquaculture": 0.65,
        "Coastal development": 0.7,
        "Tourism and recreation": 0.6,
        "Shipping and transport": 0.55,
        # Pressures
        "Overfishing": 0.85,
        "Nutrient enrichment": 0.7,
        "Habitat loss": 0.8,
        "Marine pollution": 0.65,
        "Climate-related changes": 0.75,
        "Climate change impacts": 0.9,
        # States
        "Fish stock biomass": 0.8,
        "Water quality indicators": 0.75,
        "Habitat condition": 0.7,
        "Biodiversity levels": 0.65,
        # Impacts (existing)
        "Fishery production capacity": 0.8,
        "Coastal protection services": 0.65,
        "Recreation and tourism amenity": 0.6,
        # Welfare (existing)
        "Fishing community livelihoods": 0.8,
        "Coastal community well-being": 0.75,
        "Tourism-related employment": 0.6,
        # Responses
        "Marine Protected Areas": 0.8,
        "Fishing regulations": 0.75,
        "Pollution control measures": 0.65,
        "Habitat restoration programmes": 0.6,
    }

    categories = ["drivers", "activities", "pressures", "states", "impacts", "welfare", "responses"]
    score_changes = 0
    for cat in categories:
        for elem in fallback.get(cat, []):
            name = elem["name"]
            if name in score_adjustments:
                old = elem["relevance"]
                new = score_adjustments[name]
                if old != new:
                    elem["relevance"] = new
                    changes.append(f"  [{cat}] '{name}': {old} -> {new}")
                    score_changes += 1

    db["generic_fallback"] = fallback

    print(f"\nChanges made:")
    for c in changes:
        print(c)
    print(f"\nTotal score adjustments: {score_changes}")
    print(f"New impacts added: {len(new_impacts)}")
    print(f"New welfare items added: {len(new_welfare)}")
    print()


def main():
    db = load_kb()

    task_10(db)
    task_11(db)
    task_12(db)

    save_kb(db)
    print("All tasks complete.")


if __name__ == "__main__":
    main()
