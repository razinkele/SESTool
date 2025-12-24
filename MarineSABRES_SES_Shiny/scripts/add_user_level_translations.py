#!/usr/bin/env python3
"""
Add user level translation keys to translation.json
"""

import json
import sys

# New translation keys to add
NEW_TRANSLATIONS = [
    {
        "en": "Settings",
        "es": "Configuración",
        "fr": "Paramètres",
        "de": "Einstellungen",
        "lt": "Nustatymai",
        "pt": "Configurações",
        "it": "Impostazioni"
    },
    {
        "en": "User Experience Level",
        "es": "Nivel de Experiencia del Usuario",
        "fr": "Niveau d'Expérience Utilisateur",
        "de": "Benutzererfahrungsstufe",
        "lt": "Naudotojo patirties lygis",
        "pt": "Nível de Experiência do Usuário",
        "it": "Livello di Esperienza Utente"
    },
    {
        "en": "Beginner",
        "es": "Principiante",
        "fr": "Débutant",
        "de": "Anfänger",
        "lt": "Pradedantysis",
        "pt": "Iniciante",
        "it": "Principiante"
    },
    {
        "en": "Intermediate",
        "es": "Intermedio",
        "fr": "Intermédiaire",
        "de": "Fortgeschritten",
        "lt": "Vidutinis",
        "pt": "Intermediário",
        "it": "Intermedio"
    },
    {
        "en": "Expert",
        "es": "Experto",
        "fr": "Expert",
        "de": "Experte",
        "lt": "Ekspertas",
        "pt": "Especialista",
        "it": "Esperto"
    },
    {
        "en": "Simplified interface for first-time users. Shows essential tools only.",
        "es": "Interfaz simplificada para nuevos usuarios. Muestra solo herramientas esenciales.",
        "fr": "Interface simplifiée pour les nouveaux utilisateurs. Affiche uniquement les outils essentiels.",
        "de": "Vereinfachte Benutzeroberfläche für Erstbenutzer. Zeigt nur wesentliche Werkzeuge.",
        "lt": "Supaprastinta sąsaja pradedantiesiems. Rodo tik esminius įrankius.",
        "pt": "Interface simplificada para novos usuários. Mostra apenas ferramentas essenciais.",
        "it": "Interfaccia semplificata per nuovi utenti. Mostra solo strumenti essenziali."
    },
    {
        "en": "Standard interface for regular users. Shows most tools and features.",
        "es": "Interfaz estándar para usuarios regulares. Muestra la mayoría de herramientas y funciones.",
        "fr": "Interface standard pour les utilisateurs réguliers. Affiche la plupart des outils et fonctionnalités.",
        "de": "Standardbenutzeroberfläche für regelmäßige Benutzer. Zeigt die meisten Werkzeuge und Funktionen.",
        "lt": "Standartinė sąsaja įprastiems naudotojams. Rodo daugumą įrankių ir funkcijų.",
        "pt": "Interface padrão para usuários regulares. Mostra a maioria das ferramentas e recursos.",
        "it": "Interfaccia standard per utenti abituali. Mostra la maggior parte degli strumenti e delle funzionalità."
    },
    {
        "en": "Advanced interface showing all tools, technical terminology, and advanced options.",
        "es": "Interfaz avanzada que muestra todas las herramientas, terminología técnica y opciones avanzadas.",
        "fr": "Interface avancée affichant tous les outils, la terminologie technique et les options avancées.",
        "de": "Erweiterte Benutzeroberfläche mit allen Werkzeugen, technischer Terminologie und erweiterten Optionen.",
        "lt": "Išplėstinė sąsaja, rodanti visus įrankius, techninę terminologiją ir išplėstines parinktis.",
        "pt": "Interface avançada mostrando todas as ferramentas, terminologia técnica e opções avançadas.",
        "it": "Interfaccia avanzata che mostra tutti gli strumenti, terminologia tecnica e opzioni avanzate."
    },
    {
        "en": "Select your experience level with marine ecosystem modeling:",
        "es": "Seleccione su nivel de experiencia con modelado de ecosistemas marinos:",
        "fr": "Sélectionnez votre niveau d'expérience avec la modélisation des écosystèmes marins:",
        "de": "Wählen Sie Ihre Erfahrungsstufe mit Meeresökosystemmodellierung:",
        "lt": "Pasirinkite savo patirties lygį su jūrų ekosistemų modeliavimu:",
        "pt": "Selecione seu nível de experiência com modelagem de ecossistemas marinhos:",
        "it": "Seleziona il tuo livello di esperienza con la modellazione degli ecosistemi marini:"
    },
    {
        "en": "The application will reload to apply the new user experience level.",
        "es": "La aplicación se recargará para aplicar el nuevo nivel de experiencia del usuario.",
        "fr": "L'application se rechargera pour appliquer le nouveau niveau d'expérience utilisateur.",
        "de": "Die Anwendung wird neu geladen, um die neue Benutzererfahrungsstufe anzuwenden.",
        "lt": "Programa bus perkrauta, kad būtų pritaikytas naujas naudotojo patirties lygis.",
        "pt": "A aplicação será recarregada para aplicar o novo nível de experiência do usuário.",
        "it": "L'applicazione si ricaricherà per applicare il nuovo livello di esperienza utente."
    }
]

def main():
    # Read existing translation file
    try:
        with open('translations/translation.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading translation file: {e}")
        sys.exit(1)

    # Add new translations
    if "translation" in data:
        for new_trans in NEW_TRANSLATIONS:
            data["translation"].append(new_trans)

        print(f"Added {len(NEW_TRANSLATIONS)} new translation entries")
        print(f"Total translations now: {len(data['translation'])}")
    else:
        print("Error: 'translation' key not found in JSON")
        sys.exit(1)

    # Write back to file with proper formatting
    try:
        with open('translations/translation.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("[OK] Translation file updated successfully")
    except Exception as e:
        print(f"Error writing translation file: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
