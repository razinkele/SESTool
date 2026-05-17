"""Count connections + unique elements in the 3 demo regions named in the ESP 2026 abstract.

One-off helper for Phase 0 of the abstract-revision plan; safe to delete after the abstract is finalized.
"""
import json
from pathlib import Path

KB_PATH = Path(__file__).resolve().parent.parent / "data" / "ses_knowledge_db.json"

with KB_PATH.open(encoding="utf-8") as f:
    kb = json.load(f)

ctxs = kb.get("contexts", {})
demo = {k: v for k, v in ctxs.items() if k.startswith(("macaronesia_", "arctic_", "mediterranean_"))}

print(f"=== Demo regions named in abstract ===")
print(f"Contexts ({len(demo)}):")
for k in demo:
    print(f"  - {k}")

ELEMENT_CATEGORIES = ["drivers", "activities", "pressures", "states", "impacts", "welfare", "responses"]


def collect_element_names(context: dict) -> list[str]:
    """Elements are stored under per-category keys as lists of {name, relevance} dicts."""
    names: list[str] = []
    for cat in ELEMENT_CATEGORIES:
        cat_data = context.get(cat)
        if isinstance(cat_data, list):
            for entry in cat_data:
                if isinstance(entry, dict) and "name" in entry:
                    names.append(entry["name"])
                elif isinstance(entry, str):
                    names.append(entry)
    return names


conn = sum(len(c.get("connections", [])) for c in demo.values())
elems = set()
for c in demo.values():
    elems.update(collect_element_names(c))

print(f"\nConnections (across demo regions): {conn}")
print(f"Unique elements (across demo regions): {len(elems)}")

print(f"\n=== Full KB (all regions) ===")
total_conn = sum(len(c.get("connections", [])) for c in ctxs.values())
all_elems = set()
for c in ctxs.values():
    all_elems.update(collect_element_names(c))
print(f"Contexts: {len(ctxs)}")
print(f"Connections (sum): {total_conn}")
print(f"Unique element names: {len(all_elems)}")
