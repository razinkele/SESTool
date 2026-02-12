#!/usr/bin/env python3
"""
Update merged translations file with Norwegian sidebar translations.
"""

import json
from pathlib import Path

# Norwegian translations for sidebar items
SIDEBAR_NORWEGIAN_TRANSLATIONS = {
    "AI Assistant": "AI-assistent",
    "AI guided SES creation": "AI-veiledet SES-opprettelse",
    "Analysis Tools": "Analyseverktøy",
    "BOT Analysis": "BOT-analyse",
    "Choose Method": "Velg metode",
    "CLD Visualization": "CLD-visualisering",
    "Create SES": "Opprett SES",
    "Dashboard": "Dashbord",
    "Entry Point": "Innganspunkt",
    "Evaluation": "Evaluering",
    "Export Data": "Eksporter data",
    "Getting Started": "Kom i gang",
    "Guided entry point to find the right tools for your marine management needs": "Veiledet innganspunkt for å finne de rette verktøyene for dine marine forvaltningsbehov",
    "Import Data": "Importer data",
    "Leverage Point Analysis": "Påvirkningspunktanalyse",
    "Load a previously saved project": "Last inn et tidligere lagret prosjekt",
    "Loop Detection": "Sløyfedeteksjon",
    "Navigate to ": "Naviger til ",
    "Navigating to %s...": "Navigerer til %s...",
    "Network Metrics": "Nettverksmålinger",
    "Overview of your project status and key metrics": "Oversikt over prosjektstatus og nøkkelparametre",
    "PIMS": "PIMS",
    "PIMS Module": "PIMS-modul",
    "Prepare Report": "Forbered rapport",
    "Project Setup": "Prosjektoppsett",
    "Quick Actions": "Hurtighandlinger",
    "Resources & Risks": "Ressurser og risikoer",
    "Response Measures": "Responstiltak",
    "Response & Validation": "Respons og validering",
    "Save your current project data, including all PIMS, ISA entries, and analysis results": "Lagre dine nåværende prosjektdata, inkludert alle PIMS, ISA-oppføringer og analyseresultater",
    "Scenario Builder": "Scenariobygger",
    "SES Visualization": "SES-visualisering",
    "Simplification": "Forenkling",
    "Stakeholders": "Interessenter",
    "Standard Entry": "Standard inngang",
    "Template-Based": "Malbasert",
    "Template based SES creation": "Malbasert SES-opprettelse",
    "Validation": "Validering",
    "Welcome": "Velkommen"
}

def update_merged_translations():
    """Update merged translations with sidebar Norwegian translations."""
    script_dir = Path(__file__).parent
    merged_file = script_dir.parent / 'translations' / '_merged_translations.json'

    if not merged_file.exists():
        print(f"Merged file not found: {merged_file}")
        return False

    print(f"Processing: {merged_file}")

    try:
        with open(merged_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if 'translation' not in data:
            print(f"  [ERROR] No translation array found")
            return False

        translated_count = 0
        for entry in data['translation']:
            if 'no' in entry and 'en' in entry:
                english_text = entry['en']
                # Check if we have a Norwegian translation for this English text
                if english_text in SIDEBAR_NORWEGIAN_TRANSLATIONS:
                    entry['no'] = SIDEBAR_NORWEGIAN_TRANSLATIONS[english_text]
                    translated_count += 1

        # Write back to file
        with open(merged_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"  [OK] Updated {translated_count} sidebar entries in merged file")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Updating merged translations with Norwegian sidebar translations")
    print("=" * 70)
    print()

    success = update_merged_translations()

    print()
    print("=" * 70)
    if success:
        print("Processing complete")
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
