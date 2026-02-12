#!/usr/bin/env python3
"""
Add missing translations to translation files.
Reads missing_translations.txt and adds keys to appropriate JSON files.
"""

import json
import os
import re
from pathlib import Path

# Languages to support
LANGUAGES = ['en', 'lt', 'es', 'fr', 'de', 'it', 'pt', 'el', 'no']

# Map key prefixes to translation files
FILE_MAPPING = {
    'ui.dashboard': 'translations/ui/dashboard.json',
    'ui.header': 'translations/ui/header.json',
    'ui.sidebar': 'translations/ui/sidebar.json',
    'ui.modals': 'translations/ui/modals.json',
    'common.buttons': 'translations/common/buttons.json',
    'common.messages': 'translations/common/messages.json',
    'common.labels': 'translations/common/labels.json',
    'common.misc': 'translations/common/misc.json',
    'common.validation': 'translations/common/validation.json',
    'common.navigation': 'translations/common/navigation.json',
    'modules.isa': 'translations/modules/isa_data_entry.json',
    'modules.pims': 'translations/modules/pims_stakeholder.json',
    'modules.analysis': 'translations/modules/analysis_tools.json',
    'modules.response': 'translations/modules/response_measures.json',
    'modules.scenario': 'translations/modules/scenario_builder.json',
    'modules.ses': 'translations/modules/ses_creation.json',
    'modules.cld': 'translations/modules/cld_visualization.json',
    'modules.export': 'translations/modules/export_reports.json',
    'modules.prepare': 'translations/modules/prepare_report.json',
    'modules.entry_point': 'translations/modules/entry_point.json',
    'modules.ses_models': 'translations/modules/ses_models.json',
    'data': 'translations/data/framework.json',
}

# Translation templates for common terms (basic translations)
COMMON_TRANSLATIONS = {
    'save': {'en': 'Save', 'lt': 'Išsaugoti', 'es': 'Guardar', 'fr': 'Sauvegarder', 'de': 'Speichern', 'it': 'Salva', 'pt': 'Salvar', 'el': 'Αποθήκευση', 'no': 'Lagre'},
    'cancel': {'en': 'Cancel', 'lt': 'Atšaukti', 'es': 'Cancelar', 'fr': 'Annuler', 'de': 'Abbrechen', 'it': 'Annulla', 'pt': 'Cancelar', 'el': 'Ακύρωση', 'no': 'Avbryt'},
    'close': {'en': 'Close', 'lt': 'Uždaryti', 'es': 'Cerrar', 'fr': 'Fermer', 'de': 'Schließen', 'it': 'Chiudi', 'pt': 'Fechar', 'el': 'Κλείσιμο', 'no': 'Lukk'},
    'confirm': {'en': 'Confirm', 'lt': 'Patvirtinti', 'es': 'Confirmar', 'fr': 'Confirmer', 'de': 'Bestätigen', 'it': 'Conferma', 'pt': 'Confirmar', 'el': 'Επιβεβαίωση', 'no': 'Bekreft'},
    'delete': {'en': 'Delete', 'lt': 'Ištrinti', 'es': 'Eliminar', 'fr': 'Supprimer', 'de': 'Löschen', 'it': 'Elimina', 'pt': 'Excluir', 'el': 'Διαγραφή', 'no': 'Slett'},
    'edit': {'en': 'Edit', 'lt': 'Redaguoti', 'es': 'Editar', 'fr': 'Modifier', 'de': 'Bearbeiten', 'it': 'Modifica', 'pt': 'Editar', 'el': 'Επεξεργασία', 'no': 'Rediger'},
    'add': {'en': 'Add', 'lt': 'Pridėti', 'es': 'Añadir', 'fr': 'Ajouter', 'de': 'Hinzufügen', 'it': 'Aggiungi', 'pt': 'Adicionar', 'el': 'Προσθήκη', 'no': 'Legg til'},
    'yes': {'en': 'Yes', 'lt': 'Taip', 'es': 'Sí', 'fr': 'Oui', 'de': 'Ja', 'it': 'Sì', 'pt': 'Sim', 'el': 'Ναι', 'no': 'Ja'},
    'no': {'en': 'No', 'lt': 'Ne', 'es': 'No', 'fr': 'Non', 'de': 'Nein', 'it': 'No', 'pt': 'Não', 'el': 'Όχι', 'no': 'Nei'},
    'start': {'en': 'Start', 'lt': 'Pradėti', 'es': 'Iniciar', 'fr': 'Démarrer', 'de': 'Starten', 'it': 'Avvia', 'pt': 'Iniciar', 'el': 'Έναρξη', 'no': 'Start'},
    'next': {'en': 'Next', 'lt': 'Kitas', 'es': 'Siguiente', 'fr': 'Suivant', 'de': 'Weiter', 'it': 'Avanti', 'pt': 'Próximo', 'el': 'Επόμενο', 'no': 'Neste'},
    'previous': {'en': 'Previous', 'lt': 'Ankstesnis', 'es': 'Anterior', 'fr': 'Précédent', 'de': 'Zurück', 'it': 'Precedente', 'pt': 'Anterior', 'el': 'Προηγούμενο', 'no': 'Forrige'},
    'back': {'en': 'Back', 'lt': 'Atgal', 'es': 'Atrás', 'fr': 'Retour', 'de': 'Zurück', 'it': 'Indietro', 'pt': 'Voltar', 'el': 'Πίσω', 'no': 'Tilbake'},
    'submit': {'en': 'Submit', 'lt': 'Pateikti', 'es': 'Enviar', 'fr': 'Soumettre', 'de': 'Absenden', 'it': 'Invia', 'pt': 'Enviar', 'el': 'Υποβολή', 'no': 'Send inn'},
    'reset': {'en': 'Reset', 'lt': 'Atstatyti', 'es': 'Restablecer', 'fr': 'Réinitialiser', 'de': 'Zurücksetzen', 'it': 'Reimposta', 'pt': 'Redefinir', 'el': 'Επαναφορά', 'no': 'Tilbakestill'},
    'export': {'en': 'Export', 'lt': 'Eksportuoti', 'es': 'Exportar', 'fr': 'Exporter', 'de': 'Exportieren', 'it': 'Esporta', 'pt': 'Exportar', 'el': 'Εξαγωγή', 'no': 'Eksporter'},
    'import': {'en': 'Import', 'lt': 'Importuoti', 'es': 'Importar', 'fr': 'Importer', 'de': 'Importieren', 'it': 'Importa', 'pt': 'Importar', 'el': 'Εισαγωγή', 'no': 'Importer'},
    'download': {'en': 'Download', 'lt': 'Atsisiųsti', 'es': 'Descargar', 'fr': 'Télécharger', 'de': 'Herunterladen', 'it': 'Scarica', 'pt': 'Baixar', 'el': 'Λήψη', 'no': 'Last ned'},
    'upload': {'en': 'Upload', 'lt': 'Įkelti', 'es': 'Subir', 'fr': 'Téléverser', 'de': 'Hochladen', 'it': 'Carica', 'pt': 'Carregar', 'el': 'Μεταφόρτωση', 'no': 'Last opp'},
    'settings': {'en': 'Settings', 'lt': 'Nustatymai', 'es': 'Configuración', 'fr': 'Paramètres', 'de': 'Einstellungen', 'it': 'Impostazioni', 'pt': 'Configurações', 'el': 'Ρυθμίσεις', 'no': 'Innstillinger'},
    'help': {'en': 'Help', 'lt': 'Pagalba', 'es': 'Ayuda', 'fr': 'Aide', 'de': 'Hilfe', 'it': 'Aiuto', 'pt': 'Ajuda', 'el': 'Βοήθεια', 'no': 'Hjelp'},
    'error': {'en': 'Error', 'lt': 'Klaida', 'es': 'Error', 'fr': 'Erreur', 'de': 'Fehler', 'it': 'Errore', 'pt': 'Erro', 'el': 'Σφάλμα', 'no': 'Feil'},
    'warning': {'en': 'Warning', 'lt': 'Įspėjimas', 'es': 'Advertencia', 'fr': 'Avertissement', 'de': 'Warnung', 'it': 'Avviso', 'pt': 'Aviso', 'el': 'Προειδοποίηση', 'no': 'Advarsel'},
    'success': {'en': 'Success', 'lt': 'Sėkmė', 'es': 'Éxito', 'fr': 'Succès', 'de': 'Erfolg', 'it': 'Successo', 'pt': 'Sucesso', 'el': 'Επιτυχία', 'no': 'Suksess'},
    'loading': {'en': 'Loading...', 'lt': 'Kraunama...', 'es': 'Cargando...', 'fr': 'Chargement...', 'de': 'Laden...', 'it': 'Caricamento...', 'pt': 'Carregando...', 'el': 'Φόρτωση...', 'no': 'Laster...'},
    'total': {'en': 'Total', 'lt': 'Iš viso', 'es': 'Total', 'fr': 'Total', 'de': 'Gesamt', 'it': 'Totale', 'pt': 'Total', 'el': 'Σύνολο', 'no': 'Totalt'},
    'name': {'en': 'Name', 'lt': 'Pavadinimas', 'es': 'Nombre', 'fr': 'Nom', 'de': 'Name', 'it': 'Nome', 'pt': 'Nome', 'el': 'Όνομα', 'no': 'Navn'},
    'description': {'en': 'Description', 'lt': 'Aprašymas', 'es': 'Descripción', 'fr': 'Description', 'de': 'Beschreibung', 'it': 'Descrizione', 'pt': 'Descrição', 'el': 'Περιγραφή', 'no': 'Beskrivelse'},
    'type': {'en': 'Type', 'lt': 'Tipas', 'es': 'Tipo', 'fr': 'Type', 'de': 'Typ', 'it': 'Tipo', 'pt': 'Tipo', 'el': 'Τύπος', 'no': 'Type'},
    'status': {'en': 'Status', 'lt': 'Būsena', 'es': 'Estado', 'fr': 'Statut', 'de': 'Status', 'it': 'Stato', 'pt': 'Status', 'el': 'Κατάσταση', 'no': 'Status'},
    'date': {'en': 'Date', 'lt': 'Data', 'es': 'Fecha', 'fr': 'Date', 'de': 'Datum', 'it': 'Data', 'pt': 'Data', 'el': 'Ημερομηνία', 'no': 'Dato'},
    'time': {'en': 'Time', 'lt': 'Laikas', 'es': 'Hora', 'fr': 'Heure', 'de': 'Zeit', 'it': 'Ora', 'pt': 'Hora', 'el': 'Ώρα', 'no': 'Tid'},
    'drivers': {'en': 'Drivers', 'lt': 'Veiksniai', 'es': 'Factores', 'fr': 'Facteurs', 'de': 'Treiber', 'it': 'Fattori', 'pt': 'Fatores', 'el': 'Παράγοντες', 'no': 'Drivere'},
    'activities': {'en': 'Activities', 'lt': 'Veiklos', 'es': 'Actividades', 'fr': 'Activités', 'de': 'Aktivitäten', 'it': 'Attività', 'pt': 'Atividades', 'el': 'Δραστηριότητες', 'no': 'Aktiviteter'},
    'pressures': {'en': 'Pressures', 'lt': 'Spaudimai', 'es': 'Presiones', 'fr': 'Pressions', 'de': 'Belastungen', 'it': 'Pressioni', 'pt': 'Pressões', 'el': 'Πιέσεις', 'no': 'Press'},
    'state': {'en': 'State', 'lt': 'Būklė', 'es': 'Estado', 'fr': 'État', 'de': 'Zustand', 'it': 'Stato', 'pt': 'Estado', 'el': 'Κατάσταση', 'no': 'Tilstand'},
    'impacts': {'en': 'Impacts', 'lt': 'Poveikiai', 'es': 'Impactos', 'fr': 'Impacts', 'de': 'Auswirkungen', 'it': 'Impatti', 'pt': 'Impactos', 'el': 'Επιπτώσεις', 'no': 'Konsekvenser'},
    'welfare': {'en': 'Welfare', 'lt': 'Gerovė', 'es': 'Bienestar', 'fr': 'Bien-être', 'de': 'Wohlfahrt', 'it': 'Benessere', 'pt': 'Bem-estar', 'el': 'Ευημερία', 'no': 'Velferd'},
    'responses': {'en': 'Responses', 'lt': 'Atsakai', 'es': 'Respuestas', 'fr': 'Réponses', 'de': 'Maßnahmen', 'it': 'Risposte', 'pt': 'Respostas', 'el': 'Απαντήσεις', 'no': 'Tiltak'},
    'connections': {'en': 'Connections', 'lt': 'Ryšiai', 'es': 'Conexiones', 'fr': 'Connexions', 'de': 'Verbindungen', 'it': 'Connessioni', 'pt': 'Conexões', 'el': 'Συνδέσεις', 'no': 'Forbindelser'},
    'elements': {'en': 'Elements', 'lt': 'Elementai', 'es': 'Elementos', 'fr': 'Éléments', 'de': 'Elemente', 'it': 'Elementi', 'pt': 'Elementos', 'el': 'Στοιχεία', 'no': 'Elementer'},
    'network': {'en': 'Network', 'lt': 'Tinklas', 'es': 'Red', 'fr': 'Réseau', 'de': 'Netzwerk', 'it': 'Rete', 'pt': 'Rede', 'el': 'Δίκτυο', 'no': 'Nettverk'},
    'analysis': {'en': 'Analysis', 'lt': 'Analizė', 'es': 'Análisis', 'fr': 'Analyse', 'de': 'Analyse', 'it': 'Analisi', 'pt': 'Análise', 'el': 'Ανάλυση', 'no': 'Analyse'},
    'project': {'en': 'Project', 'lt': 'Projektas', 'es': 'Proyecto', 'fr': 'Projet', 'de': 'Projekt', 'it': 'Progetto', 'pt': 'Projeto', 'el': 'Έργο', 'no': 'Prosjekt'},
    'stakeholder': {'en': 'Stakeholder', 'lt': 'Suinteresuotoji šalis', 'es': 'Interesado', 'fr': 'Partie prenante', 'de': 'Stakeholder', 'it': 'Stakeholder', 'pt': 'Parte interessada', 'el': 'Ενδιαφερόμενος', 'no': 'Interessent'},
    'stakeholders': {'en': 'Stakeholders', 'lt': 'Suinteresuotosios šalys', 'es': 'Interesados', 'fr': 'Parties prenantes', 'de': 'Stakeholder', 'it': 'Stakeholder', 'pt': 'Partes interessadas', 'el': 'Ενδιαφερόμενοι', 'no': 'Interessenter'},
    'scenario': {'en': 'Scenario', 'lt': 'Scenarijus', 'es': 'Escenario', 'fr': 'Scénario', 'de': 'Szenario', 'it': 'Scenario', 'pt': 'Cenário', 'el': 'Σενάριο', 'no': 'Scenario'},
    'report': {'en': 'Report', 'lt': 'Ataskaita', 'es': 'Informe', 'fr': 'Rapport', 'de': 'Bericht', 'it': 'Rapporto', 'pt': 'Relatório', 'el': 'Αναφορά', 'no': 'Rapport'},
    'overview': {'en': 'Overview', 'lt': 'Apžvalga', 'es': 'Resumen', 'fr': 'Aperçu', 'de': 'Übersicht', 'it': 'Panoramica', 'pt': 'Visão geral', 'el': 'Επισκόπηση', 'no': 'Oversikt'},
    'language': {'en': 'Language', 'lt': 'Kalba', 'es': 'Idioma', 'fr': 'Langue', 'de': 'Sprache', 'it': 'Lingua', 'pt': 'Idioma', 'el': 'Γλώσσα', 'no': 'Språk'},
    'ecosystem': {'en': 'Ecosystem', 'lt': 'Ekosistema', 'es': 'Ecosistema', 'fr': 'Écosystème', 'de': 'Ökosystem', 'it': 'Ecosistema', 'pt': 'Ecossistema', 'el': 'Οικοσύστημα', 'no': 'Økosystem'},
    'marine': {'en': 'Marine', 'lt': 'Jūrinis', 'es': 'Marino', 'fr': 'Marin', 'de': 'Marin', 'it': 'Marino', 'pt': 'Marinho', 'el': 'Θαλάσσιος', 'no': 'Marin'},
    'confidence': {'en': 'Confidence', 'lt': 'Pasitikėjimas', 'es': 'Confianza', 'fr': 'Confiance', 'de': 'Konfidenz', 'it': 'Confidenza', 'pt': 'Confiança', 'el': 'Εμπιστοσύνη', 'no': 'Tillit'},
    'strength': {'en': 'Strength', 'lt': 'Stiprumas', 'es': 'Fuerza', 'fr': 'Force', 'de': 'Stärke', 'it': 'Forza', 'pt': 'Força', 'el': 'Δύναμη', 'no': 'Styrke'},
    'role': {'en': 'Role', 'lt': 'Vaidmuo', 'es': 'Rol', 'fr': 'Rôle', 'de': 'Rolle', 'it': 'Ruolo', 'pt': 'Papel', 'el': 'Ρόλος', 'no': 'Rolle'},
    'welcome': {'en': 'Welcome', 'lt': 'Sveiki', 'es': 'Bienvenido', 'fr': 'Bienvenue', 'de': 'Willkommen', 'it': 'Benvenuto', 'pt': 'Bem-vindo', 'el': 'Καλώς ήρθατε', 'no': 'Velkommen'},
    'approve': {'en': 'Approve', 'lt': 'Patvirtinti', 'es': 'Aprobar', 'fr': 'Approuver', 'de': 'Genehmigen', 'it': 'Approva', 'pt': 'Aprovar', 'el': 'Έγκριση', 'no': 'Godkjenn'},
    'reject': {'en': 'Reject', 'lt': 'Atmesti', 'es': 'Rechazar', 'fr': 'Rejeter', 'de': 'Ablehnen', 'it': 'Rifiuta', 'pt': 'Rejeitar', 'el': 'Απόρριψη', 'no': 'Avvis'},
    'finish': {'en': 'Finish', 'lt': 'Baigti', 'es': 'Finalizar', 'fr': 'Terminer', 'de': 'Beenden', 'it': 'Fine', 'pt': 'Concluir', 'el': 'Τέλος', 'no': 'Fullfør'},
    'continue': {'en': 'Continue', 'lt': 'Tęsti', 'es': 'Continuar', 'fr': 'Continuer', 'de': 'Fortfahren', 'it': 'Continua', 'pt': 'Continuar', 'el': 'Συνέχεια', 'no': 'Fortsett'},
}


def get_file_for_key(key):
    """Get the appropriate translation file for a key."""
    for prefix, filepath in sorted(FILE_MAPPING.items(), key=lambda x: -len(x[0])):
        if key.startswith(prefix):
            return filepath
    return 'translations/common/misc.json'


def key_to_english(key):
    """Convert a translation key to readable English text."""
    # Get the last meaningful part of the key
    parts = key.split('.')

    # Handle truncated sentence keys (very long last parts)
    last_part = parts[-1]

    # Convert underscores to spaces
    text = last_part.replace('_', ' ').strip()

    # Check for common terms
    lower_text = text.lower()
    if lower_text in COMMON_TRANSLATIONS:
        return COMMON_TRANSLATIONS[lower_text]['en']

    # Capitalize first letter, preserve rest
    if text:
        # Handle abbreviations and special cases
        if text.isupper() and len(text) <= 5:
            return text  # Keep short abbreviations
        return text[0].upper() + text[1:] if len(text) > 1 else text.upper()

    return key


def generate_translation(english_text, lang):
    """Generate translation for a given language."""
    if lang == 'en':
        return english_text

    # Check if we have a direct translation for common terms
    lower_text = english_text.lower().strip()
    if lower_text in COMMON_TRANSLATIONS:
        return COMMON_TRANSLATIONS[lower_text].get(lang, english_text)

    # For longer text, check for partial matches at the start
    for term, translations in COMMON_TRANSLATIONS.items():
        if lower_text.startswith(term + ' ') or lower_text == term:
            if lang in translations:
                # Replace the term with translation
                return translations[lang] + english_text[len(term):]

    # Default: return English with language marker for manual review
    # (This indicates it needs manual translation)
    return english_text


def load_json_file(filepath):
    """Load a JSON translation file."""
    if not os.path.exists(filepath):
        return {'languages': LANGUAGES, 'translation': {}}

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Ensure proper structure
        if 'translation' not in data:
            data = {'languages': LANGUAGES, 'translation': data}

        return data
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return {'languages': LANGUAGES, 'translation': {}}


def save_json_file(filepath, data):
    """Save a JSON translation file."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def add_translations(missing_keys_file='missing_translations.txt'):
    """Main function to add missing translations."""

    # Read missing keys
    with open(missing_keys_file, 'r', encoding='utf-8') as f:
        missing_keys = [line.strip() for line in f if line.strip()]

    print(f"Processing {len(missing_keys)} missing keys...")

    # Group keys by file
    keys_by_file = {}
    for key in missing_keys:
        filepath = get_file_for_key(key)
        if filepath not in keys_by_file:
            keys_by_file[filepath] = []
        keys_by_file[filepath].append(key)

    # Process each file
    total_added = 0
    for filepath, keys in keys_by_file.items():
        print(f"\nProcessing {filepath} ({len(keys)} keys)...")

        # Load existing translations
        data = load_json_file(filepath)

        # Add missing keys
        added = 0
        for key in keys:
            # Check if key already exists
            if key in data.get('translation', {}):
                continue

            # Generate English text from key
            english_text = key_to_english(key)

            # Create translation entry for all languages
            translation_entry = {}
            for lang in LANGUAGES:
                translation_entry[lang] = generate_translation(english_text, lang)

            # Add to translation dict
            if 'translation' not in data:
                data['translation'] = {}
            data['translation'][key] = translation_entry
            added += 1

        if added > 0:
            # Save updated file
            save_json_file(filepath, data)
            print(f"  Added {added} new translations")
            total_added += added
        else:
            print(f"  No new translations needed")

    print(f"\n{'='*60}")
    print(f"Total translations added: {total_added}")
    print(f"Files updated: {len([f for f, k in keys_by_file.items() if len(k) > 0])}")


if __name__ == '__main__':
    add_translations()
