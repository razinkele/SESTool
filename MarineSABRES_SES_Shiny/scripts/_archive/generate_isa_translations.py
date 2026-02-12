#!/usr/bin/env python3
"""
Generate translations for ISA Data Entry Module strings
"""

import json
from pathlib import Path

# Translation dictionaries for consistent terminology
MARINE_TERMS = {
    # DAPSI(W)R(M) Framework
    "Drivers": {"es": "Impulsores", "fr": "Moteurs", "de": "Treiber", "lt": "Varomosios jėgos", "pt": "Impulsionadores", "it": "Driver"},
    "Activities": {"es": "Actividades", "fr": "Activités", "de": "Aktivitäten", "lt": "Veikla", "pt": "Atividades", "it": "Attività"},
    "Pressures": {"es": "Presiones", "fr": "Pressions", "de": "Belastungen", "lt": "Spaudimas", "pt": "Pressões", "it": "Pressioni"},
    "Marine Processes": {"es": "Procesos Marinos", "fr": "Processus Marins", "de": "Marine Prozesse", "lt": "Jūros procesai", "pt": "Processos Marinhos", "it": "Processi Marini"},
    "Ecosystem Services": {"es": "Servicios Ecosistémicos", "fr": "Services Écosystémiques", "de": "Ökosystemleistungen", "lt": "Ekosistemos paslaugos", "pt": "Serviços Ecossistêmicos", "it": "Servizi Ecosistemici"},
    "Goods and Benefits": {"es": "Bienes y Beneficios", "fr": "Biens et Avantages", "de": "Güter und Vorteile", "lt": "Prekės ir nauda", "pt": "Bens e Benefícios", "it": "Beni e Benefici"},
    "Goods & Benefits": {"es": "Bienes y Beneficios", "fr": "Biens et Avantages", "de": "Güter und Vorteile", "lt": "Prekės ir nauda", "pt": "Bens e Benefícios", "it": "Beni e Benefici"},

    # Common Actions
    "Add": {"es": "Agregar", "fr": "Ajouter", "de": "Hinzufügen", "lt": "Pridėti", "pt": "Adicionar", "it": "Aggiungi"},
    "Save": {"es": "Guardar", "fr": "Enregistrer", "de": "Speichern", "lt": "Išsaugoti", "pt": "Salvar", "it": "Salva"},
    "Delete": {"es": "Eliminar", "fr": "Supprimer", "de": "Löschen", "lt": "Ištrinti", "pt": "Excluir", "it": "Elimina"},
    "Remove": {"es": "Quitar", "fr": "Retirer", "de": "Entfernen", "lt": "Pašalinti", "pt": "Remover", "it": "Rimuovi"},
    "Edit": {"es": "Editar", "fr": "Modifier", "de": "Bearbeiten", "lt": "Redaguoti", "pt": "Editar", "it": "Modifica"},
    "Cancel": {"es": "Cancelar", "fr": "Annuler", "de": "Abbrechen", "lt": "Atšaukti", "pt": "Cancelar", "it": "Annulla"},
    "Help": {"es": "Ayuda", "fr": "Aide", "de": "Hilfe", "lt": "Pagalba", "pt": "Ajuda", "it": "Aiuto"},
    "Exercise": {"es": "Ejercicio", "fr": "Exercice", "de": "Übung", "lt": "Pratimas", "pt": "Exercício", "it": "Esercizio"},

    # ISA Specific
    "Current": {"es": "Actual", "fr": "Actuel", "de": "Aktuell", "lt": "Dabartinis", "pt": "Atual", "it": "Attuale"},
    "Name": {"es": "Nombre", "fr": "Nom", "de": "Name", "lt": "Pavadinimas", "pt": "Nome", "it": "Nome"},
    "Description": {"es": "Descripción", "fr": "Description", "de": "Beschreibung", "lt": "Aprašymas", "pt": "Descrição", "it": "Descrizione"},
    "Category": {"es": "Categoría", "fr": "Catégorie", "de": "Kategorie", "lt": "Kategorija", "pt": "Categoria", "it": "Categoria"},
    "Type": {"es": "Tipo", "fr": "Type", "de": "Typ", "lt": "Tipas", "pt": "Tipo", "it": "Tipo"},
    "Indicator": {"es": "Indicador", "fr": "Indicateur", "de": "Indikator", "lt": "Rodiklis", "pt": "Indicador", "it": "Indicatore"},
    "Purpose": {"es": "Propósito", "fr": "Objectif", "de": "Zweck", "lt": "Tikslas", "pt": "Propósito", "it": "Scopo"},
    "Spatial Scale": {"es": "Escala Espacial", "fr": "Échelle Spatiale", "de": "Räumliche Skala", "lt": "Erdvinis mastas", "pt": "Escala Espacial", "it": "Scala Spaziale"},
    "Temporal Scale": {"es": "Escala Temporal", "fr": "Échelle Temporelle", "de": "Zeitliche Skala", "lt": "Laikinis mastas", "pt": "Escala Temporal", "it": "Scala Temporale"},
    "Data Point": {"es": "Punto de Datos", "fr": "Point de Données", "de": "Datenpunkt", "lt": "Duomenų taškas", "pt": "Ponto de Dados", "it": "Punto Dati"},
}

# Load existing translations
trans_path = Path("translations/translation.json")
with open(trans_path, 'r', encoding='utf-8') as f:
    existing_trans = json.load(f)

# Get existing English keys
existing_keys = {entry['en'] for entry in existing_trans['translation']}

# Read extracted strings
strings_path = Path("isa_translatable_strings.txt")
with open(strings_path, 'r', encoding='utf-8') as f:
    new_strings = [line.strip() for line in f if line.strip()]

# Filter out strings that already exist
new_strings_to_add = [s for s in new_strings if s not in existing_keys]

print(f"Total extracted: {len(new_strings)}")
print(f"Already translated: {len(new_strings) - len(new_strings_to_add)}")
print(f"New to translate: {len(new_strings_to_add)}")

# Generate translations for new strings
new_translations = []

for eng_text in new_strings_to_add:
    # Check if exact match in marine terms
    if eng_text in MARINE_TERMS:
        trans = MARINE_TERMS[eng_text]
        entry = {
            "en": eng_text,
            "es": trans["es"],
            "fr": trans["fr"],
            "de": trans["de"],
            "lt": trans["lt"],
            "pt": trans["pt"],
            "it": trans["it"]
        }
        new_translations.append(entry)
        print(f"[OK] {eng_text}")
    else:
        # Mark for manual translation
        print(f"[MANUAL] {eng_text}")

print(f"\nAuto-translated: {len(new_translations)} strings")
print(f"Need manual translation: {len(new_strings_to_add) - len(new_translations)} strings")

# Save new translations to separate file for review
output_path = Path("isa_new_translations.json")
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump({"translation": new_translations}, f, ensure_ascii=False, indent=2)

print(f"\nNew translations saved to: {output_path}")

# Create list of strings needing manual translation
manual_path = Path("isa_manual_translations_needed.txt")
manual_strings = [s for s in new_strings_to_add if s not in MARINE_TERMS]
with open(manual_path, 'w', encoding='utf-8') as f:
    for s in manual_strings:
        f.write(f"{s}\n")

print(f"Strings needing manual translation saved to: {manual_path}")
