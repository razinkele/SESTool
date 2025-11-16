# Fix corrupted Portuguese and Italian translations for base 57 entries
# This script replaces Lithuanian placeholder text with proper PT and IT translations

$translationFile = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\translations\translation.json"

# Read the JSON file
$json = Get-Content $translationFile -Raw | ConvertFrom-Json

Write-Host "Total translations found: $($json.translation.Count)"

# Define the correct translations for base 57 entries
# Format: @{en="English"; pt="Portuguese"; it="Italian"}
$correctTranslations = @(
    @{en="Welcome to the MarineSABRES Toolbox"; pt="Bem-vindo à Caixa de Ferramentas MarineSABRES"; it="Benvenuto nella Cassetta degli Strumenti MarineSABRES"},
    @{en="This guidance system will help you find the right tools for your marine management needs."; pt="Este sistema de orientação irá ajudá-lo a encontrar as ferramentas certas para as suas necessidades de gestão marinha."; it="Questo sistema di orientamento ti aiuterà a trovare gli strumenti giusti per le tue esigenze di gestione marina."},
    @{en="What is your main marine management question?"; pt="Qual é a sua principal questão de gestão marinha?"; it="Qual è la tua principale domanda sulla gestione marina?"},
    @{en="Guided Pathway"; pt="Percurso Guiado"; it="Percorso Guidato"},
    @{en="Step-by-step guidance through the entry points"; pt="Orientação passo a passo através dos pontos de entrada"; it="Guida passo dopo passo attraverso i punti di ingresso"},
    @{en="Start Guided Journey"; pt="Iniciar Jornada Guiada"; it="Inizia il Percorso Guidato"},
    @{en="Quick Access"; pt="Acesso Rápido"; it="Accesso Rapido"},
    @{en="I know what tool I need"; pt="Eu sei que ferramenta preciso"; it="So di quale strumento ho bisogno"},
    @{en="Browse Tools"; pt="Explorar Ferramentas"; it="Sfoglia Strumenti"},
    @{en="Entry Point 0: Who Are You?"; pt="Ponto de Entrada 0: Quem é Você?"; it="Punto di Ingresso 0: Chi Sei?"},
    @{en="Select your role in marine management"; pt="Selecione o seu papel na gestão marinha"; it="Seleziona il tuo ruolo nella gestione marina"},
    @{en="Your role helps us recommend the most relevant tools and workflows for your marine management context."; pt="O seu papel ajuda-nos a recomendar as ferramentas e fluxos de trabalho mais relevantes para o seu contexto de gestão marinha."; it="Il tuo ruolo ci aiuta a raccomandare gli strumenti e i flussi di lavoro più rilevanti per il tuo contesto di gestione marina."},
    @{en="Entry Point 1: Why Do You Care?"; pt="Ponto de Entrada 1: Por Que Se Importa?"; it="Punto di Ingresso 1: Perché Ti Interessa?"},
    @{en="What basic human need drives your question?"; pt="Que necessidade humana básica impulsiona a sua questão?"; it="Quale bisogno umano fondamentale guida la tua domanda?"},
    @{en="Understanding the fundamental human need behind your question helps identify relevant ecosystem services and management priorities."; pt="Compreender a necessidade humana fundamental por trás da sua questão ajuda a identificar serviços ecossistémicos relevantes e prioridades de gestão."; it="Comprendere il bisogno umano fondamentale dietro la tua domanda aiuta a identificare i servizi ecosistemici rilevanti e le priorità di gestione."},
    @{en="EP2: Activity Sectors"; pt="EP2: Setores de Atividade"; it="EP2: Settori di Attività"},
    @{en="Select all that apply (multiple selection allowed)"; pt="Selecione todos os que se aplicam (seleção múltipla permitida)"; it="Seleziona tutti quelli che si applicano (selezione multipla consentita)"},
    @{en="Select the human activities relevant to your marine management question. These represent the 'Drivers' and 'Activities' in the DAPSI(W)R(M) framework."; pt="Selecione as atividades humanas relevantes para a sua questão de gestão marinha. Estas representam os 'Impulsionadores' e 'Atividades' no quadro DAPSI(W)R(M)."; it="Seleziona le attività umane rilevanti per la tua domanda di gestione marina. Queste rappresentano i 'Driver' e le 'Attività' nel framework DAPSI(W)R(M)."},
    @{en="EP3: Risks & Hazards"; pt="EP3: Riscos e Perigos"; it="EP3: Rischi e Pericoli"},
    @{en="What threats or hazards concern you?"; pt="Que ameaças ou perigos o preocupam?"; it="Quali minacce o pericoli ti preoccupano?"},
    @{en="Identify the environmental risks and hazards affecting your system. These help define 'Pressures' and 'State Changes' in DAPSI(W)R(M)."; pt="Identifique os riscos ambientais e perigos que afetam o seu sistema. Estes ajudam a definir 'Pressões' e 'Mudanças de Estado' em DAPSI(W)R(M)."; it="Identifica i rischi ambientali e i pericoli che influenzano il tuo sistema. Questi aiutano a definire 'Pressioni' e 'Cambiamenti di Stato' in DAPSI(W)R(M)."},
    @{en="EP4: Topics"; pt="EP4: Tópicos"; it="EP4: Argomenti"},
    @{en="Select your knowledge domain"; pt="Selecione o seu domínio de conhecimento"; it="Seleziona il tuo ambito di conoscenza"},
    @{en="Choose the topics most relevant to your question. This helps us recommend appropriate analytical tools and methods."; pt="Escolha os tópicos mais relevantes para a sua questão. Isto ajuda-nos a recomendar ferramentas analíticas e métodos apropriados."; it="Scegli gli argomenti più rilevanti per la tua domanda. Questo ci aiuta a raccomandare strumenti analitici e metodi appropriati."},
    @{en="Skip"; pt="Saltar"; it="Salta"},
    @{en="Continue"; pt="Continuar"; it="Continua"},
    @{en="Back"; pt="Voltar"; it="Indietro"},
    @{en="Typical tasks:"; pt="Tarefas típicas:"; it="Compiti tipici:"},
    @{en="Activities:"; pt="Atividades:"; it="Attività:"},
    @{en="Examples:"; pt="Exemplos:"; it="Esempi:"},
    @{en="Select"; pt="Selecionar"; it="Seleziona"},
    @{en="Selected"; pt="Selecionado"; it="Selezionato"},
    @{en="Natural"; pt="Natural"; it="Naturale"},
    @{en="Anthropogenic"; pt="Antropogénico"; it="Antropogenico"},
    @{en="Acute"; pt="Agudo"; it="Acuto"},
    @{en="Chronic"; pt="Crónico"; it="Cronico"},
    @{en="High"; pt="Alto"; it="Alto"},
    @{en="Medium"; pt="Médio"; it="Medio"},
    @{en="Low"; pt="Baixo"; it="Basso"},
    @{en="Critical"; pt="Crítico"; it="Critico"},
    @{en="Foundation"; pt="Fundação"; it="Fondazione"},
    @{en="Natural"; pt="Natural"; it="Naturale"},
    @{en="Economic"; pt="Económico"; it="Economico"},
    @{en="Governance"; pt="Governança"; it="Governance"},
    @{en="Social"; pt="Social"; it="Sociale"},
    @{en="Methodological"; pt="Metodológico"; it="Metodologico"},
    @{en="Not set"; pt="Não definido"; it="Non impostato"},
    @{en="Not defined"; pt="Não definido"; it="Non definito"},
    @{en="Complete"; pt="Completo"; it="Completo"},
    @{en="Incomplete"; pt="Incompleto"; it="Incompleto"},
    @{en="In Progress"; pt="Em Progresso"; it="In Corso"},
    @{en="Yes"; pt="Sim"; it="Sì"},
    @{en="No"; pt="Não"; it="No"},
    @{en="Loading..."; pt="A carregar..."; it="Caricamento..."},
    @{en="Error"; pt="Erro"; it="Errore"},
    @{en="Success"; pt="Sucesso"; it="Successo"},
    @{en="Warning"; pt="Aviso"; it="Avviso"},
    @{en="Info"; pt="Informação"; it="Informazione"}
)

Write-Host "Fixing $($correctTranslations.Count) base translations..."

$fixed = 0
foreach ($i in 0..($correctTranslations.Count - 1)) {
    $correct = $correctTranslations[$i]

    # Find the matching entry in the JSON by English text
    for ($j = 0; $j -lt $json.translation.Count; $j++) {
        if ($json.translation[$j].en -eq $correct.en) {
            # Update PT and IT
            $json.translation[$j].pt = $correct.pt
            $json.translation[$j].it = $correct.it
            $fixed++
            Write-Host "Fixed: $($correct.en)"
            break
        }
    }
}

Write-Host "`nFixed $fixed translations"

# Save the updated JSON (without BOM)
$jsonString = $json | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($translationFile, $jsonString, (New-Object System.Text.UTF8Encoding($False)))

Write-Host "Saved translation.json without UTF-8 BOM"
Write-Host "Done!"
