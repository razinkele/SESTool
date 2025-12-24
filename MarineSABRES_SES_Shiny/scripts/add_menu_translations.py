#!/usr/bin/env python3
"""
Script to add sidebar menu and dashboard translation entries to translation.json
"""

import json

# New translations for sidebar menu, dashboard, and modules
menu_translations = [
    # Sidebar Menu Items
    {
        "en": "Getting Started",
        "es": "Comenzar",
        "fr": "Commencer",
        "de": "Erste Schritte",
        "lt": "Pradėti",
        "pt": "Começar",
        "it": "Iniziare"
    },
    {
        "en": "Dashboard",
        "es": "Panel de Control",
        "fr": "Tableau de Bord",
        "de": "Dashboard",
        "lt": "Prietaisų skydelis",
        "pt": "Painel de Controlo",
        "it": "Pannello di Controllo"
    },
    {
        "en": "PIMS Module",
        "es": "Módulo PIMS",
        "fr": "Module PIMS",
        "de": "PIMS-Modul",
        "lt": "PIMS modulis",
        "pt": "Módulo PIMS",
        "it": "Modulo PIMS"
    },
    {
        "en": "Project Setup",
        "es": "Configuración del Proyecto",
        "fr": "Configuration du Projet",
        "de": "Projekteinrichtung",
        "lt": "Projekto sąranka",
        "pt": "Configuração do Projeto",
        "it": "Configurazione Progetto"
    },
    {
        "en": "Stakeholders",
        "es": "Partes Interesadas",
        "fr": "Parties Prenantes",
        "de": "Stakeholder",
        "lt": "Suinteresuotos šalys",
        "pt": "Partes Interessadas",
        "it": "Stakeholder"
    },
    {
        "en": "Resources & Risks",
        "es": "Recursos y Riesgos",
        "fr": "Ressources et Risques",
        "de": "Ressourcen & Risiken",
        "lt": "Ištekliai ir rizikos",
        "pt": "Recursos e Riscos",
        "it": "Risorse e Rischi"
    },
    {
        "en": "Data Management",
        "es": "Gestión de Datos",
        "fr": "Gestion des Données",
        "de": "Datenverwaltung",
        "lt": "Duomenų valdymas",
        "pt": "Gestão de Dados",
        "it": "Gestione Dati"
    },
    {
        "en": "Evaluation",
        "es": "Evaluación",
        "fr": "Évaluation",
        "de": "Bewertung",
        "lt": "Vertinimas",
        "pt": "Avaliação",
        "it": "Valutazione"
    },
    {
        "en": "AI ISA Assistant",
        "es": "Asistente ISA con IA",
        "fr": "Assistant ISA IA",
        "de": "KI ISA-Assistent",
        "lt": "AI ISA asistentas",
        "pt": "Assistente ISA com IA",
        "it": "Assistente ISA AI"
    },
    {
        "en": "ISA Data Entry",
        "es": "Entrada de Datos ISA",
        "fr": "Saisie de Données ISA",
        "de": "ISA-Dateneingabe",
        "lt": "ISA duomenų įvedimas",
        "pt": "Entrada de Dados ISA",
        "it": "Inserimento Dati ISA"
    },
    {
        "en": "CLD Visualization",
        "es": "Visualización CLD",
        "fr": "Visualisation CLD",
        "de": "CLD-Visualisierung",
        "lt": "CLD vizualizacija",
        "pt": "Visualização CLD",
        "it": "Visualizzazione CLD"
    },
    {
        "en": "Analysis Tools",
        "es": "Herramientas de Análisis",
        "fr": "Outils d'Analyse",
        "de": "Analysewerkzeuge",
        "lt": "Analizės įrankiai",
        "pt": "Ferramentas de Análise",
        "it": "Strumenti di Analisi"
    },
    {
        "en": "Network Metrics",
        "es": "Métricas de Red",
        "fr": "Métriques de Réseau",
        "de": "Netzwerkmetriken",
        "lt": "Tinklo metrikos",
        "pt": "Métricas de Rede",
        "it": "Metriche di Rete"
    },
    {
        "en": "Loop Detection",
        "es": "Detección de Bucles",
        "fr": "Détection de Boucles",
        "de": "Schleifenerkennung",
        "lt": "Ciklų aptikimas",
        "pt": "Deteção de Ciclos",
        "it": "Rilevamento Cicli"
    },
    {
        "en": "BOT Analysis",
        "es": "Análisis BOT",
        "fr": "Analyse BOT",
        "de": "BOT-Analyse",
        "lt": "BOT analizė",
        "pt": "Análise BOT",
        "it": "Analisi BOT"
    },
    {
        "en": "Simplification",
        "es": "Simplificación",
        "fr": "Simplification",
        "de": "Vereinfachung",
        "lt": "Supaprastinimas",
        "pt": "Simplificação",
        "it": "Semplificazione"
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
        "en": "Scenario Builder",
        "es": "Constructor de Escenarios",
        "fr": "Créateur de Scénarios",
        "de": "Szenario-Builder",
        "lt": "Scenarijų kūrimas",
        "pt": "Construtor de Cenários",
        "it": "Costruttore Scenari"
    },
    {
        "en": "Validation",
        "es": "Validación",
        "fr": "Validation",
        "de": "Validierung",
        "lt": "Patvirtinimas",
        "pt": "Validação",
        "it": "Validazione"
    },
    # Dashboard specific
    {
        "en": "MarineSABRES Social-Ecological Systems Analysis Tool",
        "es": "Herramienta de Análisis de Sistemas Socio-Ecológicos MarineSABRES",
        "fr": "Outil d'Analyse des Systèmes Socio-Écologiques MarineSABRES",
        "de": "MarineSABRES Sozial-Ökologisches System-Analysewerkzeug",
        "lt": "MarineSABRES socialinių-ekologinių sistemų analizės įrankis",
        "pt": "Ferramenta de Análise de Sistemas Sócio-Ecológicos MarineSABRES",
        "it": "Strumento di Analisi dei Sistemi Socio-Ecologici MarineSABRES"
    },
    {
        "en": "Total Elements",
        "es": "Elementos Totales",
        "fr": "Éléments Totaux",
        "de": "Gesamtelemente",
        "lt": "Viso elementų",
        "pt": "Total de Elementos",
        "it": "Elementi Totali"
    },
    {
        "en": "Total Connections",
        "es": "Conexiones Totales",
        "fr": "Connexions Totales",
        "de": "Gesamtverbindungen",
        "lt": "Viso ryšių",
        "pt": "Total de Conexões",
        "it": "Connessioni Totali"
    },
    {
        "en": "Loops Detected",
        "es": "Bucles Detectados",
        "fr": "Boucles Détectées",
        "de": "Schleifen Erkannt",
        "lt": "Aptikta ciklų",
        "pt": "Ciclos Detetados",
        "it": "Cicli Rilevati"
    },
    {
        "en": "CLD Preview",
        "es": "Vista Previa CLD",
        "fr": "Aperçu CLD",
        "de": "CLD-Vorschau",
        "lt": "CLD peržiūra",
        "pt": "Pré-visualização CLD",
        "it": "Anteprima CLD"
    },
    {
        "en": "No CLD Generated Yet",
        "es": "Aún no se ha Generado CLD",
        "fr": "Aucun CLD Généré Encore",
        "de": "Noch kein CLD Generiert",
        "lt": "CLD dar nesukurtas",
        "pt": "Nenhum CLD Gerado Ainda",
        "it": "Nessun CLD Generato Ancora"
    },
    {
        "en": "Build your Causal Loop Diagram from the ISA data to visualize system connections.",
        "es": "Construya su Diagrama de Bucles Causales a partir de los datos ISA para visualizar las conexiones del sistema.",
        "fr": "Construisez votre Diagramme de Boucles Causales à partir des données ISA pour visualiser les connexions du système.",
        "de": "Erstellen Sie Ihr Kausalschleifen-Diagramm aus den ISA-Daten, um Systemverbindungen zu visualisieren.",
        "lt": "Sukurkite savo priežastinių ciklų diagramą iš ISA duomenų, kad vizualizuotumėte sistemos ryšius.",
        "pt": "Construa o seu Diagrama de Ciclos Causais a partir dos dados ISA para visualizar as conexões do sistema.",
        "it": "Costruisci il tuo Diagramma dei Cicli Causali dai dati ISA per visualizzare le connessioni del sistema."
    },
    {
        "en": "Build Network from ISA Data",
        "es": "Construir Red desde Datos ISA",
        "fr": "Construire le Réseau depuis les Données ISA",
        "de": "Netzwerk aus ISA-Daten Erstellen",
        "lt": "Sukurti tinklą iš ISA duomenų",
        "pt": "Construir Rede a partir dos Dados ISA",
        "it": "Costruisci Rete dai Dati ISA"
    },
    {
        "en": "Save Project",
        "es": "Guardar Proyecto",
        "fr": "Enregistrer le Projet",
        "de": "Projekt Speichern",
        "lt": "Išsaugoti projektą",
        "pt": "Guardar Projeto",
        "it": "Salva Progetto"
    },
    {
        "en": "Load Project",
        "es": "Cargar Proyecto",
        "fr": "Charger le Projet",
        "de": "Projekt Laden",
        "lt": "Įkelti projektą",
        "pt": "Carregar Projeto",
        "it": "Carica Progetto"
    },
    {
        "en": "Save your current project data, including all PIMS, ISA entries, and analysis results",
        "es": "Guarde los datos de su proyecto actual, incluidas todas las entradas PIMS, ISA y los resultados de análisis",
        "fr": "Enregistrez les données de votre projet actuel, y compris toutes les entrées PIMS, ISA et les résultats d'analyse",
        "de": "Speichern Sie Ihre aktuellen Projektdaten, einschließlich aller PIMS-, ISA-Einträge und Analyseergebnisse",
        "lt": "Išsaugokite dabartinio projekto duomenis, įskaitant visus PIMS, ISA įrašus ir analizės rezultatus",
        "pt": "Guarde os dados do seu projeto atual, incluindo todas as entradas PIMS, ISA e resultados de análise",
        "it": "Salva i dati del progetto corrente, incluse tutte le voci PIMS, ISA e i risultati dell'analisi"
    },
    {
        "en": "Load a previously saved project",
        "es": "Cargar un proyecto guardado anteriormente",
        "fr": "Charger un projet précédemment enregistré",
        "de": "Laden Sie ein zuvor gespeichertes Projekt",
        "lt": "Įkelti anksčiau išsaugotą projektą",
        "pt": "Carregar um projeto guardado anteriormente",
        "it": "Carica un progetto salvato in precedenza"
    }
]

def main():
    # Read the existing translation file
    with open('translations/translation.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Current number of translations: {len(data['translation'])}")

    # Add new menu translations
    added = 0
    for new_entry in menu_translations:
        # Check if this translation already exists
        en_text = new_entry['en']
        exists = any(entry.get('en') == en_text for entry in data['translation'])

        if not exists:
            data['translation'].append(new_entry)
            print(f"Added: {en_text[:60]}...")
            added += 1
        else:
            print(f"Skipped (exists): {en_text[:60]}...")

    print(f"\nNew number of translations: {len(data['translation'])}")
    print(f"Added: {added} new translations")

    # Write back to file with proper formatting
    with open('translations/translation.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("Menu translations added successfully!")

if __name__ == '__main__':
    main()
