#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fix corrupted Portuguese and Italian translations while preserving
proper UTF-8 encoding for all other languages (ES, FR, DE)
"""

import json
import sys

# Translation fixes - ONLY pt and it
fixes = {
    "Select the environmental pressures, risks, or hazards you're concerned about. These represent 'Pressures' and 'State changes' in the DAPSI(W)R(M) framework.": {
        "pt": "Selecione as pressões ambientais, riscos ou perigos que o preocupam. Estes representam 'Pressões' e 'Mudanças de estado' no quadro DAPSI(W)R(M).",
        "it": "Seleziona le pressioni ambientali, i rischi o i pericoli che ti preoccupano. Questi rappresentano 'Pressioni' e 'Cambiamenti di stato' nel framework DAPSI(W)R(M)."
    },
    "Entry Point 4: Knowledge Domain": {
        "pt": "Ponto de Entrada 4: Domínio de Conhecimento",
        "it": "Punto di Ingresso 4: Ambito di Conoscenza"
    },
    "What topic areas are you interested in? (Select all that apply)": {
        "pt": "Que áreas temáticas lhe interessam? (Selecione todas as que se aplicam)",
        "it": "Quali aree tematiche ti interessano? (Seleziona tutte quelle applicabili)"
    },
    "Select the knowledge domains and analytical approaches relevant to your question. This helps match you with appropriate analysis tools and frameworks.": {
        "pt": "Selecione os domínios de conhecimento e abordagens analíticas relevantes para a sua questão. Isto ajuda a combiná-lo com ferramentas e quadros de análise apropriados.",
        "it": "Seleziona gli ambiti di conoscenza e gli approcci analitici rilevanti per la tua domanda. Questo aiuta a abbinarti con strumenti e framework di analisi appropriati."
    },
    "Get Recommendations": {
        "pt": "Obter Recomendações",
        "it": "Ottieni Raccomandazioni"
    },
    "Recommended Tools for Your Marine Management Question": {
        "pt": "Ferramentas Recomendadas para a Sua Questão de Gestão Marinha",
        "it": "Strumenti Raccomandati per la Tua Domanda di Gestione Marina"
    },
    "Your Pathway Summary": {
        "pt": "Resumo do Seu Percurso",
        "it": "Riepilogo del Tuo Percorso"
    },
    "Role:": {
        "pt": "Papel:",
        "it": "Ruolo:"
    },
    "Need:": {
        "pt": "Necessidade:",
        "it": "Necessità:"
    },
    "Risks:": {
        "pt": "Riscos:",
        "it": "Rischi:"
    },
    "Topics:": {
        "pt": "Tópicos:",
        "it": "Argomenti:"
    },
    "Recommended Workflow:": {
        "pt": "Fluxo de Trabalho Recomendado:",
        "it": "Flusso di Lavoro Raccomandato:"
    },
    "Follow this sequence of tools to address your marine management question:": {
        "pt": "Siga esta sequência de ferramentas para abordar a sua questão de gestão marinha:",
        "it": "Segui questa sequenza di strumenti per affrontare la tua domanda di gestione marina:"
    },
    "START HERE": {
        "pt": "COMEÇAR AQUI",
        "it": "INIZIA QUI"
    },
    "NEXT STEP": {
        "pt": "PRÓXIMO PASSO",
        "it": "PROSSIMO PASSO"
    },
    "ALSO RELEVANT": {
        "pt": "TAMBÉM RELEVANTE",
        "it": "ANCHE RILEVANTE"
    },
    "Skill:": {
        "pt": "Habilidade:",
        "it": "Abilità:"
    },
    "Suggested Workflow:": {
        "pt": "Fluxo de Trabalho Sugerido:",
        "it": "Flusso di Lavoro Suggerito:"
    },
    "Start with PIMS:": {
        "pt": "Começar com PIMS:",
        "it": "Inizia con PIMS:"
    },
    "Define your project goals, stakeholders, and timeline": {
        "pt": "Defina os objetivos do seu projeto, partes interessadas e cronograma",
        "it": "Definisci gli obiettivi del progetto, gli stakeholder e la timeline"
    },
    "Build your SES model:": {
        "pt": "Construa o seu modelo SES:",
        "it": "Costruisci il tuo modello SES:"
    },
    "Use ISA Data Entry to map DAPSI(W)R(M) elements": {
        "pt": "Use a Entrada de Dados ISA para mapear elementos DAPSI(W)R(M)",
        "it": "Usa l'Inserimento Dati ISA per mappare gli elementi DAPSI(W)R(M)"
    },
    "Visualize & Analyze:": {
        "pt": "Visualizar e Analisar:",
        "it": "Visualizza e Analizza:"
    },
    "Create CLD networks and run analysis tools": {
        "pt": "Crie redes CLD e execute ferramentas de análise",
        "it": "Crea reti CLD ed esegui strumenti di analisi"
    },
    "Refine & Communicate:": {
        "pt": "Refinar e Comunicar:",
        "it": "Raffinare e Comunicare:"
    },
    "Simplify models and develop management scenarios": {
        "pt": "Simplifique modelos e desenvolva cenários de gestão",
        "it": "Semplifica i modelli e sviluppa scenari di gestione"
    },
    "Start Over": {
        "pt": "Recomeçar",
        "it": "Ricomincia"
    },
    "Begin a new pathway from the welcome screen": {
        "pt": "Iniciar um novo percurso a partir do ecrã de boas-vindas",
        "it": "Inizia un nuovo percorso dalla schermata di benvenuto"
    },
    "Export Pathway Report": {
        "pt": "Exportar Relatório de Percurso",
        "it": "Esporta Rapporto Percorso"
    },
    "Download a PDF summary of your pathway and recommendations": {
        "pt": "Descarregue um resumo em PDF do seu percurso e recomendações",
        "it": "Scarica un riepilogo PDF del tuo percorso e delle raccomandazioni"
    },
    "Your Progress:": {
        "pt": "O Seu Progresso:",
        "it": "Il Tuo Progresso:"
    },
    "Welcome": {
        "pt": "Bem-vindo",
        "it": "Benvenuto"
    },
    "Language": {
        "pt": "Idioma",
        "it": "Lingua"
    },
    "Select Language": {
        "pt": "Selecionar Idioma",
        "it": "Seleziona Lingua"
    }
}

def main():
    file_path = "translations/translation.json"

    print("=== Fixing Portuguese and Italian translations ===")
    print("Reading file with proper UTF-8 encoding...")

    # Read with proper UTF-8
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    fixed_count = 0

    # Apply fixes
    for entry in data['translation']:
        en_text = entry.get('en', '')

        if en_text in fixes:
            entry['pt'] = fixes[en_text]['pt']
            entry['it'] = fixes[en_text]['it']
            fixed_count += 1
            print(f"Fixed: {en_text[:60]}...")

    print(f"\nFixed {fixed_count} entries")

    # Save with proper UTF-8 (no BOM)
    print("Saving with UTF-8 encoding (no BOM)...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    print("✓ Done! All encodings preserved correctly.")

if __name__ == '__main__':
    main()
