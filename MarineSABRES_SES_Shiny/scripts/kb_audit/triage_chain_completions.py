#!/usr/bin/env python3
"""Chain-completion connection triage for KB quality cleanup.

Processes the 301 chain-completion connections in ses_knowledge_db.json.
For each, checks if an alternative path exists via organic (non-chain-
completion) connections. Classifies as REDUNDANT or LOAD_BEARING.

Does NOT modify the original KB. Writes cleaned output to
scripts/kb_audit/output/ses_knowledge_db_cleaned.json.

Pre-flight check: verifies Part B removals have been applied before
running (otherwise path-redundancy decisions would use stale data).

Usage:
    micromamba run -n shiny python scripts/kb_audit/triage_chain_completions.py
"""

import json
import sys
from collections import defaultdict
from pathlib import Path


CHAIN_COMPLETION_MARKERS = [
    "connection added to complete",
    "added to ensure",
    "added to connect",
    "chain completion",
]

# Must match audit_kb_quality.py's bridge marker set exactly.
# If this diverges, the audit and triage will disagree.
BRIDGE_MARKERS = [
    "bridge", "connect disconnected",
    "no scientific basis", "no ecological",
    "no mechanism", "no causal",
]

# Connections that MUST be absent (Part B removals). If any are present,
# the script exits — Part B has not been applied yet.
PART_B_REMOVAL_CHECKS = [
    ("macaronesia_island", "Coastal aquaculture", "Coastal water quality"),
    ("macaronesia_island", "Ocean warming and marine heatwaves", "Coastal property values"),
    ("macaronesia_open_coast", "Pelagic Sargassum community extent", "Marine ecotourism income"),
    ("macaronesia_open_coast", "Loss of apex predator trophic function", "Disrupted pelagic food web"),
    ("macaronesia_island", "Recreational diving and whale watching", "Recreational wellbeing"),
]


def preflight_check(kb: dict) -> None:
    """Verify Part B removals have been applied."""
    for ctx_name, from_substr, to_substr in PART_B_REMOVAL_CHECKS:
        ctx = kb.get("contexts", {}).get(ctx_name, {})
        for conn in ctx.get("connections", []):
            if from_substr in conn.get("from", "") and to_substr in conn.get("to", ""):
                print(f"ERROR: Part B removal not applied: {ctx_name}: "
                      f"{from_substr} -> {to_substr}", file=sys.stderr)
                print("Run scripts/kb_audit/apply_part_b_fixes.py first.", file=sys.stderr)
                sys.exit(1)
    print("Pre-flight check passed: Part B removals verified.")


def is_chain_completion(conn: dict) -> bool:
    """True if rationale contains a chain-completion marker."""
    rationale = conn.get("rationale", "").lower()
    return any(marker in rationale for marker in CHAIN_COMPLETION_MARKERS)


def build_organic_graph(connections: list) -> dict:
    """Build adjacency dict from non-chain-completion connections."""
    graph = defaultdict(set)
    for conn in connections:
        if is_chain_completion(conn):
            continue
        f = conn.get("from", "")
        t = conn.get("to", "")
        if f and t:
            graph[f].add(t)
    return graph


def has_path(graph: dict, start: str, end: str, max_depth: int = 10) -> bool:
    """BFS check if a path exists from start to end in the organic graph."""
    if start == end:
        return True
    visited = {start}
    queue = [(start, 0)]
    while queue:
        node, depth = queue.pop(0)
        if depth >= max_depth:
            continue
        for neighbor in graph.get(node, set()):
            if neighbor == end:
                return True
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append((neighbor, depth + 1))
    return False


def is_bridge(conn: dict) -> bool:
    """True if rationale contains a bridge marker."""
    rationale = conn.get("rationale", "").lower()
    return any(marker in rationale for marker in BRIDGE_MARKERS)


def count_sccs(connections: list, exclude_conn: tuple = None) -> int:
    """Count strongly-connected components in the directed graph built
    from connections. Optionally exclude one connection (by from, to tuple)
    to measure impact of removal.
    """
    try:
        import networkx as nx
    except ImportError:
        print("ERROR: networkx not installed. Run:", file=sys.stderr)
        print("  micromamba install -n shiny networkx", file=sys.stderr)
        sys.exit(1)

    G = nx.DiGraph()
    for c in connections:
        f = c.get("from", "")
        t = c.get("to", "")
        if not f or not t:
            continue
        if exclude_conn is not None and (f, t) == exclude_conn:
            continue
        G.add_edge(f, t)
    if G.number_of_nodes() == 0:
        return 0
    return nx.number_strongly_connected_components(G)


def triage_bridges_in_context(ctx_name: str, ctx: dict) -> list:
    """Classify bridge connections in a single context using SCC criterion."""
    connections = ctx.get("connections", [])
    decisions = []

    base_scc_count = count_sccs(connections)

    for idx, conn in enumerate(connections):
        if not is_bridge(conn):
            continue
        f = conn.get("from", "")
        t = conn.get("to", "")
        new_scc_count = count_sccs(connections, exclude_conn=(f, t))
        if new_scc_count > base_scc_count:
            verdict = "LOAD_BEARING"
            reason = f"removal increases SCC count ({base_scc_count} -> {new_scc_count})"
        else:
            verdict = "REDUNDANT"
            reason = "removal does not affect strongly-connected components"
        decisions.append({
            "context": ctx_name,
            "index": idx,
            "from": f,
            "to": t,
            "from_type": conn.get("from_type", ""),
            "to_type": conn.get("to_type", ""),
            "verdict": verdict,
            "reason": reason,
            "kind": "bridge",
        })
    return decisions


def improve_bridge_rationale(conn: dict) -> str:
    """Generate context-specific rationale from element types."""
    ft = conn.get("from_type", "").lower()
    tt = conn.get("to_type", "").lower()
    templates = {
        ("drivers", "activities"): "Driver motivates the activity as a response to underlying need.",
        ("activities", "pressures"): "Human activity generates environmental pressure on the marine system.",
        ("pressures", "states"): "Pressure alters ecosystem state through direct impact mechanism.",
        ("states", "impacts"): "Ecosystem state change affects ecosystem service delivery.",
        ("impacts", "welfare"): "Ecosystem service change influences human welfare outcomes.",
        ("welfare", "drivers"): "Welfare outcomes feed back to drivers via societal response.",
        ("welfare", "responses"): "Welfare concerns trigger management response.",
        ("responses", "drivers"): "Response measure modifies underlying driver pressure.",
        ("responses", "activities"): "Response measure regulates or constrains activity.",
        ("responses", "pressures"): "Response measure directly reduces pressure intensity.",
        ("responses", "states"): "Response measure (e.g., restoration) improves ecosystem state.",
        ("activities", "activities"): "Activities interact via competition, displacement, or facilitation.",
        ("states", "states"): "Ecosystem state components interact (trophic, habitat, nutrient cycling).",
        ("pressures", "pressures"): "Pressures cascade or accumulate synergistically.",
        ("drivers", "pressures"): "Exogenic driver produces pressure without local activity intermediary.",
    }
    return templates.get((ft, tt), f"Connection linking {ft} to {tt}.")


def triage_context(ctx_name: str, ctx: dict) -> list:
    """Classify chain-completion connections in a single context."""
    connections = ctx.get("connections", [])
    organic_graph = build_organic_graph(connections)
    decisions = []

    for idx, conn in enumerate(connections):
        if not is_chain_completion(conn):
            continue
        f = conn.get("from", "")
        t = conn.get("to", "")
        # Edge case: if no organic connections of the same transition type exist,
        # cannot verify redundancy — treat as LOAD_BEARING
        transition_type = (conn.get("from_type", "").lower(), conn.get("to_type", "").lower())
        has_organic_same_type = any(
            (c.get("from_type", "").lower(), c.get("to_type", "").lower()) == transition_type
            for c in connections if not is_chain_completion(c)
        )
        if not has_organic_same_type:
            verdict = "LOAD_BEARING"
            reason = "no organic connections of same transition type to compare against"
        elif has_path(organic_graph, f, t):
            verdict = "REDUNDANT"
            reason = "alternative organic path exists"
        else:
            verdict = "LOAD_BEARING"
            reason = "no alternative path via organic connections"
        decisions.append({
            "context": ctx_name,
            "index": idx,
            "from": f,
            "to": t,
            "from_type": conn.get("from_type", ""),
            "to_type": conn.get("to_type", ""),
            "verdict": verdict,
            "reason": reason,
        })
    return decisions


def apply_removals(kb: dict, decisions: list) -> dict:
    """Return a new KB dict with REDUNDANT chain-completions and bridges
    removed, and LOAD_BEARING bridges given improved rationales."""
    remove_by_ctx = defaultdict(set)

    for d in decisions:
        key = (d["from"], d["to"])
        if d["verdict"] == "REDUNDANT":
            remove_by_ctx[d["context"]].add(key)

    cleaned = json.loads(json.dumps(kb))  # deep copy

    for ctx_name, ctx in cleaned.get("contexts", {}).items():
        removals = remove_by_ctx.get(ctx_name, set())
        new_conns = []
        for c in ctx.get("connections", []):
            key = (c.get("from", ""), c.get("to", ""))
            is_cc = is_chain_completion(c)
            is_br = is_bridge(c)
            if (is_cc or is_br) and key in removals:
                continue  # remove
            # Improve LOAD_BEARING bridge rationale
            if is_br and key not in removals:
                new_rationale = improve_bridge_rationale(c)
                c = {**c, "rationale": new_rationale}
            new_conns.append(c)
        ctx["connections"] = new_conns
    return cleaned


def write_markdown_report(decisions: list, output_path: Path) -> None:
    total = len(decisions)
    redundant = [d for d in decisions if d["verdict"] == "REDUNDANT"]
    load_bearing = [d for d in decisions if d["verdict"] == "LOAD_BEARING"]

    lines = [
        "# Chain-Completion Triage Report",
        "",
        f"**Total chain-completions:** {total}",
        f"**REDUNDANT (to remove):** {len(redundant)}",
        f"**LOAD_BEARING (to keep):** {len(load_bearing)}",
        "",
        "## REDUNDANT Connections",
        "",
    ]
    for d in redundant[:50]:
        lines.append(f"- `{d['context']}[{d['index']}]`: {d['from'][:40]} -> {d['to'][:40]} ({d['from_type']}->{d['to_type']})")
    if len(redundant) > 50:
        lines.append(f"- ... and {len(redundant) - 50} more")
    lines.append("")
    lines.append("## LOAD_BEARING Connections (sample)")
    lines.append("")
    for d in load_bearing[:20]:
        lines.append(f"- `{d['context']}[{d['index']}]`: {d['from'][:40]} -> {d['to'][:40]} -- {d['reason']}")
    if len(load_bearing) > 20:
        lines.append(f"- ... and {len(load_bearing) - 20} more")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    project_root = Path(__file__).parent.parent.parent
    kb_path = project_root / "data" / "ses_knowledge_db.json"
    output_dir = Path(__file__).parent / "output"
    output_dir.mkdir(exist_ok=True)

    with open(kb_path, "r", encoding="utf-8") as f:
        kb = json.load(f)

    preflight_check(kb)

    # Triage all contexts — both chain-completions and bridges
    all_decisions = []
    for ctx_name, ctx in kb.get("contexts", {}).items():
        all_decisions.extend(triage_context(ctx_name, ctx))
        all_decisions.extend(triage_bridges_in_context(ctx_name, ctx))

    # Write decisions
    decisions_path = output_dir / "chain_completion_decisions.json"
    with open(decisions_path, "w", encoding="utf-8") as f:
        json.dump(all_decisions, f, indent=2, ensure_ascii=False)

    md_path = output_dir / "chain_completion_decisions.md"
    write_markdown_report(all_decisions, md_path)

    # Apply and write cleaned KB
    cleaned = apply_removals(kb, all_decisions)
    cleaned_path = output_dir / "ses_knowledge_db_cleaned.json"
    with open(cleaned_path, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, indent=2, ensure_ascii=False)

    total = len(all_decisions)
    cc = [d for d in all_decisions if d.get("kind") != "bridge"]
    br = [d for d in all_decisions if d.get("kind") == "bridge"]
    cc_redundant = sum(1 for d in cc if d["verdict"] == "REDUNDANT")
    br_redundant = sum(1 for d in br if d["verdict"] == "REDUNDANT")
    print(f"\nTriage complete:")
    print(f"  Chain-completions: {len(cc)} ({cc_redundant} REDUNDANT, {len(cc)-cc_redundant} LOAD_BEARING)")
    print(f"  Bridges: {len(br)} ({br_redundant} REDUNDANT, {len(br)-br_redundant} LOAD_BEARING)")
    print(f"\nDecisions: {decisions_path}")
    print(f"Report: {md_path}")
    print(f"Cleaned KB: {cleaned_path}")


if __name__ == "__main__":
    main()
