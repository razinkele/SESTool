#!/usr/bin/env python3
"""
Extract translatable strings from ISA Data Entry Module
and generate translations for all 7 languages
"""

import re
import json
from pathlib import Path

# Read the ISA module file
isa_module_path = Path("modules/isa_data_entry_module.R")
with open(isa_module_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Patterns to extract translatable strings
patterns = [
    # h1-h6 headers with quotes
    r'h[1-6]\("([^"]+)"\)',
    # p(), strong(), em() with quotes
    r'p\("([^"]+)"\)',
    r'p\(strong\("([^"]+)"\)',
    r'strong\("([^"]+)"\)',
    # textInput labels
    r'textInput\([^,]+,\s*"([^"]+)"',
    r'textAreaInput\([^,]+,\s*"([^"]+)"',
    r'selectInput\([^,]+,\s*"([^"]+)"',
    r'numericInput\([^,]+,\s*"([^"]+)"',
    r'checkboxInput\([^,]+,\s*"([^"]+)"',
    r'radioButtons\([^,]+,\s*"([^"]+)"',
    # actionButton labels
    r'actionButton\([^,]+,\s*"([^"]+)"',
    # tabPanel titles
    r'tabPanel\("([^"]+)"',
    # placeholder text
    r'placeholder\s*=\s*"([^"]+)"',
    # title attributes
    r'title\s*=\s*"([^"]+)"',
    # helpText
    r'helpText\("([^"]+)"\)',
]

# Extract all strings
all_strings = set()
for pattern in patterns:
    matches = re.findall(pattern, content)
    all_strings.update(matches)

# Filter out strings that shouldn't be translated
exclude_patterns = [
    r'^ns\(',  # Shiny namespace
    r'^\$',    # Variables
    r'^[A-Z]+\d+$',  # IDs like GB1, ES2
    r'^btn-',  # CSS classes
    r'^icon-',  # Icon names
    r'^\d+$',  # Pure numbers
    r'^[a-z_]+$',  # Pure lowercase identifiers
    r'\.R$',  # File names
    r'^http',  # URLs
]

translatable_strings = []
for string in all_strings:
    # Skip if matches any exclude pattern
    if any(re.search(pat, string) for pat in exclude_patterns):
        continue
    # Skip very short strings (< 3 chars)
    if len(string) < 3:
        continue
    # Skip if it's just a variable name pattern
    if string.islower() and '_' in string:
        continue

    translatable_strings.append(string)

# Sort and deduplicate
translatable_strings = sorted(set(translatable_strings))

print(f"Found {len(translatable_strings)} translatable strings")
print("\nFirst 20 strings:")
for i, s in enumerate(translatable_strings[:20], 1):
    print(f"{i}. {s}")

# Save to file for review
output_path = Path("isa_translatable_strings.txt")
with open(output_path, 'w', encoding='utf-8') as f:
    for string in translatable_strings:
        f.write(f"{string}\n")

print(f"\nAll strings saved to: {output_path}")
print(f"Total strings to translate: {len(translatable_strings)}")
