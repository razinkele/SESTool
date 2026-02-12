#!/usr/bin/env python3
"""
Merge extracted translation entries into module translation files.
Avoids duplicates and maintains proper JSON structure.
"""

import json
from pathlib import Path

def load_json(file_path):
    """Load JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(file_path, data):
    """Save JSON file with pretty formatting."""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"  ✓ Saved: {file_path}")

def merge_entries(existing_file, new_entries_file, output_file):
    """Merge new entries into existing translation file."""
    
    # Load files
    existing = load_json(existing_file)
    new_entries = load_json(new_entries_file)
    
    # Get existing keys
    existing_keys = set()
    for entry in existing['translation']:
        if 'key' in entry:
            existing_keys.add(entry['key'])
    
    # Add only new entries (avoid duplicates)
    added_count = 0
    for entry in new_entries:
        key = entry.get('key')
        if key and key not in existing_keys:
            existing['translation'].append(entry)
            existing_keys.add(key)
            added_count += 1
    
    # Save merged file
    save_json(output_file, existing)
    
    return added_count, len(existing['translation'])

def main():
    """Main merge process."""
    print("="*70)
    print("MERGING EXTRACTED TRANSLATIONS INTO MODULE FILES")
    print("="*70)
    
    # Map extracted files to module files
    merges = [
        ('/tmp/new_entries_response_measures.json', 
         'translations/modules/response_measures.json'),
        
        ('/tmp/new_entries_ses_creation.json',
         'translations/modules/ses_creation.json'),
        
        ('/tmp/new_entries_entry_point.json',
         'translations/modules/entry_point.json'),
        
        ('/tmp/new_entries_export_reports.json',
         'translations/modules/export_reports.json'),
        
        ('/tmp/new_entries_isa_data_entry.json',
         'translations/modules/isa_data_entry.json'),
        
        ('/tmp/new_entries_analysis_tools.json',
         'translations/modules/analysis_tools.json'),
        
        ('/tmp/new_entries_scenario_builder.json',
         'translations/modules/scenario_builder.json'),
        
        ('/tmp/new_entries_pims_stakeholder.json',
         'translations/modules/pims_stakeholder.json'),
    ]
    
    total_added = 0
    
    for new_file, existing_file in merges:
        new_path = Path(new_file)
        existing_path = Path(existing_file)
        
        if not new_path.exists():
            print(f"\n⚠ Skipping {new_path.name} - file not found")
            continue
        
        if not existing_path.exists():
            print(f"\n⚠ Skipping {existing_path.name} - module file not found")
            continue
        
        print(f"\n{'='*70}")
        print(f"Merging: {new_path.name} → {existing_path.name}")
        print(f"{'='*70}")
        
        added, total = merge_entries(existing_path, new_path, existing_path)
        total_added += added
        
        print(f"  Added {added} new entries")
        print(f"  Total entries now: {total}")
    
    print(f"\n{'='*70}")
    print("MERGE COMPLETE")
    print(f"{'='*70}")
    print(f"Total new entries added across all modules: {total_added}")

if __name__ == '__main__':
    main()

