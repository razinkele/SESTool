#!/usr/bin/env python3
"""
Add missing i18n translations for Analysis Tools module.
Adds user-facing strings that are currently hardcoded in English.
"""

import json

# Translations for Analysis Tools module
translations_to_add = {
    # Status messages
    "analysis_detecting_loops": {
        "en": "Detecting loops...",
        "es": "Detectando bucles...",
        "fr": "Détection des boucles...",
        "de": "Schleifen werden erkannt...",
        "lt": "Aptinkamos kilpos...",
        "pt": "Detectando loops...",
        "it": "Rilevamento loop..."
    },
    "analysis_no_graph_data": {
        "en": "Error: No graph data available. Please complete ISA data entry first.",
        "es": "Error: No hay datos de gráfico disponibles. Complete primero la entrada de datos ISA.",
        "fr": "Erreur : Aucune donnée de graphique disponible. Veuillez d'abord compléter la saisie de données ISA.",
        "de": "Fehler: Keine Grafikdaten verfügbar. Bitte vervollständigen Sie zuerst die ISA-Dateneingabe.",
        "lt": "Klaida: grafiko duomenų nėra. Pirmiausia užpildykite ISA duomenų įvedimą.",
        "pt": "Erro: Não há dados de gráfico disponíveis. Complete primeiro a entrada de dados ISA.",
        "it": "Errore: Nessun dato grafico disponibile. Completare prima l'inserimento dati ISA."
    },
    "analysis_no_isa_data": {
        "en": "No ISA data found. Complete exercises first.",
        "es": "No se encontraron datos ISA. Complete primero los ejercicios.",
        "fr": "Aucune donnée ISA trouvée. Complétez d'abord les exercices.",
        "de": "Keine ISA-Daten gefunden. Übungen zuerst abschließen.",
        "lt": "ISA duomenų nerasta. Pirmiausia užbaikite pratimus.",
        "pt": "Não foram encontrados dados ISA. Complete primeiro os exercícios.",
        "it": "Nessun dato ISA trovato. Completare prima gli esercizi."
    },
    "analysis_no_loops_detected": {
        "en": "No loops detected. Try closing more feedback connections in Exercise 6.",
        "es": "No se detectaron bucles. Intente cerrar más conexiones de retroalimentación en el Ejercicio 6.",
        "fr": "Aucune boucle détectée. Essayez de fermer plus de connexions de rétroaction dans l'exercice 6.",
        "de": "Keine Schleifen erkannt. Versuchen Sie, mehr Feedback-Verbindungen in Übung 6 zu schließen.",
        "lt": "Kilpų neaptikta. Pabandykite užverti daugiau grįžtamojo ryšio jungčių 6 užduotyje.",
        "pt": "Nenhum loop detectado. Tente fechar mais conexões de feedback no Exercício 6.",
        "it": "Nessun loop rilevato. Prova a chiudere più connessioni di feedback nell'Esercizio 6."
    },
    "analysis_no_loops_found": {
        "en": "No loops found. Add loop connections in Exercise 6.",
        "es": "No se encontraron bucles. Agregue conexiones de bucle en el Ejercicio 6.",
        "fr": "Aucune boucle trouvée. Ajoutez des connexions de boucle dans l'exercice 6.",
        "de": "Keine Schleifen gefunden. Schleifenverbindungen in Übung 6 hinzufügen.",
        "lt": "Kilpų nerasta. Pridėkite kilpų jungtis 6 užduotyje.",
        "pt": "Nenhum loop encontrado. Adicione conexões de loop no Exercício 6.",
        "it": "Nessun loop trovato. Aggiungi connessioni loop nell'Esercizio 6."
    },
    "analysis_found": {
        "en": "Found",
        "es": "Se encontraron",
        "fr": "Trouvé",
        "de": "Gefunden",
        "lt": "Rasta",
        "pt": "Encontrado",
        "it": "Trovato"
    },
    "analysis_feedback_loops": {
        "en": "feedback loops!",
        "es": "bucles de retroalimentación!",
        "fr": "boucles de rétroaction !",
        "de": "Feedback-Schleifen!",
        "lt": "grįžtamojo ryšio kilpos!",
        "pt": "loops de feedback!",
        "it": "loop di feedback!"
    },

    # Data management messages
    "analysis_data_added": {
        "en": "Data point added successfully!",
        "es": "¡Punto de datos agregado exitosamente!",
        "fr": "Point de données ajouté avec succès !",
        "de": "Datenpunkt erfolgreich hinzugefügt!",
        "lt": "Duomenų taškas sėkmingai pridėtas!",
        "pt": "Ponto de dados adicionado com sucesso!",
        "it": "Punto dati aggiunto con successo!"
    },
    "analysis_csv_loaded": {
        "en": "CSV data loaded successfully!",
        "es": "¡Datos CSV cargados exitosamente!",
        "fr": "Données CSV chargées avec succès !",
        "de": "CSV-Daten erfolgreich geladen!",
        "lt": "CSV duomenys sėkmingai įkelti!",
        "pt": "Dados CSV carregados com sucesso!",
        "it": "Dati CSV caricati con successo!"
    },
    "analysis_csv_columns_error": {
        "en": "CSV must have 'Year' and 'Value' columns!",
        "es": "¡El CSV debe tener columnas 'Year' y 'Value'!",
        "fr": "Le CSV doit avoir des colonnes 'Year' et 'Value' !",
        "de": "CSV muss 'Year'- und 'Value'-Spalten haben!",
        "lt": "CSV turi turėti 'Year' ir 'Value' stulpelius!",
        "pt": "O CSV deve ter colunas 'Year' e 'Value'!",
        "it": "Il CSV deve avere colonne 'Year' e 'Value'!"
    },
    "analysis_error_loading_csv": {
        "en": "Error loading CSV:",
        "es": "Error al cargar CSV:",
        "fr": "Erreur de chargement du CSV :",
        "de": "Fehler beim Laden von CSV:",
        "lt": "Klaida įkeliant CSV:",
        "pt": "Erro ao carregar CSV:",
        "it": "Errore nel caricamento del CSV:"
    },
    "analysis_data_cleared": {
        "en": "All data cleared",
        "es": "Todos los datos eliminados",
        "fr": "Toutes les données effacées",
        "de": "Alle Daten gelöscht",
        "lt": "Visi duomenys išvalyti",
        "pt": "Todos os dados apagados",
        "it": "Tutti i dati cancellati"
    },

    # Loop classification
    "analysis_reinforcing": {
        "en": "Reinforcing",
        "es": "Refuerzo",
        "fr": "Renforçant",
        "de": "Verstärkend",
        "lt": "Stiprinantis",
        "pt": "Reforço",
        "it": "Rafforzante"
    },
    "analysis_balancing": {
        "en": "Balancing",
        "es": "Equilibrio",
        "fr": "Équilibrant",
        "de": "Ausgleichend",
        "lt": "Balansuojantis",
        "pt": "Equilíbrio",
        "it": "Bilanciante"
    },
    "analysis_loop_with": {
        "en": "loop with",
        "es": "bucle con",
        "fr": "boucle avec",
        "de": "Schleife mit",
        "lt": "kilpa su",
        "pt": "loop com",
        "it": "loop con"
    },
    "analysis_elements": {
        "en": "elements",
        "es": "elementos",
        "fr": "éléments",
        "de": "Elemente",
        "lt": "elementai",
        "pt": "elementos",
        "it": "elementi"
    },

    # Column names for loop data table
    "analysis_col_loopid": {
        "en": "Loop ID",
        "es": "ID de Bucle",
        "fr": "ID de Boucle",
        "de": "Schleifen-ID",
        "lt": "Kilpos ID",
        "pt": "ID do Loop",
        "it": "ID Loop"
    },
    "analysis_col_length": {
        "en": "Length",
        "es": "Longitud",
        "fr": "Longueur",
        "de": "Länge",
        "lt": "Ilgis",
        "pt": "Comprimento",
        "it": "Lunghezza"
    },
    "analysis_col_elements": {
        "en": "Elements",
        "es": "Elementos",
        "fr": "Éléments",
        "de": "Elemente",
        "lt": "Elementai",
        "pt": "Elementos",
        "it": "Elementi"
    },
    "analysis_col_type": {
        "en": "Type",
        "es": "Tipo",
        "fr": "Type",
        "de": "Typ",
        "lt": "Tipas",
        "pt": "Tipo",
        "it": "Tipo"
    },
    "analysis_col_polarity": {
        "en": "Polarity",
        "es": "Polaridad",
        "fr": "Polarité",
        "de": "Polarität",
        "lt": "Polaritetas",
        "pt": "Polaridade",
        "it": "Polarità"
    },
    "analysis_col_description": {
        "en": "Description",
        "es": "Descripción",
        "fr": "Description",
        "de": "Beschreibung",
        "lt": "Aprašymas",
        "pt": "Descrição",
        "it": "Descrizione"
    }
}

def load_translations(filepath):
    """Load existing translations from JSON file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_translations(translations, filepath):
    """Save translations to JSON file."""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(translations, f, ensure_ascii=False, indent=2)

def add_translations(translations, new_translations):
    """Add new translations to existing ones."""
    for key, langs in new_translations.items():
        if key in translations:
            print(f"WARNING: Key '{key}' already exists - skipping")
            continue

        # Add the new key with all language translations
        translations[key] = langs
        print(f"+ Added '{key}'")

    return translations

def main():
    filepath = 'translations/translation.json'

    print("Loading existing translations...")
    translations = load_translations(filepath)

    print(f"\nCurrent translation count: {len(translations)} keys\n")

    print("Adding analysis module translations...")
    translations = add_translations(translations, translations_to_add)

    print("\nSaving updated translations...")
    save_translations(translations, filepath)

    print(f"\n[OK] Complete! New translation count: {len(translations)} keys")
    print(f"   Added {len(translations_to_add)} new translation keys")
    print(f"   Total translations: {len(translations)} keys x 7 languages = {len(translations) * 7} entries")

if __name__ == '__main__':
    main()
