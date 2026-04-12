<div class="alert alert-info" role="alert">
<strong>Nota:</strong> Questa guida è stata tradotta automaticamente dall'inglese utilizzando Claude AI.
Se riscontrate errori, segnalateli al team del progetto MarineSABRES.
<em>Stato della traduzione: Bozza (traduzione automatica, in attesa di revisione)</em>
</div>

# Modulo di Inserimento Dati ISA - Guida Utente {#isa-data-entry-module---user-guide}

## Strumento di Analisi dei Sistemi Socio-Ecologici MarineSABRES {#marinesabres-social-ecological-systems-analysis-tool}

**Version:** 1.0
**Ultimo Aggiornamento:** Aprile 2026

---

## Indice {#table-of-contents}

1. [Introduzione](#introduction)
2. [Per Iniziare](#getting-started)
3. [Il Framework DAPSI(W)R(M)](#the-dapsiwrm-framework)
4. [Flusso di Lavoro Passo per Passo](#step-by-step-workflow)
5. [Guida Esercizio per Esercizio](#exercise-by-exercise-guide)
6. [Lavorare con Kumu](#working-with-kumu)
7. [Gestione dei Dati](#data-management)
8. [Suggerimenti e Buone Pratiche](#tips-and-best-practices)
9. [Risoluzione dei Problemi](#troubleshooting)
10. [Glossario](#glossary)

---

## Introduzione {#introduction}

### Cos'è il Modulo ISA?

Il modulo di Inserimento Dati dell'Analisi Integrata dei Sistemi (ISA) è uno strumento completo per analizzare i sistemi socio-ecologici marini utilizzando il framework DAPSI(W)R(M). Vi guida attraverso un processo sistematico di 13 esercizi per:

- Mappare la struttura del vostro sistema socio-ecologico marino
- Identificare le relazioni causali tra attività umane e cambiamenti degli ecosistemi
- Comprendere i cicli di retroazione e le dinamiche del sistema
- Identificare i punti leva per gli interventi politici
- Creare Diagrammi di Cicli Causali (CLD) visivi
- Validare i risultati con le parti interessate

### Chi Dovrebbe Usare Questo Strumento?

- Gestori degli ecosistemi marini e decisori politici
- Scienziati e ricercatori ambientali
- Pianificatori delle zone costiere
- Professionisti della conservazione
- Gruppi di parti interessate coinvolti nella gestione marina
- Studenti di sistemi socio-ecologici marini

### Funzionalità Principali

- **Flusso di lavoro strutturato:** 13 esercizi vi guidano sistematicamente attraverso l'analisi
- **Aiuto integrato:** Aiuto contestuale per ogni esercizio
- **Esportazione dati:** Esportazione verso Excel e software di visualizzazione Kumu
- **Grafici BOT:** Visualizzare le dinamiche temporali con grafici di Comportamento nel Tempo (Behaviour Over Time)
- **Flessibile:** Importare/esportare dati, salvare i progressi, collaborare con i team

---

## Per Iniziare {#getting-started}

### Accedere al Modulo ISA

1. Avviare l'applicazione Shiny MarineSABRES
2. Dal menu laterale, selezionare **"ISA Data Entry"**
3. Apparirà l'interfaccia principale ISA con le schede degli esercizi

### Panoramica dell'Interfaccia

L'interfaccia del modulo ISA è composta da:

- **Intestazione:** Titolo e descrizione del framework con pulsante di aiuto principale
- **Schede degli Esercizi:** 13 esercizi più grafici BOT e Gestione dei Dati
- **Pulsanti di Aiuto:** Cliccate sull'icona di aiuto (?) su qualsiasi esercizio per indicazioni dettagliate
- **Moduli di Inserimento:** Moduli dinamici per l'inserimento dei dati
- **Tabelle dei Dati:** Visualizzate i dati inseriti in tabelle ordinabili e ricercabili
- **Pulsanti di Salvataggio:** Salvate il vostro lavoro dopo aver completato ogni esercizio

### Ottenere Aiuto

**Guida Principale del Framework:** Cliccate sul pulsante "ISA Framework Guide" in alto per una panoramica del DAPSI(W)R(M).

**Aiuto Specifico per Esercizio:** Cliccate sul pulsante "Help" all'interno di ogni scheda di esercizio per istruzioni dettagliate, esempi e suggerimenti.

---

## Il Framework DAPSI(W)R(M) {#the-dapsiwrm-framework}

### Panoramica

DAPSI(W)R(M) è un framework causale per analizzare i sistemi socio-ecologici marini:

- **D** - **Determinanti (Drivers):** Forze sottostanti che motivano le attività umane (economiche, sociali, tecnologiche, politiche)
- **A** - **Attività (Activities):** Usi umani degli ambienti marini e costieri
- **P** - **Pressioni (Pressures):** Fattori di stress diretti sull'ambiente marino
- **S** - **Cambiamenti di Stato (State Changes):** Cambiamenti nella condizione dell'ecosistema, rappresentati attraverso:
  - **W** - **Benessere (Welfare):** Beni e Benefici derivati dall'ecosistema
  - **ES** - **Servizi Ecosistemici (Ecosystem Services):** Benefici che gli ecosistemi forniscono alle persone
  - **MPF** - **Processi e Funzionamento Marini (Marine Processes & Functioning):** Processi biologici, chimici e fisici
- **R** - **Risposte (Responses):** Azioni della società per affrontare i problemi
- **M** - **Misure (Measures):** Interventi politici e azioni gestionali

### La Catena Causale

Il framework rappresenta una catena causale:

```
Determinanti → Attività → Pressioni → Cambiamenti di Stato (MPF → ES → Benessere) → Risposte
    ↑                                                                                     ↓
    └────────────────────────── Ciclo di Retroazione ────────────────────────────────────┘
```

### Perché DAPSI(W)R(M)?

- **Sistematico:** Garantisce una copertura completa di tutti i componenti del sistema
- **Causale:** Rende espliciti i legami tra azioni umane e cambiamenti degli ecosistemi
- **Circolare:** Cattura i cicli di retroazione tra ecosistema e società
- **Rilevante per le politiche:** Si collega direttamente ai punti di intervento (Risposte/Misure)
- **Ampiamente utilizzato:** Framework standard nella politica marina europea (MSFD, WFD)

---

## Flusso di Lavoro Passo per Passo {#step-by-step-workflow}

### Sequenza Raccomandata

Seguite gli esercizi in ordine per ottenere i migliori risultati:

**Fase 1: Definizione dell'Ambito (Exercise 0)**
- Definite i confini e il contesto del vostro caso di studio

**Fase 2: Costruzione della Catena Causale (Exercises 1-5)**
- Lavorate a ritroso dagli impatti sul benessere alle cause profonde
- Exercise 1: Beni e Benefici (cosa le persone apprezzano)
- Exercise 2a: Servizi Ecosistemici (come gli ecosistemi forniscono benefici)
- Exercise 2b: Processi Marini (funzioni ecologiche sottostanti)
- Exercise 3: Pressioni (fattori di stress sull'ecosistema)
- Exercise 4: Attività (usi umani dell'ambiente marino)
- Exercise 5: Determinanti (forze che motivano le attività)

**Fase 3: Chiudere il Ciclo (Exercise 6)**
- Collegare i determinanti ai beni e benefici per creare cicli di retroazione

**Fase 4: Visualizzazione (Exercises 7-9)**
- Creare Diagrammi di Cicli Causali in Kumu
- Esportare e perfezionare il modello visivo

**Fase 5: Analisi e Validazione (Exercises 10-12)**
- Perfezionare il modello (chiarificazione)
- Identificare i punti leva
- Validare con le parti interessate

**Continuo: Grafici BOT**
- Aggiungere dati temporali quando disponibili
- Utilizzare per validare le ipotesi causali

### Requisiti di Tempo

**Analisi rapida:** 4-8 ore (caso di studio semplificato, piccolo team)

**Analisi completa:** 2-4 giorni (caso di studio complesso, coinvolgimento delle parti interessate)

**Processo partecipativo completo:** 1-2 settimane (workshop multipli, validazione estesa)

### Lavorare in Team

**Lavoro individuale:**
- Una persona inserisce i dati sulla base di revisione della letteratura e conoscenze specialistiche

**Lavoro collaborativo:**
- Esportare/importare file Excel per condividere i dati
- Utilizzare le funzionalità collaborative di Kumu per lo sviluppo del CLD
- Condurre workshop per raccogliere contributi per gli esercizi

---

## Guida Esercizio per Esercizio {#exercise-by-exercise-guide}

### Exercise 0: Svolgere la Complessità e gli Impatti sul Benessere {#exercise-0-unfolding-complexity-and-impacts-on-welfare}

**Scopo:** Definire il contesto e i confini della vostra analisi.

**Cosa Inserire:**
- Nome del Caso di Studio
- Breve Descrizione
- Ambito Geografico (es.: "Mare Baltico", "Costa dell'Atlantico settentrionale")
- Ambito Temporale (es.: "2000-2024")
- Impatti sul Benessere (osservazioni iniziali)
- Parti Interessate Principali

**Suggerimenti:**
- Siate completi ma concisi
- Considerate prospettive diverse (ambientale, economica, sociale, culturale)
- Includete sia benefici che costi
- Elencate tutte le parti interessate coinvolte e i decisori

**Esempio:**
```
Caso: Pesca Commerciale nel Mare Baltico
Ambito Geografico: Bacino del Mare Baltico
Ambito Temporale: 2000-2024
Impatti sul Benessere: Reddito dalla cattura di pesce, occupazione, sicurezza alimentare,
                       patrimonio culturale, declino degli stock
Parti Interessate: Pescatori commerciali, comunità costiere, trasformatori,
                   consumatori, ONG, gestori della pesca, decisori politici dell'UE
```

---

### Exercise 1: Specificare Beni e Benefici (G&B) {#exercise-1-specifying-goods-and-benefits}

**Scopo:** Identificare ciò che le persone apprezzano dall'ecosistema marino.

**Cosa Inserire per Ogni Bene/Beneficio:**
- **Nome:** Nome chiaro e specifico (es.: "Cattura commerciale di merluzzo")
- **Tipo:** Approvvigionamento / Regolazione / Culturale / Supporto
- **Descrizione:** Cosa fornisce questo beneficio
- **Parte Interessata:** Chi ne beneficia?
- **Importanza:** Alta / Media / Bassa
- **Tendenza:** In aumento / Stabile / In diminuzione / Sconosciuta

**Come Usare:**
1. Cliccate su "Add Good/Benefit"
2. Compilate tutti i campi
3. Cliccate su "Save Exercise 1" per aggiornare la tabella
4. Ogni G&B riceve automaticamente un ID univoco (GB001, GB002, ecc.)

**Esempi:**

| Nome | Tipo | Parte Interessata | Importanza |
|------|------|-------------------|------------|
| Sbarchi di pesce commerciale | Approvvigionamento | Pescatori, consumatori | Alta |
| Ricreazione costiera | Culturale | Turisti, residenti | Alta |
| Protezione dalle mareggiate | Regolazione | Proprietari costieri | Alta |
| Sequestro di carbonio | Regolazione | Società globale | Media |

**Suggerimenti:**
- Siate specifici: "Pesca commerciale del merluzzo" e non solo "pesca"
- Includete benefici di mercato (vendita di pesce) e non di mercato (ricreazione)
- Considerate i benefici per diversi gruppi di parti interessate
- Pensate a sinergie e compromessi

---

### Exercise 2a: Servizi Ecosistemici (ES) che Influenzano Beni e Benefici {#exercise-2a-ecosystem-services}

**Scopo:** Identificare la capacità dell'ecosistema di generare benefici.

**Cosa Inserire per Ogni Servizio Ecosistemico:**
- **Nome:** Nome del servizio
- **Tipo:** Classificazione del servizio
- **Descrizione:** Come funziona
- **Collegato a G&B:** Selezionare dal menu a tendina (beni/benefici dall'Es. 1)
- **Meccanismo:** Come questo servizio produce il beneficio?
- **Affidabilità:** Alta / Media / Bassa

**Comprendere ES vs G&B:**
- **Servizio Ecosistemico:** Il potenziale/capacità (es.: "Produttività dello stock ittico")
- **Bene/Beneficio:** Il beneficio realizzato (es.: "Cattura commerciale di pesce")

**Come Usare:**
1. Cliccate su "Add Ecosystem Service"
2. Compilate i campi
3. Selezionate quale G&B questo ES supporta (il menu a tendina mostra tutti i G&B dall'Exercise 1)
4. Cliccate su "Save Exercise 2a"

**Esempi:**

| Nome dell'ES | Collegato a G&B | Meccanismo |
|--------------|-----------------|------------|
| Reclutamento dello stock ittico | Cattura commerciale di pesce | Successo riproduttivo → biomassa pescabile |
| Filtrazione da parte dei bivalvi | Qualità dell'acqua per il turismo | I mitili filtrano le particelle → acqua limpida |
| Habitat di fanerogame marine | Nursery per specie commerciali | Rifugio per i giovanili → stock ittico adulto |

**Suggerimenti:**
- Un G&B può essere supportato da più ES
- Un ES può supportare più G&B
- Descrivete chiaramente il meccanismo (aiuta nella validazione)
- Utilizzate conoscenze scientifiche e contributi delle parti interessate

---

### Exercise 2b: Processi e Funzionamento Marini (MPF) {#exercise-2b-marine-processes-and-functioning}

**Scopo:** Identificare i processi ecologici fondamentali che supportano i servizi ecosistemici.

**Cosa Inserire per Ogni Processo Marino:**
- **Nome:** Nome del processo
- **Tipo:** Biologico / Chimico / Fisico / Ecologico
- **Descrizione:** Cosa fa questo processo
- **Collegato a ES:** Selezionare dal menu a tendina (ES dall'Es. 2a)
- **Meccanismo:** Come questo processo genera il servizio?
- **Scala Spaziale:** Dove avviene (locale/regionale/di bacino)

**Tipi di Processi Marini:**
- **Biologici:** Produzione primaria, predazione, riproduzione, migrazione
- **Chimici:** Ciclo dei nutrienti, sequestro di carbonio, regolazione del pH
- **Fisici:** Circolazione delle acque, trasporto di sedimenti, azione delle onde
- **Ecologici:** Struttura dell'habitat, dinamiche della rete trofica, biodiversità

**Come Usare:**
1. Cliccate su "Add Marine Process"
2. Compilate i campi
3. Selezionate quale ES questo MPF supporta
4. Cliccate su "Save Exercise 2b"

**Esempi:**

| Nome del MPF | Tipo | Collegato a ES | Meccanismo |
|--------------|------|----------------|------------|
| Produzione primaria fitoplanctonica | Biologico | Produttività dello stock ittico | Luce + nutrienti → biomassa → rete trofica |
| Fotosintesi delle fanerogame marine | Biologico | Stoccaggio del carbonio | Assorbimento di CO2 → materia organica → seppellimento nei sedimenti |
| Filtrazione da parte dei banchi di mitili | Ecologico | Limpidezza dell'acqua | L'alimentazione per filtrazione rimuove le particelle |

**Suggerimenti:**
- Concentratevi sui processi rilevanti per i vostri ES
- Utilizzate competenze scientifiche specialistiche
- Considerate le scale spaziali e temporali
- Più processi possono contribuire a un ES

---

### Exercise 3: Specificare le Pressioni sui Cambiamenti di Stato {#exercise-3-specifying-pressures}

**Scopo:** Identificare i fattori di stress che influenzano i processi marini.

**Cosa Inserire per Ogni Pressione:**
- **Nome:** Nome chiaro della pressione
- **Tipo:** Fisica / Chimica / Biologica / Multipla
- **Descrizione:** Natura del fattore di stress
- **Collegato a MPF:** Selezionare dal menu a tendina (MPF dall'Es. 2b)
- **Intensità:** Alta / Media / Bassa / Sconosciuta
- **Spaziale:** Dove avviene
- **Temporale:** Quando/con quale frequenza (continua/stagionale/episodica)

**Tipi di Pressioni:**
- **Fisiche:** Abrasione del fondale, perdita di habitat, rumore, calore
- **Chimiche:** Arricchimento di nutrienti, contaminanti, acidificazione
- **Biologiche:** Rimozione di specie, specie invasive, patogeni
- **Multiple:** Effetti combinati

**Come Usare:**
1. Cliccate su "Add Pressure"
2. Compilate i campi
3. Selezionate quale MPF questa pressione influenza
4. Valutate l'intensità e descrivete i pattern spaziali/temporali
5. Cliccate su "Save Exercise 3"

**Esempi:**

| Nome della Pressione | Tipo | Collegato a MPF | Intensità |
|----------------------|------|-----------------|-----------|
| Arricchimento di nutrienti | Chimica | Composizione fitoplanctonica | Alta |
| Pesca a strascico | Fisica | Struttura dell'habitat bentonico | Alta |
| Sovrapesca | Biologica | Dinamiche della rete trofica | Media |

**Suggerimenti:**
- Una pressione può influenzare più processi
- Specificate il meccanismo diretto
- Considerate gli effetti cumulativi
- Includete pressioni croniche e acute
- Utilizzate evidenze scientifiche per le valutazioni di intensità

---

### Exercise 4: Specificare le Attività che Generano Pressioni {#exercise-4-specifying-activities}

**Scopo:** Identificare le attività umane che generano pressioni.

**Cosa Inserire per Ogni Attività:**
- **Nome:** Nome chiaro
- **Settore:** Pesca / Acquacoltura / Turismo / Navigazione / Energia / Estrazione / Altro
- **Descrizione:** Cosa comporta l'attività
- **Collegato a Pressione:** Selezionare dal menu a tendina (pressioni dall'Es. 3)
- **Scala:** Locale / Regionale / Nazionale / Internazionale
- **Frequenza:** Continua / Stagionale / Occasionale / Una tantum

**Attività Marine Comuni:**
- **Pesca:** Pesca commerciale/ricreativa/di sussistenza
- **Acquacoltura:** Allevamento di pesci/molluschi
- **Turismo:** Turismo balneare, osservazione della fauna, immersioni
- **Navigazione:** Cargo, crociere, traghetti
- **Energia:** Eolico offshore, petrolio e gas, mareomotrice/moto ondoso
- **Infrastrutture:** Porti, costruzione costiera
- **Agricoltura:** Dilavamento di nutrienti (terrestre ma con impatto marino)

**Come Usare:**
1. Cliccate su "Add Activity"
2. Compilate i campi
3. Selezionate quale/i pressione/i questa attività genera
4. Specificate scala e frequenza
5. Cliccate su "Save Exercise 4"

**Esempi:**

| Nome dell'Attività | Settore | Collegato a Pressione | Scala |
|--------------------|---------|----------------------|-------|
| Pesca a strascico di fondo | Pesca | Abrasione del fondale | Regionale |
| Scarico di acque reflue costiere | Rifiuti | Arricchimento di nutrienti | Locale |
| Traffico marittimo | Navigazione | Rumore subacqueo, inquinamento da idrocarburi | Internazionale |

**Suggerimenti:**
- Siate specifici: "Pesca a strascico di fondo" e non solo "Pesca"
- Un'attività spesso genera più pressioni
- Considerate percorsi diretti e indiretti
- Includete i pattern stagionali

---

### Exercise 5: Determinanti che Danno Origine alle Attività {#exercise-5-drivers}

**Scopo:** Identificare le forze sottostanti che motivano le attività.

**Cosa Inserire per Ogni Determinante:**
- **Nome:** Nome chiaro
- **Tipo:** Economico / Sociale / Tecnologico / Politico / Ambientale / Demografico
- **Descrizione:** Cos'è questa forza e come funziona
- **Collegato ad Attività:** Selezionare dal menu a tendina (attività dall'Es. 4)
- **Tendenza:** In aumento / Stabile / In diminuzione / Ciclica / Incerta
- **Controllabilità:** Alta / Media / Bassa / Nessuna

**Tipi di Determinanti:**
- **Economici:** Domanda di mercato, prezzi, sussidi, crescita economica
- **Sociali:** Tradizioni culturali, preferenze dei consumatori, norme sociali
- **Tecnologici:** Innovazione delle attrezzature, efficienza delle imbarcazioni, nuove tecniche
- **Politici:** Regolamentazioni, governance, accordi internazionali
- **Ambientali:** Cambiamento climatico, eventi meteorologici estremi (come determinanti di adattamento)
- **Demografici:** Crescita demografica, urbanizzazione, migrazione

**Come Usare:**
1. Cliccate su "Add Driver"
2. Compilate i campi
3. Selezionate quale/i attività questo determinante motiva
4. Valutate la tendenza e la controllabilità
5. Cliccate su "Save Exercise 5"

**Esempi:**

| Nome del Determinante | Tipo | Collegato ad Attività | Controllabilità |
|-----------------------|------|----------------------|-----------------|
| Domanda globale di prodotti ittici | Economico | Espansione della pesca commerciale | Bassa |
| Obiettivi UE per le energie rinnovabili | Politico | Sviluppo dell'eolico offshore | Alta |
| Domanda di turismo costiero | Sociale/Economico | Sviluppo costiero | Media |

**Suggerimenti:**
- Pensate al PERCHÉ le persone si impegnano nelle attività
- Considerate fattori di spinta e attrazione
- I determinanti spesso interagiscono (economici + tecnologici + politici)
- Valutate la controllabilità onestamente
- I determinanti sono spesso i migliori punti di intervento

---

### Exercise 6: Chiudere il Ciclo - Determinanti e Beni e Benefici {#exercise-6-closing-the-loop}

**Scopo:** Creare cicli di retroazione collegando i determinanti ai beni e benefici.

**Cosa Identificare:**
- Come i cambiamenti nei Beni e Benefici influenzano i Determinanti?
- Come rispondono i Determinanti alle condizioni dell'ecosistema?
- Quali retroazioni sono di rinforzo (amplificanti)?
- Quali sono di bilanciamento (stabilizzanti)?

**Tipi di Cicli di Retroazione:**

**Cicli di Rinforzo (R):** I cambiamenti si auto-amplificano
- Esempio: Declino degli stock ittici → Profitti minori → Maggiore sforzo di pesca per mantenere il reddito → Ulteriore declino

**Cicli di Bilanciamento (B):** I cambiamenti innescano risposte compensative
- Esempio: Declino della qualità dell'acqua → Riduzione del turismo → Pressione economica per il risanamento → Miglioramento della qualità

**Come Usare:**
1. Esaminate l'interfaccia delle connessioni del ciclo
2. Selezionate le connessioni determinante-G&B che creano retroazioni significative
3. Documentate se le retroazioni sono di rinforzo o di bilanciamento
4. Cliccate su "Save Exercise 6"

**Esempi:**

| Da (G&B) | A (Determinante) | Tipo | Spiegazione |
|----------|------------------|------|-------------|
| Declino della cattura di pesce | Riduzione della capacità di pesca | Bilanciamento | Bassi profitti allontanano i pescatori dal settore |
| Miglioramento della qualità dell'acqua | Sostegno politico alla conservazione | Rinforzo | Il successo genera più politiche di conservazione |
| Danni costieri da tempeste | Politica di ripristino degli ecosistemi | Bilanciamento | Le perdite innescano misure protettive |

**Suggerimenti:**
- Non tutti i determinanti devono essere ricollegati
- Considerate i ritardi temporali (anni per manifestarsi)
- La conoscenza delle parti interessate è cruciale
- Documentate il tipo di ciclo (R o B)

---

### Exercises 7-9: Creazione ed Esportazione dei Diagrammi di Cicli Causali {#exercises-7-9-cld-creation}

**Scopo:** Visualizzare la struttura del vostro sistema nel software Kumu.

#### Exercise 7: Creare CLD Basato sugli Impatti in Kumu

**Passi:**
1. Cliccate su "Download Kumu CSV Files" per esportare i vostri dati
2. Andate su [kumu.io](https://kumu.io) e create un account gratuito
3. Create un nuovo progetto (scegliete il modello "Causal Loop Diagram")
4. Importate i vostri file CSV:
   - `elements.csv` → contiene tutti i nodi
   - `connections.csv` → contiene tutte le connessioni
5. Applicate il codice di stile Kumu da `Documents/Kumu_Code_Style.txt`
6. Disponete gli elementi per mostrare flussi causali chiari

**Schema Colori Kumu:**
- Beni e Benefici: Triangoli gialli
- Servizi Ecosistemici: Quadrati blu
- Processi Marini: Capsule azzurre
- Pressioni: Rombi arancioni
- Attività: Esagoni verdi
- Determinanti: Ottagoni viola

#### Exercise 8: Dalle Catene di Logica Causale ai Cicli Causali

**Passi:**
1. In Kumu, identificate i cicli chiusi nel vostro diagramma
2. Tracciate percorsi da un elemento che tornano a se stesso
3. Classificate i cicli come di rinforzo (R) o di bilanciamento (B)
4. Aggiungete identificatori di ciclo in Kumu (usate etichette o tag)
5. Concentratevi sui cicli più importanti che determinano il comportamento del sistema

**Identificare il Tipo di Ciclo:**
- Contate il numero di collegamenti negativi (-) nel ciclo
- Numero pari di collegamenti (-) = Rinforzo (R)
- Numero dispari di collegamenti (-) = Bilanciamento (B)

#### Exercise 9: Esportare il CLD per Ulteriori Analisi

**Passi:**
1. Esportate immagini ad alta risoluzione da Kumu:
   - Cliccate Share → Export → PNG/PDF
2. Scaricate il foglio di lavoro Excel completo dal modulo ISA
3. Esaminate le matrici di adiacenza per verificare tutte le connessioni
4. Create diverse viste:
   - Vista del sistema completo
   - Viste dei sottosistemi (es.: solo pesca)
   - Viste dei cicli chiave
5. Documentate i cicli chiave con descrizioni narrative

**Cliccate su "Save Exercises 7-9" al termine.**

---

### Exercises 10-12: Chiarificazione, Metriche e Validazione {#exercises-10-12-clarifying-metrics-validation}

#### Exercise 10: Chiarificazione - Endogenizzazione e Incapsulamento

**Endogenizzazione:** Portare i fattori esterni all'interno dei confini del sistema

**Cosa Fare:**
1. Esaminate i determinanti esterni
2. Qualcuno può essere spiegato da fattori all'interno del vostro sistema?
3. Aggiungete queste retroazioni interne
4. Documentate nelle "Note di Endogenizzazione"

**Esempio:** "Domanda di mercato" potrebbe essere influenzata dalla "qualità del prodotto" all'interno del vostro sistema

**Incapsulamento:** Raggruppare processi dettagliati in concetti di livello superiore

**Cosa Fare:**
1. Identificate i sottosistemi eccessivamente complessi
2. Raggruppate elementi correlati (es.: più processi dei nutrienti → "Dinamiche di eutrofizzazione")
3. Mantenete la versione dettagliata per il lavoro tecnico
4. Create una versione semplificata per la comunicazione politica
5. Documentate nelle "Note di Incapsulamento"

#### Exercise 11: Metriche, Cause Profonde e Punti Leva

**Analisi delle Cause Profonde:**
1. Utilizzate l'interfaccia "Root Causes"
2. Identificate gli elementi con molti collegamenti in uscita
3. Tracciate a ritroso dai problemi alle cause ultime
4. Concentratevi su determinanti e attività

**Identificazione dei Punti Leva:**
1. Utilizzate l'interfaccia "Leverage Points"
2. Cercate:
   - Punti di controllo dei cicli
   - Nodi ad alta centralità (molte connessioni)
   - Punti di convergenza (più percorsi si incontrano)
3. Considerate fattibilità e controllabilità
4. Prioritizzate i punti leva attuabili

**Gerarchia di Meadows:**
- Più debole: Parametri (numeri, tassi)
- Più forte: Cicli di retroazione
- Molto forte: Progettazione/struttura del sistema
- Il più forte: Paradigmi (mentalità, obiettivi)

#### Exercise 12: Presentare e Validare i Risultati

**Approcci di Validazione:**
- ✓ Revisione interna del team
- ✓ Workshop con le parti interessate
- ✓ Revisione tra pari da parte di esperti
- ✓ Approvazione finale

**Cosa Fare:**
1. Conducete le attività di validazione
2. Registrate il feedback nelle "Note di Validazione"
3. Spuntate le caselle per i tipi di validazione completati
4. Aggiornate il vostro modello sulla base del feedback
5. Preparate presentazioni per pubblici diversi

**Suggerimenti per la Presentazione:**
- Adattate la complessità al pubblico
- Utilizzate il CLD visivo per la panoramica
- Raccontate storie sui cicli chiave
- Mostrate i grafici BOT come evidenza
- Collegate alle raccomandazioni politiche
- Siate trasparenti sulle incertezze

**Cliccate su "Save Exercises 10-12" al termine.**

---

### Grafici BOT: Comportamento nel Tempo {#bot-graphs-behaviour-over-time}

**Scopo:** Visualizzare le dinamiche temporali per validare il vostro modello causale.

**Come Creare Grafici BOT:**

1. **Selezionare il Tipo di Elemento:** Scegliete dal menu a tendina (Beni e Benefici / ES / MPF / Pressioni / Attività / Determinanti)
2. **Selezionare l'Elemento Specifico:** Scegliete quale elemento rappresentare graficamente
3. **Aggiungere Punti Dati:**
   - Anno
   - Valore
   - Unità (es.: "tonnellate", "%", "indice")
   - Cliccate su "Add Data Point"
4. **Visualizzare il Grafico:** La serie temporale appare automaticamente
5. **Ripetere** per altri elementi

**Pattern da Cercare:**
- **Tendenze:** Aumento/diminuzione costante
- **Cicli:** Oscillazioni regolari
- **Gradini:** Cambiamenti improvvisi (cambiamenti politici)
- **Ritardi:** Sfasamenti temporali
- **Soglie:** Punti di svolta
- **Plateau:** Stabilità

**Utilizzare i Grafici BOT:**
- Confrontare i pattern con le previsioni del CLD
- Identificare evidenze dei cicli di retroazione
- Misurare i ritardi temporali
- Valutare gli interventi politici
- Proiettare scenari futuri

**Fonti dei Dati:**
- Statistiche ufficiali
- Monitoraggio ambientale
- Indagini scientifiche
- Osservazioni delle parti interessate
- Registri storici

**Cliccate su "Save BOT Data" per preservare il vostro lavoro.**

---

## Lavorare con Kumu {#working-with-kumu}

### Iniziare con Kumu

**1. Creare un Account:**
- Andate su [kumu.io](https://kumu.io)
- Registratevi per un account gratuito
- I progetti pubblici sono gratuiti; i progetti privati richiedono un abbonamento

**2. Creare un Nuovo Progetto:**
- Cliccate su "New Project"
- Scegliete il modello "Causal Loop Diagram"
- Date un nome al vostro progetto

**3. Importare i Dati:**
- Dal modulo ISA, scaricate i file CSV per Kumu
- In Kumu, cliccate su Import
- Caricate `elements.csv` e `connections.csv`

### Applicare la Personalizzazione dello Stile

**Copiare il Codice Kumu:**
- Aprite `Documents/Kumu_Code_Style.txt`
- Copiate tutto il contenuto

**Applicare alla Vostra Mappa:**
1. In Kumu, cliccate sull'icona Impostazioni
2. Andate su "Advanced Editor"
3. Incollate il codice
4. Cliccate su "Save"

**Risultato:** I vostri elementi saranno codificati per colore e forma per tipo:
- Beni e Benefici: Triangoli gialli
- Servizi Ecosistemici: Quadrati blu
- Processi Marini: Capsule azzurre
- Pressioni: Rombi arancioni
- Attività: Esagoni verdi
- Determinanti: Ottagoni viola

### Lavorare con il Diagramma

**Opzioni di Layout:**
- Layout automatico: Lasciate che Kumu disponga gli elementi
- Manuale: Trascinate gli elementi nelle posizioni preferite
- Circolare: Enfatizzate la struttura dei cicli
- Gerarchico: Mostrate il flusso causale dai determinanti al benessere

**Aggiungere Informazioni:**
- Cliccate su qualsiasi elemento per modificare le proprietà
- Aggiungete descrizioni, tag, campi personalizzati
- Includete fonti dei dati, livelli di affidabilità

**Evidenziare i Cicli:**
1. Identificate un percorso di ciclo chiuso
2. Aggiungete un tag "Loop" a tutti gli elementi del ciclo
3. Utilizzate il filtro di Kumu per mostrare/nascondere i cicli
4. Etichettate i cicli (es.: "R1: Spirale della Sovrapesca", "B1: Recupero della Qualità")

**Filtri e Viste:**
- Filtrare per tipo di elemento (mostrare solo i Determinanti)
- Filtrare per importanza, affidabilità, ecc.
- Creare viste multiple (sistema completo, cicli chiave, sottosistemi)
- Salvare le viste per le presentazioni

### Collaborazione

**Condivisione:**
- Condividere un link di sola visualizzazione con le parti interessate
- Esportare screenshot per i rapporti
- Incorporare in siti web/presentazioni

**Modifica in Team:**
- Aggiungere collaboratori (funzionalità a pagamento)
- Più persone possono modificare simultaneamente
- Controllo delle versioni disponibile

### Opzioni di Esportazione

**Da Kumu:**
- **PNG:** Immagine ad alta risoluzione per rapporti
- **PDF:** Formato vettoriale per pubblicazioni
- **JSON:** Dati grezzi per l'archiviazione
- **Link di condivisione:** Vista web interattiva

**Dal Modulo ISA:**
- **Foglio di lavoro Excel:** Dati completi con tutti i fogli
- **CSV per Kumu:** Elementi e connessioni
- **Matrici di adiacenza:** Matrici di connessione per l'analisi

---

## Gestione dei Dati {#data-management}

### Salvare il Vostro Lavoro

**Salvataggio automatico:**
- I dati sono memorizzati nello stato reattivo dell'applicazione durante la sessione
- Utilizzate i pulsanti "Save" dopo aver completato ogni esercizio

**Esportare in Excel:**
1. Andate alla scheda "Data Management"
2. Inserite il nome del file (es.: "MioCaso_ISA_2024")
3. Cliccate su "Export to Excel"
4. Scarica il foglio di lavoro completo con tutti i dati

### Importare Dati Esistenti

**Da Excel:**
1. Andate alla scheda "Data Management"
2. Cliccate su "Choose Excel File"
3. Selezionate il vostro file .xlsx precedentemente esportato
4. Cliccate su "Import Data"
5. I dati popolano tutti gli esercizi

**Struttura del File Excel:**
- Foglio: Case_Info
- Foglio: Goods_Benefits
- Foglio: Ecosystem_Services
- Foglio: Marine_Processes
- Foglio: Pressures
- Foglio: Activities
- Foglio: Drivers
- Foglio: BOT_Data

### Reimpostare i Dati

**Attenzione:** Questo cancella TUTTI i dati e non può essere annullato.

1. Andate alla scheda "Data Management"
2. Cliccate su "Reset All Data" (pulsante rosso)
3. Confermate l'azione
4. Tutti gli esercizi tornano allo stato vuoto

**Quando Reimpostare:**
- Iniziare un caso di studio completamente nuovo
- Scartare un'esercitazione di prova
- Dopo aver esportato i dati che volete conservare

### Flussi di Lavoro Collaborativi

**Lavoro Individuale:**
- Una persona inserisce tutti i dati
- Esporta in Excel al termine
- Condivide il file con il team per la revisione

**Lavoro Sequenziale:**
- Persona A: Exercises 0-3 → Esporta
- Persona B: Importa → Exercises 4-6 → Esporta
- Persona C: Importa → Exercises 7-12 → Esportazione finale

**Lavoro Parallelo:**
- Più persone lavorano su esercizi diversi in sessioni separate
- Consolidare in Excel (unire manualmente i fogli)
- Importare il file consolidato

**Basato su Workshop:**
- Facilitare discussioni di gruppo per ogni esercizio
- Una persona opera lo strumento e inserisce i dati di consenso
- Esportare dopo ogni esercizio per la documentazione

---

## Suggerimenti e Buone Pratiche {#tips-and-best-practices}

### Suggerimenti Generali sul Flusso di Lavoro

**1. Lavorate sistematicamente:**
- Completate gli esercizi in ordine
- Non saltate avanti (gli esercizi successivi si basano su quelli precedenti)
- Salvate dopo ogni esercizio

**2. Coinvolgete le parti interessate:**
- Conducete workshop per gli Exercises 1-6
- Validate il CLD con chi conosce il sistema
- Utilizzate prospettive diverse (utenti, gestori, scienziati)

**3. Utilizzate evidenze scientifiche:**
- Basate i collegamenti su studi sottoposti a revisione tra pari
- Citate le fonti nelle descrizioni
- Annotate i livelli di affidabilità

**4. Iniziate semplici, aggiungete dettagli:**
- Primo passaggio: Solo elementi principali
- Secondo passaggio: Aggiungete sfumature e dettagli
- Mantenete una versione semplificata per la comunicazione

**5. Documentate tutto:**
- Utilizzate generosamente i campi descrittivi
- Registrate le fonti dei dati
- Annotate ipotesi e incertezze

### Suggerimenti sulla Qualità dei Dati

**Siate Specifici:**
- ❌ "Pesca" → ✅ "Pesca commerciale a strascico di fondo per specie demersali"
- ❌ "Inquinamento" → ✅ "Arricchimento di nutrienti da dilavamento agricolo"

**Siate Completi:**
- Includete impatti positivi e negativi
- Considerate tutti i gruppi di parti interessate
- Coprite tutti i settori che utilizzano l'area marina

**Siate Realistici:**
- Concentratevi sugli elementi importanti (80% principali)
- Non cercate di includere tutto
- La complessità deve corrispondere alle conoscenze disponibili

**Siate Coerenti:**
- Utilizzate una terminologia coerente
- Mantenete un livello coerente di dettaglio tra gli esercizi
- Seguite le convenzioni di denominazione (es.: ID degli elementi)

### Suggerimenti per lo Sviluppo del CLD

**Layout:**
- Disponete secondo il flusso causale: Determinanti → Attività → Pressioni → Stato → Benessere
- Mettete in evidenza i cicli di retroazione
- Minimizzate gli incroci delle connessioni per la leggibilità

**Cicli:**
- Identificate ed etichettate i cicli chiave (R1, R2, B1, B2)
- Concentratevi sui cicli che determinano comportamenti problematici
- Documentate le narrative dei cicli (quale storia racconta ogni ciclo?)

**Validazione:**
- Il CLD spiega il comportamento osservato del sistema?
- Le parti interessate riconoscono la struttura?
- Potete tracciare eventi storici specifici attraverso il diagramma?

### Suggerimenti sui Grafici BOT

**Raccolta Dati:**
- Utilizzate le serie temporali più lunghe disponibili
- Siate coerenti con unità e scale
- Documentate chiaramente le fonti dei dati

**Confronto:**
- Rappresentate variabili correlate sullo stesso asse temporale
- Cercate correlazioni (corrispondono al vostro CLD?)
- Identificate i ritardi temporali tra causa ed effetto

**Comunicazione:**
- Annotate con eventi chiave (cambiamenti politici, disastri)
- Utilizzate schemi di colore coerenti
- Includete barre di errore o intervalli di incertezza se disponibili

### Errori Comuni da Evitare

**1. Troppo dettaglio troppo presto:**
- Iniziate con gli elementi principali
- Aggiungete dettagli nelle iterazioni
- Mantenete una versione semplificata

**2. Ignorare il contributo delle parti interessate:**
- La conoscenza locale è inestimabile
- La legittimità richiede partecipazione
- I punti ciechi emergono senza prospettive diverse

**3. Confondere ES e G&B:**
- ES = capacità/potenziale dell'ecosistema
- G&B = benefici realizzati che le persone ottengono
- Esempio: "Stock ittico" (ES) vs. "Cattura di pesce" (G&B)

**4. Collegamenti deboli:**
- Specificate sempre il meccanismo
- Evitate connessioni vaghe
- Test: Potete spiegare questo collegamento a una parte interessata?

**5. Ignorare il tempo:**
- I ritardi sono cruciali
- Alcuni effetti richiedono anni per manifestarsi
- I grafici BOT rivelano pattern temporali

**6. Nessun ciclo di retroazione:**
- L'Exercise 6 è fondamentale
- I sistemi sono circolari, non lineari
- Le retroazioni determinano le dinamiche

**7. Saltare la validazione:**
- Il vostro modello è un'ipotesi
- Testatelo contro dati e conoscenze delle parti interessate
- Iterate sulla base del feedback

---

## Risoluzione dei Problemi {#troubleshooting}

### Problemi Comuni e Soluzioni

**Problema: "I miei dati non sono stati salvati"**
- **Soluzione:** Cliccate sempre il pulsante "Save Exercise X" dopo aver inserito i dati
- Verificate che la tabella dati si aggiorni dopo il salvataggio
- Esportate in Excel frequentemente come backup

**Problema: "I menu a tendina sono vuoti"**
- **Causa:** Non avete completato l'esercizio precedente
- **Soluzione:** Completate gli esercizi in ordine. L'Es. 2a necessita dei dati dell'Es. 1, ecc.

**Problema: "Ho commesso un errore in un esercizio precedente"**
- **Soluzione:** Tornate alla scheda di quell'esercizio
- I dati sono ancora lì e modificabili
- Apportate le correzioni e cliccate di nuovo su Save

**Problema: "L'esportazione in Excel non funziona"**
- **Verificate:** Le impostazioni di download del browser
- **Verificate:** I permessi dei file nella cartella di download
- **Provate:** Un browser diverso

**Problema: "L'importazione in Kumu fallisce"**
- **Verificate:** Il formato del file CSV (deve essere separato da virgole)
- **Verificate:** Le intestazioni delle colonne corrispondano alle aspettative di Kumu
- **Provate:** Importare prima gli elementi, poi le connessioni

**Problema: "L'applicazione è lenta con grandi set di dati"**
- **Normale:** 100+ elementi possono rallentare il rendering
- **Soluzione:** Lavorate su sottosistemi separatamente
- **Soluzione:** Utilizzate Excel per la gestione dei dati, l'applicazione per la struttura

**Problema: "Non trovo il contenuto di aiuto"**
- **Posizione:** Cliccate il pulsante di Aiuto "?" su ogni scheda di esercizio
- **Guida principale:** Cliccate su "ISA Framework Guide" in cima al modulo

### Ottenere Aiuto Aggiuntivo

**Documentazione:**
- Questa Guida Utente
- MarineSABRES Simple SES DRAFT Guidance (cartella Documenti)
- Documentazione Kumu: [docs.kumu.io](https://docs.kumu.io)

**Supporto Tecnico:**
- Verificate la versione dell'applicazione e la compatibilità del browser
- Contattate il team del progetto MarineSABRES
- Segnalate bug via GitHub (se applicabile)

**Supporto Scientifico:**
- Consultate il documento di orientamento per domande metodologiche
- Coinvolgete esperti del settore per il vostro caso di studio specifico
- Partecipate ai workshop di formazione ISA

---

## Glossario {#glossary}

**Attività (A):** Usi umani degli ambienti marini e costieri (pesca, navigazione, turismo, ecc.)

**Matrice di Adiacenza (Adjacency Matrix):** Tabella che mostra quali elementi sono collegati a quali altri elementi

**Ciclo di Bilanciamento (B):** Ciclo di retroazione che contrasta il cambiamento e stabilizza il sistema

**Grafico BOT (Behaviour Over Time):** Grafico di serie temporale che mostra come un indicatore cambia nel tempo

**Catena Causale (Causal Chain):** Sequenza lineare di relazioni causa-effetto (es.: Determinanti → Attività → Pressioni)

**Diagramma di Cicli Causali (CLD):** Rete visiva che mostra gli elementi e le loro relazioni causali, inclusi i cicli di retroazione

**DAPSI(W)R(M):** Framework Determinanti-Attività-Pressioni-Stato(Benessere)-Risposte(Misure)

**Determinanti (D):** Forze sottostanti che motivano le attività (economiche, sociali, politiche, tecnologiche)

**Servizi Ecosistemici (ES):** La capacità degli ecosistemi di generare benefici per le persone

**Incapsulamento (Encapsulation):** Raggruppamento di elementi dettagliati in concetti di livello superiore per la semplificazione

**Endogenizzazione (Endogenisation):** Portare fattori esterni all'interno dei confini del sistema aggiungendo retroazioni interne

**Ciclo di Retroazione (Feedback Loop):** Percorso causale circolare dove un elemento influenza se stesso attraverso una catena di altri elementi

**Beni e Benefici (G&B):** Benefici realizzati che le persone ottengono dagli ecosistemi marini (impatti sul benessere)

**ISA (Analisi Integrata dei Sistemi):** Framework sistematico per analizzare i sistemi socio-ecologici

**Kumu:** Software gratuito online di visualizzazione di reti (kumu.io)

**Punto Leva (Leverage Point):** Posizione nel sistema dove un piccolo intervento può produrre un grande cambiamento

**Processi e Funzionamento Marini (MPF):** Processi biologici, chimici, fisici ed ecologici che supportano i servizi ecosistemici

**Misure (M):** Interventi politici e azioni gestionali (risposte)

**Polarità (Polarity):** Direzione dell'influenza causale (+ stessa direzione, - direzione opposta)

**Pressioni (P):** Fattori di stress diretti sull'ambiente marino (inquinamento, distruzione dell'habitat, rimozione di specie)

**Ciclo di Rinforzo (R):** Ciclo di retroazione che amplifica il cambiamento (può essere ciclo virtuoso o vizioso)

**Risposte (R):** Azioni della società per affrontare i problemi

**Causa Profonda (Root Cause):** Determinante o attività fondamentale all'origine di una catena causale

**Sistema Socio-Ecologico (SES):** Sistema integrato di persone e natura, con retroazioni reciproche

**Cambiamenti di Stato (S):** Cambiamenti nella condizione dell'ecosistema (rappresentati attraverso W, ES e MPF)

**Benessere (W):** Benessere umano, rappresentato attraverso beni e benefici dagli ecosistemi

---

## Appendice: Scheda di Riferimento Rapido {#appendix-quick-reference-card}

### Lista di Controllo degli Esercizi

- [ ] Exercise 0: Definire l'ambito del caso di studio
- [ ] Exercise 1: Elencare tutti i Beni e Benefici
- [ ] Exercise 2a: Identificare i Servizi Ecosistemici
- [ ] Exercise 2b: Identificare Processi e Funzionamento Marini
- [ ] Exercise 3: Identificare le Pressioni
- [ ] Exercise 4: Identificare le Attività
- [ ] Exercise 5: Identificare i Determinanti
- [ ] Exercise 6: Chiudere i cicli di retroazione
- [ ] Exercise 7: Creare CLD in Kumu
- [ ] Exercise 8: Identificare i cicli causali
- [ ] Exercise 9: Esportare e documentare il CLD
- [ ] Exercise 10: Chiarire il modello (endogenizzazione, incapsulamento)
- [ ] Exercise 11: Identificare i punti leva
- [ ] Exercise 12: Validare con le parti interessate
- [ ] Grafici BOT: Aggiungere dati temporali
- [ ] Esportare il foglio di lavoro Excel finale

### Scorciatoie da Tastiera

- **Tab:** Spostarsi tra i campi del modulo
- **Invio:** Inviare/Salvare modulo
- **Ctrl+F / Cmd+F:** Cercare nelle tabelle

### Posizione dei File

- **Guida Utente:** `Documents/ISA_User_Guide.md`
- **Documento di Orientamento:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Stile Kumu:** `Documents/Kumu_Code_Style.txt`
- **Modello Excel:** `Documents/ISA Excel Workbook.xlsx`

### Link Utili

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Documentazione Kumu:** [https://docs.kumu.io](https://docs.kumu.io)
- **Framework DAPSI(W)R:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Informazioni sul Documento {#document-information}

**Documento:** Modulo di Inserimento Dati ISA - Guida Utente
**Progetto:** Cassetta degli Attrezzi per Sistemi Socio-Ecologici MarineSABRES
**Version:** 1.0
**Data:** Aprile 2026
**Stato:** Bozza (traduzione automatica)

**Citazione:**
> Progetto MarineSABRES (2025). Modulo di Inserimento Dati ISA - Guida Utente.
> Strumento di Analisi dei Sistemi Socio-Ecologici MarineSABRES, Versione 1.0.

**Licenza:** Questa guida è fornita per l'uso con la Cassetta degli Attrezzi SES MarineSABRES.

---

**Per domande, feedback o supporto, contattate il team del progetto MarineSABRES.**

**Buona analisi!**
