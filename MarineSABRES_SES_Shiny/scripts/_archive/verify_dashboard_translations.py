#!/usr/bin/env python3
"""
Verify all Dashboard strings have translations
"""

import json
from pathlib import Path

# Load translation.json
trans_path = Path("translations/translation.json")
with open(trans_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Get all English keys
translated_keys = {entry['en'] for entry in data['translation']}

# Dashboard strings that should be translated
dashboard_strings = [
    "MarineSABRES Social-Ecological Systems Analysis Tool",
    "Welcome to the computer-assisted SES creation and analysis platform.",
    "Total Elements",
    "Connections",
    "Loops Detected",
    "Completion",
    "Project Overview",
    "Quick Access",
    "Recent Activities",
    "Project ID:",
    "Created:",
    "Last Modified:",
    "Demonstration Area:",
    "Not set",
    "Focal Issue:",
    "Not defined",
    "Status Summary",
    "PIMS Setup:",
    "Complete",
    "Incomplete",
    "ISA Data Entry:",
    "Goods & Benefits:",
    "Ecosystem Services:",
    "Marine Processes:",
    "Pressures:",
    "Activities:",
    "Drivers:",
    "entries",
    "CLD Generated:",
    "Yes",
    "No",
    "CLD Preview",
    "No CLD Generated Yet",
    "Build your Causal Loop Diagram from the ISA data to visualize system connections.",
    "Build Network from ISA Data",
    "Export & Reports",
    "Export your data, visualizations, and generate comprehensive reports.",
    "Network Overview",
    "Quick Actions",
    "Save Project",
    "Load Project",
]

# Check coverage
missing = []
found = []

for string in dashboard_strings:
    if string in translated_keys:
        found.append(string)
    else:
        missing.append(string)

print("="*70)
print("Dashboard Translation Coverage Report")
print("="*70)
print(f"\nTotal Dashboard strings checked: {len(dashboard_strings)}")
print(f"Translated: {len(found)} ({len(found)/len(dashboard_strings)*100:.1f}%)")
print(f"Missing: {len(missing)} ({len(missing)/len(dashboard_strings)*100:.1f}%)")

if missing:
    print("\n" + "="*70)
    print("MISSING TRANSLATIONS:")
    print("="*70)
    for i, string in enumerate(missing, 1):
        print(f"{i}. {string}")
else:
    print("\n" + "="*70)
    print("✅ ALL DASHBOARD STRINGS ARE TRANSLATED!")
    print("="*70)

print("\nTranslation.json stats:")
print(f"  Total entries: {len(data['translation'])}")
print(f"  Total translations: {len(data['translation']) * 7} (7 languages)")
print("\n" + "="*70)
