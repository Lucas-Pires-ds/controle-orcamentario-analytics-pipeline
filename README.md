# 📊 Controle Orçamentário — Pipeline de Dados e Analytics

> Pipeline de dados end-to-end para controle orçamentário, com foco em qualidade, rastreabilidade e modelagem analítica em um cenário corporativo simulado


---

## 🎯 Visão Geral

Este projeto simula um pipeline de dados financeiro-orçamentário completo, cobrindo desde a ingestão de dados brutos até a entrega de uma base analítica confiável para consumo em dashboards.

O objetivo não é apenas gerar visualizações, mas construir uma **infraestrutura de dados** que trate problemas reais encontrados em ambientes corporativos:

* Baixa padronização de dados na origem
* Falhas de integridade referencial
* Inconsistências semânticas
* Ausência de validações antes da análise

A solução proposta organiza e trata esses problemas na camada de dados, garantindo que o consumo analítico ocorra sobre uma base consistente, validada e rastreável.

---

## 🏢 Contexto de Negócio

**Sage** é uma empresa fictícia do setor de serviços criada como contexto para simular um cenário realista de gestão orçamentária.

### Problema Simulado

Empresas de serviços frequentemente enfrentam desafios para consolidar e analisar dados financeiros:

* Dados financeiros provenientes de múltiplas fontes 
* Dificuldade em consolidar orçado vs realizado
* Indicadores inconsistentes ou pouco confiáveis 
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
  Ingestão de dados brutos via `BULK INSERT`, preservando o formato original sem aplicar regras de negócio. Todas as colunas chegam como `VARCHAR`, pois a tipagem é responsabilidade da Silver.

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

Apresenta o problema, a solução, a arquitetura e os resultados do projeto.

### 📂 Nível 2: Documentação Técnica 

Detalhamento completo de cada etapa do pipeline:

* **[pipeline/](pipeline)** → Conceitos da Medallion Architecture
  + **[pipeline/bronze/](pipeline/01_bronze)** → Ingestão
  + **[pipeline/silver/](pipeline/02_silver)** → Validações, transformações e modelagem
  + **[pipeline/gold/](pipeline/03_gold)** → Camada analítica e métricas 
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

Os dados chegam com inconsistências estruturais. A separação em Bronze, Silver e Gold permite isolar essas etapas, garantindo tratamento antes do consumo e mantendo rastreabilidade completa.

**Transformações no SQL, não no DAX**

As regras de negócio são aplicadas na camada de dados, garantindo consistência independentemente da ferramenta de consumo.

**dim_calendario e integridade dos cálculos temporais**

A dimensão calendário garante continuidade dos períodos, evitando distorções em análises temporais.

**Mediana em vez de média no benchmark diário**

A mediana foi adotada para evitar distorções causadas por outliers identificados na base de orçamento.

**CROSS JOIN para o grid diário**

A construção de um grid completo garante continuidade das séries temporais e consistência nos cálculos de acumulado.

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
* ✅ Dashboard com 4 páginas funcionais entregue: visão operacional preventiva e análise executiva retrospectiva

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
*Análise de crescimento: comparativo 2023 vs 2024, YoY % por mês e rankings de Top 5 por centro de custo*

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

Os arquivos CSV já estão incluídos no repositório em `data/raw/`, não é necessário gerá-los.

**4. Execute os scripts SQL na ordem**

```
pipeline/01_bronze/sql/01_Ingestao_de_dados.sql
pipeline/02_silver/sql/02.1_EDA_dimensoes.sql  - opcional, apenas leitura
pipeline/02_silver/sql/02.2_EDA_facts.sql      - opcional, apenas leitura
pipeline/02_silver/sql/03_Transform.sql
pipeline/02_silver/sql/04_Criacao_de_tabelas.sql
pipeline/02_silver/sql/05_Load.sql
pipeline/03_gold/sql/06_vw_gold_lancamentos_consolidados_dia.sql
pipeline/03_gold/sql/06_vw_gold_lancamentos_diarios.sql
pipeline/03_gold/sql/06_vw_gold_lancamentos.sql
pipeline/03_gold/sql/06_vw_gold_orcamento.sql
pipeline/03_gold/sql/06_vw_gold_realizado.sql
pipeline/03_gold/sql/06_vw_gold_referencia.sql
```

> Os scripts de diagnóstico (02.1 e 02.2) documentam a análise exploratória que fundamentou as decisões de tratamento. Não precisam ser executados para o pipeline funcionar, mas são recomendados para entender o raciocínio de cada transformação.

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

**Status atual:** Projeto concluído! pipeline end-to-end implementado e dashboard entregue.

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
