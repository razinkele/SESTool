<div class="alert alert-info" role="alert">
<strong>Pastaba:</strong> Šis vadovas buvo automatiškai išverstas iš anglų kalbos naudojant Claude AI.
Jei pastebėjote klaidų, praneškite apie jas MarineSABRES projekto komandai.
<em>Vertimo būsena: Juodraštis (automatinis vertimas, laukiama peržiūros)</em>
</div>

# ISA Duomenų Įvedimo Modulis - Naudotojo Vadovas {#isa-data-entry-module---user-guide}

## MarineSABRES Socialinių-Ekologinių Sistemų Analizės Įrankis {#marinesabres-social-ecological-systems-analysis-tool}

**Version:** 1.0
**Paskutinis atnaujinimas:** 2026 m. balandis

---

## Turinys {#table-of-contents}

1. [Įvadas](#introduction)
2. [Darbo pradžia](#getting-started)
3. [DAPSI(W)R(M) sistema](#the-dapsiwrm-framework)
4. [Žingsnis po žingsnio darbo eiga](#step-by-step-workflow)
5. [Pratimų vadovas](#exercise-by-exercise-guide)
6. [Darbas su Kumu](#working-with-kumu)
7. [Duomenų valdymas](#data-management)
8. [Patarimai ir geroji praktika](#tips-and-best-practices)
9. [Trikčių šalinimas](#troubleshooting)
10. [Žodynas](#glossary)

---

## Įvadas {#introduction}

### Kas yra ISA modulis?

Integruotos sistemų analizės (ISA) duomenų įvedimo modulis yra išsamus įrankis jūrinių socialinių-ekologinių sistemų analizei, naudojant DAPSI(W)R(M) sistemą. Jis veda jus per sisteminį 13 pratimų procesą, kad galėtumėte:

- Kartografuoti savo jūrinės socialinės-ekologinės sistemos struktūrą
- Nustatyti priežastinius ryšius tarp žmogaus veiklos ir ekosistemos pokyčių
- Suprasti grįžtamojo ryšio kilpas ir sistemos dinamiką
- Nustatyti svertų taškus politikos intervencijoms
- Sukurti vizualinius Priežastinių Kilpų Diagramas (CLD)
- Patvirtinti išvadas su suinteresuotosiomis šalimis

### Kam skirtas šis įrankis?

- Jūrinių ekosistemų valdytojams ir politikos formuotojams
- Aplinkos mokslininkams ir tyrėjams
- Pakrančių zonų planuotojams
- Gamtos apsaugos specialistams
- Suinteresuotųjų šalių grupėms, dalyvaujančioms jūrų valdyme
- Studentams, studijuojantiems jūrines socialines-ekologines sistemas

### Pagrindinės savybės

- **Struktūruota darbo eiga:** 13 pratimų sistemingai veda per analizę
- **Integruota pagalba:** Kontekstinė pagalba kiekvienam pratimui
- **Duomenų eksportas:** Eksportas į Excel ir Kumu vizualizacijos programinę įrangą
- **BOT grafikai:** Vizualizuokite laikines dinamikas su Elgsenos Laike grafikais
- **Lankstus:** Importuokite/eksportuokite duomenis, išsaugokite eigą, bendradarbiaukite komandose

---

## Darbo pradžia {#getting-started}

### Prieiga prie ISA modulio

1. Paleiskite MarineSABRES Shiny programą
2. Šoniniame meniu pasirinkite **„ISA Duomenų Įvedimas"**
3. Pamatysite pagrindinę ISA sąsają su pratimų kortelėmis

### Sąsajos apžvalga

ISA modulio sąsają sudaro:

- **Antraštė:** Pavadinimas ir sistemos aprašymas su pagrindiniu pagalbos mygtuku
- **Pratimų kortelės:** 13 pratimų, BOT grafikai ir Duomenų Valdymas
- **Pagalbos mygtukai:** Spustelėkite pagalbos piktogramą (?) bet kuriame pratime, kad gautumėte išsamius nurodymus
- **Įvedimo formos:** Dinaminės formos duomenų įvedimui
- **Duomenų lentelės:** Peržiūrėkite savo įvestus duomenis rūšiuojamose, ieškomose lentelėse
- **Išsaugojimo mygtukai:** Išsaugokite savo darbą užbaigę kiekvieną pratimą

### Pagalbos gavimas

**Pagrindinis sistemos vadovas:** Spustelėkite mygtuką „ISA Sistemos Vadovas" viršuje, kad gautumėte DAPSI(W)R(M) apžvalgą.

**Pratimui specifinė pagalba:** Spustelėkite mygtuką „Pagalba" kiekvienos pratimo kortelės viduje, kad gautumėte išsamias instrukcijas, pavyzdžius ir patarimus.

---

## DAPSI(W)R(M) sistema {#the-dapsiwrm-framework}

### Apžvalga

DAPSI(W)R(M) yra priežastinė sistema jūrinių socialinių-ekologinių sistemų analizei:

- **D** - **Varomosios jėgos (Drivers):** Pagrindinės jėgos, motyvuojančios žmogaus veiklą (ekonominės, socialinės, technologinės, politinės)
- **A** - **Veiklos (Activities):** Žmogaus naudojimasis jūrine ir pakrančių aplinka
- **P** - **Spaudimai (Pressures):** Tiesioginiai stresoriai jūrinei aplinkai
- **S** - **Būsenos pokyčiai (State Changes):** Ekosistemos būklės pokyčiai, pateikiami per:
  - **W** - **Poveikis gerovei (Welfare):** Gėrybės ir nauda, gaunamos iš ekosistemos
  - **ES** - **Ekosistemos paslaugos (Ecosystem Services):** Nauda, kurią ekosistemos teikia žmonėms
  - **MPF** - **Jūriniai procesai ir funkcionavimas (Marine Processes & Functioning):** Biologiniai, cheminiai ir fiziniai procesai
- **R** - **Atsakai (Responses):** Visuomenės veiksmai problemoms spręsti
- **M** - **Priemonės (Measures):** Politikos intervencijos ir valdymo veiksmai

### Priežastinė grandinė

Sistema atvaizduoja priežastinę grandinę:

```
Varomosios jėgos → Veiklos → Spaudimai → Būsenos pokyčiai (MPF → ES → Gerovė) → Atsakai
    ↑                                                                                 ↓
    └──────────────────────── Grįžtamojo ryšio kilpa ──────────────────────────────────┘
```

### Kodėl DAPSI(W)R(M)?

- **Sisteminga:** Užtikrina visapusišką visų sistemos komponentų aprėptį
- **Priežastinė:** Nustato aiškius ryšius tarp žmogaus veiksmų ir ekosistemos pokyčių
- **Cikliška:** Fiksuoja grįžtamojo ryšio kilpas tarp ekosistemos ir visuomenės
- **Politikai aktuali:** Tiesiogiai susieta su intervencijos taškais (Atsakai/Priemonės)
- **Plačiai naudojama:** Standartinė sistema Europos jūrų politikoje (MSFD, WFD)

---

## Žingsnis po žingsnio darbo eiga {#step-by-step-workflow}

### Rekomenduojama seka

Atlikite pratimus iš eilės geriausiam rezultatui:

**1 fazė: Apimties nustatymas (Exercise 0)**
- Apibrėžkite savo atvejo studijos ribas ir kontekstą

**2 fazė: Priežastinės grandinės sudarymas (Exercises 1-5)**
- Dirbkite atgal nuo gerovės poveikio iki pagrindinių varomųjų jėgų
- Exercise 1: Gėrybės ir nauda (ką žmonės vertina)
- Exercise 2a: Ekosistemos paslaugos (kaip ekosistemos teikia naudą)
- Exercise 2b: Jūriniai procesai (pagrindinės ekologinės funkcijos)
- Exercise 3: Spaudimai (stresoriai ekosistemoje)
- Exercise 4: Veiklos (žmogaus naudojimasis jūrine aplinka)
- Exercise 5: Varomosios jėgos (jėgos, motyvuojančios veiklas)

**3 fazė: Kilpos uždarymas (Exercise 6)**
- Sujunkite varomąsias jėgas atgal su gėrybėmis ir nauda, kad sukurtumėte grįžtamojo ryšio kilpas

**4 fazė: Vizualizacija (Exercises 7-9)**
- Sukurkite Priežastinių Kilpų Diagramas Kumu programoje
- Eksportuokite ir tobulinkite savo vizualinį modelį

**5 fazė: Analizė ir patvirtinimas (Exercises 10-12)**
- Tobulinkite savo modelį (patikslinimas)
- Nustatykite svertų taškus
- Patvirtinkite su suinteresuotosiomis šalimis

**Nuolatinis: BOT grafikai**
- Pridėkite laikinius duomenis, kai jie prieinami
- Naudokite priežastinėms hipotezėms patvirtinti

### Laiko reikalavimai

**Greita analizė:** 4-8 valandos (supaprastinta atvejo studija, maža komanda)

**Išsami analizė:** 2-4 dienos (sudėtinga atvejo studija, suinteresuotųjų šalių įtraukimas)

**Visapusiškas dalyvavimo procesas:** 1-2 savaitės (daug seminarų, išsamus patvirtinimas)

### Darbas komandoje

**Individualus darbas:**
- Vienas asmuo įveda duomenis remdamasis literatūros apžvalga ir ekspertinėmis žiniomis

**Bendradarbiaujant:**
- Eksportuokite/importuokite Excel failus duomenų bendrinimui
- Naudokite Kumu bendradarbiavimo funkcijas CLD kūrimui
- Renkite seminarus pratimų indėliui surinkti

---

## Pratimų vadovas {#exercise-by-exercise-guide}

### Exercise 0: Kompleksiškumo atskleidimas ir poveikis gerovei

**Tikslas:** Nustatyti jūsų analizės kontekstą ir ribas.

**Ką įvesti:**
- Atvejo studijos pavadinimas
- Trumpas aprašymas
- Geografinė apimtis (pvz., „Baltijos jūra", „Šiaurės Atlanto pakrantė")
- Laiko apimtis (pvz., „2000-2024")
- Poveikis gerovei (pradiniai stebėjimai)
- Pagrindinės suinteresuotosios šalys

**Patarimai:**
- Būkite išsamūs, bet glaustūs
- Apsvarstykite įvairias perspektyvas (aplinkosauginę, ekonominę, socialinę, kultūrinę)
- Įtraukite ir naudą, ir kaštus
- Išvardykite visas paveiktas ir sprendimus priimančias suinteresuotąsias šalis

**Pavyzdys:**
```
Atvejis: Baltijos jūros komercinė žvejyba
Geografinė apimtis: Baltijos jūros baseinas
Laiko apimtis: 2000-2024
Poveikis gerovei: Žvejybos pajamos, užimtumas, maisto saugumas,
                  kultūros paveldas, mažėjančios atsargos
Suinteresuotosios šalys: Komerciniai žvejai, pakrančių bendruomenės, perdirbėjai,
                         vartotojai, NVO, žuvininkystės valdytojai, ES politikos formuotojai
```

---

### Exercise 1: Gėrybių ir Naudos (G&B) specifikavimas

**Tikslas:** Nustatyti, ką žmonės vertina iš jūrinės ekosistemos.

**Ką įvesti kiekvienai gėrybei/naudai:**
- **Pavadinimas:** Aiškus, konkretus pavadinimas (pvz., „Komercinė menkių žvejyba")
- **Tipas:** Aprūpinimo / Reguliacinė / Kultūrinė / Palaikomoji
- **Aprašymas:** Ką teikia ši nauda
- **Suinteresuotoji šalis:** Kam tai naudinga?
- **Svarba:** Aukšta / Vidutinė / Žema
- **Tendencija:** Didėjanti / Stabili / Mažėjanti / Nežinoma

**Kaip naudoti:**
1. Spustelėkite „Pridėti gėrybę/naudą"
2. Užpildykite visus laukus
3. Spustelėkite „Išsaugoti Exercise 1", kad atnaujintumėte lentelę
4. Kiekviena G&B automatiškai gauna unikalų ID (GB001, GB002 ir t.t.)

**Pavyzdžiai:**

| Pavadinimas | Tipas | Suinteresuotoji šalis | Svarba |
|-------------|-------|----------------------|--------|
| Komerciniai žuvų iškrovimai | Aprūpinimo | Žvejai, vartotojai | Aukšta |
| Pakrančių rekreacija | Kultūrinė | Turistai, gyventojai | Aukšta |
| Apsauga nuo audrų bangų | Reguliacinė | Pakrančių nekilnojamojo turto savininkai | Aukšta |
| Anglies sekvestracija | Reguliacinė | Globali visuomenė | Vidutinė |

**Patarimai:**
- Būkite konkretūs: „Komercinė menkių žvejyba", o ne tiesiog „žvejyba"
- Įtraukite ir rinkos (žuvų pardavimas), ir ne rinkos (rekreacija) naudą
- Apsvarstykite naudą skirtingoms suinteresuotųjų šalių grupėms
- Pagalvokite apie sinergijas ir kompromisus

---

### Exercise 2a: Ekosistemos paslaugos (ES), veikiančios gėrybes ir naudą

**Tikslas:** Nustatyti ekosistemos gebėjimą generuoti naudą.

**Ką įvesti kiekvienai ekosistemos paslaugai:**
- **Pavadinimas:** Paslaugos pavadinimas
- **Tipas:** Paslaugos klasifikacija
- **Aprašymas:** Kaip ji veikia
- **Susieta su G&B:** Pasirinkite iš išskleidžiamojo sąrašo (gėrybės/nauda iš Pr. 1)
- **Mechanizmas:** Kaip ši paslauga sukuria naudą?
- **Patikimumas:** Aukštas / Vidutinis / Žemas

**ES ir G&B supratimas:**
- **Ekosistemos paslauga:** Potencialas/gebėjimas (pvz., „Žuvų atsargų produktyvumas")
- **Gėrybė/Nauda:** Realizuota nauda (pvz., „Komercinė žuvų žvejyba")

**Kaip naudoti:**
1. Spustelėkite „Pridėti ekosistemos paslaugą"
2. Užpildykite laukus
3. Pasirinkite, kurią G&B palaiko ši ES (sąrašas rodo visas G&B iš Exercise 1)
4. Spustelėkite „Išsaugoti Exercise 2a"

**Pavyzdžiai:**

| ES pavadinimas | Susieta su G&B | Mechanizmas |
|----------------|----------------|-------------|
| Žuvų atsargų papildymas | Komercinė žuvų žvejyba | Neršto sėkmė → žvejybai tinkama biomasė |
| Moliuskų filtracija | Vandens kokybė turizmui | Midijos filtruoja daleles → skaidrus vanduo |
| Jūrinių žolių buveinė | Augykla komercinėms rūšims | Prieglobstis jaunikliams → suaugusių žuvų populiacija |

**Patarimai:**
- Vieną G&B gali palaikyti kelios ES
- Viena ES gali palaikyti kelias G&B
- Aiškiai aprašykite mechanizmą (palengvina patvirtinimą)
- Naudokite mokslines žinias ir suinteresuotųjų šalių indėlį

---

### Exercise 2b: Jūriniai procesai ir funkcionavimas (MPF)

**Tikslas:** Nustatyti fundamentalius ekologinius procesus, palaikančius ekosistemos paslaugas.

**Ką įvesti kiekvienam jūriniam procesui:**
- **Pavadinimas:** Proceso pavadinimas
- **Tipas:** Biologinis / Cheminis / Fizinis / Ekologinis
- **Aprašymas:** Ką šis procesas daro
- **Susieta su ES:** Pasirinkite iš išskleidžiamojo sąrašo (ES iš Pr. 2a)
- **Mechanizmas:** Kaip šis procesas generuoja paslaugą?
- **Erdvinė skalė:** Kur vyksta (vietinė/regioninė/baseino mastu)

**Jūrinių procesų tipai:**
- **Biologiniai:** Pirminė produkcija, plėšrūnystė, dauginimasis, migracija
- **Cheminiai:** Maistinių medžiagų apytaka, anglies sekvestracija, pH reguliavimas
- **Fiziniai:** Vandens cirkuliacija, nuosėdų transportas, bangų veikimas
- **Ekologiniai:** Buveinės struktūra, mitybos tinklo dinamika, bioįvairovė

**Kaip naudoti:**
1. Spustelėkite „Pridėti jūrinį procesą"
2. Užpildykite laukus
3. Pasirinkite, kurią ES palaiko šis MPF
4. Spustelėkite „Išsaugoti Exercise 2b"

**Pavyzdžiai:**

| MPF pavadinimas | Tipas | Susieta su ES | Mechanizmas |
|-----------------|-------|---------------|-------------|
| Fitoplanktono pirminė produkcija | Biologinis | Žuvų atsargų produktyvumas | Šviesa + maistinės medžiagos → biomasė → mitybos tinklas |
| Jūrinių žolių fotosintezė | Biologinis | Anglies kaupimas | CO2 absorbcija → organinė medžiaga → palaidojimas nuosėdose |
| Midžių lovų filtracija | Ekologinis | Vandens skaidrumas | Filtrinis maitinimasis šalina daleles |

**Patarimai:**
- Sutelkite dėmesį į procesus, susijusius su jūsų ES
- Naudokite mokslines žinias
- Apsvarstykite erdvines ir laikines skales
- Keli procesai gali prisidėti prie vienos ES

---

### Exercise 3: Spaudimų būsenos pokyčiams specifikavimas

**Tikslas:** Nustatyti stresorius, veikiančius jūrinius procesus.

**Ką įvesti kiekvienam spaudimui:**
- **Pavadinimas:** Aiškus spaudimo pavadinimas
- **Tipas:** Fizinis / Cheminis / Biologinis / Daugialypis
- **Aprašymas:** Stresoriaus pobūdis
- **Susieta su MPF:** Pasirinkite iš išskleidžiamojo sąrašo (MPF iš Pr. 2b)
- **Intensyvumas:** Aukštas / Vidutinis / Žemas / Nežinomas
- **Erdvinis:** Kur pasireiškia
- **Laikinis:** Kada/kaip dažnai (nuolatinis/sezoninis/epizodinis)

**Spaudimų tipai:**
- **Fiziniai:** Jūros dugno abrazcija, buveinių praradimas, triukšmas, šiluma
- **Cheminiai:** Maistinių medžiagų perteklius, teršalai, rūgštėjimas
- **Biologiniai:** Rūšių pašalinimas, invazinės rūšys, patogenai
- **Daugialypiai:** Kombinuoti poveikiai

**Kaip naudoti:**
1. Spustelėkite „Pridėti spaudimą"
2. Užpildykite laukus
3. Pasirinkite, kurį MPF veikia šis spaudimas
4. Įvertinkite intensyvumą ir aprašykite erdvinius/laikinius modelius
5. Spustelėkite „Išsaugoti Exercise 3"

**Pavyzdžiai:**

| Spaudimo pavadinimas | Tipas | Susieta su MPF | Intensyvumas |
|----------------------|-------|----------------|--------------|
| Maistinių medžiagų perteklius | Cheminis | Fitoplanktono sudėtis | Aukštas |
| Dugninė tralavimo žvejyba | Fizinis | Bentinės buveinės struktūra | Aukštas |
| Peržvejojimas | Biologinis | Mitybos tinklo dinamika | Vidutinis |

**Patarimai:**
- Vienas spaudimas gali veikti kelis procesus
- Nurodykite tiesioginį mechanizmą
- Apsvarstykite kumuliatyvius poveikius
- Įtraukite ir chroniškas, ir ūmias presijas
- Naudokite mokslinius įrodymus intensyvumo vertinimams

---

### Exercise 4: Veiklų, veikiančių spaudimus, specifikavimas

**Tikslas:** Nustatyti žmogaus veiklas, generuojančias spaudimus.

**Ką įvesti kiekvienai veiklai:**
- **Pavadinimas:** Aiškus pavadinimas
- **Sektorius:** Žuvininkystė / Akvakultūra / Turizmas / Laivyba / Energetika / Kasyba / Kita
- **Aprašymas:** Ką apima veikla
- **Susieta su spaudimu:** Pasirinkite iš išskleidžiamojo sąrašo (spaudimai iš Pr. 3)
- **Mastelis:** Vietinis / Regioninis / Nacionalinis / Tarptautinis
- **Dažnumas:** Nuolatinis / Sezoninis / Retkarčiais / Vienkartinis

**Dažnos jūrinės veiklos:**
- **Žuvininkystė:** Komercinė/pramoginė/pragyvenimui skirta žvejyba
- **Akvakultūra:** Žuvų/moliuskų auginimas
- **Turizmas:** Paplūdimio turizmas, laukinės gamtos stebėjimas, nardymas
- **Laivyba:** Kroviniai, kruizai, keltai
- **Energetika:** Jūrinė vėjo energetika, nafta ir dujos, potvynių/bangų energija
- **Infrastruktūra:** Uostai, pakrančių statyba
- **Žemės ūkis:** Maistinių medžiagų nutekėjimas (sausumos kilmės, bet su jūriniu poveikiu)

**Kaip naudoti:**
1. Spustelėkite „Pridėti veiklą"
2. Užpildykite laukus
3. Pasirinkite, kokį spaudimą(-us) generuoja ši veikla
4. Nurodykite mastelį ir dažnumą
5. Spustelėkite „Išsaugoti Exercise 4"

**Pavyzdžiai:**

| Veiklos pavadinimas | Sektorius | Susieta su spaudimu | Mastelis |
|---------------------|-----------|---------------------|----------|
| Dugninė tralavimo žvejyba | Žuvininkystė | Jūros dugno abrazcija | Regioninis |
| Pakrančių nuotekų išleidimas | Atliekos | Maistinių medžiagų perteklius | Vietinis |
| Laivų eismas | Laivyba | Povandeninis triukšmas, naftos tarša | Tarptautinis |

**Patarimai:**
- Būkite konkretūs: „Dugninė tralavimo žvejyba", o ne tiesiog „Žvejyba"
- Viena veikla dažnai generuoja kelis spaudimus
- Apsvarstykite tiesioginius ir netiesioginius kelius
- Įtraukite sezonius modelius

---

### Exercise 5: Varomosios jėgos, sukeliančios veiklas

**Tikslas:** Nustatyti pagrindines jėgas, motyvuojančias veiklas.

**Ką įvesti kiekvienai varomajai jėgai:**
- **Pavadinimas:** Aiškus pavadinimas
- **Tipas:** Ekonominis / Socialinis / Technologinis / Politinis / Aplinkos / Demografinis
- **Aprašymas:** Kas yra ši jėga ir kaip ji veikia
- **Susieta su veikla:** Pasirinkite iš išskleidžiamojo sąrašo (veiklos iš Pr. 4)
- **Tendencija:** Didėjanti / Stabili / Mažėjanti / Ciklinė / Neaiški
- **Kontroliuojamumas:** Aukštas / Vidutinis / Žemas / Jokio

**Varomųjų jėgų tipai:**
- **Ekonominiai:** Rinkos paklausa, kainos, subsidijos, ekonominis augimas
- **Socialiniai:** Kultūrinės tradicijos, vartotojų pasirinkimai, socialinės normos
- **Technologiniai:** Žvejybos įrankių inovacijos, laivų efektyvumas, naujos technikos
- **Politiniai:** Reguliavimas, valdymas, tarptautiniai susitarimai
- **Aplinkos:** Klimato kaita, ekstremalūs orai (kaip prisitaikymo varomosios jėgos)
- **Demografiniai:** Gyventojų skaičiaus augimas, urbanizacija, migracija

**Kaip naudoti:**
1. Spustelėkite „Pridėti varomąją jėgą"
2. Užpildykite laukus
3. Pasirinkite, kokią veiklą(-as) motyvuoja ši jėga
4. Įvertinkite tendenciją ir kontroliuojamumą
5. Spustelėkite „Išsaugoti Exercise 5"

**Pavyzdžiai:**

| Jėgos pavadinimas | Tipas | Susieta su veikla | Kontroliuojamumas |
|-------------------|-------|-------------------|-------------------|
| Globali jūros gėrybių paklausa | Ekonominis | Komercinės žvejybos plėtra | Žemas |
| ES atsinaujinančios energijos tikslai | Politinis | Jūrinės vėjo energetikos plėtra | Aukštas |
| Pakrančių turizmo paklausa | Socialinis/Ekonominis | Pakrančių plėtra | Vidutinis |

**Patarimai:**
- Pagalvokite, KODĖL žmonės užsiima veiklomis
- Apsvarstykite ir stūmimo, ir traukimo veiksnius
- Varomosios jėgos dažnai sąveikauja (ekonominė + technologinė + politinė)
- Vertinkite kontroliuojamumą sąžiningai
- Varomosios jėgos dažnai yra geriausi intervencijos taškai

---

### Exercise 6: Kilpos uždarymas - Varomosios jėgos su Gėrybėmis ir Nauda

**Tikslas:** Sukurti grįžtamojo ryšio kilpas, sujungiant varomąsias jėgas atgal su gėrybėmis ir nauda.

**Ką nustatyti:**
- Kaip Gėrybių ir Naudos pokyčiai veikia Varomąsias jėgas?
- Kaip Varomosios jėgos reaguoja į ekosistemos sąlygas?
- Kurie grįžtamieji ryšiai yra stiprinantys (stiprinami)?
- Kurie yra balansuojantys (stabilizuojantys)?

**Grįžtamojo ryšio kilpų tipai:**

**Stiprinančios kilpos (R):** Pokyčiai stiprina patys save
- Pavyzdys: Mažėjančios žuvų atsargos → Mažesnis pelnas → Didesnis žvejybos pastangų siekiant išlaikyti pajamas → Tolesnis mažėjimas

**Balansuojančios kilpos (B):** Pokyčiai sukelia kompensuojančius atsakus
- Pavyzdys: Prastėjanti vandens kokybė → Mažėjantis turizmas → Ekonominis spaudimas valyti → Pagerėjusi kokybė

**Kaip naudoti:**
1. Peržiūrėkite kilpų jungčių sąsają
2. Pasirinkite varomoji jėga-G&B jungtis, kuriančias reikšmingus grįžtamuosius ryšius
3. Dokumentuokite, ar grįžtamieji ryšiai yra stiprinantys ar balansuojantys
4. Spustelėkite „Išsaugoti Exercise 6"

**Pavyzdžiai:**

| Iš (G&B) | Į (Varomoji jėga) | Tipas | Paaiškinimas |
|-----------|--------------------|-------|--------------|
| Mažėjanti žuvų žvejyba | Sumažėjusi žvejybos pajėgumas | Balansuojantis | Mažas pelnas stumia žvejus iš pramonės |
| Pagerėjusi vandens kokybė | Politinė parama gamtosaugai | Stiprinantis | Sėkmė gimdo daugiau gamtosauginės politikos |
| Pakrančių audrų žala | Ekosistemų atkūrimo politika | Balansuojantis | Nuostoliai sukelia apsaugines priemones |

**Patarimai:**
- Ne visos varomosios jėgos turi būti sujungtos atgal
- Apsvarstykite laiko vėlavimus (metai, kol pasireiškia)
- Suinteresuotųjų šalių žinios yra labai svarbios
- Dokumentuokite kilpos tipą (R arba B)

---

### Exercises 7-9: Priežastinių Kilpų Diagramų kūrimas ir eksportas

**Tikslas:** Vizualizuoti sistemos struktūrą Kumu programinėje įrangoje.

#### Exercise 7: Poveikiu pagrįstos CLD kūrimas Kumu

**Žingsniai:**
1. Spustelėkite „Atsisiųsti Kumu CSV failus", kad eksportuotumėte duomenis
2. Eikite į [kumu.io](https://kumu.io) ir sukurkite nemokamą paskyrą
3. Sukurkite naują projektą (pasirinkite „Causal Loop Diagram" šabloną)
4. Importuokite savo CSV failus:
   - `elements.csv` → apima visus mazgus
   - `connections.csv` → apima visas briaunas
5. Pritaikykite Kumu stiliaus kodą iš `Documents/Kumu_Code_Style.txt`
6. Išdėstykite elementus, kad būtų matomi aiškūs priežastiniai srautai

**Kumu spalvų schema:**
- Gėrybės ir Nauda: Geltoni trikampiai
- Ekosistemos paslaugos: Mėlyni kvadratai
- Jūriniai procesai: Šviesiai mėlynos kapsulės
- Spaudimai: Oranžiniai rombai
- Veiklos: Žali šešiakampiai
- Varomosios jėgos: Violetiniai aštuonkampiai

#### Exercise 8: Nuo priežastinės logikos grandinių prie priežastinių kilpų

**Žingsniai:**
1. Kumu programoje identifikuokite uždarytas kilpas savo diagramoje
2. Atsekite kelius nuo elemento atgal iki jo paties
3. Klasifikuokite kilpas kaip stiprinančias (R) arba balansuojančias (B)
4. Pridėkite kilpų identifikatorius Kumu (naudokite žymas ar tags)
5. Sutelkite dėmesį į svarbiausias kilpas, lemiančias sistemos elgseną

**Kilpos tipo nustatymas:**
- Suskaičiuokite neigiamų (-) jungčių skaičių kilpoje
- Lyginis (-) jungčių skaičius = Stiprinanti (R)
- Nelyginis (-) jungčių skaičius = Balansuojanti (B)

#### Exercise 9: CLD eksportavimas tolesnei analizei

**Žingsniai:**
1. Eksportuokite aukštos rezoliucijos vaizdus iš Kumu:
   - Spustelėkite Bendrinti → Eksportuoti → PNG/PDF
2. Atsisiųskite visą Excel darbo knygą iš ISA modulio
3. Peržiūrėkite gretimumo matricas, kad patikrintumėte visas jungtis
4. Sukurkite skirtingas peržiūras:
   - Visos sistemos vaizdas
   - Posistemių vaizdai (pvz., tik žuvininkystė)
   - Pagrindinių kilpų vaizdai
5. Dokumentuokite pagrindines kilpas su aprašomosiomis naratyvomis

**Spustelėkite „Išsaugoti Exercises 7-9", kai baigsite.**

---

### Exercises 10-12: Patikslinimas, metrikos ir patvirtinimas

#### Exercise 10: Patikslinimas - Endogenizacija ir inkapsulacija

**Endogenizacija:** Išorinių veiksnių įtraukimas į sistemos ribas

**Ką daryti:**
1. Peržiūrėkite išorines varomąsias jėgas
2. Ar kurios nors gali būti paaiškintos veiksniais jūsų sistemos viduje?
3. Pridėkite šiuos vidinius grįžtamuosius ryšius
4. Dokumentuokite „Endogenizacijos pastabose"

**Pavyzdys:** „Rinkos paklausa" gali būti veikiama „produkto kokybės" jūsų sistemoje

**Inkapsulacija:** Detalių procesų grupavimas į aukštesnio lygio konceptus

**Ką daryti:**
1. Identifikuokite pernelyg sudėtingas posistemes
2. Sugrupuokite susijusius elementus (pvz., keli maistinių medžiagų procesai → „Eutrofikacijos dinamika")
3. Išlaikykite detalią versiją techniniam darbui
4. Sukurkite supaprastintą versiją politikos komunikacijai
5. Dokumentuokite „Inkapsulacijos pastabose"

#### Exercise 11: Metrikos, pagrindinės priežastys ir svertų taškai

**Pagrindinių priežasčių analizė:**
1. Naudokite „Pagrindinių priežasčių" sąsają
2. Identifikuokite elementus su daug išeinančių jungčių
3. Atsekite nuo problemų iki pagrindinių priežasčių
4. Sutelkite dėmesį į varomąsias jėgas ir veiklas

**Svertų taškų identifikavimas:**
1. Naudokite „Svertų taškų" sąsają
2. Ieškokite:
   - Kilpų kontrolės taškų
   - Aukšto centralumo mazgų (daug jungčių)
   - Konvergencijos taškų (susitinka keli keliai)
3. Apsvarstykite įgyvendinamumą ir kontroliuojamumą
4. Prioritetizuokite veiksmingus svertų taškus

**Meadows hierarchija:**
- Silpniausia: Parametrai (skaičiai, normos)
- Stipriau: Grįžtamojo ryšio kilpos
- Labai stipru: Sistemos dizainas/struktūra
- Stipriausia: Paradigmos (mąstymo būdai, tikslai)

#### Exercise 12: Rezultatų pristatymas ir patvirtinimas

**Patvirtinimo metodai:**
- ✓ Vidinė komandos peržiūra
- ✓ Suinteresuotųjų šalių seminaras
- ✓ Ekspertų recenzavimas
- ✓ Galutinis patvirtinimas

**Ką daryti:**
1. Vykdykite patvirtinimo veiklas
2. Fiksuokite grįžtamąjį ryšį „Patvirtinimo pastabose"
3. Pažymėkite langelius atliktų patvirtinimo tipų
4. Atnaujinkite modelį pagal grįžtamąjį ryšį
5. Paruoškite pristatymus skirtingoms auditorijoms

**Pristatymo patarimai:**
- Pritaikykite sudėtingumą auditorijai
- Naudokite vizualinę CLD apžvalgai
- Papasakokite istorijas apie pagrindines kilpas
- Parodykite BOT grafikus kaip įrodymus
- Susiekite su politikos rekomendacijomis
- Būkite skaidrūs dėl neapibrėžtumų

**Spustelėkite „Išsaugoti Exercises 10-12", kai baigsite.**

---

### BOT grafikai: Elgsena laike {#bot-graphs-behaviour-over-time}

**Tikslas:** Vizualizuoti laikines dinamikas priežastiniam modeliui patvirtinti.

**Kaip sukurti BOT grafikus:**

1. **Pasirinkite elemento tipą:** Rinkitės iš išskleidžiamojo sąrašo (Gėrybės ir Nauda / ES / MPF / Spaudimai / Veiklos / Varomosios jėgos)
2. **Pasirinkite konkretų elementą:** Pasirinkite, kurį elementą grafiškai atvaizduoti
3. **Pridėkite duomenų taškus:**
   - Metai
   - Reikšmė
   - Vienetas (pvz., „tonos", „%", „indeksas")
   - Spustelėkite „Pridėti duomenų tašką"
4. **Peržiūrėkite grafiką:** Laiko eilutė atsiranda automatiškai
5. **Pakartokite** kitiems elementams

**Ko ieškoti:**
- **Tendencijos:** Pastovus didėjimas/mažėjimas
- **Ciklai:** Reguliarūs svyravimai
- **Pakopiniai pokyčiai:** Staigūs pokyčiai (politikos kaita)
- **Vėlavimai:** Laiko atsilikimas
- **Slenksčiai:** Lūžio taškai
- **Plynaukštės:** Stabilumas

**BOT grafikų naudojimas:**
- Palyginkite modelius su CLD prognozėmis
- Identifikuokite grįžtamojo ryšio kilpų įrodymus
- Išmatuokite laiko vėlavimus
- Įvertinkite politikos intervencijas
- Projektuokite ateities scenarijus

**Duomenų šaltiniai:**
- Oficialios statistikos
- Aplinkos monitoringas
- Mokslinės apklausos
- Suinteresuotųjų šalių stebėjimai
- Istoriniai įrašai

**Spustelėkite „Išsaugoti BOT duomenis", kad išsaugotumėte savo darbą.**

---

## Darbas su Kumu {#working-with-kumu}

### Darbo pradžia su Kumu

**1. Paskyros sukūrimas:**
- Eikite į [kumu.io](https://kumu.io)
- Užsiregistruokite nemokamą paskyrą
- Vieši projektai yra nemokami; privatiems projektams reikia prenumeratos

**2. Naujo projekto sukūrimas:**
- Spustelėkite „Naujas projektas"
- Pasirinkite „Causal Loop Diagram" šabloną
- Pavadinkite savo projektą

**3. Duomenų importavimas:**
- Iš ISA modulio atsisiųskite Kumu CSV failus
- Kumu programoje spustelėkite Importuoti
- Įkelkite `elements.csv` ir `connections.csv`

### Pritaikytų stilių taikymas

**Nukopijuokite Kumu kodą:**
- Atidarykite `Documents/Kumu_Code_Style.txt`
- Nukopijuokite visą turinį

**Pritaikykite savo žemėlapiui:**
1. Kumu programoje spustelėkite Nustatymų piktogramą
2. Eikite į „Išplėstinį redaktorių"
3. Įklijuokite kodą
4. Spustelėkite „Išsaugoti"

**Rezultatas:** Jūsų elementai bus spalvoti ir formuoti pagal tipą:
- Gėrybės ir Nauda: Geltoni trikampiai
- Ekosistemos paslaugos: Mėlyni kvadratai
- Jūriniai procesai: Šviesiai mėlynos kapsulės
- Spaudimai: Oranžiniai rombai
- Veiklos: Žali šešiakampiai
- Varomosios jėgos: Violetiniai aštuonkampiai

### Darbas su diagrama

**Išdėstymo parinktys:**
- Automatinis išdėstymas: Leiskite Kumu surikiuoti elementus
- Rankinis: Vilkite elementus į norimas pozicijas
- Žiedinis: Pabrėžkite kilpų struktūrą
- Hierarchinis: Parodykite priežastinį srautą nuo varomųjų jėgų iki gerovės

**Informacijos pridėjimas:**
- Spustelėkite bet kurį elementą, kad redaguotumėte savybes
- Pridėkite aprašymus, žymas, pasirinktinius laukus
- Įtraukite duomenų šaltinius, patikimumo lygius

**Kilpų paryškinimas:**
1. Identifikuokite uždarą kilpos kelią
2. Pridėkite „Kilpa" žymą visiems kilpos elementams
3. Naudokite Kumu filtrą kilpoms rodyti/slėpti
4. Pažymėkite kilpas (pvz., „R1: Peržvejojimo spiralė", „B1: Kokybės atstatymas")

**Filtrai ir peržiūros:**
- Filtruokite pagal elemento tipą (rodyti tik Varomąsias jėgas)
- Filtruokite pagal svarbą, patikimumą ir kt.
- Sukurkite kelias peržiūras (visa sistema, pagrindinės kilpos, posistemės)
- Išsaugokite peržiūras pristatymams

### Bendradarbiavimas

**Dalinimasis:**
- Dalinkitės tik peržiūros nuoroda su suinteresuotosiomis šalimis
- Eksportuokite ekrano kopijas ataskaitoms
- Integruokite į svetaines/pristatymus

**Komandinis redagavimas:**
- Pridėkite bendradarbius (mokama funkcija)
- Keli žmonės gali redaguoti vienu metu
- Versijų kontrolė prieinama

### Eksporto parinktys

**Iš Kumu:**
- **PNG:** Aukštos rezoliucijos vaizdas ataskaitoms
- **PDF:** Vektorinis formatas publikacijoms
- **JSON:** Neapdoroti duomenys archyvavimui
- **Bendrinimo nuoroda:** Interaktyvi interneto peržiūra

**Iš ISA modulio:**
- **Excel darbo knyga:** Pilni duomenys su visais lapais
- **Kumu CSV:** Elementai ir jungtys
- **Gretimumo matricos:** Jungčių matricos analizei

---

## Duomenų valdymas {#data-management}

### Darbo išsaugojimas

**Automatinis išsaugojimas:**
- Duomenys saugomi programos reaktyviojoje būsenoje jūsų sesijos metu
- Naudokite „Išsaugoti" mygtukus užbaigę kiekvieną pratimą

**Eksportas į Excel:**
1. Eikite į „Duomenų valdymo" kortelę
2. Įveskite failo pavadinimą (pvz., „ManoAtvejis_ISA_2024")
3. Spustelėkite „Eksportuoti į Excel"
4. Atsisiunčiama visa darbo knyga su visais duomenimis

### Esamų duomenų importavimas

**Iš Excel:**
1. Eikite į „Duomenų valdymo" kortelę
2. Spustelėkite „Pasirinkti Excel failą"
3. Pasirinkite anksčiau eksportuotą .xlsx failą
4. Spustelėkite „Importuoti duomenis"
5. Duomenys užpildo visus pratimus

**Excel failo struktūra:**
- Lapas: Case_Info
- Lapas: Goods_Benefits
- Lapas: Ecosystem_Services
- Lapas: Marine_Processes
- Lapas: Pressures
- Lapas: Activities
- Lapas: Drivers
- Lapas: BOT_Data

### Duomenų atstatymas

**Įspėjimas:** Tai ištrina VISUS duomenis ir negali būti atšaukta.

1. Eikite į „Duomenų valdymo" kortelę
2. Spustelėkite „Atstatyti visus duomenis" (raudonas mygtukas)
3. Patvirtinkite veiksmą
4. Visi pratimai grįžta į tuščią būseną

**Kada atstatyti:**
- Pradedant visiškai naują atvejo studiją
- Atmetant praktinį bandymą
- Po duomenų, kuriuos norite išsaugoti, eksportavimo

### Bendradarbiavimo darbo eigos

**Individualus darbas:**
- Vienas asmuo įveda visus duomenis
- Eksportuoja Excel, kai baigia
- Dalinasi failu su komanda peržiūrai

**Nuoseklus darbas:**
- Asmuo A: Exercises 0-3 → Eksportuoti
- Asmuo B: Importuoti → Exercises 4-6 → Eksportuoti
- Asmuo C: Importuoti → Exercises 7-12 → Galutinis eksportas

**Lygiagretus darbas:**
- Keli žmonės dirba su skirtingais pratimais atskirose sesijose
- Konsoliduoti Excel (rankiniu būdu sujungti lapus)
- Importuoti konsoliduotą failą

**Seminarais grindžiamas:**
- Moderuoti grupines diskusijas kiekvienam pratimui
- Vienas asmuo valdo įrankį ir įveda konsensuso duomenis
- Eksportuoti po kiekvieno pratimo dokumentavimui

---

## Patarimai ir geroji praktika {#tips-and-best-practices}

### Bendrieji darbo eigos patarimai

**1. Dirbkite sistemingai:**
- Atlikite pratimus iš eilės
- Nepraleidinėkite (vėlesni pratimai remiasi ankstesniais)
- Išsaugokite po kiekvieno pratimo

**2. Įtraukite suinteresuotąsias šalis:**
- Veskite seminarus Exercises 1-6
- Patvirtinkite CLD su tais, kurie pažįsta sistemą
- Naudokite įvairias perspektyvas (naudotojai, valdytojai, mokslininkai)

**3. Naudokite mokslinius įrodymus:**
- Grįskite ryšius recenzuotomis studijomis
- Cituokite šaltinius aprašymuose
- Pažymėkite patikimumo lygius

**4. Pradėkite paprastai, pridėkite detalių:**
- Pirmas praėjimas: Tik pagrindiniai elementai
- Antras praėjimas: Pridėkite niuansus ir detales
- Laikykite supaprastintą versiją komunikacijai

**5. Dokumentuokite viską:**
- Dosniai naudokite aprašymo laukus
- Fiksuokite duomenų šaltinius
- Pažymėkite prielaidas ir neapibrėžtumus

### Duomenų kokybės patarimai

**Būkite konkretūs:**
- ❌ „Žvejyba" → ✅ „Komercinė dugninė tralavimo žvejyba demersalinėms rūšims"
- ❌ „Tarša" → ✅ „Maistinių medžiagų perteklius dėl žemės ūkio nutekėjimo"

**Būkite išsamūs:**
- Įtraukite teigiamus ir neigiamus poveikius
- Apsvarstykite visas suinteresuotųjų šalių grupes
- Apimkite visus sektorius, naudojančius jūrų zoną

**Būkite realistiški:**
- Sutelkite dėmesį į svarbius elementus (viršutinius 80%)
- Nebandykite įtraukti visko
- Sudėtingumas turi atitikti turimas žinias

**Būkite nuoseklūs:**
- Naudokite nuoseklią terminologiją
- Palaikykite nuoseklų detalumo lygį visuose pratimuose
- Laikykitės pavadinimų taisyklių (pvz., elementų ID)

### CLD kūrimo patarimai

**Išdėstymas:**
- Išdėstykite priežastiniu srautu: Varomosios jėgos → Veiklos → Spaudimai → Būsena → Gerovė
- Aiškiai parodykite grįžtamojo ryšio kilpas
- Minimizuokite briaunų susikirtimus skaitomumui

**Kilpos:**
- Identifikuokite ir pažymėkite pagrindines kilpas (R1, R2, B1, B2)
- Sutelkite dėmesį į kilpas, lemiančias probleminę elgseną
- Dokumentuokite kilpų pasakojimus (kokią istoriją pasakoja kiekviena kilpa?)

**Patvirtinimas:**
- Ar CLD paaiškina stebimą sistemos elgseną?
- Ar suinteresuotosios šalys atpažįsta struktūrą?
- Ar galite atsekti konkrečius istorinius įvykius per diagramą?

### BOT grafikų patarimai

**Duomenų rinkimas:**
- Naudokite ilgiausias prieinamas laiko eilutes
- Būkite nuoseklūs su vienetais ir skalėmis
- Aiškiai dokumentuokite duomenų šaltinius

**Palyginimas:**
- Nubraižykite susijusius kintamuosius toje pačioje laiko ašyje
- Ieškokite korelacijų (ar jos sutampa su jūsų CLD?)
- Identifikuokite laiko vėlavimus tarp priežasties ir pasekmės

**Komunikacija:**
- Anotuokite pagrindiniais įvykiais (politikos pokyčiai, katastrofos)
- Naudokite nuoseklias spalvų schemas
- Įtraukite paklaidos juostas ar neapibrėžtumo diapazonus, jei prieinama

### Dažnos klaidos, kurių reikia vengti

**1. Per daug detalių per anksti:**
- Pradėkite nuo pagrindinių elementų
- Pridėkite detales iteracijomis
- Laikykite supaprastintą versiją

**2. Suinteresuotųjų šalių indėlio praleidimas:**
- Vietinės žinios yra neįkainojamos
- Teisėtumui reikia dalyvavimo
- Aklieji taškai atsiranda be įvairių perspektyvų

**3. ES ir G&B painiojimas:**
- ES = ekosistemos gebėjimas/potencialas
- G&B = realizuota nauda, kurią žmonės gauna
- Pavyzdys: „Žuvų atsargos" (ES) vs. „Žuvų žvejyba" (G&B)

**4. Silpni ryšiai:**
- Visada nurodykite mechanizmą
- Venkite miglotų jungčių
- Testas: Ar galite paaiškinti šį ryšį suinteresuotajai šaliai?

**5. Laiko ignoravimas:**
- Vėlavimai yra lemiami
- Kai kurie poveikiai pasireiškia per metus
- BOT grafikai atskleidžia laikinius modelius

**6. Nėra grįžtamojo ryšio kilpų:**
- Exercise 6 yra ypatingai svarbus
- Sistemos yra cikliškos, ne linijinės
- Grįžtamieji ryšiai lemia dinamiką

**7. Patvirtinimo praleidimas:**
- Jūsų modelis yra hipotezė
- Patikrinkite jį duomenimis ir suinteresuotųjų šalių žiniomis
- Iteruokite pagal grįžtamąjį ryšį

---

## Trikčių šalinimas {#troubleshooting}

### Dažnos problemos ir sprendimai

**Problema: „Mano duomenys neišsisaugojo"**
- **Sprendimas:** Visada spustelėkite „Išsaugoti Exercise X" mygtuką po duomenų įvedimo
- Patikrinkite, ar duomenų lentelė atsinaujina po išsaugojimo
- Dažnai eksportuokite į Excel kaip atsarginę kopiją

**Problema: „Išskleidžiamieji sąrašai tušti"**
- **Priežastis:** Neužbaigėte ankstesnio pratimo
- **Sprendimas:** Atlikite pratimus iš eilės. Pr. 2a reikia duomenų iš Pr. 1 ir t.t.

**Problema: „Padariau klaidą ankstesniame pratime"**
- **Sprendimas:** Grįžkite į to pratimo kortelę
- Duomenys vis dar ten ir redaguojami
- Atlikite pataisymus ir spustelėkite Išsaugoti dar kartą

**Problema: „Excel eksportas neveikia"**
- **Patikrinkite:** Naršyklės atsisiuntimo nustatymus
- **Patikrinkite:** Failų leidimus atsisiuntimo aplanke
- **Pabandykite:** Kitą naršyklę

**Problema: „Kumu importas nepavyksta"**
- **Patikrinkite:** CSV failo formatą (turi būti atskirta kableliais)
- **Patikrinkite:** Ar stulpelių antraštės atitinka Kumu reikalavimus
- **Pabandykite:** Pirmiausia importuoti elementus, tada jungtis

**Problema: „Programa lėta su dideliais duomenų rinkiniais"**
- **Normalu:** Daugiau nei 100 elementų gali sulėtinti atvaizdavimą
- **Sprendimas:** Dirbkite su posistemėmis atskirai
- **Sprendimas:** Naudokite Excel duomenų valdymui, programą struktūrai

**Problema: „Nerandu pagalbos turinio"**
- **Vieta:** Spustelėkite „?" pagalbos mygtuką kiekvienos pratimo kortelėje
- **Pagrindinis vadovas:** Spustelėkite „ISA Sistemos Vadovas" modulio viršuje

### Papildomos pagalbos gavimas

**Dokumentacija:**
- Šis naudotojo vadovas
- MarineSABRES paprasta SES JUODRAŠTIS vadovas (Dokumentų aplankas)
- Kumu dokumentacija: [docs.kumu.io](https://docs.kumu.io)

**Techninis palaikymas:**
- Patikrinkite programos versiją ir naršyklės suderinamumą
- Susisiekite su MarineSABRES projekto komanda
- Praneškite apie klaidas per GitHub (jei taikoma)

**Mokslinis palaikymas:**
- Žiūrėkite vadovą metodologiniams klausimams
- Pasitelkite srities ekspertus savo konkrečiai atvejo studijai
- Dalyvaukite ISA mokymo seminaruose

---

## Žodynas {#glossary}

**Veiklos (A):** Žmogaus naudojimasis jūrine ir pakrančių aplinka (žvejyba, laivyba, turizmas ir kt.)

**Gretimumo matrica:** Lentelė, rodanti, kurie elementai yra sujungti su kuriais kitais elementais

**Balansuojanti kilpa (B):** Grįžtamojo ryšio kilpa, kompensuojanti pokyčius ir stabilizuojanti sistemą

**BOT (Elgsena laike) grafikas:** Laiko eilutės grafikas, rodantis, kaip rodiklis keičiasi laikui bėgant

**Priežastinė grandinė:** Linijinė priežasties-pasekmės ryšių seka (pvz., Varomosios jėgos → Veiklos → Spaudimai)

**Priežastinių kilpų diagrama (CLD):** Vizualinis tinklas, rodantis elementus ir jų priežastinius ryšius, įskaitant grįžtamojo ryšio kilpas

**DAPSI(W)R(M):** Varomosios jėgos-Veiklos-Spaudimai-Būsena(Gerovė)-Atsakai(Priemonės) sistema

**Varomosios jėgos (D):** Pagrindinės jėgos, motyvuojančios veiklas (ekonominės, socialinės, politinės, technologinės)

**Ekosistemos paslaugos (ES):** Ekosistemų gebėjimas generuoti naudą žmonėms

**Inkapsulacija:** Detalių elementų grupavimas į aukštesnio lygio konceptus supaprastinimui

**Endogenizacija:** Išorinių veiksnių įtraukimas į sistemos ribas pridedant vidinius grįžtamuosius ryšius

**Grįžtamojo ryšio kilpa:** Ciklinis priežastinis kelias, kuriuo elementas veikia pats save per kitų elementų grandinę

**Gėrybės ir Nauda (G&B):** Realizuota nauda, kurią žmonės gauna iš jūrinių ekosistemų (poveikis gerovei)

**ISA (Integruota sistemų analizė):** Sisteminė sistema socialinių-ekologinių sistemų analizei

**Kumu:** Nemokama internetinė tinklų vizualizacijos programinė įranga (kumu.io)

**Sverto taškas:** Vieta sistemoje, kur nedidelė intervencija gali sukelti didelį pokytį

**Jūriniai procesai ir funkcionavimas (MPF):** Biologiniai, cheminiai, fiziniai ir ekologiniai procesai, palaikantys ekosistemos paslaugas

**Priemonės (M):** Politikos intervencijos ir valdymo veiksmai (atsakai)

**Poliariškumas:** Priežastinės įtakos kryptis (+ ta pati kryptis, - priešinga kryptis)

**Spaudimai (P):** Tiesioginiai stresoriai jūrinei aplinkai (tarša, buveinių naikinimas, rūšių pašalinimas)

**Stiprinanti kilpa (R):** Grįžtamojo ryšio kilpa, stiprinanti pokytį (gali būti dorybinis arba ydinis ratas)

**Atsakai (R):** Visuomenės veiksmai problemoms spręsti

**Pagrindinė priežastis:** Fundamentali varomoji jėga arba veikla priežastinės grandinės pradžioje

**Socialinė-ekologinė sistema (SES):** Integruota žmonių ir gamtos sistema su abipusiais grįžtamaisiais ryšiais

**Būsenos pokyčiai (S):** Ekosistemos būklės pokyčiai (atvaizduojami per W, ES ir MPF)

**Gerovė (W):** Žmogaus gerovė, atvaizduojama per gėrybes ir naudą iš ekosistemų

---

## Priedas: Greitos nuorodos kortelė {#appendix-quick-reference-card}

### Pratimų kontrolinis sąrašas

- [ ] Exercise 0: Apibrėžti atvejo studijos apimtį
- [ ] Exercise 1: Išvardyti visas Gėrybes ir Naudą
- [ ] Exercise 2a: Identifikuoti Ekosistemos paslaugas
- [ ] Exercise 2b: Identifikuoti Jūrinius procesus ir funkcionavimą
- [ ] Exercise 3: Identifikuoti Spaudimus
- [ ] Exercise 4: Identifikuoti Veiklas
- [ ] Exercise 5: Identifikuoti Varomąsias jėgas
- [ ] Exercise 6: Uždaryti grįžtamojo ryšio kilpas
- [ ] Exercise 7: Sukurti CLD Kumu
- [ ] Exercise 8: Identifikuoti priežastines kilpas
- [ ] Exercise 9: Eksportuoti ir dokumentuoti CLD
- [ ] Exercise 10: Patikslinti modelį (endogenizacija, inkapsulacija)
- [ ] Exercise 11: Identifikuoti svertų taškus
- [ ] Exercise 12: Patvirtinti su suinteresuotosiomis šalimis
- [ ] BOT grafikai: Pridėti laikinius duomenis
- [ ] Eksportuoti galutinę Excel darbo knygą

### Spartieji klavišai

- **Tab:** Judėti tarp formos laukų
- **Enter:** Pateikti/Išsaugoti formą
- **Ctrl+F / Cmd+F:** Ieškoti lentelėse

### Failų vietos

- **Naudotojo vadovas:** `Documents/ISA_User_Guide.md`
- **Vadovo dokumentas:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Kumu stilius:** `Documents/Kumu_Code_Style.txt`
- **Excel šablonas:** `Documents/ISA Excel Workbook.xlsx`

### Naudingi saitai

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Kumu dokumentacija:** [https://docs.kumu.io](https://docs.kumu.io)
- **DAPSI(W)R sistema:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Dokumento informacija {#document-information}

**Dokumentas:** ISA Duomenų Įvedimo Modulis - Naudotojo Vadovas
**Projektas:** MarineSABRES Socialinių-Ekologinių Sistemų Įrankių rinkinys
**Version:** 1.0
**Data:** 2026 m. balandis
**Būsena:** Juodraštis (automatinis vertimas)

**Citavimas:**
> MarineSABRES projektas (2025). ISA Duomenų Įvedimo Modulis - Naudotojo Vadovas.
> MarineSABRES Socialinių-Ekologinių Sistemų Analizės Įrankis, Versija 1.0.

**Licencija:** Šis vadovas pateikiamas naudojimui su MarineSABRES SES Įrankių rinkiniu.

---

**Klausimais, atsiliepimais ar palaikymu kreipkitės į MarineSABRES projekto komandą.**

**Sėkmingos analizės!**
