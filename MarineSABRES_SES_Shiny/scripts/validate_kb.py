#!/usr/bin/env python3
"""
Validate DAPSI(W)R(M) knowledge base integrity.

Checks:
  1. Cross-category conflicts (elements in multiple categories across contexts)
  2. Connection flow validity (only approved DAPSI(W)R(M) transitions)
  3. Orphan elements per context (listed but unused in connections)
  4. Reversibility vocabulary
  5. Temporal lag format
  6. Confidence distribution

Exit code 1 if any FAIL (checks 1 or 2). Exit code 0 otherwise.
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

# Resolve input file relative to this script's grandparent (project root)
PROJECT_ROOT = Path(__file__).resolve().parent.parent
KB_PATH = PROJECT_ROOT / "data" / "ses_knowledge_db.json"

# Category keys in the KB
CATEGORIES = ["drivers", "activities", "pressures", "states", "impacts", "welfare", "responses"]

# Valid connection flows expressed as (from_type, to_type)
VALID_FLOWS = {
    ("drivers", "activities"),       # D -> A
    ("activities", "pressures"),     # A -> P
    ("pressures", "states"),         # P -> S
    ("states", "impacts"),           # S -> I
    ("impacts", "welfare"),          # I -> W
    ("welfare", "drivers"),          # W -> D
    ("responses", "activities"),     # R -> A
    ("responses", "pressures"),      # R -> P
    ("responses", "drivers"),        # R -> D
    ("states", "states"),            # S -> S
    ("pressures", "pressures"),      # P -> P
    ("activities", "activities"),    # A -> A
}

VALID_REVERSIBILITY = {"reversible", "partially_reversible", "irreversible"}
VALID_TEMPORAL_LAG = {"immediate", "short-term", "medium-term", "long-term"}


def load_kb():
    with open(KB_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def check_cross_category_conflicts(db):
    """Check 1: elements appearing in multiple categories across all contexts."""
    # Map element name -> set of categories it appears in (across all contexts)
    element_categories = defaultdict(set)
    for ctx_name, ctx in db["contexts"].items():
        for cat in CATEGORIES:
            for elem in ctx.get(cat, []):
                element_categories[elem["name"]].add(cat)

    conflicts = {name: cats for name, cats in element_categories.items() if len(cats) > 1}

    print("=" * 70)
    print("CHECK 1: Cross-category conflicts")
    print("=" * 70)
    if conflicts:
        print(f"FAIL — {len(conflicts)} element(s) appear in multiple categories:\n")
        for name, cats in sorted(conflicts.items()):
            print(f"  - \"{name}\"")
            print(f"    categories: {', '.join(sorted(cats))}")
        print()
        return False
    else:
        print(f"PASS — all elements belong to a single category across contexts.\n")
        return True


def check_connection_flows(db):
    """Check 2: every connection must use a valid DAPSI(W)R(M) flow."""
    print("=" * 70)
    print("CHECK 2: Connection flow validity")
    print("=" * 70)

    invalid = []
    total = 0
    for ctx_name, ctx in db["contexts"].items():
        for i, conn in enumerate(ctx.get("connections", [])):
            total += 1
            flow = (conn["from_type"], conn["to_type"])
            if flow not in VALID_FLOWS:
                invalid.append({
                    "context": ctx_name,
                    "index": i,
                    "from": conn["from"],
                    "from_type": conn["from_type"],
                    "to": conn["to"],
                    "to_type": conn["to_type"],
                })

    if invalid:
        print(f"FAIL — {len(invalid)} invalid flow(s) out of {total} connections:\n")
        for item in invalid:
            print(f"  [{item['context']}] #{item['index']}")
            print(f"    {item['from_type']} -> {item['to_type']}")
            print(f"    \"{item['from']}\" -> \"{item['to']}\"")
        print()
        return False
    else:
        print(f"PASS — all {total} connections use valid flows.\n")
        return True


def check_orphan_elements(db):
    """Check 3: elements listed in a context but not referenced in any connection."""
    print("=" * 70)
    print("CHECK 3: Orphan elements per context")
    print("=" * 70)

    total_elements = 0
    total_orphans = 0

    for ctx_name, ctx in sorted(db["contexts"].items()):
        # Collect all element names per category
        all_elements = {}
        for cat in CATEGORIES:
            for elem in ctx.get(cat, []):
                all_elements[elem["name"]] = cat

        # Collect names referenced in connections
        connected = set()
        for conn in ctx.get("connections", []):
            connected.add(conn["from"])
            connected.add(conn["to"])

        orphans = {name: cat for name, cat in all_elements.items() if name not in connected}
        n_elem = len(all_elements)
        n_orphan = len(orphans)
        total_elements += n_elem
        total_orphans += n_orphan
        rate = (n_orphan / n_elem * 100) if n_elem else 0

        status = "WARN" if n_orphan > 0 else "OK"
        print(f"  [{status}] {ctx_name}: {n_orphan}/{n_elem} orphans ({rate:.0f}%)")
        if orphans:
            for name, cat in sorted(orphans.items(), key=lambda x: x[1]):
                print(f"        - [{cat}] {name}")

    overall_rate = (total_orphans / total_elements * 100) if total_elements else 0
    print(f"\n  Overall: {total_orphans}/{total_elements} orphans ({overall_rate:.1f}%)\n")


def check_reversibility(db):
    """Check 4: reversibility values must be from the allowed vocabulary."""
    print("=" * 70)
    print("CHECK 4: Reversibility vocabulary")
    print("=" * 70)

    bad = []
    values = defaultdict(int)
    for ctx_name, ctx in db["contexts"].items():
        for conn in ctx.get("connections", []):
            val = conn.get("reversibility")
            if val is not None:
                values[val] += 1
                if val not in VALID_REVERSIBILITY:
                    bad.append((ctx_name, conn["from"], conn["to"], val))

    print(f"  Allowed: {', '.join(sorted(VALID_REVERSIBILITY))}")
    print(f"  Distribution:")
    for v, count in sorted(values.items(), key=lambda x: -x[1]):
        flag = " *** INVALID" if v not in VALID_REVERSIBILITY else ""
        print(f"    {v}: {count}{flag}")

    if bad:
        print(f"\n  WARN — {len(bad)} connection(s) with invalid reversibility:")
        for ctx, fr, to, val in bad:
            print(f"    [{ctx}] \"{fr}\" -> \"{to}\": \"{val}\"")
    else:
        print(f"\n  PASS — all values use valid vocabulary.")
    print()


def check_temporal_lag(db):
    """Check 5: temporal lag must be categorical, not numeric."""
    print("=" * 70)
    print("CHECK 5: Temporal lag format")
    print("=" * 70)

    bad = []
    values = defaultdict(int)
    for ctx_name, ctx in db["contexts"].items():
        for conn in ctx.get("connections", []):
            val = conn.get("temporal_lag")
            if val is not None:
                values[val] += 1
                # Flag if not in valid set or if it looks numeric
                is_numeric = False
                if isinstance(val, (int, float)):
                    is_numeric = True
                elif isinstance(val, str):
                    try:
                        float(val)
                        is_numeric = True
                    except ValueError:
                        pass
                if val not in VALID_TEMPORAL_LAG or is_numeric:
                    bad.append((ctx_name, conn["from"], conn["to"], val))

    print(f"  Allowed: {', '.join(sorted(VALID_TEMPORAL_LAG))}")
    print(f"  Distribution:")
    for v, count in sorted(values.items(), key=lambda x: -x[1]):
        flag = " *** INVALID" if v not in VALID_TEMPORAL_LAG else ""
        print(f"    {v}: {count}{flag}")

    if bad:
        print(f"\n  WARN — {len(bad)} connection(s) with non-standard temporal lag:")
        for ctx, fr, to, val in bad:
            print(f"    [{ctx}] \"{fr}\" -> \"{to}\": \"{val}\"")
    else:
        print(f"\n  PASS — all values use valid categorical labels.")
    print()


def check_confidence(db):
    """Check 6: report confidence distribution (expected 1-5)."""
    print("=" * 70)
    print("CHECK 6: Confidence distribution")
    print("=" * 70)

    counts = defaultdict(int)
    out_of_range = []
    for ctx_name, ctx in db["contexts"].items():
        for conn in ctx.get("connections", []):
            val = conn.get("confidence")
            if val is not None:
                counts[val] += 1
                if not isinstance(val, (int, float)) or val < 1 or val > 5:
                    out_of_range.append((ctx_name, conn["from"], conn["to"], val))

    total = sum(counts.values())
    print(f"  Total connections with confidence: {total}")
    for level in sorted(counts.keys()):
        pct = counts[level] / total * 100 if total else 0
        print(f"    Level {level}: {counts[level]} ({pct:.1f}%)")

    if out_of_range:
        print(f"\n  WARN — {len(out_of_range)} value(s) outside 1-5 range:")
        for ctx, fr, to, val in out_of_range:
            print(f"    [{ctx}] \"{fr}\" -> \"{to}\": {val}")
    else:
        print(f"\n  PASS — all confidence values in range 1-5.")
    print()


def main():
    if not KB_PATH.exists():
        print(f"ERROR: Knowledge base not found at {KB_PATH}")
        sys.exit(1)

    db = load_kb()
    n_contexts = len(db.get("contexts", {}))
    total_connections = sum(
        len(ctx.get("connections", [])) for ctx in db["contexts"].values()
    )
    print(f"Knowledge Base: {KB_PATH.name}")
    print(f"Version: {db.get('version', 'unknown')}")
    print(f"Contexts: {n_contexts} | Connections: {total_connections}")
    print()

    has_fail = False

    # Checks that cause FAIL (exit 1)
    if not check_cross_category_conflicts(db):
        has_fail = True
    if not check_connection_flows(db):
        has_fail = True

    # Checks that are informational / WARN only
    check_orphan_elements(db)
    check_reversibility(db)
    check_temporal_lag(db)
    check_confidence(db)

    # Summary
    print("=" * 70)
    if has_fail:
        print("RESULT: FAIL — critical issues found (see above)")
        sys.exit(1)
    else:
        print("RESULT: PASS — no critical issues (warnings may exist)")
        sys.exit(0)


if __name__ == "__main__":
    main()
