# Fix all 26 remaining corrupted Portuguese and Italian translations
# Replaces Lithuanian text with proper PT and IT translations

$translationFile = "translations\translation.json"

# Read JSON
$json = Get-Content $translationFile -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "=== Fixing All 26 Corrupted Translations ==="
Write-Host ""

# Map of English text to correct PT and IT translations
$fixes = @{
    "Select the environmental pressures, risks, or hazards you're concerned about. These represent 'Pressures' and 'State changes' in the DAPSI(W)R(M) framework." = @{
        pt = "Selecione as pressoes ambientais, riscos ou perigos que o preocupam. Estes representam 'Pressoes' e 'Mudancas de estado' no quadro DAPSI(W)R(M)."
        it = "Seleziona le pressioni ambientali, i rischi o i pericoli che ti preoccupano. Questi rappresentano 'Pressioni' e 'Cambiamenti di stato' nel framework DAPSI(W)R(M)."
    }
    "Entry Point 4: Knowledge Domain" = @{
        pt = "Ponto de Entrada 4: Dominio de Conhecimento"
        it = "Punto di Ingresso 4: Ambito di Conoscenza"
    }
    "What topic areas are you interested in? (Select all that apply)" = @{
        pt = "Que areas tematicas lhe interessam? (Selecione todas as que se aplicam)"
        it = "Quali aree tematiche ti interessano? (Seleziona tutte quelle applicabili)"
    }
    "Select the knowledge domains and analytical approaches relevant to your question. This helps match you with appropriate analysis tools and frameworks." = @{
        pt = "Selecione os dominios de conhecimento e abordagens analiticas relevantes para a sua questao. Isto ajuda a combina-lo com ferramentas e quadros de analise apropriados."
        it = "Seleziona gli ambiti di conoscenza e gli approcci analitici rilevanti per la tua domanda. Questo aiuta a abbinarti con strumenti e framework di analisi appropriati."
    }
    "Get Recommendations" = @{
        pt = "Obter Recomendacoes"
        it = "Ottieni Raccomandazioni"
    }
    "Recommended Tools for Your Marine Management Question" = @{
        pt = "Ferramentas Recomendadas para a Sua Questao de Gestao Marinha"
        it = "Strumenti Raccomandati per la Tua Domanda di Gestione Marina"
    }
    "Your Pathway Summary" = @{
        pt = "Resumo do Seu Percurso"
        it = "Riepilogo del Tuo Percorso"
    }
    "Role:" = @{
        pt = "Papel:"
        it = "Ruolo:"
    }
    "Need:" = @{
        pt = "Necessidade:"
        it = "Necessita:"
    }
    "Risks:" = @{
        pt = "Riscos:"
        it = "Rischi:"
    }
    "Topics:" = @{
        pt = "Topicos:"
        it = "Argomenti:"
    }
    "Recommended Workflow:" = @{
        pt = "Fluxo de Trabalho Recomendado:"
        it = "Flusso di Lavoro Raccomandato:"
    }
    "Follow this sequence of tools to address your marine management question:" = @{
        pt = "Siga esta sequencia de ferramentas para abordar a sua questao de gestao marinha:"
        it = "Segui questa sequenza di strumenti per affrontare la tua domanda di gestione marina:"
    }
    "START HERE" = @{
        pt = "COMECAR AQUI"
        it = "INIZIA QUI"
    }
    "NEXT STEP" = @{
        pt = "PROXIMO PASSO"
        it = "PROSSIMO PASSO"
    }
    "ALSO RELEVANT" = @{
        pt = "TAMBEM RELEVANTE"
        it = "ANCHE RILEVANTE"
    }
    "Skill:" = @{
        pt = "Habilidade:"
        it = "Abilita:"
    }
    "Suggested Workflow:" = @{
        pt = "Fluxo de Trabalho Sugerido:"
        it = "Flusso di Lavoro Suggerito:"
    }
    "Start with PIMS:" = @{
        pt = "Comecar com PIMS:"
        it = "Inizia con PIMS:"
    }
    "Define your project goals, stakeholders, and timeline" = @{
        pt = "Defina os objetivos do seu projeto, partes interessadas e cronograma"
        it = "Definisci gli obiettivi del progetto, gli stakeholder e la timeline"
    }
    "Build your SES model:" = @{
        pt = "Construa o seu modelo SES:"
        it = "Costruisci il tuo modello SES:"
    }
    "Use ISA Data Entry to map DAPSI(W)R(M) elements" = @{
        pt = "Use a Entrada de Dados ISA para mapear elementos DAPSI(W)R(M)"
        it = "Usa l'Inserimento Dati ISA per mappare gli elementi DAPSI(W)R(M)"
    }
    "Visualize & Analyze:" = @{
        pt = "Visualizar e Analisar:"
        it = "Visualizza e Analizza:"
    }
    "Create CLD networks and run analysis tools" = @{
        pt = "Crie redes CLD e execute ferramentas de analise"
        it = "Crea reti CLD ed esegui strumenti di analisi"
    }
    "Refine & Communicate:" = @{
        pt = "Refinar e Comunicar:"
        it = "Raffinare e Comunicare:"
    }
    "Simplify models and develop management scenarios" = @{
        pt = "Simplifique modelos e desenvolva cenarios de gestao"
        it = "Semplifica i modelli e sviluppa scenari di gestione"
    }
    "Start Over" = @{
        pt = "Recomecar"
        it = "Ricomincia"
    }
    "Begin a new pathway from the welcome screen" = @{
        pt = "Iniciar um novo percurso a partir do ecra de boas-vindas"
        it = "Inizia un nuovo percorso dalla schermata di benvenuto"
    }
    "Export Pathway Report" = @{
        pt = "Exportar Relatorio de Percurso"
        it = "Esporta Rapporto Percorso"
    }
    "Download a PDF summary of your pathway and recommendations" = @{
        pt = "Descarregue um resumo em PDF do seu percurso e recomendacoes"
        it = "Scarica un riepilogo PDF del tuo percorso e delle raccomandazioni"
    }
    "Your Progress:" = @{
        pt = "O Seu Progresso:"
        it = "Il Tuo Progresso:"
    }
    "Welcome" = @{
        pt = "Bem-vindo"
        it = "Benvenuto"
    }
    "Language" = @{
        pt = "Idioma"
        it = "Lingua"
    }
    "Select Language" = @{
        pt = "Selecionar Idioma"
        it = "Seleziona Lingua"
    }
}

$fixed = 0

foreach ($key in $fixes.Keys) {
    for ($i = 0; $i -lt $json.translation.Count; $i++) {
        if ($json.translation[$i].en -eq $key) {
            $json.translation[$i].pt = $fixes[$key].pt
            $json.translation[$i].it = $fixes[$key].it
            $fixed++
            Write-Host "Fixed: $key"
            break
        }
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Fixed $fixed out of 26 expected corrupted entries"
Write-Host ""

# Save without BOM
$jsonString = $json | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding($False)
[System.IO.File]::WriteAllText("$PWD\$translationFile", $jsonString, $utf8NoBom)

Write-Host "Saved translation.json without UTF-8 BOM"
Write-Host "Done!"
