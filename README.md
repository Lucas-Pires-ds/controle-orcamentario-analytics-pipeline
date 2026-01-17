# 📊 Projeto de Controle Orçamentário — Pipeline ETL e Analytics

## 📌 TL;DR
- Pipeline ETL completo em **SQL Server** (Bronze → Silver → Gold)
- Forte foco em **qualidade de dados**, integridade referencial e rastreabilidade
- Modelo dimensional para análise financeira e orçamentária
- Camada Gold composta por **3 views analíticas**:
  - **Orçamento**
  - **Lançamentos**
  - **Realizado**
- Cruzamento **Orçado vs Realizado realizado no Power BI**
- Métricas prontas para consumo no **Power BI**, com mínima lógica em DAX

---

## 🧭 Visão Geral

Este projeto simula um **pipeline de dados financeiro-orçamentário**, cobrindo desde a ingestão de dados brutos até a entrega de um **modelo analítico confiável para consumo no Power BI**.

O objetivo não é apenas gerar dashboards, mas estruturar dados de forma consistente, tratando problemas reais como:
- Baixa padronização
- Falhas de integridade
- Inconsistências semânticas
- Ausência de controle de qualidade antes da análise

O pipeline foi desenvolvido utilizando **SQL Server**, **Python** e **Power BI**, com foco em decisões técnicas explícitas e defensivas, próximas do que ocorre em ambientes corporativos.

---

## 🏢 Contexto do Negócio — Sage

A **Sage** é uma empresa fictícia do setor de serviços, criada como contexto para a construção e validação do pipeline de dados apresentado neste projeto.

A empresa opera com múltiplos **centros de custo** (administrativo, operações e marketing), realiza **planejamento orçamentário mensal** e registra **lançamentos financeiros diários** relacionados a fornecedores, campanhas e despesas operacionais.

Como ocorre em muitos ambientes corporativos, a base financeira apresenta problemas recorrentes na origem dos dados, tais como:
- Baixa padronização de campos na origem
- Variações de texto e status sem padronização
- Referências inválidas a dimensões analíticas
- Ausência de validações antes do consumo analítico

O projeto foi desenvolvido para estruturar, tratar e padronizar esses dados ao longo das camadas de ETL, viabilizando uma análise confiável de **Orçado vs Realizado**, tanto em nível **mensal (visão executiva)** quanto **diário (acompanhamento intramês)**, com regras de negócio e qualidade aplicadas ainda na camada de dados.

---

## 🎯 Problema de Negócio

Empresas de serviços, como a Sage, frequentemente enfrentam desafios como:

- Dados financeiros vindos de múltiplas fontes
- Falta de validações antes da análise
- Dificuldade em garantir consistência entre categorias, centros de custo e campanhas
- Baixa confiabilidade nos indicadores financeiros e orçamentários

Este projeto resolve esses pontos ao:

- Centralizar os dados em um pipeline único
- Aplicar regras de saneamento ainda na camada de dados
- Garantir integridade referencial e semântica
- Entregar bases analíticas confiáveis para consumo no Power BI

---

## 🏗️ Arquitetura de Dados

![Arquitetura do Pipeline de Dados](docs_e_imagens/diagrama_pipeline_de_dados.png)

O projeto segue o padrão **Medallion Architecture**, com responsabilidades bem definidas por camada.

---

## 🥉 Camada Bronze (stg_)

Responsável pela ingestão dos dados brutos.

- Ingestão via **Python (Pandas) + BULK INSERT**
- Todas as colunas armazenadas como `VARCHAR(MAX)` ou `VARCHAR(200)`
- Nenhuma tipagem ou regra de negócio aplicada

**Objetivo:** garantir que a carga nunca falhe por incompatibilidade de tipos e preservar o dado original.

> Os caminhos utilizados nos comandos `BULK INSERT` são parametrizáveis e devem ser ajustados conforme o ambiente local.

---

## 🔎 Transformações via Views (vw_)

As transformações entre Bronze e Silver são feitas por meio de **Views** no SQL Server.

Benefícios:
- Ajuste de regras sem reprocessar dados físicos
- Auditoria e rastreabilidade das transformações
- Separação clara entre ingestão e tratamento

---

## 🥈 Camada Silver (dim_ e fact_)

Camada responsável pela persistência dos dados tratados.

Características:
- Dados tipados
- Aplicação de `PRIMARY KEY` e `FOREIGN KEY`
- Modelo dimensional em **Star Schema**

Essa camada representa a base confiável para consumo analítico.

---

## ✅ Framework de Qualidade de Dados

Antes da carga definitiva na Silver, foi realizado **Data Profiling** por meio de queries de diagnóstico.

### Principais validações aplicadas

- **Auditoria de Espaços**
  - `LEN(col) > LEN(TRIM(col))`
- **Sanidade de IDs**
  - Identificação de valores como `"101.0"` importados como string
- **Validação de Domínio**
  - Meses fora do intervalo válido (1–12)
- **Unicidade**
  - Detecção de chaves duplicadas (`GROUP BY + HAVING COUNT(*) > 1`)

Essas validações evitam erros silenciosos e garantem confiabilidade antes da persistência física.

---

## 📈 Resultados do Processo de ETL

O processo de ETL não teve como objetivo apenas mover dados entre camadas, mas **sanear, padronizar e tornar a base analítica confiável** antes do consumo no Power BI.

As intervenções realizadas ao longo das camadas Bronze, Silver e Gold foram guiadas por problemas concretos identificados no Data Profiling, com foco em reduzir risco analítico e garantir consistência dos indicadores.

---

### 🧪 Principais Tratamentos Aplicados no ETL

| Tipo de validação / tratamento      | Evidência identificada na Bronze            | Ação aplicada no ETL                           | Impacto analítico |
|------------------------------------|---------------------------------------------|------------------------------------------------|-------------------|
| Datas nulas                        | Registros sem referência temporal            | Descarte controlado ainda na View              | Evita distorções em análises temporais |
| Centros de custo inválidos         | IDs inexistentes nas dimensões               | Uso de membro coringa `-1 (NÃO IDENTIFICADO)`  | Preserva valores financeiros sem violar FKs |
| IDs com resíduos decimais          | Strings no formato `"101.0"`                 | Conversão `FLOAT → INT`                        | Garante integridade das chaves |
| Status de pagamento inconsistentes | Variações de case, gênero e idioma           | Normalização semântica via `CASE WHEN`         | Indicadores consistentes no dashboard |
| Valores com sinal inconsistente    | Valores negativos sem estorno associado      | Tratamento com `ABS()` e redundância defensiva | Evita interpretação financeira incorreta |
| Espaços e ruídos textuais          | Strings com espaços extras                   | Aplicação de `TRIM()` e padronização de texto  | Melhora agrupamentos e filtros |

---

### 📊 Resultado Final do Pipeline

Após a aplicação das regras de ETL e qualidade de dados:

- 100% dos registros persistidos na camada Silver respeitam regras de tipagem e integridade referencial
- O modelo dimensional pode ser consumido diretamente no Power BI, sem necessidade de tratamentos adicionais em DAX
- As métricas de **Orçado vs Realizado** refletem regras de negócio explícitas e defensivas
- O risco de erros silenciosos em análises financeiras foi mitigado ainda na camada de dados

O valor do pipeline não está apenas na visualização final, mas na **confiabilidade da base analítica construída**, garantindo que as análises reflitam o negócio de forma consistente e rastreável.

---

### Correção de Tipagem na Ingestão

Durante a ingestão, alguns identificadores numéricos foram importados como strings decimais (ex: `"101.0"`), o que impede a conversão direta para `INT` no SQL Server.

Para tratar esse cenário, foi aplicada a conversão:

CAST(CAST(col AS FLOAT) AS INT)

Essa abordagem garante a correta tipagem dos identificadores e evita falhas de conversão durante o processo de ETL.

---

### Tratamento e Padronização de Texto

Foi implementada uma lógica personalizada de padronização textual:

- Primeira letra maiúscula
- Demais letras minúsculas
- Preservação de siglas (`RH`, `TI`)
- Tratamento correto de delimitadores (`Limpeza/Conservação`)

O objetivo é melhorar a leitura analítica sem alterar o significado dos dados.

---

### Integridade e Limpeza

- Registros com IDs nulos foram identificados como causa raiz de duplicidades
- Esses registros foram descartados ainda nas Views
- Validações garantem que toda categoria possua Centro de Custo válido antes da carga

---

## 🧩 Modelo Dimensional (Silver)

O modelo foi construído seguindo o padrão **Star Schema**, priorizando clareza e performance.

### Dimensões implementadas

- `dim_centro_custo`
- `dim_categoria` (FK para centro de custo)
- `dim_camp_marketing`
- `dim_fornecedores`

---

## 📄 Tabela Fato — fact_lancamentos

A tabela `fact_lancamentos` representa os lançamentos financeiros realizados.

### Diagnóstico de Qualidade (Pré-Carga)

Durante o profiling da `stg_lancamentos`, foram identificados:

- **Integridade Temporal**
  - 27 registros sem data (~0,6%)
- **Integridade Referencial**
  - 65 registros (~1,3%) sem centro de custo válido
- **Anomalias de Sinal**
  - Valores negativos sem correspondência com estorno
- **Inconsistência Semântica**
  - Status duplicados por variação de case e gênero

---

### Decisões de Engenharia

- **Descarte Estratégico**
  - Registros sem data removidos (baixo impacto financeiro)
- **Membro Coringa**
  - Criação do registro `-1 (NÃO IDENTIFICADO)` em `dim_centro_custo`
- **Redundância Defensiva**
  - `valor`: tratado com `ABS()` e `CHECK (> 0)`
  - `valor_original`: preservado para auditoria
- **Normalização de Status**
  - Padronização para apenas `Pago` e `Aberto`

---

### Status Final da fact_lancamentos

- Chave primária definida
- Integridade referencial garantida
- 100% dos registros válidos segundo regras de negócio

---

## 🥇 Camada Gold — Decisões Analíticas

A camada Gold foi desenhada a partir das necessidades analíticas da Sage, com foco em **simplicidade, clareza semântica e redução de lógica no Power BI**.

Diferente de uma camada puramente agregada, a Gold foi estruturada em **três views analíticas independentes**, cada uma com responsabilidade bem definida.  
O **cruzamento entre orçamento e realizado é realizado no Power BI**, e não na camada de dados, por decisão arquitetural consciente.

---

### 📊 vw_gold_orcamento

Responsabilidades:

- Consolidação mensal de orçamento

- Cálculo de **YTD**

- Pesos relativos por **centro de custo** e **categoria**

- Média histórica mensal

- Flag de valores atípicos via desvio em relação à média

- Proteção contra divisão por zero (NULLIF)

- Nenhum cruzamento com realizado

### 📄 vw_gold_lancamentos

Responsabilidades:

- Visão detalhada e auditável dos lançamentos diários

- Preservação de valor_original e valor tratado

- Flags de centro de custo coringa

- Enriquecimento dimensional completo (centro de custo, categoria, fornecedor, campanha)

- Nenhuma agregação (base para drill-down)

### 📈 vw_gold_realizado

Responsabilidades:

- Consolidação mensal do realizado

- Uso consciente da dim_calendario para continuidade temporal

- Métricas avançadas:

  - YTD

  - MoM absoluto e percentual

  - YoY absoluto e percentual

  - Média mensal

  - Pesos relativos

  - Flags de anomalia

- Manutenção da rastreabilidade do centro de custo coringa

- Nenhum cálculo de Orçado vs Realizado

### Regras Analíticas 

- Uso de `COALESCE` para consistência visual

- Prevenção de divisão por zero com `NULLIF`

- Continuidade temporal garantida via `dim_calendario`

- Flags explícitas para valores atípicos

- Cálculos complexos concentrados na Gold quando necessário, o restante será feito no Power BI

---

## 🛠️ Stack Utilizada

- **SQL Server** — ETL e modelagem dimensional
- **Python (Pandas)** — ingestão e dados sintéticos
- **Power BI** — visualização
- **Git / GitHub** — versionamento e documentação

---

## 📌 Objetivo do Projeto

Este projeto foi desenvolvido para consolidar estudos em **Análise de Dados, BI e Engenharia Analítica**, aplicando conceitos em um cenário financeiro realista.

O foco está no processo:
- Decisões técnicas explícitas
- Tratamento de dados imperfeitos
- Construção de uma base analítica confiável

---

## 📎 Próximos Passos

- Evoluir análises no Power BI
- Publicar dashboards finais

> **Status:** projeto em desenvolvimento contínuo.

📬 Fique à vontade para explorar o repositório e enviar feedbacks ou sugestões.
