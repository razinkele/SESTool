#!/usr/bin/env python3
"""
Extract missing translation keys from backup file and create complete entries.
This script matches truncated keys with full English text from the legacy backup.
"""

import json
import sys
from pathlib import Path

def load_backup():
    """Load the legacy translation backup file."""
    backup_path = Path('translations/translation.json.backup')
    with open(backup_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_module_file(module_name):
    """Load existing module translation file."""
    module_path = Path(f'translations/modules/{module_name}.json')
    if module_path.exists():
        with open(module_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None

def load_missing_keys(module_base_name):
    """Load the list of missing keys for a module."""
    keys_file = Path(f'/tmp/used_keys_{module_base_name}.txt')
    if not keys_file.exists():
        return []
    with open(keys_file, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def find_translation_in_backup(key, backup):
    """
    Find a translation entry in backup by key or by matching English text.
    Handles both keyed entries and flat-key entries.
    """
    # Try exact key match first
    for entry in backup['translation']:
        if entry.get('key') == key:
            return entry
    
    # Try matching by truncated English text in key
    # Extract the last part of the key (after last dot) which might be truncated English
    key_suffix = key.split('.')[-1]
    
    for entry in backup['translation']:
        en_text = entry.get('en', '')
        # Check if English text (normalized) matches or starts with key suffix
        normalized_en = en_text.lower().replace(' ', '_').replace('-', '_')
        if normalized_en.startswith(key_suffix.lower()) or key_suffix.lower() in normalized_en:
            return entry
    
    return None

def create_placeholder_entry(key):
    """Create a placeholder entry when no translation is found."""
    # Extract readable text from key
    key_parts = key.split('.')
    english_text = key_parts[-1].replace('_', ' ').title()
    
    return {
        "key": key,
        "en": english_text,
        "es": f"[ES] {english_text}",
        "fr": f"[FR] {english_text}",
        "de": f"[DE] {english_text}",
        "lt": f"[LT] {english_text}",
        "pt": f"[PT] {english_text}",
        "it": f"[IT] {english_text}"
    }

def extract_missing_for_module(module_base_name, module_trans_name, backup):
    """Extract all missing translations for a module."""
    print(f"\n{'='*70}")
    print(f"Processing: {module_base_name} → {module_trans_name}.json")
    print(f"{'='*70}")
    
    # Load missing keys
    missing_keys = load_missing_keys(module_base_name)
    if not missing_keys:
        print(f"No missing keys file found for {module_base_name}")
        return None
    
    print(f"Found {len(missing_keys)} missing keys")
    
    # Load existing module file
    module_data = load_module_file(module_trans_name)
    if not module_data:
        print(f"Module file not found: {module_trans_name}.json")
        return None
    
    # Track results
    found_count = 0
    placeholder_count = 0
    new_entries = []
    
    # Process each missing key
    for key in missing_keys:
        # Try to find in backup
        entry = find_translation_in_backup(key, backup)
        
        if entry:
            # Found in backup - ensure it has the 'key' field
            if 'key' not in entry:
                entry['key'] = key
            new_entries.append(entry)
            found_count += 1
            print(f"  ✓ Found: {key}")
        else:
            # Create placeholder
            entry = create_placeholder_entry(key)
            new_entries.append(entry)
            placeholder_count += 1
            print(f"  ⚠ Placeholder: {key} → {entry['en']}")
    
    print(f"\nResults:")
    print(f"  Found in backup: {found_count}")
    print(f"  Created placeholders: {placeholder_count}")
    
    return {
        'module_name': module_trans_name,
        'existing_entries': len(module_data['translation']),
        'new_entries': new_entries,
        'found_count': found_count,
        'placeholder_count': placeholder_count
    }

def main():
    """Main extraction process."""
    print("="*70)
    print("COMPREHENSIVE TRANSLATION EXTRACTION")
    print("="*70)
    
    # Load backup
    print("\nLoading backup translation file...")
    backup = load_backup()
    print(f"Loaded {len(backup['translation'])} entries from backup")
    
    # Module mapping: base_name → translation_file_name
    modules = {
        'response': 'response_measures',
        'create_ses': 'ses_creation',
        'template_ses': 'ses_creation',
        'entry_point': 'entry_point',
        'export_reports': 'export_reports',
        'ai_isa_assistant': 'isa_data_entry',
        'analysis_tools': 'analysis_tools',
        'isa_data_entry': 'isa_data_entry',
        'scenario_builder': 'scenario_builder',
        'pims_stakeholder': 'pims_stakeholder',
    }
    
    # Process each module
    results = []
    for base_name, trans_name in modules.items():
        result = extract_missing_for_module(base_name, trans_name, backup)
        if result:
            results.append(result)
    
    # Save results summary
    summary = {
        'total_modules': len(results),
        'modules': results,
        'grand_total_found': sum(r['found_count'] for r in results),
        'grand_total_placeholders': sum(r['placeholder_count'] for r in results)
    }
    
    summary_file = Path('scripts/extraction_summary.json')
    with open(summary_file, 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*70}")
    print("EXTRACTION COMPLETE")
    print(f"{'='*70}")
    print(f"Total modules processed: {len(results)}")
    print(f"Total found in backup: {summary['grand_total_found']}")
    print(f"Total placeholders created: {summary['grand_total_placeholders']}")
    print(f"\nSummary saved to: {summary_file}")
    
    # Save each module's new entries
    for result in results:
        output_file = Path(f'/tmp/new_entries_{result["module_name"]}.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result['new_entries'], f, indent=2, ensure_ascii=False)
        print(f"New entries for {result['module_name']}: {output_file}")

if __name__ == '__main__':
    main()

