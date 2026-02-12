#!/usr/bin/env python3
"""
Replace English baseline with proper Norwegian translations for common UI elements.
"""

import json
from pathlib import Path

# Norwegian translations for common UI elements
NORWEGIAN_TRANSLATIONS = {
    # Common buttons
    "Add": "Legg til",
    "add": "legg til",
    "Apply": "Bruk",
    "Back": "Tilbake",
    "Cancel": "Avbryt",
    "cancel": "avbryt",
    "Clear": "Tøm",
    "Close": "Lukk",
    "Confirm": "Bekreft",
    "Continue": "Fortsett",
    "create": "opprett",
    "Delete": "Slett",
    "delete": "slett",
    "Download": "Last ned",
    "Edit": "Rediger",
    "Export": "Eksporter",
    "Filter": "Filtrer",
    "Finish": "Fullfør",
    "Help": "Hjelp",
    "Import": "Importer",
    "Load": "Last inn",
    "Load Project": "Last inn prosjekt",
    "Next": "Neste",
    "No": "Nei",
    "Previous": "Forrige",
    "Refresh": "Oppdater",
    "Reject": "Avvis",
    "Remove": "Fjern",
    "Reset": "Tilbakestill",
    "Save": "Lagre",
    "Save Project": "Lagre prosjekt",
    "Search": "Søk",
    "Skip": "Hopp over",
    "Start": "Start",
    "Submit": "Send inn",
    "Update": "Oppdater",
    "Upload": "Last opp",
    "Yes": "Ja",

    # Common labels and navigation
    "Language": "Språk",
    "Settings": "Innstillinger",
    "About": "Om",
    "App Info": "App-informasjon",
    "Bookmark": "Bokmerke",
    "Change Language": "Bytt språk",
    "User": "Bruker",
    "User Account": "Brukerkonto",
    "User Profile": "Brukerprofil",
    "User Guide": "Brukerveiledning",
    "User Experience Level": "Brukeropplevelsesnivå",
    "Help": "Hjelp",
    "Dashboard": "Dashbord",
    "Home": "Hjem",
    "Project": "Prosjekt",
    "Project Info": "Prosjektinformasjon",
    "Project Setup": "Prosjektoppsett",
    "Project Overview": "Prosjektoversikt",
    "New Project": "Nytt prosjekt",
    "Open User Guide": "Åpne brukerveiledning",
    "Application Settings": "Programinnstillinger",
    "Download Manuals": "Last ned brukermanualer",
    "Step-by-Step Tutorial": "Trinn-for-trinn veiledning",
    "Quick Reference": "Hurtigreferanse",

    # Common messages
    "Loading...": "Laster...",
    "Please wait...": "Vennligst vent...",
    "Error": "Feil",
    "Warning": "Advarsel",
    "Success": "Suksess",
    "Information": "Informasjon",
    "Note": "Merk",
    "Required": "Påkrevd",
    "Optional": "Valgfritt",
    "Name": "Navn",
    "Description": "Beskrivelse",
    "Type": "Type",
    "Status": "Status",
    "Date": "Dato",
    "Time": "Tid",
    "Created": "Opprettet",
    "Modified": "Endret",
    "Author": "Forfatter",
    "Version": "Versjon",

    # Data entry
    "Enter": "Skriv inn",
    "Select": "Velg",
    "Choose": "Velg",
    "Input": "Inndata",
    "Output": "Utdata",

    # Actions
    "Copy": "Kopier",
    "Paste": "Lim inn",
    "Cut": "Klipp ut",
    "Undo": "Angre",
    "Redo": "Gjør om",
    "Print": "Skriv ut",

    # Modal/Dialog
    "OK": "OK",
    "Dismiss": "Avvis",
    "More": "Mer",
    "Less": "Mindre",
    "Show": "Vis",
    "Hide": "Skjul",

    # File operations
    "File": "Fil",
    "Folder": "Mappe",
    "Path": "Sti",
    "Size": "Størrelse",

    # Common phrases
    "Changing Language": "Endrer språk",
    "Save current state as bookmark": "Lagre nåværende tilstand som bokmerke",
    "Recommended for New Users": "Anbefalt for nye brukere",
    "Complete User Manuals": "Fullstendige brukermanualer",
    "Download User Manuals & Guides": "Last ned brukermanualer og guider",
}

def translate_file(filepath):
    """Translate Norwegian entries in a JSON file."""
    print(f"Processing: {filepath}")

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if 'translation' not in data:
            print(f"  [SKIP] No translation array found\n")
            return False

        translated_count = 0
        for entry in data['translation']:
            if 'no' in entry and 'en' in entry:
                english_text = entry['en']
                # Check if we have a translation for this English text
                if english_text in NORWEGIAN_TRANSLATIONS:
                    # Only update if it's currently the same as English
                    if entry['no'] == english_text:
                        entry['no'] = NORWEGIAN_TRANSLATIONS[english_text]
                        translated_count += 1

        if translated_count > 0:
            # Write back to file
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"  [OK] Translated {translated_count} entries\n")
            return True
        else:
            print(f"  [SKIP] No translations applied\n")
            return False

    except Exception as e:
        print(f"  [ERROR] {e}\n")
        return False

def main():
    """Process all translation JSON files."""
    script_dir = Path(__file__).parent
    translations_dir = script_dir.parent / 'translations'

    print("=" * 70)
    print("Applying proper Norwegian translations to common UI elements")
    print("=" * 70)
    print()

    # Find all JSON files in subdirectories
    json_files = []
    for subdir in ['common', 'ui', 'data', 'modules']:
        subdir_path = translations_dir / subdir
        if subdir_path.exists():
            json_files.extend(subdir_path.glob('*.json'))

    # Also process merged file
    merged_file = translations_dir / '_merged_translations.json'
    if merged_file.exists():
        json_files.append(merged_file)

    # Filter out backup files
    json_files = [f for f in json_files if 'backup' not in str(f).lower()]

    if not json_files:
        print("No JSON files found to process.")
        return

    print(f"Found {len(json_files)} JSON files to process.\n")

    success_count = 0
    for json_file in sorted(json_files):
        if translate_file(json_file):
            success_count += 1

    print("=" * 70)
    print(f"Processing complete: {success_count} files updated with Norwegian translations")
    print(f"Total translation mappings available: {len(NORWEGIAN_TRANSLATIONS)}")
    print("=" * 70)

if __name__ == "__main__":
    main()
