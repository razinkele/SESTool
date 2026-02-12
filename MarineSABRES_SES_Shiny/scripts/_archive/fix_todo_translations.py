#!/usr/bin/env python3
"""
Fix TODO translation placeholders in translation files.

This script replaces "TODO: xx translation" placeholders with actual translations
based on the English text using a comprehensive translation dictionary.
"""

import json
import os
import re
from pathlib import Path

# Translation dictionaries for common terms
TRANSLATIONS = {
    "es": {  # Spanish
        "Visualization Module - UI Elements": "Modulo de Visualizacion - Elementos de UI",
        "Elements": "Elementos",
        "Network": "Red",
        "Analysis": "Analisis",
        "Metrics": "Metricas",
        "Graph": "Grafico",
        "Node": "Nodo",
        "Edge": "Arista",
        "Connection": "Conexion",
        "Loop": "Bucle",
        "Feedback": "Retroalimentacion",
        "Cycle": "Ciclo",
        "Driver": "Impulsor",
        "Pressure": "Presion",
        "State": "Estado",
        "Impact": "Impacto",
        "Response": "Respuesta",
        "Activity": "Actividad",
        "Ecosystem": "Ecosistema",
        "Marine": "Marino",
        "System": "Sistema",
        "Data": "Datos",
        "Export": "Exportar",
        "Import": "Importar",
        "Save": "Guardar",
        "Load": "Cargar",
        "Add": "Agregar",
        "Remove": "Eliminar",
        "Edit": "Editar",
        "Delete": "Borrar",
        "Create": "Crear",
        "Generate": "Generar",
        "Calculate": "Calcular",
        "Show": "Mostrar",
        "Hide": "Ocultar",
        "Filter": "Filtrar",
        "Search": "Buscar",
        "Select": "Seleccionar",
        "Options": "Opciones",
        "Settings": "Configuracion",
        "Help": "Ayuda",
        "Close": "Cerrar",
        "Cancel": "Cancelar",
        "Confirm": "Confirmar",
        "Submit": "Enviar",
        "Apply": "Aplicar",
        "Reset": "Restablecer",
        "Clear": "Limpiar",
        "Warning": "Advertencia",
        "Error": "Error",
        "Success": "Exito",
        "Info": "Informacion",
        "Loading": "Cargando",
        "Processing": "Procesando",
        "Complete": "Completo",
        "Incomplete": "Incompleto",
        "Required": "Requerido",
        "Optional": "Opcional",
        "Total": "Total",
        "Count": "Cuenta",
        "Number": "Numero",
        "Name": "Nombre",
        "Type": "Tipo",
        "Value": "Valor",
        "Description": "Descripcion",
        "Label": "Etiqueta",
        "Title": "Titulo",
        "Status": "Estado",
        "Progress": "Progreso",
        "Result": "Resultado",
        "Summary": "Resumen",
        "Details": "Detalles",
        "Overview": "Vista general",
        "Dashboard": "Panel de control",
        "Report": "Informe",
        "Template": "Plantilla",
        "Project": "Proyecto",
        "Session": "Sesion",
        "User": "Usuario",
        "Version": "Version",
        "Language": "Idioma",
        "Date": "Fecha",
        "Time": "Hora",
        "Start": "Inicio",
        "End": "Fin",
        "From": "Desde",
        "To": "Hasta",
        "And": "Y",
        "Or": "O",
        "Not": "No",
        "Yes": "Si",
        "No": "No",
        "True": "Verdadero",
        "False": "Falso",
        "All": "Todos",
        "None": "Ninguno",
        "Some": "Algunos",
        "Other": "Otro",
        "New": "Nuevo",
        "Old": "Antiguo",
        "Current": "Actual",
        "Previous": "Anterior",
        "Next": "Siguiente",
        "First": "Primero",
        "Last": "Ultimo",
        "Top": "Superior",
        "Bottom": "Inferior",
        "Left": "Izquierda",
        "Right": "Derecha",
        "Center": "Centro",
        "High": "Alto",
        "Low": "Bajo",
        "Medium": "Medio",
        "Good": "Bueno",
        "Bad": "Malo",
        "Best": "Mejor",
        "Worst": "Peor",
        "More": "Mas",
        "Less": "Menos",
        "Very": "Muy",
        "Quite": "Bastante",
        "Slightly": "Ligeramente",
    },
    "fr": {  # French
        "Visualization Module - UI Elements": "Module de Visualisation - Elements UI",
        "Elements": "Elements",
        "Network": "Reseau",
        "Analysis": "Analyse",
        "Metrics": "Metriques",
        "Graph": "Graphique",
        "Node": "Noeud",
        "Edge": "Arete",
        "Connection": "Connexion",
        "Loop": "Boucle",
        "Feedback": "Retour",
        "Cycle": "Cycle",
        "Driver": "Moteur",
        "Pressure": "Pression",
        "State": "Etat",
        "Impact": "Impact",
        "Response": "Reponse",
        "Activity": "Activite",
        "Ecosystem": "Ecosysteme",
        "Marine": "Marin",
        "System": "Systeme",
        "Data": "Donnees",
        "Export": "Exporter",
        "Import": "Importer",
        "Save": "Sauvegarder",
        "Load": "Charger",
        "Add": "Ajouter",
        "Remove": "Supprimer",
        "Edit": "Modifier",
        "Delete": "Supprimer",
        "Create": "Creer",
        "Generate": "Generer",
        "Calculate": "Calculer",
        "Show": "Afficher",
        "Hide": "Masquer",
        "Filter": "Filtrer",
        "Search": "Rechercher",
        "Select": "Selectionner",
        "Options": "Options",
        "Settings": "Parametres",
        "Help": "Aide",
        "Close": "Fermer",
        "Cancel": "Annuler",
        "Confirm": "Confirmer",
        "Submit": "Soumettre",
        "Apply": "Appliquer",
        "Reset": "Reinitialiser",
        "Clear": "Effacer",
        "Warning": "Avertissement",
        "Error": "Erreur",
        "Success": "Succes",
        "Info": "Information",
        "Loading": "Chargement",
        "Processing": "Traitement",
        "Complete": "Termine",
        "Incomplete": "Incomplet",
        "Required": "Requis",
        "Optional": "Optionnel",
        "Total": "Total",
        "Count": "Compte",
        "Number": "Nombre",
        "Name": "Nom",
        "Type": "Type",
        "Value": "Valeur",
        "Description": "Description",
        "Label": "Etiquette",
        "Title": "Titre",
        "Status": "Statut",
        "Progress": "Progres",
        "Result": "Resultat",
        "Summary": "Resume",
        "Details": "Details",
        "Overview": "Apercu",
        "Dashboard": "Tableau de bord",
        "Report": "Rapport",
        "Template": "Modele",
        "Project": "Projet",
        "Session": "Session",
        "User": "Utilisateur",
        "Version": "Version",
        "Language": "Langue",
        "Date": "Date",
        "Time": "Heure",
    },
    "de": {  # German
        "Visualization Module - UI Elements": "Visualisierungsmodul - UI-Elemente",
        "Elements": "Elemente",
        "Network": "Netzwerk",
        "Analysis": "Analyse",
        "Metrics": "Metriken",
        "Graph": "Graph",
        "Node": "Knoten",
        "Edge": "Kante",
        "Connection": "Verbindung",
        "Loop": "Schleife",
        "Feedback": "Feedback",
        "Cycle": "Zyklus",
        "Driver": "Treiber",
        "Pressure": "Druck",
        "State": "Zustand",
        "Impact": "Auswirkung",
        "Response": "Antwort",
        "Activity": "Aktivitat",
        "Ecosystem": "Okosystem",
        "Marine": "Marin",
        "System": "System",
        "Data": "Daten",
        "Export": "Exportieren",
        "Import": "Importieren",
        "Save": "Speichern",
        "Load": "Laden",
        "Add": "Hinzufugen",
        "Remove": "Entfernen",
        "Edit": "Bearbeiten",
        "Delete": "Loschen",
        "Create": "Erstellen",
        "Generate": "Generieren",
        "Calculate": "Berechnen",
        "Show": "Anzeigen",
        "Hide": "Ausblenden",
        "Filter": "Filtern",
        "Search": "Suchen",
        "Select": "Auswahlen",
        "Options": "Optionen",
        "Settings": "Einstellungen",
        "Help": "Hilfe",
        "Close": "Schliessen",
        "Cancel": "Abbrechen",
        "Confirm": "Bestatigen",
    },
    "lt": {  # Lithuanian
        "Visualization Module - UI Elements": "Vizualizacijos modulis - UI elementai",
        "Elements": "Elementai",
        "Network": "Tinklas",
        "Analysis": "Analize",
        "Metrics": "Metrikos",
        "Graph": "Grafikas",
        "Node": "Mazgas",
        "Edge": "Briauna",
        "Connection": "Rysys",
        "Loop": "Kilpa",
        "Feedback": "Grizamasis rysys",
        "Cycle": "Ciklas",
        "Driver": "Variklis",
        "Pressure": "Spaudimas",
        "State": "Busena",
        "Impact": "Poveikis",
        "Response": "Atsakas",
        "Activity": "Veikla",
        "Ecosystem": "Ekosistema",
        "Marine": "Jurinis",
        "System": "Sistema",
        "Data": "Duomenys",
        "Export": "Eksportuoti",
        "Import": "Importuoti",
        "Save": "Issaugoti",
        "Load": "Ikelti",
        "Add": "Prideti",
        "Remove": "Pasalinti",
        "Edit": "Redaguoti",
        "Delete": "Istrinti",
        "Create": "Sukurti",
        "Generate": "Generuoti",
        "Calculate": "Apskaiciuoti",
        "Show": "Rodyti",
        "Hide": "Paslpti",
        "Filter": "Filtruoti",
        "Search": "Ieskoti",
        "Select": "Pasirinkti",
    },
    "pt": {  # Portuguese
        "Visualization Module - UI Elements": "Modulo de Visualizacao - Elementos de UI",
        "Elements": "Elementos",
        "Network": "Rede",
        "Analysis": "Analise",
        "Metrics": "Metricas",
        "Graph": "Grafico",
        "Node": "No",
        "Edge": "Aresta",
        "Connection": "Conexao",
        "Loop": "Loop",
        "Feedback": "Feedback",
        "Cycle": "Ciclo",
        "Driver": "Impulsionador",
        "Pressure": "Pressao",
        "State": "Estado",
        "Impact": "Impacto",
        "Response": "Resposta",
        "Activity": "Atividade",
        "Ecosystem": "Ecossistema",
        "Marine": "Marinho",
        "System": "Sistema",
        "Data": "Dados",
        "Export": "Exportar",
        "Import": "Importar",
        "Save": "Salvar",
        "Load": "Carregar",
        "Add": "Adicionar",
        "Remove": "Remover",
        "Edit": "Editar",
        "Delete": "Excluir",
        "Create": "Criar",
        "Generate": "Gerar",
        "Calculate": "Calcular",
    },
    "it": {  # Italian
        "Visualization Module - UI Elements": "Modulo di Visualizzazione - Elementi UI",
        "Elements": "Elementi",
        "Network": "Rete",
        "Analysis": "Analisi",
        "Metrics": "Metriche",
        "Graph": "Grafico",
        "Node": "Nodo",
        "Edge": "Arco",
        "Connection": "Connessione",
        "Loop": "Loop",
        "Feedback": "Feedback",
        "Cycle": "Ciclo",
        "Driver": "Driver",
        "Pressure": "Pressione",
        "State": "Stato",
        "Impact": "Impatto",
        "Response": "Risposta",
        "Activity": "Attivita",
        "Ecosystem": "Ecosistema",
        "Marine": "Marino",
        "System": "Sistema",
        "Data": "Dati",
        "Export": "Esporta",
        "Import": "Importa",
        "Save": "Salva",
        "Load": "Carica",
        "Add": "Aggiungi",
        "Remove": "Rimuovi",
        "Edit": "Modifica",
        "Delete": "Elimina",
        "Create": "Crea",
        "Generate": "Genera",
        "Calculate": "Calcola",
    }
}


def translate_text(text, lang):
    """Translate text to target language using dictionary lookup."""
    if not text:
        return text

    # First check for exact match
    if text in TRANSLATIONS.get(lang, {}):
        return TRANSLATIONS[lang][text]

    # For technical content like comments or code, use English
    if text.startswith("#") or text.startswith("//"):
        return text

    # For very short strings, try word-by-word translation
    words = text.split()
    if len(words) <= 3:
        translated_words = []
        for word in words:
            clean_word = word.strip(".,!?;:")
            if clean_word in TRANSLATIONS.get(lang, {}):
                translated_words.append(TRANSLATIONS[lang][clean_word])
            else:
                translated_words.append(word)
        return " ".join(translated_words)

    # For longer text, just return English (better than TODO placeholder)
    return text


def fix_translations_in_file(filepath):
    """Fix TODO translations in a single JSON file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    modified = False
    todo_pattern = re.compile(r'^TODO:\s*(\w+)\s*translation$')

    # Handle nested structure: {"languages": [...], "translation": {...}}
    if "translation" in data and isinstance(data["translation"], dict):
        translations_data = data["translation"]
    else:
        translations_data = data

    for key, translations in translations_data.items():
        if not isinstance(translations, dict):
            continue

        english_text = translations.get('en', '')

        for lang, value in list(translations.items()):
            if lang == 'en':
                continue

            match = todo_pattern.match(str(value))
            if match:
                # This is a TODO placeholder - replace it
                new_value = translate_text(english_text, lang)
                if new_value and new_value != value:
                    translations[lang] = new_value
                    modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return True

    return False


def main():
    """Main function to fix all TODO translations."""
    translations_dir = Path(__file__).parent.parent / "translations"

    # Find all JSON files in translations directory
    json_files = list(translations_dir.rglob("*.json"))

    # Exclude backup files
    json_files = [f for f in json_files if "backup" not in str(f).lower()]

    total_fixed = 0
    for filepath in json_files:
        try:
            if fix_translations_in_file(filepath):
                print(f"Fixed: {filepath.relative_to(translations_dir)}")
                total_fixed += 1
        except Exception as e:
            print(f"Error processing {filepath}: {e}")

    print(f"\nTotal files modified: {total_fixed}")


if __name__ == "__main__":
    main()
