#!/usr/bin/env python3
"""
Add Dashboard module translations to translation.json
"""

import json
from pathlib import Path

# Dashboard translations dictionary
DASHBOARD_TRANSLATIONS = {
    "Welcome to the computer-assisted SES creation and analysis platform.": {
        "es": "Bienvenido a la plataforma de creación y análisis de SES asistida por computadora.",
        "fr": "Bienvenue sur la plateforme de création et d'analyse SES assistée par ordinateur.",
        "de": "Willkommen zur computergestützten SES-Erstellungs- und Analyseplattform.",
        "lt": "Sveiki atvykę į kompiuterio pagalbą naudojančią SES kūrimo ir analizės platformą.",
        "pt": "Bem-vindo à plataforma de criação e análise de SES assistida por computador.",
        "it": "Benvenuto nella piattaforma di creazione e analisi SES assistita da computer."
    },
    "Project Overview": {
        "es": "Resumen del Proyecto",
        "fr": "Aperçu du Projet",
        "de": "Projektübersicht",
        "lt": "Projekto apžvalga",
        "pt": "Visão Geral do Projeto",
        "it": "Panoramica del Progetto"
    },
    "Recent Activities": {
        "es": "Actividades Recientes",
        "fr": "Activités Récentes",
        "de": "Letzte Aktivitäten",
        "lt": "Naujausia veikla",
        "pt": "Atividades Recentes",
        "it": "Attività Recenti"
    },
    "Connections": {
        "es": "Conexiones",
        "fr": "Connexions",
        "de": "Verbindungen",
        "lt": "Ryšiai",
        "pt": "Conexões",
        "it": "Connessioni"
    },
    "Completion": {
        "es": "Finalización",
        "fr": "Achèvement",
        "de": "Fertigstellung",
        "lt": "Užbaigimas",
        "pt": "Conclusão",
        "it": "Completamento"
    },
    "Project ID:": {
        "es": "ID del Proyecto:",
        "fr": "ID du Projet :",
        "de": "Projekt-ID:",
        "lt": "Projekto ID:",
        "pt": "ID do Projeto:",
        "it": "ID Progetto:"
    },
    "Created:": {
        "es": "Creado:",
        "fr": "Créé :",
        "de": "Erstellt:",
        "lt": "Sukurta:",
        "pt": "Criado:",
        "it": "Creato:"
    },
    "Last Modified:": {
        "es": "Última Modificación:",
        "fr": "Dernière Modification :",
        "de": "Zuletzt Geändert:",
        "lt": "Paskutinį kartą keista:",
        "pt": "Última Modificação:",
        "it": "Ultima Modifica:"
    },
    "Demonstration Area:": {
        "es": "Área de Demostración:",
        "fr": "Zone de Démonstration :",
        "de": "Demonstrationsbereich:",
        "lt": "Demonstracinė sritis:",
        "pt": "Área de Demonstração:",
        "it": "Area di Dimostrazione:"
    },
    "Not set": {
        "es": "No establecido",
        "fr": "Non défini",
        "de": "Nicht festgelegt",
        "lt": "Nenustatyta",
        "pt": "Não definido",
        "it": "Non impostato"
    },
    "Focal Issue:": {
        "es": "Asunto Focal:",
        "fr": "Question Centrale :",
        "de": "Kernthema:",
        "lt": "Pagrindinė problema:",
        "pt": "Questão Focal:",
        "it": "Questione Focale:"
    },
    "Not defined": {
        "es": "No definido",
        "fr": "Non défini",
        "de": "Nicht definiert",
        "lt": "Neapibrėžta",
        "pt": "Não definido",
        "it": "Non definito"
    },
    "Status Summary": {
        "es": "Resumen del Estado",
        "fr": "Résumé du Statut",
        "de": "Statusübersicht",
        "lt": "Būklės santrauka",
        "pt": "Resumo do Status",
        "it": "Riepilogo dello Stato"
    },
    "PIMS Setup:": {
        "es": "Configuración PIMS:",
        "fr": "Configuration PIMS :",
        "de": "PIMS-Konfiguration:",
        "lt": "PIMS sąranka:",
        "pt": "Configuração PIMS:",
        "it": "Configurazione PIMS:"
    },
    "Complete": {
        "es": "Completo",
        "fr": "Complet",
        "de": "Vollständig",
        "lt": "Baigta",
        "pt": "Completo",
        "it": "Completo"
    },
    "Incomplete": {
        "es": "Incompleto",
        "fr": "Incomplet",
        "de": "Unvollständig",
        "lt": "Nebaigta",
        "pt": "Incompleto",
        "it": "Incompleto"
    },
    "ISA Data Entry:": {
        "es": "Entrada de Datos ISA:",
        "fr": "Saisie de Données ISA :",
        "de": "ISA-Dateneingabe:",
        "lt": "ISA duomenų įvedimas:",
        "pt": "Entrada de Dados ISA:",
        "it": "Inserimento Dati ISA:"
    },
    "entries": {
        "es": "entradas",
        "fr": "entrées",
        "de": "Einträge",
        "lt": "įrašai",
        "pt": "entradas",
        "it": "voci"
    },
    "CLD Generated:": {
        "es": "DBC Generado:",
        "fr": "DBC Généré :",
        "de": "ULS Generiert:",
        "lt": "PKD sukurtas:",
        "pt": "DLC Gerado:",
        "it": "DCC Generato:"
    },
    "Yes": {
        "es": "Sí",
        "fr": "Oui",
        "de": "Ja",
        "lt": "Taip",
        "pt": "Sim",
        "it": "Sì"
    },
    "No": {
        "es": "No",
        "fr": "Non",
        "de": "Nein",
        "lt": "Ne",
        "pt": "Não",
        "it": "No"
    },
    "Export & Reports": {
        "es": "Exportar e Informes",
        "fr": "Exportation et Rapports",
        "de": "Export und Berichte",
        "lt": "Eksportas ir ataskaitos",
        "pt": "Exportação e Relatórios",
        "it": "Esportazione e Report"
    },
    "Export your data, visualizations, and generate comprehensive reports.": {
        "es": "Exporte sus datos, visualizaciones y genere informes completos.",
        "fr": "Exportez vos données, visualisations et générez des rapports complets.",
        "de": "Exportieren Sie Ihre Daten, Visualisierungen und erstellen Sie umfassende Berichte.",
        "lt": "Eksportuokite duomenis, vizualizacijas ir generuokite išsamias ataskaitas.",
        "pt": "Exporte seus dados, visualizações e gere relatórios completos.",
        "it": "Esporta i tuoi dati, visualizzazioni e genera report completi."
    }
}

# Load existing translations
trans_path = Path("translations/translation.json")
with open(trans_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Get existing English keys
existing_keys = {entry['en'] for entry in data['translation']}

# Add new translations
added_count = 0
for eng_text, translations in DASHBOARD_TRANSLATIONS.items():
    if eng_text not in existing_keys:
        entry = {
            "en": eng_text,
            "es": translations["es"],
            "fr": translations["fr"],
            "de": translations["de"],
            "lt": translations["lt"],
            "pt": translations["pt"],
            "it": translations["it"]
        }
        data['translation'].append(entry)
        added_count += 1
        print(f"[ADDED] {eng_text}")
    else:
        print(f"[EXISTS] {eng_text}")

# Save updated translations
with open(trans_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n{'='*60}")
print(f"Dashboard Translation Summary:")
print(f"  New translations added: {added_count}")
print(f"  Already existed: {len(DASHBOARD_TRANSLATIONS) - added_count}")
print(f"  Total Dashboard strings: {len(DASHBOARD_TRANSLATIONS)}")
print(f"{'='*60}")
print(f"\nUpdated translation.json successfully!")
