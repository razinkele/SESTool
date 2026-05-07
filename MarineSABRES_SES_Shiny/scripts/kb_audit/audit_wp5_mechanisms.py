#!/usr/bin/env python3
"""WP5 mechanism KB quality audit.

Reads data/ses_knowledge_db_wp5_mechanisms.json and flags:
  - Mechanisms missing any of the 13 required attributes
  - Mechanisms with <8/9 completeness attributes populated (per spec §5.7 floor)
  - DA names not in the canonical {macaronesia, tuscan, arctic} set
  - Empty references or evidence_base arrays
  - finance_flow with no payer or no receiver
  - Mechanism IDs that are not unique within the file
  - valuation_unit_values band-ordering violations (low <= central <= high)

Exits with status 1 if any FAIL-class issue is found.

Usage:
    micromamba run -n shiny python scripts/kb_audit/audit_wp5_mechanisms.py
"""

import json
import sys
from pathlib import Path

KB_PATH = Path("data/ses_knowledge_db_wp5_mechanisms.json")
CANONICAL_DAS = {"macaronesia", "tuscan", "arctic"}
REQUIRED_ATTRS = [
    "id", "name", "cost_profile", "what_it_funds", "finance_flow",
    "design_parameters", "evidence_base", "transferable_lessons",
    "applies_to_DAs", "success_metrics", "risks_and_guardrails",
    "use_in_impact_assessment", "references",
]
# Of these 13, 9 are counted toward the spec's "≥8/9" completeness floor.
# `id` is required but always populated by construction; `applies_to_DAs`,
# `success_metrics`, `risks_and_guardrails` are project-internal cross-references
# that may legitimately be lean or empty pending Phase 3/4.
COMPLETENESS_ATTRS = [
    "name", "cost_profile", "what_it_funds", "finance_flow",
    "design_parameters", "evidence_base", "transferable_lessons",
    "use_in_impact_assessment", "references",
]


def is_populated(value):
    """Return True if a JSON value carries non-trivial content."""
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, (list, dict)):
        return bool(value)
    return True


def audit_mechanism(da_name, mech, seen_ids):
    issues = []
    mid = mech.get("id", "<missing-id>")

    # Missing required attributes (FAIL)
    for attr in REQUIRED_ATTRS:
        if attr not in mech:
            issues.append(("FAIL", f"{da_name}/{mid}: missing required attribute '{attr}'"))

    # ID uniqueness
    if mid in seen_ids:
        issues.append(("FAIL", f"{mid}: duplicate id (also appears in {seen_ids[mid]})"))
    else:
        seen_ids[mid] = da_name

    # Completeness floor (>=8/9)
    populated = sum(1 for a in COMPLETENESS_ATTRS if is_populated(mech.get(a)))
    if populated < 8:
        issues.append(("FAIL", f"{da_name}/{mid}: only {populated}/9 completeness attrs populated; spec floor is 8"))

    # finance_flow structure
    ff = mech.get("finance_flow") or {}
    if not ff.get("payer"):
        issues.append(("FAIL", f"{da_name}/{mid}: finance_flow.payer is empty"))
    if not ff.get("receiver"):
        issues.append(("FAIL", f"{da_name}/{mid}: finance_flow.receiver is empty"))

    # applies_to_DAs canonicality
    for da in mech.get("applies_to_DAs", []):
        if da not in CANONICAL_DAS:
            issues.append(("FAIL", f"{da_name}/{mid}: applies_to_DAs contains non-canonical '{da}'"))

    # Empty references is a WARN (some mechanisms genuinely have only one source)
    if not mech.get("references"):
        issues.append(("WARN", f"{da_name}/{mid}: references array is empty"))
    if not mech.get("evidence_base"):
        issues.append(("WARN", f"{da_name}/{mid}: evidence_base array is empty"))

    return issues


def main():
    if not KB_PATH.exists():
        print(f"FAIL: KB file not found at {KB_PATH}", file=sys.stderr)
        sys.exit(1)

    with KB_PATH.open(encoding="utf-8") as f:
        kb = json.load(f)

    issues = []
    seen_ids = {}

    das = kb.get("demonstration_areas", {})
    for da_name in das:
        if da_name not in CANONICAL_DAS:
            issues.append(("FAIL", f"demonstration_areas: non-canonical key '{da_name}'"))
        for mech in das[da_name].get("mechanisms", []):
            issues.extend(audit_mechanism(da_name, mech, seen_ids))

    # Valuation block sanity
    vuv = kb.get("valuation_unit_values", {})
    if "posidonia_oceanica" in vuv:
        pos = vuv["posidonia_oceanica"]
        for service, vals in pos.items():
            if not all(k in vals for k in ("low", "central", "high", "unit", "method")):
                issues.append(("FAIL", f"valuation_unit_values.posidonia_oceanica.{service}: missing low/central/high/unit/method"))
            elif not (vals["low"] <= vals["central"] <= vals["high"]):
                issues.append(("FAIL", f"valuation_unit_values.posidonia_oceanica.{service}: bands not ordered low <= central <= high"))

    # Report
    fails = [i for i in issues if i[0] == "FAIL"]
    warns = [i for i in issues if i[0] == "WARN"]

    n_mechs = sum(len(da.get("mechanisms", [])) for da in das.values())
    print(f"=== WP5 mechanism KB audit ===")
    print(f"Mechanisms: {n_mechs}")
    print(f"Issues: {len(fails)} FAIL, {len(warns)} WARN")
    for sev, msg in fails + warns:
        print(f"  [{sev}] {msg}")

    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
