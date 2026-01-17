# 📊 Controle Orçamentário — Pipeline de Dados e Analytics

> Pipeline completo de ETL simulando gestão orçamentária corporativa, com foco em qualidade de dados e modelagem dimensional



---

## 🎯 Visão Geral

Este projeto simula um pipeline de dados financeiro-orçamentário completo, cobrindo desde a ingestão de dados brutos até a entrega de uma base analítica confiável para consumo em dashboards.

O objetivo não é apenas gerar visualizações, mas construir uma **infraestrutura de dados** que trate problemas reais encontrados em ambientes corporativos:

- Baixa padronização de dados na origem
- Falhas de integridade referencial
- Inconsistências semânticas
- Ausência de validações antes da análise

---

## 🏢 Contexto de Negócio

**Sage** é uma empresa fictícia do setor de serviços que enfrenta desafios comuns na gestão orçamentária:

- Dados financeiros provenientes de múltiplas fontes
- Dificuldade em consolidar orçado vs realizado
- Baixa confiabilidade dos indicadores financeiros
- Ausência de controle de qualidade antes da análise

O pipeline desenvolvido centraliza, trata e padroniza esses dados ao longo de camadas de ETL, viabilizando análises confiáveis de **Budget vs Actual** em nível mensal e diário.

---

## 🏗️ Arquitetura

O projeto segue o padrão **Medallion Architecture** (Bronze → Silver → Gold), com separação clara de responsabilidades:

![Arquitetura do Pipeline](docs_e_imagens/diagrama_pipeline_de_dados.png)

### Camadas implementadas:

- **🥉 Bronze**: Ingestão de dados brutos via Python + BULK INSERT
- **🥈 Silver**: Modelo dimensional (Star Schema) com integridade referencial
- **🥇 Gold**: Views analíticas especializadas (Orçamento, Realizado, Lançamentos)

📖 **[Documentação completa do pipeline](pipeline/)**

---

## 🧭 Como Navegar Neste Repositório

Este repositório está organizado em **dois níveis de documentação**:

### 📄 Nível 1: Visão Geral (este README)
Contexto de negócio, arquitetura geral e resultados do projeto

### 📂 Nível 2: Documentação Técnica Detalhada
Cada camada do pipeline possui documentação técnica específica em seu diretório:

- **[pipeline/](pipeline/)** → Conceitos da Medallion Architecture
  - **[pipeline/bronze/](pipeline/bronze/)** → Ingestão e scripts Python/SQL
  - **[pipeline/silver/](pipeline/silver/)** → Validações, transformações e modelo dimensional
  - **[pipeline/gold/](pipeline/gold/)** → Views analíticas e métricas calculadas
- **[dashboards/](dashboards/)** → Visualizações Power BI e decisões de BI

---

## 📊 Estrutura do Projeto
```
📦 controle-orcamentario-analytics-pipeline/
│
├── 📂 pipeline/          # Camadas de ETL (Bronze, Silver, Gold)
├── 📂 dashboards/        # Visualizações Power BI
├── 📂 data/              # Dados sintéticos (CSVs)
├── 📂 docs_e_imagens/    # Diagramas e documentação visual
├── 📄 registros.md       # Diário de desenvolvimento
└── 📄 README.md          # Este arquivo
```

---

## 🛠️ Stack Tecnológica

| Tecnologia | Uso |
|------------|-----|
| **SQL Server** | ETL, modelagem dimensional, transformações |
| **Python (Pandas)** | Geração de dados sintéticos, ingestão |
| **Power BI** | Visualização e análise |
| **Git/GitHub** | Versionamento e documentação |

---

## ✅ Principais Diferenciais

### 1. Framework de Qualidade de Dados
- Validações aplicadas antes da persistência na camada Silver
- Diagnósticos de integridade temporal, referencial e semântica
- Tratamento defensivo de anomalias (flags ao invés de exclusão)

### 2. Modelagem Dimensional
- Star Schema com 4 dimensões e 2 fatos
- Integridade referencial garantida via constraints
- dim_calendario para continuidade temporal

### 3. Camada Gold Especializada
- 3 views independentes com responsabilidades bem definidas
- Métricas avançadas: YTD, MoM, YoY, pesos relativos
- Cruzamento Orçado vs Realizado realizado no Power BI

### 4. Rastreabilidade
- Transformações via Views para auditoria completa
- Preservação de valores originais para investigação
- Flags de qualidade em toda a pipeline

---

## 📈 Resultados

Após aplicação das regras de ETL e qualidade:

- ✅ 100% dos registros na Silver respeitam tipagem e integridade referencial
- ✅ Modelo dimensional pronto para consumo sem tratamentos adicionais em DAX
- ✅ Métricas de Orçado vs Realizado com regras de negócio explícitas
- ✅ Risco de erros silenciosos mitigado na camada de dados

---

## 📌 Status e Próximos Passos

**Status atual:** Camadas Bronze, Silver e Gold implementadas e documentadas

**Próximos passos:**
- [ ] Desenvolvimento dos dashboards no Power BI
- [ ] Publicação de visualizações finais
- [ ] Adição de testes automatizados de qualidade

---

## 📬 Sobre Este Projeto

Este projeto faz parte de um portfólio de dados, desenvolvido com foco em boas práticas de engenharia analítica e qualidade de dados.

A documentação técnica completa de cada etapa está disponível nos respectivos diretórios do repositório.

Feedbacks e sugestões são bem-vindos através das issues do GitHub ou por mensagem no meu **[Linkedin:](https://www.linkedin.com/in/lucas-pires-da-hora/)**.

---
