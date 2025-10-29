#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Add Template SES Module translations to translation.json
Adds ~35 translation entries across 7 languages
"""

import json
import sys

# Template SES Module translations
TEMPLATE_SES_TRANSLATIONS = [
    # Main UI Header
    {
        "en": "Template-Based SES Creation",
        "es": "Creación de SES Basada en Plantillas",
        "fr": "Création de SES Basée sur des Modèles",
        "de": "Vorlagenbasierte SES-Erstellung",
        "lt": "SES kūrimas pagal šablonus",
        "pt": "Criação de SES Baseada em Modelos",
        "it": "Creazione SES Basata su Modelli"
    },
    {
        "en": "Choose a pre-built template that matches your scenario and customize it to your needs",
        "es": "Elija una plantilla predefinida que coincida con su escenario y personalícela según sus necesidades",
        "fr": "Choisissez un modèle prédéfini correspondant à votre scénario et personnalisez-le selon vos besoins",
        "de": "Wählen Sie eine vorgefertigte Vorlage, die zu Ihrem Szenario passt, und passen Sie sie an Ihre Bedürfnisse an",
        "lt": "Pasirinkite iš anksto sukurtą šabloną, atitinkantį jūsų scenarijų, ir pritaikykite jį savo poreikiams",
        "pt": "Escolha um modelo pré-construído que corresponda ao seu cenário e personalize-o de acordo com suas necessidades",
        "it": "Scegli un modello predefinito che corrisponda al tuo scenario e personalizzalo in base alle tue esigenze"
    },
    {
        "en": "Available Templates",
        "es": "Plantillas Disponibles",
        "fr": "Modèles Disponibles",
        "de": "Verfügbare Vorlagen",
        "lt": "Prieinami šablonai",
        "pt": "Modelos Disponíveis",
        "it": "Modelli Disponibili"
    },
    {
        "en": "Template Preview",
        "es": "Vista Previa de Plantilla",
        "fr": "Aperçu du Modèle",
        "de": "Vorlagenvorschau",
        "lt": "Šablono peržiūra",
        "pt": "Visualização do Modelo",
        "it": "Anteprima del Modello"
    },
    {
        "en": "Use This Template",
        "es": "Usar Esta Plantilla",
        "fr": "Utiliser ce Modèle",
        "de": "Diese Vorlage Verwenden",
        "lt": "Naudoti šį šabloną",
        "pt": "Usar Este Modelo",
        "it": "Usa Questo Modello"
    },
    {
        "en": "Customize Before Using",
        "es": "Personalizar Antes de Usar",
        "fr": "Personnaliser Avant Utilisation",
        "de": "Vor Verwendung Anpassen",
        "lt": "Pritaikyti prieš naudojant",
        "pt": "Personalizar Antes de Usar",
        "it": "Personalizza Prima dell'Uso"
    },

    # DAPSI(W)R(M) Element Labels
    {
        "en": "Drivers",
        "es": "Impulsores",
        "fr": "Facteurs",
        "de": "Treiber",
        "lt": "Veiksniai",
        "pt": "Impulsores",
        "it": "Fattori"
    },
    {
        "en": "Activities",
        "es": "Actividades",
        "fr": "Activités",
        "de": "Aktivitäten",
        "lt": "Veiklos",
        "pt": "Atividades",
        "it": "Attività"
    },
    {
        "en": "Pressures",
        "es": "Presiones",
        "fr": "Pressions",
        "de": "Belastungen",
        "lt": "Spaudimai",
        "pt": "Pressões",
        "it": "Pressioni"
    },
    {
        "en": "Marine Processes",
        "es": "Procesos Marinos",
        "fr": "Processus Marins",
        "de": "Marine Prozesse",
        "lt": "Jūros procesai",
        "pt": "Processos Marinhos",
        "it": "Processi Marini"
    },
    {
        "en": "Ecosystem Services",
        "es": "Servicios Ecosistémicos",
        "fr": "Services Écosystémiques",
        "de": "Ökosystemleistungen",
        "lt": "Ekosistemos paslaugos",
        "pt": "Serviços Ecossistêmicos",
        "it": "Servizi Ecosistemici"
    },
    {
        "en": "Goods & Benefits",
        "es": "Bienes y Beneficios",
        "fr": "Biens et Avantages",
        "de": "Güter und Vorteile",
        "lt": "Prekės ir nauda",
        "pt": "Bens e Benefícios",
        "it": "Beni e Benefici"
    },

    # Notification Messages
    {
        "en": "Template",
        "es": "Plantilla",
        "fr": "Modèle",
        "de": "Vorlage",
        "lt": "Šablonas",
        "pt": "Modelo",
        "it": "Modello"
    },
    {
        "en": "loaded successfully with example connections!",
        "es": "cargada exitosamente con conexiones de ejemplo!",
        "fr": "chargé avec succès avec des connexions d'exemple!",
        "de": "erfolgreich mit Beispielverbindungen geladen!",
        "lt": "sėkmingai įkeltas su pavyzdiniais ryšiais!",
        "pt": "carregado com sucesso com conexões de exemplo!",
        "it": "caricato con successo con connessioni di esempio!"
    },

    # Template Names
    {
        "en": "Fisheries Management",
        "es": "Gestión Pesquera",
        "fr": "Gestion des Pêcheries",
        "de": "Fischerei-Management",
        "lt": "Žvejybos valdymas",
        "pt": "Gestão Pesqueira",
        "it": "Gestione della Pesca"
    },
    {
        "en": "Common fisheries management scenario with overfishing pressures",
        "es": "Escenario común de gestión pesquera con presiones de sobrepesca",
        "fr": "Scénario de gestion des pêcheries avec pressions de surpêche",
        "de": "Gängiges Fischerei-Management-Szenario mit Überfischungsdruck",
        "lt": "Įprastas žvejybos valdymo scenarijus su peržvejojimo spaudimais",
        "pt": "Cenário comum de gestão pesqueira com pressões de sobrepesca",
        "it": "Scenario comune di gestione della pesca con pressioni di sovrapesca"
    },
    {
        "en": "Extraction",
        "es": "Extracción",
        "fr": "Extraction",
        "de": "Extraktion",
        "lt": "Gavyba",
        "pt": "Extração",
        "it": "Estrazione"
    },
    {
        "en": "Coastal Tourism",
        "es": "Turismo Costero",
        "fr": "Tourisme Côtier",
        "de": "Küstentourismus",
        "lt": "Pajūrio turizmas",
        "pt": "Turismo Costeiro",
        "it": "Turismo Costiero"
    },
    {
        "en": "Tourism development impacts on coastal ecosystems",
        "es": "Impactos del desarrollo turístico en ecosistemas costeros",
        "fr": "Impacts du développement touristique sur les écosystèmes côtiers",
        "de": "Auswirkungen der Tourismusentwicklung auf Küstenökosysteme",
        "lt": "Turizmo plėtros poveikis pajūrio ekosistemoms",
        "pt": "Impactos do desenvolvimento turístico em ecossistemas costeiros",
        "it": "Impatti dello sviluppo turistico sugli ecosistemi costieri"
    },
    {
        "en": "Recreation",
        "es": "Recreación",
        "fr": "Loisirs",
        "de": "Erholung",
        "lt": "Poilsis",
        "pt": "Recreação",
        "it": "Ricreazione"
    },
    {
        "en": "Aquaculture Development",
        "es": "Desarrollo de Acuicultura",
        "fr": "Développement de l'Aquaculture",
        "de": "Aquakultur-Entwicklung",
        "lt": "Akvakultūros plėtra",
        "pt": "Desenvolvimento da Aquicultura",
        "it": "Sviluppo dell'Acquacoltura"
    },
    {
        "en": "Marine aquaculture expansion and environmental impacts",
        "es": "Expansión de la acuicultura marina e impactos ambientales",
        "fr": "Expansion de l'aquaculture marine et impacts environnementaux",
        "de": "Ausweitung der marinen Aquakultur und Umweltauswirkungen",
        "lt": "Jūrų akvakultūros plėtra ir poveikis aplinkai",
        "pt": "Expansão da aquicultura marinha e impactos ambientais",
        "it": "Espansione dell'acquacoltura marina e impatti ambientali"
    },
    {
        "en": "Production",
        "es": "Producción",
        "fr": "Production",
        "de": "Produktion",
        "lt": "Gamyba",
        "pt": "Produção",
        "it": "Produzione"
    },
    {
        "en": "Marine Pollution",
        "es": "Contaminación Marina",
        "fr": "Pollution Marine",
        "de": "Meeresverschmutzung",
        "lt": "Jūros tarša",
        "pt": "Poluição Marinha",
        "it": "Inquinamento Marino"
    },
    {
        "en": "Pollution impacts from land and sea-based sources",
        "es": "Impactos de contaminación de fuentes terrestres y marinas",
        "fr": "Impacts de pollution provenant de sources terrestres et marines",
        "de": "Verschmutzungsauswirkungen aus land- und meeresbasierten Quellen",
        "lt": "Taršos poveikis iš sausumos ir jūros šaltinių",
        "pt": "Impactos de poluição de fontes terrestres e marinhas",
        "it": "Impatti dell'inquinamento da fonti terrestri e marine"
    },
    {
        "en": "Environmental",
        "es": "Ambiental",
        "fr": "Environnemental",
        "de": "Umwelt",
        "lt": "Aplinkosauga",
        "pt": "Ambiental",
        "it": "Ambientale"
    },
    {
        "en": "Climate Change Impacts",
        "es": "Impactos del Cambio Climático",
        "fr": "Impacts du Changement Climatique",
        "de": "Klimawandel-Auswirkungen",
        "lt": "Klimato kaitos poveikis",
        "pt": "Impactos das Mudanças Climáticas",
        "it": "Impatti del Cambiamento Climatico"
    },
    {
        "en": "Climate change effects on marine ecosystems",
        "es": "Efectos del cambio climático en ecosistemas marinos",
        "fr": "Effets du changement climatique sur les écosystèmes marins",
        "de": "Klimawandeleffekte auf marine Ökosysteme",
        "lt": "Klimato kaitos poveikis jūrų ekosistemoms",
        "pt": "Efeitos das mudanças climáticas em ecossistemas marinhos",
        "it": "Effetti del cambiamento climatico sugli ecosistemi marini"
    },
    {
        "en": "Climate",
        "es": "Clima",
        "fr": "Climat",
        "de": "Klima",
        "lt": "Klimatas",
        "pt": "Clima",
        "it": "Clima"
    }
]


def add_translations_to_file(json_file_path):
    """Add Template SES translations to translation.json"""

    try:
        # Read existing translation file
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        initial_count = len(data['translation'])

        # Add new translations
        data['translation'].extend(TEMPLATE_SES_TRANSLATIONS)

        final_count = len(data['translation'])
        added_count = final_count - initial_count

        # Write back to file
        with open(json_file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)

        print(f"[OK] Successfully added {added_count} Template SES translation entries")
        print(f"[OK] Total entries: {initial_count} -> {final_count}")
        print(f"[OK] Total translations: {final_count * 7} (across 7 languages)")

        return True

    except FileNotFoundError:
        print(f"[ERROR] Translation file not found: {json_file_path}")
        return False
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON in translation file: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Failed to add translations: {e}")
        return False


if __name__ == "__main__":
    translation_file = "translations/translation.json"

    print("=" * 60)
    print("Template SES Module - Translation Addition")
    print("=" * 60)
    print(f"Target file: {translation_file}")
    print(f"New entries: {len(TEMPLATE_SES_TRANSLATIONS)}")
    print(f"Languages: 7 (en, es, fr, de, lt, pt, it)")
    print("=" * 60)

    success = add_translations_to_file(translation_file)

    if success:
        print("\n[OK] Template SES translations added successfully!")
        sys.exit(0)
    else:
        print("\n[ERROR] Failed to add translations")
        sys.exit(1)
