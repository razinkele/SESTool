#!/usr/bin/env python3
"""Fix 68 element misclassifications in ses_knowledge_db.json."""

import json
import os
from collections import defaultdict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DB_PATH = os.path.join(PROJECT_ROOT, "data", "ses_knowledge_db.json")

with open(DB_PATH, "r", encoding="utf-8") as f:
    db = json.load(f)

changes_log = defaultdict(list)

# ── Helpers ──────────────────────────────────────────────────────────────

def find_element(element_list, name):
    """Find element dict by exact name."""
    for e in element_list:
        if e["name"] == name:
            return e
    return None

def remove_element(element_list, name):
    """Remove element by name, return the removed dict or None."""
    for i, e in enumerate(element_list):
        if e["name"] == name:
            return element_list.pop(i)
    return None

def add_element_if_missing(element_list, name, relevance=0.8):
    """Add element if not already present."""
    if not find_element(element_list, name):
        element_list.append({"name": name, "relevance": relevance})
        return True
    return False

def rename_element_in_list(element_list, old_name, new_name):
    """Rename element in list. Returns True if found."""
    e = find_element(element_list, old_name)
    if e:
        e["name"] = new_name
        return True
    return False

def rename_in_connections(connections, old_name, new_name, old_type=None, new_type=None):
    """Update connection from/to fields. Optionally update from_type/to_type."""
    count = 0
    for conn in connections:
        if conn["from"] == old_name:
            conn["from"] = new_name
            if old_type and new_type and conn.get("from_type") == old_type:
                conn["from_type"] = new_type
            count += 1
        if conn["to"] == old_name:
            conn["to"] = new_name
            if old_type and new_type and conn.get("to_type") == old_type:
                conn["to_type"] = new_type
            count += 1
    return count

def move_element(ctx, ctx_name, elem_name, from_cat, to_cat):
    """Move element from one category to another within a context. Update connections."""
    elem = remove_element(ctx[from_cat], elem_name)
    if elem is None:
        return False
    # Add to target category
    add_element_if_missing(ctx[to_cat], elem_name, elem.get("relevance", 0.8))
    # Update connections
    if "connections" in ctx:
        for conn in ctx["connections"]:
            if conn["from"] == elem_name and conn.get("from_type") == from_cat:
                conn["from_type"] = to_cat
            if conn["to"] == elem_name and conn.get("to_type") == from_cat:
                conn["to_type"] = to_cat
    changes_log[ctx_name].append(f"  Moved '{elem_name}' from {from_cat} to {to_cat}")
    return True

def merge_element(ctx, ctx_name, alt_name, canonical_name, category):
    """Merge alt_name into canonical_name. Redirect connections, remove alt."""
    removed = remove_element(ctx[category], alt_name)
    if removed is None:
        return False
    # Ensure canonical exists
    add_element_if_missing(ctx[category], canonical_name, removed.get("relevance", 0.8))
    # Redirect connections
    if "connections" in ctx:
        for conn in ctx["connections"]:
            if conn["from"] == alt_name:
                conn["from"] = canonical_name
            if conn["to"] == alt_name:
                conn["to"] = canonical_name
    changes_log[ctx_name].append(f"  Merged '{alt_name}' -> '{canonical_name}' in {category}")
    return True

def rename_element(ctx, ctx_name, old_name, new_name, category):
    """Rename element and update all connections."""
    if not rename_element_in_list(ctx[category], old_name, new_name):
        return False
    if "connections" in ctx:
        rename_in_connections(ctx["connections"], old_name, new_name)
    changes_log[ctx_name].append(f"  Renamed '{old_name}' -> '{new_name}' in {category}")
    return True


# ═══════════════════════════════════════════════════════════════════════
# PATTERN A: Rename activity-phrased Drivers to demand-phrased (13 renames)
# ═══════════════════════════════════════════════════════════════════════

RENAMES = {
    "Agricultural intensification in catchment": "Agricultural production demand in catchment",
    "Agricultural intensification in surrounding plains": "Agricultural production demand",
    "Agricultural production in Danube basin": "Food production demand from Danube basin",
    "Coastal population growth and urbanisation": "Coastal population growth and housing demand",
    "Coastal urbanisation pressure": "Coastal housing and infrastructure demand",
    "Watershed land-use intensification": "Agricultural land-use demand in watershed",
    "Coastal resort and marina development": "Coastal resort and marina demand",
    "Coastal tourism and resort development": "Coastal tourism demand",
    "Coastal development for resort infrastructure": "Tourism infrastructure demand",
    "Industrial and urban development along coast": "Industrial and urban land demand on coast",
}

print("=" * 70)
print("PATTERN A — Rename activity-phrased Drivers")
print("=" * 70)
rename_count = 0
for ctx_name, ctx in db["contexts"].items():
    for old_name, new_name in RENAMES.items():
        if find_element(ctx.get("drivers", []), old_name):
            rename_element(ctx, ctx_name, old_name, new_name, "drivers")
            rename_count += 1

print(f"  {rename_count} renames applied across contexts")

# ═══════════════════════════════════════════════════════════════════════
# PATTERN A: Move natural-process Drivers to Pressures
# ═══════════════════════════════════════════════════════════════════════

print("\nPATTERN A — Move natural-process Drivers to Pressures")
print("-" * 50)

# "Climate change and ocean warming" → pressures in all contexts
climate_contexts = []
for ctx_name, ctx in db["contexts"].items():
    if find_element(ctx.get("drivers", []), "Climate change and ocean warming"):
        move_element(ctx, ctx_name, "Climate change and ocean warming", "drivers", "pressures")
        # Add replacement driver if no other drivers exist that could feed the chain
        add_element_if_missing(ctx["drivers"], "Climate change adaptation needs", 0.8)
        changes_log[ctx_name].append("  Added replacement driver 'Climate change adaptation needs'")
        climate_contexts.append(ctx_name)
print(f"  Moved 'Climate change and ocean warming' in {len(climate_contexts)} contexts: {', '.join(climate_contexts)}")

# "Climate warming of shallow Baltic bays" → pressures
for ctx_name, ctx in db["contexts"].items():
    if find_element(ctx.get("drivers", []), "Climate warming of shallow Baltic bays"):
        move_element(ctx, ctx_name, "Climate warming of shallow Baltic bays", "drivers", "pressures")
        add_element_if_missing(ctx["drivers"], "Climate change adaptation needs", 0.8)
        changes_log[ctx_name].append("  Added replacement driver 'Climate change adaptation needs'")
        print(f"  Moved 'Climate warming of shallow Baltic bays' in {ctx_name}")

# "Climate-driven Arctic warming and glacial retreat" → pressures
for ctx_name, ctx in db["contexts"].items():
    if find_element(ctx.get("drivers", []), "Climate-driven Arctic warming and glacial retreat"):
        move_element(ctx, ctx_name, "Climate-driven Arctic warming and glacial retreat", "drivers", "pressures")
        add_element_if_missing(ctx["drivers"], "Climate change adaptation needs", 0.8)
        changes_log[ctx_name].append("  Added replacement driver 'Climate change adaptation needs'")
        print(f"  Moved 'Climate-driven Arctic warming and glacial retreat' in {ctx_name}")

# "Climate change impacts" in generic_fallback
gf = db["generic_fallback"]
elem = remove_element(gf["drivers"], "Climate change impacts")
if elem:
    add_element_if_missing(gf["pressures"], "Climate change impacts", elem.get("relevance", 0.8))
    add_element_if_missing(gf["drivers"], "Climate change adaptation and resilience needs", 0.8)
    changes_log["generic_fallback"].append("  Moved 'Climate change impacts' from drivers to pressures")
    changes_log["generic_fallback"].append("  Added fallback driver 'Climate change adaptation and resilience needs'")
    print("  Moved 'Climate change impacts' in generic_fallback")

# ═══════════════════════════════════════════════════════════════════════
# PATTERN A: Move ecological-state Drivers to States
# ═══════════════════════════════════════════════════════════════════════

print("\nPATTERN A — Move ecological-state Drivers to States")
print("-" * 50)

for ctx_name, ctx in db["contexts"].items():
    if find_element(ctx.get("drivers", []), "Green turtle population recovery (post-harvest moratorium)"):
        move_element(ctx, ctx_name, "Green turtle population recovery (post-harvest moratorium)", "drivers", "states")
        add_element_if_missing(ctx["drivers"], "Marine biodiversity conservation demand", 0.8)
        changes_log[ctx_name].append("  Added replacement driver 'Marine biodiversity conservation demand'")
        print(f"  Moved 'Green turtle population recovery' in {ctx_name}")

for ctx_name, ctx in db["contexts"].items():
    if find_element(ctx.get("drivers", []), "Seal population recovery concerns"):
        move_element(ctx, ctx_name, "Seal population recovery concerns", "drivers", "states")
        add_element_if_missing(ctx["drivers"], "Marine biodiversity conservation demand", 0.8)
        changes_log[ctx_name].append("  Added replacement driver 'Marine biodiversity conservation demand'")
        print(f"  Moved 'Seal population recovery concerns' in {ctx_name}")

# ═══════════════════════════════════════════════════════════════════════
# PATTERN B: Move 23 Pressure elements to States
# ═══════════════════════════════════════════════════════════════════════

print("\n" + "=" * 70)
print("PATTERN B — Move Pressure elements to States")
print("=" * 70)

PRESSURE_TO_STATE = [
    "Crown-of-thorns starfish (Acanthaster planci) outbreaks",
    "Invasive comb jelly (Mnemiopsis leidyi)",
    "Invasive round goby altering nearshore food webs",
    "Invasive Manila clam (Ruditapes philippinarum) spread",
    "Chinese mitten crab and Pacific oyster (Eriocheir sinensis, Magallana gigas) invasion",
    "Round goby and Chinese mitten crab (Neogobius melanostomus, Eriocheir sinensis) invasion",
    "Pacific oyster (Magallana gigas) reef expansion displacing native beds",
    "Invasive Caulerpa cylindracea displacement of native habitats",
    "Invasive algae colonisation of volcanic substrates",
    "Invasive tropical species establishment",
    "Invasive species threatening endemic island biota",
    "Deep-water hypoxia (dead zones)",
    "Hypoxia and hydrogen sulphide in deep waters",
    "Stony coral tissue loss disease (SCTLD)",
    "Sargassum inundation events",
    "Overgrazing by recovering green turtle populations",
    "Grey seal predation on coastal fish stocks and gear damage",
    "Coastal erosion and sediment deficit",
    "Coastal erosion of limestone and glacial till shores",
]

# Handle merges first
# "Crown-of-thorns starfish (Acanthaster) outbreaks" -> merge with "(Acanthaster planci)" version
# "Sargassum mass inundation events" -> merge with "Sargassum inundation events"

p2s_count = 0
for ctx_name, ctx in db["contexts"].items():
    # Merge "Crown-of-thorns starfish (Acanthaster) outbreaks" into canonical
    if find_element(ctx.get("pressures", []), "Crown-of-thorns starfish (Acanthaster) outbreaks"):
        # First move the canonical if it exists in pressures, or create it in states
        merge_element(ctx, ctx_name,
                      "Crown-of-thorns starfish (Acanthaster) outbreaks",
                      "Crown-of-thorns starfish (Acanthaster planci) outbreaks",
                      "pressures")
        # Now the canonical name is in pressures; it will be moved to states below

    # Merge "Sargassum mass inundation events" into "Sargassum inundation events"
    if find_element(ctx.get("pressures", []), "Sargassum mass inundation events"):
        merge_element(ctx, ctx_name,
                      "Sargassum mass inundation events",
                      "Sargassum inundation events",
                      "pressures")

    # Now move all pressures to states
    for elem_name in PRESSURE_TO_STATE:
        if find_element(ctx.get("pressures", []), elem_name):
            move_element(ctx, ctx_name, elem_name, "pressures", "states")
            p2s_count += 1

print(f"  Moved {p2s_count} pressure->state elements across contexts")

# ═══════════════════════════════════════════════════════════════════════
# PATTERN C: Move 12 Impact elements to Welfare (10) or States (2)
# ═══════════════════════════════════════════════════════════════════════

print("\n" + "=" * 70)
print("PATTERN C — Move Impact elements to Welfare or States")
print("=" * 70)

IMPACT_TO_WELFARE = [
    "Tuna export revenue and processing employment",
    "Renewable energy generation capacity",
    "Renewable energy generation from offshore wind",
    "Shipping and trade route services",
    "Transatlantic shipping corridor services",
    "Shipping route provision",
    "Shipping route accessibility in summer",
    "Port and navigation accessibility",
    "Shellfish aquaculture production",
]

IMPACT_TO_STATE = [
    "Seabird population sustainability",
    "Coastal food web integrity",
]

ic_count = 0
for ctx_name, ctx in db["contexts"].items():
    # Merge "Navigation and port accessibility" into "Port and navigation accessibility"
    if find_element(ctx.get("impacts", []), "Navigation and port accessibility"):
        merge_element(ctx, ctx_name,
                      "Navigation and port accessibility",
                      "Port and navigation accessibility",
                      "impacts")

    for elem_name in IMPACT_TO_WELFARE:
        if find_element(ctx.get("impacts", []), elem_name):
            move_element(ctx, ctx_name, elem_name, "impacts", "welfare")
            ic_count += 1

    for elem_name in IMPACT_TO_STATE:
        if find_element(ctx.get("impacts", []), elem_name):
            move_element(ctx, ctx_name, elem_name, "impacts", "states")
            ic_count += 1

print(f"  Moved {ic_count} impact elements across contexts")

# ═══════════════════════════════════════════════════════════════════════
# PATTERN D: Move 7 Activity elements to Pressures
# ═══════════════════════════════════════════════════════════════════════

print("\n" + "=" * 70)
print("PATTERN D — Move Activity elements to Pressures")
print("=" * 70)

ACTIVITY_TO_PRESSURE = [
    "Hurricane formation and intensification",
    "Green turtle foraging on seagrass beds",
    "Global greenhouse gas emissions",
    "Agricultural and urban watershed runoff",
    "Danube-origin nutrient and pollutant loading",
    "Military munition dumping legacy",
    "Coastal farmland drainage to nearshore waters",
]

ad_count = 0
for ctx_name, ctx in db["contexts"].items():
    for elem_name in ACTIVITY_TO_PRESSURE:
        if find_element(ctx.get("activities", []), elem_name):
            move_element(ctx, ctx_name, elem_name, "activities", "pressures")
            ad_count += 1

print(f"  Moved {ad_count} activity->pressure elements across contexts")

# ═══════════════════════════════════════════════════════════════════════
# PATTERN E: Move 7 Welfare elements to Impacts
# ═══════════════════════════════════════════════════════════════════════

print("\n" + "=" * 70)
print("PATTERN E — Move Welfare elements to Impacts")
print("=" * 70)

WELFARE_TO_IMPACT = [
    "Climate mitigation value of blue carbon storage",
    "Climate regulation benefits (carbon sink)",
    "Global climate stability benefit",
    "Seabird conservation value (public concern)",
    "Shorebird conservation as international heritage value",
    "Marine scientific knowledge advancement",
    "Scientific and educational value",
]

we_count = 0
for ctx_name, ctx in db["contexts"].items():
    for elem_name in WELFARE_TO_IMPACT:
        if find_element(ctx.get("welfare", []), elem_name):
            move_element(ctx, ctx_name, elem_name, "welfare", "impacts")
            we_count += 1

print(f"  Moved {we_count} welfare->impact elements across contexts")

# ═══════════════════════════════════════════════════════════════════════
# SAVE
# ═══════════════════════════════════════════════════════════════════════

with open(DB_PATH, "w", encoding="utf-8") as f:
    json.dump(db, f, indent=2, ensure_ascii=False)

print("\n" + "=" * 70)
print("SUMMARY")
print("=" * 70)

total_changes = sum(len(v) for v in changes_log.values())
print(f"Total changes: {total_changes}")
print(f"Contexts modified: {len(changes_log)}")
print(f"\nBreakdown:")
print(f"  Pattern A renames: {rename_count}")
print(f"  Pattern A climate moves: {len(climate_contexts) + 2}")  # +2 for Baltic bays and Arctic
print(f"  Pattern A ecological-state moves: 2")
print(f"  Pattern B pressure->state: {p2s_count}")
print(f"  Pattern C impact->welfare/state: {ic_count}")
print(f"  Pattern D activity->pressure: {ad_count}")
print(f"  Pattern E welfare->impact: {we_count}")
print(f"\nPer-context details:")
for ctx_name in sorted(changes_log.keys()):
    entries = changes_log[ctx_name]
    print(f"\n  [{ctx_name}] ({len(entries)} changes):")
    for entry in entries:
        print(f"    {entry}")

print("\nFile saved:", DB_PATH)
