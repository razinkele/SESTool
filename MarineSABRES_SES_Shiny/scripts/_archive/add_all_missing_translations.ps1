# Add all missing Dashboard and Entry Point translations with proper Portuguese and Italian

$translationFile = "c:\Users\DELL\OneDrive - ku.lt\HORIZON_EUROPE\Marine-SABRES\SESToolbox\MarineSABRES_SES_Shiny\translations\translation.json"

# Read current file
$json = Get-Content $translationFile -Raw | ConvertFrom-Json

# Helper function to add a translation entry
function Add-Translation {
    param($en, $es, $fr, $de, $pt, $it)
    return @{
        "en" = $en
        "es" = $es
        "fr" = $fr
        "de" = $de
        "pt" = $pt
        "it" = $it
    }
}

# Dashboard translations (18 entries)
$dashboardTranslations = @(
    (Add-Translation -en "MarineSABRES Social-Ecological Systems Analysis Tool" -es "Herramienta de Análisis de Sistemas Socio-Ecológicos MarineSABRES" -fr "Outil d'Analyse des Systèmes Socio-Écologiques MarineSABRES" -de "MarineSABRES Sozial-Ökologisches Systemanalyse-Tool" -pt "Ferramenta de Análise de Sistemas Socioecológicos MarineSABRES" -it "Strumento di Analisi dei Sistemi Socio-Ecologici MarineSABRES"),
    (Add-Translation -en "Welcome to the computer-assisted SES creation and analysis platform." -es "Bienvenido a la plataforma de creación y análisis de SES asistida por computadora." -fr "Bienvenue sur la plateforme de création et d'analyse de SES assistée par ordinateur." -de "Willkommen auf der computergestützten SES-Erstellungs- und Analyseplattform." -pt "Bem-vindo à plataforma de criação e análise de SES assistida por computador." -it "Benvenuto nella piattaforma di creazione e analisi SES assistita da computer."),
    (Add-Translation -en "Total Elements" -es "Elementos Totales" -fr "Éléments Totaux" -de "Gesamtelemente" -pt "Elementos Totais" -it "Elementi Totali"),
    (Add-Translation -en "Connections" -es "Conexiones" -fr "Connexions" -de "Verbindungen" -pt "Conexões" -it "Connessioni"),
    (Add-Translation -en "Loops Detected" -es "Bucles Detectados" -fr "Boucles Détectées" -de "Schleifen Erkannt" -pt "Ciclos Detectados" -it "Cicli Rilevati"),
    (Add-Translation -en "Completion" -es "Finalización" -fr "Achèvement" -de "Fertigstellung" -pt "Conclusão" -it "Completamento"),
    (Add-Translation -en "Project Overview" -es "Resumen del Proyecto" -fr "Aperçu du Projet" -de "Projektübersicht" -pt "Visão Geral do Projeto" -it "Panoramica del Progetto"),
    (Add-Translation -en "Recent Activities" -es "Actividades Recientes" -fr "Activités Récentes" -de "Kürzliche Aktivitäten" -pt "Atividades Recentes" -it "Attività Recenti"),
    (Add-Translation -en "CLD Preview" -es "Vista Previa CLD" -fr "Aperçu CLD" -de "CLD-Vorschau" -pt "Visualização CLD" -it "Anteprima CLD"),
    (Add-Translation -en "No CLD Generated Yet" -es "Aún No se ha Generado CLD" -fr "Aucun CLD Généré Pour le Moment" -de "Noch Kein CLD Generiert" -pt "Nenhum CLD Gerado Ainda" -it "Nessun CLD Generato Ancora"),
    (Add-Translation -en "Build your Causal Loop Diagram from the ISA data to visualize system connections." -es "Construya su Diagrama de Bucle Causal a partir de los datos ISA para visualizar las conexiones del sistema." -fr "Construisez votre Diagramme de Boucle Causale à partir des données ISA pour visualiser les connexions du système." -de "Erstellen Sie Ihr Ursache-Wirkungs-Diagramm aus den ISA-Daten, um Systemverbindungen zu visualisieren." -pt "Construa seu Diagrama de Loop Causal a partir dos dados ISA para visualizar as conexões do sistema." -it "Costruisci il tuo Diagramma di Loop Causale dai dati ISA per visualizzare le connessioni del sistema."),
    (Add-Translation -en "Build Network from ISA Data" -es "Construir Red desde Datos ISA" -fr "Construire le Réseau à partir des Données ISA" -de "Netzwerk aus ISA-Daten Erstellen" -pt "Construir Rede a partir de Dados ISA" -it "Costruisci Rete dai Dati ISA"),
    (Add-Translation -en "Project ID:" -es "ID del Proyecto:" -fr "ID du Projet:" -de "Projekt-ID:" -pt "ID do Projeto:" -it "ID Progetto:"),
    (Add-Translation -en "Created:" -es "Creado:" -fr "Créé:" -de "Erstellt:" -pt "Criado:" -it "Creato:"),
    (Add-Translation -en "Last Modified:" -es "Última Modificación:" -fr "Dernière Modification:" -de "Zuletzt Geändert:" -pt "Última Modificação:" -it "Ultima Modifica:"),
    (Add-Translation -en "Demonstration Area:" -es "Área de Demostración:" -fr "Zone de Démonstration:" -de "Demonstrationsbereich:" -pt "Área de Demonstração:" -it "Area Dimostrativa:"),
    (Add-Translation -en "Not set" -es "No establecido" -fr "Non défini" -de "Nicht festgelegt" -pt "Não definido" -it "Non impostato"),
    (Add-Translation -en "Focal Issue:" -es "Problema Focal:" -fr "Problème Focal:" -de "Schwerpunktthema:" -pt "Problema Focal:" -it "Problema Focale:"),
    (Add-Translation -en "Not defined" -es "No definido" -fr "Non défini" -de "Nicht definiert" -pt "Não definido" -it "Non definito"),
    (Add-Translation -en "Status Summary" -es "Resumen de Estado" -fr "Résumé du Statut" -de "Statusübersicht" -pt "Resumo de Status" -it "Riepilogo Stato"),
    (Add-Translation -en "PIMS Setup:" -es "Configuración PIMS:" -fr "Configuration PIMS:" -de "PIMS-Einrichtung:" -pt "Configuração PIMS:" -it "Configurazione PIMS:"),
    (Add-Translation -en "Complete" -es "Completo" -fr "Terminé" -de "Abgeschlossen" -pt "Completo" -it "Completo"),
    (Add-Translation -en "Incomplete" -es "Incompleto" -fr "Incomplet" -de "Unvollständig" -pt "Incompleto" -it "Incompleto"),
    (Add-Translation -en "ISA Data Entry:" -es "Entrada de Datos ISA:" -fr "Saisie de Données ISA:" -de "ISA-Dateneingabe:" -pt "Entrada de Dados ISA:" -it "Inserimento Dati ISA:"),
    (Add-Translation -en "In Progress" -es "En Progreso" -fr "En Cours" -de "In Bearbeitung" -pt "Em Progresso" -it "In Corso"),
    (Add-Translation -en "CLD Generated:" -es "CLD Generado:" -fr "CLD Généré:" -de "CLD Erstellt:" -pt "CLD Gerado:" -it "CLD Generato:"),
    (Add-Translation -en "Yes" -es "Sí" -fr "Oui" -de "Ja" -pt "Sim" -it "Sì"),
    (Add-Translation -en "No" -es "No" -fr "Non" -de "Nein" -pt "Não" -it "No")
)

# Additional Entry Point translations (25 entries)
$entryPointTranslations = @(
    (Add-Translation -en "EP0: Role" -es "EP0: Rol" -fr "EP0: Rôle" -de "EP0: Rolle" -pt "EP0: Papel" -it "EP0: Ruolo"),
    (Add-Translation -en "EP1: Need" -es "EP1: Necesidad" -fr "EP1: Besoin" -de "EP1: Bedarf" -pt "EP1: Necessidade" -it "EP1: Necessità"),
    (Add-Translation -en "EP2-3: Context" -es "EP2-3: Contexto" -fr "EP2-3: Contexte" -de "EP2-3: Kontext" -pt "EP2-3: Contexto" -it "EP2-3: Contesto"),
    (Add-Translation -en "EP4: Topic" -es "EP4: Tema" -fr "EP4: Sujet" -de "EP4: Thema" -pt "EP4: Tópico" -it "EP4: Argomento"),
    (Add-Translation -en "Tools" -es "Herramientas" -fr "Outils" -de "Werkzeuge" -pt "Ferramentas" -it "Strumenti"),
    (Add-Translation -en "e.g., How can we reduce fishing impacts while maintaining livelihoods?" -es "ej., ¿Cómo podemos reducir los impactos de la pesca manteniendo los medios de vida?" -fr "par ex., Comment réduire les impacts de la pêche tout en maintenant les moyens de subsistance?" -de "z.B., Wie können wir die Auswirkungen der Fischerei reduzieren und gleichzeitig den Lebensunterhalt sichern?" -pt "ex., Como podemos reduzir os impactos da pesca mantendo os meios de subsistência?" -it "es., Come possiamo ridurre gli impatti della pesca mantenendo i mezzi di sussistenza?"),
    (Add-Translation -en "Typical tasks:" -es "Tareas típicas:" -fr "Tâches typiques:" -de "Typische Aufgaben:" -pt "Tarefas típicas:" -it "Compiti tipici:"),
    (Add-Translation -en "Skip if you're not sure or want to see all options" -es "Omitir si no está seguro o desea ver todas las opciones" -fr "Passer si vous n'êtes pas sûr ou souhaitez voir toutes les options" -de "Überspringen, wenn Sie unsicher sind oder alle Optionen sehen möchten" -pt "Pular se não tiver certeza ou quiser ver todas as opções" -it "Salta se non sei sicuro o vuoi vedere tutte le opzioni"),
    (Add-Translation -en "Continue to EP1" -es "Continuar a EP1" -fr "Continuer vers EP1" -de "Weiter zu EP1" -pt "Continuar para EP1" -it "Continua a EP1"),
    (Add-Translation -en "Proceed to identify your basic human needs" -es "Proceda a identificar sus necesidades humanas básicas" -fr "Procédez à l'identification de vos besoins humains fondamentaux" -de "Fahren Sie fort, um Ihre grundlegenden menschlichen Bedürfnisse zu identifizieren" -pt "Prossiga para identificar suas necessidades humanas básicas" -it "Procedi per identificare i tuoi bisogni umani fondamentali"),
    (Add-Translation -en "Return to role selection" -es "Volver a la selección de rol" -fr "Retourner à la sélection de rôle" -de "Zurück zur Rollenauswahl" -pt "Retornar à seleção de papel" -it "Torna alla selezione del ruolo"),
    (Add-Translation -en "Skip if multiple needs apply or you're unsure" -es "Omitir si aplican múltiples necesidades o no está seguro" -fr "Passer si plusieurs besoins s'appliquent ou si vous n'êtes pas sûr" -de "Überspringen, wenn mehrere Bedürfnisse zutreffen oder Sie unsicher sind" -pt "Pular se múltiplas necessidades se aplicam ou se você não tem certeza" -it "Salta se si applicano più necessità o se non sei sicuro"),
    (Add-Translation -en "Proceed to specify activities and risks" -es "Proceda a especificar actividades y riesgos" -fr "Procédez à la spécification des activités et des risques" -de "Fahren Sie fort, um Aktivitäten und Risiken zu spezifizieren" -pt "Prossiga para especificar atividades e riscos" -it "Procedi per specificare attività e rischi"),
    (Add-Translation -en "Return to basic needs" -es "Volver a las necesidades básicas" -fr "Retourner aux besoins fondamentaux" -de "Zurück zu den Grundbedürfnissen" -pt "Retornar às necessidades básicas" -it "Torna ai bisogni fondamentali"),
    (Add-Translation -en "Skip if you want to explore all activities and risks" -es "Omitir si desea explorar todas las actividades y riesgos" -fr "Passer si vous souhaitez explorer toutes les activités et risques" -de "Überspringen, wenn Sie alle Aktivitäten und Risiken erkunden möchten" -pt "Pular se quiser explorar todas as atividades e riscos" -it "Salta se vuoi esplorare tutte le attività e i rischi"),
    (Add-Translation -en "Proceed to select knowledge topics" -es "Proceda a seleccionar temas de conocimiento" -fr "Procédez à la sélection des sujets de connaissances" -de "Fahren Sie fort, um Wissensthemen auszuwählen" -pt "Prossiga para selecionar tópicos de conhecimento" -it "Procedi per selezionare gli argomenti di conoscenza"),
    (Add-Translation -en "Return to activities and risks" -es "Volver a actividades y riesgos" -fr "Retourner aux activités et risques" -de "Zurück zu Aktivitäten und Risiken" -pt "Retornar a atividades e riscos" -it "Torna ad attività e rischi"),
    (Add-Translation -en "Skip to see all available tools" -es "Omitir para ver todas las herramientas disponibles" -fr "Passer pour voir tous les outils disponibles" -de "Überspringen, um alle verfügbaren Tools anzuzeigen" -pt "Pular para ver todas as ferramentas disponíveis" -it "Salta per vedere tutti gli strumenti disponibili"),
    (Add-Translation -en "Get personalized tool recommendations based on your pathway" -es "Obtenga recomendaciones de herramientas personalizadas según su ruta" -fr "Obtenez des recommandations d'outils personnalisées en fonction de votre parcours" -de "Erhalten Sie personalisierte Tool-Empfehlungen basierend auf Ihrem Pfad" -pt "Obtenha recomendações de ferramentas personalizadas com base em sua jornada" -it "Ottieni raccomandazioni di strumenti personalizzate in base al tuo percorso"),
    (Add-Translation -en "Go to" -es "Ir a" -fr "Aller à" -de "Gehe zu" -pt "Ir para" -it "Vai a")
)

# Add all new translations to the existing array
Write-Host "Adding $($dashboardTranslations.Count) Dashboard translations..."
foreach ($trans in $dashboardTranslations) {
    $json.translation += $trans
}

Write-Host "Adding $($entryPointTranslations.Count) Entry Point translations..."
foreach ($trans in $entryPointTranslations) {
    $json.translation += $trans
}

Write-Host "Total translations: $($json.translation.Count)"

# Save the complete file
$json | ConvertTo-Json -Depth 10 | Set-Content $translationFile -Encoding UTF8

Write-Host "Complete translation.json created successfully!"
Write-Host "Languages: en, es, fr, de, pt, it"
Write-Host "Total entries: $($json.translation.Count)"
