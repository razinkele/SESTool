#!/usr/bin/env python3
"""KB Quality Audit Script for MarineSABRES SES Toolbox.

Reads both KB JSON files and flags data quality issues for manual review.
Does NOT modify the KB files.

Usage:
    micromamba run -n shiny python scripts/kb_audit/audit_kb_quality.py
"""

import json
import os
import sys
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path

# Valid transitions after the Rule 17 update (21 total)
VALID_TRANSITIONS = {
    ("drivers", "activities"), ("activities", "pressures"),
    ("pressures", "states"), ("states", "impacts"),
    ("impacts", "welfare"), ("welfare", "responses"),
    ("welfare", "measures"),  # Rule 8: GB/W → R/M
    ("welfare", "drivers"),  # collapsed Rules 6+7
    ("responses", "drivers"), ("responses", "activities"),
    ("responses", "pressures"), ("responses", "states"),
    ("measures", "drivers"), ("measures", "activities"),
    ("measures", "pressures"), ("measures", "states"),
    ("measures", "responses"),  # Rule 13
    ("responses", "responses"),  # Rule 14
    ("drivers", "welfare"),  # Rule 15
    ("states", "states"),  # Rule 16
    ("pressures", "pressures"),  # Rule 17
}


def audit_kb(kb_path: str) -> dict:
    """Audit a single KB file and return flags."""
    with open(kb_path, "r", encoding="utf-8") as f:
        kb = json.load(f)

    flags = {
        "halpern_only": [],
        "chain_completion": [],
        "bridge_connections": [],
        "duplicate_rationale": [],
        "single_reference": [],
        "non_framework_transitions": [],
    }

    all_rationales = defaultdict(list)
    total_connections = 0

    # KB files nest contexts under a "contexts" key
    contexts = kb.get("contexts", {})
    if not isinstance(contexts, dict):
        contexts = {}

    for context_name, context_data in contexts.items():
        if not isinstance(context_data, dict):
            continue
        connections = context_data.get("connections", [])
        if not isinstance(connections, list):
            continue

        for idx, conn in enumerate(connections):
            if not isinstance(conn, dict):
                continue
            total_connections += 1

            from_elem = conn.get("from", "")
            to_elem = conn.get("to", "")
            from_type = conn.get("from_type", "").lower()
            to_type = conn.get("to_type", "").lower()
            rationale = conn.get("rationale", "")
            refs = conn.get("references", [])
            confidence = conn.get("confidence", None)

            entry = {
                "context": context_name,
                "index": idx,
                "from": from_elem,
                "to": to_elem,
                "from_type": from_type,
                "to_type": to_type,
            }

            # Flag 1: Halpern-only references
            if isinstance(refs, list) and len(refs) > 0:
                all_halpern = all(
                    "halpern" in str(r).lower() for r in refs
                )
                if all_halpern:
                    flags["halpern_only"].append(entry)

            # Flag 2: Chain-completion connections
            rationale_lower = rationale.lower()
            if any(
                marker in rationale_lower
                for marker in [
                    "connection added to complete",
                    "added to ensure",
                    "added to connect",
                    "chain completion",
                ]
            ):
                flags["chain_completion"].append(entry)

            # Flag 3: Bridge connections and explicitly invalid connections
            if any(
                marker in rationale_lower
                for marker in [
                    "bridge", "connect disconnected",
                    "no scientific basis", "no ecological",
                    "no mechanism", "no causal",
                ]
            ):
                flags["bridge_connections"].append(entry)

            # Flag 5: Single-reference connections
            if isinstance(refs, list) and len(refs) == 1:
                flags["single_reference"].append(entry)
            elif isinstance(refs, str) and refs.strip():
                # Some refs might be strings instead of arrays
                if ";" not in refs and "," not in refs:
                    flags["single_reference"].append(entry)

            # Flag 6: Non-framework transitions
            if from_type and to_type:
                if (from_type, to_type) not in VALID_TRANSITIONS:
                    flags["non_framework_transitions"].append(entry)

            # Collect rationale for duplicate detection
            if rationale.strip() and len(rationale) > 50:
                key = rationale.strip()[:200]
                all_rationales[key].append(entry)

    # Flag 4: Duplicate rationale (3+ occurrences with different element pairs)
    for rationale_prefix, entries in all_rationales.items():
        if len(entries) >= 3:
            pairs = set((e["from"], e["to"]) for e in entries)
            if len(pairs) > 1:
                flags["duplicate_rationale"].append({
                    "rationale_prefix": rationale_prefix,
                    "count": len(entries),
                    "distinct_pairs": len(pairs),
                    "connections": entries[:5],
                })

    summary = {
        "halpern_only_count": len(flags["halpern_only"]),
        "chain_completion_count": len(flags["chain_completion"]),
        "bridge_count": len(flags["bridge_connections"]),
        "duplicate_rationale_groups": len(flags["duplicate_rationale"]),
        "single_reference_count": len(flags["single_reference"]),
        "non_framework_transition_count": len(flags["non_framework_transitions"]),
    }

    return {
        "kb_file": kb_path,
        "total_connections": total_connections,
        "flags": flags,
        "summary": summary,
    }


def write_markdown(report: dict, output_path: str):
    """Write a human-readable Markdown summary."""
    s = report["summary"]
    lines = [
        f"# KB Quality Audit Report",
        f"",
        f"**File**: `{report['kb_file']}`",
        f"**Date**: {date.today().isoformat()}",
        f"**Total connections**: {report['total_connections']}",
        f"",
        f"## Summary",
        f"",
        f"| Flag | Count |",
        f"|------|-------|",
        f"| Halpern-only references | {s['halpern_only_count']} |",
        f"| Chain-completion (auto-generated) | {s['chain_completion_count']} |",
        f"| Bridge connections | {s['bridge_count']} |",
        f"| Duplicate rationale groups | {s['duplicate_rationale_groups']} |",
        f"| Single-reference connections | {s['single_reference_count']} |",
        f"| Non-framework transitions | {s['non_framework_transition_count']} |",
        f"",
    ]

    for flag_name, flag_list in report["flags"].items():
        if not flag_list:
            continue
        lines.append(f"## {flag_name.replace('_', ' ').title()} ({len(flag_list)})")
        lines.append("")
        for item in flag_list[:20]:
            if "rationale_prefix" in item:
                lines.append(
                    f"- **{item['count']}x** ({item['distinct_pairs']} pairs): "
                    f'"{item["rationale_prefix"][:80]}..."'
                )
            else:
                lines.append(
                    f"- `{item['context']}[{item['index']}]`: "
                    f"{item['from'][:40]} -> {item['to'][:40]}"
                )
        if len(flag_list) > 20:
            lines.append(f"- ... and {len(flag_list) - 20} more")
        lines.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    project_root = Path(__file__).parent.parent.parent  # audit_kb_quality.py -> kb_audit/ -> scripts/ -> project root
    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(exist_ok=True)

    kb_files = [
        project_root / "data" / "ses_knowledge_db.json",
        project_root / "data" / "ses_knowledge_db_offshore_wind.json",
    ]

    for kb_path in kb_files:
        if not kb_path.exists():
            print(f"WARNING: {kb_path} not found, skipping")
            continue

        print(f"Auditing {kb_path.name}...")
        report = audit_kb(str(kb_path))
        report["audit_date"] = date.today().isoformat()

        stem = kb_path.stem
        json_out = output_dir / f"{stem}_audit.json"
        md_out = output_dir / f"{stem}_audit.md"

        with open(json_out, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        write_markdown(report, str(md_out))

        s = report["summary"]
        print(f"  Total connections: {report['total_connections']}")
        print(f"  Halpern-only: {s['halpern_only_count']}")
        print(f"  Chain-completion: {s['chain_completion_count']}")
        print(f"  Bridge: {s['bridge_count']}")
        print(f"  Duplicate rationale: {s['duplicate_rationale_groups']}")
        print(f"  Single-reference: {s['single_reference_count']}")
        print(f"  Non-framework: {s['non_framework_transition_count']}")
        print(f"  Reports: {json_out}, {md_out}")
        print()

    print("Audit complete.")


if __name__ == "__main__":
    main()
