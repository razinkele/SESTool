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
    # ----- mac_02: MPA tourism-levy fund (partner-pickable default) -----
    {
        "id": "mac_02_tourism_levy_fund",
        "name": "MPA tourism-levy fund",
        "cost_profile": "recurring",
        "what_it_funds": "Conservation actions and visitor-management infrastructure in Macaronesian MPAs, financed by a small per-visitor or per-vessel levy on marine tourism operators.",
        "finance_flow": {
            "payer": ["marine tourism operators (whale-watching, dive boats, charter vessels)"],
            "receiver": "MPA management body",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Levy collected at point of sale (not at the dock) for compliance",
            "Earmarked spending plan published annually",
            "Levy adjusts inversely with visitor numbers to smooth revenue",
        ],
        "evidence_base": [
            "Galápagos visitor entry fee (operational precedent)",
            "Bonaire dive tag programme",
        ],
        "transferable_lessons": [
            "Visible reinvestment in infrastructure (mooring buoys, signage) sustains operator buy-in",
            "Online point-of-sale collection has lower leakage than on-water enforcement",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["T_02"],
        "risks_and_guardrails": [
            {"risk": "Levy passed entirely to visitors with no operator engagement",
             "guardrail": "Operator co-governance seat on the spending plan"},
        ],
        "use_in_impact_assessment": "Use for any Macaronesia scenario with active marine tourism. Score positively on FF and EC.",
        "references": ["MarineSABRES D5.2 Blue Corridor toolkit, §x.x"],
    },
    # ----- mac_03: Multi-year Delivery & Shared-Services Facility -----
    {
        "id": "mac_03_multi_year_delivery_facility",
        "name": "Multi-year Delivery & Shared-Services Facility",
        "cost_profile": "recurring",
        "what_it_funds": "A ring-fenced multi-year facility funding the recurring delivery functions corridor scenarios depend on but cannot sustain through one-off projects: core delivery staff, joint procurement of training and shared tools, maintenance of shared SOPs and reporting templates, indicator-pipeline support, and an optional small contingency window. Disburses against milestones rather than ad-hoc annual allocations.",
        "finance_flow": {
            "payer": [
                "EU seed funding (Horizon Europe successor + EMFAF)",
                "national governments (PT, ES)",
                "regional co-finance",
            ],
            "receiver": "ring-fenced delivery facility / host entity / contracted implementing partners",
            "type": "blended",
        },
        "design_parameters": [
            "Ring-fencing + multi-annual commitment (3–5 years) — not annually renewable",
            "Window structure with explicit % allocations across coordination, monitoring, training, implementation",
            "Disbursement rule: milestone/KPI-gated rather than block grants",
            "Narrow corridor-delivery mandate + eligibility rules to prevent mission creep",
            "Overhead caps and stop/go gates on IT/consultancy spend (MVP-only for shared tools)",
        ],
        "evidence_base": [
            "Conservation trust fund / ring-fenced facility models in protected-area finance guidance",
            "OECD ocean-finance literature on recurrent delivery needs and financing gaps",
            "MSP4BIO planning support logic for biodiversity mainstreaming in recurring cycles",
            "CMAR-style regional cooperation practice on delivery beyond pilot phases",
        ],
        "transferable_lessons": [
            "Pooled finance works best when the facility has a narrow, explicit mandate with transparent allocation rules",
            "Multi-year commitments are essential — short project cycles destroy delivery continuity",
            "Distinguish core delivery funding from optional co-financing for rollout to avoid pot-of-money optics",
            "Tie disbursement to delivered outputs and documented user uptake, not budget execution",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "M_01", "M_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Facility becomes too broad and turns into a generic funding pot",
             "guardrail": "Define narrow corridor-delivery mandate + eligible cost categories at the founding charter"},
            {"risk": "Unstable or politically contestable replenishment",
             "guardrail": "Set multi-year commitments and renewal rules in advance; tie to treaty-level codification where feasible"},
            {"risk": "Co-financing window rewards opportunistic projects rather than corridor priorities",
             "guardrail": "Tie any rollout support to agreed corridor work-programme priorities and reporting"},
            {"risk": "Administrative overhead crowds out delivery",
             "guardrail": "Cap management costs, require annual public reporting on allocations and outputs, run independent annual audit"},
            {"risk": "IT/consultancy budget sink",
             "guardrail": "MVP-only IT scope with stop/go gate tied to delivered outputs and documented uptake"},
        ],
        "use_in_impact_assessment": "Use this mechanism when scoring Macaronesia scenarios where delivery continuity is the binding constraint (S3 Coordinated and S4 Integrated). Score positively on FF (sustained funding) and PI (translates declarations into operational delivery); pair with C_02 monitoring-capacity indicator and corridor-wide implementation outputs. Without this mechanism, S3/S4 are paper exercises — with it, sustained capacity becomes plausible.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #2",
            "OECD ocean-finance literature on biodiversity finance",
            "MSP4BIO Deliverable 3.2",
        ],
    },
    # ----- mac_04: Shared evidence & decision-products layer -----
    {
        "id": "mac_04_shared_evidence_services",
        "name": "Shared evidence & decision-products layer",
        "cost_profile": "recurring",
        "what_it_funds": "Production of usable shared corridor evidence rather than raw data dumps: indicator briefs, operator-facing summaries (\"what this means for you\"), harmonised reporting templates, plain-language syntheses, simple dashboards, and translation/layout. The aim is to make corridor evidence operationally usable by authorities, operators, and stakeholders across the Azores–Madeira–Canary Islands rather than letting data sit unused.",
        "finance_flow": {
            "payer": [
                "public corridor-delivery funding",
                "EU technical-assistance line",
                "facility/shared-services budget",
            ],
            "receiver": "designated technical unit / contracted comms+data product team",
            "type": "public",
        },
        "design_parameters": [
            "Define a minimum viable product set per year (briefs, decision notes, templates) with named owners and sign-off",
            "Each product must declare its decision use-case before publication",
            "Update cadence and version control with documented method changes",
            "Accessibility: multilingual layout, plain-language operator summary (≤2 pages) plus glossary",
            "5–10 user test before public release of any new product",
        ],
        "evidence_base": [
            "MSP4BIO Baltic Sea brief on turning cumulative-impact and biodiversity data into planning-relevant outputs",
            "Marine corridor / connectivity literature reviewed by Podda & Porporato on bridging fragmented data",
            "MSP / biodiversity planning literature on integrating evidence into decision cycles",
        ],
        "transferable_lessons": [
            "Data availability alone is insufficient — the bottleneck is converting data into audience-specific products that fit decision cycles",
            "Connectivity-related products gain durability when embedded in formal MSP/MPA cycles, not left as project outputs",
            "Decision-note format alongside dashboards prevents technical showcase syndrome",
            "Common metadata + version control across archipelagos is what makes products comparable",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_01", "C_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Product layer becomes a technical showcase with no operational uptake",
             "guardrail": "Define target users and required use-cases at the outset; track adoption metrics"},
            {"risk": "Over-complex dashboards displace usable decisions",
             "guardrail": "Require a short decision-note format alongside any dashboard"},
            {"risk": "Inconsistent definitions undermine cross-archipelago comparability",
             "guardrail": "Adopt common metadata, update rules and version control"},
            {"risk": "Shared products are not trusted",
             "guardrail": "Make methods transparent and link each product to named data sources and update dates"},
            {"risk": "Too technical to apply",
             "guardrail": "Enforce a 2-page operator summary + glossary, plus a 5–10 user test before release"},
        ],
        "use_in_impact_assessment": "Use whenever scoring requires consistent cross-archipelago evidence interpretation (any S2–S4 scenario). Score positively on C_02 and as an enabler for C_01 connectivity scoring. Treat as an enabling layer underpinning multiple indicators rather than a standalone delivery mechanism. Without this layer, the rest of the toolkit's reporting becomes archipelago-by-archipelago and uninterpretable.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #3",
            "MSP4BIO Baltic Sea brief",
            "Podda & Porporato — marine corridor connectivity review",
        ],
    },
    # ----- mac_05: Integrated monitoring & data pipeline -----
    {
        "id": "mac_05_integrated_monitoring",
        "name": "Integrated monitoring & data pipeline",
        "cost_profile": "recurring",
        "what_it_funds": "A repeatable corridor-scale annual monitoring pipeline producing harmonised indicator outputs: AIS-derived vessel-flow products (M_01), sensitive-area overlap/proximity products (M_02), method documentation, QA/QC routines, and recurring updates of pressure/activity datasets. Moves the DA from fragmented project monitoring to a stable, year-on-year comparable indicator pipeline that feeds the impact assessment.",
        "finance_flow": {
            "payer": [
                "public corridor-delivery funding",
                "ring-fenced facility share",
                "service contracts (analytics provider or public agency)",
            ],
            "receiver": "designated technical unit / monitoring consortium / contracted analytical support",
            "type": "public",
        },
        "design_parameters": [
            "Define minimum core indicator set first, extended set later",
            "Adopt one fixed method per reporting year; freeze definitions and publish a method note",
            "Data access/rights resolved upfront (AIS sources, confidentiality)",
            "Definition set for sensitive areas + buffers documented and version-controlled",
            "Reporting calendar fixed and named delivery owners assigned",
            "Include implementation/process indicators alongside ecological/pressure metrics",
        ],
        "evidence_base": [
            "MSP4BIO Baltic Sea — strongest cumulative-pressure/impact analogue",
            "Monitoring and biodiversity-assessment literature on repeatable indicator systems",
            "Marine corridor literature (Podda & Porporato) on integrated monitoring approaches",
            "Regional MSP/MPA practice on harmonised monitoring under fragmented competences",
        ],
        "transferable_lessons": [
            "Monitoring becomes management-useful only when method-stable, repeatable, QA'd, and linked to decision cycles",
            "One-off analyses or project dashboards do not survive into reporting cycles",
            "Pressure/impact tools work best embedded in planning and review cycles",
            "Add implementation/process indicators alongside ecological metrics — otherwise the system tracks pressures but not whether measures are happening",
        ],
        "applies_to_DAs": ["macaronesia"],
        "success_metrics": ["C_02", "M_01", "M_02", "F_02", "F_03", "T_03"],
        "risks_and_guardrails": [
            {"risk": "Monitoring system becomes too broad and collapses under data demands",
             "guardrail": "Define a minimum core indicator set first; expand only after stable annual delivery"},
            {"risk": "Indicators are updated inconsistently across archipelagos",
             "guardrail": "Adopt common metadata, version control and QA/QC procedures"},
            {"risk": "Annual outputs are delayed and lose management value",
             "guardrail": "Fix reporting calendar and assign delivery owners"},
            {"risk": "System tracks pressures but not whether measures are implemented",
             "guardrail": "Include implementation/process indicators alongside ecological/pressure metrics"},
            {"risk": "Outputs misread as enforcement proof",
             "guardrail": "Label as risk/pressure indicators and include coverage/limitations on each release"},
            {"risk": "Method disputes undermine comparability",
             "guardrail": "Adopt one fixed method per year; publish method note with definitions frozen for the reporting year"},
        ],
        "use_in_impact_assessment": "This is the indicator-engine row. It underpins C_02 (monitoring capacity exists and is repeatable), conditions the credibility of S3 and S4, and supports interpretation of M_01/M_02. Without an integrated monitoring pipeline, scenario-level indicator claims default to one-off project artefacts. Score positively on EE (enables enforcement targeting) and PI; pair with M_01 vessel-flows + M_02 sensitive-area overlap as primary indicator outputs.",
        "references": [
            "MarineSABRES D5.2 Blue Corridor toolkit, mechanism #4",
            "MSP4BIO Baltic Sea cumulative-impact assessment work",
            "Podda & Porporato — marine corridor connectivity review",
        ],
    },
    # Additional Macaronesia mechanisms appended by Task D1
]

TUSCAN_MECHANISMS = [
    # ----- tus_01: Payment for Ecosystem Services (PES) for Posidonia conservation -----
    {
        "id": "tus_01_pes_posidonia",
        "name": "Payment for Ecosystem Services (PES) for Posidonia conservation",
        "cost_profile": "recurring",
        "what_it_funds": "Direct compensation to fishers, dive operators, and coastal landowners for verifiable conservation actions protecting Posidonia oceanica meadows (e.g., gear modifications, anchoring restrictions, no-take agreements).",
        "finance_flow": {
            "payer": ["regional MPA authority", "EU LIFE / EMFAF co-funding", "tourism operator levies"],
            "receiver": "individual fishers / cooperatives / landowners",
            "type": "blended",
        },
        "design_parameters": [
            "Verifiable on-water actions tied to monitoring data (not self-reported)",
            "Annual payment cycle aligned with fishing season",
            "Eligibility floor: minimum patch area protected per recipient",
            "Sunset clause: 5-year cycle with renewal contingent on biophysical outcomes",
        ],
        "evidence_base": [
            "Costa Rica Pago por Servicios Ambientales (operational precedent)",
            "Mediterranean Posidonia restoration trials (Boudouresque et al., site-specific)",
        ],
        "transferable_lessons": [
            "Self-reported actions reduce political cost but degrade outcomes; tie payments to monitoring data",
            "Cooperatives administer payments more efficiently than per-vessel transfers",
            "Tourism levy tolerated when receipts are visibly earmarked for marine conservation",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Adverse selection — only low-effort fishers enroll",
             "guardrail": "Eligibility floor + onboarding workshop on actions required"},
            {"risk": "Greenwashing if monitoring is weak",
             "guardrail": "Independent verification by MPA scientific staff or contracted institute"},
        ],
        "use_in_impact_assessment": "Use when scoring a Tuscan scenario that depends on voluntary fisher cooperation (S2 Light or S3 Coordinated). Score positively on EQ (compensates affected fishers) and EE (when monitoring is robust). Pair with POS_density biophysical indicator.",
        "references": ["MarineSABRES D5.2 Tuscan DA, §x.x Financial mechanisms"],
    },
    # ----- tus_02: Mooring-buoy permit fee (partner-pickable default) -----
    {
        "id": "tus_02_mooring_buoy_permit",
        "name": "Mooring-buoy permit fee",
        "cost_profile": "recurring",
        "what_it_funds": "Installation, maintenance, and enforcement of mooring buoys protecting Posidonia meadows from anchor damage, financed by per-vessel permit fees.",
        "finance_flow": {
            "payer": ["recreational and commercial vessels operating in Tuscan MPA waters"],
            "receiver": "MPA management body / contracted maintenance operator",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Mandatory mooring (anchoring banned) inside designated meadow zones",
            "Permit price covers maintenance cost + 20% reserve",
            "Online permit purchase with automated boundary enforcement via AIS",
        ],
        "evidence_base": [
            "Mediterranean MPA mooring-buoy systems (multiple operational precedents)",
        ],
        "transferable_lessons": [
            "Mandatory mooring works only with credible enforcement; voluntary systems fail",
            "AIS-based boundary enforcement is cheaper than patrol vessels for small MPAs",
        ],
        "applies_to_DAs": ["tuscan"],
        "success_metrics": ["POS_density"],
        "risks_and_guardrails": [
            {"risk": "Insufficient buoy density forces anchoring outside designated zones",
             "guardrail": "Capacity sized to peak summer demand × 1.2"},
        ],
        "use_in_impact_assessment": "Use for any Tuscan scenario protecting Posidonia. Score strongly positive on EE.",
        "references": ["MarineSABRES D5.2 Tuscan DA, §x.x"],
    },
    # Additional Tuscan mechanisms appended by Task D2
]

ARCTIC_MECHANISMS = [
    # ----- arc_01: Cost-recovery fees on quota holders -----
    {
        "id": "arc_01_cost_recovery_fees",
        "name": "Cost-recovery fees on quota holders",
        "cost_profile": "recurring",
        "what_it_funds": "Enforcement, observer programmes, and stock-assessment science in the Arctic Northeast Atlantic, financed by per-tonne or per-vessel fees levied on quota holders.",
        "finance_flow": {
            "payer": ["quota holders (commercial fishing operators)"],
            "receiver": "national fisheries authorities (NO, IS, FO, RU); ICES/NEAFC scientific programmes",
            "type": "private-to-public",
        },
        "design_parameters": [
            "Fee scaled by landed value, not landed tonnage (better tracks effort to value)",
            "Earmarked use: science + enforcement; not general treasury",
            "Annual fee adjustment via published methodology to avoid political volatility",
            "Reduced fee for vessels carrying observers / electronic monitoring",
        ],
        "evidence_base": [
            "Iceland fisheries fee (operational precedent since 2012)",
            "OECD Sustainable Fisheries report (2022) on cost-recovery best practice",
        ],
        "transferable_lessons": [
            "Public earmark builds quota-holder political tolerance",
            "Per-value (not per-tonne) fees survive price-shock years better",
            "Fee discount for monitoring-equipped vessels accelerates adoption",
        ],
        "applies_to_DAs": ["arctic"],
        "success_metrics": [],
        "risks_and_guardrails": [
            {"risk": "Fees become a general revenue grab",
             "guardrail": "Earmarked use legislated, not just administrative"},
            {"risk": "Race-to-the-bottom across jurisdictions",
             "guardrail": "Coordinated minimum fee floor under NEAFC framework"},
        ],
        "use_in_impact_assessment": "Use when scoring an Arctic scenario where enforcement and science capacity are the binding constraint (Partial or Full Agreement). Score positively on EC (efficient cost recovery) and FF (sustained funding). Pair with stock-status indicators in later phases.",
        "references": ["MarineSABRES D5.2 Arctic DA, §x.x Financial mechanisms", "OECD Sustainable Fisheries (2022)"],
    },
    # Additional Arctic mechanisms appended by Task D3
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
