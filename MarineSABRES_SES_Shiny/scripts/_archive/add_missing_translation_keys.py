#!/usr/bin/env python3
# Add missing translation keys for module headers
# This ensures all modules have proper translations in all languages

import json
import sys
import os

# Windows UTF-8 encoding fix
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Define all missing translation keys
MISSING_KEYS = {
    "translations/modules/analysis_tools.json": {
        "modules.analysis.loops.title": {
            "en": "Feedback Loop Detection and Analysis",
            "es": "Detección y Análisis de Bucles de Retroalimentación",
            "fr": "Détection et Analyse des Boucles de Rétroaction",
            "de": "Erkennung und Analyse von Rückkopplungsschleifen",
            "lt": "Grįžtamojo Ryšio Kilpų Aptikimas ir Analizė",
            "pt": "Detecção e Análise de Loops de Retroalimentação",
            "it": "Rilevamento e Analisi dei Loop di Feedback",
            "no": "Deteksjon og Analyse av Tilbakemeldingssløyfer"
        },
        "modules.analysis.loops.subtitle": {
            "en": "Automatically identify and analyze feedback loops in your Causal Loop Diagram.",
            "es": "Identifique y analice automáticamente los bucles de retroalimentación en su Diagrama de Bucles Causales.",
            "fr": "Identifiez et analysez automatiquement les boucles de rétroaction dans votre diagramme de boucles causales.",
            "de": "Identifizieren und analysieren Sie automatisch Rückkopplungsschleifen in Ihrem Kausalschleifendiagramm.",
            "lt": "Automatiškai nustatykite ir analizuokite grįžtamojo ryšio kilpas savo Priežastinių Kilpų Diagramoje.",
            "pt": "Identifique e analise automaticamente os loops de retroalimentação no seu Diagrama de Loops Causais.",
            "it": "Identifica e analizza automaticamente i loop di feedback nel tuo Diagramma dei Loop Causali.",
            "no": "Identifiser og analyser automatisk tilbakemeldingssløyfer i ditt Årsaksløkkediagram."
        },
        "modules.analysis.leverage.title": {
            "en": "Leverage Point Analysis",
            "es": "Análisis de Puntos de Apalancamiento",
            "fr": "Analyse des Points de Levier",
            "de": "Analyse von Hebelpunkten",
            "lt": "Sverto Taškų Analizė",
            "pt": "Análise de Pontos de Alavancagem",
            "it": "Analisi dei Punti di Leva",
            "no": "Analyse av Vippepunkter"
        },
        "modules.analysis.leverage.subtitle": {
            "en": "Identify the most influential nodes in your network that could serve as key intervention points.",
            "es": "Identifique los nodos más influyentes en su red que podrían servir como puntos clave de intervención.",
            "fr": "Identifiez les nœuds les plus influents de votre réseau qui pourraient servir de points d'intervention clés.",
            "de": "Identifizieren Sie die einflussreichsten Knoten in Ihrem Netzwerk, die als Schlüssel-Interventionspunkte dienen könnten.",
            "lt": "Nustatykite įtakingiausius mazgus savo tinkle, kurie galėtų būti pagrindiniai intervencijos taškai.",
            "pt": "Identifique os nós mais influentes na sua rede que podem servir como pontos-chave de intervenção.",
            "it": "Identifica i nodi più influenti nella tua rete che potrebbero servire come punti chiave di intervento.",
            "no": "Identifiser de mest innflytelsesrike nodene i nettverket ditt som kan tjene som nøkkelintervensjonspunkter."
        }
    },
    "translations/modules/cld_visualization.json": {
        "modules.cld.visualization.title": {
            "en": "Causal Loop Diagram Visualization",
            "es": "Visualización del Diagrama de Bucles Causales",
            "fr": "Visualisation du Diagramme de Boucles Causales",
            "de": "Visualisierung des Kausalschleifendiagramms",
            "lt": "Priežastinių Kilpų Diagramos Vizualizacija",
            "pt": "Visualização do Diagrama de Loops Causais",
            "it": "Visualizzazione del Diagramma dei Loop Causali",
            "no": "Visualisering av Årsaksløkkediagram"
        },
        "modules.cld.visualization.subtitle": {
            "en": "Interactive network visualization of your social-ecological system",
            "es": "Visualización interactiva de la red de su sistema socio-ecológico",
            "fr": "Visualisation interactive du réseau de votre système socio-écologique",
            "de": "Interaktive Netzwerkvisualisierung Ihres sozial-ökologischen Systems",
            "lt": "Interaktyvi jūsų socialinės-ekologinės sistemos tinklo vizualizacija",
            "pt": "Visualização interativa da rede do seu sistema socio-ecológico",
            "it": "Visualizzazione interattiva della rete del tuo sistema socio-ecologico",
            "no": "Interaktiv nettverksvisualisering av ditt sosial-økologiske system"
        }
    },
    "translations/modules/ses_creation.json": {
        "modules.ses.creation.title": {
            "en": "Create Your Social-Ecological System",
            "es": "Cree su Sistema Socio-Ecológico",
            "fr": "Créez votre Système Socio-Écologique",
            "de": "Erstellen Sie Ihr Sozial-Ökologisches System",
            "lt": "Sukurkite savo Socialinę-Ekologinę Sistemą",
            "pt": "Crie o seu Sistema Socio-Ecológico",
            "it": "Crea il tuo Sistema Socio-Ecologico",
            "no": "Opprett ditt Sosial-Økologiske System"
        },
        "modules.ses.creation.subtitle": {
            "en": "Choose the method that best fits your experience level and project needs",
            "es": "Elija el método que mejor se adapte a su nivel de experiencia y las necesidades de su proyecto",
            "fr": "Choisissez la méthode qui correspond le mieux à votre niveau d'expérience et aux besoins de votre projet",
            "de": "Wählen Sie die Methode, die am besten zu Ihrer Erfahrung und Ihren Projektanforderungen passt",
            "lt": "Pasirinkite metodą, kuris geriausiai atitinka jūsų patirties lygį ir projekto poreikius",
            "pt": "Escolha o método que melhor se adapta ao seu nível de experiência e às necessidades do projeto",
            "it": "Scegli il metodo che meglio si adatta al tuo livello di esperienza e alle esigenze del progetto",
            "no": "Velg metoden som best passer ditt erfaringsnivå og prosjektbehov"
        },
        "modules.ses.template.title": {
            "en": "Template-Based SES Creation",
            "es": "Creación de SES Basada en Plantillas",
            "fr": "Création SES Basée sur des Modèles",
            "de": "Vorlagenbasierte SES-Erstellung",
            "lt": "SES Kūrimas Remiantis Šablonais",
            "pt": "Criação de SES Baseada em Modelos",
            "it": "Creazione SES Basata su Modelli",
            "no": "Malbasert SES-Oppretting"
        },
        "modules.ses.template.subtitle": {
            "en": "Choose a pre-built template that matches your scenario and customize it to your needs",
            "es": "Elija una plantilla predefinida que coincida con su escenario y personalícela según sus necesidades",
            "fr": "Choisissez un modèle pré-construit qui correspond à votre scénario et personnalisez-le selon vos besoins",
            "de": "Wählen Sie eine vorgefertigte Vorlage, die zu Ihrem Szenario passt, und passen Sie sie an Ihre Bedürfnisse an",
            "lt": "Pasirinkite iš anksto sukurtą šabloną, atitinkantį jūsų scenarijų, ir pritaikykite jį savo poreikiams",
            "pt": "Escolha um modelo pré-construído que corresponda ao seu cenário e personalize-o de acordo com suas necessidades",
            "it": "Scegli un modello pre-costruito che corrisponde al tuo scenario e personalizzalo in base alle tue esigenze",
            "no": "Velg en ferdigbygd mal som passer ditt scenario og tilpass den til dine behov"
        }
    },
    "translations/modules/export_reports.json": {
        "modules.export.reports.title": {
            "en": "Export & Reports",
            "es": "Exportación e Informes",
            "fr": "Exportation et Rapports",
            "de": "Export & Berichte",
            "lt": "Eksportavimas ir Ataskaitos",
            "pt": "Exportação e Relatórios",
            "it": "Esportazione e Rapporti",
            "no": "Eksport og Rapporter"
        },
        "modules.export.reports.subtitle": {
            "en": "Export your data, visualizations, and generate comprehensive reports.",
            "es": "Exporte sus datos, visualizaciones y genere informes completos.",
            "fr": "Exportez vos données, visualisations et générez des rapports complets.",
            "de": "Exportieren Sie Ihre Daten, Visualisierungen und erstellen Sie umfassende Berichte.",
            "lt": "Eksportuokite savo duomenis, vizualizacijas ir generuokite išsamias ataskaitas.",
            "pt": "Exporte seus dados, visualizações e gere relatórios abrangentes.",
            "it": "Esporta i tuoi dati, visualizzazioni e genera report completi.",
            "no": "Eksporter dataene dine, visualiseringer og generer omfattende rapporter."
        }
    },
    "translations/modules/isa_data_entry.json": {
        "modules.isa.data_entry.title": {
            "en": "Integrated Systems Analysis (ISA) Data Entry",
            "es": "Entrada de Datos de Análisis de Sistemas Integrados (ISA)",
            "fr": "Saisie de Données d'Analyse de Systèmes Intégrés (ISA)",
            "de": "Dateneingabe für Integrierte Systemanalyse (ISA)",
            "lt": "Integruotos Sistemų Analizės (ISA) Duomenų Įvedimas",
            "pt": "Entrada de Dados de Análise de Sistemas Integrados (ISA)",
            "it": "Inserimento Dati di Analisi dei Sistemi Integrati (ISA)",
            "no": "Integrert Systemanalyse (ISA) Datainnlegging"
        },
        "modules.isa.data_entry.subtitle": {
            "en": "Follow the structured exercises to build your marine Social-Ecological System analysis.",
            "es": "Siga los ejercicios estructurados para construir su análisis del Sistema Socio-Ecológico Marino.",
            "fr": "Suivez les exercices structurés pour construire votre analyse du Système Socio-Écologique Marin.",
            "de": "Folgen Sie den strukturierten Übungen, um Ihre Analyse des marinen Sozial-Ökologischen Systems zu erstellen.",
            "lt": "Sekite struktūrizuotus pratimus, kad sukurtumėte savo Jūrinės Socialinės-Ekologinės Sistemos analizę.",
            "pt": "Siga os exercícios estruturados para construir sua análise do Sistema Socio-Ecológico Marinho.",
            "it": "Segui gli esercizi strutturati per costruire la tua analisi del Sistema Socio-Ecologico Marino.",
            "no": "Følg de strukturerte øvelsene for å bygge din analyse av det Marine Sosial-Økologiske Systemet."
        }
    },
    "translations/modules/pims_stakeholder.json": {
        "modules.pims.resources.subtitle": {
            "en": "Manage project resources, risks, and constraints.",
            "es": "Gestione los recursos, riesgos y restricciones del proyecto.",
            "fr": "Gérez les ressources, risques et contraintes du projet.",
            "de": "Verwalten Sie Projektressourcen, Risiken und Einschränkungen.",
            "lt": "Valdykite projekto išteklius, rizikas ir apribojimus.",
            "pt": "Gerencie recursos, riscos e restrições do projeto.",
            "it": "Gestisci le risorse, i rischi e i vincoli del progetto.",
            "no": "Administrer prosjektressurser, risikoer og begrensninger."
        }
    }
}

def add_keys_to_file(file_path, keys_to_add):
    """Add missing keys to a translation JSON file."""
    # Ensure directory exists
    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    # Load existing file or create new structure
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    else:
        data = {
            "languages": ["en", "es", "fr", "de", "lt", "pt", "it", "no"],
            "translation": {}
        }

    # Add new keys
    added_count = 0
    for key, translations in keys_to_add.items():
        if key not in data["translation"]:
            data["translation"][key] = translations
            added_count += 1
            print(f"  ✓ Added: {key}")
        else:
            print(f"  → Already exists: {key}")

    # Save back
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    return added_count

def main():
    print("=== Adding Missing Translation Keys ===\n")

    total_added = 0
    for file_path, keys in MISSING_KEYS.items():
        print(f"\nProcessing: {file_path}")
        added = add_keys_to_file(file_path, keys)
        total_added += added

    print(f"\n=== Summary ===")
    print(f"Total keys added: {total_added}")
    print("\n✓ All translation keys have been added!")

if __name__ == "__main__":
    main()
