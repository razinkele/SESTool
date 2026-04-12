<div class="alert alert-info" role="alert">
<strong>Merk:</strong> Denne veiledningen ble maskinoversatt fra engelsk ved hjelp av Claude AI.
Hvis du oppdager feil, vennligst rapporter dem til MarineSABRES-prosjektteamet.
<em>Oversettelsesstatus: Utkast (maskinoversatt, venter på gjennomgang)</em>
</div>

# ISA-dataregistreringsmodul - Brukerveiledning {#isa-data-entry-module---user-guide}

## MarineSABRES verktøy for analyse av sosial-økologiske systemer {#marinesabres-social-ecological-systems-analysis-tool}

**Version:** 1.0
**Sist oppdatert:** April 2026

---

## Innholdsfortegnelse {#table-of-contents}

1. [Innledning](#introduction)
2. [Komme i gang](#getting-started)
3. [DAPSI(W)R(M)-rammeverket](#the-dapsiwrm-framework)
4. [Trinnvis arbeidsflyt](#step-by-step-workflow)
5. [Øvelse-for-øvelse-veiledning](#exercise-by-exercise-guide)
6. [Arbeide med Kumu](#working-with-kumu)
7. [Datahåndtering](#data-management)
8. [Tips og god praksis](#tips-and-best-practices)
9. [Feilsøking](#troubleshooting)
10. [Ordliste](#glossary)

---

## Innledning {#introduction}

### Hva er ISA-modulen?

ISA-dataregistreringsmodulen (Integrated Systems Analysis) er et omfattende verktøy for å analysere marine sosial-økologiske systemer ved bruk av DAPSI(W)R(M)-rammeverket. Den veileder deg gjennom en systematisk prosess med 13 øvelser for å:

- Kartlegge strukturen i ditt marine sosial-økologiske system
- Identifisere årsakssammenhenger mellom menneskelige aktiviteter og endringer i økosystemet
- Forstå tilbakekoblingssløyfer og systemdynamikk
- Identifisere påvirkningspunkter for politiske intervensjoner
- Lage visuelle kausale sløyfediagrammer (CLD)
- Validere funn med interessenter

### Hvem bør bruke dette verktøyet?

- Forvaltere av marine økosystemer og beslutningstakere
- Miljøforskere og forskere
- Kystsoneplanleggere
- Naturvernpraktikere
- Interessentgrupper involvert i marin forvaltning
- Studenter som studerer marine sosial-økologiske systemer

### Nøkkelfunksjoner

- **Strukturert arbeidsflyt:** 13 øvelser veileder deg systematisk gjennom analysen
- **Innebygd hjelp:** Kontekstsensitiv hjelp for hver øvelse
- **Dataeksport:** Eksport til Excel og Kumu-visualiseringsprogramvare
- **BOT-grafer:** Visualiser temporale dynamikker med Behaviour Over Time-grafer
- **Fleksibelt:** Importer/eksporter data, lagre fremgang, samarbeide med team

---

## Komme i gang {#getting-started}

### Tilgang til ISA-modulen

1. Start MarineSABRES Shiny-applikasjonen
2. Fra sidemenyen, velg **"ISA Data Entry"**
3. Du vil se ISA-hovedgrensesnittet med øvelsesfaner

### Oversikt over grensesnittet

ISA-modulens grensesnitt består av:

- **Topptekst:** Tittel og rammeverkssbeskrivelse med hovedhjelpeknapp
- **Øvelsesfaner:** 13 øvelser pluss BOT-grafer og Datahåndtering
- **Hjelpeknapper:** Klikk på hjelpeikonet (?) på enhver øvelse for detaljert veiledning
- **Inndataskjemaer:** Dynamiske skjemaer for dataregistrering
- **Datatabeller:** Se dine registrerte data i sorterbare, søkbare tabeller
- **Lagreknapper:** Lagre arbeidet ditt etter å ha fullført hver øvelse

### Få hjelp

**Hovedveiledning for rammeverket:** Klikk på "ISA Framework Guide"-knappen øverst for en oversikt over DAPSI(W)R(M).

**Øvelsesspesifikk hjelp:** Klikk på "Help"-knappen i hver øvelsesfane for detaljerte instruksjoner, eksempler og tips.

---

## DAPSI(W)R(M)-rammeverket {#the-dapsiwrm-framework}

### Oversikt

DAPSI(W)R(M) er et kausalt rammeverk for å analysere marine sosial-økologiske systemer:

- **D** - **Drivkrefter (Drivers):** Underliggende krefter som motiverer menneskelige aktiviteter (økonomiske, sosiale, teknologiske, politiske)
- **A** - **Aktiviteter (Activities):** Menneskelig bruk av marine og kystnære miljøer
- **P** - **Press (Pressures):** Direkte stressfaktorer på det marine miljøet
- **S** - **Tilstandsendringer (State Changes):** Endringer i økosystemets tilstand, representert gjennom:
  - **W** - **Velferd (Welfare):** Goder og fordeler avledet fra økosystemet
  - **ES** - **Økosystemtjenester (Ecosystem Services):** Fordeler økosystemer gir til mennesker
  - **MPF** - **Marine prosesser og funksjoner (Marine Processes & Functioning):** Biologiske, kjemiske og fysiske prosesser
- **R** - **Responser (Responses):** Samfunnsmessige tiltak for å løse problemer
- **M** - **Tiltak (Measures):** Politiske intervensjoner og forvaltningstiltak

### Årsakskjeden

Rammeverket representerer en årsakskjede:

```
Drivkrefter → Aktiviteter → Press → Tilstandsendringer (MPF → ES → Velferd) → Responser
    ↑                                                                              ↓
    └──────────────────────── Tilbakekoblingssløyfe ─────────────────────────────┘
```

### Hvorfor DAPSI(W)R(M)?

- **Systematisk:** Sikrer omfattende dekning av alle systemkomponenter
- **Kausal:** Gjør eksplisitte koblinger mellom menneskelige handlinger og økosystemendringer
- **Sirkulær:** Fanger tilbakekoblingssløyfer mellom økosystem og samfunn
- **Politikkrelevant:** Kobler direkte til intervensjonspunkter (Responser/Tiltak)
- **Bredt brukt:** Standardrammeverk i europeisk marinpolitikk (MSFD, WFD)

---

## Trinnvis arbeidsflyt {#step-by-step-workflow}

### Anbefalt rekkefølge

Følg øvelsene i rekkefølge for best resultat:

**Fase 1: Avgrensning (Exercise 0)**
- Definer grensene og konteksten for din case-studie

**Fase 2: Bygge årsakskjeden (Exercises 1-5)**
- Arbeid bakover fra velferdseffekter til grunnleggende årsaker
- Exercise 1: Goder og fordeler (hva mennesker verdsetter)
- Exercise 2a: Økosystemtjenester (hvordan økosystemer gir fordeler)
- Exercise 2b: Marine prosesser (underliggende økologiske funksjoner)
- Exercise 3: Press (stressfaktorer på økosystemet)
- Exercise 4: Aktiviteter (menneskelig bruk av det marine miljøet)
- Exercise 5: Drivkrefter (krefter som motiverer aktiviteter)

**Fase 3: Lukke sløyfen (Exercise 6)**
- Koble drivkrefter tilbake til goder og fordeler for å skape tilbakekoblingssløyfer

**Fase 4: Visualisering (Exercises 7-9)**
- Lage kausale sløyfediagrammer i Kumu
- Eksportere og forbedre den visuelle modellen

**Fase 5: Analyse og validering (Exercises 10-12)**
- Forbedre modellen (avklaring)
- Identifisere påvirkningspunkter
- Validere med interessenter

**Løpende: BOT-grafer**
- Legge til tidsseriedata når tilgjengelig
- Bruke for å validere kausale hypoteser

### Tidsbehov

**Rask analyse:** 4-8 timer (forenklet case-studie, lite team)

**Omfattende analyse:** 2-4 dager (kompleks case-studie, interessentinvolvering)

**Full deltakende prosess:** 1-2 uker (flere workshops, omfattende validering)

### Arbeide i team

**Individuelt arbeid:**
- Én person registrerer data basert på litteraturgjennomgang og ekspertkunnskap

**Samarbeid:**
- Eksporter/importer Excel-filer for å dele data
- Bruk Kumus samarbeidsfunksjoner for CLD-utvikling
- Gjennomfør workshops for å samle innspill til øvelsene

---

## Øvelse-for-øvelse-veiledning {#exercise-by-exercise-guide}

### Exercise 0: Utfolde kompleksitet og velferdseffekter {#exercise-0-unfolding-complexity-and-impacts-on-welfare}

**Formål:** Definere konteksten og grensene for analysen din.

**Hva du skal registrere:**
- Navn på case-studien
- Kort beskrivelse
- Geografisk omfang (f.eks. "Østersjøen", "Nordatlantisk kyst")
- Tidsmessig omfang (f.eks. "2000-2024")
- Velferdseffekter (innledende observasjoner)
- Nøkkelinteressenter

**Tips:**
- Vær omfattende men kortfattet
- Vurder ulike perspektiver (miljømessige, økonomiske, sosiale, kulturelle)
- Inkluder både fordeler og kostnader
- List opp alle berørte interessenter og beslutningstakere

**Eksempel:**
```
Case: Kommersielt fiske i Østersjøen
Geografisk omfang: Østersjøbassenget
Tidsmessig omfang: 2000-2024
Velferdseffekter: Inntekt fra fiskefangst, sysselsetting, matsikkerhet,
                  kulturarv, fallende bestander
Interessenter: Yrkesfiskere, kystsamfunn, foredlingsindustri,
               forbrukere, frivillige organisasjoner, fiskeriforvaltere, EUs beslutningstakere
```

---

### Exercise 1: Spesifisere goder og fordeler (G&B) {#exercise-1-specifying-goods-and-benefits}

**Formål:** Identifisere hva mennesker verdsetter fra det marine økosystemet.

**Hva du skal registrere for hvert gode/fordel:**
- **Navn:** Tydelig, spesifikt navn (f.eks. "Kommersiell torskefangst")
- **Type:** Forsynende / Regulerende / Kulturell / Støttende
- **Beskrivelse:** Hva denne fordelen gir
- **Interessent:** Hvem drar nytte?
- **Viktighet:** Høy / Middels / Lav
- **Trend:** Økende / Stabil / Avtagende / Ukjent

**Slik bruker du det:**
1. Klikk "Add Good/Benefit"
2. Fyll ut alle felt
3. Klikk "Save Exercise 1" for å oppdatere tabellen
4. Hvert G&B får automatisk en unik ID (GB001, GB002, osv.)

**Eksempler:**

| Navn | Type | Interessent | Viktighet |
|------|------|-------------|-----------|
| Kommersielle fiskelandinger | Forsynende | Fiskere, forbrukere | Høy |
| Kystfriluftsliv | Kulturell | Turister, innbyggere | Høy |
| Stormflodsbeskyttelse | Regulerende | Eiere av kysteiendommer | Høy |
| Karbonbinding | Regulerende | Globalt samfunn | Middels |

**Tips:**
- Vær spesifikk: "Kommersielt torskefiske" ikke bare "fiske"
- Inkluder både markedsbaserte (fiskesalg) og ikke-markedsbaserte (friluftsliv) fordeler
- Vurder fordeler for ulike interessentgrupper
- Tenk på synergier og avveininger

---

### Exercise 2a: Økosystemtjenester (ES) som påvirker goder og fordeler {#exercise-2a-ecosystem-services}

**Formål:** Identifisere økosystemets kapasitet til å generere fordeler.

**Hva du skal registrere for hver økosystemtjeneste:**
- **Navn:** Navn på tjenesten
- **Type:** Tjenesteklassifisering
- **Beskrivelse:** Hvordan den fungerer
- **Koblet til G&B:** Velg fra nedtrekksmenyen (goder/fordeler fra Øv. 1)
- **Mekanisme:** Hvordan produserer denne tjenesten fordelen?
- **Pålitelighet:** Høy / Middels / Lav

**Forstå ES vs G&B:**
- **Økosystemtjeneste:** Potensialet/kapasiteten (f.eks. "Fiskebestandens produktivitet")
- **Gode/Fordel:** Den realiserte fordelen (f.eks. "Kommersiell fiskefangst")

**Slik bruker du det:**
1. Klikk "Add Ecosystem Service"
2. Fyll ut feltene
3. Velg hvilken G&B denne ES støtter (nedtrekksmenyen viser alle G&B fra Exercise 1)
4. Klikk "Save Exercise 2a"

**Eksempler:**

| ES-navn | Koblet til G&B | Mekanisme |
|---------|----------------|-----------|
| Rekruttering av fiskebestand | Kommersiell fiskefangst | Gyteuksess → fiskbar biomasse |
| Filtrering av skjell | Vannkvalitet for turisme | Blåskjell filtrerer partikler → klart vann |
| Ålegrashabitat | Oppvekstområde for kommersielle arter | Skjul for yngel → voksen fiskebestand |

**Tips:**
- Én G&B kan støttes av flere ES
- Én ES kan støtte flere G&B
- Beskriv mekanismen tydelig (hjelper ved validering)
- Bruk vitenskapelig kunnskap og innspill fra interessenter

---

### Exercise 2b: Marine prosesser og funksjoner (MPF) {#exercise-2b-marine-processes-and-functioning}

**Formål:** Identifisere de fundamentale økologiske prosessene som støtter økosystemtjenester.

**Hva du skal registrere for hver marin prosess:**
- **Navn:** Navn på prosessen
- **Type:** Biologisk / Kjemisk / Fysisk / Økologisk
- **Beskrivelse:** Hva denne prosessen gjør
- **Koblet til ES:** Velg fra nedtrekksmenyen (ES fra Øv. 2a)
- **Mekanisme:** Hvordan genererer denne prosessen tjenesten?
- **Romlig skala:** Hvor den forekommer (lokal/regional/bassengnivå)

**Typer marine prosesser:**
- **Biologiske:** Primærproduksjon, predasjon, reproduksjon, migrasjon
- **Kjemiske:** Næringsstoffkretsløp, karbonbinding, pH-regulering
- **Fysiske:** Vannsirkulasjon, sedimenttransport, bølgevirkning
- **Økologiske:** Habitatstruktur, næringsnetodynamikk, biodiversitet

**Slik bruker du det:**
1. Klikk "Add Marine Process"
2. Fyll ut feltene
3. Velg hvilken ES denne MPF støtter
4. Klikk "Save Exercise 2b"

**Eksempler:**

| MPF-navn | Type | Koblet til ES | Mekanisme |
|----------|------|---------------|-----------|
| Fytoplankton primærproduksjon | Biologisk | Fiskebestandens produktivitet | Lys + næringsstoffer → biomasse → næringsnett |
| Ålegrasfotosyntese | Biologisk | Karbonlagring | CO2-opptak → organisk materiale → begravelse i sediment |
| Blåskjellbankfiltrering | Økologisk | Vannklarhet | Filtreringsernæring fjerner partikler |

**Tips:**
- Fokuser på prosesser som er relevante for dine ES
- Bruk vitenskapelig ekspertise
- Vurder romlige og tidsmessige skalaer
- Flere prosesser kan bidra til én ES

---

### Exercise 3: Spesifisere press på tilstandsendringer {#exercise-3-specifying-pressures}

**Formål:** Identifisere stressfaktorer som påvirker marine prosesser.

**Hva du skal registrere for hvert press:**
- **Navn:** Tydelig navn på presset
- **Type:** Fysisk / Kjemisk / Biologisk / Multippel
- **Beskrivelse:** Stressfaktorens natur
- **Koblet til MPF:** Velg fra nedtrekksmenyen (MPF fra Øv. 2b)
- **Intensitet:** Høy / Middels / Lav / Ukjent
- **Romlig:** Hvor det forekommer
- **Tidsmessig:** Når/hvor ofte (kontinuerlig/sesongbasert/episodisk)

**Typer press:**
- **Fysisk:** Bunnslitasje, habitattap, støy, varme
- **Kjemisk:** Næringsberikelse, forurensninger, forsuring
- **Biologisk:** Artsuttak, invasive arter, patogener
- **Multippel:** Kombinerte effekter

**Slik bruker du det:**
1. Klikk "Add Pressure"
2. Fyll ut feltene
3. Velg hvilken MPF dette presset påvirker
4. Vurder intensiteten og beskriv romlige/tidsmessige mønstre
5. Klikk "Save Exercise 3"

**Eksempler:**

| Pressnavn | Type | Koblet til MPF | Intensitet |
|-----------|------|----------------|------------|
| Næringsberikelse | Kjemisk | Fytoplanktonsammensetning | Høy |
| Bunntråling | Fysisk | Bentisk habitatstruktur | Høy |
| Overfiske | Biologisk | Næringsnetodynamikk | Middels |

**Tips:**
- Ett press kan påvirke flere prosesser
- Spesifiser den direkte mekanismen
- Vurder kumulative effekter
- Inkluder både kronisk og akutt press
- Bruk vitenskapelig evidens for intensitetsvurderinger

---

### Exercise 4: Spesifisere aktiviteter som genererer press {#exercise-4-specifying-activities}

**Formål:** Identifisere menneskelige aktiviteter som genererer press.

**Hva du skal registrere for hver aktivitet:**
- **Navn:** Tydelig navn
- **Sektor:** Fiskeri / Akvakultur / Turisme / Skipsfart / Energi / Gruvedrift / Annet
- **Beskrivelse:** Hva aktiviteten innebærer
- **Koblet til press:** Velg fra nedtrekksmenyen (press fra Øv. 3)
- **Skala:** Lokal / Regional / Nasjonal / Internasjonal
- **Frekvens:** Kontinuerlig / Sesongbasert / Sporadisk / Engangs

**Vanlige marine aktiviteter:**
- **Fiskeri:** Kommersielt/fritids-/levebrødsfiske
- **Akvakultur:** Fiske-/skjelloppdrett
- **Turisme:** Strandturisme, dyreobservasjon, dykking
- **Skipsfart:** Frakt, cruise, ferger
- **Energi:** Havvind, olje og gass, tidevann/bølge
- **Infrastruktur:** Havner, kystbygging
- **Landbruk:** Næringsavrenning (landbasert men med marin påvirkning)

**Slik bruker du det:**
1. Klikk "Add Activity"
2. Fyll ut feltene
3. Velg hvilke(t) press denne aktiviteten genererer
4. Spesifiser skala og frekvens
5. Klikk "Save Exercise 4"

**Eksempler:**

| Aktivitetsnavn | Sektor | Koblet til press | Skala |
|----------------|--------|------------------|-------|
| Bunntrålsfiske | Fiskeri | Bunnslitasje | Regional |
| Kystutslipp av avløpsvann | Avfall | Næringsberikelse | Lokal |
| Skipstrafikk | Skipsfart | Undervannsstøy, oljeforurensning | Internasjonal |

**Tips:**
- Vær spesifikk: "Bunntråling" ikke bare "Fiske"
- Én aktivitet genererer ofte flere press
- Vurder både direkte og indirekte veier
- Inkluder sesongmønstre

---

### Exercise 5: Drivkrefter som gir opphav til aktiviteter {#exercise-5-drivers}

**Formål:** Identifisere underliggende krefter som motiverer aktiviteter.

**Hva du skal registrere for hver drivkraft:**
- **Navn:** Tydelig navn
- **Type:** Økonomisk / Sosial / Teknologisk / Politisk / Miljømessig / Demografisk
- **Beskrivelse:** Hva denne kraften er og hvordan den virker
- **Koblet til aktivitet:** Velg fra nedtrekksmenyen (aktiviteter fra Øv. 4)
- **Trend:** Økende / Stabil / Avtagende / Syklisk / Usikker
- **Kontrollerbarhet:** Høy / Middels / Lav / Ingen

**Typer drivkrefter:**
- **Økonomiske:** Markedsetterspørsel, priser, subsidier, økonomisk vekst
- **Sosiale:** Kulturelle tradisjoner, forbrukerpreferanser, sosiale normer
- **Teknologiske:** Redskapsinnovasjon, fartøyeffektivitet, nye teknikker
- **Politiske:** Reguleringer, styring, internasjonale avtaler
- **Miljømessige:** Klimaendringer, ekstremvær (som tilpasningsdrivkrefter)
- **Demografiske:** Befolkningsvekst, urbanisering, migrasjon

**Slik bruker du det:**
1. Klikk "Add Driver"
2. Fyll ut feltene
3. Velg hvilke(n) aktivitet(er) denne drivkraften motiverer
4. Vurder trend og kontrollerbarhet
5. Klikk "Save Exercise 5"

**Eksempler:**

| Drivkraftnavn | Type | Koblet til aktivitet | Kontrollerbarhet |
|---------------|------|----------------------|------------------|
| Global etterspørsel etter sjømat | Økonomisk | Utvidelse av kommersielt fiske | Lav |
| EUs mål for fornybar energi | Politisk | Havvindutvikling | Høy |
| Etterspørsel etter kystturisme | Sosial/Økonomisk | Kystutvikling | Middels |

**Tips:**
- Tenk over HVORFOR folk driver med aktivitetene
- Vurder både push- og pull-faktorer
- Drivkrefter samvirker ofte (økonomiske + teknologiske + politiske)
- Vurder kontrollerbarheten ærlig
- Drivkrefter er ofte de beste intervensjonspunktene

---

### Exercise 6: Lukke sløyfen - Drivkrefter til goder og fordeler {#exercise-6-closing-the-loop}

**Formål:** Skape tilbakekoblingssløyfer ved å koble drivkrefter tilbake til goder og fordeler.

**Hva skal identifiseres:**
- Hvordan påvirker endringer i Goder og Fordeler Drivkreftene?
- Hvordan responderer Drivkreftene på økosystemtilstanden?
- Hvilke tilbakekoblinger er forsterkende (amplifying)?
- Hvilke er balanserende (stabiliserende)?

**Typer tilbakekoblingssløyfer:**

**Forsterkende sløyfer (R):** Endringer forsterker seg selv
- Eksempel: Fallende fiskebestander → Lavere profitt → Mer fiskeinnsats for å opprettholde inntekt → Ytterligere nedgang

**Balanserende sløyfer (B):** Endringer utløser motvirkenderesponser
- Eksempel: Fallende vannkvalitet → Redusert turisme → Økonomisk press for opprydding → Forbedret kvalitet

**Slik bruker du det:**
1. Gjennomgå grensesnittet for sløyfekoblinger
2. Velg drivkraft-til-G&B-koblinger som skaper meningsfulle tilbakekoblinger
3. Dokumenter om tilbakekoblingene er forsterkende eller balanserende
4. Klikk "Save Exercise 6"

**Eksempler:**

| Fra (G&B) | Til (Drivkraft) | Type | Forklaring |
|-----------|-----------------|------|------------|
| Fallende fiskefangst | Redusert fiskekapasitet | Balanserende | Lav profitt driver fiskere ut av bransjen |
| Forbedret vannkvalitet | Politisk støtte til vern | Forsterkende | Suksess genererer mer vernepolitikk |
| Stormskader på kysten | Politikk for økosystemrestaurering | Balanserende | Tap utløser beskyttelsestiltak |

**Tips:**
- Ikke alle drivkrefter trenger å kobles tilbake
- Vurder tidsforsinkelser (år før de manifesteres)
- Interessentenes kunnskap er avgjørende
- Dokumenter sløyfetype (R eller B)

---

### Exercises 7-9: Oppretting og eksport av kausale sløyfediagrammer {#exercises-7-9-cld-creation}

**Formål:** Visualisere systemstrukturen i Kumu-programvaren.

#### Exercise 7: Lage effektbasert CLD i Kumu

**Trinn:**
1. Klikk "Download Kumu CSV Files" for å eksportere dataene dine
2. Gå til [kumu.io](https://kumu.io) og opprett en gratis konto
3. Opprett et nytt prosjekt (velg malen "Causal Loop Diagram")
4. Importer CSV-filene dine:
   - `elements.csv` → inneholder alle noder
   - `connections.csv` → inneholder alle kanter
5. Bruk Kumu-stilkoden fra `Documents/Kumu_Code_Style.txt`
6. Arranger elementene for å vise tydelige årsaksflyter

**Kumu-fargeskjema:**
- Goder og fordeler: Gule trekanter
- Økosystemtjenester: Blå firkanter
- Marine prosesser: Lyseblå kapsler
- Press: Oransje diamanter
- Aktiviteter: Grønne sekskanter
- Drivkrefter: Lilla åttekanter

#### Exercise 8: Fra kausale logikkkjeder til kausale sløyfer

**Trinn:**
1. I Kumu, identifiser lukkede sløyfer i diagrammet ditt
2. Spor stier fra et element tilbake til seg selv
3. Klassifiser sløyfer som forsterkende (R) eller balanserende (B)
4. Legg til sløyfeidentifikatorer i Kumu (bruk etiketter eller tagger)
5. Fokuser på de viktigste sløyfene som driver systematferden

**Identifisere sløyfetype:**
- Tell antall negative (-) koblinger i sløyfen
- Partall negative (-) koblinger = Forsterkende (R)
- Oddetall negative (-) koblinger = Balanserende (B)

#### Exercise 9: Eksportere CLD for videre analyse

**Trinn:**
1. Eksporter høyoppløselige bilder fra Kumu:
   - Klikk Share → Export → PNG/PDF
2. Last ned komplett Excel-arbeidsbok fra ISA-modulen
3. Gjennomgå nabomatriser for å verifisere alle koblinger
4. Lag ulike visninger:
   - Full systemvisning
   - Delsystemvisninger (f.eks. bare fiskeri)
   - Nøkkelsløyfevisninger
5. Dokumenter nøkkelsløyfer med narrative beskrivelser

**Klikk "Save Exercises 7-9" når du er ferdig.**

---

### Exercises 10-12: Avklaring, metrikker og validering {#exercises-10-12-clarifying-metrics-validation}

#### Exercise 10: Avklaring - Endogenisering og innkapsling

**Endogenisering:** Bringe eksterne faktorer inn i systemgrensen

**Hva du skal gjøre:**
1. Gjennomgå eksterne drivkrefter
2. Kan noen forklares av faktorer innenfor systemet ditt?
3. Legg til disse interne tilbakekoblingene
4. Dokumenter i "Endogeniseringsnotater"

**Eksempel:** "Markedsetterspørsel" kan påvirkes av "produktkvalitet" innenfor systemet ditt

**Innkapsling:** Gruppere detaljerte prosesser i overordnede konsepter

**Hva du skal gjøre:**
1. Identifiser overmåte komplekse delsystemer
2. Grupper relaterte elementer (f.eks. flere næringsstoffprosesser → "Eutrofieringsdynamikk")
3. Behold den detaljerte versjonen for teknisk arbeid
4. Lag en forenklet versjon for politisk kommunikasjon
5. Dokumenter i "Innkapslingsnotater"

#### Exercise 11: Metrikker, grunnårsaker og påvirkningspunkter

**Grunnårsaksanalyse:**
1. Bruk grensesnittet "Root Causes"
2. Identifiser elementer med mange utgående koblinger
3. Spor bakover fra problemer til ultimate årsaker
4. Fokuser på drivkrefter og aktiviteter

**Identifisering av påvirkningspunkter:**
1. Bruk grensesnittet "Leverage Points"
2. Se etter:
   - Sløyfekontrollpunkter
   - Noder med høy sentralitet (mange koblinger)
   - Konvergenspunkter (flere stier møtes)
3. Vurder gjennomførbarhet og kontrollerbarhet
4. Prioriter handlingsbare påvirkningspunkter

**Meadows' hierarki:**
- Svakest: Parametere (tall, rater)
- Sterkere: Tilbakekoblingssløyfer
- Veldig sterkt: Systemdesign/-struktur
- Sterkest: Paradigmer (tankesett, mål)

#### Exercise 12: Presentere og validere resultater

**Valideringstilnærminger:**
- ✓ Intern teamgjennomgang
- ✓ Interessentworkshop
- ✓ Ekspertfagfellevurdering
- ✓ Endelig godkjenning

**Hva du skal gjøre:**
1. Gjennomfør valideringsaktiviteter
2. Registrer tilbakemeldinger i "Valideringsnotater"
3. Kryss av for fullførte valideringstyper
4. Oppdater modellen basert på tilbakemeldinger
5. Forbered presentasjoner for ulike målgrupper

**Presentasjonstips:**
- Tilpass kompleksiteten til publikum
- Bruk det visuelle CLD for oversikt
- Fortell historier om nøkkelsløyfer
- Vis BOT-grafer som evidens
- Koble til politikkanbefalinger
- Vær transparent om usikkerheter

**Klikk "Save Exercises 10-12" når du er ferdig.**

---

### BOT-grafer: Behaviour Over Time {#bot-graphs-behaviour-over-time}

**Formål:** Visualisere temporale dynamikker for å validere din kausale modell.

**Hvordan lage BOT-grafer:**

1. **Velg elementtype:** Velg fra nedtrekksmenyen (Goder og fordeler / ES / MPF / Press / Aktiviteter / Drivkrefter)
2. **Velg spesifikt element:** Velg hvilket element som skal graferes
3. **Legg til datapunkter:**
   - År
   - Verdi
   - Enhet (f.eks. "tonn", "%", "indeks")
   - Klikk "Add Data Point"
4. **Se grafen:** Tidsserien vises automatisk
5. **Gjenta** for andre elementer

**Mønstre å se etter:**
- **Trender:** Jevn økning/nedgang
- **Sykler:** Regelmessige svingninger
- **Trinn:** Plutselige endringer (politikkskifter)
- **Forsinkelser:** Tidsforsinkelser
- **Terskelverdier:** Vippepunkter
- **Platåer:** Stabilitet

**Bruke BOT-grafer:**
- Sammenligne mønstre med CLD-prediksjoner
- Identifisere evidens for tilbakekoblingssløyfer
- Måle tidsforsinkelser
- Evaluere politiske intervensjoner
- Projisere fremtidige scenarier

**Datakilder:**
- Offisiell statistikk
- Miljøovervåking
- Vitenskapelige undersøkelser
- Interessentobservasjoner
- Historiske registre

**Klikk "Save BOT Data" for å bevare arbeidet ditt.**

---

## Arbeide med Kumu {#working-with-kumu}

### Komme i gang med Kumu

**1. Opprette konto:**
- Gå til [kumu.io](https://kumu.io)
- Registrer deg for en gratis konto
- Offentlige prosjekter er gratis; private prosjekter krever abonnement

**2. Opprette nytt prosjekt:**
- Klikk "New Project"
- Velg malen "Causal Loop Diagram"
- Gi prosjektet ditt et navn

**3. Importere data:**
- Fra ISA-modulen, last ned Kumu CSV-filer
- I Kumu, klikk Import
- Last opp `elements.csv` og `connections.csv`

### Bruke egendefinert stilkode

**Kopiere Kumu-koden:**
- Åpne `Documents/Kumu_Code_Style.txt`
- Kopier alt innhold

**Bruke på kartet ditt:**
1. I Kumu, klikk på Innstillinger-ikonet
2. Gå til "Advanced Editor"
3. Lim inn koden
4. Klikk "Save"

**Resultat:** Elementene dine vil bli fargekodet og formet etter type:
- Goder og fordeler: Gule trekanter
- Økosystemtjenester: Blå firkanter
- Marine prosesser: Lyseblå kapsler
- Press: Oransje diamanter
- Aktiviteter: Grønne sekskanter
- Drivkrefter: Lilla åttekanter

### Arbeide med diagrammet

**Layoutalternativer:**
- Automatisk layout: La Kumu arrangere elementene
- Manuell: Dra elementer til foretrukne posisjoner
- Sirkulær: Fremhev sløyfestruktur
- Hierarkisk: Vis årsaksflyt fra drivkrefter til velferd

**Legge til informasjon:**
- Klikk på et element for å redigere egenskaper
- Legg til beskrivelser, tagger, egendefinerte felt
- Inkluder datakilder, pålitelighetsnivåer

**Fremheve sløyfer:**
1. Identifiser en lukket sløyfesti
2. Legg til en "Loop"-tagg på alle elementer i sløyfen
3. Bruk Kumus filter for å vise/skjule sløyfer
4. Merk sløyfer (f.eks. "R1: Overfiskespiral", "B1: Kvalitetsgjenoppretting")

**Filtre og visninger:**
- Filtrer etter elementtype (vis bare Drivkrefter)
- Filtrer etter viktighet, pålitelighet, osv.
- Lag flere visninger (fullt system, nøkkelsløyfer, delsystemer)
- Lagre visninger for presentasjoner

### Samarbeid

**Deling:**
- Del visningslenke med interessenter
- Eksporter skjermbilder til rapporter
- Bygg inn i nettsider/presentasjoner

**Teamredigering:**
- Legg til samarbeidspartnere (betalt funksjon)
- Flere personer kan redigere samtidig
- Versjonskontroll tilgjengelig

### Eksportalternativer

**Fra Kumu:**
- **PNG:** Høyoppløselig bilde for rapporter
- **PDF:** Vektorformat for publikasjoner
- **JSON:** Rådata for arkivering
- **Delingslenke:** Interaktiv nettvisning

**Fra ISA-modulen:**
- **Excel-arbeidsbok:** Komplett data med alle ark
- **Kumu CSV:** Elementer og koblinger
- **Nabomatriser:** Koblingsmatriser for analyse

---

## Datahåndtering {#data-management}

### Lagre arbeidet ditt

**Autolagring:**
- Data lagres i appens reaktive tilstand under økten din
- Bruk "Save"-knappene etter å ha fullført hver øvelse

**Eksportere til Excel:**
1. Gå til fanen "Data Management"
2. Skriv inn filnavn (f.eks. "MinCase_ISA_2024")
3. Klikk "Export to Excel"
4. Laster ned komplett arbeidsbok med alle data

### Importere eksisterende data

**Fra Excel:**
1. Gå til fanen "Data Management"
2. Klikk "Choose Excel File"
3. Velg din tidligere eksporterte .xlsx-fil
4. Klikk "Import Data"
5. Dataene fyller alle øvelser

**Excel-filstruktur:**
- Ark: Case_Info
- Ark: Goods_Benefits
- Ark: Ecosystem_Services
- Ark: Marine_Processes
- Ark: Pressures
- Ark: Activities
- Ark: Drivers
- Ark: BOT_Data

### Tilbakestille data

**Advarsel:** Dette sletter ALLE data og kan ikke angres.

1. Gå til fanen "Data Management"
2. Klikk "Reset All Data" (rød knapp)
3. Bekreft handlingen
4. Alle øvelser går tilbake til blank tilstand

**Når du bør tilbakestille:**
- Starte en helt ny case-studie
- Forkaste en øvelseskjøring
- Etter å ha eksportert data du vil beholde

### Samarbeidsflyter

**Individuelt arbeid:**
- Én person registrerer alle data
- Eksporterer Excel når ferdig
- Deler filen med teamet for gjennomgang

**Sekvensielt arbeid:**
- Person A: Exercises 0-3 → Eksporter
- Person B: Importer → Exercises 4-6 → Eksporter
- Person C: Importer → Exercises 7-12 → Slutteksport

**Parallelt arbeid:**
- Flere personer jobber med ulike øvelser i separate økter
- Konsolider i Excel (manuelt slå sammen ark)
- Importer konsolidert fil

**Workshopbasert:**
- Fasiliter gruppediskusjoner for hver øvelse
- Én person bruker verktøyet og registrerer konsensusdata
- Eksporter etter hver øvelse for dokumentasjon

---

## Tips og god praksis {#tips-and-best-practices}

### Generelle arbeidsflytstips

**1. Arbeid systematisk:**
- Fullfør øvelsene i rekkefølge
- Ikke hopp fremover (senere øvelser bygger på tidligere)
- Lagre etter hver øvelse

**2. Engasjer interessenter:**
- Gjennomfør workshops for Exercises 1-6
- Valider CLD med de som kjenner systemet
- Bruk mangfoldige perspektiver (brukere, forvaltere, forskere)

**3. Bruk vitenskapelig evidens:**
- Baser koblinger på fagfellevurderte studier
- Referer til kilder i beskrivelsene
- Merk pålitelighetsnivåer

**4. Start enkelt, legg til detaljer:**
- Første gjennomgang: Bare hovedelementer
- Andre gjennomgang: Legg til nyanser og detaljer
- Behold en forenklet versjon for kommunikasjon

**5. Dokumenter alt:**
- Bruk beskrivelsesfeltene raust
- Registrer datakilder
- Merk antakelser og usikkerheter

### Tips for datakvalitet

**Vær spesifikk:**
- ❌ "Fiske" → ✅ "Kommersielt bunntrålsfiske etter demersale arter"
- ❌ "Forurensning" → ✅ "Næringsberikelse fra landbruksavrenning"

**Vær omfattende:**
- Inkluder positive og negative effekter
- Vurder alle interessentgrupper
- Dekk alle sektorer som bruker det marine området

**Vær realistisk:**
- Fokuser på viktige elementer (topp 80 %)
- Ikke prøv å inkludere alt
- Kompleksiteten bør samsvare med tilgjengelig kunnskap

**Vær konsekvent:**
- Bruk konsekvent terminologi
- Oppretthold konsekvent detaljnivå på tvers av øvelser
- Følg navnekonvensjoner (f.eks. element-IDer)

### Tips for CLD-utvikling

**Layout:**
- Arranger i årsaksflyt: Drivkrefter → Aktiviteter → Press → Tilstand → Velferd
- Plasser tilbakekoblingssløyfer fremtredende
- Minimer kantkrysninger for lesbarhet

**Sløyfer:**
- Identifiser og merk nøkkelsløyfer (R1, R2, B1, B2)
- Fokuser på sløyfer som driver problematisk atferd
- Dokumenter sløyfefortellinger (hvilken historie forteller hver sløyfe?)

**Validering:**
- Forklarer CLD den observerte systematferden?
- Gjenkjenner interessentene strukturen?
- Kan du spore spesifikke historiske hendelser gjennom diagrammet?

### Tips for BOT-grafer

**Datainnsamling:**
- Bruk lengst tilgjengelige tidsserier
- Vær konsekvent med enheter og skalaer
- Dokumenter datakilder tydelig

**Sammenligning:**
- Plott relaterte variabler på samme tidsakse
- Se etter korrelasjoner (stemmer de med CLD?)
- Identifiser tidsforsinkelser mellom årsak og virkning

**Kommunikasjon:**
- Merk med nøkkelhendelser (politikkendringer, katastrofer)
- Bruk konsekvente fargeskjemaer
- Inkluder feilmarginer eller usikkerhetsintervaller hvis tilgjengelig

### Vanlige fallgruver å unngå

**1. For mye detalj for tidlig:**
- Start med hovedelementene
- Legg til detaljer i iterasjoner
- Behold en forenklet versjon

**2. Hoppe over interessentinnspill:**
- Lokal kunnskap er uvurderlig
- Legitimitet krever deltakelse
- Blinde flekker oppstår uten mangfoldige perspektiver

**3. Forveksle ES og G&B:**
- ES = økosystemets kapasitet/potensial
- G&B = realiserte fordeler mennesker oppnår
- Eksempel: "Fiskebestand" (ES) vs. "Fiskefangst" (G&B)

**4. Svake koblinger:**
- Spesifiser alltid mekanismen
- Unngå vage forbindelser
- Test: Kan du forklare denne koblingen til en interessent?

**5. Ignorere tid:**
- Forsinkelser er avgjørende
- Noen effekter tar år å manifestere seg
- BOT-grafer avslører temporale mønstre

**6. Ingen tilbakekoblingssløyfer:**
- Exercise 6 er kritisk
- Systemer er sirkulære, ikke lineære
- Tilbakekoblinger driver dynamikken

**7. Hoppe over validering:**
- Modellen din er en hypotese
- Test mot data og interessentkunnskap
- Iterer basert på tilbakemeldinger

---

## Feilsøking {#troubleshooting}

### Vanlige problemer og løsninger

**Problem: "Dataene mine ble ikke lagret"**
- **Løsning:** Klikk alltid "Save Exercise X"-knappen etter at du har registrert data
- Sjekk at datatabellen oppdateres etter lagring
- Eksporter til Excel jevnlig som sikkerhetskopi

**Problem: "Nedtrekksmenyene er tomme"**
- **Årsak:** Du har ikke fullført den forrige øvelsen
- **Løsning:** Fullfør øvelsene i rekkefølge. Øv. 2a trenger data fra Øv. 1, osv.

**Problem: "Jeg gjorde en feil i en tidligere øvelse"**
- **Løsning:** Gå tilbake til den øvelsesfanen
- Dataene er fortsatt der og kan redigeres
- Gjør rettelsene og klikk Save igjen

**Problem: "Excel-eksporten fungerer ikke"**
- **Sjekk:** Nettleserens nedlastingsinnstillinger
- **Sjekk:** Filtillatelser i nedlastingsmappen
- **Prøv:** En annen nettleser

**Problem: "Kumu-importen feiler"**
- **Sjekk:** CSV-filformatet (må være kommaseparert)
- **Sjekk:** Kolonneoverskriftene samsvarer med Kumus forventninger
- **Prøv:** Importer elementer først, deretter koblinger

**Problem: "Appen er treg med store datasett"**
- **Normalt:** 100+ elementer kan gjøre gjengivelsen treg
- **Løsning:** Arbeid med delsystemer separat
- **Løsning:** Bruk Excel for datahåndtering, appen for struktur

**Problem: "Jeg finner ikke hjelpeinnholdet"**
- **Plassering:** Klikk Hjelp "?"-knappen på hver øvelsesfane
- **Hovedveiledning:** Klikk "ISA Framework Guide" øverst i modulen

### Få ytterligere hjelp

**Dokumentasjon:**
- Denne brukerveiledningen
- MarineSABRES Simple SES DRAFT Guidance (Dokumenter-mappen)
- Kumu-dokumentasjon: [docs.kumu.io](https://docs.kumu.io)

**Teknisk støtte:**
- Sjekk appversjonen og nettleserkompatibilitet
- Kontakt MarineSABRES-prosjektteamet
- Rapporter feil via GitHub (hvis aktuelt)

**Vitenskapelig støtte:**
- Se veiledningsdokumentet for metodiske spørsmål
- Engasjer fageksperter for din spesifikke case-studie
- Delta på ISA-opplæringsworkshops

---

## Ordliste {#glossary}

**Aktiviteter (A):** Menneskelig bruk av marine og kystnære miljøer (fiske, skipsfart, turisme, osv.)

**Nabomatrise (Adjacency Matrix):** Tabell som viser hvilke elementer som er koblet til hvilke andre elementer

**Balanserende sløyfe (B):** Tilbakekoblingssløyfe som motvirker endring og stabiliserer systemet

**BOT-graf (Behaviour Over Time):** Tidsseriediagram som viser hvordan en indikator endrer seg over tid

**Årsakskjede (Causal Chain):** Lineær sekvens av årsak-virkningsforhold (f.eks. Drivkrefter → Aktiviteter → Press)

**Kausalt sløyfediagram (CLD):** Visuelt nettverk som viser elementer og deres årsaksforhold, inkludert tilbakekoblingssløyfer

**DAPSI(W)R(M):** Rammeverk for Drivkrefter-Aktiviteter-Press-Tilstand(Velferd)-Responser(Tiltak)

**Drivkrefter (D):** Underliggende krefter som motiverer aktiviteter (økonomiske, sosiale, politiske, teknologiske)

**Økosystemtjenester (ES):** Økosystemenes kapasitet til å generere fordeler for mennesker

**Innkapsling (Encapsulation):** Gruppering av detaljerte elementer i overordnede konsepter for forenkling

**Endogenisering (Endogenisation):** Bringe eksterne faktorer inn i systemgrensen ved å legge til interne tilbakekoblinger

**Tilbakekoblingssløyfe (Feedback Loop):** Sirkulær årsakssti der et element påvirker seg selv gjennom en kjede av andre elementer

**Goder og fordeler (G&B):** Realiserte fordeler som mennesker oppnår fra marine økosystemer (velferdseffekter)

**ISA (Integrert systemanalyse):** Systematisk rammeverk for å analysere sosial-økologiske systemer

**Kumu:** Gratis nettbasert programvare for nettverksvisualisering (kumu.io)

**Påvirkningspunkt (Leverage Point):** Sted i systemet der en liten intervensjon kan produsere stor endring

**Marine prosesser og funksjoner (MPF):** Biologiske, kjemiske, fysiske og økologiske prosesser som støtter økosystemtjenester

**Tiltak (M):** Politiske intervensjoner og forvaltningstiltak (responser)

**Polaritet (Polarity):** Retning for kausal påvirkning (+ samme retning, - motsatt retning)

**Press (P):** Direkte stressfaktorer på det marine miljøet (forurensning, habitatødeleggelse, artsuttak)

**Forsterkende sløyfe (R):** Tilbakekoblingssløyfe som forsterker endring (kan være god eller ond sirkel)

**Responser (R):** Samfunnsmessige tiltak for å løse problemer

**Grunnårsak (Root Cause):** Fundamental drivkraft eller aktivitet ved opprinnelsen av en årsakskjede

**Sosial-økologisk system (SES):** Integrert system av mennesker og natur, med gjensidige tilbakekoblinger

**Tilstandsendringer (S):** Endringer i økosystemets tilstand (representert gjennom W, ES og MPF)

**Velferd (W):** Menneskelig velvære, representert gjennom goder og fordeler fra økosystemer

---

## Tillegg: Hurtigreferansekort {#appendix-quick-reference-card}

### Øvelsessjekkliste

- [ ] Exercise 0: Definere omfanget av case-studien
- [ ] Exercise 1: Liste alle Goder og Fordeler
- [ ] Exercise 2a: Identifisere Økosystemtjenester
- [ ] Exercise 2b: Identifisere Marine Prosesser og Funksjoner
- [ ] Exercise 3: Identifisere Press
- [ ] Exercise 4: Identifisere Aktiviteter
- [ ] Exercise 5: Identifisere Drivkrefter
- [ ] Exercise 6: Lukke tilbakekoblingssløyfer
- [ ] Exercise 7: Lage CLD i Kumu
- [ ] Exercise 8: Identifisere kausale sløyfer
- [ ] Exercise 9: Eksportere og dokumentere CLD
- [ ] Exercise 10: Avklare modell (endogenisering, innkapsling)
- [ ] Exercise 11: Identifisere påvirkningspunkter
- [ ] Exercise 12: Validere med interessenter
- [ ] BOT-grafer: Legge til tidsseriedata
- [ ] Eksportere endelig Excel-arbeidsbok

### Hurtigtaster

- **Tab:** Flytte mellom skjemafelt
- **Enter:** Send/Lagre skjema
- **Ctrl+F / Cmd+F:** Søke i tabeller

### Filplasseringer

- **Brukerveiledning:** `Documents/ISA_User_Guide.md`
- **Veiledningsdokument:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Kumu-stil:** `Documents/Kumu_Code_Style.txt`
- **Excel-mal:** `Documents/ISA Excel Workbook.xlsx`

### Nyttige lenker

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Kumu-dokumentasjon:** [https://docs.kumu.io](https://docs.kumu.io)
- **DAPSI(W)R-rammeverket:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Dokumentinformasjon {#document-information}

**Dokument:** ISA-dataregistreringsmodul - Brukerveiledning
**Prosjekt:** MarineSABRES verktøykasse for sosial-økologiske systemer
**Version:** 1.0
**Dato:** April 2026
**Status:** Utkast (maskinoversatt)

**Sitering:**
> MarineSABRES-prosjektet (2025). ISA-dataregistreringsmodul - Brukerveiledning.
> MarineSABRES verktøy for analyse av sosial-økologiske systemer, versjon 1.0.

**Lisens:** Denne veiledningen er levert for bruk med MarineSABRES SES-verktøykassen.

---

**For spørsmål, tilbakemeldinger eller støtte, vennligst kontakt MarineSABRES-prosjektteamet.**

**Lykke til med analysen!**
