# Replace Lithuanian translations with Portuguese translations
library(jsonlite)

# Read the translation file
trans <- fromJSON("translation.json", simplifyVector = FALSE)

# Portuguese translations mapping (Lithuanian text -> Portuguese text)
portuguese_translations <- list(
  "Sveiki atvykę į MarineSABRES įrankių rinkinį" = "Bem-vindo à Caixa de Ferramentas MarineSABRES",
  "Ši orientavimo sistema padės jums rasti tinkamas priemones jūrų valdymo poreikiams." = "Este sistema de orientação irá ajudá-lo a encontrar as ferramentas certas para as suas necessidades de gestão marinha.",
  "Koks yra jūsų pagrindinis jūrų valdymo klausimas?" = "Qual é a sua principal questão de gestão marinha?",
  "Vedamas kelias" = "Caminho Guiado",
  "Nuoseklus vedimas per įėjimo taškus" = "Orientação passo a passo pelos pontos de entrada",
  "Pradėti vedamą kelionę" = "Iniciar Jornada Guiada",
  "Greita prieiga" = "Acesso Rápido",
  "Žinau, kokios priemonės man reikia" = "Eu sei que ferramenta preciso",
  "Naršyti priemones" = "Explorar Ferramentas",
  "Įėjimo taškas 0: Kas jūs?" = "Ponto de Entrada 0: Quem é Você?",
  "Pasirinkite savo vaidmenį jūrų valdyme" = "Selecione o seu papel na gestão marinha",
  "Jūsų vaidmuo padeda mums rekomenduoti tinkamiausias priemones ir darbo eigas jūsų jūrų valdymo kontekstui." = "O seu papel ajuda-nos a recomendar as ferramentas e fluxos de trabalho mais relevantes para o seu contexto de gestão marinha.",
  "Įėjimo taškas 1: Kodėl jums rūpi?" = "Ponto de Entrada 1: Por Que Você Se Importa?",
  "Koks pagrindinis žmogaus poreikis skatina jūsų klausimą?" = "Que necessidade humana básica motiva a sua questão?",
  "Supratimas pagrindinio žmogaus poreikio už jūsų klausimo padeda nustatyti svarbias ekosistemų paslaugas ir valdymo prioritetus." = "Compreender a necessidade humana fundamental por trás da sua questão ajuda a identificar serviços ecossistêmicos relevantes e prioridades de gestão.",
  "EP2: Veiklos sektoriai" = "EP2: Setores de Atividade",
  "Pasirinkite visus tinkamus (galima kelių pasirinkimas)" = "Selecione todos que se aplicam (seleção múltipla permitida)",
  "Pasirinkite žmogaus veiklą, susijusią su jūsų jūrų valdymo klausimu. Tai atspindi 'Varomąsias jėgas' ir 'Veiklą' DAPSI(W)R(M) sistemoje." = "Selecione as atividades humanas relevantes para a sua questão de gestão marinha. Estas representam os 'Impulsores' e 'Atividades' no quadro DAPSI(W)R(M).",
  "EP3: Rizikos ir pavojai" = "EP3: Riscos e Perigos",
  "Pasirinkite aplinkos spaudimus, rizikas ar pavojus, kurie jus jaudina. Tai atspindi 'Spaudimus' ir 'Būklės pokyčius' DAPSI(W)R(M) sistemoje." = "Selecione as pressões ambientais, riscos ou perigos que o preocupam. Estes representam 'Pressões' e 'Mudanças de estado' no quadro DAPSI(W)R(M).",
  "Įėjimo taškas 4: Žinių sritis" = "Ponto de Entrada 4: Domínio do Conhecimento",
  "Kokios teminės sritys jus domina? (Pasirinkite visas tinkamas)" = "Que áreas temáticas lhe interessam? (Selecione todas que se aplicam)",
  "Pasirinkite žinių sritis ir analitinius metodus, susijusius su jūsų klausimu. Tai padeda susieti jus su tinkamomis analizės priemonėmis ir sistemomis." = "Selecione os domínios de conhecimento e abordagens analíticas relevantes para a sua questão. Isto ajuda a associá-lo com ferramentas e estruturas de análise apropriadas.",
  "Praleisti" = "Pular",
  "Atgal" = "Voltar",
  "Tęsti" = "Continuar",
  "Gauti rekomendacijas" = "Obter Recomendações",
  "Rekomenduojamos priemonės jūsų jūrų valdymo klausimui" = "Ferramentas Recomendadas para a Sua Questão de Gestão Marinha",
  "Jūsų kelio santrauka" = "Resumo do Seu Percurso",
  "Vaidmuo:" = "Papel:",
  "Poreikis:" = "Necessidade:",
  "Veiklos:" = "Atividades:",
  "Rizikos:" = "Riscos:",
  "Temos:" = "Tópicos:",
  "Rekomenduojama darbo eiga:" = "Fluxo de Trabalho Recomendado:",
  "Sekite šią priemonių seką, kad išspręstumėte savo jūrų valdymo klausimą:" = "Siga esta sequência de ferramentas para abordar a sua questão de gestão marinha:",
  "PRADĖKITE ČIA" = "COMECE AQUI",
  "KITAS ŽINGSNIS" = "PRÓXIMO PASSO",
  "TAIP PAT SVARBU" = "TAMBÉM RELEVANTE",
  "Įgūdis:" = "Habilidade:",
  "Siūloma darbo eiga:" = "Fluxo de Trabalho Sugerido:",
  "Pradėkite su PIMS:" = "Comece com PIMS:",
  "Apibrėžkite projekto tikslus, suinteresuotas šalis ir laikotarpį" = "Defina os objetivos do projeto, as partes interessadas e o cronograma",
  "Sukurkite savo SES modelį:" = "Construa o seu modelo SES:",
  "Naudokite ISA duomenų įvedimą DAPSI(W)R(M) elementams susieti" = "Use a entrada de dados ISA para mapear elementos DAPSI(W)R(M)",
  "Vizualizuoti ir analizuoti:" = "Visualizar e Analisar:",
  "Sukurkite CLD tinklus ir paleiskite analizės priemones" = "Crie redes CLD e execute ferramentas de análise",
  "Patobulinti ir komunikuoti:" = "Refinar e Comunicar:",
  "Supaprastinkite modelius ir sukurkite valdymo scenarijus" = "Simplifique modelos e desenvolva cenários de gestão",
  "Pradėti iš naujo" = "Recomeçar",
  "Pradėti naują kelią nuo pasveikimo ekrano" = "Iniciar um novo percurso a partir do ecrã de boas-vindas",
  "Eksportuoti kelio ataskaitą" = "Exportar Relatório do Percurso",
  "Atsisiųskite PDF santrauką savo kelio ir rekomendacijų" = "Descarregue um resumo PDF do seu percurso e recomendações",
  "Jūsų pažanga:" = "O Seu Progresso:",
  "Sveiki" = "Bem-vindo",
  "Kalba" = "Idioma",
  "Pasirinkite kalbą" = "Selecione o Idioma"
)

# Replace Lithuanian with Portuguese
for (i in seq_along(trans$translation)) {
  if (!is.null(trans$translation[[i]]$pt)) {
    lt_text <- trans$translation[[i]]$pt
    if (!is.null(portuguese_translations[[lt_text]])) {
      trans$translation[[i]]$pt <- portuguese_translations[[lt_text]]
    }
  }
}

# Write back to file
write_json(trans, "translation.json", pretty = TRUE, auto_unbox = TRUE)

cat("Portuguese translations updated successfully!\n")
