"""
Build (text, DAPSIWRM-category) labelled pairs for the BERT chunk-classifier.

Sources:
  - data/ml_training_data.rds-derived 7 templates' element names (232 pairs)
  - data/ses_knowledge_db.json — full KB (33 contexts, ~1200 connections)
  - data/ses_knowledge_db_offshore_wind.json — 4 regional contexts

The full KB stores elements under per-category fields (drivers, activities,
pressures, marine_processes_functioning, ecosystem_services, goods_benefits,
responses) as lists of {name, relevance} dicts.

Output: data/element_classifier_training.json with shape:
  {
    "examples": [{"text": "...", "category": "Drivers"}, ...],
    "categories": ["Drivers", "Activities", ...]
  }
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CATEGORY_MAP = {
    "drivers": "Drivers",
    "activities": "Activities",
    "pressures": "Pressures",
    "states": "Marine Processes & Functioning",          # used in main KB
    "marine_processes_functioning": "Marine Processes & Functioning",
    "marine_processes": "Marine Processes & Functioning",
    "components": "Marine Processes & Functioning",
    "impacts": "Ecosystem Services",                      # used in main KB
    "ecosystem_services": "Ecosystem Services",
    "welfare": "Goods & Benefits",                         # used in main KB
    "goods_benefits": "Goods & Benefits",
    "goods_and_benefits": "Goods & Benefits",
    "responses": "Responses",
    "measures": "Responses",
}


def harvest(json_path):
    """Yield (name, canonical_category) from one KB file."""
    if not os.path.exists(json_path):
        return
    with open(json_path, encoding="utf-8") as f:
        kb = json.load(f)
    contexts = kb.get("contexts", {})
    for ctx_name, ctx in contexts.items():
        for kb_field, canonical in CATEGORY_MAP.items():
            elements = ctx.get(kb_field, [])
            if not isinstance(elements, list):
                continue
            for el in elements:
                name = None
                if isinstance(el, dict):
                    name = el.get("name") or el.get("element_name")
                elif isinstance(el, str):
                    name = el
                if name and len(name.strip()) >= 3:
                    yield name.strip(), canonical


def main():
    examples_by_name = {}

    for kb_file in [
        "data/ses_knowledge_db.json",
        "data/ses_knowledge_db_offshore_wind.json",
    ]:
        path = os.path.join(ROOT, kb_file)
        for name, cat in harvest(path):
            # Dedupe on name (first category wins; element naming is consistent
            # in the KB)
            key = name.lower()
            if key not in examples_by_name:
                examples_by_name[key] = {"text": name, "category": cat}

    examples = list(examples_by_name.values())

    categories = sorted({e["category"] for e in examples})
    out_path = os.path.join(ROOT, "data/element_classifier_training.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({"examples": examples, "categories": categories}, f, indent=2, ensure_ascii=False)

    print(f"Wrote {len(examples)} examples to {out_path}")
    print("Class balance:")
    counts = {}
    for e in examples:
        counts[e["category"]] = counts.get(e["category"], 0) + 1
    for c in categories:
        print(f"  {c}: {counts.get(c, 0)}")


if __name__ == "__main__":
    main()
