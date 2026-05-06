#!/usr/bin/env python3
"""Build the WP5 financial-mechanism knowledge base from D5.2 source extracts.

Reads markdown extracts of the four WP5 source documents and emits
data/ses_knowledge_db_wp5_mechanisms.json. Mirrors the offshore-wind KB build
script's style and manual-edit guard.

Usage:
    micromamba run -n shiny python scripts/build_wp5_mechanisms_kb.py

Source extracts (regenerate via python-docx if missing):
    ~/AppData/Local/Temp/wp5_extract/D5.2_main.md
    ~/AppData/Local/Temp/wp5_extract/D5.2_macaronesia.md
    ~/AppData/Local/Temp/wp5_extract/blue_corridor.md
    ~/AppData/Local/Temp/wp5_extract/tuscan.md
    ~/AppData/Local/Temp/wp5_extract/arctic.md

NOTE ON MANUAL POST-GENERATION EDITS
------------------------------------
data/ses_knowledge_db_wp5_mechanisms.json may be hand-edited after generation
during partner-review cycles. Rerunning this script REGENERATES from the
in-script mechanism definitions (below) and will drop any manual additions
not mirrored here. Before rebuilding:
  1. git diff data/ses_knowledge_db_wp5_mechanisms.json against last commit
  2. confirm whether the JSON state is authoritative (keep) or this script
     is (overwrite)
  3. if the JSON is authoritative, mirror manual changes into the in-script
     definitions below before rebuilding
"""

import json
from datetime import date
from pathlib import Path

OUT_PATH = Path("data/ses_knowledge_db_wp5_mechanisms.json")
SOURCE_COMMIT = "1f636e8"
SOURCE_DOCS = [
    "Blue_corridor_financial toolkit_17_04_2026.docx",
    "Draft financial mechanisms_Tuscan DA.docx",
    "Draft text financial mechanisms_Arctic DA.docx",
    "MarineSABRES_Deliverable5.2_Draftv3.docx",
]

# ============================================================================
# MECHANISM DEFINITIONS
# ============================================================================
# Each mechanism MUST carry all 13 attributes:
#   id, name, cost_profile, what_it_funds, finance_flow, design_parameters,
#   evidence_base, transferable_lessons, applies_to_DAs, success_metrics,
#   risks_and_guardrails, use_in_impact_assessment, references
# Of these, 9 are subject to the audit's ≥8/9 completeness floor (`id` is
# the 10th required field but is always populated by construction).
# `success_metrics` may legitimately be empty if no Phase 3 indicator covers
# the mechanism yet.

MACARONESIA_MECHANISMS = [
    # ----- mac_01: Blue Corridor Facility -----
    {
        "id": "mac_01_blue_corridor_facility",
        "name": "Blue Corridor Facility",
        "cost_profile": "recurring",
        "what_it_funds": "A regional financing facility funding coordinated monitoring, enforcement, scientific assessment, and stakeholder engagement across the Azores-Madeira-Canary Islands EEZ + ABNJ Blue Corridor.",
        "finance_flow": {
            "payer": [
                "EU (Horizon Europe successor + EMFAF)",
                "national governments (PT, ES)",
                "philanthropic foundations",
            ],
            "receiver": "regional secretariat (proposed: hosted by an existing IGO or jointly by national MPA agencies)",
            "type": "blended",
        },
        "design_parameters": [
            "Narrow corridor-delivery mandate to prevent mission creep",
            "Eligible cost categories defined in the founding charter (monitoring, enforcement, science, engagement; not general MPA operations)",
            "Three-jurisdiction governing board with rotating chair",
            "Annual operating budget €5–15M, with multi-year commitment cycles",
        ],
        "evidence_base": [
            "MSP4BIO D3.2 (regional financing analogues)",
            "OSPAR Coordinated Environmental Monitoring Programme (governance precedent)",
            "Mediterranean MedPAN Fund (operational precedent for regional MPA financing)",
        ],
        "transferable_lessons": [
            "Regional secretariat must have legal personality; informal coordination collapses under fiscal stress",
            "Multi-year commitment cycles essential — annual renewals create activity gaps that erode trust",
            "Co-funding from national governments (not just EU) increases political durability",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_01", "C_02", "M_01"],
        "risks_and_guardrails": [
            {"risk": "Mandate creep — facility becomes a generic MPA funding pot",
             "guardrail": "Founding charter narrows eligible activities to corridor-delivery; annual board review of out-of-scope requests"},
            {"risk": "Free-riding by one jurisdiction",
             "guardrail": "Co-funding share required as condition of voting rights"},
            {"risk": "Political withdrawal during national election cycles",
             "guardrail": "Multi-year commitments + treaty-level codification (where feasible)"},
        ],
        "use_in_impact_assessment": "Use this mechanism when scoring a Macaronesia scenario where regional coordination capacity is the binding constraint (S3 Coordinated EEZ or S4 Integrated EEZ+ABNJ). Score it positively on EE (enables monitoring) and negatively on PI (requires multi-state agreement). Pair with M_01 vessel-movement indicator for measurable success.",
        "references": [
            "MarineSABRES D5.2 §5.x Blue Corridor financial toolkit",
            "MSP4BIO Deliverable 3.2",
        ],
    },
    # Additional Macaronesia mechanisms appended by Tasks C2, D1
]

TUSCAN_MECHANISMS = [
    # Filled in by Task C2 (sample) and Task D2 (remainder)
]

ARCTIC_MECHANISMS = [
    # Filled in by Task C2 (sample) and Task D3 (remainder)
]

VALUATION_UNIT_VALUES = {
    "posidonia_oceanica": {
        "coastal_protection":   {"low": 3500,  "central": 10350, "high": 17200, "unit": "EUR/ha/yr", "method": "avoided_cost"},
        "carbon_sequestration": {"low": 40,    "central": 140,   "high": 240,   "unit": "EUR/ha/yr", "method": "social_cost_of_carbon"},
        "recreation_tourism":   {"low": 400,   "central": 2500,  "high": 4600,  "unit": "EUR/ha/yr", "method": "travel_cost_or_WTP"},
        "food_provision":       {"low": 150,   "central": 975,   "high": 1800,  "unit": "EUR/ha/yr", "method": "market_pricing"},
        "water_purification":   {"low": 350,   "central": 1175,  "high": 2000,  "unit": "EUR/ha/yr", "method": "replacement_cost"},
    },
    "restoration_costs": {
        "posidonia_oceanica": {"low": 100000, "high": 500000, "unit": "EUR/ha", "early_survival_low": 0.38, "early_survival_high": 0.60},
    },
}

# ============================================================================
# BUILD
# ============================================================================

def build_kb():
    return {
        "version": "1.0.0",
        "description": "WP5 financial and implementation mechanisms catalogue (Marine SABRES Deliverable 5.2). Mechanisms are indexed by Demonstration Area; each mechanism follows a fixed 10-attribute structure mirroring the Blue Corridor toolkit annex. Bundled `valuation_unit_values` carries Tuscan Posidonia oceanica benefit-transfer estimates consumed by the Phase 2 valuation calculator.",
        "last_updated": str(date.today()),
        "source_documents": SOURCE_DOCS,
        "source_commit": SOURCE_COMMIT,
        "demonstration_areas": {
            "macaronesia": {
                "description": "Blue Corridor (EEZ + ABNJ); cross-jurisdictional MPA network spanning Azores-Madeira-Canary Islands, with mechanisms supporting coordinated monitoring, enforcement, and connectivity-preserving fisheries management.",
                "mechanisms": MACARONESIA_MECHANISMS,
            },
            "tuscan": {
                "description": "Tuscan Archipelago National Park; mechanisms supporting Posidonia oceanica meadow protection, restoration, and enforcement against anchoring and trawling damage.",
                "mechanisms": TUSCAN_MECHANISMS,
            },
            "arctic": {
                "description": "Arctic Northeast Atlantic; mechanisms supporting quota allocation, enforcement, and incentive design for sustainable fisheries under ICES/NEAFC governance.",
                "mechanisms": ARCTIC_MECHANISMS,
            },
        },
        "valuation_unit_values": VALUATION_UNIT_VALUES,
    }


def main():
    kb = build_kb()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(kb, f, ensure_ascii=False, indent=2)
    print(f"[build_wp5_mechanisms_kb] wrote {OUT_PATH} "
          f"(macaronesia={len(MACARONESIA_MECHANISMS)}, "
          f"tuscan={len(TUSCAN_MECHANISMS)}, "
          f"arctic={len(ARCTIC_MECHANISMS)})")


if __name__ == "__main__":
    main()
