#!/usr/bin/env python3
"""One-shot script to apply Part B of the KB quality cleanup.

Removes 11 invalid connections and reclassifies 3 elements in
data/ses_knowledge_db.json. Modifies the file in place after creating
a .backup copy.

Usage:
    micromamba run -n shiny python scripts/kb_audit/apply_part_b_fixes.py
"""

import json
import shutil
import sys
from pathlib import Path


# Part B1-B5: Connections to remove (match on context + from + to substrings)
REMOVALS = [
    # B1: 6 A→S connections in Macaronesia
    ("macaronesia_island", "Coastal aquaculture", "Coastal water quality index"),
    ("macaronesia_island", "Scientific research and monitoring", "Rocky reef community structure"),
    ("macaronesia_island", "Submarine cable and pipeline installation", "Cystoseira"),
    ("macaronesia_open_coast", "Offshore wind and wave energy development", "Pelagic shark"),
    ("macaronesia_open_coast", "Marine scientific research expeditions", "Pelagic Sargassum"),
    ("macaronesia_open_coast", "Military sonar exercises", "Large cetacean population health"),
    # B2: P→W
    ("macaronesia_island", "Ocean warming and marine heatwaves", "Coastal property values"),
    # B3: S→W
    ("macaronesia_open_coast", "Pelagic Sargassum community extent", "Marine ecotourism income"),
    # B4: I→I
    ("macaronesia_open_coast", "Loss of apex predator trophic function", "Disrupted pelagic food web"),
    # B5: 2 A→W
    ("macaronesia_island", "Recreational diving and whale watching", "Recreational wellbeing"),
    ("macaronesia_open_coast", "Industrial tuna purse-seine", "Cultural significance of traditional tuna fishing"),
]

# Part B6-B7: Element reclassifications
RECLASSIFICATIONS = [
    # B6: 2 drivers → responses
    {
        "context": "macaronesia_island",
        "element_name_substring": "EU Biodiversity Strategy 2030 targets",
        "from_array": "drivers",
        "to_array": "responses",
        "update_conn_field": "from_type",
        "new_type": "responses",
    },
    {
        "context": "macaronesia_seamount",
        "element_name_substring": "OSPAR and CBD conservation commitments",
        "from_array": "drivers",
        "to_array": "responses",
        "update_conn_field": "from_type",
        "new_type": "responses",
    },
    # B7: 1 pressures → activities (target element)
    {
        "context": "macaronesia_island",
        "element_name_substring": "Coastal urbanization and land reclamation",
        "from_array": "pressures",
        "to_array": "activities",
        "update_conn_field": "to_type",
        "new_type": "activities",
        "extra_flag": "reclassified-from-pressure-2026-04-11; needs downstream A→P connections",
    },
]


def apply_removals(kb: dict, removals: list) -> int:
    """Remove connections matching (context, from_substr, to_substr)."""
    removed = 0
    for ctx_name, from_substr, to_substr in removals:
        ctx = kb.get("contexts", {}).get(ctx_name)
        if not ctx:
            print(f"WARNING: context '{ctx_name}' not found", file=sys.stderr)
            continue
        conns = ctx.get("connections", [])
        before = len(conns)
        ctx["connections"] = [
            c for c in conns
            if not (from_substr in c.get("from", "") and to_substr in c.get("to", ""))
        ]
        n = before - len(ctx["connections"])
        if n == 0:
            print(f"WARNING: no match for {ctx_name}: {from_substr} -> {to_substr}", file=sys.stderr)
        removed += n
    return removed


def apply_reclassifications(kb: dict, reclass: list) -> int:
    """Move elements between category arrays and update connection types."""
    count = 0
    for r in reclass:
        ctx = kb.get("contexts", {}).get(r["context"])
        if not ctx:
            print(f"WARNING: context '{r['context']}' not found", file=sys.stderr)
            continue

        # Find and move the element dict
        from_arr = ctx.get(r["from_array"], [])
        to_arr = ctx.setdefault(r["to_array"], [])

        moved_elem = None
        new_from_arr = []
        for elem in from_arr:
            elem_name = elem.get("name", "") if isinstance(elem, dict) else str(elem)
            if r["element_name_substring"] in elem_name and moved_elem is None:
                moved_elem = elem
                if isinstance(elem, dict) and "extra_flag" in r:
                    elem["flag"] = r["extra_flag"]
            else:
                new_from_arr.append(elem)
        ctx[r["from_array"]] = new_from_arr

        if moved_elem is None:
            print(f"WARNING: element '{r['element_name_substring']}' not found in {r['context']}.{r['from_array']}", file=sys.stderr)
            continue

        to_arr.append(moved_elem)

        # Update connections that reference this element
        conn_updates = 0
        for conn in ctx.get("connections", []):
            if r["update_conn_field"] == "from_type":
                if r["element_name_substring"] in conn.get("from", ""):
                    conn["from_type"] = r["new_type"]
                    conn_updates += 1
            elif r["update_conn_field"] == "to_type":
                if r["element_name_substring"] in conn.get("to", ""):
                    conn["to_type"] = r["new_type"]
                    conn_updates += 1

        print(f"Reclassified {r['element_name_substring'][:40]}... "
              f"({r['from_array']} -> {r['to_array']}, {conn_updates} connection(s) updated)")
        count += 1
    return count


def main():
    project_root = Path(__file__).parent.parent.parent
    kb_path = project_root / "data" / "ses_knowledge_db.json"
    backup_path = kb_path.with_suffix(".json.backup-part-b")

    print(f"Reading {kb_path}")
    with open(kb_path, "r", encoding="utf-8") as f:
        kb = json.load(f)

    # Backup
    print(f"Creating backup: {backup_path}")
    shutil.copy2(kb_path, backup_path)

    # Apply changes
    print("\nApplying removals...")
    n_removed = apply_removals(kb, REMOVALS)
    print(f"Removed {n_removed} connections (expected 11)")

    print("\nApplying reclassifications...")
    n_reclass = apply_reclassifications(kb, RECLASSIFICATIONS)
    print(f"Reclassified {n_reclass} elements (expected 3)")

    if n_removed != 11 or n_reclass != 3:
        print("\nERROR: counts do not match expected values. Aborting write.", file=sys.stderr)
        sys.exit(1)

    # Write
    print(f"\nWriting {kb_path}")
    with open(kb_path, "w", encoding="utf-8") as f:
        json.dump(kb, f, indent=2, ensure_ascii=False)

    # Validate
    with open(kb_path, "r", encoding="utf-8") as f:
        json.load(f)
    print("JSON validated successfully.")
    print("\nDone. Original backed up to:", backup_path)


if __name__ == "__main__":
    main()
