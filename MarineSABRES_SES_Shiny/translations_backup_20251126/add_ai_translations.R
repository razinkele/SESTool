# Add AI ISA Assistant translations to translation.json
library(jsonlite)

# Read existing translations
trans <- fromJSON("translation.json", simplifyVector = FALSE)

# New translations for AI ISA Assistant module
ai_translations <- list(
  list(
    en = "AI-Assisted ISA Creation",
    es = "Creación ISA Asistida por IA",
    fr = "Création ISA Assistée par IA",
    de = "KI-Gestützte ISA-Erstellung",
    pt = "Criação ISA Assistida por IA"
  ),
  list(
    en = "Let me guide you step-by-step through building your DAPSI(W)R(M) model.",
    es = "Permítame guiarle paso a paso en la construcción de su modelo DAPSI(W)R(M).",
    fr = "Laissez-moi vous guider étape par étape dans la construction de votre modèle DAPSI(W)R(M).",
    de = "Lassen Sie mich Sie Schritt für Schritt durch den Aufbau Ihres DAPSI(W)R(M)-Modells führen.",
    pt = "Deixe-me guiá-lo passo a passo na construção do seu modelo DAPSI(W)R(M)."
  ),
  list(
    en = "AI Assistant",
    es = "Asistente IA",
    fr = "Assistant IA",
    de = "KI-Assistent",
    pt = "Assistente IA"
  ),
  list(
    en = "You",
    es = "Usted",
    fr = "Vous",
    de = "Sie",
    pt = "Você"
  ),
  list(
    en = "Type your answer here...",
    es = "Escriba su respuesta aquí...",
    fr = "Tapez votre réponse ici...",
    de = "Geben Sie hier Ihre Antwort ein...",
    pt = "Digite sua resposta aqui..."
  ),
  list(
    en = "Submit Answer",
    es = "Enviar Respuesta",
    fr = "Soumettre la Réponse",
    de = "Antwort Absenden",
    pt = "Enviar Resposta"
  ),
  list(
    en = "Skip This Question",
    es = "Saltar Esta Pregunta",
    fr = "Passer Cette Question",
    de = "Diese Frage Überspringen",
    pt = "Pular Esta Pergunta"
  ),
  list(
    en = "Quick options (click to add):",
    es = "Opciones rápidas (haga clic para agregar):",
    fr = "Options rapides (cliquez pour ajouter):",
    de = "Schnelloptionen (klicken zum Hinzufügen):",
    pt = "Opções rápidas (clique para adicionar):"
  ),
  list(
    en = "Your SES Model Progress",
    es = "Progreso de su Modelo SES",
    fr = "Progression de Votre Modèle SES",
    de = "Ihr SES-Modell-Fortschritt",
    pt = "Progresso do Seu Modelo SES"
  ),
  list(
    en = "Elements Created:",
    es = "Elementos Creados:",
    fr = "Éléments Créés:",
    de = "Erstellte Elemente:",
    pt = "Elementos Criados:"
  ),
  list(
    en = "Total elements created",
    es = "Total de elementos creados",
    fr = "Total des éléments créés",
    de = "Insgesamt erstellte Elemente",
    pt = "Total de elementos criados"
  ),
  list(
    en = "Current Framework:",
    es = "Marco Actual:",
    fr = "Cadre Actuel:",
    de = "Aktueller Rahmen:",
    pt = "Estrutura Atual:"
  ),
  list(
    en = "Drivers:",
    es = "Impulsores:",
    fr = "Moteurs:",
    de = "Treiber:",
    pt = "Impulsores:"
  ),
  list(
    en = "Preview Model",
    es = "Vista Previa del Modelo",
    fr = "Aperçu du Modèle",
    de = "Modellvorschau",
    pt = "Pré-visualizar Modelo"
  ),
  list(
    en = "Save to ISA Data Entry",
    es = "Guardar en Entrada de Datos ISA",
    fr = "Enregistrer dans Saisie de Données ISA",
    de = "In ISA-Dateneingabe Speichern",
    pt = "Salvar na Entrada de Dados ISA"
  ),
  list(
    en = "Confirm Start Over",
    es = "Confirmar Reinicio",
    fr = "Confirmer le Redémarrage",
    de = "Neustart Bestätigen",
    pt = "Confirmar Recomeço"
  ),
  list(
    en = "Are you sure you want to start over? All current progress will be lost.",
    es = "¿Está seguro de que desea comenzar de nuevo? Se perderá todo el progreso actual.",
    fr = "Êtes-vous sûr de vouloir recommencer? Toute la progression actuelle sera perdue.",
    de = "Sind Sie sicher, dass Sie von vorne beginnen möchten? Der gesamte aktuelle Fortschritt geht verloren.",
    pt = "Tem certeza de que deseja recomeçar? Todo o progresso atual será perdido."
  ),
  list(
    en = "Yes, Start Over",
    es = "Sí, Comenzar de Nuevo",
    fr = "Oui, Recommencer",
    de = "Ja, Von Vorne Beginnen",
    pt = "Sim, Recomeçar"
  ),
  list(
    en = "Cancel",
    es = "Cancelar",
    fr = "Annuler",
    de = "Abbrechen",
    pt = "Cancelar"
  ),
  list(
    en = "Your DAPSI(W)R(M) Model Preview",
    es = "Vista Previa de su Modelo DAPSI(W)R(M)",
    fr = "Aperçu de Votre Modèle DAPSI(W)R(M)",
    de = "Vorschau Ihres DAPSI(W)R(M)-Modells",
    pt = "Pré-visualização do Seu Modelo DAPSI(W)R(M)"
  ),
  list(
    en = "Project Information",
    es = "Información del Proyecto",
    fr = "Informations sur le Projet",
    de = "Projektinformationen",
    pt = "Informações do Projeto"
  ),
  list(
    en = "Project/Location:",
    es = "Proyecto/Ubicación:",
    fr = "Projet/Emplacement:",
    de = "Projekt/Standort:",
    pt = "Projeto/Localização:"
  ),
  list(
    en = "Ecosystem Type:",
    es = "Tipo de Ecosistema:",
    fr = "Type d'Écosystème:",
    de = "Ökosystemtyp:",
    pt = "Tipo de Ecossistema:"
  ),
  list(
    en = "Main Issue:",
    es = "Problema Principal:",
    fr = "Problème Principal:",
    de = "Hauptproblem:",
    pt = "Problema Principal:"
  ),
  list(
    en = "Drivers (Societal Needs)",
    es = "Impulsores (Necesidades Sociales)",
    fr = "Moteurs (Besoins Sociétaux)",
    de = "Treiber (Gesellschaftliche Bedürfnisse)",
    pt = "Impulsores (Necessidades Sociais)"
  ),
  list(
    en = "Activities (Human Actions)",
    es = "Actividades (Acciones Humanas)",
    fr = "Activités (Actions Humaines)",
    de = "Aktivitäten (Menschliche Handlungen)",
    pt = "Atividades (Ações Humanas)"
  ),
  list(
    en = "Pressures (Environmental Stressors)",
    es = "Presiones (Estresores Ambientales)",
    fr = "Pressions (Facteurs de Stress Environnementaux)",
    de = "Belastungen (Umweltstressoren)",
    pt = "Pressões (Estressores Ambientais)"
  ),
  list(
    en = "State Changes (Ecosystem Effects)",
    es = "Cambios de Estado (Efectos del Ecosistema)",
    fr = "Changements d'État (Effets sur l'Écosystème)",
    de = "Zustandsänderungen (Ökosystemeffekte)",
    pt = "Mudanças de Estado (Efeitos no Ecossistema)"
  ),
  list(
    en = "Impacts (Service Effects)",
    es = "Impactos (Efectos en los Servicios)",
    fr = "Impacts (Effets sur les Services)",
    de = "Auswirkungen (Serviceeffekte)",
    pt = "Impactos (Efeitos nos Serviços)"
  ),
  list(
    en = "Welfare (Human Well-being)",
    es = "Bienestar (Bienestar Humano)",
    fr = "Bien-être (Bien-être Humain)",
    de = "Wohlergehen (Menschliches Wohlbefinden)",
    pt = "Bem-estar (Bem-estar Humano)"
  ),
  list(
    en = "Total elements:",
    es = "Total de elementos:",
    fr = "Total des éléments:",
    de = "Gesamtelemente:",
    pt = "Total de elementos:"
  ),
  list(
    en = "Close",
    es = "Cerrar",
    fr = "Fermer",
    de = "Schließen",
    pt = "Fechar"
  ),
  list(
    en = "Model saved! Navigate to 'ISA Data Entry' to see your elements.",
    es = "¡Modelo guardado! Navegue a 'Entrada de Datos ISA' para ver sus elementos.",
    fr = "Modèle enregistré! Accédez à 'Saisie de Données ISA' pour voir vos éléments.",
    de = "Modell gespeichert! Navigieren Sie zu 'ISA-Dateneingabe', um Ihre Elemente zu sehen.",
    pt = "Modelo salvo! Navegue até 'Entrada de Dados ISA' para ver seus elementos."
  ),
  list(
    en = "Step",
    es = "Paso",
    fr = "Étape",
    de = "Schritt",
    pt = "Passo"
  ),
  list(
    en = "of",
    es = "de",
    fr = "de",
    de = "von",
    pt = "de"
  ),
  list(
    en = "Complete! Review your model",
    es = "¡Completado! Revise su modelo",
    fr = "Complet! Examinez votre modèle",
    de = "Fertig! Überprüfen Sie Ihr Modell",
    pt = "Completo! Revise seu modelo"
  ),
  # Question flow titles
  list(
    en = "Welcome & Introduction",
    es = "Bienvenida e Introducción",
    fr = "Bienvenue et Introduction",
    de = "Willkommen & Einführung",
    pt = "Boas-vindas e Introdução"
  ),
  list(
    en = "Ecosystem Context",
    es = "Contexto del Ecosistema",
    fr = "Contexte de l'Écosystème",
    de = "Ökosystem-Kontext",
    pt = "Contexto do Ecossistema"
  ),
  list(
    en = "Main Issue Identification",
    es = "Identificación del Problema Principal",
    fr = "Identification du Problème Principal",
    de = "Hauptproblem-Identifizierung",
    pt = "Identificação do Problema Principal"
  ),
  list(
    en = "Drivers - Societal Needs",
    es = "Impulsores - Necesidades Sociales",
    fr = "Moteurs - Besoins Sociétaux",
    de = "Treiber - Gesellschaftliche Bedürfnisse",
    pt = "Impulsores - Necessidades Sociais"
  ),
  list(
    en = "Activities - Human Actions",
    es = "Actividades - Acciones Humanas",
    fr = "Activités - Actions Humaines",
    de = "Aktivitäten - Menschliche Handlungen",
    pt = "Atividades - Ações Humanas"
  ),
  list(
    en = "Pressures - Environmental Stressors",
    es = "Presiones - Estresores Ambientales",
    fr = "Pressions - Facteurs de Stress Environnementaux",
    de = "Belastungen - Umweltstressoren",
    pt = "Pressões - Estressores Ambientais"
  ),
  list(
    en = "State Changes - Ecosystem Effects",
    es = "Cambios de Estado - Efectos del Ecosistema",
    fr = "Changements d'État - Effets sur l'Écosystème",
    de = "Zustandsänderungen - Ökosystemeffekte",
    pt = "Mudanças de Estado - Efeitos no Ecossistema"
  ),
  list(
    en = "Impacts - Effects on Ecosystem Services",
    es = "Impactos - Efectos en los Servicios Ecosistémicos",
    fr = "Impacts - Effets sur les Services Écosystémiques",
    de = "Auswirkungen - Effekte auf Ökosystemleistungen",
    pt = "Impactos - Efeitos nos Serviços Ecossistêmicos"
  ),
  list(
    en = "Welfare - Human Well-being Effects",
    es = "Bienestar - Efectos en el Bienestar Humano",
    fr = "Bien-être - Effets sur le Bien-être Humain",
    de = "Wohlergehen - Auswirkungen auf Menschliches Wohlbefinden",
    pt = "Bem-estar - Efeitos no Bem-estar Humano"
  ),
  # Ecosystem type options
  list(
    en = "Coastal waters",
    es = "Aguas costeras",
    fr = "Eaux côtières",
    de = "Küstengewässer",
    pt = "Águas costeiras"
  ),
  list(
    en = "Open ocean",
    es = "Océano abierto",
    fr = "Océan ouvert",
    de = "Offenes Meer",
    pt = "Oceano aberto"
  ),
  list(
    en = "Estuaries",
    es = "Estuarios",
    fr = "Estuaires",
    de = "Flussmündungen",
    pt = "Estuários"
  ),
  list(
    en = "Coral reefs",
    es = "Arrecifes de coral",
    fr = "Récifs coralliens",
    de = "Korallenriffe",
    pt = "Recifes de coral"
  ),
  list(
    en = "Mangroves",
    es = "Manglares",
    fr = "Mangroves",
    de = "Mangroven",
    pt = "Manguezais"
  ),
  list(
    en = "Seagrass beds",
    es = "Praderas de pastos marinos",
    fr = "Herbiers marins",
    de = "Seegraswiesen",
    pt = "Campos de ervas marinhas"
  ),
  list(
    en = "Deep sea",
    es = "Mar profundo",
    fr = "Mer profonde",
    de = "Tiefsee",
    pt = "Mar profundo"
  ),
  list(
    en = "Other",
    es = "Otro",
    fr = "Autre",
    de = "Andere",
    pt = "Outro"
  )
)

# Add new translations to existing
trans$translation <- c(trans$translation, ai_translations)

# Write back to file
write_json(trans, "translation.json", pretty = TRUE, auto_unbox = TRUE)

cat("AI ISA Assistant translations added successfully!\n")
cat("Total translations now:", length(trans$translation), "\n")
