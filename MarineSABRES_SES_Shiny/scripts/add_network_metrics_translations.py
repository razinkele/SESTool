#!/usr/bin/env python3
"""
Add Network Metrics module translations to translation.json
"""
import json

# Network Metrics translations - all strings from the module
NETWORK_METRICS_TRANSLATIONS = [
    # Module title and description
    {
        "en": "Network Metrics Analysis",
        "es": "Análisis de Métricas de Red",
        "fr": "Analyse des Métriques de Réseau",
        "de": "Netzwerkmetrik-Analyse",
        "lt": "Tinklo metrikų analizė",
        "pt": "Análise de Métricas de Rede",
        "it": "Analisi delle Metriche di Rete"
    },
    {
        "en": "Calculate and visualize centrality metrics to identify key nodes and understand network structure.",
        "es": "Calcule y visualice métricas de centralidad para identificar nodos clave y comprender la estructura de la red.",
        "fr": "Calculez et visualisez les métriques de centralité pour identifier les nœuds clés et comprendre la structure du réseau.",
        "de": "Berechnen und visualisieren Sie Zentralitätsmetriken, um Schlüsselknoten zu identifizieren und die Netzwerkstruktur zu verstehen.",
        "lt": "Apskaičiuokite ir vizualizuokite centrinio svarbos metrikos, kad nustatytumėte pagrindinius mazgus ir suprastumėte tinklo struktūrą.",
        "pt": "Calcule e visualize métricas de centralidade para identificar nós-chave e compreender a estrutura da rede.",
        "it": "Calcola e visualizza le metriche di centralità per identificare i nodi chiave e comprendere la struttura della rete."
    },

    # Warning messages
    {
        "en": "No CLD data found.",
        "es": "No se encontraron datos CLD.",
        "fr": "Aucune donnée CLD trouvée.",
        "de": "Keine CLD-Daten gefunden.",
        "lt": "CLD duomenų nerasta.",
        "pt": "Nenhum dado CLD encontrado.",
        "it": "Nessun dato CLD trovato."
    },
    {
        "en": "Please generate a CLD network first using:",
        "es": "Por favor, genere primero una red CLD utilizando:",
        "fr": "Veuillez d'abord générer un réseau CLD en utilisant:",
        "de": "Bitte generieren Sie zuerst ein CLD-Netzwerk mit:",
        "lt": "Pirmiausia sugeneruokite CLD tinklą naudodami:",
        "pt": "Por favor, gere primeiro uma rede CLD usando:",
        "it": "Si prega di generare prima una rete CLD utilizzando:"
    },
    {
        "en": "Navigate to 'ISA Data Entry' and complete your SES model",
        "es": "Navegue a 'Entrada de Datos ISA' y complete su modelo SES",
        "fr": "Accédez à 'Saisie de Données ISA' et complétez votre modèle SES",
        "de": "Navigieren Sie zu 'ISA-Dateneingabe' und vervollständigen Sie Ihr SES-Modell",
        "lt": "Eikite į 'ISA duomenų įvedimas' ir užbaikite savo SES modelį",
        "pt": "Navegue para 'Entrada de Dados ISA' e complete o seu modelo SES",
        "it": "Vai a 'Immissione Dati ISA' e completa il tuo modello SES"
    },
    {
        "en": "Go to 'CLD Visualization' and click 'Generate CLD'",
        "es": "Vaya a 'Visualización CLD' y haga clic en 'Generar CLD'",
        "fr": "Allez dans 'Visualisation CLD' et cliquez sur 'Générer CLD'",
        "de": "Gehen Sie zu 'CLD-Visualisierung' und klicken Sie auf 'CLD Generieren'",
        "lt": "Eikite į 'CLD vizualizacija' ir spustelėkite 'Generuoti CLD'",
        "pt": "Vá para 'Visualização CLD' e clique em 'Gerar CLD'",
        "it": "Vai a 'Visualizzazione CLD' e fai clic su 'Genera CLD'"
    },
    {
        "en": "Return here to analyze network metrics",
        "es": "Regrese aquí para analizar las métricas de red",
        "fr": "Revenez ici pour analyser les métriques de réseau",
        "de": "Kehren Sie hierher zurück, um Netzwerkmetriken zu analysieren",
        "lt": "Grįžkite čia, kad analizuotumėte tinklo metrikos",
        "pt": "Retorne aqui para analisar as métricas de rede",
        "it": "Torna qui per analizzare le metriche di rete"
    },

    # Button labels
    {
        "en": "Calculate Network Metrics",
        "es": "Calcular Métricas de Red",
        "fr": "Calculer les Métriques de Réseau",
        "de": "Netzwerkmetriken Berechnen",
        "lt": "Apskaičiuoti tinklo metrikos",
        "pt": "Calcular Métricas de Rede",
        "it": "Calcola Metriche di Rete"
    },
    {
        "en": "Download Network Metrics",
        "es": "Descargar Métricas de Red",
        "fr": "Télécharger les Métriques de Réseau",
        "de": "Netzwerkmetriken Herunterladen",
        "lt": "Atsisiųsti tinklo metrikos",
        "pt": "Baixar Métricas de Rede",
        "it": "Scarica Metriche di Rete"
    },

    # Network-level metrics
    {
        "en": "Network Summary",
        "es": "Resumen de Red",
        "fr": "Résumé du Réseau",
        "de": "Netzwerkübersicht",
        "lt": "Tinklo santrauka",
        "pt": "Resumo da Rede",
        "it": "Riepilogo della Rete"
    },
    {
        "en": "Total Nodes",
        "es": "Total de Nodos",
        "fr": "Total de Nœuds",
        "de": "Gesamtknoten",
        "lt": "Viso mazgų",
        "pt": "Total de Nós",
        "it": "Totale Nodi"
    },
    {
        "en": "Total Edges",
        "es": "Total de Enlaces",
        "fr": "Total d'Arêtes",
        "de": "Gesamtkanten",
        "lt": "Viso ryšių",
        "pt": "Total de Arestas",
        "it": "Totale Archi"
    },
    {
        "en": "Network Density",
        "es": "Densidad de Red",
        "fr": "Densité du Réseau",
        "de": "Netzwerkdichte",
        "lt": "Tinklo tankis",
        "pt": "Densidade da Rede",
        "it": "Densità della Rete"
    },
    {
        "en": "Network Diameter",
        "es": "Diámetro de Red",
        "fr": "Diamètre du Réseau",
        "de": "Netzwerkdurchmesser",
        "lt": "Tinklo skersmuo",
        "pt": "Diâmetro da Rede",
        "it": "Diametro della Rete"
    },
    {
        "en": "Average Path Length",
        "es": "Longitud Promedio de Ruta",
        "fr": "Longueur Moyenne du Chemin",
        "de": "Durchschnittliche Pfadlänge",
        "lt": "Vidutinis kelio ilgis",
        "pt": "Comprimento Médio do Caminho",
        "it": "Lunghezza Media del Percorso"
    },
    {
        "en": "Network Connectivity",
        "es": "Conectividad de Red",
        "fr": "Connectivité du Réseau",
        "de": "Netzwerkkonnektivität",
        "lt": "Tinklo junglumas",
        "pt": "Conectividade da Rede",
        "it": "Connettività della Rete"
    },

    # Tab titles
    {
        "en": "All Metrics",
        "es": "Todas las Métricas",
        "fr": "Toutes les Métriques",
        "de": "Alle Metriken",
        "lt": "Visos metrikos",
        "pt": "Todas as Métricas",
        "it": "Tutte le Metriche"
    },
    {
        "en": "Visualizations",
        "es": "Visualizaciones",
        "fr": "Visualisations",
        "de": "Visualisierungen",
        "lt": "Vizualizacijos",
        "pt": "Visualizações",
        "it": "Visualizzazioni"
    },
    {
        "en": "Key Nodes",
        "es": "Nodos Clave",
        "fr": "Nœuds Clés",
        "de": "Schlüsselknoten",
        "lt": "Pagrindiniai mazgai",
        "pt": "Nós-Chave",
        "it": "Nodi Chiave"
    },
    {
        "en": "Guide",
        "es": "Guía",
        "fr": "Guide",
        "de": "Leitfaden",
        "lt": "Vadovas",
        "pt": "Guia",
        "it": "Guida"
    },

    # Column headers
    {
        "en": "Node ID",
        "es": "ID del Nodo",
        "fr": "ID du Nœud",
        "de": "Knoten-ID",
        "lt": "Mazgo ID",
        "pt": "ID do Nó",
        "it": "ID del Nodo"
    },
    {
        "en": "Node Label",
        "es": "Etiqueta del Nodo",
        "fr": "Étiquette du Nœud",
        "de": "Knotenbeschriftung",
        "lt": "Mazgo etiketė",
        "pt": "Rótulo do Nó",
        "it": "Etichetta del Nodo"
    },
    {
        "en": "Node Type",
        "es": "Tipo de Nodo",
        "fr": "Type de Nœud",
        "de": "Knotentyp",
        "lt": "Mazgo tipas",
        "pt": "Tipo de Nó",
        "it": "Tipo di Nodo"
    },

    # Centrality metrics
    {
        "en": "Degree Centrality",
        "es": "Centralidad de Grado",
        "fr": "Centralité de Degré",
        "de": "Gradzentralität",
        "lt": "Laipsnio centrinis svarba",
        "pt": "Centralidade de Grau",
        "it": "Centralità di Grado"
    },
    {
        "en": "In-Degree",
        "es": "Grado de Entrada",
        "fr": "Degré d'Entrée",
        "de": "Eingangsgrad",
        "lt": "Įėjimo laipsnis",
        "pt": "Grau de Entrada",
        "it": "Grado di Ingresso"
    },
    {
        "en": "Out-Degree",
        "es": "Grado de Salida",
        "fr": "Degré de Sortie",
        "de": "Ausgangsgrad",
        "lt": "Išėjimo laipsnis",
        "pt": "Grau de Saída",
        "it": "Grado di Uscita"
    },
    {
        "en": "Betweenness Centrality",
        "es": "Centralidad de Intermediación",
        "fr": "Centralité d'Intermédiarité",
        "de": "Zwischenzentralität",
        "lt": "Tarpininkavimo centrinis svarba",
        "pt": "Centralidade de Intermediação",
        "it": "Centralità di Betweenness"
    },
    {
        "en": "Closeness Centrality",
        "es": "Centralidad de Cercanía",
        "fr": "Centralité de Proximité",
        "de": "Nähezentralität",
        "lt": "Artumo centrinis svarba",
        "pt": "Centralidade de Proximidade",
        "it": "Centralità di Vicinanza"
    },
    {
        "en": "Eigenvector Centrality",
        "es": "Centralidad de Vector Propio",
        "fr": "Centralité de Vecteur Propre",
        "de": "Eigenvektorzentralität",
        "lt": "Tikrinio vektoriaus centrinis svarba",
        "pt": "Centralidade de Vetor Próprio",
        "it": "Centralità di Autovettore"
    },
    {
        "en": "PageRank",
        "es": "PageRank",
        "fr": "PageRank",
        "de": "PageRank",
        "lt": "PageRank",
        "pt": "PageRank",
        "it": "PageRank"
    },

    # Visualization controls
    {
        "en": "Select Metric",
        "es": "Seleccionar Métrica",
        "fr": "Sélectionner la Métrique",
        "de": "Metrik Auswählen",
        "lt": "Pasirinkti metriką",
        "pt": "Selecionar Métrica",
        "it": "Seleziona Metrica"
    },
    {
        "en": "Top N Nodes",
        "es": "Top N Nodos",
        "fr": "Top N Nœuds",
        "de": "Top N Knoten",
        "lt": "Top N mazgai",
        "pt": "Top N Nós",
        "it": "Top N Nodi"
    },
    {
        "en": "Bar Plot - Top Nodes by Selected Metric",
        "es": "Gráfico de Barras - Nodos Principales por Métrica Seleccionada",
        "fr": "Graphique à Barres - Nœuds Principaux par Métrique Sélectionnée",
        "de": "Balkendiagramm - Top-Knoten nach Ausgewählter Metrik",
        "lt": "Stulpelinė diagrama - Pagrindiniai mazgai pagal pasirinktą metriką",
        "pt": "Gráfico de Barras - Nós Principais por Métrica Selecionada",
        "it": "Grafico a Barre - Nodi Principali per Metrica Selezionata"
    },
    {
        "en": "Comparison Plot - Degree vs Betweenness",
        "es": "Gráfico de Comparación - Grado vs Intermediación",
        "fr": "Graphique de Comparaison - Degré vs Intermédiarité",
        "de": "Vergleichsdiagramm - Grad vs Zwischen",
        "lt": "Palyginimo diagrama - Laipsnis vs Tarpininkavimas",
        "pt": "Gráfico de Comparação - Grau vs Intermediação",
        "it": "Grafico di Confronto - Grado vs Betweenness"
    },
    {
        "en": "Distribution Histogram",
        "es": "Histograma de Distribución",
        "fr": "Histogramme de Distribution",
        "de": "Verteilungshistogramm",
        "lt": "Pasiskirstymo histograma",
        "pt": "Histograma de Distribuição",
        "it": "Istogramma di Distribuzione"
    },
    {
        "en": "Bubble size represents PageRank",
        "es": "El tamaño de la burbuja representa PageRank",
        "fr": "La taille de la bulle représente le PageRank",
        "de": "Blasengröße steht für PageRank",
        "lt": "Burbulo dydis atspindi PageRank",
        "pt": "O tamanho da bolha representa o PageRank",
        "it": "La dimensione della bolla rappresenta il PageRank"
    },
    {
        "en": "Mean",
        "es": "Media",
        "fr": "Moyenne",
        "de": "Mittelwert",
        "lt": "Vidurkis",
        "pt": "Média",
        "it": "Media"
    },
    {
        "en": "Median",
        "es": "Mediana",
        "fr": "Médiane",
        "de": "Median",
        "lt": "Mediana",
        "pt": "Mediana",
        "it": "Mediana"
    },

    # Key nodes sections
    {
        "en": "Top 5 Nodes by Degree",
        "es": "Top 5 Nodos por Grado",
        "fr": "Top 5 Nœuds par Degré",
        "de": "Top 5 Knoten nach Grad",
        "lt": "Top 5 mazgai pagal laipsnį",
        "pt": "Top 5 Nós por Grau",
        "it": "Top 5 Nodi per Grado"
    },
    {
        "en": "Top 5 Nodes by Betweenness",
        "es": "Top 5 Nodos por Intermediación",
        "fr": "Top 5 Nœuds par Intermédiarité",
        "de": "Top 5 Knoten nach Zwischen",
        "lt": "Top 5 mazgai pagal tarpininkavimą",
        "pt": "Top 5 Nós por Intermediação",
        "it": "Top 5 Nodi per Betweenness"
    },
    {
        "en": "Top 5 Nodes by Closeness",
        "es": "Top 5 Nodos por Cercanía",
        "fr": "Top 5 Nœuds par Proximité",
        "de": "Top 5 Knoten nach Nähe",
        "lt": "Top 5 mazgai pagal artumą",
        "pt": "Top 5 Nós por Proximidade",
        "it": "Top 5 Nodi per Vicinanza"
    },
    {
        "en": "Top 5 Nodes by PageRank",
        "es": "Top 5 Nodos por PageRank",
        "fr": "Top 5 Nœuds par PageRank",
        "de": "Top 5 Knoten nach PageRank",
        "lt": "Top 5 mazgai pagal PageRank",
        "pt": "Top 5 Nós por PageRank",
        "it": "Top 5 Nodi per PageRank"
    },
    {
        "en": "Most connected nodes in the network",
        "es": "Nodos más conectados en la red",
        "fr": "Nœuds les plus connectés du réseau",
        "de": "Am meisten verbundene Knoten im Netzwerk",
        "lt": "Labiausiai susiję mazgai tinkle",
        "pt": "Nós mais conectados na rede",
        "it": "Nodi più connessi nella rete"
    },
    {
        "en": "Critical bridge nodes connecting different parts",
        "es": "Nodos puente críticos que conectan diferentes partes",
        "fr": "Nœuds de pont critiques reliant différentes parties",
        "de": "Kritische Brückenknoten, die verschiedene Teile verbinden",
        "lt": "Kritiniai tilto mazgai, jungiantys skirtingas dalis",
        "pt": "Nós de ponte críticos conectando diferentes partes",
        "it": "Nodi ponte critici che collegano diverse parti"
    },
    {
        "en": "Most central nodes with shortest paths to others",
        "es": "Nodos más centrales con rutas más cortas a otros",
        "fr": "Nœuds les plus centraux avec les chemins les plus courts vers les autres",
        "de": "Zentralste Knoten mit kürzesten Pfaden zu anderen",
        "lt": "Centriškiausi mazgai su trumpiausiais keliais į kitus",
        "pt": "Nós mais centrais com caminhos mais curtos para outros",
        "it": "Nodi più centrali con percorsi più brevi verso gli altri"
    },
    {
        "en": "Most influential nodes based on incoming connections",
        "es": "Nodos más influyentes basados en conexiones entrantes",
        "fr": "Nœuds les plus influents basés sur les connexions entrantes",
        "de": "Einflussreichste Knoten basierend auf eingehenden Verbindungen",
        "lt": "Įtakingiausi mazgai pagal įeinančius ryšius",
        "pt": "Nós mais influentes com base em conexões de entrada",
        "it": "Nodi più influenti in base alle connessioni in entrata"
    },

    # Success/notification messages
    {
        "en": "Network metrics calculated successfully!",
        "es": "¡Métricas de red calculadas con éxito!",
        "fr": "Métriques de réseau calculées avec succès!",
        "de": "Netzwerkmetriken erfolgreich berechnet!",
        "lt": "Tinklo metrikos sėkmingai apskaičiuotos!",
        "pt": "Métricas de rede calculadas com sucesso!",
        "it": "Metriche di rete calcolate con successo!"
    },
    {
        "en": "Error calculating metrics:",
        "es": "Error al calcular métricas:",
        "fr": "Erreur lors du calcul des métriques:",
        "de": "Fehler beim Berechnen von Metriken:",
        "lt": "Klaida skaičiuojant metrikos:",
        "pt": "Erro ao calcular métricas:",
        "it": "Errore nel calcolo delle metriche:"
    },

    # Guide content
    {
        "en": "Network Metrics Guide",
        "es": "Guía de Métricas de Red",
        "fr": "Guide des Métriques de Réseau",
        "de": "Netzwerkmetrik-Leitfaden",
        "lt": "Tinklo metrikų vadovas",
        "pt": "Guia de Métricas de Rede",
        "it": "Guida alle Metriche di Rete"
    },
    {
        "en": "Understanding Centrality Metrics",
        "es": "Comprender las Métricas de Centralidad",
        "fr": "Comprendre les Métriques de Centralité",
        "de": "Verständnis der Zentralitätsmetriken",
        "lt": "Centrinio svarbos metrikų supratimas",
        "pt": "Compreendendo as Métricas de Centralidade",
        "it": "Comprendere le Metriche di Centralità"
    },
    {
        "en": "Total number of connections (in + out). High values indicate hub nodes.",
        "es": "Número total de conexiones (entrada + salida). Valores altos indican nodos concentradores.",
        "fr": "Nombre total de connexions (entrée + sortie). Des valeurs élevées indiquent des nœuds hub.",
        "de": "Gesamtzahl der Verbindungen (eingehend + ausgehend). Hohe Werte weisen auf Hub-Knoten hin.",
        "lt": "Bendras ryšių skaičius (įėjimas + išėjimas). Didelės reikšmės rodo koncentratoriaus mazgus.",
        "pt": "Número total de conexões (entrada + saída). Valores altos indicam nós concentradores.",
        "it": "Numero totale di connessioni (in + out). Valori elevati indicano nodi hub."
    },
    {
        "en": "How often a node lies on the shortest path between other nodes. Important for information flow.",
        "es": "Con qué frecuencia un nodo se encuentra en el camino más corto entre otros nodos. Importante para el flujo de información.",
        "fr": "À quelle fréquence un nœud se trouve sur le chemin le plus court entre d'autres nœuds. Important pour le flux d'informations.",
        "de": "Wie oft ein Knoten auf dem kürzesten Pfad zwischen anderen Knoten liegt. Wichtig für den Informationsfluss.",
        "lt": "Kaip dažnai mazgas yra trumpiausiame kelyje tarp kitų mazgų. Svarbu informacijos srautui.",
        "pt": "Com que frequência um nó está no caminho mais curto entre outros nós. Importante para o fluxo de informações.",
        "it": "Quanto spesso un nodo si trova sul percorso più breve tra altri nodi. Importante per il flusso di informazioni."
    },
    {
        "en": "Average distance to all other nodes. High values indicate central position in network.",
        "es": "Distancia promedio a todos los demás nodos. Valores altos indican posición central en la red.",
        "fr": "Distance moyenne à tous les autres nœuds. Des valeurs élevées indiquent une position centrale dans le réseau.",
        "de": "Durchschnittliche Entfernung zu allen anderen Knoten. Hohe Werte weisen auf eine zentrale Position im Netzwerk hin.",
        "lt": "Vidutinis atstumas iki visų kitų mazgų. Didelės reikšmės rodo centrinę poziciją tinkle.",
        "pt": "Distância média para todos os outros nós. Valores altos indicam posição central na rede.",
        "it": "Distanza media da tutti gli altri nodi. Valori elevati indicano una posizione centrale nella rete."
    },
    {
        "en": "Influence based on connections to other influential nodes. Considers network structure.",
        "es": "Influencia basada en conexiones con otros nodos influyentes. Considera la estructura de la red.",
        "fr": "Influence basée sur les connexions avec d'autres nœuds influents. Considère la structure du réseau.",
        "de": "Einfluss basierend auf Verbindungen zu anderen einflussreichen Knoten. Berücksichtigt die Netzwerkstruktur.",
        "lt": "Įtaka pagrįsta ryšiais su kitais įtakingais mazgais. Atsižvelgia į tinklo struktūrą.",
        "pt": "Influência baseada em conexões com outros nós influentes. Considera a estrutura da rede.",
        "it": "Influenza basata su connessioni con altri nodi influenti. Considera la struttura della rete."
    },
    {
        "en": "Importance based on incoming links (Google algorithm). High values indicate authority.",
        "es": "Importancia basada en enlaces entrantes (algoritmo de Google). Valores altos indican autoridad.",
        "fr": "Importance basée sur les liens entrants (algorithme Google). Des valeurs élevées indiquent l'autorité.",
        "de": "Wichtigkeit basierend auf eingehenden Links (Google-Algorithmus). Hohe Werte weisen auf Autorität hin.",
        "lt": "Svarba pagrįsta įeinančiais nuorodomis (Google algoritmas). Didelės reikšmės rodo autoritetą.",
        "pt": "Importância baseada em links de entrada (algoritmo do Google). Valores altos indicam autoridade.",
        "it": "Importanza basata su link in entrata (algoritmo Google). Valori elevati indicano autorità."
    },
    {
        "en": "Use Cases",
        "es": "Casos de Uso",
        "fr": "Cas d'Utilisation",
        "de": "Anwendungsfälle",
        "lt": "Naudojimo atvejai",
        "pt": "Casos de Uso",
        "it": "Casi d'Uso"
    },
    {
        "en": "Identify intervention points (high betweenness nodes)",
        "es": "Identificar puntos de intervención (nodos de alta intermediación)",
        "fr": "Identifier les points d'intervention (nœuds à haute intermédiarité)",
        "de": "Interventionspunkte identifizieren (Knoten mit hoher Zwischenzentralität)",
        "lt": "Nustatyti intervencijos taškus (didelio tarpininkavimo mazgai)",
        "pt": "Identificar pontos de intervenção (nós de alta intermediação)",
        "it": "Identificare i punti di intervento (nodi ad alta betweenness)"
    },
    {
        "en": "Find key stakeholders (high degree nodes)",
        "es": "Encontrar partes interesadas clave (nodos de alto grado)",
        "fr": "Trouver les parties prenantes clés (nœuds de haut degré)",
        "de": "Schlüsselakteure finden (Knoten mit hohem Grad)",
        "lt": "Rasti pagrindinius suinteresuotus subjektus (didelio laipsnio mazgai)",
        "pt": "Encontrar partes interessadas-chave (nós de alto grau)",
        "it": "Trovare le parti interessate chiave (nodi ad alto grado)"
    },
    {
        "en": "Understand system connectivity and structure",
        "es": "Comprender la conectividad y estructura del sistema",
        "fr": "Comprendre la connectivité et la structure du système",
        "de": "Systemkonnektivität und -struktur verstehen",
        "lt": "Suprasti sistemos junglumą ir struktūrą",
        "pt": "Compreender a conectividade e estrutura do sistema",
        "it": "Comprendere la connettività e la struttura del sistema"
    },
    {
        "en": "Assess system vulnerabilities (critical bridge nodes)",
        "es": "Evaluar vulnerabilidades del sistema (nodos puente críticos)",
        "fr": "Évaluer les vulnérabilités du système (nœuds de pont critiques)",
        "de": "Systemschwachstellen bewerten (kritische Brückenknoten)",
        "lt": "Įvertinti sistemos pažeidžiamumą (kritiniai tilto mazgai)",
        "pt": "Avaliar vulnerabilidades do sistema (nós de ponte críticos)",
        "it": "Valutare le vulnerabilità del sistema (nodi ponte critici)"
    }
]

def add_translations_to_file(json_file_path):
    """Add Network Metrics translations to the translation.json file"""

    # Read existing translations
    with open(json_file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Get current count
    original_count = len(data['translation'])

    # Add new translations
    data['translation'].extend(NETWORK_METRICS_TRANSLATIONS)

    # Write back
    with open(json_file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    new_count = len(data['translation'])
    added = new_count - original_count

    print(f"[OK] Successfully added {added} Network Metrics translations")
    print(f"   Original count: {original_count}")
    print(f"   New count: {new_count}")
    print(f"\nTranslations added for all 7 languages:")
    for lang in data['languages']:
        print(f"   - {lang}")

if __name__ == "__main__":
    json_file = "translations/translation.json"
    add_translations_to_file(json_file)
