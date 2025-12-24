#!/usr/bin/env python3
"""
Script to add Export tab translation entries to translation.json
"""

import json

# New translations for Export tab
export_translations = [
    {
        "en": "Export Data",
        "es": "Exportar Datos",
        "fr": "Exporter les Données",
        "de": "Daten Exportieren",
        "lt": "Eksportuoti duomenis",
        "pt": "Exportar Dados",
        "it": "Esporta Dati"
    },
    {
        "en": "Select Format:",
        "es": "Seleccionar Formato:",
        "fr": "Sélectionner le Format:",
        "de": "Format Auswählen:",
        "lt": "Pasirinkite formatą:",
        "pt": "Selecionar Formato:",
        "it": "Seleziona Formato:"
    },
    {
        "en": "Select Components:",
        "es": "Seleccionar Componentes:",
        "fr": "Sélectionner les Composants:",
        "de": "Komponenten Auswählen:",
        "lt": "Pasirinkite komponentus:",
        "pt": "Selecionar Componentes:",
        "it": "Seleziona Componenti:"
    },
    {
        "en": "Project Metadata",
        "es": "Metadatos del Proyecto",
        "fr": "Métadonnées du Projet",
        "de": "Projektmetadaten",
        "lt": "Projekto metaduomenys",
        "pt": "Metadados do Projeto",
        "it": "Metadati del Progetto"
    },
    {
        "en": "PIMS Data",
        "es": "Datos PIMS",
        "fr": "Données PIMS",
        "de": "PIMS-Daten",
        "lt": "PIMS duomenys",
        "pt": "Dados PIMS",
        "it": "Dati PIMS"
    },
    {
        "en": "ISA Data",
        "es": "Datos ISA",
        "fr": "Données ISA",
        "de": "ISA-Daten",
        "lt": "ISA duomenys",
        "pt": "Dados ISA",
        "it": "Dati ISA"
    },
    {
        "en": "CLD Data",
        "es": "Datos CLD",
        "fr": "Données CLD",
        "de": "CLD-Daten",
        "lt": "CLD duomenys",
        "pt": "Dados CLD",
        "it": "Dati CLD"
    },
    {
        "en": "Analysis Results",
        "es": "Resultados del Análisis",
        "fr": "Résultats de l'Analyse",
        "de": "Analyseergebnisse",
        "lt": "Analizės rezultatai",
        "pt": "Resultados da Análise",
        "it": "Risultati dell'Analisi"
    },
    {
        "en": "Response Measures",
        "es": "Medidas de Respuesta",
        "fr": "Mesures de Réponse",
        "de": "Reaktionsmaßnahmen",
        "lt": "Atsakomosios priemonės",
        "pt": "Medidas de Resposta",
        "it": "Misure di Risposta"
    },
    {
        "en": "Download Data",
        "es": "Descargar Datos",
        "fr": "Télécharger les Données",
        "de": "Daten Herunterladen",
        "lt": "Atsisiųsti duomenis",
        "pt": "Descarregar Dados",
        "it": "Scarica Dati"
    },
    {
        "en": "Export Visualizations",
        "es": "Exportar Visualizaciones",
        "fr": "Exporter les Visualisations",
        "de": "Visualisierungen Exportieren",
        "lt": "Eksportuoti vizualizacijas",
        "pt": "Exportar Visualizações",
        "it": "Esporta Visualizzazioni"
    },
    {
        "en": "Width (pixels):",
        "es": "Ancho (píxeles):",
        "fr": "Largeur (pixels):",
        "de": "Breite (Pixel):",
        "lt": "Plotis (pikseliai):",
        "pt": "Largura (pixels):",
        "it": "Larghezza (pixel):"
    },
    {
        "en": "Height (pixels):",
        "es": "Alto (píxeles):",
        "fr": "Hauteur (pixels):",
        "de": "Höhe (Pixel):",
        "lt": "Aukštis (pikseliai):",
        "pt": "Altura (pixels):",
        "it": "Altezza (pixel):"
    },
    {
        "en": "Download Visualization",
        "es": "Descargar Visualización",
        "fr": "Télécharger la Visualisation",
        "de": "Visualisierung Herunterladen",
        "lt": "Atsisiųsti vizualizaciją",
        "pt": "Descarregar Visualização",
        "it": "Scarica Visualizzazione"
    },
    {
        "en": "Generate Report",
        "es": "Generar Informe",
        "fr": "Générer le Rapport",
        "de": "Bericht Erstellen",
        "lt": "Generuoti ataskaitą",
        "pt": "Gerar Relatório",
        "it": "Genera Rapporto"
    },
    {
        "en": "Report Type:",
        "es": "Tipo de Informe:",
        "fr": "Type de Rapport:",
        "de": "Berichtstyp:",
        "lt": "Ataskaitos tipas:",
        "pt": "Tipo de Relatório:",
        "it": "Tipo di Rapporto:"
    },
    {
        "en": "Executive Summary",
        "es": "Resumen Ejecutivo",
        "fr": "Résumé Exécutif",
        "de": "Zusammenfassung",
        "lt": "Vykdomoji santrauka",
        "pt": "Resumo Executivo",
        "it": "Riepilogo Esecutivo"
    },
    {
        "en": "Technical Report",
        "es": "Informe Técnico",
        "fr": "Rapport Technique",
        "de": "Technischer Bericht",
        "lt": "Techninis pranešimas",
        "pt": "Relatório Técnico",
        "it": "Rapporto Tecnico"
    },
    {
        "en": "Stakeholder Presentation",
        "es": "Presentación para Partes Interesadas",
        "fr": "Présentation aux Parties Prenantes",
        "de": "Stakeholder-Präsentation",
        "lt": "Suinteresuotų šalių pristatymas",
        "pt": "Apresentação às Partes Interessadas",
        "it": "Presentazione per gli Stakeholder"
    },
    {
        "en": "Full Project Report",
        "es": "Informe Completo del Proyecto",
        "fr": "Rapport de Projet Complet",
        "de": "Vollständiger Projektbericht",
        "lt": "Išsamus projekto ataskaita",
        "pt": "Relatório Completo do Projeto",
        "it": "Rapporto di Progetto Completo"
    },
    {
        "en": "Report Format:",
        "es": "Formato del Informe:",
        "fr": "Format du Rapport:",
        "de": "Berichtsformat:",
        "lt": "Ataskaitos formatas:",
        "pt": "Formato do Relatório:",
        "it": "Formato del Rapporto:"
    },
    {
        "en": "Include Visualizations",
        "es": "Incluir Visualizaciones",
        "fr": "Inclure les Visualisations",
        "de": "Visualisierungen Einbeziehen",
        "lt": "Įtraukti vizualizacijas",
        "pt": "Incluir Visualizações",
        "it": "Includi Visualizzazioni"
    },
    {
        "en": "Include Data Tables",
        "es": "Incluir Tablas de Datos",
        "fr": "Inclure les Tableaux de Données",
        "de": "Datentabellen Einbeziehen",
        "lt": "Įtraukti duomenų lenteles",
        "pt": "Incluir Tabelas de Dados",
        "it": "Includi Tabelle di Dati"
    }
]

def main():
    # Read the existing translation file
    with open('translations/translation.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Current number of translations: {len(data['translation'])}")

    # Add new export translations
    for new_entry in export_translations:
        # Check if this translation already exists
        en_text = new_entry['en']
        exists = any(entry.get('en') == en_text for entry in data['translation'])

        if not exists:
            data['translation'].append(new_entry)
            print(f"Added: {en_text}")
        else:
            print(f"Skipped (exists): {en_text}")

    print(f"New number of translations: {len(data['translation'])}")

    # Write back to file with proper formatting
    with open('translations/translation.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("Export translations added successfully!")

if __name__ == '__main__':
    main()
