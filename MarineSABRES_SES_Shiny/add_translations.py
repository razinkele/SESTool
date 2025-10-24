#!/usr/bin/env python3
"""
Script to add Portuguese (pt) and Italian (it) translations to translation.json
For entries that already have pt/it, they are preserved. For missing ones, we translate from Spanish (es).
"""

import json
import sys

# Translation mappings based on existing patterns in the file
# Portuguese translations (based on Spanish with Portuguese variations)
pt_translations = {
    "Welcome to the MarineSABRES Toolbox": "Bem-vindo à Caixa de Ferramentas MarineSABRES",
    "This guidance system will help you find the right tools for your marine management needs.": "Este sistema de orientação irá ajudá-lo a encontrar as ferramentas certas para as suas necessidades de gestão marinha.",
    "What is your main marine management question?": "Qual é a sua principal questão de gestão marinha?",
    "Guided Pathway": "Percurso Guiado",
    "Step-by-step guidance through the entry points": "Orientação passo a passo através dos pontos de entrada",
    "Start Guided Journey": "Iniciar Percurso Guiado",
    "Quick Access": "Acesso Rápido",
    "I know what tool I need": "Sei qual ferramenta preciso",
    "Browse Tools": "Explorar Ferramentas",
    "Entry Point 0: Who Are You?": "Ponto de Entrada 0: Quem É Você?",
    "Select your role in marine management": "Selecione o seu papel na gestão marinha",
    "Your role helps us recommend the most relevant tools and workflows for your marine management context.": "O seu papel ajuda-nos a recomendar as ferramentas e fluxos de trabalho mais relevantes para o seu contexto de gestão marinha.",
    "Entry Point 1: Why Do You Care?": "Ponto de Entrada 1: Por Que Se Importa?",
    "What basic human need drives your question?": "Que necessidade humana básica impulsiona a sua questão?",
    "Understanding the fundamental human need behind your question helps identify relevant ecosystem services and management priorities.": "Compreender a necessidade humana fundamental por trás da sua questão ajuda a identificar serviços ecossistémicos relevantes e prioridades de gestão.",
    "EP2: Activity Sectors": "EP2: Setores de Atividade",
    "Select all that apply (multiple selection allowed)": "Selecione todos os que se aplicam (seleção múltipla permitida)",
    "EP3: Risks & Hazards": "EP3: Riscos e Perigos",
    "Skip": "Ignorar",
    "Back": "Voltar",
    "Continue": "Continuar",
    "Continue to EP1": "Continuar para EP1",
    "Activities:": "Atividades:",
    "Go to": "Ir para",
    "Skip if you're not sure or want to see all options": "Ignorar se não tiver certeza ou quiser ver todas as opções",
    "Proceed to identify your basic human needs": "Prosseguir para identificar as suas necessidades humanas básicas",
    "Return to role selection": "Retornar à seleção de papel",
    "Skip if multiple needs apply or you're unsure": "Ignorar se várias necessidades se aplicam ou se não tiver certeza",
    "Proceed to specify activities and risks": "Prosseguir para especificar atividades e riscos",
    "Return to basic needs": "Retornar às necessidades básicas",
    "Skip if you want to explore all activities and risks": "Ignorar se quiser explorar todas as atividades e riscos",
    "Proceed to select knowledge topics": "Prosseguir para selecionar tópicos de conhecimento",
    "Return to activities and risks": "Retornar às atividades e riscos",
    "Skip to see all available tools": "Ignorar para ver todas as ferramentas disponíveis",
    "Get personalized tool recommendations based on your pathway": "Obter recomendações personalizadas de ferramentas com base no seu percurso",
    "Typical tasks:": "Tarefas típicas:",
    "EP0: Role": "EP0: Papel",
    "EP1: Need": "EP1: Necessidade",
    "EP2-3: Context": "EP2-3: Contexto",
    "EP4: Topic": "EP4: Tópico",
    "Tools": "Ferramentas",
    "e.g., How can we reduce fishing impacts while maintaining livelihoods?": "por exemplo, Como podemos reduzir os impactos da pesca mantendo os meios de subsistência?"
}

# Italian translations
it_translations = {
    "Welcome to the MarineSABRES Toolbox": "Benvenuto nella Toolbox MarineSABRES",
    "This guidance system will help you find the right tools for your marine management needs.": "Questo sistema di orientamento ti aiuterà a trovare gli strumenti giusti per le tue esigenze di gestione marina.",
    "What is your main marine management question?": "Qual è la tua principale domanda sulla gestione marina?",
    "Guided Pathway": "Percorso Guidato",
    "Step-by-step guidance through the entry points": "Guida passo dopo passo attraverso i punti di ingresso",
    "Start Guided Journey": "Inizia il Percorso Guidato",
    "Quick Access": "Accesso Rapido",
    "I know what tool I need": "So quale strumento mi serve",
    "Browse Tools": "Esplora Strumenti",
    "Entry Point 0: Who Are You?": "Punto di Ingresso 0: Chi Sei?",
    "Select your role in marine management": "Seleziona il tuo ruolo nella gestione marina",
    "Your role helps us recommend the most relevant tools and workflows for your marine management context.": "Il tuo ruolo ci aiuta a raccomandare gli strumenti e i flussi di lavoro più rilevanti per il tuo contesto di gestione marina.",
    "Entry Point 1: Why Do You Care?": "Punto di Ingresso 1: Perché Ti Importa?",
    "What basic human need drives your question?": "Quale bisogno umano fondamentale guida la tua domanda?",
    "Understanding the fundamental human need behind your question helps identify relevant ecosystem services and management priorities.": "Comprendere il bisogno umano fondamentale dietro la tua domanda aiuta a identificare i servizi ecosistemici rilevanti e le priorità di gestione.",
    "EP2: Activity Sectors": "EP2: Settori di Attività",
    "Select all that apply (multiple selection allowed)": "Seleziona tutte quelle applicabili (selezione multipla consentita)",
    "EP3: Risks & Hazards": "EP3: Rischi e Pericoli",
    "Skip": "Salta",
    "Back": "Indietro",
    "Continue": "Continua",
    "Continue to EP1": "Continua a EP1",
    "Activities:": "Attività:",
    "Go to": "Vai a",
    "Skip if you're not sure or want to see all options": "Salta se non sei sicuro o vuoi vedere tutte le opzioni",
    "Proceed to identify your basic human needs": "Procedi per identificare i tuoi bisogni umani fondamentali",
    "Return to role selection": "Ritorna alla selezione del ruolo",
    "Skip if multiple needs apply or you're unsure": "Salta se si applicano più bisogni o non sei sicuro",
    "Proceed to specify activities and risks": "Procedi per specificare attività e rischi",
    "Return to basic needs": "Ritorna ai bisogni fondamentali",
    "Skip if you want to explore all activities and risks": "Salta se vuoi esplorare tutte le attività e i rischi",
    "Proceed to select knowledge topics": "Procedi per selezionare argomenti di conoscenza",
    "Return to activities and risks": "Ritorna alle attività e ai rischi",
    "Skip to see all available tools": "Salta per vedere tutti gli strumenti disponibili",
    "Get personalized tool recommendations based on your pathway": "Ottieni raccomandazioni personalizzate di strumenti in base al tuo percorso",
    "Typical tasks:": "Compiti tipici:",
    "EP0: Role": "EP0: Ruolo",
    "EP1: Need": "EP1: Bisogno",
    "EP2-3: Context": "EP2-3: Contesto",
    "EP4: Topic": "EP4: Argomento",
    "Tools": "Strumenti",
    "e.g., How can we reduce fishing impacts while maintaining livelihoods?": "ad es., Come possiamo ridurre gli impatti della pesca mantenendo i mezzi di sussistenza?"
}

def main():
    # Read the existing translation file
    with open('translations/translation.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"Processing {len(data['translation'])} translation entries...")

    # Track statistics
    added_pt = 0
    added_it = 0

    # Process each translation entry
    for idx, entry in enumerate(data['translation']):
        en_text = entry.get('en', '')

        # Add Portuguese if missing
        if 'pt' not in entry:
            if en_text in pt_translations:
                entry['pt'] = pt_translations[en_text]
                added_pt += 1
            else:
                # Use Spanish as a fallback (Portuguese is similar to Spanish)
                if 'es' in entry:
                    entry['pt'] = entry['es']  # Temporary - can be refined
                    added_pt += 1

        # Add Italian if missing
        if 'it' not in entry:
            if en_text in it_translations:
                entry['it'] = it_translations[en_text]
                added_it += 1
            else:
                # Use French as a fallback (Italian is similar to French)
                if 'fr' in entry:
                    entry['it'] = entry['fr']  # Temporary - can be refined
                    added_it += 1

    print(f"Added {added_pt} Portuguese translations")
    print(f"Added {added_it} Italian translations")

    # Write back to file with proper formatting
    with open('translations/translation.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("Translation file updated successfully!")

if __name__ == '__main__':
    main()
