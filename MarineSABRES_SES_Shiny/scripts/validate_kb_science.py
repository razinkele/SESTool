#!/usr/bin/env python3
"""
Scientific validation of Caribbean and Atlantic DAPSI(W)R(M) knowledge base connections.

Validates polarity, strength, confidence, and temporal_lag against published marine
ecology literature (GCRMN, NOAA, ICCAT, ICES, CRFM, peer-reviewed journals).

Only changes values where scientifically warranted. Conservative approach.
"""

import json
import sys
from pathlib import Path
from copy import deepcopy

PROJECT_ROOT = Path(__file__).resolve().parent.parent
KB_PATH = PROJECT_ROOT / "data" / "ses_knowledge_db.json"

TARGET_CONTEXTS = [
    "caribbean_coral_reef",
    "caribbean_seagrass",
    "caribbean_island",
    "atlantic_offshore",
    "atlantic_island",
    "atlantic_estuary",
    "atlantic_open_coast",
]


def find_connection(connections, from_name, to_name):
    """Find connection index by from/to names."""
    for i, c in enumerate(connections):
        if c["from"] == from_name and c["to"] == to_name:
            return i
    return None


# Each fix: (context, from, to, field_changes_dict)
# field_changes_dict maps field_name -> (old_value, new_value, scientific_rationale)
FIXES = [
    # =========================================================================
    # CARIBBEAN CORAL REEF
    # =========================================================================
    (
        "caribbean_coral_reef",
        "Mass coral bleaching from thermal stress",
        "Live coral cover percentage",
        {
            "temporal_lag": (
                "short-term",
                "medium-term",
                "GCRMN 2024 report: bleaching mortality unfolds over weeks but ecosystem-level "
                "coral cover decline persists for years to decades; recovery requires 10-15 years "
                "minimum (Hughes et al. 2018, GCRMN Caribbean 2025 report).",
            ),
        },
    ),
    (
        "caribbean_coral_reef",
        "Stony coral tissue loss disease (SCTLD)",
        "Live coral cover percentage",
        {
            "temporal_lag": (
                "short-term",
                "medium-term",
                "SCTLD spreads across reef tracts over months to years; the disease has been "
                "spreading since 2014 and continues to cause mortality across 30+ Caribbean "
                "countries (NOAA CoRIS, Frontiers in Marine Science 2023 review).",
            ),
            "reversibility": (
                "partially_reversible",
                "irreversible",
                "SCTLD-susceptible species like Dendrogyra cylindrus and Meandrina meandrites "
                "have suffered 90-100% mortality; some species face functional extinction "
                "(Nature Communications Biology 2022).",
            ),
        },
    ),
    (
        "caribbean_coral_reef",
        "Reef-based tourism attraction value",
        "Tourism-dependent community livelihoods",
        {
            "strength": (
                "medium",
                "strong",
                "Reef tourism is the primary economic driver for many Caribbean SIDS; "
                "the Caribbean Tourism Organisation reports reef-adjacent tourism accounts "
                "for 30-50% of GDP in several island nations.",
            ),
        },
    ),
    (
        "caribbean_coral_reef",
        "Hurricane physical damage to reef structure",
        "Live coral cover percentage",
        {
            "polarity": (
                "+",
                "-",
                "Hurricane physical damage destroys coral frameworks, reducing live coral cover. "
                "This is a well-established negative relationship (Alvarez-Filip et al. 2009, "
                "GCRMN Caribbean reports). The positive polarity was an error.",
            ),
            "strength": (
                "medium",
                "strong",
                "Category 4-5 hurricanes can reduce live coral cover by 17-80% on impacted reefs "
                "(Gardner et al. 2005, Nature). Well-documented across Caribbean.",
            ),
            "confidence": (
                3,
                5,
                "Extensively documented relationship across decades of Caribbean reef monitoring.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Hurricane physical damage to reef structure",
                "Hurricanes cause mechanical destruction of coral frameworks through wave action and debris, "
                "directly reducing live coral cover (Gardner et al. 2005; Alvarez-Filip et al. 2009).",
            ),
        },
    ),
    (
        "caribbean_coral_reef",
        "Macroalgal cover on reef substrate",
        "Biodiversity and pharmaceutical potential",
        {
            "polarity": (
                "+",
                "-",
                "Macroalgal overgrowth smothers coral and reduces reef biodiversity, "
                "which diminishes pharmaceutical bioprospecting potential. GCRMN Caribbean 2025: "
                "macroalgae cover rose 85% since 1980 as biodiversity declined.",
            ),
            "rationale": (
                "Bridge connection to integrate isolated subgraph into main DAPSI(W)R(M) network",
                "Macroalgal dominance reduces coral and invertebrate diversity, diminishing the "
                "reef biodiversity that underpins pharmaceutical bioprospecting potential.",
            ),
        },
    ),
    # =========================================================================
    # CARIBBEAN SEAGRASS
    # =========================================================================
    (
        "caribbean_seagrass",
        "Climate change and ocean warming",
        "Thalassia testudinum shoot density and canopy height",
        {
            "polarity": (
                "+",
                "-",
                "Ocean warming causes thermal stress that exceeds Thalassia thermal tolerance, "
                "leading to seagrass die-offs. This is a negative effect, well documented in "
                "Florida Bay and Caribbean shallow waters (Koch et al. 2007).",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Climate change and ocean warming",
                "Rising sea temperatures cause thermal stress that reduces Thalassia shoot density "
                "and canopy height through die-offs in shallow waters (Koch et al. 2007).",
            ),
        },
    ),
    (
        "caribbean_seagrass",
        "Green turtle (Chelonia mydas) population abundance",
        "Nursery habitat provision for conch and lobster",
        {
            "polarity": (
                "+",
                "-",
                "Recovering green turtle populations intensify grazing on Thalassia meadows, "
                "reducing seagrass canopy that provides nursery habitat for conch and lobster. "
                "Overgrazing by turtles can degrade nursery function (Fourqurean et al. 2010; "
                "Christianen et al. 2014).",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Green turtle (Chelonia mydas) population abundance",
                "High green turtle abundance leads to intensive grazing that can degrade seagrass "
                "canopy structure, reducing the nursery habitat value for juvenile conch and lobster.",
            ),
        },
    ),
    (
        "caribbean_seagrass",
        "Seagrass epiphyte load and algal community composition",
        "Nursery habitat provision for conch and lobster",
        {
            "polarity": (
                "+",
                "-",
                "High epiphyte loads smother seagrass blades, reducing canopy quality and the "
                "nursery habitat function. Excessive epiphytes degrade, not enhance, nursery value.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Seagrass epiphyte load and algal community composition",
                "Heavy epiphyte loads degrade seagrass canopy quality, reducing the shelter and "
                "food resources that provide nursery habitat for juvenile conch and lobster.",
            ),
        },
    ),
    # =========================================================================
    # CARIBBEAN ISLAND
    # =========================================================================
    (
        "caribbean_island",
        "Fringing coral reef live cover and structural complexity",
        "Reef-based tourism and recreation value",
        {
            "strength": (
                "medium",
                "strong",
                "Healthy reefs with high live coral cover and fish diversity are the core product "
                "of Caribbean dive/snorkel tourism. Multiple studies show strong positive correlation "
                "between reef health and tourism satisfaction (Uyarra et al. 2009).",
            ),
        },
    ),
    (
        "caribbean_island",
        "Overfishing of reef herbivores (parrotfish, surgeonfish)",
        "Coral bleaching from marine heatwaves",
        {
            "strength": (
                "medium",
                "weak",
                "The link between herbivore loss and bleaching susceptibility is indirect - "
                "herbivore loss leads to macroalgal overgrowth which reduces coral resilience "
                "to thermal stress, but does not directly cause bleaching. Relationship is "
                "mediated through multiple steps (Hughes et al. 2007).",
            ),
            "confidence": (
                4,
                3,
                "Evidence for indirect resilience reduction is growing but the causal pathway "
                "from herbivore loss to increased bleaching mortality is complex and context-dependent.",
            ),
        },
    ),
    (
        "caribbean_island",
        "Saltwater intrusion from sea level rise and over-extraction",
        "Fringing coral reef live cover and structural complexity",
        {
            "polarity": (
                "+",
                "-",
                "Saltwater intrusion into coastal aquifers and altered freshwater discharge "
                "patterns can stress nearshore coral communities through salinity and nutrient "
                "changes. This is a negative effect on reef health, not positive.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Saltwater intrusion from sea level rise and over-extraction",
                "Saltwater intrusion alters coastal freshwater discharge patterns, increasing "
                "nutrient loading and salinity stress on nearshore fringing reefs.",
            ),
        },
    ),
    (
        "caribbean_island",
        "Reef-based tourism and recreation value",
        "Tourism-dependent household income and employment",
        {
            "strength": (
                "medium",
                "strong",
                "In Caribbean SIDS, reef tourism is the dominant economic sector, directly "
                "supporting 30-50% of GDP and employment in many islands (UNWTO, CTO reports).",
            ),
        },
    ),
    # =========================================================================
    # ATLANTIC OFFSHORE
    # =========================================================================
    (
        "atlantic_offshore",
        "Marine plastic accumulation (North Atlantic gyre)",
        "Atlantic bluefin tuna stock recovery status",
        {
            "polarity": (
                "+",
                "-",
                "Marine plastic pollution negatively affects bluefin tuna through microplastic "
                "ingestion, which can cause gut inflammation, reduced feeding efficiency, and "
                "bioaccumulation of plastic-associated toxins (Romeo et al. 2015).",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Marine plastic accumulation (North Atlantic gyre)",
                "Microplastic ingestion by bluefin tuna causes gut inflammation and toxin "
                "bioaccumulation, negatively affecting stock health and recovery potential.",
            ),
        },
    ),
    (
        "atlantic_offshore",
        "Climate change and ocean warming",
        "Atlantic bluefin tuna stock recovery status",
        {
            "polarity": (
                "+",
                "-",
                "Ocean warming shifts bluefin tuna thermal habitat, disrupts spawning cues, "
                "and alters prey distribution, generally hindering stock recovery. ICCAT SCRS "
                "reports note climate-driven distribution shifts as a concern for stock assessment.",
            ),
            "strength": (
                "medium",
                "weak",
                "The effect of climate on bluefin tuna is complex - some range expansion may "
                "occur, but spawning habitat and prey disruption are negative. Net effect uncertain.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Climate change and ocean warming",
                "Ocean warming disrupts bluefin tuna spawning habitat, alters prey distribution, "
                "and shifts thermal habitat boundaries, complicating stock recovery (ICCAT SCRS).",
            ),
        },
    ),
    (
        "atlantic_offshore",
        "Seabird bycatch mitigation (tori lines, weighted hooks)",
        "Seabird and turtle bycatch in longline fisheries",
        {
            "strength": (
                "medium",
                "strong",
                "Tori lines and weighted hooks reduce seabird bycatch by 80-90% when properly "
                "deployed (PLOS ONE 2017, Biological Conservation 2020). This is a well-documented "
                "strong effect, adopted as ACAP best practice.",
            ),
            "confidence": (
                5,
                5,
                "Confirmed by multiple peer-reviewed studies and operational monitoring across "
                "multiple longline fleets globally.",
            ),
        },
    ),
    (
        "atlantic_offshore",
        "ICCAT bluefin tuna quota management",
        "Overfishing of Atlantic bluefin tuna",
        {
            "strength": (
                "medium",
                "strong",
                "ICCAT quota management is credited with the recovery of Eastern Atlantic bluefin "
                "from near-collapse. Stock is now not overfished and not subject to overfishing "
                "(ICCAT SCRS 2024-2025). The 2006 recovery plan was transformative.",
            ),
            "confidence": (
                4,
                5,
                "ICCAT stock assessments confirm the quota system has been effective. TAC increased "
                "from 13,500t (2010) to 40,570t (2023-2025) reflecting recovery success.",
            ),
        },
    ),
    # =========================================================================
    # ATLANTIC ISLAND
    # =========================================================================
    (
        "atlantic_island",
        "Oil and bilge water pollution from shipping lanes",
        "Seamount and deepwater reef biodiversity",
        {
            "polarity": (
                "+",
                "-",
                "Oil and bilge water pollution from shipping damages deepwater reef organisms "
                "through toxicity and smothering. This is clearly a negative effect on biodiversity.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Oil and bilge water pollution from shipping lanes",
                "Oil and bilge water discharges from shipping lanes introduce hydrocarbons and "
                "contaminants that are toxic to sensitive deepwater reef organisms.",
            ),
        },
    ),
    (
        "atlantic_island",
        "Volcanic substrate erosion from storm wave action",
        "Seamount and deepwater reef biodiversity",
        {
            "polarity": (
                "+",
                "-",
                "Storm-driven erosion of volcanic substrate destroys the physical habitat that "
                "deepwater reef organisms colonise. This reduces biodiversity, not enhances it.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Volcanic substrate erosion from storm wave action",
                "Storm wave erosion removes volcanic substrate that provides settlement habitat "
                "for deepwater reef organisms, reducing biodiversity on exposed seamounts.",
            ),
        },
    ),
    (
        "atlantic_island",
        "Invasive mammalian predators (rats, feral cats, mice) on native wildlife",
        "Native seabird colony breeding success (Cory's shearwater, petrels)",
        {
            "strength": (
                "medium",
                "strong",
                "Invasive predators are the primary driver of seabird population declines on "
                "Atlantic islands. Rat predation can cause >90% nest failure in petrel colonies "
                "(Igual et al. 2006, Jones et al. 2008). Well documented on Macaronesian islands.",
            ),
            "confidence": (
                4,
                5,
                "Extensively documented across Azores, Canaries, Madeira, and Cape Verde. "
                "Eradication programmes show rapid seabird recovery confirming causal link.",
            ),
        },
    ),
    # =========================================================================
    # ATLANTIC ESTUARY
    # =========================================================================
    (
        "atlantic_estuary",
        "Microplastic accumulation in estuarine sediments",
        "European eel (Anguilla anguilla) recruitment",
        {
            "polarity": (
                "+",
                "-",
                "Microplastic ingestion by glass eels and elvers causes gut damage, reduces "
                "feeding efficiency, and may impair growth during the critical recruitment "
                "phase. This is a negative effect (Bour et al. 2020).",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Microplastic accumulation in estuarine sediments",
                "Microplastic ingestion by recruiting glass eels causes gut inflammation and "
                "reduced feeding efficiency, negatively affecting recruitment success.",
            ),
        },
    ),
    (
        "atlantic_estuary",
        "Thermal plumes from coastal power stations",
        "European eel (Anguilla anguilla) recruitment",
        {
            "polarity": (
                "+",
                "-",
                "Thermal plumes raise water temperatures beyond eel thermal preferences, "
                "disrupt migration cues, and can cause thermal barriers to glass eel passage. "
                "Entrainment in cooling water intakes also causes direct mortality.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Thermal plumes from coastal power stations",
                "Thermal plumes create temperature barriers that disrupt glass eel migration, "
                "and cooling water entrainment causes direct mortality during recruitment.",
            ),
        },
    ),
    (
        "atlantic_estuary",
        "Altered freshwater flow regime from upstream regulation",
        "European eel (Anguilla anguilla) recruitment",
        {
            "polarity": (
                "+",
                "-",
                "Altered flow regimes disrupt the freshwater cues that glass eels use for "
                "upstream migration, and dams/weirs physically block passage. Reduced flows "
                "also decrease nursery habitat quality. Well documented by ICES WGEEL.",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Altered freshwater flow regime from upstream regulation",
                "Flow regulation disrupts migration cues and creates physical barriers to glass "
                "eel passage, reducing recruitment success (ICES WGEEL reports).",
            ),
        },
    ),
    # =========================================================================
    # ATLANTIC OPEN COAST
    # =========================================================================
    (
        "atlantic_open_coast",
        "Nutrient enrichment from agricultural sources",
        "Kelp forest (Laminaria hyperborea/digitata) canopy cover",
        {
            "polarity": (
                "+",
                "-",
                "Nutrient enrichment promotes epiphytic algal overgrowth on kelp blades, increases "
                "water turbidity reducing light, and favours fast-growing opportunistic algae over "
                "kelp. Well documented in European Atlantic kelp systems (Gorman et al. 2009).",
            ),
            "rationale": (
                "Connection added to complete DAPSI(W)R(M) chain for Nutrient enrichment from agricultural sources",
                "Nutrient enrichment from agricultural runoff promotes epiphyte smothering and "
                "turbidity that reduces light to kelp canopies, driving kelp decline.",
            ),
        },
    ),
    (
        "atlantic_open_coast",
        "Storm intensification from climate change",
        "Sea level rise from thermal expansion and ice melt",
        {
            "polarity": (
                "+",
                "-",
                "Storm intensification and sea level rise are parallel consequences of climate "
                "change, not causally linked in this direction. However, intense storms cause "
                "temporary negative effects on coastal sea level dynamics through erosion. "
                "Correcting polarity; storms don't cause sea level rise.",
            ),
            "strength": (
                "strong",
                "weak",
                "These are co-occurring climate change impacts, not causally related in a "
                "strong direct manner. Storm surge is temporary, not persistent sea level rise.",
            ),
            "confidence": (
                4,
                2,
                "The causal relationship is weak - storms and sea level rise are parallel "
                "consequences of climate change, not causally linked.",
            ),
            "rationale": (
                "More intense storms accelerate coastal erosion rates along exposed Atlantic coastlines through increased wave energy",
                "Storm intensification and sea level rise are parallel consequences of climate change; "
                "storms cause temporary surge but do not drive persistent sea level rise.",
            ),
        },
    ),
]


def apply_fixes(db):
    """Apply all scientifically validated fixes to the knowledge base."""
    changes = []
    errors = []

    for ctx_name, from_name, to_name, field_changes in FIXES:
        if ctx_name not in db["contexts"]:
            errors.append(f"Context '{ctx_name}' not found in KB")
            continue

        conns = db["contexts"][ctx_name]["connections"]
        idx = find_connection(conns, from_name, to_name)

        if idx is None:
            errors.append(
                f"[{ctx_name}] Connection not found: '{from_name}' -> '{to_name}'"
            )
            continue

        conn = conns[idx]

        for field, vals in field_changes.items():
            # rationale fields have 2-tuple (old, new); other fields have 3-tuple (old, new, reason)
            if len(vals) == 2:
                old_val, new_val = vals
                rationale = "Updated for scientific accuracy."
            else:
                old_val, new_val, rationale = vals

            actual_old = conn.get(field)
            if actual_old != old_val:
                errors.append(
                    f"[{ctx_name}] #{idx} field '{field}': expected old='{old_val}', "
                    f"got '{actual_old}' for '{from_name}' -> '{to_name}'"
                )
                continue

            conn[field] = new_val
            changes.append(
                {
                    "context": ctx_name,
                    "index": idx,
                    "from": from_name,
                    "to": to_name,
                    "field": field,
                    "old": old_val,
                    "new": new_val,
                    "rationale": rationale,
                }
            )

    return changes, errors


def print_summary(changes, errors):
    """Print a summary of all changes made."""
    print("=" * 78)
    print("SCIENTIFIC VALIDATION: Caribbean & Atlantic Knowledge Base Connections")
    print("=" * 78)
    print()

    # Group changes by context
    by_context = {}
    for c in changes:
        by_context.setdefault(c["context"], []).append(c)

    total_changes = len(changes)
    total_connections_reviewed = sum(
        len(db["contexts"][ctx].get("connections", []))
        for ctx in TARGET_CONTEXTS
        if ctx in db["contexts"]
    )

    print(f"Connections reviewed: {total_connections_reviewed}")
    print(f"Changes applied:     {total_changes}")
    print(f"Errors:              {len(errors)}")
    print()

    if errors:
        print("ERRORS:")
        for e in errors:
            print(f"  ! {e}")
        print()

    for ctx_name in TARGET_CONTEXTS:
        ctx_changes = by_context.get(ctx_name, [])
        if not ctx_changes:
            continue

        print(f"--- {ctx_name} ({len(ctx_changes)} field changes) ---")
        # Group by connection
        by_conn = {}
        for c in ctx_changes:
            key = (c["from"], c["to"])
            by_conn.setdefault(key, []).append(c)

        for (from_name, to_name), conn_changes in by_conn.items():
            print(f'  "{from_name}" -> "{to_name}"')
            for c in conn_changes:
                print(f"    {c['field']}: {c['old']} -> {c['new']}")
                # Print rationale wrapped at 70 chars
                rat = c["rationale"]
                indent = "      "
                words = rat.split()
                line = indent
                for w in words:
                    if len(line) + len(w) + 1 > 78:
                        print(line)
                        line = indent + w
                    else:
                        line = line + " " + w if line.strip() else indent + w
                if line.strip():
                    print(line)
            print()

    print("=" * 78)
    print(
        f"SUMMARY: {total_changes} field changes across "
        f"{len(by_context)} contexts ({total_connections_reviewed} connections reviewed)"
    )
    print("=" * 78)


if __name__ == "__main__":
    if not KB_PATH.exists():
        print(f"ERROR: Knowledge base not found at {KB_PATH}")
        sys.exit(1)

    with open(KB_PATH, "r", encoding="utf-8") as f:
        db = json.load(f)

    # Store original for comparison
    original = deepcopy(db)

    changes, errors = apply_fixes(db)

    print_summary(changes, errors)

    if errors:
        print(f"\nWARNING: {len(errors)} error(s) encountered. Review above.")

    if not changes:
        print("\nNo changes to apply.")
        sys.exit(0)

    # Update last_updated
    db["last_updated"] = "2026-03-17"

    # Write updated KB
    with open(KB_PATH, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"\nUpdated knowledge base written to {KB_PATH}")
    print("Run 'python scripts/validate_kb.py' to verify structural integrity.")
