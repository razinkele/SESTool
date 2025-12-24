#!/usr/bin/env python3
"""
Generate complete ISA module translations for all 7 languages
Comprehensive dictionary approach with marine science terminology
"""

import json
from pathlib import Path

# Comprehensive ISA translation dictionary
ISA_TRANSLATIONS = {
    # Core DAPSI(W)R(M) terms
    "Drivers": {"es": "Impulsores", "fr": "Moteurs", "de": "Treiber", "lt": "Varomosios jėgos", "pt": "Impulsionadores", "it": "Driver"},
    "Activities": {"es": "Actividades", "fr": "Activités", "de": "Aktivitäten", "lt": "Veikla", "pt": "Atividades", "it": "Attività"},
    "Pressures": {"es": "Presiones", "fr": "Pressions", "de": "Belastungen", "lt": "Spaudimas", "pt": "Pressões", "it": "Pressioni"},
    "Marine Processes": {"es": "Procesos Marinos", "fr": "Processus Marins", "de": "Marine Prozesse", "lt": "Jūros procesai", "pt": "Processos Marinhos", "it": "Processi Marini"},
    "Ecosystem Services": {"es": "Servicios Ecosistémicos", "fr": "Services Écosystémiques", "de": "Ökosystemleistungen", "lt": "Ekosistemos paslaugos", "pt": "Serviços Ecossistêmicos", "it": "Servizi Ecosistemici"},
    "Goods and Benefits": {"es": "Bienes y Beneficios", "fr": "Biens et Avantages", "de": "Güter und Vorteile", "lt": "Prekės ir nauda", "pt": "Bens e Benefícios", "it": "Beni e Benefici"},
    "Goods & Benefits": {"es": "Bienes y Beneficios", "fr": "Biens et Avantages", "de": "Güter und Vorteile", "lt": "Prekės ir nauda", "pt": "Bens e Benefícios", "it": "Beni e Benefici"},

    # Exercise titles
    "Exercise 0: Complexity": {"es": "Ejercicio 0: Complejidad", "fr": "Exercice 0 : Complexité", "de": "Übung 0: Komplexität", "lt": "Pratimas 0: Sudėtingumas", "pt": "Exercício 0: Complexidade", "it": "Esercizio 0: Complessità"},
    "Exercise 1: Goods & Benefits": {"es": "Ejercicio 1: Bienes y Beneficios", "fr": "Exercice 1 : Biens et Avantages", "de": "Übung 1: Güter und Vorteile", "lt": "Pratimas 1: Prekės ir nauda", "pt": "Exercício 1: Bens e Benefícios", "it": "Esercizio 1: Beni e Benefici"},
    "Exercise 2a: Ecosystem Services": {"es": "Ejercicio 2a: Servicios Ecosistémicos", "fr": "Exercice 2a : Services Écosystémiques", "de": "Übung 2a: Ökosystemleistungen", "lt": "Pratimas 2a: Ekosistemos paslaugos", "pt": "Exercício 2a: Serviços Ecossistêmicos", "it": "Esercizio 2a: Servizi Ecosistemici"},
    "Exercise 2b: Marine Processes": {"es": "Ejercicio 2b: Procesos Marinos", "fr": "Exercice 2b : Processus Marins", "de": "Übung 2b: Marine Prozesse", "lt": "Pratimas 2b: Jūros procesai", "pt": "Exercício 2b: Processos Marinhos", "it": "Esercizio 2b: Processi Marini"},
    "Exercise 3: Pressures": {"es": "Ejercicio 3: Presiones", "fr": "Exercice 3 : Pressions", "de": "Übung 3: Belastungen", "lt": "Pratimas 3: Spaudimas", "pt": "Exercício 3: Pressões", "it": "Esercizio 3: Pressioni"},
    "Exercise 4: Activities": {"es": "Ejercicio 4: Actividades", "fr": "Exercice 4 : Activités", "de": "Übung 4: Aktivitäten", "lt": "Pratimas 4: Veikla", "pt": "Exercício 4: Atividades", "it": "Esercizio 4: Attività"},
    "Exercise 5: Drivers": {"es": "Ejercicio 5: Impulsores", "fr": "Exercice 5 : Moteurs", "de": "Übung 5: Treiber", "lt": "Pratimas 5: Varomosios jėgos", "pt": "Exercício 5: Impulsionadores", "it": "Esercizio 5: Driver"},
    "Exercise 6: Loop Closure": {"es": "Ejercicio 6: Cierre del Bucle", "fr": "Exercice 6 : Fermeture de Boucle", "de": "Übung 6: Schleifenschließung", "lt": "Pratimas 6: Ciklo uždarymas", "pt": "Exercício 6: Fechamento do Ciclo", "it": "Esercizio 6: Chiusura del Ciclo"},
    "Exercise 7: BOT Graphs": {"es": "Ejercicio 7: Gráficos CDT", "fr": "Exercice 7 : Graphiques CDT", "de": "Übung 7: VZG-Diagramme", "lt": "Pratimas 7: ELG grafikai", "pt": "Exercício 7: Gráficos CDT", "it": "Esercizio 7: Grafici CDT"},
    "Exercise 8: CLD": {"es": "Ejercicio 8: DBC", "fr": "Exercice 8 : DBC", "de": "Übung 8: ULS", "lt": "Pratimas 8: PKD", "pt": "Exercício 8: DLC", "it": "Esercizio 8: DCC"},
    "Exercise 9: Data Management": {"es": "Ejercicio 9: Gestión de Datos", "fr": "Exercice 9 : Gestion des Données", "de": "Übung 9: Datenverwaltung", "lt": "Pratimas 9: Duomenų valdymas", "pt": "Exercício 9: Gestão de Dados", "it": "Esercizio 9: Gestione Dati"},

    # Common actions
    "Add": {"es": "Agregar", "fr": "Ajouter", "de": "Hinzufügen", "lt": "Pridėti", "pt": "Adicionar", "it": "Aggiungi"},
    "Save": {"es": "Guardar", "fr": "Enregistrer", "de": "Speichern", "lt": "Išsaugoti", "pt": "Salvar", "it": "Salva"},
    "Delete": {"es": "Eliminar", "fr": "Supprimer", "de": "Löschen", "lt": "Ištrinti", "pt": "Excluir", "it": "Elimina"},
    "Remove": {"es": "Quitar", "fr": "Retirer", "de": "Entfernen", "lt": "Pašalinti", "pt": "Remover", "it": "Rimuovi"},
    "Edit": {"es": "Editar", "fr": "Modifier", "de": "Bearbeiten", "lt": "Redaguoti", "pt": "Editar", "it": "Modifica"},
    "Cancel": {"es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "lt": "Atšaukti", "pt": "Cancelar", "it": "Annulla"},
    "Help": {"es": "Ayuda", "fr": "Aide", "de": "Hilfe", "lt": "Pagalba", "pt": "Ajuda", "it": "Aiuto"},

    # Common labels
    "Name": {"es": "Nombre", "fr": "Nom", "de": "Name", "lt": "Pavadinimas", "pt": "Nome", "it": "Nome"},
    "Description": {"es": "Descripción", "fr": "Description", "de": "Beschreibung", "lt": "Aprašymas", "pt": "Descrição", "it": "Descrizione"},
    "Description:": {"es": "Descripción:", "fr": "Description :", "de": "Beschreibung:", "lt": "Aprašymas:", "pt": "Descrição:", "it": "Descrizione:"},
    "Category": {"es": "Categoría", "fr": "Catégorie", "de": "Kategorie", "lt": "Kategorija", "pt": "Categoria", "it": "Categoria"},
    "Type": {"es": "Tipo", "fr": "Type", "de": "Typ", "lt": "Tipas", "pt": "Tipo", "it": "Tipo"},
    "Type:": {"es": "Tipo:", "fr": "Type :", "de": "Typ:", "lt": "Tipas:", "pt": "Tipo:", "it": "Tipo:"},
    "Indicator": {"es": "Indicador", "fr": "Indicateur", "de": "Indikator", "lt": "Rodiklis", "pt": "Indicador", "it": "Indicatore"},
    "Indicator:": {"es": "Indicador:", "fr": "Indicateur :", "de": "Indikator:", "lt": "Rodiklis:", "pt": "Indicador:", "it": "Indicatore:"},
    "Purpose": {"es": "Propósito", "fr": "Objectif", "de": "Zweck", "lt": "Tikslas", "pt": "Propósito", "it": "Scopo"},
    "Purpose:": {"es": "Propósito:", "fr": "Objectif :", "de": "Zweck:", "lt": "Tikslas:", "pt": "Propósito:", "it": "Scopo:"},
    "Example": {"es": "Ejemplo", "fr": "Exemple", "de": "Beispiel", "lt": "Pavyzdys", "pt": "Exemplo", "it": "Esempio"},
    "Example:": {"es": "Ejemplo:", "fr": "Exemple :", "de": "Beispiel:", "lt": "Pavyzdys:", "pt": "Exemplo:", "it": "Esempio:"},
    "Examples": {"es": "Ejemplos", "fr": "Exemples", "de": "Beispiele", "lt": "Pavyzdžiai", "pt": "Exemplos", "it": "Esempi"},
    "Current": {"es": "Actual", "fr": "Actuel", "de": "Aktuell", "lt": "Dabartinis", "pt": "Atual", "it": "Attuale"},

    # Exercise-specific headers
    "Unfolding Complexity and Impacts on Welfare": {"es": "Desentrañando la Complejidad e Impactos en el Bienestar", "fr": "Déploiement de la Complexité et Impacts sur le Bien-être", "de": "Entfaltung der Komplexität und Auswirkungen auf das Wohlergehen", "lt": "Sudėtingumo atskleidimas ir poveikis gerovei", "pt": "Desdobrando a Complexidade e Impactos no Bem-estar", "it": "Svolgimento della Complessità e Impatti sul Benessere"},
    "Specifying Goods and Benefits (G&B)": {"es": "Especificando Bienes y Beneficios", "fr": "Spécification des Biens et Avantages", "de": "Spezifizierung von Gütern und Vorteilen", "lt": "Prekių ir naudos specifikavimas", "pt": "Especificando Bens e Benefícios", "it": "Specificazione di Beni e Benefici"},

    # Form fields
    "Case Study Name:": {"es": "Nombre del Estudio de Caso:", "fr": "Nom de l'Étude de Cas :", "de": "Name der Fallstudie:", "lt": "Atvejo studijos pavadinimas:", "pt": "Nome do Estudo de Caso:", "it": "Nome dello Studio di Caso:"},
    "Brief Description:": {"es": "Breve Descripción:", "fr": "Brève Description :", "de": "Kurzbeschreibung:", "lt": "Trumpas aprašymas:", "pt": "Breve Descrição:", "it": "Breve Descrizione:"},
    "Geographic Scope:": {"es": "Alcance Geográfico:", "fr": "Portée Géographique :", "de": "Geografischer Umfang:", "lt": "Geografinė aprėptis:", "pt": "Âmbito Geográfico:", "it": "Ambito Geografico:"},
    "Temporal Scope:": {"es": "Alcance Temporal:", "fr": "Portée Temporelle :", "de": "Zeitlicher Umfang:", "lt": "Laikinė aprėptis:", "pt": "Âmbito Temporal:", "it": "Ambito Temporale:"},

    # Categories
    "Provisioning": {"es": "Aprovisionamiento", "fr": "Approvisionnement", "de": "Versorgung", "lt": "Aprūpinimas", "pt": "Provisionamento", "it": "Approvvigionamento"},
    "Regulating": {"es": "Regulación", "fr": "Régulation", "de": "Regulierung", "lt": "Reguliavimas", "pt": "Regulação", "it": "Regolazione"},
    "Cultural": {"es": "Cultural", "fr": "Culturel", "de": "Kulturell", "lt": "Kultūrinis", "pt": "Cultural", "it": "Culturale"},
    "Cultural:": {"es": "Cultural:", "fr": "Culturel :", "de": "Kulturell:", "lt": "Kultūrinis:", "pt": "Cultural:", "it": "Culturale:"},
    "Supporting": {"es": "Apoyo", "fr": "Soutien", "de": "Unterstützend", "lt": "Palaikymas", "pt": "Suporte", "it": "Supporto"},

    # Specific marine terms
    "Aquaculture:": {"es": "Acuicultura:", "fr": "Aquaculture :", "de": "Aquakultur:", "lt": "Akvakultūra:", "pt": "Aquicultura:", "it": "Acquacoltura:"},
    "Agriculture:": {"es": "Agricultura:", "fr": "Agriculture :", "de": "Landwirtschaft:", "lt": "Žemės ūkis:", "pt": "Agricultura:", "it": "Agricoltura:"},
    "Fishing:": {"es": "Pesca:", "fr": "Pêche :", "de": "Fischerei:", "lt": "Žvejyba:", "pt": "Pesca:", "it": "Pesca:"},
    "Tourism:": {"es": "Turismo:", "fr": "Tourisme :", "de": "Tourismus:", "lt": "Turizmas:", "pt": "Turismo:", "it": "Turismo:"},
    "Shipping:": {"es": "Transporte Marítimo:", "fr": "Transport Maritime :", "de": "Schifffahrt:", "lt": "Laivyba:", "pt": "Transporte Marítimo:", "it": "Navigazione:"},
    "Energy:": {"es": "Energía:", "fr": "Énergie :", "de": "Energie:", "lt": "Energija:", "pt": "Energia:", "it": "Energia:"},

    # Driver categories
    "Economic:": {"es": "Económico:", "fr": "Économique :", "de": "Wirtschaftlich:", "lt": "Ekonominis:", "pt": "Econômico:", "it": "Economico:"},
    "Demographic:": {"es": "Demográfico:", "fr": "Démographique :", "de": "Demografisch:", "lt": "Demografinis:", "pt": "Demográfico:", "it": "Demografico:"},
    "Environmental:": {"es": "Ambiental:", "fr": "Environnemental :", "de": "Umwelt:", "lt": "Aplinkos:", "pt": "Ambiental:", "it": "Ambientale:"},
    "Technological:": {"es": "Tecnológico:", "fr": "Technologique :", "de": "Technologisch:", "lt": "Technologinis:", "pt": "Tecnológico:", "it": "Tecnologico:"},
    "Political:": {"es": "Político:", "fr": "Politique :", "de": "Politisch:", "lt": "Politinis:", "pt": "Político:", "it": "Politico:"},

    # Pressure categories
    "Biological:": {"es": "Biológico:", "fr": "Biologique :", "de": "Biologisch:", "lt": "Biologinis:", "pt": "Biológico:", "it": "Biologico:"},
    "Chemical:": {"es": "Químico:", "fr": "Chimique :", "de": "Chemisch:", "lt": "Cheminis:", "pt": "Químico:", "it": "Chimico:"},
    "Physical:": {"es": "Físico:", "fr": "Physique :", "de": "Physikalisch:", "lt": "Fizinis:", "pt": "Físico:", "it": "Fisico:"},

    # System terms
    "Confidence:": {"es": "Confianza:", "fr": "Confiance :", "de": "Vertrauen:", "lt": "Pasitikėjimas:", "pt": "Confiança:", "it": "Fiducia:"},
    "Polarity:": {"es": "Polaridad:", "fr": "Polarité :", "de": "Polarität:", "lt": "Poliškumas:", "pt": "Polaridade:", "it": "Polarità:"},
    "Strength:": {"es": "Fuerza:", "fr": "Force :", "de": "Stärke:", "lt": "Stiprumas:", "pt": "Força:", "it": "Forza:"},
    "Delay:": {"es": "Retraso:", "fr": "Retard :", "de": "Verzögerung:", "lt": "Vėlavimas:", "pt": "Atraso:", "it": "Ritardo:"},

    # Actions with context
    "Add Good/Benefit": {"es": "Agregar Bien/Beneficio", "fr": "Ajouter Bien/Avantage", "de": "Gut/Vorteil hinzufügen", "lt": "Pridėti prekę/naudą", "pt": "Adicionar Bem/Benefício", "it": "Aggiungi Bene/Beneficio"},
    "Add Ecosystem Service": {"es": "Agregar Servicio Ecosistémico", "fr": "Ajouter Service Écosystémique", "de": "Ökosystemleistung hinzufügen", "lt": "Pridėti ekosistemos paslaugą", "pt": "Adicionar Serviço Ecossistêmico", "it": "Aggiungi Servizio Ecosistemico"},
    "Add Marine Process": {"es": "Agregar Proceso Marino", "fr": "Ajouter Processus Marin", "de": "Marinen Prozess hinzufügen", "lt": "Pridėti jūros procesą", "pt": "Adicionar Processo Marinho", "it": "Aggiungi Processo Marino"},
    "Add Pressure": {"es": "Agregar Presión", "fr": "Ajouter Pression", "de": "Belastung hinzufügen", "lt": "Pridėti spaudimą", "pt": "Adicionar Pressão", "it": "Aggiungi Pressione"},
    "Add Activity": {"es": "Agregar Actividad", "fr": "Ajouter Activité", "de": "Aktivität hinzufügen", "lt": "Pridėti veiklą", "pt": "Adicionar Atividade", "it": "Aggiungi Attività"},
    "Add Driver": {"es": "Agregar Impulsor", "fr": "Ajouter Moteur", "de": "Treiber hinzufügen", "lt": "Pridėti varomąją jėgą", "pt": "Adicionar Impulsionador", "it": "Aggiungi Driver"},

    # Save actions
    "Save Exercise 0": {"es": "Guardar Ejercicio 0", "fr": "Enregistrer Exercice 0", "de": "Übung 0 speichern", "lt": "Išsaugoti pratimą 0", "pt": "Salvar Exercício 0", "it": "Salva Esercizio 0"},
    "Save Exercise 1": {"es": "Guardar Ejercicio 1", "fr": "Enregistrer Exercice 1", "de": "Übung 1 speichern", "lt": "Išsaugoti pratimą 1", "pt": "Salvar Exercício 1", "it": "Salva Esercizio 1"},
    "Save Exercise 2a": {"es": "Guardar Ejercicio 2a", "fr": "Enregistrer Exercice 2a", "de": "Übung 2a speichern", "lt": "Išsaugoti pratimą 2a", "pt": "Salvar Exercício 2a", "it": "Salva Esercizio 2a"},
    "Save Exercise 2b": {"es": "Guardar Ejercicio 2b", "fr": "Enregistrer Exercice 2b", "de": "Übung 2b speichern", "lt": "Išsaugoti pratimą 2b", "pt": "Salvar Exercício 2b", "it": "Salva Esercizio 2b"},
    "Save Exercise 3": {"es": "Guardar Ejercicio 3", "fr": "Enregistrer Exercice 3", "de": "Übung 3 speichern", "lt": "Išsaugoti pratimą 3", "pt": "Salvar Exercício 3", "it": "Salva Esercizio 3"},
    "Save Exercise 4": {"es": "Guardar Ejercicio 4", "fr": "Enregistrer Exercice 4", "de": "Übung 4 speichern", "lt": "Išsaugoti pratimą 4", "pt": "Salvar Exercício 4", "it": "Salva Esercizio 4"},
    "Save Exercise 5": {"es": "Guardar Ejercicio 5", "fr": "Enregistrer Exercice 5", "de": "Übung 5 speichern", "lt": "Išsaugoti pratimą 5", "pt": "Salvar Exercício 5", "it": "Salva Esercizio 5"},
    "Save Exercise 6": {"es": "Guardar Ejercicio 6", "fr": "Enregistrer Exercice 6", "de": "Übung 6 speichern", "lt": "Išsaugoti pratimą 6", "pt": "Salvar Exercício 6", "it": "Salva Esercizio 6"},
    "Save Exercise 7": {"es": "Guardar Ejercicio 7", "fr": "Enregistrer Exercice 7", "de": "Übung 7 speichern", "lt": "Išsaugoti pratimą 7", "pt": "Salvar Exercício 7", "it": "Salva Esercizio 7"},
    "Save Exercise 8": {"es": "Guardar Ejercicio 8", "fr": "Enregistrer Exercice 8", "de": "Übung 8 speichern", "lt": "Išsaugoti pratimą 8", "pt": "Salvar Exercício 8", "it": "Salva Esercizio 8"},
    "Save Exercise 9": {"es": "Guardar Ejercicio 9", "fr": "Enregistrer Exercice 9", "de": "Übung 9 speichern", "lt": "Išsaugoti pratimą 9", "pt": "Salvar Exercício 9", "it": "Salva Esercizio 9"},
}

# Read existing translations
trans_path = Path("translations/translation.json")
with open(trans_path, 'r', encoding='utf-8') as f:
    existing_data = json.load(f)

# Get existing English keys
existing_keys = {entry['en'] for entry in existing_data['translation']}

# Read extracted ISA strings
strings_path = Path("isa_translatable_strings.txt")
with open(strings_path, 'r', encoding='utf-8') as f:
    isa_strings = [line.strip() for line in f if line.strip()]

# Generate new translations
new_count = 0
found_count = 0
missing_count = 0

for eng_text in isa_strings:
    if eng_text in existing_keys:
        found_count += 1
        continue

    if eng_text in ISA_TRANSLATIONS:
        trans = ISA_TRANSLATIONS[eng_text]
        entry = {
            "en": eng_text,
            "es": trans["es"],
            "fr": trans["fr"],
            "de": trans["de"],
            "lt": trans["lt"],
            "pt": trans["pt"],
            "it": trans["it"]
        }
        existing_data['translation'].append(entry)
        new_count += 1
        print(f"[OK] {eng_text}")
    else:
        missing_count += 1
        print(f"[MISSING] {eng_text}")

# Save updated translations
with open(trans_path, 'w', encoding='utf-8') as f:
    json.dump(existing_data, f, ensure_ascii=False, indent=2)

print(f"\n{'='*60}")
print(f"Translation Summary:")
print(f"  Already existed: {found_count}")
print(f"  Newly added: {new_count}")
print(f"  Still missing: {missing_count}")
print(f"  Total processed: {len(isa_strings)}")
print(f"{'='*60}")
print(f"\nUpdated translation.json with {new_count} new ISA entries")
