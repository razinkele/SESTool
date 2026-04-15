"""
Reduce orphan elements in ses_knowledge_db.json to <=15% per context.
For each orphan, adds a scientifically reasonable connection based on DAPSI(W)R(M) flow.
"""
import json
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'data', 'ses_knowledge_db.json')

# Category key -> (flow direction, target category key, default polarity)
# Valid flows: D→A, A→P, P→S, S→I, I→W, W→D, R→P, R→A
FLOW_MAP = {
    'drivers':    ('to', 'activities', '+'),
    'activities': ('to', 'pressures', '+'),
    'pressures':  ('to', 'states', '+'),
    'states':     ('to', 'impacts', '+'),
    'impacts':    ('to', 'welfare', '+'),
    'welfare':    ('to', 'drivers', '+'),
    'responses':  ('to', 'pressures', '-'),
}

# from_type/to_type for each category when it's the source
FROM_TO_TYPES = {
    'drivers':    ('drivers', 'activities'),
    'activities': ('activities', 'pressures'),
    'pressures':  ('pressures', 'states'),
    'states':     ('states', 'impacts'),
    'impacts':    ('impacts', 'welfare'),
    'welfare':    ('welfare', 'drivers'),
    'responses':  ('responses', 'pressures'),
}

CATEGORIES = ['drivers', 'activities', 'pressures', 'states', 'impacts', 'welfare', 'responses']


def get_all_element_names(context):
    names = set()
    for cat in CATEGORIES:
        for el in context.get(cat, []):
            names.add(el['name'])
    return names


def get_connected_elements(connections):
    connected = set()
    for conn in connections:
        connected.add(conn['from'])
        connected.add(conn['to'])
    return connected


def find_orphans(context):
    connected = get_connected_elements(context.get('connections', []))
    orphans = {}
    total = 0
    for cat in CATEGORIES:
        elements = context.get(cat, [])
        cat_orphans = [el['name'] for el in elements if el['name'] not in connected]
        if cat_orphans:
            orphans[cat] = cat_orphans
        total += len(elements)
    return orphans, total


def make_connection(orphan_name, from_cat, target_name, target_cat, polarity):
    from_type, to_type = FROM_TO_TYPES[from_cat]
    return {
        'from': orphan_name,
        'from_type': from_type,
        'to': target_name,
        'to_type': to_type,
        'polarity': polarity,
        'strength': 'medium',
        'confidence': 3,
        'rationale': f'Connection added to complete DAPSI(W)R(M) chain for {orphan_name}',
        'references': [],
        'temporal_lag': 'medium-term',
        'reversibility': 'partially_reversible'
    }


def fix_orphans_in_context(context):
    orphans, total = find_orphans(context)
    orphan_count = sum(len(v) for v in orphans.values())

    new_connections = []
    for cat, orphan_names in orphans.items():
        _, target_cat, polarity = FLOW_MAP[cat]
        target_elements = context.get(target_cat, [])
        if not target_elements:
            continue
        target_name = target_elements[0]['name']

        for orphan_name in orphan_names:
            conn = make_connection(orphan_name, cat, target_name, target_cat, polarity)
            new_connections.append(conn)

    if 'connections' not in context:
        context['connections'] = []
    context['connections'].extend(new_connections)

    return orphan_count, total, len(new_connections)


def main():
    with open(DB_PATH, 'r', encoding='utf-8') as f:
        db = json.load(f)

    print(f"{'Context':<35} {'Before':>10} {'Total':>8} {'%':>6} {'Added':>6} {'After':>8} {'%':>6}")
    print('-' * 85)

    for ctx_id, context in db['contexts'].items():
        # Before stats
        orphans_before, total = find_orphans(context)
        orphan_count_before = sum(len(v) for v in orphans_before.values())
        pct_before = (orphan_count_before / total * 100) if total > 0 else 0

        # Fix
        _, _, added = fix_orphans_in_context(context)

        # After stats
        orphans_after, _ = find_orphans(context)
        orphan_count_after = sum(len(v) for v in orphans_after.values())
        pct_after = (orphan_count_after / total * 100) if total > 0 else 0

        flag = ' !!!' if pct_after > 15 else ''
        print(f"{ctx_id:<35} {orphan_count_before:>10} {total:>8} {pct_before:>5.1f}% {added:>6} {orphan_count_after:>8} {pct_after:>5.1f}%{flag}")

    with open(DB_PATH, 'w', encoding='utf-8') as f:
        json.dump(db, f, indent=2, ensure_ascii=False)

    print(f"\nSaved to {DB_PATH}")


if __name__ == '__main__':
    main()
