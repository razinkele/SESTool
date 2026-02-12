#!/usr/bin/env python3
"""Generate flat-to-namespaced key mapping

This script analyzes the extracted translation keys and suggests appropriate
namespaced keys based on context and source file location.

Strategy: Hybrid organization - Common functions (buttons, labels) + module-specific
"""

import json
import re
from pathlib import Path
from collections import defaultdict

def to_snake_case(text):
    """Convert text to snake_case"""
    # Remove special characters except spaces and hyphens
    text = re.sub(r'[^\w\s-]', '', text)
    # Replace spaces and hyphens with underscores
    text = re.sub(r'[-\s]+', '_', text)
    # Convert to lowercase
    text = text.lower()
    # Remove multiple underscores
    text = re.sub(r'_+', '_', text)
    # Remove leading/trailing underscores
    text = text.strip('_')
    return text

def suggest_namespace(english_key, source_files):
    """AI-assisted namespace suggestion based on key and source files"""

    # Determine most common source file
    source_file = source_files[0] if source_files else 'unknown'

    # Common UI element patterns
    common_buttons = ['Close', 'Cancel', 'Apply', 'Save', 'Load', 'Delete', 'Edit', 'Add', 'Remove',
                      'Next', 'Previous', 'Back', 'Continue', 'Skip', 'Finish', 'Submit', 'Confirm',
                      'Yes', 'No', 'OK', 'Done', 'Start', 'Stop', 'Pause', 'Resume', 'Reset', 'Clear']
    common_labels = ['Name:', 'Description:', 'Purpose:', 'Type:', 'Category:', 'Status:', 'Date:',
                     'Title:', 'Label:', 'Value:', 'Comment:', 'Notes:', 'Details:', 'Summary:']
    common_messages = ['Loading...', 'Processing...', 'Please wait', 'No data available', 'Error:',
                      'Success', 'Warning', 'Information', 'Confirm', 'Are you sure?']

    # Remove punctuation for matching
    clean_key = english_key.strip(':').strip()

    # Common buttons
    if clean_key in common_buttons:
        return f"common.buttons.{to_snake_case(clean_key)}"

    # Common labels
    if any(english_key.endswith(label) or clean_key in label for label in common_labels):
        return f"common.labels.{to_snake_case(clean_key)}"

    # Common messages
    if any(msg in english_key for msg in common_messages):
        return f"common.messages.{to_snake_case(english_key)}"

    # Module-specific detection from file path
    if 'isa_data_entry' in source_file:
        # Determine exercise number
        if 'exercise 0' in english_key.lower() or 'preliminary' in english_key.lower():
            return f"modules.isa.data_entry.ex0.{to_snake_case(english_key)}"
        elif 'exercise 1' in english_key.lower() or 'driver' in english_key.lower():
            return f"modules.isa.data_entry.ex1.{to_snake_case(english_key)}"
        elif 'exercise 2a' in english_key.lower() or ('exercise 2' in english_key.lower() and 'activit' in english_key.lower()):
            return f"modules.isa.data_entry.ex2a.{to_snake_case(english_key)}"
        elif 'exercise 2b' in english_key.lower() or ('exercise 2' in english_key.lower() and 'pressure' in english_key.lower()):
            return f"modules.isa.data_entry.ex2b.{to_snake_case(english_key)}"
        elif 'exercise 3' in english_key.lower() or 'state' in english_key.lower():
            return f"modules.isa.data_entry.ex3.{to_snake_case(english_key)}"
        elif 'exercise 4' in english_key.lower() or 'impact' in english_key.lower():
            return f"modules.isa.data_entry.ex4.{to_snake_case(english_key)}"
        elif 'exercise 5' in english_key.lower() or 'welfare' in english_key.lower():
            return f"modules.isa.data_entry.ex5.{to_snake_case(english_key)}"
        elif 'exercise 6' in english_key.lower() or 'response' in english_key.lower():
            return f"modules.isa.data_entry.ex6.{to_snake_case(english_key)}"
        elif any(ex in english_key.lower() for ex in ['exercise 7', 'exercise 8', 'exercise 9', 'ecosystem service', 'goods', 'benefit']):
            return f"modules.isa.data_entry.ex789.{to_snake_case(english_key)}"
        elif any(ex in english_key.lower() for ex in ['exercise 10', 'exercise 11', 'exercise 12', 'connection']):
            return f"modules.isa.data_entry.ex101112.{to_snake_case(english_key)}"
        else:
            return f"modules.isa.data_entry.common.{to_snake_case(english_key)}"

    elif 'ai_isa_assistant' in source_file:
        return f"modules.isa.ai_assistant.{to_snake_case(english_key)}"

    elif 'pims_stakeholder' in source_file:
        return f"modules.pims.stakeholder.{to_snake_case(english_key)}"

    elif 'pims' in source_file and 'project' in source_file:
        return f"modules.pims.project.{to_snake_case(english_key)}"

    elif 'pims' in source_file and 'resource' in source_file:
        return f"modules.pims.resources.{to_snake_case(english_key)}"

    elif 'pims' in source_file and 'evaluation' in source_file:
        return f"modules.pims.evaluation.{to_snake_case(english_key)}"

    elif 'analysis_tools' in source_file:
        if 'loop' in english_key.lower():
            return f"modules.analysis.loops.{to_snake_case(english_key)}"
        elif 'leverage' in english_key.lower():
            return f"modules.analysis.leverage.{to_snake_case(english_key)}"
        elif 'network' in english_key.lower() or 'metric' in english_key.lower():
            return f"modules.analysis.network.{to_snake_case(english_key)}"
        elif 'bot' in english_key.lower():
            return f"modules.analysis.bot.{to_snake_case(english_key)}"
        elif 'simplif' in english_key.lower():
            return f"modules.analysis.simplify.{to_snake_case(english_key)}"
        else:
            return f"modules.analysis.common.{to_snake_case(english_key)}"

    elif 'cld_visualization' in source_file:
        return f"modules.cld.visualization.{to_snake_case(english_key)}"

    elif 'scenario_builder' in source_file:
        return f"modules.scenario.builder.{to_snake_case(english_key)}"

    elif 'response_module' in source_file:
        return f"modules.response.measures.{to_snake_case(english_key)}"

    elif 'entry_point' in source_file:
        return f"modules.entry_point.{to_snake_case(english_key)}"

    elif 'template_ses' in source_file or 'create_ses' in source_file:
        return f"modules.ses.creation.{to_snake_case(english_key)}"

    elif 'export' in source_file or 'report' in source_file:
        return f"modules.export.reports.{to_snake_case(english_key)}"

    # UI components
    elif 'ui_sidebar' in source_file or 'sidebar' in english_key.lower():
        return f"ui.sidebar.{to_snake_case(english_key)}"

    elif 'ui_header' in source_file or 'header' in english_key.lower():
        return f"ui.header.{to_snake_case(english_key)}"

    elif 'modals' in source_file or 'modal' in english_key.lower():
        return f"ui.modals.{to_snake_case(english_key)}"

    elif 'dashboard' in source_file:
        return f"ui.dashboard.{to_snake_case(english_key)}"

    # Data/framework terms
    if any(term in english_key for term in ['Driver', 'Activity', 'Pressure', 'State', 'Impact', 'Welfare', 'Response', 'Measure', 'Component', 'Ecosystem', 'Marine']):
        return f"data.framework.{to_snake_case(english_key)}"

    # Default to common.misc
    return f"common.misc.{to_snake_case(english_key)}"

def main():
    print("=" * 60)
    print("Translation Key Mapping Generator")
    print("=" * 60)
    print()

    # Load audit results
    print("Loading audit data...")
    with open('scripts/migration_audit.json', 'r', encoding='utf-8') as f:
        audit = json.load(f)

    print(f"Found {audit['summary']['unique_keys']} unique keys")
    print()

    # Create mapping
    print("Generating namespace suggestions...")
    mapping = {}
    category_counts = defaultdict(int)

    for key, info in audit['by_key'].items():
        source_files = info['files']
        namespaced_key = suggest_namespace(key, source_files)
        mapping[key] = {
            'namespaced_key': namespaced_key,
            'source_files': source_files,
            'usage_count': info['count']
        }

        # Count by category
        category = namespaced_key.split('.')[0]
        category_counts[category] += 1

    print(f"✓ Created {len(mapping)} key mappings")
    print()

    # Statistics by category
    print("Mapping Statistics by Category:")
    print("-" * 60)
    for category, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  {category:20s}: {count:4d} keys")

    # Save mapping
    output_file = 'scripts/key_mapping.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(mapping, f, indent=2, ensure_ascii=False)

    print()
    print(f"✓ Mapping saved to: {output_file}")
    print()

    # Create simple flat mapping for easy lookups
    simple_mapping = {k: v['namespaced_key'] for k, v in mapping.items()}
    simple_output = 'scripts/key_mapping_simple.json'
    with open(simple_output, 'w', encoding='utf-8') as f:
        json.dump(simple_mapping, f, indent=2, ensure_ascii=False)

    print(f"✓ Simple mapping saved to: {simple_output}")
    print()

    # Show examples
    print("Sample Mappings:")
    print("-" * 60)
    examples = list(mapping.items())[:15]
    for flat_key, info in examples:
        print(f"  '{flat_key:30s}' → '{info['namespaced_key']}'")

    print()
    print("=" * 60)
    print("Key mapping generation complete!")
    print("=" * 60)
    print()
    print("NEXT STEPS:")
    print("1. Review key_mapping.json and adjust namespaces if needed")
    print("2. Run migrate_legacy_translations.py to convert translation files")
    print("3. Run migrate_r_code.py to update R code")

if __name__ == '__main__':
    main()
