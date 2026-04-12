<div class="alert alert-info" role="alert">
<strong>Hinweis:</strong> Dieses Handbuch wurde maschinell aus dem Englischen mit Claude AI übersetzt.
Wenn Sie Fehler bemerken, melden Sie diese bitte dem MarineSABRES-Projektteam.
<em>Übersetzungsstatus: Entwurf (maschinell übersetzt, Überprüfung ausstehend)</em>
</div>

# ISA-Dateneingabemodul - Benutzerhandbuch {#isa-data-entry-module---user-guide}

## MarineSABRES Analyse-Tool für Sozial-Ökologische Systeme {#marinesabres-social-ecological-systems-analysis-tool}

**Version:** 1.0
**Letzte Aktualisierung:** April 2026

---

## Inhaltsverzeichnis {#table-of-contents}

1. [Einführung](#introduction)
2. [Erste Schritte](#getting-started)
3. [Das DAPSI(W)R(M)-Rahmenwerk](#the-dapsiwrm-framework)
4. [Schritt-für-Schritt-Arbeitsablauf](#step-by-step-workflow)
5. [Übung-für-Übung-Anleitung](#exercise-by-exercise-guide)
6. [Arbeiten mit Kumu](#working-with-kumu)
7. [Datenverwaltung](#data-management)
8. [Tipps und Best Practices](#tips-and-best-practices)
9. [Fehlerbehebung](#troubleshooting)
10. [Glossar](#glossary)

---

## Einführung {#introduction}

### Was ist das ISA-Modul?

Das Dateneingabemodul der Integrierten Systemanalyse (ISA) ist ein umfassendes Werkzeug zur Analyse mariner sozial-ökologischer Systeme unter Verwendung des DAPSI(W)R(M)-Rahmenwerks. Es führt Sie durch einen systematischen 13-Übungen-Prozess, um:

- Die Struktur Ihres marinen sozial-ökologischen Systems zu kartieren
- Kausale Beziehungen zwischen menschlichen Aktivitäten und Ökosystemveränderungen zu identifizieren
- Rückkopplungsschleifen und Systemdynamiken zu verstehen
- Hebelpunkte für politische Interventionen zu identifizieren
- Visuelle Kausale Schleifendiagramme (CLD) zu erstellen
- Ergebnisse mit Interessengruppen zu validieren

### Wer sollte dieses Werkzeug nutzen?

- Manager mariner Ökosysteme und politische Entscheidungsträger
- Umweltwissenschaftler und Forscher
- Küstenzonenplaner
- Naturschutzpraktiker
- Interessengruppen, die an der Meeresbewirtschaftung beteiligt sind
- Studierende der marinen sozial-ökologischen Systeme

### Hauptmerkmale

- **Strukturierter Arbeitsablauf:** 13 Übungen führen Sie systematisch durch die Analyse
- **Integrierte Hilfe:** Kontextsensitive Hilfe für jede Übung
- **Datenexport:** Export nach Excel und Kumu-Visualisierungssoftware
- **BOT-Diagramme:** Visualisieren Sie zeitliche Dynamiken mit Verhaltens-über-die-Zeit-Diagrammen
- **Flexibel:** Importieren/exportieren Sie Daten, speichern Sie den Fortschritt, arbeiten Sie im Team

---

## Erste Schritte {#getting-started}

### Zugang zum ISA-Modul

1. Starten Sie die MarineSABRES Shiny-Anwendung
2. Wählen Sie im Seitenmenü **„ISA-Dateneingabe"**
3. Sie sehen die ISA-Hauptoberfläche mit den Übungsregisterkarten

### Überblick über die Oberfläche

Die Oberfläche des ISA-Moduls besteht aus:

- **Kopfzeile:** Titel und Rahmenwerk-Beschreibung mit Haupthilfe-Button
- **Übungsregisterkarten:** 13 Übungen plus BOT-Diagramme und Datenverwaltung
- **Hilfe-Buttons:** Klicken Sie auf das Hilfe-Symbol (?) bei jeder Übung für detaillierte Anleitung
- **Eingabeformulare:** Dynamische Formulare zur Dateneingabe
- **Datentabellen:** Sehen Sie Ihre eingegebenen Daten in sortierbaren, durchsuchbaren Tabellen
- **Speichern-Buttons:** Speichern Sie Ihre Arbeit nach Abschluss jeder Übung

### Hilfe erhalten

**Hauptrahmenwerk-Leitfaden:** Klicken Sie oben auf den Button „ISA-Rahmenwerk-Leitfaden" für einen Überblick über DAPSI(W)R(M).

**Übungsspezifische Hilfe:** Klicken Sie auf den „Hilfe"-Button in jeder Übungsregisterkarte für detaillierte Anweisungen, Beispiele und Tipps.

---

## Das DAPSI(W)R(M)-Rahmenwerk {#the-dapsiwrm-framework}

### Überblick

DAPSI(W)R(M) ist ein kausales Rahmenwerk zur Analyse mariner sozial-ökologischer Systeme:

- **D** - **Treibende Kräfte (Drivers):** Grundlegende Kräfte, die menschliche Aktivitäten motivieren (wirtschaftliche, soziale, technologische, politische)
- **A** - **Aktivitäten (Activities):** Menschliche Nutzungen mariner und küstennaher Umgebungen
- **P** - **Belastungen (Pressures):** Direkte Stressoren auf die Meeresumwelt
- **S** - **Zustandsänderungen (State Changes):** Veränderungen des Ökosystemzustands, dargestellt durch:
  - **W** - **Auswirkungen auf das Wohlergehen (Welfare):** Güter und Vorteile aus dem Ökosystem
  - **ES** - **Ökosystemleistungen (Ecosystem Services):** Leistungen, die Ökosysteme für Menschen erbringen
  - **MPF** - **Marine Prozesse und Funktionsweise (Marine Processes & Functioning):** Biologische, chemische und physikalische Prozesse
- **R** - **Reaktionen (Responses):** Gesellschaftliche Maßnahmen zur Problemlösung
- **M** - **Maßnahmen (Measures):** Politische Interventionen und Managementmaßnahmen

### Die Kausalkette

Das Rahmenwerk stellt eine Kausalkette dar:

```
Treibende Kräfte → Aktivitäten → Belastungen → Zustandsänderungen (MPF → ES → Wohlergehen) → Reaktionen
    ↑                                                                                            ↓
    └──────────────────────── Rückkopplungsschleife ────────────────────────────────────────────┘
```

### Warum DAPSI(W)R(M)?

- **Systematisch:** Gewährleistet umfassende Abdeckung aller Systemkomponenten
- **Kausal:** Stellt explizite Verbindungen zwischen menschlichen Handlungen und Ökosystemveränderungen her
- **Zirkulär:** Erfasst Rückkopplungsschleifen zwischen Ökosystem und Gesellschaft
- **Politikrelevant:** Verbindet direkt mit Interventionspunkten (Reaktionen/Maßnahmen)
- **Weit verbreitet:** Standardrahmenwerk in der europäischen Meerespolitik (MSFD, WFD)

---

## Schritt-für-Schritt-Arbeitsablauf {#step-by-step-workflow}

### Empfohlene Reihenfolge

Folgen Sie den Übungen der Reihe nach für beste Ergebnisse:

**Phase 1: Eingrenzung (Exercise 0)**
- Definieren Sie die Grenzen und den Kontext Ihrer Fallstudie

**Phase 2: Aufbau der Kausalkette (Exercises 1-5)**
- Arbeiten Sie rückwärts von den Auswirkungen auf das Wohlergehen zu den Grundursachen
- Exercise 1: Güter und Vorteile (was Menschen wertschätzen)
- Exercise 2a: Ökosystemleistungen (wie Ökosysteme Vorteile erbringen)
- Exercise 2b: Marine Prozesse (zugrundeliegende ökologische Funktionen)
- Exercise 3: Belastungen (Stressoren auf das Ökosystem)
- Exercise 4: Aktivitäten (menschliche Nutzungen der Meeresumwelt)
- Exercise 5: Treibende Kräfte (Kräfte, die Aktivitäten motivieren)

**Phase 3: Schließen der Schleife (Exercise 6)**
- Verbinden Sie treibende Kräfte zurück mit den Gütern und Vorteilen, um Rückkopplungsschleifen zu erstellen

**Phase 4: Visualisierung (Exercises 7-9)**
- Erstellen Sie Kausale Schleifendiagramme in Kumu
- Exportieren und verfeinern Sie Ihr visuelles Modell

**Phase 5: Analyse und Validierung (Exercises 10-12)**
- Verfeinern Sie Ihr Modell (Klärung)
- Identifizieren Sie Hebelpunkte
- Validieren Sie mit Interessengruppen

**Fortlaufend: BOT-Diagramme**
- Fügen Sie zeitliche Daten hinzu, wenn verfügbar
- Nutzen Sie sie zur Validierung kausaler Hypothesen

### Zeitanforderungen

**Schnellanalyse:** 4-8 Stunden (vereinfachte Fallstudie, kleines Team)

**Umfassende Analyse:** 2-4 Tage (komplexe Fallstudie, Einbindung von Interessengruppen)

**Vollständiger partizipativer Prozess:** 1-2 Wochen (mehrere Workshops, umfassende Validierung)

### Teamarbeit

**Einzelarbeit:**
- Eine Person gibt Daten basierend auf Literaturrecherche und Expertenwissen ein

**Kollaboratives Arbeiten:**
- Exportieren/importieren Sie Excel-Dateien zum Datenaustausch
- Nutzen Sie die kollaborativen Funktionen von Kumu für die CLD-Entwicklung
- Führen Sie Workshops durch, um Beiträge für die Übungen zu sammeln

---

## Übung-für-Übung-Anleitung {#exercise-by-exercise-guide}

### Exercise 0: Entfaltung der Komplexität und Auswirkungen auf das Wohlergehen

**Zweck:** Festlegung des Kontexts und der Grenzen Ihrer Analyse.

**Was einzugeben ist:**
- Name der Fallstudie
- Kurze Beschreibung
- Geographischer Umfang (z.B. „Ostsee", „Nordatlantikküste")
- Zeitlicher Umfang (z.B. „2000-2024")
- Auswirkungen auf das Wohlergehen (erste Beobachtungen)
- Wichtige Interessengruppen

**Tipps:**
- Seien Sie umfassend, aber prägnant
- Berücksichtigen Sie verschiedene Perspektiven (ökologisch, wirtschaftlich, sozial, kulturell)
- Schließen Sie sowohl Vorteile als auch Kosten ein
- Listen Sie alle betroffenen und entscheidungstragenden Interessengruppen auf

**Beispiel:**
```
Fall: Kommerzielle Fischerei der Ostsee
Geographischer Umfang: Ostseebecken
Zeitlicher Umfang: 2000-2024
Auswirkungen auf das Wohlergehen: Fischfangeinkommen, Beschäftigung, Ernährungssicherheit,
                                   Kulturerbe, abnehmende Bestände
Interessengruppen: Kommerzielle Fischer, Küstengemeinden, Verarbeiter,
                   Verbraucher, NGOs, Fischereimanager, EU-Politikentscheider
```

---

### Exercise 1: Spezifizierung von Gütern und Vorteilen (G&B)

**Zweck:** Identifizieren, was Menschen am marinen Ökosystem wertschätzen.

**Was für jedes Gut/jeden Vorteil einzugeben ist:**
- **Name:** Klarer, spezifischer Name (z.B. „Kommerzieller Dorschfang")
- **Typ:** Versorgend / Regulierend / Kulturell / Unterstützend
- **Beschreibung:** Was dieser Vorteil bietet
- **Interessengruppe:** Wer profitiert?
- **Wichtigkeit:** Hoch / Mittel / Niedrig
- **Trend:** Zunehmend / Stabil / Abnehmend / Unbekannt

**Anleitung:**
1. Klicken Sie auf „Gut/Vorteil hinzufügen"
2. Füllen Sie alle Felder aus
3. Klicken Sie auf „Exercise 1 speichern", um die Tabelle zu aktualisieren
4. Jedes G&B erhält automatisch eine eindeutige ID (GB001, GB002, usw.)

**Beispiele:**

| Name | Typ | Interessengruppe | Wichtigkeit |
|------|-----|------------------|-------------|
| Kommerzielle Fischanlandungen | Versorgend | Fischer, Verbraucher | Hoch |
| Küstenerholung | Kulturell | Touristen, Anwohner | Hoch |
| Sturmflutschutz | Regulierend | Küstenimmobilienbesitzer | Hoch |
| Kohlenstoffbindung | Regulierend | Globale Gesellschaft | Mittel |

**Tipps:**
- Seien Sie spezifisch: „Kommerzielle Dorschfischerei" nicht nur „Fischerei"
- Schließen Sie marktfähige (Fischverkauf) und nicht-marktfähige (Erholung) Vorteile ein
- Berücksichtigen Sie Vorteile für verschiedene Interessengruppen
- Denken Sie an Synergien und Zielkonflikte

---

### Exercise 2a: Ökosystemleistungen (ES), die Güter und Vorteile beeinflussen

**Zweck:** Die Kapazität des Ökosystems zur Erzeugung von Vorteilen identifizieren.

**Was für jede Ökosystemleistung einzugeben ist:**
- **Name:** Name der Leistung
- **Typ:** Klassifizierung der Leistung
- **Beschreibung:** Wie sie funktioniert
- **Verknüpft mit G&B:** Auswahl aus dem Dropdown-Menü (Güter/Vorteile aus Üb. 1)
- **Mechanismus:** Wie erzeugt diese Leistung den Vorteil?
- **Vertrauen:** Hoch / Mittel / Niedrig

**ES vs. G&B verstehen:**
- **Ökosystemleistung:** Das Potenzial/die Kapazität (z.B. „Fischbestandsproduktivität")
- **Gut/Vorteil:** Der realisierte Vorteil (z.B. „Kommerzieller Fischfang")

**Anleitung:**
1. Klicken Sie auf „Ökosystemleistung hinzufügen"
2. Füllen Sie die Felder aus
3. Wählen Sie, welches G&B diese ES unterstützt (Dropdown zeigt alle G&B aus Exercise 1)
4. Klicken Sie auf „Exercise 2a speichern"

**Beispiele:**

| ES-Name | Verknüpft mit G&B | Mechanismus |
|---------|-------------------|-------------|
| Fischbestandsrekrutierung | Kommerzieller Fischfang | Laicherfolg → befischbare Biomasse |
| Muschelfiltrierung | Wasserqualität für Tourismus | Muscheln filtern Partikel → klares Wasser |
| Seegrashabitat | Kinderstube für kommerzielle Arten | Schutz für Jungfische → adulter Fischbestand |

**Tipps:**
- Ein G&B kann von mehreren ES unterstützt werden
- Eine ES kann mehrere G&B unterstützen
- Beschreiben Sie den Mechanismus klar (erleichtert die Validierung)
- Nutzen Sie wissenschaftliches Wissen und Beiträge der Interessengruppen

---

### Exercise 2b: Marine Prozesse und Funktionsweise (MPF)

**Zweck:** Die grundlegenden ökologischen Prozesse identifizieren, die Ökosystemleistungen unterstützen.

**Was für jeden marinen Prozess einzugeben ist:**
- **Name:** Name des Prozesses
- **Typ:** Biologisch / Chemisch / Physikalisch / Ökologisch
- **Beschreibung:** Was dieser Prozess bewirkt
- **Verknüpft mit ES:** Auswahl aus dem Dropdown-Menü (ES aus Üb. 2a)
- **Mechanismus:** Wie erzeugt dieser Prozess die Leistung?
- **Räumliche Skala:** Wo er auftritt (lokal/regional/beckenweit)

**Arten mariner Prozesse:**
- **Biologisch:** Primärproduktion, Prädation, Reproduktion, Migration
- **Chemisch:** Nährstoffkreislauf, Kohlenstoffbindung, pH-Regulierung
- **Physikalisch:** Wasserzirkulation, Sedimenttransport, Welleneinwirkung
- **Ökologisch:** Habitatstruktur, Nahrungsnetz-Dynamik, Biodiversität

**Anleitung:**
1. Klicken Sie auf „Marinen Prozess hinzufügen"
2. Füllen Sie die Felder aus
3. Wählen Sie, welche ES dieser MPF unterstützt
4. Klicken Sie auf „Exercise 2b speichern"

**Beispiele:**

| MPF-Name | Typ | Verknüpft mit ES | Mechanismus |
|----------|-----|------------------|-------------|
| Phytoplankton-Primärproduktion | Biologisch | Fischbestandsproduktivität | Licht + Nährstoffe → Biomasse → Nahrungsnetz |
| Seegras-Photosynthese | Biologisch | Kohlenstoffspeicherung | CO2-Aufnahme → organisches Material → Sedimenteinlagerung |
| Muschelbankfiltration | Ökologisch | Wasserklarheit | Filtrierende Ernährung entfernt Partikel |

**Tipps:**
- Konzentrieren Sie sich auf Prozesse, die für Ihre ES relevant sind
- Nutzen Sie wissenschaftliche Expertise
- Berücksichtigen Sie räumliche und zeitliche Skalen
- Mehrere Prozesse können zu einer ES beitragen

---

### Exercise 3: Spezifizierung von Belastungen auf Zustandsänderungen

**Zweck:** Stressoren identifizieren, die marine Prozesse beeinflussen.

**Was für jede Belastung einzugeben ist:**
- **Name:** Klarer Name der Belastung
- **Typ:** Physikalisch / Chemisch / Biologisch / Mehrfach
- **Beschreibung:** Art des Stressors
- **Verknüpft mit MPF:** Auswahl aus dem Dropdown-Menü (MPF aus Üb. 2b)
- **Intensität:** Hoch / Mittel / Niedrig / Unbekannt
- **Räumlich:** Wo sie auftritt
- **Zeitlich:** Wann/wie oft (kontinuierlich/saisonal/episodisch)

**Arten von Belastungen:**
- **Physikalisch:** Abrasion des Meeresbodens, Habitatverlust, Lärm, Wärme
- **Chemisch:** Nährstoffanreicherung, Schadstoffe, Versauerung
- **Biologisch:** Artenentnahme, invasive Arten, Pathogene
- **Mehrfach:** Kombinierte Effekte

**Anleitung:**
1. Klicken Sie auf „Belastung hinzufügen"
2. Füllen Sie die Felder aus
3. Wählen Sie, welchen MPF diese Belastung beeinflusst
4. Bewerten Sie die Intensität und beschreiben Sie räumliche/zeitliche Muster
5. Klicken Sie auf „Exercise 3 speichern"

**Beispiele:**

| Belastungsname | Typ | Verknüpft mit MPF | Intensität |
|----------------|-----|-------------------|------------|
| Nährstoffanreicherung | Chemisch | Phytoplanktonzusammensetzung | Hoch |
| Grundschleppnetzfischerei | Physikalisch | Benthische Habitatstruktur | Hoch |
| Überfischung | Biologisch | Nahrungsnetz-Dynamik | Mittel |

**Tipps:**
- Eine Belastung kann mehrere Prozesse beeinflussen
- Spezifizieren Sie den direkten Mechanismus
- Berücksichtigen Sie kumulative Effekte
- Schließen Sie sowohl chronische als auch akute Belastungen ein
- Nutzen Sie wissenschaftliche Belege für Intensitätsbewertungen

---

### Exercise 4: Spezifizierung von Aktivitäten, die Belastungen verursachen

**Zweck:** Menschliche Aktivitäten identifizieren, die Belastungen erzeugen.

**Was für jede Aktivität einzugeben ist:**
- **Name:** Klarer Name
- **Sektor:** Fischerei / Aquakultur / Tourismus / Schifffahrt / Energie / Bergbau / Sonstige
- **Beschreibung:** Worin die Aktivität besteht
- **Verknüpft mit Belastung:** Auswahl aus dem Dropdown-Menü (Belastungen aus Üb. 3)
- **Skala:** Lokal / Regional / National / International
- **Häufigkeit:** Kontinuierlich / Saisonal / Gelegentlich / Einmalig

**Häufige marine Aktivitäten:**
- **Fischerei:** Kommerzielle/Freizeit-/Subsistenzfischerei
- **Aquakultur:** Fisch-/Muschelzucht
- **Tourismus:** Strandtourismus, Wildtierbeobachtung, Tauchen
- **Schifffahrt:** Fracht, Kreuzfahrten, Fähren
- **Energie:** Offshore-Windkraft, Öl und Gas, Gezeiten-/Wellenenergie
- **Infrastruktur:** Häfen, Küstenbau
- **Landwirtschaft:** Nährstoffabfluss (landbasiert, aber mit mariner Auswirkung)

**Anleitung:**
1. Klicken Sie auf „Aktivität hinzufügen"
2. Füllen Sie die Felder aus
3. Wählen Sie, welche Belastung(en) diese Aktivität erzeugt
4. Geben Sie Skala und Häufigkeit an
5. Klicken Sie auf „Exercise 4 speichern"

**Beispiele:**

| Aktivitätsname | Sektor | Verknüpft mit Belastung | Skala |
|----------------|--------|-------------------------|-------|
| Grundschleppnetzfischerei | Fischerei | Abrasion des Meeresbodens | Regional |
| Küstenabwassereinleitung | Abfall | Nährstoffanreicherung | Lokal |
| Schiffsverkehr | Schifffahrt | Unterwasserlärm, Ölverschmutzung | International |

**Tipps:**
- Seien Sie spezifisch: „Grundschleppnetzfischerei" nicht nur „Fischerei"
- Eine Aktivität erzeugt oft mehrere Belastungen
- Berücksichtigen Sie direkte und indirekte Wirkungspfade
- Schließen Sie saisonale Muster ein

---

### Exercise 5: Treibende Kräfte, die zu Aktivitäten führen

**Zweck:** Die zugrundeliegenden Kräfte identifizieren, die Aktivitäten motivieren.

**Was für jede treibende Kraft einzugeben ist:**
- **Name:** Klarer Name
- **Typ:** Wirtschaftlich / Sozial / Technologisch / Politisch / Umweltbezogen / Demographisch
- **Beschreibung:** Was diese Kraft ist und wie sie wirkt
- **Verknüpft mit Aktivität:** Auswahl aus dem Dropdown-Menü (Aktivitäten aus Üb. 4)
- **Trend:** Zunehmend / Stabil / Abnehmend / Zyklisch / Unsicher
- **Steuerbarkeit:** Hoch / Mittel / Niedrig / Keine

**Arten treibender Kräfte:**
- **Wirtschaftlich:** Marktnachfrage, Preise, Subventionen, Wirtschaftswachstum
- **Sozial:** Kulturelle Traditionen, Verbraucherpräferenzen, soziale Normen
- **Technologisch:** Fanggeräteinnovation, Schiffseffizienz, neue Techniken
- **Politisch:** Regulierungen, Governance, internationale Abkommen
- **Umweltbezogen:** Klimawandel, Extremwetterereignisse (als Anpassungstreiber)
- **Demographisch:** Bevölkerungswachstum, Urbanisierung, Migration

**Anleitung:**
1. Klicken Sie auf „Treibende Kraft hinzufügen"
2. Füllen Sie die Felder aus
3. Wählen Sie, welche Aktivität(en) diese Kraft motiviert
4. Bewerten Sie Trend und Steuerbarkeit
5. Klicken Sie auf „Exercise 5 speichern"

**Beispiele:**

| Name der Kraft | Typ | Verknüpft mit Aktivität | Steuerbarkeit |
|----------------|-----|-------------------------|---------------|
| Globale Nachfrage nach Meeresfrüchten | Wirtschaftlich | Expansion der kommerziellen Fischerei | Niedrig |
| EU-Ziele für erneuerbare Energien | Politisch | Offshore-Windentwicklung | Hoch |
| Nachfrage nach Küstentourismus | Sozial/Wirtschaftlich | Küstenentwicklung | Mittel |

**Tipps:**
- Denken Sie darüber nach, WARUM Menschen Aktivitäten ausüben
- Berücksichtigen Sie sowohl Push- als auch Pull-Faktoren
- Treibende Kräfte interagieren oft (wirtschaftlich + technologisch + politisch)
- Bewerten Sie die Steuerbarkeit ehrlich
- Treibende Kräfte sind oft die besten Interventionspunkte

---

### Exercise 6: Schließen der Schleife - Treibende Kräfte zu Gütern und Vorteilen

**Zweck:** Rückkopplungsschleifen erstellen, indem treibende Kräfte zurück mit Gütern und Vorteilen verbunden werden.

**Was zu identifizieren ist:**
- Wie beeinflussen Veränderungen bei Gütern und Vorteilen die treibenden Kräfte?
- Wie reagieren treibende Kräfte auf Ökosystembedingungen?
- Welche Rückkopplungen sind verstärkend (amplifierend)?
- Welche sind ausgleichend (stabilisierend)?

**Arten von Rückkopplungsschleifen:**

**Verstärkende Schleifen (R):** Veränderungen verstärken sich selbst
- Beispiel: Abnehmende Fischbestände → Geringere Gewinne → Mehr Fischereiaufwand zur Einkommenserhaltung → Weiterer Rückgang

**Ausgleichende Schleifen (B):** Veränderungen lösen ausgleichende Reaktionen aus
- Beispiel: Abnehmende Wasserqualität → Rückgang des Tourismus → Wirtschaftlicher Druck zur Sanierung → Verbesserte Qualität

**Anleitung:**
1. Überprüfen Sie die Schleifenverbindungs-Oberfläche
2. Wählen Sie treibende-Kraft-zu-G&B-Verbindungen, die bedeutsame Rückkopplungen erzeugen
3. Dokumentieren Sie, ob Rückkopplungen verstärkend oder ausgleichend sind
4. Klicken Sie auf „Exercise 6 speichern"

**Beispiele:**

| Von (G&B) | Zu (Treibende Kraft) | Typ | Erklärung |
|-----------|----------------------|-----|-----------|
| Rückgang des Fischfangs | Reduzierte Fischereikapazität | Ausgleichend | Geringe Gewinne drängen Fischer aus der Industrie |
| Verbesserte Wasserqualität | Politische Unterstützung für Naturschutz | Verstärkend | Erfolg erzeugt mehr Naturschutzpolitik |
| Küstensturmschäden | Politik der Ökosystemwiederherstellung | Ausgleichend | Verluste lösen Schutzmaßnahmen aus |

**Tipps:**
- Nicht alle treibenden Kräfte müssen zurückverbunden werden
- Berücksichtigen Sie Zeitverzögerungen (Jahre bis zur Manifestation)
- Das Wissen der Interessengruppen ist entscheidend
- Dokumentieren Sie den Schleifentyp (R oder B)

---

### Exercises 7-9: Erstellung und Export von Kausalen Schleifendiagrammen

**Zweck:** Visualisierung Ihrer Systemstruktur in der Kumu-Software.

#### Exercise 7: Erstellen eines wirkungsbasierten CLD in Kumu

**Schritte:**
1. Klicken Sie auf „Kumu-CSV-Dateien herunterladen", um Ihre Daten zu exportieren
2. Gehen Sie zu [kumu.io](https://kumu.io) und erstellen Sie ein kostenloses Konto
3. Erstellen Sie ein neues Projekt (wählen Sie die Vorlage „Causal Loop Diagram")
4. Importieren Sie Ihre CSV-Dateien:
   - `elements.csv` → enthält alle Knoten
   - `connections.csv` → enthält alle Kanten
5. Wenden Sie den Kumu-Stilcode aus `Documents/Kumu_Code_Style.txt` an
6. Ordnen Sie die Elemente an, um klare kausale Flüsse zu zeigen

**Kumu-Farbschema:**
- Güter und Vorteile: Gelbe Dreiecke
- Ökosystemleistungen: Blaue Quadrate
- Marine Prozesse: Hellblaue Pillen
- Belastungen: Orange Rauten
- Aktivitäten: Grüne Sechsecke
- Treibende Kräfte: Violette Achtecke

#### Exercise 8: Von kausalen Logikketten zu kausalen Schleifen

**Schritte:**
1. Identifizieren Sie in Kumu geschlossene Schleifen in Ihrem Diagramm
2. Verfolgen Sie Pfade von einem Element zurück zu sich selbst
3. Klassifizieren Sie Schleifen als verstärkend (R) oder ausgleichend (B)
4. Fügen Sie Schleifen-Kennzeichnungen in Kumu hinzu (verwenden Sie Labels oder Tags)
5. Konzentrieren Sie sich auf die wichtigsten Schleifen, die das Systemverhalten bestimmen

**Schleifentyp identifizieren:**
- Zählen Sie die Anzahl der negativen (-) Verbindungen in der Schleife
- Gerade Anzahl von (-) Verbindungen = Verstärkend (R)
- Ungerade Anzahl von (-) Verbindungen = Ausgleichend (B)

#### Exercise 9: CLD für weitere Analyse exportieren

**Schritte:**
1. Exportieren Sie hochauflösende Bilder aus Kumu:
   - Klicken Sie auf Teilen → Exportieren → PNG/PDF
2. Laden Sie die vollständige Excel-Arbeitsmappe aus dem ISA-Modul herunter
3. Überprüfen Sie die Adjazenzmatrizen, um alle Verbindungen zu verifizieren
4. Erstellen Sie verschiedene Ansichten:
   - Gesamtsystemansicht
   - Subsystemansichten (z.B. nur Fischerei)
   - Schlüsselschleifen-Ansichten
5. Dokumentieren Sie Schlüsselschleifen mit narrativen Beschreibungen

**Klicken Sie auf „Exercises 7-9 speichern", wenn Sie fertig sind.**

---

### Exercises 10-12: Klärung, Metriken und Validierung

#### Exercise 10: Klärung - Endogenisierung und Kapselung

**Endogenisierung:** Einbeziehung externer Faktoren innerhalb der Systemgrenzen

**Was zu tun ist:**
1. Überprüfen Sie die externen treibenden Kräfte
2. Können einige durch Faktoren innerhalb Ihres Systems erklärt werden?
3. Fügen Sie diese internen Rückkopplungen hinzu
4. Dokumentieren Sie in „Endogenisierungs-Notizen"

**Beispiel:** „Marktnachfrage" könnte durch „Produktqualität" innerhalb Ihres Systems beeinflusst werden

**Kapselung:** Gruppierung detaillierter Prozesse zu übergeordneten Konzepten

**Was zu tun ist:**
1. Identifizieren Sie übermäßig komplexe Subsysteme
2. Gruppieren Sie verwandte Elemente (z.B. mehrere Nährstoffprozesse → „Eutrophierungsdynamik")
3. Behalten Sie die detaillierte Version für technische Arbeit
4. Erstellen Sie eine vereinfachte Version für politische Kommunikation
5. Dokumentieren Sie in „Kapselungs-Notizen"

#### Exercise 11: Metriken, Grundursachen und Hebelpunkte

**Grundursachenanalyse:**
1. Nutzen Sie die „Grundursachen"-Oberfläche
2. Identifizieren Sie Elemente mit vielen ausgehenden Verbindungen
3. Verfolgen Sie Probleme rückwärts bis zu den Grundursachen
4. Konzentrieren Sie sich auf treibende Kräfte und Aktivitäten

**Identifizierung von Hebelpunkten:**
1. Nutzen Sie die „Hebelpunkte"-Oberfläche
2. Suchen Sie nach:
   - Schleifenkontrollpunkten
   - Knoten mit hoher Zentralität (viele Verbindungen)
   - Konvergenzpunkten (mehrere Pfade treffen sich)
3. Berücksichtigen Sie Machbarkeit und Steuerbarkeit
4. Priorisieren Sie umsetzbare Hebelpunkte

**Meadows' Hierarchie:**
- Schwächste: Parameter (Zahlen, Raten)
- Stärker: Rückkopplungsschleifen
- Sehr stark: Systemdesign/-struktur
- Stärkste: Paradigmen (Denkweisen, Ziele)

#### Exercise 12: Präsentation und Validierung der Ergebnisse

**Validierungsansätze:**
- ✓ Interne Teamüberprüfung
- ✓ Workshop mit Interessengruppen
- ✓ Experten-Peer-Review
- ✓ Endgültige Genehmigung

**Was zu tun ist:**
1. Führen Sie Validierungsaktivitäten durch
2. Zeichnen Sie Feedback in „Validierungsnotizen" auf
3. Markieren Sie die Kontrollkästchen für abgeschlossene Validierungstypen
4. Aktualisieren Sie Ihr Modell basierend auf Feedback
5. Bereiten Sie Präsentationen für verschiedene Zielgruppen vor

**Präsentationstipps:**
- Passen Sie die Komplexität an das Publikum an
- Nutzen Sie das visuelle CLD für den Überblick
- Erzählen Sie Geschichten über die Schlüsselschleifen
- Zeigen Sie BOT-Diagramme als Belege
- Verknüpfen Sie mit politischen Empfehlungen
- Seien Sie transparent über Unsicherheiten

**Klicken Sie auf „Exercises 10-12 speichern", wenn Sie fertig sind.**

---

### BOT-Diagramme: Verhalten über die Zeit {#bot-graphs-behaviour-over-time}

**Zweck:** Visualisierung zeitlicher Dynamiken zur Validierung Ihres kausalen Modells.

**Wie man BOT-Diagramme erstellt:**

1. **Elementtyp auswählen:** Wählen Sie aus dem Dropdown-Menü (Güter und Vorteile / ES / MPF / Belastungen / Aktivitäten / Treibende Kräfte)
2. **Spezifisches Element auswählen:** Wählen Sie das zu grafisch darzustellende Element
3. **Datenpunkte hinzufügen:**
   - Jahr
   - Wert
   - Einheit (z.B. „Tonnen", „%", „Index")
   - Klicken Sie auf „Datenpunkt hinzufügen"
4. **Diagramm ansehen:** Die Zeitreihe erscheint automatisch
5. **Wiederholen** für andere Elemente

**Muster, nach denen zu suchen ist:**
- **Trends:** Stetige Zunahme/Abnahme
- **Zyklen:** Regelmäßige Schwingungen
- **Stufen:** Plötzliche Veränderungen (Politikwechsel)
- **Verzögerungen:** Zeitliche Verschiebungen
- **Schwellenwerte:** Kipppunkte
- **Plateaus:** Stabilität

**Verwendung von BOT-Diagrammen:**
- Vergleichen Sie Muster mit den CLD-Vorhersagen
- Identifizieren Sie Belege für Rückkopplungsschleifen
- Messen Sie Zeitverzögerungen
- Bewerten Sie politische Interventionen
- Projizieren Sie Zukunftsszenarien

**Datenquellen:**
- Offizielle Statistiken
- Umweltmonitoring
- Wissenschaftliche Erhebungen
- Beobachtungen der Interessengruppen
- Historische Aufzeichnungen

**Klicken Sie auf „BOT-Daten speichern", um Ihre Arbeit zu sichern.**

---

## Arbeiten mit Kumu {#working-with-kumu}

### Erste Schritte mit Kumu

**1. Konto erstellen:**
- Gehen Sie zu [kumu.io](https://kumu.io)
- Registrieren Sie sich für ein kostenloses Konto
- Öffentliche Projekte sind kostenlos; private Projekte erfordern ein Abonnement

**2. Neues Projekt erstellen:**
- Klicken Sie auf „Neues Projekt"
- Wählen Sie die Vorlage „Causal Loop Diagram"
- Benennen Sie Ihr Projekt

**3. Daten importieren:**
- Laden Sie aus dem ISA-Modul die Kumu-CSV-Dateien herunter
- Klicken Sie in Kumu auf Importieren
- Laden Sie `elements.csv` und `connections.csv` hoch

### Benutzerdefinierte Stile anwenden

**Kumu-Code kopieren:**
- Öffnen Sie `Documents/Kumu_Code_Style.txt`
- Kopieren Sie den gesamten Inhalt

**Auf Ihre Karte anwenden:**
1. Klicken Sie in Kumu auf das Einstellungen-Symbol
2. Gehen Sie zum „Erweiterten Editor"
3. Fügen Sie den Code ein
4. Klicken Sie auf „Speichern"

**Ergebnis:** Ihre Elemente werden nach Typ farblich und formlich kodiert:
- Güter und Vorteile: Gelbe Dreiecke
- Ökosystemleistungen: Blaue Quadrate
- Marine Prozesse: Hellblaue Pillen
- Belastungen: Orange Rauten
- Aktivitäten: Grüne Sechsecke
- Treibende Kräfte: Violette Achtecke

### Mit dem Diagramm arbeiten

**Layout-Optionen:**
- Auto-Layout: Lassen Sie Kumu die Elemente anordnen
- Manuell: Ziehen Sie Elemente an bevorzugte Positionen
- Kreisförmig: Betonen Sie die Schleifenstruktur
- Hierarchisch: Zeigen Sie den kausalen Fluss von treibenden Kräften zum Wohlergehen

**Informationen hinzufügen:**
- Klicken Sie auf ein beliebiges Element, um Eigenschaften zu bearbeiten
- Fügen Sie Beschreibungen, Tags, benutzerdefinierte Felder hinzu
- Schließen Sie Datenquellen, Vertrauensniveaus ein

**Schleifen hervorheben:**
1. Identifizieren Sie einen geschlossenen Schleifenpfad
2. Fügen Sie allen Elementen in der Schleife ein „Schleifen"-Tag hinzu
3. Nutzen Sie den Kumu-Filter zum Ein-/Ausblenden von Schleifen
4. Beschriften Sie Schleifen (z.B. „R1: Überfischungsspirale", „B1: Qualitätserholung")

**Filter und Ansichten:**
- Filtern Sie nach Elementtyp (nur treibende Kräfte anzeigen)
- Filtern Sie nach Wichtigkeit, Vertrauen usw.
- Erstellen Sie mehrere Ansichten (Gesamtsystem, Schlüsselschleifen, Subsysteme)
- Speichern Sie Ansichten für Präsentationen

### Zusammenarbeit

**Teilen:**
- Teilen Sie einen Nur-Lese-Link mit Interessengruppen
- Exportieren Sie Screenshots für Berichte
- Betten Sie in Websites/Präsentationen ein

**Teambearbeitung:**
- Fügen Sie Mitarbeiter hinzu (kostenpflichtige Funktion)
- Mehrere Personen können gleichzeitig bearbeiten
- Versionskontrolle verfügbar

### Exportoptionen

**Aus Kumu:**
- **PNG:** Hochauflösendes Bild für Berichte
- **PDF:** Vektorformat für Publikationen
- **JSON:** Rohdaten zur Archivierung
- **Geteilter Link:** Interaktive Webansicht

**Aus dem ISA-Modul:**
- **Excel-Arbeitsmappe:** Vollständige Daten mit allen Blättern
- **Kumu-CSV:** Elemente und Verbindungen
- **Adjazenzmatrizen:** Verbindungsmatrizen für die Analyse

---

## Datenverwaltung {#data-management}

### Ihre Arbeit speichern

**Automatisches Speichern:**
- Daten werden während Ihrer Sitzung im reaktiven Zustand der Anwendung gespeichert
- Verwenden Sie die „Speichern"-Buttons nach Abschluss jeder Übung

**Nach Excel exportieren:**
1. Gehen Sie zur Registerkarte „Datenverwaltung"
2. Geben Sie den Dateinamen ein (z.B. „MeinFall_ISA_2024")
3. Klicken Sie auf „Nach Excel exportieren"
4. Die vollständige Arbeitsmappe mit allen Daten wird heruntergeladen

### Bestehende Daten importieren

**Aus Excel:**
1. Gehen Sie zur Registerkarte „Datenverwaltung"
2. Klicken Sie auf „Excel-Datei auswählen"
3. Wählen Sie Ihre zuvor exportierte .xlsx-Datei
4. Klicken Sie auf „Daten importieren"
5. Die Daten befüllen alle Übungen

**Excel-Dateistruktur:**
- Blatt: Case_Info
- Blatt: Goods_Benefits
- Blatt: Ecosystem_Services
- Blatt: Marine_Processes
- Blatt: Pressures
- Blatt: Activities
- Blatt: Drivers
- Blatt: BOT_Data

### Daten zurücksetzen

**Warnung:** Dies löscht ALLE Daten und kann nicht rückgängig gemacht werden.

1. Gehen Sie zur Registerkarte „Datenverwaltung"
2. Klicken Sie auf „Alle Daten zurücksetzen" (roter Button)
3. Bestätigen Sie die Aktion
4. Alle Übungen kehren zum leeren Zustand zurück

**Wann zurücksetzen:**
- Beginn einer völlig neuen Fallstudie
- Verwerfen eines Übungsdurchlaufs
- Nach Export der Daten, die Sie behalten möchten

### Kollaborative Arbeitsabläufe

**Einzelarbeit:**
- Eine Person gibt alle Daten ein
- Excel exportieren, wenn fertig
- Datei zur Überprüfung mit dem Team teilen

**Sequentielle Arbeit:**
- Person A: Exercises 0-3 → Exportieren
- Person B: Importieren → Exercises 4-6 → Exportieren
- Person C: Importieren → Exercises 7-12 → Endexport

**Parallele Arbeit:**
- Mehrere Personen arbeiten in separaten Sitzungen an verschiedenen Übungen
- In Excel konsolidieren (Blätter manuell zusammenführen)
- Konsolidierte Datei importieren

**Workshop-basiert:**
- Gruppendiskussionen für jede Übung moderieren
- Eine Person bedient das Tool und gibt Konsensdaten ein
- Nach jeder Übung zur Dokumentation exportieren

---

## Tipps und Best Practices {#tips-and-best-practices}

### Allgemeine Arbeitsablauf-Tipps

**1. Arbeiten Sie systematisch:**
- Schließen Sie die Übungen der Reihe nach ab
- Springen Sie nicht voraus (spätere Übungen bauen auf früheren auf)
- Speichern Sie nach jeder Übung

**2. Binden Sie Interessengruppen ein:**
- Führen Sie Workshops für die Exercises 1-6 durch
- Validieren Sie das CLD mit denjenigen, die das System kennen
- Nutzen Sie vielfältige Perspektiven (Nutzer, Manager, Wissenschaftler)

**3. Nutzen Sie wissenschaftliche Belege:**
- Basieren Sie Verknüpfungen auf begutachteten Studien
- Zitieren Sie Quellen in den Beschreibungen
- Vermerken Sie Vertrauensniveaus

**4. Beginnen Sie einfach, fügen Sie Detail hinzu:**
- Erster Durchgang: Nur Hauptelemente
- Zweiter Durchgang: Nuancen und Details hinzufügen
- Behalten Sie eine vereinfachte Version für die Kommunikation

**5. Dokumentieren Sie alles:**
- Nutzen Sie die Beschreibungsfelder großzügig
- Dokumentieren Sie Datenquellen
- Notieren Sie Annahmen und Unsicherheiten

### Tipps zur Datenqualität

**Seien Sie spezifisch:**
- ❌ „Fischerei" → ✅ „Kommerzielle Grundschleppnetzfischerei auf Bodenfischarten"
- ❌ „Verschmutzung" → ✅ „Nährstoffanreicherung durch landwirtschaftlichen Abfluss"

**Seien Sie umfassend:**
- Schließen Sie positive und negative Auswirkungen ein
- Berücksichtigen Sie alle Interessengruppen
- Decken Sie alle Sektoren ab, die den Meeresraum nutzen

**Seien Sie realistisch:**
- Konzentrieren Sie sich auf die wichtigsten Elemente (obere 80%)
- Versuchen Sie nicht, alles einzubeziehen
- Die Komplexität sollte dem verfügbaren Wissen entsprechen

**Seien Sie konsistent:**
- Verwenden Sie einheitliche Terminologie
- Halten Sie ein einheitliches Detailniveau über alle Übungen hinweg ein
- Befolgen Sie Namenskonventionen (z.B. Element-IDs)

### Tipps zur CLD-Entwicklung

**Layout:**
- Ordnen Sie im kausalen Fluss an: Treibende Kräfte → Aktivitäten → Belastungen → Zustand → Wohlergehen
- Platzieren Sie Rückkopplungsschleifen prominent
- Minimieren Sie Kantenkreuzungen für Lesbarkeit

**Schleifen:**
- Identifizieren und beschriften Sie Schlüsselschleifen (R1, R2, B1, B2)
- Konzentrieren Sie sich auf Schleifen, die problematisches Verhalten antreiben
- Dokumentieren Sie Schleifen-Narrative (welche Geschichte erzählt jede Schleife?)

**Validierung:**
- Erklärt das CLD das beobachtete Systemverhalten?
- Erkennen die Interessengruppen die Struktur?
- Können Sie spezifische historische Ereignisse durch das Diagramm verfolgen?

### Tipps für BOT-Diagramme

**Datenerhebung:**
- Verwenden Sie die längsten verfügbaren Zeitreihen
- Seien Sie konsistent mit Einheiten und Skalen
- Dokumentieren Sie Datenquellen klar

**Vergleich:**
- Stellen Sie verwandte Variablen auf derselben Zeitachse dar
- Suchen Sie nach Korrelationen (stimmen sie mit Ihrem CLD überein?)
- Identifizieren Sie Zeitverzögerungen zwischen Ursache und Wirkung

**Kommunikation:**
- Annotieren Sie mit Schlüsselereignissen (Politikwechsel, Katastrophen)
- Verwenden Sie konsistente Farbschemata
- Fügen Sie Fehlerbalken oder Unsicherheitsbereiche hinzu, wenn verfügbar

### Häufige Fehler, die zu vermeiden sind

**1. Zu viel Detail zu früh:**
- Beginnen Sie mit den Hauptelementen
- Fügen Sie Detail in Iterationen hinzu
- Behalten Sie eine vereinfachte Version

**2. Übergehung des Inputs der Interessengruppen:**
- Lokales Wissen ist unschätzbar
- Legitimität erfordert Beteiligung
- Blinde Flecken entstehen ohne vielfältige Perspektiven

**3. Verwechslung von ES und G&B:**
- ES = Kapazität/Potenzial des Ökosystems
- G&B = Realisierte Vorteile, die Menschen erhalten
- Beispiel: „Fischbestand" (ES) vs. „Fischfang" (G&B)

**4. Schwache Verknüpfungen:**
- Spezifizieren Sie immer den Mechanismus
- Vermeiden Sie vage Verbindungen
- Test: Können Sie diesen Link einer Interessengruppe erklären?

**5. Zeit ignorieren:**
- Verzögerungen sind entscheidend
- Manche Effekte brauchen Jahre, um sich zu manifestieren
- BOT-Diagramme zeigen zeitliche Muster

**6. Keine Rückkopplungsschleifen:**
- Exercise 6 ist kritisch
- Systeme sind zirkulär, nicht linear
- Rückkopplungen treiben die Dynamik an

**7. Validierung überspringen:**
- Ihr Modell ist eine Hypothese
- Testen Sie es gegen Daten und Wissen der Interessengruppen
- Iterieren Sie basierend auf Feedback

---

## Fehlerbehebung {#troubleshooting}

### Häufige Probleme und Lösungen

**Problem: „Meine Daten wurden nicht gespeichert"**
- **Lösung:** Klicken Sie immer auf den „Exercise X speichern"-Button nach der Dateneingabe
- Überprüfen Sie, ob sich die Datentabelle nach dem Speichern aktualisiert
- Exportieren Sie regelmäßig nach Excel als Sicherung

**Problem: „Dropdown-Listen sind leer"**
- **Ursache:** Sie haben die vorherige Übung nicht abgeschlossen
- **Lösung:** Schließen Sie die Übungen der Reihe nach ab. Üb. 2a benötigt Daten aus Üb. 1, usw.

**Problem: „Ich habe einen Fehler in einer vorherigen Übung gemacht"**
- **Lösung:** Gehen Sie zur Registerkarte dieser Übung zurück
- Die Daten sind noch vorhanden und bearbeitbar
- Nehmen Sie Korrekturen vor und klicken Sie erneut auf Speichern

**Problem: „Der Excel-Export funktioniert nicht"**
- **Prüfen Sie:** Die Download-Einstellungen des Browsers
- **Prüfen Sie:** Die Dateiberechtigungen im Download-Ordner
- **Versuchen Sie:** Einen anderen Browser

**Problem: „Der Kumu-Import schlägt fehl"**
- **Prüfen Sie:** Das CSV-Dateiformat (muss kommagetrennt sein)
- **Prüfen Sie:** Ob die Spaltenüberschriften den Kumu-Erwartungen entsprechen
- **Versuchen Sie:** Zuerst Elemente importieren, dann Verbindungen

**Problem: „Die Anwendung ist langsam bei großen Datensätzen"**
- **Normal:** Mehr als 100 Elemente können das Rendering verlangsamen
- **Lösung:** Arbeiten Sie an Subsystemen getrennt
- **Lösung:** Nutzen Sie Excel für die Datenverwaltung, die Anwendung für die Struktur

**Problem: „Ich finde den Hilfeinhalt nicht"**
- **Ort:** Klicken Sie auf den „?"-Hilfe-Button in jeder Übungsregisterkarte
- **Hauptleitfaden:** Klicken Sie oben im Modul auf „ISA-Rahmenwerk-Leitfaden"

### Zusätzliche Hilfe erhalten

**Dokumentation:**
- Dieses Benutzerhandbuch
- MarineSABRES Einfacher SES ENTWURF-Leitfaden (Dokumente-Ordner)
- Kumu-Dokumentation: [docs.kumu.io](https://docs.kumu.io)

**Technischer Support:**
- Prüfen Sie die App-Version und Browser-Kompatibilität
- Kontaktieren Sie das MarineSABRES-Projektteam
- Melden Sie Fehler über GitHub (falls zutreffend)

**Wissenschaftlicher Support:**
- Konsultieren Sie den Leitfaden für methodische Fragen
- Beziehen Sie Fachexperten für Ihre spezifische Fallstudie ein
- Nehmen Sie an ISA-Schulungsworkshops teil

---

## Glossar {#glossary}

**Aktivitäten (A):** Menschliche Nutzungen mariner und küstennaher Umgebungen (Fischerei, Schifffahrt, Tourismus usw.)

**Adjazenzmatrix:** Tabelle, die zeigt, welche Elemente mit welchen anderen Elementen verbunden sind

**Ausgleichende Schleife (B):** Rückkopplungsschleife, die Veränderungen entgegenwirkt und das System stabilisiert

**BOT-Diagramm (Verhalten über die Zeit):** Zeitreihendiagramm, das zeigt, wie sich ein Indikator über die Zeit verändert

**Kausalkette:** Lineare Abfolge von Ursache-Wirkungs-Beziehungen (z.B. Treibende Kräfte → Aktivitäten → Belastungen)

**Kausales Schleifendiagramm (CLD):** Visuelles Netzwerk, das Elemente und ihre kausalen Beziehungen einschließlich Rückkopplungsschleifen zeigt

**DAPSI(W)R(M):** Rahmenwerk für Treibende Kräfte-Aktivitäten-Belastungen-Zustand(Wohlergehen)-Reaktionen(Maßnahmen)

**Treibende Kräfte (D):** Grundlegende Kräfte, die Aktivitäten motivieren (wirtschaftlich, sozial, politisch, technologisch)

**Ökosystemleistungen (ES):** Die Kapazität von Ökosystemen, Vorteile für Menschen zu erzeugen

**Kapselung:** Gruppierung detaillierter Elemente zu übergeordneten Konzepten zur Vereinfachung

**Endogenisierung:** Einbeziehung externer Faktoren in die Systemgrenzen durch Hinzufügen interner Rückkopplungen

**Rückkopplungsschleife:** Zirkulärer Kausalpfad, in dem ein Element sich selbst durch eine Kette anderer Elemente beeinflusst

**Güter und Vorteile (G&B):** Realisierte Vorteile, die Menschen aus marinen Ökosystemen erhalten (Auswirkungen auf das Wohlergehen)

**ISA (Integrierte Systemanalyse):** Systematisches Rahmenwerk zur Analyse sozial-ökologischer Systeme

**Kumu:** Kostenlose Online-Netzwerk-Visualisierungssoftware (kumu.io)

**Hebelpunkt:** Stelle im System, an der eine kleine Intervention eine große Veränderung bewirken kann

**Marine Prozesse und Funktionsweise (MPF):** Biologische, chemische, physikalische und ökologische Prozesse, die Ökosystemleistungen unterstützen

**Maßnahmen (M):** Politische Interventionen und Managementmaßnahmen (Reaktionen)

**Polarität:** Richtung des kausalen Einflusses (+ gleiche Richtung, - entgegengesetzte Richtung)

**Belastungen (P):** Direkte Stressoren auf die Meeresumwelt (Verschmutzung, Habitatzerstörung, Artenentnahme)

**Verstärkende Schleife (R):** Rückkopplungsschleife, die Veränderungen verstärkt (kann ein Tugend- oder Teufelskreis sein)

**Reaktionen (R):** Gesellschaftliche Maßnahmen zur Problemlösung

**Grundursache:** Fundamentale treibende Kraft oder Aktivität am Ursprung einer Kausalkette

**Sozial-ökologisches System (SES):** Integriertes System aus Menschen und Natur mit wechselseitigen Rückkopplungen

**Zustandsänderungen (S):** Veränderungen des Ökosystemzustands (dargestellt durch W, ES und MPF)

**Wohlergehen (W):** Menschliches Wohlergehen, dargestellt durch Güter und Vorteile aus Ökosystemen

---

## Anhang: Kurzreferenzkarte {#appendix-quick-reference-card}

### Übungs-Checkliste

- [ ] Exercise 0: Umfang der Fallstudie definieren
- [ ] Exercise 1: Alle Güter und Vorteile auflisten
- [ ] Exercise 2a: Ökosystemleistungen identifizieren
- [ ] Exercise 2b: Marine Prozesse und Funktionsweise identifizieren
- [ ] Exercise 3: Belastungen identifizieren
- [ ] Exercise 4: Aktivitäten identifizieren
- [ ] Exercise 5: Treibende Kräfte identifizieren
- [ ] Exercise 6: Rückkopplungsschleifen schließen
- [ ] Exercise 7: CLD in Kumu erstellen
- [ ] Exercise 8: Kausale Schleifen identifizieren
- [ ] Exercise 9: CLD exportieren und dokumentieren
- [ ] Exercise 10: Modell klären (Endogenisierung, Kapselung)
- [ ] Exercise 11: Hebelpunkte identifizieren
- [ ] Exercise 12: Mit Interessengruppen validieren
- [ ] BOT-Diagramme: Zeitliche Daten hinzufügen
- [ ] Endgültige Excel-Arbeitsmappe exportieren

### Tastaturkürzel

- **Tab:** Zwischen Formularfeldern wechseln
- **Enter:** Formular absenden/speichern
- **Strg+F / Cmd+F:** In Tabellen suchen

### Dateispeicherorte

- **Benutzerhandbuch:** `Documents/ISA_User_Guide.md`
- **Leitfaden-Dokument:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Kumu-Styling:** `Documents/Kumu_Code_Style.txt`
- **Excel-Vorlage:** `Documents/ISA Excel Workbook.xlsx`

### Nützliche Links

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Kumu-Dokumentation:** [https://docs.kumu.io](https://docs.kumu.io)
- **DAPSI(W)R-Rahmenwerk:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Dokumentinformationen {#document-information}

**Dokument:** ISA-Dateneingabemodul - Benutzerhandbuch
**Projekt:** MarineSABRES Toolbox für Sozial-Ökologische Systeme
**Version:** 1.0
**Datum:** April 2026
**Status:** Entwurf (maschinelle Übersetzung)

**Zitierung:**
> MarineSABRES-Projekt (2025). ISA-Dateneingabemodul - Benutzerhandbuch.
> MarineSABRES Analyse-Tool für Sozial-Ökologische Systeme, Version 1.0.

**Lizenz:** Dieses Handbuch wird zur Verwendung mit der MarineSABRES SES-Toolbox bereitgestellt.

---

**Für Fragen, Feedback oder Support wenden Sie sich bitte an das MarineSABRES-Projektteam.**

**Viel Erfolg bei der Analyse!**
