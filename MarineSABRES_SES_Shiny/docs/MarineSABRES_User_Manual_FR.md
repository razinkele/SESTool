---
title: "Boîte à Outils SES MarineSABRES - Manuel d'Utilisation"
subtitle: "Plateforme d'Analyse des Systèmes Socio-Écologiques"
author: "Projet MarineSABRES"
date: "Version 1.10.0 - Mars 2026"
lang: fr
toc: true
toc-depth: 3
numbersections: true
geometry: margin=2.5cm
fontsize: 11pt
documentclass: article
papersize: a4
---

\newpage

# Introduction

## À Propos de la Boîte à Outils SES MarineSABRES

La **Boîte à Outils des Systèmes Socio-Écologiques (SES) MarineSABRES** est une application web complète conçue pour soutenir l'analyse participative et la gestion des systèmes socio-écologiques marins. Elle met en œuvre le **cadre DAPSI(W)R(M)** (Drivers-Activities-Pressures-State changes-Welfare impacts-Response Measures / Moteurs-Activités-Pressions-Changements d'État-Impacts sur le Bien-être-Mesures de Réponse) pour analyser les interactions complexes entre les écosystèmes marins et les activités humaines.

> **Note sur la Terminologie du Cadre:** Dans DAPSI(W)R(M), "R" et "M" font référence aux Réponses politiques/de gestion et aux Mesures d'application. Cet outil les traite comme une catégorie unifiée "Mesures de Réponse" pour représenter de manière exhaustive les interventions de gestion.

### Capacités Clés

- **Analyse Intégrée des Systèmes (ISA)**: Approche structurée en 13 exercices pour cartographier les relations de cause à effet
- **Création Assistée par IA**: Interface conversationnelle pour une cartographie rapide du système
- **Visualisation Interactive**: Diagrammes de Boucles Causales (CLD) dynamiques avec des layouts réseau avancés
- **Détection des Boucles de Rétroaction**: Identification automatique des boucles de renforcement et d'équilibrage
- **Analyse de Réseau**: Métriques de centralité, points de levier et analyse MICMAC
- **Planification des Réponses**: Priorisation et évaluation d'impact des interventions de gestion
- **Gestion des Parties Prenantes**: Analyse Pouvoir-Intérêt et planification de l'engagement
- **Recommandations Contextuelles**: Orientations stratégiques et de gestion basées sur les données
- **Support Multilingue**: Disponible en 9 langues (EN, ES, FR, DE, LT, PT, IT, NO, EL)
- **Attributs de Délai Temporel** : Capturer les relations de décalage temporel entre les connexions
- **Base de Connaissances** : 1 120 connexions scientifiquement validées à travers 30 contextes d'écosystèmes marins
- **Gouvernance par Pays** : 97 pays avec suggestions d'éléments de gouvernance et socio-économiques
- **Système de Modèles** : 7 modèles SES pré-construits pour les scénarios marins courants

## Utilisateurs Cibles

- **Gestionnaires de Ressources Marines**: Planifier et évaluer les interventions de gestion
- **Analystes Politiques**: Évaluer les impacts des politiques sur les systèmes marins
- **Consultants Environnementaux**: Soutenir la planification spatiale marine et les évaluations d'impact
- **Chercheurs**: Étudier la dynamique des systèmes socio-écologiques marins
- **Facilitateurs de Parties Prenantes**: Guider les ateliers de cartographie participative du système

## Exigences Système

### Logiciels Requis
- **R** version 4.4.1 ou supérieure
- **Navigateur Web Moderne**: Chrome (recommandé), Firefox, Edge ou Safari
- **Optionnel**: Pandoc (pour la génération de rapports PDF/Word)

### Matériel Requis
- **Processeur**: Dual-core 2.0 GHz ou plus rapide
- **RAM**: 4 GB minimum, 8 GB recommandé
- **Stockage**: 500 MB d'espace disque libre
- **Affichage**: Résolution minimale 1366x768, 1920x1080 recommandé

### Connexion Internet
- Requis uniquement pour l'installation initiale des packages R
- Fonctionnement hors ligne supporté après installation

\newpage

# Nouveautés

## Version 1.10.0 (Mars 2026)

### Revue Qualité & Validation Scientifique de la Base de Connaissances
- 68 erreurs de classification d'éléments corrigées dans la base DAPSI(W)R(M)
- 213 attributs de connexion validés scientifiquement par rapport à la littérature publiée (HELCOM, ICES, OSPAR, UNEP-MAP, GCRMN, GIEC RE6, AMAP)
- 1 120 connexions totales à travers 30 contextes d'écosystèmes marins (contre 622 précédemment)
- Zéro éléments orphelins — chaque élément connecté à au moins un autre
- Distribution de confiance recalibrée selon les niveaux de preuve
- Références de la BC accessibles depuis le menu Aide dans la barre supérieure

### Améliorations de Gouvernance & Socio-Économiques
- 2 nouvelles conventions régionales : PROE/Nouméa (Pacifique) et Abidjan (Afrique de l'Ouest)
- Lacunes de gouvernance comblées pour 4 groupes (Européens non-UE, Latino-Américains, Côtiers Africains, Asie-Pacifique)
- 16 reclassifications d'éléments de gouvernance/SE pour plus de précision

### Améliorations de la Revue des Connexions
- Nouveaux onglets de lots W→D, P→P et S→S pour les boucles de rétroaction et effets en cascade
- Persistance du bouton de délai entre les changements d'onglets
- Labels de force/confiance et infobulles internationalisés

## Version 1.9.0 (Mars 2026)

### Attributs de Délai Temporel
- Catégories de délai pour les connexions : immédiat, court terme, moyen terme, long terme
- Motifs de tirets visuels sur les arêtes du réseau indiquant le délai
- Cartes de revue des connexions avec bouton de délai, menu déroulant et saisie numérique
- Support complet d'import et export Excel/Kumu pour les colonnes de délai
- Rétro-compatible avec les fichiers de projet antérieurs

## Version 1.8.1 (Mars 2026)

### Audit & Nettoyage du Code Source
- 12 corrections de bogues critiques dans 20 fichiers
- Suppression de code mort et renforcement des tests

## Version 1.8.0 (Mars 2026)

### Base de Connaissances & Gouvernance par Pays
- Base de données de gouvernance par pays avec 97 pays sur 11 mers régionales
- Module de construction graphique de réseau SES
- Système de tutoriels avec visites guidées
- Chargeur Excel universel pour l'import flexible de modèles SES
- Registre de modèles ML et infrastructure d'embeddings textuels

\newpage

# Démarrage

## Installation

### Étape 1: Installer R et RStudio

1. **Télécharger R** depuis [https://cran.r-project.org/](https://cran.r-project.org/)
2. **Télécharger RStudio** (optionnel mais recommandé) depuis [https://posit.co/downloads/](https://posit.co/downloads/)
3. Installer les deux applications en suivant les procédures standard

### Étape 2: Installer les Packages Requis

Ouvrir R ou RStudio et exécuter:

```r
# Installer les packages requis
install.packages(c(
  "shiny", "shinydashboard", "shinyjs", "shiny.i18n",
  "DT", "dplyr", "tidyr", "ggplot2", "plotly",
  "visNetwork", "igraph", "DiagrammeR",
  "openxlsx", "jsonlite", "rmarkdown", "knitr",
  "digest", "htmlwidgets"
))
```

### Étape 3: Lancer l'Application

```r
# Définir le répertoire de travail
setwd("/chemin/vers/MarineSABRES_SES_Shiny")

# Lancer l'application
shiny::runApp()
```

**Alternative avec run_app.R:**

```bash
cd /chemin/vers/MarineSABRES_SES_Shiny
Rscript run_app.R
```

## Premier Lancement

### Vue d'Ensemble de l'Interface

Au lancement, vous verrez le **Tableau de Bord** avec:

**Barre d'En-tête:**
- Titre et logo de l'application
- Sélecteur de langue (9 langues disponibles)
- Sélecteur de niveau utilisateur (Débutant/Intermédiaire/Expert)
- Bouton d'aide

**Menu Latéral:**
- Navigation vers tous les modules
- Boutons Sauvegarder/Charger projet
- Indicateur de sauvegarde automatique

**Panneau Principal:**
- Boîtes de valeur récapitulatives (éléments, connexions, boucles, % d'achèvement)
- Vue d'ensemble du statut du projet
- Boutons d'action rapide

### Créer Votre Premier Projet

1. **Naviguer vers Point d'Entrée** (Démarrage)
   - Choisir "Parcours Guidé" ou "Accès Rapide"
   - Répondre aux questions contextuelles sur votre rôle et objectifs
   - Recevoir des recommandations d'outils personnalisées

2. **Configurer les Informations du Projet** (PIMS → Configuration du Projet)
   - Entrer le nom du projet
   - Sélectionner la zone de démonstration
   - Définir le problème focal
   - Spécifier les limites du système

3. **Choisir Votre Flux de Travail**
   - **ISA Standard**: Approche structurée en 13 exercices (recommandé pour une analyse approfondie)
   - **Assisté par IA**: Entretien conversationnel en 11 étapes (voie rapide pour utilisateurs expérimentés)
   - **Basé sur Modèle**: Modèles pré-configurés pour scénarios courants
   - **Importer Données**: Charger des données ISA existantes depuis Excel

4. **Sauvegarder Votre Travail**
   - Cliquer sur "Sauvegarder Projet" dans la barre latérale
   - Choisir un nom de fichier (ex: `mon_projet_2025-11-16.rds`)
   - Sauvegarder régulièrement tout au long de votre session

\newpage

# Modules Principaux

## PIMS (Système de Gestion d'Information Projet)

### Configuration du Projet

Définir la portée et le contexte de votre analyse.

**Champs à Compléter:**

- **Nom du Projet**: Identifiant unique pour votre projet
- **ID Projet**: Code auto-généré ou personnalisé
- **Zone de Démonstration**: Focus géographique
  - Archipel Toscan
  - Atlantique Nord-Est Arctique
  - Macaronésie
  - Personnalisé (spécifier)

- **Problème Focal**: Question ou préoccupation de gestion primaire
- **Échelle Temporelle**: Horizon temporel (années/décennies/siècles)
- **Échelle Spatiale**: Étendue géographique (local/régional/national/international)
- **Limites du Système**: Ce qui est inclus/exclu de l'analyse

**Meilleures Pratiques:**
- Être spécifique sur le problème focal (ex: "Déclin des herbiers marins dû à la pollution nutritive" vs "Qualité de l'eau")
- Définir clairement les limites pour délimiter votre analyse
- Considérer plusieurs échelles temporelles pour différents composants du système

### Gestion des Parties Prenantes

Identifier et catégoriser les parties prenantes dans votre système marin.

**Registre des Parties Prenantes:**

Créer des entrées avec:
- **Nom**: Nom de l'organisation ou du groupe
- **Type**:
  - Contributeurs (fournissent ressources/intrants)
  - Extracteurs (récoltent/retirent des ressources)
  - Régulateurs (établissent règles/politiques)
  - Affectés (subissent des impacts)
  - Bénéficiaires (reçoivent des bénéfices)
  - Influenceurs (façonnent les décisions)
- **Informations de Contact**: Email, téléphone, adresse
- **Pouvoir**: Niveau d'influence (Élevé/Moyen/Faible)
- **Intérêt**: Enjeu dans les résultats (Élevé/Moyen/Faible)
- **Niveau d'Engagement**: Participation actuelle (spectre IAP2)
  - Informer
  - Consulter
  - Impliquer
  - Collaborer
  - Responsabiliser
- **Notes**: Contexte additionnel

**Grille Pouvoir-Intérêt:**

Matrice visuelle positionnant automatiquement les parties prenantes par pouvoir et intérêt:
- **Pouvoir Élevé, Intérêt Élevé**: Acteurs clés - collaborer étroitement
- **Pouvoir Élevé, Intérêt Faible**: Maintenir satisfaits - mises à jour régulières
- **Pouvoir Faible, Intérêt Élevé**: Maintenir informés - engager activement
- **Pouvoir Faible, Intérêt Faible**: Surveiller - effort minimal

**Export:** Télécharger le registre des parties prenantes en Excel pour partage externe

\newpage

## Créer SES (Système Socio-Écologique)

### Méthode 1: Saisie ISA Standard

Approche structurée complète en 13 exercices suivant le cadre DAPSI(W)R(M).

#### Exercice 0: Cadrage de la Complexité

Établir le contexte pour votre analyse.

**Questions Clés:**
1. Quelle est la zone d'étude de cas?
2. Quelle est la portée géographique et temporelle?
3. Quels impacts sur le bien-être sont préoccupants?
4. Qui sont les parties prenantes clés?

**Résultat:** Fondation contextuelle pour les exercices suivants

#### Exercice 1: Biens & Bénéfices (B&B)

Identifier les résultats valorisés du système marin.

**Formulaire de Saisie de Données:**
- **ID**: Identifiant unique auto-généré
- **Nom**: Nom descriptif (ex: "Capture de poissons commerciaux")
- **Type**:
  - Approvisionnement (nourriture, matériaux)
  - Régulation (climat, qualité de l'eau)
  - Culturel (récréation, patrimoine)
  - Support (cycle des nutriments, habitat)
- **Description**: Explication détaillée
- **Partie Prenante**: Qui bénéficie?
- **Importance**: Signification socio-économique (Élevée/Moyenne/Faible)
- **Tendance**: Trajectoire historique (Croissante/Stable/Décroissante/Inconnue)

**Table Interactive:**
- Ajouter, éditer, supprimer des entrées
- Trier et filtrer par n'importe quelle colonne
- Fonctionnalité de recherche
- Export vers Excel

#### Exercice 2a: Services Écosystémiques (SE)

Cartographier les services qui soutiennent les biens et bénéfices.

**Champs:**
- **Nom**: Description du service (ex: "Reconstitution des stocks de poissons")
- **Type**: Approvisionnement/Régulation/Culturel/Support
- **B&B Liés**: Sélectionner quels biens/bénéfices ce service soutient
- **Mécanisme**: Comment le service fournit le bénéfice
- **Confiance**: Qualité de la preuve (Élevée/Moyenne/Faible)

**Matrice d'Adjacence:**
- Lignes: Services Écosystémiques
- Colonnes: Biens & Bénéfices
- Cellules: Force de la relation
  - `+fort`, `+moyen`, `+faible` (contributions positives)
  - Vide (pas de relation)

#### Exercice 2b: Processus & Fonctionnement Marins (PFM)

Identifier les processus écologiques qui permettent les services.

**Champs Additionnels:**
- **Type de Processus**: Biologique/Chimique/Physique
- **Sensibilité**: Vulnérabilité au changement (Élevée/Moyenne/Faible)
- **Échelle Spatiale**: Étendue géographique (m²/km²/régional)

**Exemples:**
- Biologique: "Photosynthèse des herbiers marins"
- Chimique: "Absorption de nutriments par les macroalgues"
- Physique: "Stabilisation des sédiments par les racines"

#### Exercice 3: Pressions (P)

Documenter les facteurs de stress affectant les processus marins.

**Catégories de Pression (alignées avec DCSMM):**
- Physique: Étouffement, abrasion, perte d'habitat
- Chimique: Contaminants, nutriments, acidification
- Biologique: Introduction d'espèces, pathogènes
- Autre: Bruit, lumière, champs électromagnétiques

**Champs:**
- **Intensité**: Magnitude de la pression (Élevée/Moyenne/Faible/Inconnue)
- **Modèle Spatial**: Source ponctuelle/Diffuse/Régionale
- **Modèle Temporel**: Continue/Saisonnière/Épisodique/Permanente

#### Exercice 4: Activités (A)

Identifier les actions humaines qui génèrent des pressions.

**Secteurs d'Activité:**
- Pêche (Commerciale/Récréative)
- Aquaculture
- Tourisme et Récréation
- Navigation et Transport
- Production d'Énergie
- Développement Côtier
- Agriculture et Sylviculture
- Industrie et Extraction Minière
- Élimination des Déchets
- Recherche et Surveillance

**Champs:**
- **Échelle**: Étendue opérationnelle (Local/Régional/National/International)
- **Fréquence**: À quelle fréquence (Quotidienne/Hebdomadaire/Saisonnière/Annuelle/Irrégulière)

#### Exercice 5: Moteurs (M)

Analyser les causes profondes derrière les activités.

**Types de Moteurs:**
- **Économique**: Demande du marché, prix, subventions, commerce
- **Social**: Population, démographie, mode de vie, traditions
- **Technologique**: Innovation, efficacité, capacité
- **Environnemental**: Climat, disponibilité des ressources
- **Politique/Institutionnel**: Réglementations, gouvernance, droits de propriété

**Champs:**
- **Tendance**: Direction du changement (Croissante/Stable/Décroissante/Cyclique)
- **Contrôlabilité**: Peut-il être géré? (Élevée/Moyenne/Faible/Aucune)

#### Exercice 6: Fermeture de Boucle (Rétroaction)

Compléter la chaîne causale avec les réponses du bien-être vers les moteurs.

**Connexions de Rétroaction:**
- Sélectionner B&B (point de départ)
- Sélectionner Moteur (point d'arrivée)
- Spécifier:
  - **Type d'Effet**: Positif (amplification) / Négatif (atténuation)
  - **Force**: Fort/Moyen/Faible
  - **Confiance**: Élevée/Moyenne/Faible
  - **Délai**: Immédiat/Court terme/Moyen terme/Long terme (durée optionnelle en années)
  - **Mécanisme**: Voie explicative

#### Exercice 7-9: Création de CLD

**Exercice 7**: Examiner tous les éléments et connexions
**Exercice 8**: Générer le Diagramme de Boucles Causales
**Exercice 9**: Exporter vers des plateformes de visualisation (Kumu.io)

#### Exercice 10-12: Analyse & Documentation

**Exercice 10**: Analyse de la dynamique du système
**Exercice 11**: Graphiques de Comportement dans le Temps (BOT)
**Exercice 12**: Documentation de validation

#### Onglet Gestion des Données

**Importer depuis Excel:**
1. Télécharger le modèle (bouton fourni)
2. Remplir le modèle avec vos données
3. Téléverser le fichier Excel complété
4. Examiner l'aperçu d'importation
5. Confirmer l'importation (fusionner ou remplacer les données existantes)

**Exporter vers Excel:**
- Classeur multi-feuilles
- Tous les tableaux ISA inclus (y compris les colonnes de Délai)
- Matrices d'adjacence
- Compatible avec le format Kumu.io
- Prêt pour l'analyse externe

\newpage

### Méthode 2: Création ISA Assistée par IA

Guidance conversationnelle étape par étape pour une cartographie rapide du système.

**Processus d'Entretien en 11 Étapes:**

**Étape 1: Introduction**
- Accueil et vue d'ensemble
- Explication du processus
- Temps estimé: 30-60 minutes

**Étape 2: Contexte du Projet**
- Nom et description du projet
- Objectifs primaires
- Résultats attendus

**Étape 3: Sélection de la Mer Régionale**
Choisir parmi 13 mers régionales:
- Mer Baltique
- Mer Méditerranée
- Mer Noire
- Atlantique Nord-Est
- Océan Arctique
- Et 8 autres...

**Étape 4: Type d'Écosystème**
12 catégories d'écosystèmes:
- Herbiers marins
- Récifs coralliens
- Forêts de kelp
- Récifs rocheux
- Plages de sable
- Vasières
- Estuaires
- Mer profonde
- Et 4 autres...

**Étape 5: Sous-type d'Écosystème**
Raffinement contextuel basé sur la sélection de l'Étape 4

**Étape 6: Problèmes Principaux**
Sélectionner parmi 25+ problèmes pré-définis ou spécifier personnalisé:
- Surpêche
- Pollution (nutriments, plastiques, produits chimiques)
- Dégradation de l'habitat
- Impacts du changement climatique
- Espèces invasives
- Développement côtier
- Pression touristique
- Et beaucoup d'autres...

**Étapes 7-11: Définition des Éléments**
Pour chaque niveau DAPSI(W)R(M):
- Suggestions pré-remplies basées sur votre contexte
- Option de saisie en texte libre
- Plusieurs éléments peuvent être ajoutés
- Aperçu en temps réel des éléments créés

**Fonctionnalités de Session:**
- **Sauvegarde Automatique**: Progrès sauvegardé dans localStorage du navigateur
- **Récupération de Session**: Reprendre si interrompu
- **Interface de Chat**: Invites conversationnelles
- **Conscience du Contexte**: Suggestions s'adaptant aux réponses précédentes
- **Intégration Directe**: Sauvegarde dans les données principales du projet

**Quand Utiliser:**
- Projets avec contraintes de temps (évaluation rapide)
- Phase de cadrage initiale
- Utilisateurs expérimentés familiers avec DAPSI(W)R(M)
- Lorsque les connaissances expertes peuvent combler rapidement les lacunes

\newpage

## Visualisation CLD

Visualisation de réseau interactive de votre système socio-écologique.

### Affichage du Réseau

**Encodage Visuel:**

**Couleurs des Nœuds (niveaux DAPSI(W)R(M)):**
- Violet: Moteurs
- Vert: Activités
- Orange: Pressions
- Bleu Clair: Processus Marins
- Bleu Foncé: Services Écosystémiques
- Jaune Clair: Biens & Bénéfices

**Formes des Nœuds:**
- Étoile: Moteurs
- Hexagone: Activités
- Losange: Pressions
- Point: Processus Marins
- Carré: Services Écosystémiques
- Triangle: Biens & Bénéfices

**Couleurs des Arêtes:**
- Bleu Clair: Connexions positives/de renforcement
- Rouge: Connexions négatives/d'opposition

### Algorithmes de Disposition

**1. Disposition Hiérarchique (Recommandé)**
- **Direction**: Bas-Haut (montre le flux DAPSI), Haut-Bas, Gauche-Droite, Droite-Gauche
- **Séparation de Niveau**: Ajuster l'espacement (50-300px)
- **Idéal pour**: Comprendre la structure DAPSI, présentations

**2. Basé sur la Physique (Force Atlas 2)**
- **Gravité**: Force d'attraction entre nœuds connectés
- **Longueur de Ressort**: Longueur d'arête idéale
- **Idéal pour**: Découvrir des clusters, identifier des nœuds centraux

**3. Disposition Circulaire**
- Nœuds arrangés en cercle
- **Idéal pour**: Petits réseaux, reconnaissance de motifs

**4. Positionnement Manuel**
- Glisser les nœuds vers les positions désirées
- Positions sauvegardées avec le projet
- **Idéal pour**: Arrangements personnalisés, présentations finales

### Contrôles Interactifs

**Navigation:**
- **Zoom**: Molette de souris ou geste de pincement
- **Panoramique**: Cliquer et glisser l'arrière-plan
- **Réinitialiser la Vue**: Bouton pour restaurer la vue initiale
- **Ajuster à l'Écran**: Auto-zoom pour afficher tous les nœuds

**Interactions de Nœud:**
- **Clic**: Sélectionner le nœud (met en surbrillance les voisins)
- **Double-clic**: Centrer la vue sur le nœud
- **Survol**: Afficher l'infobulle avec les détails

**Recherche:**
- Taper le nom du nœud pour trouver et mettre en surbrillance
- Liste déroulante de tous les nœuds
- Auto-centrage sur le nœud sélectionné

### Fonctionnalités de Mise en Évidence

**Points de Levier:**
- Mettre en évidence les nœuds à haute influence
- Basé sur les métriques de centralité
- Activer/désactiver

**Mise en Évidence de Boucle:**
- Sélectionner la boucle dans le menu déroulant
- Tous les nœuds et arêtes de la boucle mis en évidence
- Autres éléments estompés
- Utile pour les discussions spécifiques à une boucle

### Options d'Export

**Export PNG:**
- Image raster haute résolution (150 dpi)
- Dimensions personnalisées (400-4000px)
- Option de fond transparent
- **Utiliser pour**: Rapports, présentations, publications

**Export SVG:**
- Graphiques vectoriels évolutifs
- Éditable dans Illustrator, Inkscape
- Pas de perte de qualité à n'importe quelle taille
- **Utiliser pour**: Publications professionnelles, affiches

**Export HTML:**
- Fichier autonome entièrement interactif
- Partager avec les parties prenantes
- Aucun serveur requis
- **Utiliser pour**: Partage avec les parties prenantes, intégration web

\newpage

## Outils d'Analyse

### Détection de Boucles

Identifier automatiquement les boucles de rétroaction dans votre système.

**Comment Fonctionnent les Boucles de Rétroaction:**

- **Boucles de Renforcement (R)**: Amplifient le changement (nombre pair de liens négatifs)
  - Exemple: Plus de poissons → Plus d'effort de pêche → Moins de poissons → Moins d'effort de pêche → Plus de poissons
  - Conduit à une croissance ou un déclin exponentiel

- **Boucles d'Équilibrage (B)**: Stabilisent le système (nombre impair de liens négatifs)
  - Exemple: Surpêche → Stocks épuisés → Réglementations → Pêche réduite → Récupération des stocks
  - Conduit à l'équilibre ou à l'oscillation

**Paramètres de Détection:**

- **Longueur Maximale de Boucle**: 3-15 éléments (par défaut: 8)
  - Plus court: Trouver des cycles de rétroaction serrés
  - Plus long: Découvrir des boucles complexes multi-étapes

- **Cycles Maximaux**: 50-2000 (par défaut: 500)
  - Limite le temps de calcul
  - Plus de cycles = traitement plus long mais résultats plus complets

- **Inclure les Auto-Boucles**: Oui/Non
  - Auto-boucle: Élément s'influence directement

- **Filtrer les Boucles Triviales**: Oui (recommandé)
  - Supprime les boucles simples à 2 nœuds
  - Se concentre sur la rétroaction complexe

**Processus de Détection:**

1. Cliquer sur le bouton "Détecter les Boucles"
2. L'algorithme s'exécute (peut prendre 10-60 secondes pour les grands réseaux)
3. L'indicateur de progrès affiche le statut
4. Les résultats apparaissent dans 5 onglets

**Onglet 1: Détecter les Boucles**
- Contrôles de détection
- Statistiques récapitulatives
  - Total de boucles trouvées
  - Nombre de renforcements
  - Nombre d'équilibrages
- Table de données des boucles (ID, Type, Longueur, Éléments, Polarités des liens)

**Onglet 2: Classification des Boucles**
- Graphiques de distribution (R vs. B)
- Tables séparées pour chaque type
- Résumé statistique

**Onglet 3: Détails de la Boucle**
- Sélectionner une boucle spécifique dans le menu déroulant
- Voir les propriétés de la boucle:
  - Type (R/B)
  - Longueur (nombre d'éléments)
  - Chemin (séquence d'éléments)
  - Polarités des liens
- Description narrative (chaîne causale auto-générée)
- Boucle mise en évidence dans la visualisation CLD

**Onglet 4: Boucles Dominantes**
- Classement par:
  - **Occurrence**: Combien de fois les éléments apparaissent dans les boucles
  - **Participation**: Pourcentage de boucles impliquant l'élément
- Table des boucles les plus influentes
- Graphiques de participation des éléments
- **Valeur stratégique**: Identifie les points d'intervention

**Onglet 5: Exporter les Résultats**
- **Export Excel**: Classeur multi-feuilles
  - Toutes les boucles
  - Boucles R uniquement
  - Boucles B uniquement
  - Statistiques récapitulatives
- **Rapport de Boucle**: Document PDF avec analyse
- **Diagrammes de Boucle**: Fichier ZIP des visualisations de boucles individuelles

**Guidance d'Interprétation:**

**Haute proportion de boucles R (>70%):**
- Système sujet à des changements rapides
- Points de basculement probables
- Urgence de gestion élevée
- Focus: Renforcer les mécanismes d'équilibrage

**Haute proportion de boucles B (>70%):**
- Système très stable/résistant au changement
- Les interventions peuvent rencontrer de la résistance
- Effort persistant requis
- Focus: Déplacer les points d'équilibre

**Mélange équilibré (30-70% chacun):**
- Stabilité modérée
- Potentiel de changement et d'autorégulation
- Focus: Tirer parti des boucles R pour les changements souhaités, utiliser les boucles B pour stabiliser

\newpage

### Métriques de Réseau

Quantifier l'importance des nœuds et la structure du réseau.

**Mesures de Centralité:**

**1. Centralité de Degré**
- **Degré Entrant**: Nombre de connexions entrantes
  - Degré entrant élevé = fortement influencé par d'autres éléments
  - Bons indicateurs de l'état du système

- **Degré Sortant**: Nombre de connexions sortantes
  - Degré sortant élevé = influence de nombreux autres éléments
  - Bonnes cibles d'intervention

**2. Centralité d'Intermédiarité**
- Mesure à quelle fréquence un nœud se trouve sur les chemins les plus courts
- Intermédiarité élevée = fait le pont entre différentes parties du système
- Critique pour le flux d'information/influence
- La suppression déconnecte le système

**3. Centralité de Proximité**
- Distance moyenne vers tous les autres nœuds
- Proximité élevée = propagation rapide de l'influence
- Important pour les réponses rapides du système

**4. Centralité de Vecteur Propre**
- Importance basée sur l'importance des voisins
- Vecteur propre élevé = connecté à d'autres nœuds importants
- Identifie les éléments vraiment influents

**5. PageRank**
- Algorithme de Google adapté aux réseaux
- Score d'importance pondéré
- Bonne mesure d'influence globale

**Métriques au Niveau du Réseau:**

- **Densité**: Proportion de connexions possibles qui existent
  - Faible (<0.1): Système clairsemé, modulaire
  - Moyenne (0.1-0.3): Modérément connecté
  - Élevée (>0.3): Système étroitement couplé

- **Diamètre**: Plus long chemin le plus court entre deux nœuds quelconques
  - Mesure la "largeur" du système

- **Longueur Moyenne du Chemin**: Chemin le plus court moyen
  - Mesure la rapidité de propagation de l'influence

**Analyse MICMAC:**

Classe les nœuds par influence et dépendance:

**Quatre Quadrants:**

1. **Variables Relais** (Influence élevée, Dépendance élevée)
   - Instables, transmettent les effets
   - Interdépendances complexes
   - Nécessitent une gestion prudente

2. **Variables Influentes** (Influence élevée, Dépendance faible)
   - Forts moteurs du système
   - Indépendants des autres éléments
   - Cibles d'intervention primaires

3. **Variables Dépendantes** (Influence faible, Dépendance élevée)
   - Résultats/indicateurs
   - Sensibles aux changements
   - Bons points de surveillance

4. **Variables Autonomes** (Influence faible, Dépendance faible)
   - Faiblement connectées
   - Rôle limité dans la dynamique
   - Peuvent être supprimées pour simplifier

**Analyse des Points de Levier:**

Identifie les points d'intervention à fort impact utilisant un score composite:

```
Score de Levier = Intermédiarité + Vecteur Propre + PageRank
```

**Top 10 des Points de Levier** classés par score

**Catégories:**
- **Moteurs**: Nœuds à degré sortant élevé → Interventions en cascade
- **Récepteurs**: Nœuds à degré entrant élevé → Indicateurs de surveillance
- **Connecteurs**: Nœuds à intermédiarité élevée → Critiques pour la résilience

**Section Recommandations Stratégiques:**

Basé sur les résultats d'analyse, génère des orientations contextuelles:

1. **Points d'Intervention Prioritaires**: Nomme les 3 premiers nœuds de levier avec scores
2. **Stratégie en Cascade**: Nœuds moteurs avec nombres d'influence moyens
3. **Système d'Alerte Précoce**: Nœuds récepteurs comme indicateurs de surveillance
4. **Alertes de Dynamique du Système**: Avertissements basés sur les boucles (points de basculement vs. résistance)
5. **Protection de la Résilience**: Nœuds connecteurs à préserver

\newpage

## Réponse & Validation

### Mesures de Réponse

Documenter et prioriser les interventions de gestion.

**Onglet 1: Registre des Réponses**

Créer des entrées d'intervention avec:

- **ID**: Auto-généré
- **Nom**: Description de l'intervention
- **Type**:
  - Réglementaire: Lois, quotas, fermetures
  - Économique: Subventions, taxes, basé sur le marché
  - Éducatif: Sensibilisation, formation
  - Technique: Infrastructure, technologie
  - Institutionnel: Réformes de gouvernance
  - Volontaire: Codes de conduite, certification
  - Mixte: Combinaison

- **Description**: Explication détaillée
- **Niveau Cible**: Quel niveau DAPSI(W)R(M)?
  - Moteurs
  - Activités
  - Pressions
  - État
  - Multiple

- **Élément Cible**: ID de nœud spécifique
- **Efficacité**: Impact attendu (Élevée/Moyenne/Faible/Inconnue)
- **Faisabilité**: Facilité de mise en œuvre (Élevée/Moyenne/Faible)
- **Coût**: Échelle 1-10 (1=minimal, 10=très coûteux)
- **Parties Prenantes Responsables**: Qui met en œuvre?
- **Obstacles à la Mise en Œuvre**: Défis anticipés
- **Statut**:
  - Proposé
  - Planifié
  - Mis en Œuvre
  - Partiellement Mis en Œuvre
  - Abandonné

**Onglet 2: Évaluation d'Impact**

Cartographier les réponses aux problèmes qu'elles abordent.

**Créer des Liens d'Impact:**
- Sélectionner Mesure de réponse
- Sélectionner Problème (Pression/Activité/Moteur)
- Spécifier:
  - **Force d'Impact**: Fort/Modéré/Faible
  - **Échéance**: Immédiate/Court-terme (1-2a)/Moyen-terme (3-5a)/Long-terme (>5a)
  - **Confiance**: Qualité de la preuve

**Table Matrice d'Impact:**
- Lignes: Réponses
- Colonnes: Problèmes
- Cellules: Force + échéance

**Carte Thermique Visuelle:**
- Force d'impact codée par couleur
- Identification rapide des réponses multi-bénéfices

**Onglet 3: Priorisation**

Classement multicritères des réponses.

**Curseurs de Pondération:**
- **Poids d'Efficacité** (0-1): Quelle importance a la magnitude de l'impact?
- **Poids de Faisabilité** (0-1): Quelle importance a la facilité de mise en œuvre?
- **Poids du Coût** (0-1, inverse): Quelle sensibilité avons-nous au coût?

**Calcul du Score de Priorité:**
```
Priorité = (Efficacité × P_eff) +
           (Faisabilité × P_fais) -
           (Coût/10 × P_coût)
```

**Table Classée:**
- Réponses triées par score de priorité
- Affiche toutes les valeurs d'entrée et poids
- Identifier les meilleurs candidats

**Nuages de Points:**
- **Efficacité vs. Faisabilité**: Identifier les "victoires rapides" (les deux élevés)
- **Coût vs. Impact**: Évaluer la rentabilité

**Analyse de Sensibilité:**
- Ajuster les poids pour tester la robustesse
- Voir comment les classements changent
- Identifier les meilleurs choix stables

**Onglet 4: Plan de Mise en Œuvre**

Suivre le déploiement des réponses dans le temps.

**Jalons:**
- **Nom du Jalon**: Livrable/point de contrôle clé
- **ID de Réponse**: Quelle mesure?
- **Date Cible**: Achèvement planifié
- **Statut**: En Attente/En Cours/Complété/Retardé
- **Notes**: Mises à jour de progrès

**Diagramme de Gantt:**
- Visualisation de la chronologie
- Dépendances des jalons
- Chemin critique mis en évidence
- Export en PNG

**Onglet 5: Export**

Télécharger la documentation de planification des réponses:
- Classeur Excel (tous les onglets)
- Rapport récapitulatif PDF
- Graphique de chronologie de mise en œuvre

\newpage

### Générateur de Scénarios

Explorer des alternatives "et si" et comparer des scénarios.

**Gestion de Scénarios:**

**Créer un Nouveau Scénario:**
1. Cliquer sur "Nouveau Scénario"
2. Entrer le nom et la description
3. La carte de scénario apparaît dans la galerie

**Affichage des Cartes de Scénario:**
- Aperçu miniature
- Nom du scénario
- Date de création
- Nombre de modifications
- Indicateur de statut actif

**Onglet Configurer:**

Apporter des modifications au réseau pour le scénario:

**Ajouter des Nœuds:**
- Nouveaux éléments pour représenter des états alternatifs
- Exemple: "Zone Marine Protégée établie"

**Supprimer des Nœuds:**
- Simuler la suppression d'éléments
- Exemple: Supprimer l'activité "Chalutage de fond"

**Modifier des Nœuds:**
- Changer les propriétés (importance, tendance, etc.)
- Exemple: Augmenter l'intensité du "Tourisme"

**Ajouter des Liens:**
- Nouvelles connexions causales
- Exemple: "ZMP" → "Biomasse de poissons" (+fort)

**Supprimer des Liens:**
- Briser les connexions existantes
- Exemple: Supprimer "Effort de pêche" → "Stock de poissons"

**Modifier des Liens:**
- Changer la polarité ou la force
- Exemple: Affaiblir "Pollution" → "Santé des herbiers"

**Onglet Analyse d'Impact:**

Évaluer les effets du scénario sur:

**Métriques de Réseau:**
- Comparer densité, centralité, etc. à la ligne de base
- Identifier les changements structurels

**Dynamique de Boucle:**
- Re-exécuter la détection de boucle pour le scénario
- Comparer la distribution R/B
- Identifier les nouvelles boucles/boucles supprimées

**Points de Levier:**
- Recalculer les nœuds principaux
- Voir comment les points d'intervention se déplacent

**Propagation d'Impact:**
- Tracer les effets des changements
- Identifier les conséquences en cascade

**Onglet Comparer:**

Comparaison côte à côte des scénarios:

**Vue Table:**
- Comparaison métrique par métrique
- Ligne de base vs. Scénario A vs. Scénario B
- Colonnes de différence (Δ)

**Vue Graphique:**
- Graphiques radar pour comparaison multi-métrique
- Graphiques à barres pour indicateurs clés
- Comparaison de structure de réseau

**Génération de Rapport:**
- PDF de comparaison de scénarios
- Inclut toutes les métriques, graphiques et narratifs
- Export pour présentation aux parties prenantes

\newpage

## Export & Rapports

### Export de Données

Exporter les données de votre projet dans plusieurs formats.

**Export Excel (.xlsx)**

Classeur multi-feuilles contenant:
- Métadonnées du projet
- Tous les tableaux ISA (B&B, SE, PFM, P, A, M)
- Matrices d'adjacence
- Nœuds et arêtes CLD
- Résultats de détection de boucle
- Métriques de réseau
- Registre des parties prenantes
- Mesures de réponse
- Comparaisons de scénarios

**Export CSV (.csv)**
- Export de table unique
- Choisir un ensemble de données spécifique
- Compatible avec tout logiciel de feuille de calcul

**Export JSON (.json)**
- Données structurées hiérarchiques
- Projet complet incluant les structures imbriquées
- Compatible avec applications web, bases de données
- Compatible Kumu.io (avec style)

**Export de Données R (.RData)**
- Format R natif
- Préserve tous les types d'objets
- Charger directement dans R pour analyse personnalisée

### Export de Visualisation

Exporter les visualisations CLD dans plusieurs formats.

**HTML (Interactif)**
- Réseau entièrement interactif
- Fichier autonome (aucun serveur nécessaire)
- Partager par email ou web
- Les destinataires peuvent explorer, zoomer, panoramiquer
- **Taille du fichier**: 500KB - 2MB typique
- **Idéal pour**: Partage avec parties prenantes, intégration web

**PNG (Image Raster)**
- Bitmap haute résolution (150 dpi par défaut)
- Dimensions personnalisées (400-4000px largeur/hauteur)
- Option de fond transparent
- **Taille du fichier**: 100KB - 5MB
- **Idéal pour**: Rapports, présentations, affiches

**SVG (Graphiques Vectoriels)**
- Évolutif à n'importe quelle taille sans perte de qualité
- Éditable dans un logiciel de graphiques vectoriels
- Petite taille de fichier
- **Idéal pour**: Publications, design professionnel, impression grand format

**PDF (Prêt à Imprimer)**
- Qualité publication
- Intégrable dans des documents
- Nécessite l'installation de Pandoc + LaTeX
- **Idéal pour**: Rapports formels, archivage

\newpage

### Génération de Rapports

Créer automatiquement des rapports d'analyse complets.

**Types de Rapports:**

**1. Résumé Exécutif (2-3 pages)**

Public cible: Décideurs, responsables politiques

Contenu:
- Vue d'ensemble du projet (1 paragraphe)
- Résultats clés (points):
  - Nombre d'éléments et connexions
  - Boucles de rétroaction détectées (nombre R vs. B)
  - Top 3 des points de levier
  - Défis de gestion critiques
- Recommandations prioritaires (3-5 items)
- Visuel: Diagramme CLD simplifié

**2. Rapport Technique (10-15 pages)**

Public cible: Chercheurs, analystes techniques

Contenu:
- Analyse complète DAPSI(W)R(M)
- Comptes d'éléments par type (table)
- Métriques de réseau (densité, centralité, etc.)
- Analyse détaillée des boucles:
  - Classification des boucles
  - Boucles dominantes
  - Implications système
- Analyse des points de levier (top 10)
- Tables de données (tous les exercices ISA)

**3. Présentation aux Parties Prenantes (5-7 pages)**

Public cible: Parties prenantes générales, groupes communautaires

Contenu:
- Description du système en langage simple
- Lourd en visuel (CLD, graphiques, infographies)
- Vue d'ensemble du système:
  - Principaux moteurs identifiés
  - Pressions clés
  - Impacts écosystémiques
  - Conséquences sur le bien-être
- Opportunités d'action
- Opportunités d'engagement
- Questions de discussion

**4. Rapport de Projet Complet (20-30 pages)**

Public cible: Documentation complète pour tous les publics

Contenu:
- Toutes les sections ci-dessus combinées
- Méthodologie complète
- Tous les tableaux de données
- Toutes les visualisations
- Recommandations détaillées (contextuelles):

  **Recommandations Stratégiques:**
  - Points d'intervention prioritaires (nommés, avec scores)
  - Stratégie d'intervention en cascade (nœuds Moteurs spécifiques)
  - Système de surveillance d'alerte précoce (nœuds Récepteurs spécifiques)
  - Alertes de dynamique du système (basées sur composition des boucles)
  - Protection de la résilience (nœuds Connecteurs spécifiques)

  **Recommandations de Gestion:**
  - Conception d'intervention (conseils spécifiques à la densité du réseau)
  - Stratégie de surveillance (sélection d'indicateurs basée sur les données)
  - Gestion adaptative (stratégie informée par les boucles avec timing)
  - Engagement des parties prenantes (alignement stratégique aux points de levier)
  - Prochaines étapes immédiates (5 plans d'action détaillés)

- Annexes:
  - Glossaire
  - Sources de données
  - Documentation de validation
  - Références

**Options de Rapport:**

**Inclure les Visualisations:**
- [x] Diagramme de réseau CLD
- [x] Graphiques de distribution des boucles
- [x] Classements des points de levier
- [x] Graphiques de métriques de réseau

**Inclure les Tables de Données:**
- [x] Tous les tableaux d'éléments ISA
- [x] Matrices d'adjacence
- [x] Table de détails des boucles
- [x] Résumé des métriques

**Marque Personnalisée:**
- Ajouter votre logo
- Palette de couleurs personnalisée
- Pied de page de l'organisation

**Formats de Rapport:**

**HTML (Version Web)**
- Table des matières interactive (barre latérale flottante)
- Sections repliables
- Références croisées hyperliens
- Visualisations interactives intégrées
- **Taille du fichier**: 1-5 MB
- **Idéal pour**: Partage par email, publication web, visionnage à l'écran

**PDF (Version Imprimée)**
- Formatage professionnel
- Numéros de page et en-têtes
- Qualité prête à imprimer
- Nécessite Pandoc + LaTeX/TinyTeX
- **Taille du fichier**: 2-10 MB
- **Idéal pour**: Distribution formelle, archivage, impression

**Word (.docx)**
- Document éditable
- Tables et figures
- Nécessite l'installation de Pandoc
- **Taille du fichier**: 1-5 MB
- **Idéal pour**: Édition collaborative, formatage personnalisé

**Processus de Génération:**

1. Naviguer vers le module "Préparer Rapport"
2. Sélectionner le type de rapport
3. Choisir les options (visualisations, tables de données)
4. Cliquer sur "Générer Rapport"
5. Traitement (10-30 secondes)
6. Le bouton de téléchargement apparaît
7. Ouvrir/sauvegarder le fichier de rapport

**Dépannage:**

- **La génération de PDF échoue**: Installer Pandoc et TinyTeX
  ```r
  install.packages("tinytex")
  tinytex::install_tinytex()
  ```

- **Le rapport est vide**: Assurez-vous d'avoir complété la saisie des données ISA et exécuté les analyses

- **Les graphiques n'apparaissent pas**: Vérifier que les modules d'analyse ont été exécutés

\newpage

# Flux de Travail & Meilleures Pratiques

## Flux de Travail Recommandés

### Atelier Participatif Standard (3 jours)

**Jour 1: Cartographie du Système (6 heures)**
- Matin: Introduction et configuration du projet (1h)
  - Présenter le cadre DAPSI(W)R(M)
  - Définir le problème focal et les limites
  - Identifier les parties prenantes

- Fin de matinée: Biens & Bénéfices (1.5h)
  - Brainstorm des résultats valorisés (Exercice 1)
  - Prioriser par importance

- Après-midi: Travail à rebours (3.5h)
  - Services Écosystémiques (Exercice 2a)
  - Processus Marins (Exercice 2b)
  - Pause
  - Pressions (Exercice 3)

**Jour 2: Chaînes Causales et Visualisation (6 heures)**
- Matin: Moteurs et Activités (2h)
  - Activités générant des pressions (Exercice 4)
  - Moteurs de cause profonde (Exercice 5)

- Fin de matinée: Fermeture de boucle (1.5h)
  - Connexions de rétroaction (Exercice 6)
  - Valider les connexions

- Après-midi: Création et exploration de CLD (2.5h)
  - Générer le réseau (Exercice 7-8)
  - Exploration interactive
  - Identifier les motifs

**Jour 3: Analyse et Planification (6 heures)**
- Matin: Analyse (2h)
  - Détection de boucles
  - Métriques de réseau
  - Points de levier

- Fin de matinée: Planification des réponses (2h)
  - Brainstorm des interventions
  - Priorisation multicritères

- Après-midi: Synthèse (2h)
  - Génération de rapport
  - Planification d'action
  - Accord sur les prochaines étapes

### Flux de Travail Solo/Recherche (25 jours)

**Semaine 1: Fondation (5 jours)**
- Jour 1-2: Configuration du projet, revue de littérature
- Jour 3-4: Saisie des données ISA (Exercices 0-3)
- Jour 5: Saisie des données ISA (Exercices 4-6)

**Semaine 2: Analyse (5 jours)**
- Jour 6: Génération et exploration de CLD
- Jour 7-8: Détection et interprétation des boucles
- Jour 9: Calcul des métriques de réseau
- Jour 10: Analyse des points de levier

**Semaine 3: Validation (5 jours)**
- Jour 11-13: Consultation d'experts
- Jour 14-15: Revue des parties prenantes et révision

**Semaine 4: Planification des Réponses (5 jours)**
- Jour 16-17: Identification des mesures de réponse
- Jour 18-19: Évaluation d'impact et priorisation
- Jour 20: Planification de la mise en œuvre

**Semaine 5: Documentation (5 jours)**
- Jour 21-22: Analyse de scénarios
- Jour 23-24: Génération de rapport
- Jour 25: Revue finale et soumission

### Évaluation Rapide (Assistée par IA, 1 jour)

**Matin (3 heures)**
- 0-30min: Configuration du projet
- 30-90min: Entretien ISA assisté par IA (11 étapes)
- 90-120min: Examiner et affiner les éléments générés
- 120-180min: Visualisation et exploration de CLD

**Après-midi (3 heures)**
- 180-240min: Détection et analyse des boucles
- 240-300min: Brainstorm de réponses
- 300-360min: Génération de rapport et prochaines étapes

## Meilleures Pratiques

### Qualité des Données

**1. Conventions de Dénomination Claires**
- Utiliser des noms descriptifs et spécifiques
- Éviter le jargon ou les acronymes (ou les définir)
- Être cohérent à travers des éléments similaires

**Exemples:**
- Bon: "Pêche commerciale au chalut de fond"
- Mauvais: "Pêche" (trop vague)
- Mauvais: "PCCF" (acronyme peu clair)

**2. Descriptions Complètes**
- Fournir un contexte pour chaque élément
- Expliquer les mécanismes pour les relations
- Documenter les sources de preuves

**3. Granularité Appropriée**
- Pas trop large: "Pollution" → "Pollution nutritive de l'agriculture"
- Pas trop étroit: "Ruissellement d'azote du champ 23A" → "Ruissellement nutritif agricole"
- Faire correspondre l'échelle d'analyse au contexte de décision

**4. Validation**
- Attribuer honnêtement les scores de confiance
- Documenter les incertitudes
- Chercher une revue d'experts
- Incorporer les retours des parties prenantes

### Conception de Réseau

**1. Taille Optimale du Réseau**
- Point idéal: 20-60 nœuds
- Trop petit (<15): Manque des dynamiques importantes
- Trop grand (>100): Difficile à analyser et communiquer
- Se concentrer sur les éléments les plus importants

**2. Équilibre à Travers les Niveaux DAPSI**
- Viser des nombres similaires à chaque niveau
- Éviter de surreprésenter un niveau
- Exemple de distribution: 5M, 8A, 10P, 8E, 6W, 5R

**3. Densité de Connexion**
- Cible: 1.5-3 connexions par nœud en moyenne
- Trop clairsemé: Peut manquer des rétroactions clés
- Trop dense: Difficile à interpréter, moins utile

**4. Boucles de Rétroaction**
- Concevoir délibérément une certaine rétroaction
- Chaque M devrait ultimement se connecter à un B&B
- Chercher des conséquences involontaires

### Engagement des Parties Prenantes

**1. Cartographie Participative**
- Impliquer des parties prenantes diverses
- Utiliser la visualisation pour faciliter la discussion
- Capturer les connaissances locales/traditionnelles
- Valider les connaissances d'experts

**2. Gestion Pouvoir-Intérêt**
- Engager étroitement pouvoir élevé/intérêt élevé (collaborer)
- Maintenir satisfaits pouvoir élevé/intérêt faible (informer régulièrement)
- Maintenir informés pouvoir faible/intérêt élevé (consulter)
- Surveiller pouvoir faible/intérêt faible (effort minimal)

**3. Processus Transparent**
- Documenter toutes les hypothèses
- Rendre explicites les sources de données
- Expliquer les incertitudes
- Partager les résultats préliminaires pour retour

**4. Résultats Actionnables**
- Lier l'analyse aux questions de gestion
- Prioriser les recommandations pratiques
- Développer des prochaines étapes claires
- Attribuer des responsabilités

### Conseils Techniques

**1. Sauvegarder Souvent**
- Utiliser la fonction de Sauvegarde Automatique
- Sauvegarde manuelle toutes les 15-30 minutes
- Utiliser des noms de fichiers descriptifs avec dates
- Garder des copies de sauvegarde

**2. Développement Incrémental**
- Commencer simple, ajouter de la complexité graduellement
- Tester de petites sections avant de construire le réseau complet
- Valider fréquemment pendant le développement

**3. Utiliser les Modèles**
- Tirer parti des modèles existants quand applicable
- Personnaliser plutôt que partir de zéro
- Documenter vos propres modèles pour réutilisation

**4. Exporter Régulièrement**
- Exporter vers Excel pour sauvegarde externe
- Exporter les visualisations aux jalons clés
- Générer des rapports périodiquement pour vérifier l'exhaustivité

**5. Recommandations de Navigateur**
- Chrome (meilleure performance)
- Firefox (bonne alternative)
- Éviter Internet Explorer
- Garder le navigateur à jour

**6. Performance**
- Fermer les autres onglets/applications du navigateur
- Vider le cache du navigateur si lent
- Réduire la taille du réseau si >100 nœuds causent du retard
- Utiliser la disposition hiérarchique pour les grands réseaux

\newpage

# Dépannage

## Problèmes Courants

### Problèmes d'Installation

**Problème: L'installation du package échoue**

Solution:
```r
# Essayer d'installer depuis un miroir CRAN différent
options(repos = "https://cloud.r-project.org/")
install.packages("nom_du_package")

# Ou utiliser l'installateur de package de RStudio (Outils > Installer des Packages)
```

**Problème: L'application ne démarre pas**

Solutions:
1. Vérifier la version de R (doit être 4.0+)
   ```r
   R.version.string
   ```
2. Vérifier que tous les packages sont installés
   ```r
   packages_requis <- c("shiny", "shinydashboard", "shinyjs", ...)
   manquants <- packages_requis[!packages_requis %in% installed.packages()]
   if(length(manquants) > 0) install.packages(manquants)
   ```
3. Vérifier les messages d'erreur dans la console R

### Problèmes de Saisie de Données

**Problème: Impossible d'ajouter de nouveaux éléments**

Solutions:
- Assurez-vous que tous les champs requis sont complétés
- Vérifier les ID en double
- Vérifier le type de données (numérique vs. texte)
- Vider le cache du navigateur

**Problème: La matrice d'adjacence ne se sauvegarde pas**

Solutions:
- Remplir au moins une cellule dans la matrice
- Utiliser le format correct: `+fort`, `+moyen`, `+faible`, `-fort`, etc.
- Sauvegarder l'exercice avant de passer au suivant

### Problèmes de Visualisation

**Problème: Le CLD ne s'affiche pas**

Solutions:
- Assurez-vous que les données ISA sont entrées (Exercices 1-6)
- Vérifier que JavaScript du navigateur est activé
- Essayer de rafraîchir la page (F5)
- Vérifier la console du navigateur pour les erreurs (F12 → onglet Console)

**Problème: Nœuds qui se chevauchent/disposition désordonnée**

Solutions:
- Utiliser la disposition Hiérarchique (direction Bas-Haut)
- Augmenter la séparation de niveau (150-200px)
- Essayer la disposition Physique avec une gravité plus élevée
- Repositionner manuellement les nœuds et sauvegarder

### Problèmes d'Analyse

**Problème: La détection de boucles se bloque**

Solutions:
- Réseau trop grand (>100 nœuds)
- Réduire la longueur max de boucle (essayer 6-8)
- Réduire les cycles max (essayer 200-500)
- Filtrer les boucles triviales: Oui
- Simplifier le réseau (supprimer les éléments de faible importance)

**Problème: Aucune boucle détectée**

Solutions:
- Vérifier que l'Exercice 6 (Fermeture de Boucle) est complété
- Vérifier que des connexions de rétroaction existent (liens M → B&B)
- Augmenter la longueur max de boucle (essayer 10-12)
- Vérifier que le réseau est entièrement connecté

### Problèmes de Génération de Rapport

**Problème: La génération de rapport échoue**

Solutions:
- Compléter d'abord la saisie minimale de données
- Exécuter les analyses requises avant le rapport
- Vérifier l'espace disque disponible
- Essayer d'abord le format HTML (plus compatible)

**Problème: La génération de PDF échoue**

Solutions:
```r
# Installer les outils requis
install.packages("tinytex")
tinytex::install_tinytex()

# Vérifier l'installation
tinytex:::is_tinytex()  # Devrait retourner TRUE
```

\newpage

# Glossaire

**Activité (A)**: Actions humaines qui génèrent des pressions sur les systèmes marins (ex: pêche, navigation, tourisme)

**Matrice d'Adjacence**: Table montrant les connexions entre deux ensembles d'éléments; lignes et colonnes représentent les éléments, cellules contiennent des informations de relation

**Boucle d'Équilibrage (B)**: Boucle de rétroaction avec nombre impair de liens négatifs; stabilise le système vers l'équilibre

**Centralité d'Intermédiarité**: Mesure de réseau de la fréquence à laquelle un nœud se trouve sur les chemins les plus courts entre d'autres nœuds; indique l'importance de pontage

**Diagramme de Boucles Causales (CLD)**: Visualisation de réseau montrant les relations de cause à effet et les boucles de rétroaction

**Centralité**: Famille de métriques quantifiant l'importance des nœuds dans les réseaux (degré, intermédiarité, proximité, vecteur propre)

**DAPSI(W)R(M)**: Cadre Drivers-Activities-Pressures-State changes-Welfare impacts-Response Measures (Moteurs-Activités-Pressions-Changements d'État-Impacts sur le Bien-être-Mesures de Réponse) pour l'analyse SES. Le "R/M" représente les interventions de gestion, combinant les réponses politiques et les mesures d'application en une seule catégorie unifiée.

**Centralité de Degré**: Nombre de connexions; degré entrant (entrant), degré sortant (sortant)

**Moteur (D)**: Causes profondes derrière les activités (facteurs économiques, sociaux, technologiques, environnementaux, politiques)

**Service Écosystémique (SE/W)**: Avantages que les écosystèmes fournissent aux humains (approvisionnement, régulation, culturel, support)

**Arête**: Connexion/lien entre nœuds dans le réseau; représente une relation causale

**Centralité de Vecteur Propre**: Importance basée sur l'importance des voisins; score élevé = connecté à d'autres nœuds importants

**Boucle de Rétroaction**: Chemin circulaire dans le réseau où l'élément s'influence lui-même à travers une chaîne d'autres éléments

**Biens & Bénéfices (B&B/R)**: Résultats valorisés des systèmes marins reçus par les parties prenantes

**Disposition Hiérarchique**: Algorithme de visualisation de réseau organisant les nœuds en niveaux/couches

**ISA**: Analyse Intégrée des Systèmes - méthodologie structurée pour l'analyse SES

**Point de Levier**: Emplacement d'intervention à fort impact identifié à travers les métriques de centralité

**Processus/Fonctionnement Marin (PFM/E/I)**: Processus écologiques et changements d'état dans l'environnement marin

**MICMAC**: Matrice des Impacts Croisés - analyse classant les nœuds par influence et dépendance

**Densité de Réseau**: Proportion de connexions possibles qui existent réellement; mesure de connectivité

**Métriques de Réseau**: Mesures quantitatives de la structure du réseau (densité, centralité, diamètre, etc.)

**Nœud**: Élément dans le diagramme de réseau représentant un composant du système

**PageRank**: Algorithme de Google pour classer l'importance; adapté pour l'analyse de réseau

**PIMS**: Système de Gestion d'Information Projet - module pour les métadonnées de projet et les parties prenantes

**Polarité**: Signe de la relation causale - positif (+) ou négatif (-)

**Pression (P)**: Facteurs de stress directs sur l'environnement marin (physique, chimique, biologique)

**Boucle de Renforcement (R)**: Boucle de rétroaction avec nombre pair de liens négatifs; amplifie le changement

**Mesures de Réponse (R/M)**: Interventions de gestion et instruments politiques conçus pour aborder les moteurs, activités ou pressions. Englobe à la fois les réponses au niveau politique et les mesures d'application spécifiques. Exemples : réglementations (quotas de pêche, AMP), instruments économiques (taxes, subventions), programmes éducatifs et solutions techniques. Partie du cadre DAPSI(W)R(M).

**SES**: Système Socio-Écologique - système couplé humain-naturel

**Partie Prenante**: Individu ou groupe avec intérêt ou enjeu dans les résultats du système

**visNetwork**: Package R pour visualisation de réseau interactive utilisant la bibliothèque vis.js

---

**Version du Document:** 1.10.0
**Dernière Mise à Jour:** Mars 2026
**Licence:** CC BY 4.0
**Contact:** support@marinesabres.eu
**Site Web:** www.marinesabres.eu

---
