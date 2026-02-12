#!/usr/bin/env python3
"""Fix obvious misclassifications in key mapping

Cleans up common.misc and fixes known issues.
"""

import json
import re

def main():
    print("=" * 60)
    print("Key Mapping Cleanup")
    print("=" * 60)
    print()

    # Load current mapping
    with open('scripts/key_mapping_simple.json', 'r', encoding='utf-8') as f:
        mapping = json.load(f)

    print(f"Loaded {len(mapping)} mappings")
    print()

    fixes = 0

    # Fix 1: UI/Action buttons that ended up in wrong places
    button_fixes = {
        'Save Project': 'common.buttons.save_project',
        'Load Project': 'common.buttons.load_project',
        'Save': 'common.buttons.save',
        'Load': 'common.buttons.load',
        'Apply': 'common.buttons.apply',
    }

    for key, new_ns in button_fixes.items():
        if key in mapping and mapping[key] != new_ns:
            old_ns = mapping[key]
            mapping[key] = new_ns
            print(f"✓ Fixed: '{key}'")
            print(f"  {old_ns} → {new_ns}")
            fixes += 1

    # Fix 2: UI sidebar items misclassified as common.misc
    sidebar_patterns = [
        ('Getting Started', 'ui.sidebar.getting_started'),
        ('Dashboard', 'ui.sidebar.dashboard'),
        ('AI Assistant', 'ui.sidebar.ai_assistant'),
        ('Standard Entry', 'ui.sidebar.standard_entry'),
        ('Template-Based', 'ui.sidebar.template_based'),
        ('Analysis Tools', 'ui.sidebar.analysis_tools'),
        ('Loop Detection', 'ui.sidebar.loop_detection'),
        ('Leverage Point Analysis', 'ui.sidebar.leverage_point_analysis'),
        ('PIMS Module', 'ui.sidebar.pims_module'),
        ('Create SES', 'ui.sidebar.create_ses'),
        ('SES Visualization', 'ui.sidebar.ses_visualization'),
        ('Response & Validation', 'ui.sidebar.response_validation'),
        ('Response Measures', 'ui.sidebar.response_measures'),
        ('Scenario Builder', 'ui.sidebar.scenario_builder'),
        ('Import Data', 'ui.sidebar.import_data'),
        ('Export Data', 'ui.sidebar.export_data'),
        ('Prepare Report', 'ui.sidebar.prepare_report'),
        ('Quick Actions', 'ui.sidebar.quick_actions'),
    ]

    for key, new_ns in sidebar_patterns:
        if key in mapping and 'common.misc' in mapping[key]:
            old_ns = mapping[key]
            mapping[key] = new_ns
            print(f"✓ Fixed: '{key}'")
            print(f"  {old_ns} → {new_ns}")
            fixes += 1

    # Fix 3: Dashboard/status items
    dashboard_items = {
        'Project Overview': 'ui.dashboard.project_overview',
        'Status Summary': 'ui.dashboard.status_summary',
        'ISA Data Status': 'ui.dashboard.isa_data_status',
        'CLD Status': 'ui.dashboard.cld_status',
        'Analysis Status': 'ui.dashboard.analysis_status',
        'Total Elements': 'ui.dashboard.total_elements',
    }

    for key, new_ns in dashboard_items.items():
        if key in mapping and mapping[key] != new_ns:
            old_ns = mapping[key]
            mapping[key] = new_ns
            print(f"✓ Fixed: '{key}'")
            print(f"  {old_ns} → {new_ns}")
            fixes += 1

    # Fix 4: Success/error messages
    message_patterns = [
        ('successfully!', 'common.messages'),
        ('Error:', 'common.messages'),
        ('Warning:', 'common.messages'),
        ('restored successfully', 'common.messages'),
        ('saved successfully', 'common.messages'),
        ('loaded successfully', 'common.messages'),
    ]

    for key, value in list(mapping.items()):
        if 'common.misc' in value:
            for pattern, category in message_patterns:
                if pattern in key:
                    new_ns = value.replace('common.misc', category)
                    mapping[key] = new_ns
                    print(f"✓ Fixed: '{key[:50]}'")
                    print(f"  {value} → {new_ns}")
                    fixes += 1
                    break

    # Fix 5: Shorten overly long keys
    print()
    print("Shortening long keys...")
    shortened = 0

    for key, ns in list(mapping.items()):
        if len(ns) > 80:
            parts = ns.split('.')
            if len(parts) > 2:
                # Keep category.subcategory and shorten the rest
                base = '.'.join(parts[:2])
                item = parts[-1]

                # Truncate to reasonable length
                if len(item) > 50:
                    # Abbreviate common words
                    item = item.replace('including', 'incl')
                    item = item.replace('current', 'curr')
                    item = item.replace('project', 'proj')
                    item = item.replace('data', 'dat')
                    item = item.replace('analysis', 'anlys')
                    item = item.replace('results', 'res')
                    item = item.replace('entries', 'ent')
                    item = item[:50]  # Hard limit

                new_ns = f"{base}.{item}"
                if new_ns != ns:
                    mapping[key] = new_ns
                    print(f"✓ Shortened: {ns[:60]}... → {new_ns[:60]}...")
                    shortened += 1

    print()
    print(f"✓ Applied {fixes} fixes")
    print(f"✓ Shortened {shortened} keys")
    print()

    # Save updated mapping
    with open('scripts/key_mapping_simple.json', 'w', encoding='utf-8') as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)

    print("✓ Updated mapping saved to: scripts/key_mapping_simple.json")
    print()

    # Count remaining common.misc
    misc_count = sum(1 for v in mapping.values() if 'common.misc' in v)
    print(f"Remaining common.misc entries: {misc_count} (down from 76)")
    print()

    print("=" * 60)
    print("Cleanup complete!")
    print("=" * 60)

if __name__ == '__main__':
    main()
