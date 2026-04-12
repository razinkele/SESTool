<div class="alert alert-info" role="alert">
<strong>Nota:</strong> Este guia foi traduzido automaticamente do inglês utilizando Claude AI.
Se detetar erros, por favor comunique-os à equipa do projeto MarineSABRES.
<em>Estado da tradução: Rascunho (tradução automática, pendente de revisão)</em>
</div>

# Módulo de Introdução de Dados ISA - Guia do Utilizador {#isa-data-entry-module---user-guide}

## Ferramenta de Análise de Sistemas Socioecológicos MarineSABRES {#marinesabres-social-ecological-systems-analysis-tool}

**Version:** 1.0
**Última Atualização:** Abril de 2026

---

## Índice {#table-of-contents}

1. [Introdução](#introduction)
2. [Primeiros Passos](#getting-started)
3. [O Quadro DAPSI(W)R(M)](#the-dapsiwrm-framework)
4. [Fluxo de Trabalho Passo a Passo](#step-by-step-workflow)
5. [Guia Exercício a Exercício](#exercise-by-exercise-guide)
6. [Trabalhar com Kumu](#working-with-kumu)
7. [Gestão de Dados](#data-management)
8. [Dicas e Boas Práticas](#tips-and-best-practices)
9. [Resolução de Problemas](#troubleshooting)
10. [Glossário](#glossary)

---

## Introdução {#introduction}

### O que é o Módulo ISA?

O módulo de Introdução de Dados da Análise Integrada de Sistemas (ISA) é uma ferramenta abrangente para analisar sistemas socioecológicos marinhos utilizando o quadro DAPSI(W)R(M). Guia-o através de um processo sistemático de 13 exercícios para:

- Mapear a estrutura do seu sistema socioecológico marinho
- Identificar relações causais entre atividades humanas e alterações nos ecossistemas
- Compreender ciclos de retroação e dinâmicas do sistema
- Identificar pontos de alavancagem para intervenções políticas
- Criar Diagramas de Ciclos Causais (CLD) visuais
- Validar resultados com partes interessadas

### Quem Deve Usar Esta Ferramenta?

- Gestores de ecossistemas marinhos e decisores políticos
- Cientistas e investigadores ambientais
- Planeadores de zonas costeiras
- Profissionais de conservação
- Grupos de partes interessadas envolvidos na gestão marinha
- Estudantes de sistemas socioecológicos marinhos

### Funcionalidades Principais

- **Fluxo de trabalho estruturado:** 13 exercícios guiam-no sistematicamente através da análise
- **Ajuda integrada:** Ajuda contextual para cada exercício
- **Exportação de dados:** Exportação para Excel e software de visualização Kumu
- **Gráficos BOT:** Visualizar dinâmicas temporais com gráficos de Comportamento ao Longo do Tempo (Behaviour Over Time)
- **Flexível:** Importar/exportar dados, guardar progresso, colaborar com equipas

---

## Primeiros Passos {#getting-started}

### Aceder ao Módulo ISA

1. Inicie a aplicação Shiny MarineSABRES
2. No menu lateral, selecione **"ISA Data Entry"**
3. Verá a interface principal do ISA com separadores de exercícios

### Visão Geral da Interface

A interface do módulo ISA consiste em:

- **Cabeçalho:** Título e descrição do quadro com botão de ajuda principal
- **Separadores de Exercícios:** 13 exercícios mais gráficos BOT e Gestão de Dados
- **Botões de Ajuda:** Clique no ícone de ajuda (?) em qualquer exercício para orientação detalhada
- **Formulários de Entrada:** Formulários dinâmicos para introdução de dados
- **Tabelas de Dados:** Visualize os seus dados introduzidos em tabelas ordenáveis e pesquisáveis
- **Botões de Guardar:** Guarde o seu trabalho após completar cada exercício

### Obter Ajuda

**Guia Principal do Quadro:** Clique no botão "ISA Framework Guide" no topo para uma visão geral do DAPSI(W)R(M).

**Ajuda Específica por Exercício:** Clique no botão "Help" dentro de cada separador de exercício para instruções detalhadas, exemplos e dicas.

---

## O Quadro DAPSI(W)R(M) {#the-dapsiwrm-framework}

### Visão Geral

DAPSI(W)R(M) é um quadro causal para analisar sistemas socioecológicos marinhos:

- **D** - **Forças Motrizes (Drivers):** Forças subjacentes que motivam as atividades humanas (económicas, sociais, tecnológicas, políticas)
- **A** - **Atividades (Activities):** Usos humanos dos ambientes marinhos e costeiros
- **P** - **Pressões (Pressures):** Fatores de stress diretos sobre o ambiente marinho
- **S** - **Alterações de Estado (State Changes):** Alterações na condição do ecossistema, representadas através de:
  - **W** - **Bem-Estar (Welfare):** Bens e Benefícios derivados do ecossistema
  - **ES** - **Serviços Ecossistémicos (Ecosystem Services):** Benefícios que os ecossistemas proporcionam às pessoas
  - **MPF** - **Processos e Funcionamento Marinhos (Marine Processes & Functioning):** Processos biológicos, químicos e físicos
- **R** - **Respostas (Responses):** Ações da sociedade para resolver problemas
- **M** - **Medidas (Measures):** Intervenções políticas e ações de gestão

### A Cadeia Causal

O quadro representa uma cadeia causal:

```
Forças Motrizes → Atividades → Pressões → Alterações de Estado (MPF → ES → Bem-Estar) → Respostas
    ↑                                                                                        ↓
    └──────────────────────── Ciclo de Retroação ───────────────────────────────────────────┘
```

### Porquê DAPSI(W)R(M)?

- **Sistemático:** Garante uma cobertura abrangente de todos os componentes do sistema
- **Causal:** Explicita as ligações entre ações humanas e alterações nos ecossistemas
- **Circular:** Captura ciclos de retroação entre ecossistema e sociedade
- **Relevante para políticas:** Liga-se diretamente a pontos de intervenção (Respostas/Medidas)
- **Amplamente utilizado:** Quadro padrão na política marinha europeia (MSFD, WFD)

---

## Fluxo de Trabalho Passo a Passo {#step-by-step-workflow}

### Sequência Recomendada

Siga os exercícios por ordem para melhores resultados:

**Fase 1: Definição do Âmbito (Exercise 0)**
- Defina os limites e o contexto do seu estudo de caso

**Fase 2: Construção da Cadeia Causal (Exercises 1-5)**
- Trabalhe de trás para a frente, dos impactos no bem-estar até às causas raiz
- Exercise 1: Bens e Benefícios (o que as pessoas valorizam)
- Exercise 2a: Serviços Ecossistémicos (como os ecossistemas proporcionam benefícios)
- Exercise 2b: Processos Marinhos (funções ecológicas subjacentes)
- Exercise 3: Pressões (fatores de stress sobre o ecossistema)
- Exercise 4: Atividades (usos humanos do ambiente marinho)
- Exercise 5: Forças Motrizes (forças que motivam as atividades)

**Fase 3: Fechar o Ciclo (Exercise 6)**
- Ligar as forças motrizes de volta aos bens e benefícios para criar ciclos de retroação

**Fase 4: Visualização (Exercises 7-9)**
- Criar Diagramas de Ciclos Causais em Kumu
- Exportar e refinar o seu modelo visual

**Fase 5: Análise e Validação (Exercises 10-12)**
- Refinar o seu modelo (clarificação)
- Identificar pontos de alavancagem
- Validar com partes interessadas

**Contínuo: Gráficos BOT**
- Adicionar dados temporais sempre que disponíveis
- Usar para validar hipóteses causais

### Requisitos de Tempo

**Análise rápida:** 4-8 horas (estudo de caso simplificado, equipa pequena)

**Análise abrangente:** 2-4 dias (estudo de caso complexo, envolvimento de partes interessadas)

**Processo participativo completo:** 1-2 semanas (múltiplos workshops, validação extensiva)

### Trabalhar em Equipa

**Trabalho individual:**
- Uma pessoa introduz os dados com base em revisão de literatura e conhecimento especializado

**Trabalho colaborativo:**
- Exportar/importar ficheiros Excel para partilhar dados
- Utilizar as funcionalidades colaborativas do Kumu para desenvolvimento de CLD
- Realizar workshops para recolher contributos para os exercícios

---

## Guia Exercício a Exercício {#exercise-by-exercise-guide}

### Exercise 0: Desdobrar a Complexidade e os Impactos no Bem-Estar {#exercise-0-unfolding-complexity-and-impacts-on-welfare}

**Objetivo:** Definir o contexto e os limites da sua análise.

**O que Introduzir:**
- Nome do Estudo de Caso
- Descrição Breve
- Âmbito Geográfico (ex.: "Mar Báltico", "Costa do Atlântico Norte")
- Âmbito Temporal (ex.: "2000-2024")
- Impactos no Bem-Estar (observações iniciais)
- Partes Interessadas Principais

**Dicas:**
- Seja abrangente mas conciso
- Considere perspetivas diversas (ambiental, económica, social, cultural)
- Inclua tanto benefícios como custos
- Liste todas as partes interessadas afetadas e decisoras

**Exemplo:**
```
Caso: Pesca Comercial no Mar Báltico
Âmbito Geográfico: Bacia do Mar Báltico
Âmbito Temporal: 2000-2024
Impactos no Bem-Estar: Rendimento da captura de peixe, emprego, segurança alimentar,
                       património cultural, declínio dos stocks
Partes Interessadas: Pescadores comerciais, comunidades costeiras, processadores,
                     consumidores, ONG, gestores de pescas, decisores políticos da UE
```

---

### Exercise 1: Especificar Bens e Benefícios (G&B) {#exercise-1-specifying-goods-and-benefits}

**Objetivo:** Identificar o que as pessoas valorizam do ecossistema marinho.

**O que Introduzir para Cada Bem/Benefício:**
- **Nome:** Nome claro e específico (ex.: "Captura comercial de bacalhau")
- **Tipo:** Aprovisionamento / Regulação / Cultural / Suporte
- **Descrição:** O que este benefício proporciona
- **Parte Interessada:** Quem beneficia?
- **Importância:** Alta / Média / Baixa
- **Tendência:** Crescente / Estável / Decrescente / Desconhecida

**Como Usar:**
1. Clique em "Add Good/Benefit"
2. Preencha todos os campos
3. Clique em "Save Exercise 1" para atualizar a tabela
4. Cada G&B recebe automaticamente um ID único (GB001, GB002, etc.)

**Exemplos:**

| Nome | Tipo | Parte Interessada | Importância |
|------|------|-------------------|-------------|
| Desembarques de peixe comercial | Aprovisionamento | Pescadores, consumidores | Alta |
| Recreação costeira | Cultural | Turistas, residentes | Alta |
| Proteção contra tempestades | Regulação | Proprietários costeiros | Alta |
| Sequestro de carbono | Regulação | Sociedade global | Média |

**Dicas:**
- Seja específico: "Pesca comercial de bacalhau" e não apenas "pesca"
- Inclua benefícios de mercado (venda de peixe) e fora do mercado (recreação)
- Considere benefícios para diferentes grupos de partes interessadas
- Pense em sinergias e compromissos

---

### Exercise 2a: Serviços Ecossistémicos (ES) que Afetam Bens e Benefícios {#exercise-2a-ecosystem-services}

**Objetivo:** Identificar a capacidade do ecossistema para gerar benefícios.

**O que Introduzir para Cada Serviço Ecossistémico:**
- **Nome:** Nome do serviço
- **Tipo:** Classificação do serviço
- **Descrição:** Como funciona
- **Ligação a G&B:** Selecionar do menu suspenso (bens/benefícios do Ex. 1)
- **Mecanismo:** Como é que este serviço produz o benefício?
- **Confiança:** Alta / Média / Baixa

**Compreender ES vs G&B:**
- **Serviço Ecossistémico:** O potencial/capacidade (ex.: "Produtividade do stock pesqueiro")
- **Bem/Benefício:** O benefício realizado (ex.: "Captura comercial de peixe")

**Como Usar:**
1. Clique em "Add Ecosystem Service"
2. Preencha os campos
3. Selecione qual G&B este ES suporta (o menu suspenso mostra todos os G&B do Exercise 1)
4. Clique em "Save Exercise 2a"

**Exemplos:**

| Nome do ES | Ligação a G&B | Mecanismo |
|------------|---------------|-----------|
| Recrutamento do stock pesqueiro | Captura comercial de peixe | Sucesso de desova → biomassa pescável |
| Filtração por bivalves | Qualidade da água para turismo | Mexilhões filtram partículas → água límpida |
| Habitat de ervas marinhas | Berçário para espécies comerciais | Abrigo para juvenis → stock de peixe adulto |

**Dicas:**
- Um G&B pode ser suportado por múltiplos ES
- Um ES pode suportar múltiplos G&B
- Descreva claramente o mecanismo (ajuda na validação)
- Utilize conhecimento científico e contributos das partes interessadas

---

### Exercise 2b: Processos e Funcionamento Marinhos (MPF) {#exercise-2b-marine-processes-and-functioning}

**Objetivo:** Identificar os processos ecológicos fundamentais que suportam os serviços ecossistémicos.

**O que Introduzir para Cada Processo Marinho:**
- **Nome:** Nome do processo
- **Tipo:** Biológico / Químico / Físico / Ecológico
- **Descrição:** O que este processo faz
- **Ligação a ES:** Selecionar do menu suspenso (ES do Ex. 2a)
- **Mecanismo:** Como é que este processo gera o serviço?
- **Escala Espacial:** Onde ocorre (local/regional/bacia)

**Tipos de Processos Marinhos:**
- **Biológicos:** Produção primária, predação, reprodução, migração
- **Químicos:** Ciclo de nutrientes, sequestro de carbono, regulação do pH
- **Físicos:** Circulação de água, transporte de sedimentos, ação das ondas
- **Ecológicos:** Estrutura de habitat, dinâmicas da teia alimentar, biodiversidade

**Como Usar:**
1. Clique em "Add Marine Process"
2. Preencha os campos
3. Selecione qual ES este MPF suporta
4. Clique em "Save Exercise 2b"

**Exemplos:**

| Nome do MPF | Tipo | Ligação a ES | Mecanismo |
|-------------|------|--------------|-----------|
| Produção primária fitoplanctónica | Biológico | Produtividade do stock pesqueiro | Luz + nutrientes → biomassa → teia alimentar |
| Fotossíntese de ervas marinhas | Biológico | Armazenamento de carbono | Absorção de CO2 → matéria orgânica → enterramento em sedimentos |
| Filtração por bancos de mexilhão | Ecológico | Claridade da água | Alimentação por filtração remove partículas |

**Dicas:**
- Concentre-se nos processos relevantes para os seus ES
- Utilize conhecimento científico especializado
- Considere escalas espaciais e temporais
- Múltiplos processos podem contribuir para um ES

---

### Exercise 3: Especificar Pressões sobre Alterações de Estado {#exercise-3-specifying-pressures}

**Objetivo:** Identificar fatores de stress que afetam os processos marinhos.

**O que Introduzir para Cada Pressão:**
- **Nome:** Nome claro da pressão
- **Tipo:** Física / Química / Biológica / Múltipla
- **Descrição:** Natureza do fator de stress
- **Ligação a MPF:** Selecionar do menu suspenso (MPF do Ex. 2b)
- **Intensidade:** Alta / Média / Baixa / Desconhecida
- **Espacial:** Onde ocorre
- **Temporal:** Quando/com que frequência (contínua/sazonal/episódica)

**Tipos de Pressões:**
- **Físicas:** Abrasão do fundo marinho, perda de habitat, ruído, calor
- **Químicas:** Enriquecimento em nutrientes, contaminantes, acidificação
- **Biológicas:** Remoção de espécies, espécies invasoras, patogénios
- **Múltiplas:** Efeitos combinados

**Como Usar:**
1. Clique em "Add Pressure"
2. Preencha os campos
3. Selecione qual MPF esta pressão afeta
4. Avalie a intensidade e descreva os padrões espaciais/temporais
5. Clique em "Save Exercise 3"

**Exemplos:**

| Nome da Pressão | Tipo | Ligação a MPF | Intensidade |
|-----------------|------|---------------|-------------|
| Enriquecimento em nutrientes | Química | Composição fitoplanctónica | Alta |
| Arrasto de fundo | Física | Estrutura do habitat bentónico | Alta |
| Sobrepesca | Biológica | Dinâmicas da teia alimentar | Média |

**Dicas:**
- Uma pressão pode afetar múltiplos processos
- Especifique o mecanismo direto
- Considere efeitos cumulativos
- Inclua pressões crónicas e agudas
- Utilize evidência científica para classificações de intensidade

---

### Exercise 4: Especificar Atividades que Afetam Pressões {#exercise-4-specifying-activities}

**Objetivo:** Identificar atividades humanas que geram pressões.

**O que Introduzir para Cada Atividade:**
- **Nome:** Nome claro
- **Setor:** Pescas / Aquacultura / Turismo / Transporte Marítimo / Energia / Mineração / Outro
- **Descrição:** O que a atividade envolve
- **Ligação a Pressão:** Selecionar do menu suspenso (pressões do Ex. 3)
- **Escala:** Local / Regional / Nacional / Internacional
- **Frequência:** Contínua / Sazonal / Ocasional / Pontual

**Atividades Marinhas Comuns:**
- **Pescas:** Pesca comercial/recreativa/de subsistência
- **Aquacultura:** Aquacultura de peixe/bivalves
- **Turismo:** Turismo balnear, observação de fauna, mergulho
- **Transporte Marítimo:** Carga, cruzeiros, ferries
- **Energia:** Eólica offshore, petróleo e gás, marés/ondas
- **Infraestruturas:** Portos, construção costeira
- **Agricultura:** Escoamento de nutrientes (terrestre mas com impacto marinho)

**Como Usar:**
1. Clique em "Add Activity"
2. Preencha os campos
3. Selecione qual(is) pressão(ões) esta atividade gera
4. Especifique escala e frequência
5. Clique em "Save Exercise 4"

**Exemplos:**

| Nome da Atividade | Setor | Ligação a Pressão | Escala |
|-------------------|-------|-------------------|--------|
| Pesca de arrasto de fundo | Pescas | Abrasão do fundo marinho | Regional |
| Descarga de águas residuais costeiras | Resíduos | Enriquecimento em nutrientes | Local |
| Tráfego marítimo | Transporte Marítimo | Ruído subaquático, poluição por petróleo | Internacional |

**Dicas:**
- Seja específico: "Arrasto de fundo" e não apenas "Pesca"
- Uma atividade frequentemente gera múltiplas pressões
- Considere vias diretas e indiretas
- Inclua padrões sazonais

---

### Exercise 5: Forças Motrizes que Dão Origem a Atividades {#exercise-5-drivers}

**Objetivo:** Identificar as forças subjacentes que motivam as atividades.

**O que Introduzir para Cada Força Motriz:**
- **Nome:** Nome claro
- **Tipo:** Económico / Social / Tecnológico / Político / Ambiental / Demográfico
- **Descrição:** O que é esta força e como funciona
- **Ligação a Atividade:** Selecionar do menu suspenso (atividades do Ex. 4)
- **Tendência:** Crescente / Estável / Decrescente / Cíclica / Incerta
- **Controlabilidade:** Alta / Média / Baixa / Nenhuma

**Tipos de Forças Motrizes:**
- **Económicas:** Procura de mercado, preços, subsídios, crescimento económico
- **Sociais:** Tradições culturais, preferências dos consumidores, normas sociais
- **Tecnológicas:** Inovação de equipamentos, eficiência de embarcações, novas técnicas
- **Políticas:** Regulamentações, governança, acordos internacionais
- **Ambientais:** Alterações climáticas, fenómenos meteorológicos extremos (como forças motrizes de adaptação)
- **Demográficas:** Crescimento populacional, urbanização, migração

**Como Usar:**
1. Clique em "Add Driver"
2. Preencha os campos
3. Selecione qual(is) atividade(s) esta força motriz motiva
4. Avalie a tendência e a controlabilidade
5. Clique em "Save Exercise 5"

**Exemplos:**

| Nome da Força Motriz | Tipo | Ligação a Atividade | Controlabilidade |
|----------------------|------|---------------------|------------------|
| Procura global de produtos do mar | Económico | Expansão da pesca comercial | Baixa |
| Metas de energia renovável da UE | Político | Desenvolvimento eólico offshore | Alta |
| Procura de turismo costeiro | Social/Económico | Desenvolvimento costeiro | Média |

**Dicas:**
- Pense no PORQUÊ de as pessoas se envolverem nas atividades
- Considere fatores de impulso e atração
- As forças motrizes interagem frequentemente (económicas + tecnológicas + políticas)
- Avalie a controlabilidade honestamente
- As forças motrizes são frequentemente os melhores pontos de intervenção

---

### Exercise 6: Fechar o Ciclo - Forças Motrizes a Bens e Benefícios {#exercise-6-closing-the-loop}

**Objetivo:** Criar ciclos de retroação ligando as forças motrizes de volta aos bens e benefícios.

**O que Identificar:**
- Como é que as alterações nos Bens e Benefícios influenciam as Forças Motrizes?
- Como é que as Forças Motrizes respondem às condições do ecossistema?
- Quais retroações são reforçadoras (amplificadoras)?
- Quais são equilibradoras (estabilizadoras)?

**Tipos de Ciclos de Retroação:**

**Ciclos Reforçadores (R):** As alterações amplificam-se a si mesmas
- Exemplo: Declínio dos stocks pesqueiros → Lucros menores → Mais esforço de pesca para manter o rendimento → Declínio adicional

**Ciclos Equilibradores (B):** As alterações desencadeiam respostas compensatórias
- Exemplo: Declínio da qualidade da água → Redução do turismo → Pressão económica para limpeza → Melhoria da qualidade

**Como Usar:**
1. Reveja a interface de ligações do ciclo
2. Selecione as ligações força motriz-a-G&B que criam retroações significativas
3. Documente se as retroações são reforçadoras ou equilibradoras
4. Clique em "Save Exercise 6"

**Exemplos:**

| De (G&B) | Para (Força Motriz) | Tipo | Explicação |
|----------|---------------------|------|------------|
| Declínio da captura de peixe | Redução da capacidade pesqueira | Equilibrador | Lucros baixos afastam pescadores da indústria |
| Melhoria da qualidade da água | Apoio político à conservação | Reforçador | O sucesso gera mais políticas de conservação |
| Danos costeiros por tempestades | Política de restauração de ecossistemas | Equilibrador | As perdas desencadeiam medidas de proteção |

**Dicas:**
- Nem todas as forças motrizes precisam de ser reconectadas
- Considere desfasamentos temporais (anos para se manifestarem)
- O conhecimento das partes interessadas é crucial
- Documente o tipo de ciclo (R ou B)

---

### Exercises 7-9: Criação e Exportação de Diagramas de Ciclos Causais {#exercises-7-9-cld-creation}

**Objetivo:** Visualizar a estrutura do seu sistema no software Kumu.

#### Exercise 7: Criar CLD Baseado em Impactos em Kumu

**Passos:**
1. Clique em "Download Kumu CSV Files" para exportar os seus dados
2. Vá a [kumu.io](https://kumu.io) e crie uma conta gratuita
3. Crie um novo projeto (escolha o modelo "Causal Loop Diagram")
4. Importe os seus ficheiros CSV:
   - `elements.csv` → contém todos os nós
   - `connections.csv` → contém todas as ligações
5. Aplique o código de estilização Kumu de `Documents/Kumu_Code_Style.txt`
6. Organize os elementos para mostrar fluxos causais claros

**Esquema de Cores Kumu:**
- Bens e Benefícios: Triângulos amarelos
- Serviços Ecossistémicos: Quadrados azuis
- Processos Marinhos: Cápsulas azuis claras
- Pressões: Losangos laranja
- Atividades: Hexágonos verdes
- Forças Motrizes: Octógonos roxos

#### Exercise 8: Das Cadeias de Lógica Causal aos Ciclos Causais

**Passos:**
1. No Kumu, identifique ciclos fechados no seu diagrama
2. Trace percursos de um elemento de volta a si mesmo
3. Classifique os ciclos como reforçadores (R) ou equilibradores (B)
4. Adicione identificadores de ciclo no Kumu (use etiquetas ou tags)
5. Concentre-se nos ciclos mais importantes que determinam o comportamento do sistema

**Identificar o Tipo de Ciclo:**
- Conte o número de ligações negativas (-) no ciclo
- Número par de ligações (-) = Reforçador (R)
- Número ímpar de ligações (-) = Equilibrador (B)

#### Exercise 9: Exportar CLD para Análise Posterior

**Passos:**
1. Exporte imagens de alta resolução do Kumu:
   - Clique em Share → Export → PNG/PDF
2. Descarregue o livro de trabalho Excel completo do módulo ISA
3. Reveja as matrizes de adjacência para verificar todas as ligações
4. Crie diferentes vistas:
   - Vista do sistema completo
   - Vistas de subsistemas (ex.: apenas pescas)
   - Vistas de ciclos-chave
5. Documente os ciclos-chave com descrições narrativas

**Clique em "Save Exercises 7-9" quando terminar.**

---

### Exercises 10-12: Clarificação, Métricas e Validação {#exercises-10-12-clarifying-metrics-validation}

#### Exercise 10: Clarificação - Endogeneização e Encapsulamento

**Endogeneização:** Trazer fatores externos para dentro dos limites do sistema

**O que Fazer:**
1. Reveja as forças motrizes externas
2. Alguma pode ser explicada por fatores dentro do seu sistema?
3. Adicione estas retroações internas
4. Documente em "Notas de Endogeneização"

**Exemplo:** "Procura de mercado" pode ser influenciada pela "qualidade do produto" dentro do seu sistema

**Encapsulamento:** Agrupar processos detalhados em conceitos de nível superior

**O que Fazer:**
1. Identifique subsistemas excessivamente complexos
2. Agrupe elementos relacionados (ex.: múltiplos processos de nutrientes → "Dinâmicas de eutrofização")
3. Mantenha a versão detalhada para trabalho técnico
4. Crie uma versão simplificada para comunicação política
5. Documente em "Notas de Encapsulamento"

#### Exercise 11: Métricas, Causas Raiz e Pontos de Alavancagem

**Análise de Causas Raiz:**
1. Utilize a interface "Root Causes"
2. Identifique elementos com muitas ligações de saída
3. Trace de trás para a frente desde os problemas até às causas últimas
4. Concentre-se nas forças motrizes e atividades

**Identificação de Pontos de Alavancagem:**
1. Utilize a interface "Leverage Points"
2. Procure:
   - Pontos de controlo de ciclos
   - Nós de alta centralidade (muitas ligações)
   - Pontos de convergência (múltiplos percursos se encontram)
3. Considere viabilidade e controlabilidade
4. Priorize pontos de alavancagem acionáveis

**Hierarquia de Meadows:**
- Mais fraco: Parâmetros (números, taxas)
- Mais forte: Ciclos de retroação
- Muito forte: Conceção/estrutura do sistema
- O mais forte: Paradigmas (mentalidades, objetivos)

#### Exercise 12: Apresentar e Validar Resultados

**Abordagens de Validação:**
- ✓ Revisão interna da equipa
- ✓ Workshop com partes interessadas
- ✓ Revisão por pares especialistas
- ✓ Aprovação final

**O que Fazer:**
1. Realize atividades de validação
2. Registe o feedback em "Notas de Validação"
3. Assinale as caixas para os tipos de validação completados
4. Atualize o seu modelo com base no feedback
5. Prepare apresentações para diferentes audiências

**Dicas de Apresentação:**
- Adapte a complexidade à audiência
- Utilize o CLD visual para visão geral
- Conte histórias sobre os ciclos-chave
- Mostre gráficos BOT como evidência
- Ligue a recomendações políticas
- Seja transparente sobre incertezas

**Clique em "Save Exercises 10-12" quando terminar.**

---

### Gráficos BOT: Comportamento ao Longo do Tempo {#bot-graphs-behaviour-over-time}

**Objetivo:** Visualizar dinâmicas temporais para validar o seu modelo causal.

**Como Criar Gráficos BOT:**

1. **Selecionar Tipo de Elemento:** Escolha do menu suspenso (Bens e Benefícios / ES / MPF / Pressões / Atividades / Forças Motrizes)
2. **Selecionar Elemento Específico:** Escolha qual elemento representar graficamente
3. **Adicionar Pontos de Dados:**
   - Ano
   - Valor
   - Unidade (ex.: "toneladas", "%", "índice")
   - Clique em "Add Data Point"
4. **Ver Gráfico:** A série temporal aparece automaticamente
5. **Repetir** para outros elementos

**Padrões a Procurar:**
- **Tendências:** Aumento/diminuição constante
- **Ciclos:** Oscilações regulares
- **Degraus:** Alterações súbitas (mudanças políticas)
- **Atrasos:** Desfasamentos temporais
- **Limiares:** Pontos de viragem
- **Planaltos:** Estabilidade

**Utilizar Gráficos BOT:**
- Comparar padrões com as previsões do CLD
- Identificar evidências de ciclos de retroação
- Medir atrasos temporais
- Avaliar intervenções políticas
- Projetar cenários futuros

**Fontes de Dados:**
- Estatísticas oficiais
- Monitorização ambiental
- Inquéritos científicos
- Observações das partes interessadas
- Registos históricos

**Clique em "Save BOT Data" para preservar o seu trabalho.**

---

## Trabalhar com Kumu {#working-with-kumu}

### Começar com o Kumu

**1. Criar Conta:**
- Vá a [kumu.io](https://kumu.io)
- Registe-se para uma conta gratuita
- Projetos públicos são gratuitos; projetos privados requerem subscrição

**2. Criar Novo Projeto:**
- Clique em "New Project"
- Escolha o modelo "Causal Loop Diagram"
- Dê nome ao seu projeto

**3. Importar Dados:**
- Do módulo ISA, descarregue os ficheiros CSV para Kumu
- No Kumu, clique em Import
- Carregue `elements.csv` e `connections.csv`

### Aplicar Estilização Personalizada

**Copiar o Código Kumu:**
- Abra `Documents/Kumu_Code_Style.txt`
- Copie todo o conteúdo

**Aplicar ao Seu Mapa:**
1. No Kumu, clique no ícone de Definições
2. Vá a "Advanced Editor"
3. Cole o código
4. Clique em "Save"

**Resultado:** Os seus elementos serão codificados por cor e forma por tipo:
- Bens e Benefícios: Triângulos amarelos
- Serviços Ecossistémicos: Quadrados azuis
- Processos Marinhos: Cápsulas azuis claras
- Pressões: Losangos laranja
- Atividades: Hexágonos verdes
- Forças Motrizes: Octógonos roxos

### Trabalhar com o Diagrama

**Opções de Disposição:**
- Disposição automática: Deixe o Kumu organizar os elementos
- Manual: Arraste elementos para posições preferidas
- Circular: Enfatizar a estrutura de ciclos
- Hierárquica: Mostrar fluxo causal das forças motrizes ao bem-estar

**Adicionar Informação:**
- Clique em qualquer elemento para editar propriedades
- Adicione descrições, tags, campos personalizados
- Inclua fontes de dados, níveis de confiança

**Destacar Ciclos:**
1. Identifique um percurso de ciclo fechado
2. Adicione uma tag "Loop" a todos os elementos do ciclo
3. Utilize o filtro do Kumu para mostrar/ocultar ciclos
4. Etiquete ciclos (ex.: "R1: Espiral de Sobrepesca", "B1: Recuperação da Qualidade")

**Filtros e Vistas:**
- Filtrar por tipo de elemento (mostrar apenas Forças Motrizes)
- Filtrar por importância, confiança, etc.
- Criar múltiplas vistas (sistema completo, ciclos-chave, subsistemas)
- Guardar vistas para apresentações

### Colaboração

**Partilha:**
- Partilhar link de visualização com partes interessadas
- Exportar capturas de ecrã para relatórios
- Incorporar em websites/apresentações

**Edição em Equipa:**
- Adicionar colaboradores (funcionalidade paga)
- Múltiplas pessoas podem editar simultaneamente
- Controlo de versões disponível

### Opções de Exportação

**Do Kumu:**
- **PNG:** Imagem de alta resolução para relatórios
- **PDF:** Formato vetorial para publicações
- **JSON:** Dados brutos para arquivo
- **Link de partilha:** Vista web interativa

**Do Módulo ISA:**
- **Livro de trabalho Excel:** Dados completos com todas as folhas
- **CSV para Kumu:** Elementos e ligações
- **Matrizes de adjacência:** Matrizes de ligações para análise

---

## Gestão de Dados {#data-management}

### Guardar o Seu Trabalho

**Gravação automática:**
- Os dados são armazenados no estado reativo da aplicação durante a sua sessão
- Utilize os botões "Save" após completar cada exercício

**Exportar para Excel:**
1. Vá ao separador "Data Management"
2. Introduza o nome do ficheiro (ex.: "MeuCaso_ISA_2024")
3. Clique em "Export to Excel"
4. Descarrega o livro de trabalho completo com todos os dados

### Importar Dados Existentes

**Do Excel:**
1. Vá ao separador "Data Management"
2. Clique em "Choose Excel File"
3. Selecione o seu ficheiro .xlsx previamente exportado
4. Clique em "Import Data"
5. Os dados preenchem todos os exercícios

**Estrutura do Ficheiro Excel:**
- Folha: Case_Info
- Folha: Goods_Benefits
- Folha: Ecosystem_Services
- Folha: Marine_Processes
- Folha: Pressures
- Folha: Activities
- Folha: Drivers
- Folha: BOT_Data

### Repor Dados

**Aviso:** Isto apaga TODOS os dados e não pode ser desfeito.

1. Vá ao separador "Data Management"
2. Clique em "Reset All Data" (botão vermelho)
3. Confirme a ação
4. Todos os exercícios regressam ao estado em branco

**Quando Repor:**
- Iniciar um estudo de caso completamente novo
- Descartar uma execução de prática
- Após exportar dados que deseja manter

### Fluxos de Trabalho Colaborativos

**Trabalho Individual:**
- Uma pessoa introduz todos os dados
- Exporta Excel quando terminar
- Partilha o ficheiro com a equipa para revisão

**Trabalho Sequencial:**
- Pessoa A: Exercises 0-3 → Exportar
- Pessoa B: Importar → Exercises 4-6 → Exportar
- Pessoa C: Importar → Exercises 7-12 → Exportação final

**Trabalho Paralelo:**
- Múltiplas pessoas trabalham em diferentes exercícios em sessões separadas
- Consolidar em Excel (fundir folhas manualmente)
- Importar ficheiro consolidado

**Baseado em Workshop:**
- Facilitar discussões de grupo para cada exercício
- Uma pessoa opera a ferramenta e introduz os dados de consenso
- Exportar após cada exercício para registo

---

## Dicas e Boas Práticas {#tips-and-best-practices}

### Dicas Gerais de Fluxo de Trabalho

**1. Trabalhe sistematicamente:**
- Complete os exercícios por ordem
- Não salte em frente (os exercícios posteriores baseiam-se nos anteriores)
- Guarde após cada exercício

**2. Envolva partes interessadas:**
- Realize workshops para os Exercises 1-6
- Valide o CLD com quem conhece o sistema
- Utilize perspetivas diversas (utilizadores, gestores, cientistas)

**3. Utilize evidência científica:**
- Baseie as ligações em estudos revistos por pares
- Cite fontes nas descrições
- Note os níveis de confiança

**4. Comece simples, adicione detalhe:**
- Primeira passagem: Apenas elementos principais
- Segunda passagem: Adicione nuances e detalhes
- Mantenha uma versão simplificada para comunicação

**5. Documente tudo:**
- Utilize os campos de descrição generosamente
- Registe as fontes de dados
- Note pressupostos e incertezas

### Dicas de Qualidade dos Dados

**Seja Específico:**
- ❌ "Pesca" → ✅ "Pesca comercial de arrasto de fundo para espécies demersais"
- ❌ "Poluição" → ✅ "Enriquecimento em nutrientes por escoamento agrícola"

**Seja Abrangente:**
- Inclua impactos positivos e negativos
- Considere todos os grupos de partes interessadas
- Cubra todos os setores que utilizam a área marinha

**Seja Realista:**
- Concentre-se nos elementos importantes (80% principais)
- Não tente incluir tudo
- A complexidade deve corresponder ao conhecimento disponível

**Seja Consistente:**
- Utilize terminologia consistente
- Mantenha um nível consistente de detalhe entre exercícios
- Siga convenções de nomenclatura (ex.: IDs de elementos)

### Dicas de Desenvolvimento de CLD

**Disposição:**
- Organize em fluxo causal: Forças Motrizes → Atividades → Pressões → Estado → Bem-Estar
- Coloque os ciclos de retroação em destaque
- Minimize cruzamentos de ligações para legibilidade

**Ciclos:**
- Identifique e etiquete ciclos-chave (R1, R2, B1, B2)
- Concentre-se nos ciclos que impulsionam comportamentos problemáticos
- Documente narrativas de ciclos (que história conta cada ciclo?)

**Validação:**
- O CLD explica o comportamento observado do sistema?
- As partes interessadas reconhecem a estrutura?
- Consegue traçar eventos históricos específicos através do diagrama?

### Dicas de Gráficos BOT

**Recolha de Dados:**
- Utilize as séries temporais mais longas disponíveis
- Seja consistente com unidades e escalas
- Documente as fontes de dados claramente

**Comparação:**
- Represente variáveis relacionadas no mesmo eixo temporal
- Procure correlações (correspondem ao seu CLD?)
- Identifique atrasos temporais entre causa e efeito

**Comunicação:**
- Anote com eventos-chave (mudanças políticas, desastres)
- Utilize esquemas de cores consistentes
- Inclua barras de erro ou intervalos de incerteza se disponíveis

### Armadilhas Comuns a Evitar

**1. Demasiado detalhe demasiado cedo:**
- Comece com os elementos principais
- Adicione detalhe em iterações
- Mantenha uma versão simplificada

**2. Ignorar o contributo das partes interessadas:**
- O conhecimento local é inestimável
- A legitimidade requer participação
- Pontos cegos surgem sem perspetivas diversas

**3. Confundir ES e G&B:**
- ES = capacidade/potencial do ecossistema
- G&B = benefícios realizados que as pessoas obtêm
- Exemplo: "Stock pesqueiro" (ES) vs. "Captura de peixe" (G&B)

**4. Ligações fracas:**
- Especifique sempre o mecanismo
- Evite ligações vagas
- Teste: Consegue explicar esta ligação a uma parte interessada?

**5. Ignorar o tempo:**
- Os atrasos são cruciais
- Alguns efeitos demoram anos a manifestar-se
- Os gráficos BOT revelam padrões temporais

**6. Sem ciclos de retroação:**
- O Exercise 6 é crítico
- Os sistemas são circulares, não lineares
- As retroações impulsionam as dinâmicas

**7. Ignorar a validação:**
- O seu modelo é uma hipótese
- Teste contra dados e conhecimento das partes interessadas
- Itere com base no feedback

---

## Resolução de Problemas {#troubleshooting}

### Problemas Comuns e Soluções

**Problema: "Os meus dados não foram guardados"**
- **Solução:** Clique sempre no botão "Save Exercise X" após introduzir dados
- Verifique se a tabela de dados atualiza após guardar
- Exporte para Excel frequentemente como cópia de segurança

**Problema: "As listas suspensas estão vazias"**
- **Causa:** Não completou o exercício anterior
- **Solução:** Complete os exercícios por ordem. O Ex. 2a necessita de dados do Ex. 1, etc.

**Problema: "Cometi um erro num exercício anterior"**
- **Solução:** Volte ao separador desse exercício
- Os dados ainda estão lá e são editáveis
- Faça as correções e clique em Save novamente

**Problema: "A exportação para Excel não funciona"**
- **Verifique:** As definições de transferência do navegador
- **Verifique:** As permissões de ficheiro na pasta de transferências
- **Tente:** Outro navegador

**Problema: "A importação para Kumu falha"**
- **Verifique:** O formato do ficheiro CSV (deve ser separado por vírgulas)
- **Verifique:** Os cabeçalhos das colunas correspondem às expectativas do Kumu
- **Tente:** Importar elementos primeiro, depois ligações

**Problema: "A aplicação está lenta com grandes conjuntos de dados"**
- **Normal:** 100+ elementos podem tornar a renderização lenta
- **Solução:** Trabalhe em subsistemas separadamente
- **Solução:** Utilize Excel para gestão de dados, a aplicação para estrutura

**Problema: "Não encontro o conteúdo de ajuda"**
- **Localização:** Clique no botão de Ajuda "?" em cada separador de exercício
- **Guia principal:** Clique em "ISA Framework Guide" no topo do módulo

### Obter Ajuda Adicional

**Documentação:**
- Este Guia do Utilizador
- MarineSABRES Simple SES DRAFT Guidance (pasta Documentos)
- Documentação do Kumu: [docs.kumu.io](https://docs.kumu.io)

**Suporte Técnico:**
- Verifique a versão da aplicação e compatibilidade do navegador
- Contacte a equipa do projeto MarineSABRES
- Reporte bugs via GitHub (se aplicável)

**Suporte Científico:**
- Consulte o documento de orientação para questões metodológicas
- Envolva especialistas do domínio para o seu estudo de caso específico
- Participe em workshops de formação ISA

---

## Glossário {#glossary}

**Atividades (A):** Usos humanos dos ambientes marinhos e costeiros (pesca, transporte marítimo, turismo, etc.)

**Matriz de Adjacência (Adjacency Matrix):** Tabela que mostra quais elementos estão ligados a quais outros elementos

**Ciclo Equilibrador (B):** Ciclo de retroação que contraria a mudança e estabiliza o sistema

**Gráfico BOT (Behaviour Over Time):** Gráfico de série temporal que mostra como um indicador muda ao longo do tempo

**Cadeia Causal (Causal Chain):** Sequência linear de relações causa-efeito (ex.: Forças Motrizes → Atividades → Pressões)

**Diagrama de Ciclos Causais (CLD):** Rede visual que mostra elementos e as suas relações causais, incluindo ciclos de retroação

**DAPSI(W)R(M):** Quadro Forças Motrizes-Atividades-Pressões-Estado(Bem-Estar)-Respostas(Medidas)

**Forças Motrizes (D):** Forças subjacentes que motivam atividades (económicas, sociais, políticas, tecnológicas)

**Serviços Ecossistémicos (ES):** A capacidade dos ecossistemas de gerar benefícios para as pessoas

**Encapsulamento (Encapsulation):** Agrupamento de elementos detalhados em conceitos de nível superior para simplificação

**Endogeneização (Endogenisation):** Trazer fatores externos para dentro dos limites do sistema adicionando retroações internas

**Ciclo de Retroação (Feedback Loop):** Via causal circular onde um elemento influencia a si mesmo através de uma cadeia de outros elementos

**Bens e Benefícios (G&B):** Benefícios realizados que as pessoas obtêm dos ecossistemas marinhos (impactos no bem-estar)

**ISA (Análise Integrada de Sistemas):** Quadro sistemático para analisar sistemas socioecológicos

**Kumu:** Software gratuito online de visualização de redes (kumu.io)

**Ponto de Alavancagem (Leverage Point):** Localização no sistema onde uma pequena intervenção pode produzir uma grande mudança

**Processos e Funcionamento Marinhos (MPF):** Processos biológicos, químicos, físicos e ecológicos que suportam serviços ecossistémicos

**Medidas (M):** Intervenções políticas e ações de gestão (respostas)

**Polaridade (Polarity):** Direção da influência causal (+ mesma direção, - direção oposta)

**Pressões (P):** Fatores de stress diretos sobre o ambiente marinho (poluição, destruição de habitat, remoção de espécies)

**Ciclo Reforçador (R):** Ciclo de retroação que amplifica a mudança (pode ser ciclo virtuoso ou vicioso)

**Respostas (R):** Ações da sociedade para resolver problemas

**Causa Raiz (Root Cause):** Força motriz ou atividade fundamental na origem de uma cadeia causal

**Sistema Socioecológico (SES):** Sistema integrado de pessoas e natureza, com retroações recíprocas

**Alterações de Estado (S):** Alterações na condição do ecossistema (representadas através de W, ES e MPF)

**Bem-Estar (W):** Bem-estar humano, representado através de bens e benefícios dos ecossistemas

---

## Apêndice: Cartão de Referência Rápida {#appendix-quick-reference-card}

### Lista de Verificação de Exercícios

- [ ] Exercise 0: Definir o âmbito do estudo de caso
- [ ] Exercise 1: Listar todos os Bens e Benefícios
- [ ] Exercise 2a: Identificar Serviços Ecossistémicos
- [ ] Exercise 2b: Identificar Processos e Funcionamento Marinhos
- [ ] Exercise 3: Identificar Pressões
- [ ] Exercise 4: Identificar Atividades
- [ ] Exercise 5: Identificar Forças Motrizes
- [ ] Exercise 6: Fechar ciclos de retroação
- [ ] Exercise 7: Criar CLD em Kumu
- [ ] Exercise 8: Identificar ciclos causais
- [ ] Exercise 9: Exportar e documentar CLD
- [ ] Exercise 10: Clarificar modelo (endogeneização, encapsulamento)
- [ ] Exercise 11: Identificar pontos de alavancagem
- [ ] Exercise 12: Validar com partes interessadas
- [ ] Gráficos BOT: Adicionar dados temporais
- [ ] Exportar livro de trabalho Excel final

### Atalhos de Teclado

- **Tab:** Mover entre campos do formulário
- **Enter:** Submeter/Guardar formulário
- **Ctrl+F / Cmd+F:** Pesquisar dentro de tabelas

### Localização de Ficheiros

- **Guia do Utilizador:** `Documents/ISA_User_Guide.md`
- **Documento de Orientação:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Estilização Kumu:** `Documents/Kumu_Code_Style.txt`
- **Modelo Excel:** `Documents/ISA Excel Workbook.xlsx`

### Links Úteis

- **Kumu:** [https://kumu.io](https://kumu.io)
- **Documentação Kumu:** [https://docs.kumu.io](https://docs.kumu.io)
- **Quadro DAPSI(W)R:** Elliott et al. (2017), Marine Pollution Bulletin

---

## Informação do Documento {#document-information}

**Documento:** Módulo de Introdução de Dados ISA - Guia do Utilizador
**Projeto:** Caixa de Ferramentas de Sistemas Socioecológicos MarineSABRES
**Version:** 1.0
**Data:** Abril de 2026
**Estado:** Rascunho (tradução automática)

**Citação:**
> Projeto MarineSABRES (2025). Módulo de Introdução de Dados ISA - Guia do Utilizador.
> Ferramenta de Análise de Sistemas Socioecológicos MarineSABRES, Versão 1.0.

**Licença:** Este guia é fornecido para uso com a Caixa de Ferramentas SES MarineSABRES.

---

**Para questões, feedback ou suporte, por favor contacte a equipa do projeto MarineSABRES.**

**Boas análises!**
