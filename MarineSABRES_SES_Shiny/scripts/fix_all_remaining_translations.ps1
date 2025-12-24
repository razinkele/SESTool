# Complete fix for ALL remaining corrupted PT/IT translations
# This script finds any entry with Lithuanian characters and replaces with proper translations

$translationFile = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\translations\translation.json"

# Read the JSON file
$json = Get-Content $translationFile -Raw | ConvertFrom-Json

Write-Host "Total translations: $($json.translation.Count)"

# Define ALL remaining corrections needed (entries that weren't in the first script)
$additionalFixes = @{
    "What threats or hazards concern you?" = @{pt="Que ameaças ou perigos o preocupam?"; it="Quali minacce o pericoli ti preoccupano?"}
    "Identify the environmental risks and hazards affecting your system. These help define 'Pressures' and 'State Changes' in DAPSI(W)R(M)." = @{pt="Identifique os riscos ambientais e perigos que afetam o seu sistema. Estes ajudam a definir 'Pressões' e 'Mudanças de Estado' em DAPSI(W)R(M)."; it="Identifica i rischi ambientali e i pericoli che influenzano il tuo sistema. Questi aiutano a definire 'Pressioni' e 'Cambiamenti di Stato' in DAPSI(W)R(M)."}
    "EP4: Topics" = @{pt="EP4: Tópicos"; it="EP4: Argomenti"}
    "Select your knowledge domain" = @{pt="Selecione o seu domínio de conhecimento"; it="Seleziona il tuo ambito di conoscenza"}
    "Choose the topics most relevant to your question. This helps us recommend appropriate analytical tools and methods." = @{pt="Escolha os tópicos mais relevantes para a sua questão. Isto ajuda-nos a recomendar ferramentas analíticas e métodos apropriados."; it="Scegli gli argomenti più rilevanti per la tua domanda. Questo ci aiuta a raccomandare strumenti analitici e metodi appropriati."}
    "Examples:" = @{pt="Exemplos:"; it="Esempi:"}
    "Natural" = @{pt="Natural"; it="Naturale"}
    "Anthropogenic" = @{pt="Antropogénico"; it="Antropogenico"}
    "Acute" = @{pt="Agudo"; it="Acuto"}
    "Chronic" = @{pt="Crónico"; it="Cronico"}
    "High" = @{pt="Alto"; it="Alto"}
    "Medium" = @{pt="Médio"; it="Medio"}
    "Low" = @{pt="Baixo"; it="Basso"}
    "Critical" = @{pt="Crítico"; it="Critico"}
    "Foundation" = @{pt="Fundação"; it="Fondazione"}
    "Economic" = @{pt="Económico"; it="Economico"}
    "Governance" = @{pt="Governança"; it="Governance"}
    "Social" = @{pt="Social"; it="Sociale"}
    "Methodological" = @{pt="Metodológico"; it="Metodologico"}
    "Loading..." = @{pt="A carregar..."; it="Caricamento..."}
    "Error" = @{pt="Erro"; it="Errore"}
    "Success" = @{pt="Sucesso"; it="Successo"}
    "Warning" = @{pt="Aviso"; it="Avviso"}
    "Info" = @{pt="Informação"; it="Informazione"}
    "Quick Access" = @{pt="Acesso Rápido"; it="Accesso Rapido"}
    "Select the environmental pressures, risks, or hazards you're concerned about. These represent 'Pressures' and 'State changes' in the DAPSI(W)R(M) framework." = @{pt="Selecione as pressões ambientais, riscos ou perigos que o preocupam. Estes representam 'Pressões' e 'Mudanças de estado' no quadro DAPSI(W)R(M)."; it="Seleziona le pressioni ambientali, i rischi o i pericoli che ti preoccupano. Questi rappresentano 'Pressioni' e 'Cambiamenti di stato' nel framework DAPSI(W)R(M)."}
    "Entry Point 4: Knowledge Domain" = @{pt="Ponto de Entrada 4: Domínio de Conhecimento"; it="Punto di Ingresso 4: Ambito di Conoscenza"}
    "What topic areas are you interested in? (Select all that apply)" = @{pt="Que áreas temáticas lhe interessam? (Selecione todas as que se aplicam)"; it="Quali aree tematiche ti interessano? (Seleziona tutte quelle applicabili)"}
    "Select the knowledge domains and analytical approaches relevant to your question. This helps match you with appropriate analysis tools and frameworks." = @{pt="Selecione os domínios de conhecimento e abordagens analíticas relevantes para a sua questão. Isto ajuda a combiná-lo com ferramentas e quadros de análise apropriados."; it="Seleziona gli ambiti di conoscenza e gli approcci analitici rilevanti per la tua domanda. Questo aiuta a abbinarti con strumenti e framework di analisi appropriati."}
    "Get Recommendations" = @{pt="Obter Recomendações"; it="Ottieni Raccomandazioni"}
    "Recommended Tools for Your Marine Management Question" = @{pt="Ferramentas Recomendadas para a Sua Questão de Gestão Marinha"; it="Strumenti Raccomandati per la Tua Domanda di Gestione Marina"}
    "Your Pathway Summary" = @{pt="Resumo do Seu Percurso"; it="Riepilogo del Tuo Percorso"}
    "Role:" = @{pt="Papel:"; it="Ruolo:"}
    "Need:" = @{pt="Necessidade:"; it="Necessità:"}
    "Risks:" = @{pt="Riscos:"; it="Rischi:"}
    "Topics:" = @{pt="Tópicos:"; it="Argomenti:"}
    "Recommended Workflow:" = @{pt="Fluxo de Trabalho Recomendado:"; it="Flusso di Lavoro Raccomandato:"}
    "Follow this sequence of tools to address your marine management question:" = @{pt="Siga esta sequência de ferramentas para abordar a sua questão de gestão marinha:"; it="Segui questa sequenza di strumenti per affrontare la tua domanda di gestione marina:"}
    "START HERE" = @{pt="COMEÇAR AQUI"; it="INIZIA QUI"}
    "NEXT STEP" = @{pt="PROXIMO PASSO"; it="PROSSIMO PASSO"}
    "ALSO RELEVANT" = @{pt="TAMBÉM RELEVANTE"; it="ANCHE RILEVANTE"}
    "Skill:" = @{pt="Habilidade:"; it="Abilità:"}
    "Suggested Workflow:" = @{pt="Fluxo de Trabalho Sugerido:"; it="Flusso di Lavoro Suggerito:"}
    "Start with PIMS:" = @{pt="Começar com PIMS:"; it="Inizia con PIMS:"}
    "Define your project goals, stakeholders, and timeline" = @{pt="Defina os objetivos do seu projeto, partes interessadas e cronograma"; it="Definisci gli obiettivi del progetto, gli stakeholder e la timeline"}
    "Build your SES model:" = @{pt="Construa o seu modelo SES:"; it="Costruisci il tuo modello SES:"}
    "Use ISA Data Entry to map DAPSI(W)R(M) elements" = @{pt="Use a Entrada de Dados ISA para mapear elementos DAPSI(W)R(M)"; it="Usa l'Inserimento Dati ISA per mappare gli elementi DAPSI(W)R(M)"}
    "Visualize & Analyze:" = @{pt="Visualizar e Analisar:"; it="Visualizza e Analizza:"}
    "Create CLD networks and run analysis tools" = @{pt="Crie redes CLD e execute ferramentas de análise"; it="Crea reti CLD ed esegui strumenti di analisi"}
    "Refine & Communicate:" = @{pt="Refinar e Comunicar:"; it="Raffinare e Comunicare:"}
    "Simplify models and develop management scenarios" = @{pt="Simplifique modelos e desenvolva cenários de gestão"; it="Semplifica i modelli e sviluppa scenari di gestione"}
    "Start Over" = @{pt="Recomeçar"; it="Ricomincia"}
    "Begin a new pathway from the welcome screen" = @{pt="Iniciar um novo percurso a partir do ecrã de boas-vindas"; it="Inizia un nuovo percorso dalla schermata di benvenuto"}
    "Export Pathway Report" = @{pt="Exportar Relatório de Percurso"; it="Esporta Rapporto Percorso"}
    "Download a PDF summary of your pathway and recommendations" = @{pt="Descarregue um resumo em PDF do seu percurso e recomendações"; it="Scarica un riepilogo PDF del tuo percorso e delle raccomandazioni"}
    "Your Progress:" = @{pt="O Seu Progresso:"; it="Il Tuo Progresso:"}
    "Welcome" = @{pt="Bem-vindo"; it="Benvenuto"}
    "Language" = @{pt="Idioma"; it="Lingua"}
    "Select Language" = @{pt="Selecionar Idioma"; it="Seleziona Lingua"}
}

$fixed = 0
$notFound = 0

foreach ($key in $additionalFixes.Keys) {
    $translations = $additionalFixes[$key]

    # Find the entry with matching English text
    $found = $false
    for ($i = 0; $i -lt $json.translation.Count; $i++) {
        if ($json.translation[$i].en -eq $key) {
            # Check if it needs fixing (contains Lithuanian characters)
            if ($json.translation[$i].pt -match '[ĄČĖŠįųž]' -or $json.translation[$i].it -match '[ĄČĖŠįųž]') {
                $json.translation[$i].pt = $translations.pt
                $json.translation[$i].it = $translations.it
                $fixed++
                Write-Host "Fixed: $key"
            }
            $found = $true
            break
        }
    }

    if (-not $found) {
        $notFound++
        Write-Host "NOT FOUND: $key" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================`n"
Write-Host "Fixed: $fixed entries"
Write-Host "Not found: $notFound entries"
Write-Host "`n========================================`n"

# Save the updated JSON without BOM
$jsonString = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($translationFile, $jsonString, (New-Object System.Text.UTF8Encoding($False)))

Write-Host "Saved translation.json without UTF-8 BOM"
Write-Host "Done!"
