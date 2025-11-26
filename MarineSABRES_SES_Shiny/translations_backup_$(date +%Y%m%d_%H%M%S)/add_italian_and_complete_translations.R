# Complete localization: Add Italian and all remaining UI strings
library(jsonlite)

# Read existing translations
trans <- fromJSON("translation.json", simplifyVector = FALSE)

# Add Italian to languages list
trans$languages <- c(trans$languages, "it")

# Function to add Italian to existing translations (default placeholder)
for (i in seq_along(trans$translation)) {
  if (is.null(trans$translation[[i]]$it)) {
    trans$translation[[i]]$it <- paste0("[IT] ", trans$translation[[i]]$en)
  }
}

# Comprehensive new translations for entire app
complete_translations <- list(
  # Menu items
  list(
    en = "Getting Started",
    es = "Comenzando",
    fr = "Premiers Pas",
    de = "Erste Schritte",
    pt = "Começando",
    it = "Iniziare"
  ),
  list(
    en = "PIMS",
    es = "PIMS",
    fr = "PIMS",
    de = "PIMS",
    pt = "PIMS",
    it = "PIMS"
  ),
  list(
    en = "Project Information Management System",
    es = "Sistema de Gestión de Información de Proyectos",
    fr = "Système de Gestion de l'Information de Projet",
    de = "Projektinformations-Managementsystem",
    pt = "Sistema de Gestão de Informação do Projeto",
    it = "Sistema di Gestione delle Informazioni di Progetto"
  ),
  list(
    en = "CLD Visualization",
    es = "Visualización CLD",
    fr = "Visualisation CLD",
    de = "CLD-Visualisierung",
    pt = "Visualização CLD",
    it = "Visualizzazione CLD"
  ),
  list(
    en = "Analysis Tools",
    es = "Herramientas de Análisis",
    fr = "Outils d'Analyse",
    de = "Analysewerkzeuge",
    pt = "Ferramentas de Análise",
    it = "Strumenti di Analisi"
  ),
  list(
    en = "Network Metrics",
    es = "Métricas de Red",
    fr = "Métriques de Réseau",
    de = "Netzwerkmetriken",
    pt = "Métricas de Rede",
    it = "Metriche di Rete"
  ),
  list(
    en = "Loop Detection",
    es = "Detección de Bucles",
    fr = "Détection de Boucles",
    de = "Schleifenerkennung",
    pt = "Detecção de Loops",
    it = "Rilevamento di Loop"
  ),
  list(
    en = "BOT Analysis",
    es = "Análisis BOT",
    fr = "Analyse BOT",
    de = "BOT-Analyse",
    pt = "Análise BOT",
    it = "Analisi BOT"
  ),
  list(
    en = "Model Simplification",
    es = "Simplificación de Modelo",
    fr = "Simplification de Modèle",
    de = "Modellvereinfachung",
    pt = "Simplificação de Modelo",
    it = "Semplificazione del Modello"
  ),
  list(
    en = "Response Measures",
    es = "Medidas de Respuesta",
    fr = "Mesures de Réponse",
    de = "Reaktionsmaßnahmen",
    pt = "Medidas de Resposta",
    it = "Misure di Risposta"
  ),
  list(
    en = "Help",
    es = "Ayuda",
    fr = "Aide",
    de = "Hilfe",
    pt = "Ajuda",
    it = "Aiuto"
  ),
  # Common buttons and actions
  list(
    en = "Save",
    es = "Guardar",
    fr = "Enregistrer",
    de = "Speichern",
    pt = "Salvar",
    it = "Salva"
  ),
  list(
    en = "Load",
    es = "Cargar",
    fr = "Charger",
    de = "Laden",
    pt = "Carregar",
    it = "Carica"
  ),
  list(
    en = "Delete",
    es = "Eliminar",
    fr = "Supprimer",
    de = "Löschen",
    pt = "Excluir",
    it = "Elimina"
  ),
  list(
    en = "Edit",
    es = "Editar",
    fr = "Modifier",
    de = "Bearbeiten",
    pt = "Editar",
    it = "Modifica"
  ),
  list(
    en = "Add",
    es = "Agregar",
    fr = "Ajouter",
    de = "Hinzufügen",
    pt = "Adicionar",
    it = "Aggiungi"
  ),
  list(
    en = "Update",
    es = "Actualizar",
    fr = "Mettre à Jour",
    de = "Aktualisieren",
    pt = "Atualizar",
    it = "Aggiorna"
  ),
  list(
    en = "Export",
    es = "Exportar",
    fr = "Exporter",
    de = "Exportieren",
    pt = "Exportar",
    it = "Esporta"
  ),
  list(
    en = "Import",
    es = "Importar",
    fr = "Importer",
    de = "Importieren",
    pt = "Importar",
    it = "Importa"
  ),
  list(
    en = "Download",
    es = "Descargar",
    fr = "Télécharger",
    de = "Herunterladen",
    pt = "Baixar",
    it = "Scarica"
  ),
  list(
    en = "Upload",
    es = "Subir",
    fr = "Téléverser",
    de = "Hochladen",
    pt = "Enviar",
    it = "Carica"
  ),
  list(
    en = "Reset",
    es = "Restablecer",
    fr = "Réinitialiser",
    de = "Zurücksetzen",
    pt = "Redefinir",
    it = "Ripristina"
  ),
  list(
    en = "Apply",
    es = "Aplicar",
    fr = "Appliquer",
    de = "Anwenden",
    pt = "Aplicar",
    it = "Applica"
  ),
  list(
    en = "Clear",
    es = "Limpiar",
    fr = "Effacer",
    de = "Löschen",
    pt = "Limpar",
    it = "Pulisci"
  ),
  list(
    en = "Search",
    es = "Buscar",
    fr = "Rechercher",
    de = "Suchen",
    pt = "Pesquisar",
    it = "Cerca"
  ),
  list(
    en = "Filter",
    es = "Filtrar",
    fr = "Filtrer",
    de = "Filtern",
    pt = "Filtrar",
    it = "Filtra"
  ),
  list(
    en = "View",
    es = "Ver",
    fr = "Voir",
    de = "Ansehen",
    pt = "Ver",
    it = "Visualizza"
  ),
  list(
    en = "Create",
    es = "Crear",
    fr = "Créer",
    de = "Erstellen",
    pt = "Criar",
    it = "Crea"
  ),
  # DAPSI(W)R(M) Framework elements
  list(
    en = "Marine Processes & Functioning",
    es = "Procesos y Funcionamiento Marino",
    fr = "Processus et Fonctionnement Marins",
    de = "Marine Prozesse & Funktionsweise",
    pt = "Processos e Funcionamento Marinho",
    it = "Processi e Funzionamento Marino"
  ),
  list(
    en = "Ecosystem Services",
    es = "Servicios Ecosistémicos",
    fr = "Services Écosystémiques",
    de = "Ökosystemleistungen",
    pt = "Serviços Ecossistêmicos",
    it = "Servizi Ecosistemici"
  ),
  list(
    en = "Goods & Benefits",
    es = "Bienes y Beneficios",
    fr = "Biens et Avantages",
    de = "Güter & Vorteile",
    pt = "Bens e Benefícios",
    it = "Beni e Benefici"
  ),
  list(
    en = "Responses",
    es = "Respuestas",
    fr = "Réponses",
    de = "Reaktionen",
    pt = "Respostas",
    it = "Risposte"
  ),
  list(
    en = "Measures",
    es = "Medidas",
    fr = "Mesures",
    de = "Maßnahmen",
    pt = "Medidas",
    it = "Misure"
  ),
  # Status messages
  list(
    en = "Loading...",
    es = "Cargando...",
    fr = "Chargement...",
    de = "Wird geladen...",
    pt = "Carregando...",
    it = "Caricamento..."
  ),
  list(
    en = "Saving...",
    es = "Guardando...",
    fr = "Enregistrement...",
    de = "Speichern...",
    pt = "Salvando...",
    it = "Salvataggio..."
  ),
  list(
    en = "Success!",
    es = "¡Éxito!",
    fr = "Succès!",
    de = "Erfolg!",
    pt = "Sucesso!",
    it = "Successo!"
  ),
  list(
    en = "Error",
    es = "Error",
    fr = "Erreur",
    de = "Fehler",
    pt = "Erro",
    it = "Errore"
  ),
  list(
    en = "Warning",
    es = "Advertencia",
    fr = "Avertissement",
    de = "Warnung",
    pt = "Aviso",
    it = "Avviso"
  ),
  list(
    en = "Information",
    es = "Información",
    fr = "Information",
    de = "Information",
    pt = "Informação",
    it = "Informazione"
  ),
  list(
    en = "Please wait...",
    es = "Por favor espere...",
    fr = "Veuillez patienter...",
    de = "Bitte warten...",
    pt = "Por favor aguarde...",
    it = "Attendere prego..."
  ),
  list(
    en = "Processing...",
    es = "Procesando...",
    fr = "Traitement...",
    de = "Verarbeitung...",
    pt = "Processando...",
    it = "Elaborazione..."
  ),
  list(
    en = "No data available",
    es = "No hay datos disponibles",
    fr = "Aucune donnée disponible",
    de = "Keine Daten verfügbar",
    pt = "Nenhum dado disponível",
    it = "Nessun dato disponibile"
  ),
  list(
    en = "Data loaded successfully",
    es = "Datos cargados exitosamente",
    fr = "Données chargées avec succès",
    de = "Daten erfolgreich geladen",
    pt = "Dados carregados com sucesso",
    it = "Dati caricati con successo"
  ),
  list(
    en = "Select an option",
    es = "Seleccione una opción",
    fr = "Sélectionnez une option",
    de = "Wählen Sie eine Option",
    pt = "Selecione uma opção",
    it = "Seleziona un'opzione"
  ),
  # Project/Analysis terms
  list(
    en = "Project Name",
    es = "Nombre del Proyecto",
    fr = "Nom du Projet",
    de = "Projektname",
    pt = "Nome do Projeto",
    it = "Nome del Progetto"
  ),
  list(
    en = "Description",
    es = "Descripción",
    fr = "Description",
    de = "Beschreibung",
    pt = "Descrição",
    it = "Descrizione"
  ),
  list(
    en = "Location",
    es = "Ubicación",
    fr = "Emplacement",
    de = "Standort",
    pt = "Localização",
    it = "Posizione"
  ),
  list(
    en = "Date",
    es = "Fecha",
    fr = "Date",
    de = "Datum",
    pt = "Data",
    it = "Data"
  ),
  list(
    en = "Author",
    es = "Autor",
    fr = "Auteur",
    de = "Autor",
    pt = "Autor",
    it = "Autore"
  ),
  list(
    en = "Status",
    es = "Estado",
    fr = "Statut",
    de = "Status",
    pt = "Estado",
    it = "Stato"
  ),
  list(
    en = "Type",
    es = "Tipo",
    fr = "Type",
    de = "Typ",
    pt = "Tipo",
    it = "Tipo"
  ),
  list(
    en = "Category",
    es = "Categoría",
    fr = "Catégorie",
    de = "Kategorie",
    pt = "Categoria",
    it = "Categoria"
  ),
  list(
    en = "Name",
    es = "Nombre",
    fr = "Nom",
    de = "Name",
    pt = "Nome",
    it = "Nome"
  ),
  list(
    en = "Value",
    es = "Valor",
    fr = "Valeur",
    de = "Wert",
    pt = "Valor",
    it = "Valore"
  ),
  list(
    en = "Connection",
    es = "Conexión",
    fr = "Connexion",
    de = "Verbindung",
    pt = "Conexão",
    it = "Connessione"
  ),
  list(
    en = "From",
    es = "Desde",
    fr = "De",
    de = "Von",
    pt = "De",
    it = "Da"
  ),
  list(
    en = "To",
    es = "Hasta",
    fr = "À",
    de = "Bis",
    pt = "Para",
    it = "A"
  ),
  list(
    en = "Strength",
    es = "Fuerza",
    fr = "Force",
    de = "Stärke",
    pt = "Força",
    it = "Forza"
  ),
  list(
    en = "Positive",
    es = "Positivo",
    fr = "Positif",
    de = "Positiv",
    pt = "Positivo",
    it = "Positivo"
  ),
  list(
    en = "Negative",
    es = "Negativo",
    fr = "Négatif",
    de = "Negativ",
    pt = "Negativo",
    it = "Negativo"
  ),
  list(
    en = "Neutral",
    es = "Neutral",
    fr = "Neutre",
    de = "Neutral",
    pt = "Neutro",
    it = "Neutro"
  )
)

# Add complete translations
trans$translation <- c(trans$translation, complete_translations)

# Write back
write_json(trans, "translation.json", pretty = TRUE, auto_unbox = TRUE)

cat("Complete localization added successfully!\n")
cat("Total languages:", length(trans$languages), "\n")
cat("Total translations:", length(trans$translation), "\n")
