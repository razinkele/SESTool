#!/usr/bin/env python3
"""Preview key mapping before migration

Shows sample mappings organized by category to verify automated namespace suggestions.
"""

import json
from collections import defaultdict

def main():
    print("=" * 80)
    print("KEY MAPPING PREVIEW - Verify Before Migration")
    print("=" * 80)
    print()

    # Load mapping
    with open('scripts/key_mapping_simple.json', 'r', encoding='utf-8') as f:
        mapping = json.load(f)

    # Load audit to get usage counts
    with open('scripts/migration_audit.json', 'r', encoding='utf-8') as f:
        audit = json.load(f)

    # Group by category
    by_category = defaultdict(list)
    for flat_key, namespaced_key in mapping.items():
        category = namespaced_key.split('.')[0]
        subcategory = '.'.join(namespaced_key.split('.')[:2])
        usage = audit['by_key'].get(flat_key, {}).get('count', 0)
        by_category[subcategory].append({
            'flat': flat_key,
            'namespaced': namespaced_key,
            'usage': usage
        })

    # Sort categories
    sorted_categories = sorted(by_category.items(), key=lambda x: sum(item['usage'] for item in x[1]), reverse=True)

    # Display top categories with samples
    print("TOP CATEGORIES BY USAGE:")
    print("=" * 80)
    print()

    displayed = 0
    for subcategory, items in sorted_categories[:20]:  # Top 20 subcategories
        total_usage = sum(item['usage'] for item in items)
        print(f"📁 {subcategory} ({len(items)} keys, {total_usage} usages)")
        print("-" * 80)

        # Sort by usage and show top examples
        sorted_items = sorted(items, key=lambda x: x['usage'], reverse=True)
        for item in sorted_items[:5]:  # Top 5 examples per category
            flat_display = item['flat'][:45] + '...' if len(item['flat']) > 45 else item['flat']
            print(f"  {item['usage']:3d}x  '{flat_display}'")
            print(f"        → {item['namespaced']}")
            print()

        if len(sorted_items) > 5:
            print(f"        ... and {len(sorted_items) - 5} more keys in this category")
        print()

        displayed += 1
        if displayed >= 15:  # Limit to top 15 categories for readability
            break

    # Show code transformation examples
    print()
    print("=" * 80)
    print("CODE TRANSFORMATION EXAMPLES:")
    print("=" * 80)
    print()

    examples = [
        ('Close', 'common.buttons.close'),
        ('Getting Started', 'ui.sidebar.getting_started'),
        ('Save Project', 'common.buttons.save_project'),
        ('AI Assistant', 'ui.sidebar.ai_assistant'),
        ('Loop Detection', 'modules.analysis.loops.loop_detection'),
        ('Add Stakeholder', 'modules.pims.stakeholder.add_stakeholder'),
        ('Exercise 1: Drivers', 'modules.isa.data_entry.ex1.exercise_1_drivers'),
    ]

    for flat, expected_ns in examples:
        actual_ns = mapping.get(flat, 'NOT FOUND')
        match = "✓" if actual_ns == expected_ns else "✗"

        print(f"{match} R code transformation:")
        print(f"   BEFORE: i18n$t(\"{flat}\")")
        print(f"   AFTER:  i18n$t(\"{actual_ns}\")")
        print()

    # Statistics
    print("=" * 80)
    print("MAPPING STATISTICS:")
    print("=" * 80)
    print()

    category_counts = defaultdict(int)
    for ns_key in mapping.values():
        category = ns_key.split('.')[0]
        category_counts[category] += 1

    print("Distribution by top-level category:")
    for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
        percentage = (count / len(mapping)) * 100
        bar = "█" * int(percentage / 2)
        print(f"  {category:12s}: {count:4d} keys ({percentage:5.1f}%) {bar}")

    print()
    print("=" * 80)
    print("VALIDATION CHECKS:")
    print("=" * 80)
    print()

    # Check for potential issues
    issues = []

    # 1. Keys with no dots (not namespaced)
    non_namespaced = [k for k, v in mapping.items() if '.' not in v]
    if non_namespaced:
        issues.append(f"⚠️  {len(non_namespaced)} keys have no namespace dots")

    # 2. Very long keys (potential issues)
    long_keys = [(k, v) for k, v in mapping.items() if len(v) > 80]
    if long_keys:
        issues.append(f"⚠️  {len(long_keys)} keys are very long (>80 chars)")
        print(f"Long keys examples:")
        for flat, ns in long_keys[:3]:
            print(f"  - {ns[:77]}...")

    # 3. Keys mapped to common.misc (might need better categorization)
    misc_keys = [(k, v) for k, v in mapping.items() if 'common.misc' in v]
    if misc_keys:
        print(f"ℹ️  {len(misc_keys)} keys mapped to common.misc (review recommended):")
        for flat, ns in misc_keys[:5]:
            print(f"  - '{flat}' → {ns}")
        if len(misc_keys) > 5:
            print(f"  ... and {len(misc_keys) - 5} more")

    print()
    if issues:
        for issue in issues:
            print(issue)
    else:
        print("✅ No issues found!")

    print()
    print("=" * 80)
    print("NEXT STEPS:")
    print("=" * 80)
    print()
    print("1. Review the mappings above")
    print("2. If adjustments needed: Edit scripts/key_mapping_simple.json")
    print("3. If satisfied: Proceed with Phase 2 migration scripts")
    print()
    print("To manually adjust a mapping:")
    print('  1. Open: scripts/key_mapping_simple.json')
    print('  2. Find the flat key (e.g., "Getting Started")')
    print('  3. Change the namespaced value (e.g., "ui.sidebar.getting_started")')
    print('  4. Save and re-run the migration scripts')
    print()

if __name__ == '__main__':
    main()
