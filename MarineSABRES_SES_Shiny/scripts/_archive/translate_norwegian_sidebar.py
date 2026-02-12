#!/usr/bin/env python3
"""
Add proper Norwegian translations for sidebar menu items.
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

def translate_sidebar():
    """Translate sidebar Norwegian entries."""
    script_dir = Path(__file__).parent
    sidebar_file = script_dir.parent / 'translations' / 'ui' / 'sidebar.json'

    if not sidebar_file.exists():
        print(f"Sidebar file not found: {sidebar_file}")
        return False

    print(f"Processing: {sidebar_file}")

    try:
        with open(sidebar_file, 'r', encoding='utf-8') as f:
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
                    print(f"  [OK] '{english_text}' -> '{entry['no']}'")

        # Write back to file
        with open(sidebar_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\n  [COMPLETE] Translated {translated_count} sidebar entries")
        return True

    except Exception as e:
        print(f"  [ERROR] {e}")
        return False

def main():
    print("=" * 70)
    print("Adding Norwegian translations for sidebar menu items")
    print("=" * 70)
    print()

    success = translate_sidebar()

    print()
    print("=" * 70)
    if success:
        print(f"Processing complete: {len(SIDEBAR_NORWEGIAN_TRANSLATIONS)} sidebar translations added")
    else:
        print("Processing failed")
    print("=" * 70)

if __name__ == "__main__":
    main()
