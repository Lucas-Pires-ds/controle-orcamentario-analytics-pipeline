# 📊 Controle Orçamentário — Pipeline de Dados e Analytics

> Pipeline completo de ETL simulando gestão orçamentária corporativa, com foco em qualidade de dados e modelagem dimensional

---

## 🎯 Visão Geral

Este projeto simula um pipeline de dados financeiro-orçamentário completo, cobrindo desde a ingestão de dados brutos até a entrega de uma base analítica confiável para consumo em dashboards.

O objetivo não é apenas gerar visualizações, mas construir uma **infraestrutura de dados** que trate problemas reais encontrados em ambientes corporativos:

* Baixa padronização de dados na origem
* Falhas de integridade referencial
* Inconsistências semânticas
* Ausência de validações antes da análise

---

## 🏢 Contexto de Negócio

**Sage** é uma empresa fictícia do setor de serviços criada como contexto para este projeto de portfólio.

### Problema Simulado

Empresas de serviços frequentemente enfrentam desafios na gestão orçamentária:

* Dados financeiros provenientes de múltiplas fontes
* Dificuldade em consolidar orçado vs realizado
* Baixa confiabilidade dos indicadores financeiros
* Dependência excessiva de tratamentos manuais no BI

Este projeto simula esse cenário e propõe uma abordagem estruturada para lidar com esses problemas.

### Abordagem de Solução

Para lidar com os desafios apresentados, o projeto foi pensado a partir de alguns princípios simples:

* Centralizar os dados financeiros em uma única base confiável
* Separar claramente dados brutos, dados tratados e dados prontos para análise
* Aplicar validações antes da análise, reduzindo a necessidade de correções no BI
* Manter rastreabilidade das informações, permitindo investigar inconsistências até a origem do dado

---

## 🏗️ Arquitetura

O projeto segue o padrão **Medallion Architecture** (Bronze → Silver → Gold), com separação clara de responsabilidades:

[![Arquitetura do Pipeline](docs_e_imagens/diagrama_pipeline_de_dados.png)](docs_e_imagens/diagrama_pipeline_de_dados.png)

### Camadas implementadas:

* **🥉 Bronze**
  Ingestão de dados brutos via `BULK INSERT`, preservando o formato original sem aplicar regras de negócio. Todas as colunas chegam como `VARCHAR` — a tipagem é responsabilidade da Silver.

* **🥈 Silver**
  Aplicação de validações de qualidade, padronizações e modelagem dimensional (Star Schema), garantindo integridade referencial e consistência semântica.

* **🥇 Gold**
  Views analíticas especializadas com métricas pré-calculadas e estrutura pronta para consumo no Power BI.

📖 **[Documentação completa do pipeline](pipeline)**

### Modelo Dimensional (Star Schema)

[![Modelo Dimensional](docs_e_imagens/modelo_dimensional.png)](docs_e_imagens/modelo_dimensional.png)

A camada Silver implementa um modelo dimensional completo com:

* 📊 **2 Fatos**: Orçamento (mensal) e Lançamentos (diário)
* 📋 **6 Dimensões**: Centro de Custo, Categoria, Fornecedores, Campanhas, Calendário e Mês
* 🔗 **Integridade Referencial**: Todas as foreign keys validadas via constraints


📖 **[Ver documentação técnica completa →](pipeline/02_silver)**

---

## 🧭 Como Navegar Neste Repositório

Este repositório está organizado em **dois níveis de documentação**:

### 📄 Nível 1: Visão Geral (este README)

Contexto de negócio, arquitetura geral e resultados do projeto

### 📂 Nível 2: Documentação Técnica Detalhada

Cada camada do pipeline possui documentação técnica específica em seu diretório:

* **[pipeline/](pipeline)** → Conceitos da Medallion Architecture
  + **[pipeline/bronze/](pipeline/01_bronze)** → Ingestão e scripts SQL
  + **[pipeline/silver/](pipeline/02_silver)** → Validações, transformações e modelo dimensional
  + **[pipeline/gold/](pipeline/03_gold)** → Views analíticas e métricas calculadas
* **[dashboards/](dashboards)** → Visualizações Power BI e decisões de BI

---

## 📊 Estrutura do Projeto

```
📦 controle-orcamentario-analytics-pipeline/
│
├── 📂 pipeline/          # Camadas de ETL (Bronze, Silver, Gold)
├── 📂 dashboards/        # Visualizações Power BI
├── 📂 data/              # Dados sintéticos (CSVs prontos para uso)
├── 📂 docs_e_imagens/    # Diagramas e documentação visual
├── 📄 registros.md       # Diário de desenvolvimento
└── 📄 README.md          # Este arquivo
```

---

## 🛠️ Stack Utilizada

| Tecnologia | Uso |
| --- | --- |
| **SQL Server** | ETL, modelagem dimensional, transformações e views analíticas |
| **Power BI** | Visualização, DAX e análise |
| **Git/GitHub** | Versionamento e documentação |
| **Python** | Geração dos dados sintéticos utilizados como fonte do pipeline |

---

## 🧠 Decisões Arquiteturais

**Escolha da Medallion Architecture**

O problema central do projeto é que os dados chegam sujos — espaços extras, IDs inválidos, tipos errados, status inconsistentes. Isso indica que era preciso um lugar para guardar esses dados sem perder a origem, outro para tratá-los, e outro para servir o dashboard. A separação em Bronze, Silver e Gold resolve exatamente isso: qualquer inconsistência que aparecer depois pode ser rastreada até a fonte sem precisar reprocessar tudo do zero. As regras de negócio ficam centralizadas na Silver, então o Power BI consome dados já tratados em vez de reimplementar validações em DAX.

**Transformações no SQL, não no DAX**

Se a lógica de negócio vive no DAX, ela só existe dentro do Power BI. Qualquer outra consulta ao banco recebe o dado bruto. Manter as transformações no SQL garante que o dado já saia tratado independente de quem ou o que estiver consultando. Também é mais eficiente, o SQL lida com volume muito melhor do que Pandas ou DAX.

**dim_calendario e integridade dos cálculos temporais**

`LAG()` conta posições na partição, não meses no calendário. Se não houver lançamentos em algum mês, o `LAG(1)` compara com o mês anterior que *tem* dados — não com o mês imediatamente anterior. O resultado parece correto mas está errado. O `RIGHT JOIN` com a `dim_calendario` força a existência de todos os meses no período com valor zero quando necessário, garantindo que o LAG sempre compare o que deve comparar.

**Mediana em vez de média no benchmark diário**

O diagnóstico da `fact_orcamento` encontrou outliers com valores entre 8x e 10x a média — erros de digitação nos dados de orçamento. Usar média como benchmark puxaria o `peso_do_dia` para cima e geraria alertas falsos no dashboard operacional. A mediana ignora esses extremos e reflete o comportamento típico da série.

**CROSS JOIN para o grid diário**

O acumulado MTD precisa de uma linha para cada combinação de `data × centro_de_custo × categoria`, inclusive nos dias sem lançamento. Sem isso, os dias sem movimento simplesmente não existem na série e as curvas do dashboard ficam com saltos. O `CROSS JOIN` entre a `dim_calendario` e as combinações distintas de centro de custo e categoria gera esse grid completo. O `LEFT JOIN` posterior preenche os dias com movimento e mantém zero nos demais.

---

## ✅ Principais Diferenciais

### 1. Framework de Qualidade de Dados

* Validações aplicadas antes da persistência na camada Silver
* Verificações de nulos, duplicatas, chaves inválidas e inconsistências de valores
* Dados suspeitos preservados e sinalizados, não removidos

### 2. Modelagem Dimensional

* Star Schema com 6 dimensões e 2 fatos
* Integridade referencial garantida via constraints
* `dim_calendario` para continuidade temporal em cálculos de série histórica

### 3. Camada Gold Especializada

* 5 views com responsabilidades bem definidas
* Métricas avançadas: YTD, MoM, YoY, pesos relativos, projeção MTD
* Benchmark de consumo diário baseado em mediana histórica

### 4. Rastreabilidade

* Transformações via Views para auditoria completa
* Preservação de valores originais para investigação
* Flags de qualidade em toda a pipeline

---

## 📈 Resultados

Após aplicação das regras de ETL e qualidade:

* ✅ 100% dos registros na Silver respeitam tipagem e integridade referencial
* ✅ 92 registros problemáticos identificados e tratados automaticamente
* ✅ Modelo dimensional pronto para consumo sem tratamentos adicionais em DAX
* ✅ 16+ métricas analíticas disponíveis (YTD, MoM, YoY, etc)
* ✅ Métricas de Orçado vs Realizado com regras de negócio explícitas
* ✅ Risco de erros silenciosos mitigado na camada de dados
* ✅ Dashboard com 4 páginas funcionais entregue — visão operacional preventiva e análise executiva retrospectiva

---

## 📊 Preview do Dashboard

> Camada de visualização construída em Power BI sobre as views Gold. Quatro páginas com contextos analíticos distintos.

![Operacional — Monitoramento](docs_e_imagens/dash_operacional_monitoramento.png)
*Monitoramento preventivo intra-mês: ritmo de consumo vs orçado ideal (baseado em benchmark histórico) e semáforo de risco por centro de custo*

![Operacional — Detalhamento](docs_e_imagens/dash_operacional_detalhamento.png)
*Investigação de lançamentos: tabela diária com status de pagamento, pendências financeiras e ranking por categoria e fornecedor*

![Analytics — Performance Orçamentária](docs_e_imagens/dash_analytics_performance.png)
*Visão executiva retrospectiva: orçado vs realizado com linha de desvio e matriz de performance por centro de custo × mês*

![Analytics — Evolução e Tendências](docs_e_imagens/dash_analytics_tendencias.png)
*Análise de crescimento: comparativo YoY, ranking de crescimento estrutural e top 5 centros de custo com maior variação*

---

## ⚙️ Como Rodar Este Projeto

### Pré-requisitos

* SQL Server 
* SQL Server Management Studio (SSMS) 
* Power BI Desktop
* Git

### Passo a passo

**1. Clone o repositório**
```bash
git clone https://github.com/Lucas-Pires-ds/controle-orcamentario-analytics-pipeline.git
```

**2. Crie o banco de dados**

No SSMS, crie um banco chamado `Financeiro_BI` ou ajuste o nome nos scripts conforme sua preferência.

**3. Ajuste o caminho dos arquivos CSV**

No script `pipeline/01_bronze/sql/01_Ingestao_de_dados.sql`, localize os comandos `BULK INSERT` e substitua o caminho pelo diretório local onde você clonou o repositório:

```sql
-- Substitua pelo caminho no seu ambiente
BULK INSERT stg_lancamentos 
FROM 'C:\seu_caminho\data\raw\fact_lancamentos.csv' ...
```

Os arquivos CSV já estão incluídos no repositório em `data/raw/` — não é necessário gerá-los.

**4. Execute os scripts SQL na ordem**

```
pipeline/01_bronze/sql/01_Ingestao_de_dados.sql
pipeline/02_silver/sql/02_Criacao_de_tabelas.sql
pipeline/02_silver/sql/03_Diagnostico_de_dados_dimensoes.sql  - opcional, apenas leitura
pipeline/02_silver/sql/04_Diagnostico_de_dados_facts.sql      - opcional, apenas leitura
pipeline/02_silver/sql/05_Views_e_Transformacoes.sql
pipeline/02_silver/sql/06_Carga_de_dados.sql
pipeline/03_gold/sql/07_Views_golds.sql
```

> Os scripts de diagnóstico (03 e 04) documentam a análise exploratória que fundamentou as decisões de tratamento. Não precisam ser executados para o pipeline funcionar, mas são recomendados para entender o raciocínio de cada transformação.

**5. Conecte o Power BI**

Abra o arquivo `.pbix` em `dashboards/` e atualize a conexão para apontar para o seu SQL Server e banco `Financeiro_BI`.

---

## 🔭 Como Este Projeto Poderia Evoluir

O escopo atual cobre o pipeline de dados e o dashboard analítico. Algumas evoluções naturais para um ambiente de produção seriam:

* Substituir a execução manual dos scripts por uma ferramenta de orquestração com agendamento automático
* Adicionar testes automatizados de qualidade de dados a cada execução do pipeline
* Migrar para cloud, aproximando a arquitetura de um ambiente corporativo real

---

## 📌 Status

**Status atual:** Projeto concluído — pipeline end-to-end implementado e dashboard entregue.

| Camada | Status |
|---|---|
| 🥉 Bronze | ✅ Concluído |
| 🥈 Silver | ✅ Concluído |
| 🥇 Gold | ✅ Concluído |
| 📊 Dashboard | ✅ Concluído |

---

## 📬 Sobre Este Projeto

Este projeto faz parte de um portfólio de dados, desenvolvido com foco em boas práticas de engenharia analítica e qualidade de dados.

A documentação técnica completa de cada etapa está disponível nos respectivos diretórios do repositório.

Feedbacks e sugestões são bem-vindos através de mensagens no meu **[LinkedIn](https://www.linkedin.com/in/lucas-pires-da-hora/)**.
