# 📊 Projeto de Controle Orçamentário — Pipeline ETL e Analytics
## Visão Geral

Este projeto simula um **pipeline completo de dados para controle orçamentário**, cobrindo desde a ingestão de dados brutos até a preparação de um **modelo analítico pronto para consumo em Power BI**.

O foco principal não é apenas gerar dashboards, mas **demonstrar pensamento de engenharia analítica**, com atenção especial à **qualidade dos dados**, **rastreabilidade**, **modelagem dimensional** e **integridade referencial** — problemas reais encontrados em ambientes corporativos.

O projeto foi desenvolvido com **SQL Server**, **Python** e **Power BI**, adotando boas práticas de arquitetura e ETL utilizadas no mercado.

## 🎯 Problema de Negócio

Empresas que trabalham com orçamento frequentemente enfrentam desafios como:

* Dados financeiros vindos de múltiplas fontes e com baixa padronização

* Falta de controle de qualidade antes da análise

* Dificuldade em garantir consistência entre categorias, centros de custo e campanhas

Este projeto resolve esses problemas ao estruturar um pipeline que:

* Centraliza os dados

* Sanea inconsistências ainda na camada de dados

* Entrega dimensões confiáveis para análises financeiras e orçamentárias

## 🏗️ Arquitetura de Dados

Foi adotado o padrão Medallion Architecture, separando claramente as responsabilidades de cada camada:

### 🥉 Camada Bronze (stg_)

* Ingestão de dados brutos via **Python (Pandas) + Bulk Insert**

* Todas as colunas armazenadas como VARCHAR(MAX) ou VARCHAR(200)

* Objetivo: **garantir que a carga nunca falhe por incompatibilidade de tipos**

> **Nota:** Os caminhos utilizados nos comandos `BULK INSERT` são parametrizáveis e devem ser ajustados conforme o ambiente local de execução.


A decisão de manter dados não tipados nesta camada permite que o saneamento ocorra de forma controlada no SQL Server.

### 🥈 Camada Silver (dim_)

* Persistência física dos dados transformados e tipados

* Aplicação de **PRIMARY KEY** e **FOREIGN KEY**

* Preparação de um **modelo dimensional (Star Schema)**

As tabelas desta camada são a base confiável para o consumo analítico.

### 🔎 Transformações via Views (vw_)

* As transformações entre Bronze e Silver são feitas via **Views**

* Permite testar e ajustar regras de limpeza **sem reprocessar a carga física**

* Facilita auditoria, manutenção e rastreabilidade

## ✅ Framework de Qualidade de Dados

Antes da carga definitiva na camada Silver, foi implementado um conjunto de queries de diagnóstico, atuando como um framework de Data Quality.

### Principais validações

* **Auditoria de Espaços:** detecção de espaços extras com LEN(col) > LEN(TRIM(col))

* **Sanidade de IDs:** identificação de valores como 101.0 importados como string

* **Validação de Domínio:** meses fora do intervalo válido (1–12)

* **Unicidade:** verificação de chaves primárias duplicadas (GROUP BY + HAVING COUNT(*) > 1)

Essas validações permitem identificar problemas antes da persistência física, evitando erros silenciosos no modelo analítico.

## ⚙️ Decisões Técnicas de ETL
### Conversão de Tipagem Complexa

Para tratar IDs numéricos importados como strings decimais (ex: "101.0"), foi utilizada a conversão aninhada:

CAST(CAST(id_categoria AS FLOAT) AS INT)


Essa abordagem evita erros comuns do SQL Server ao tentar converter diretamente strings com ponto decimal para inteiros.

### Padronização Semântica de Strings

Foi desenvolvida uma lógica de InitCap personalizada, com foco na estética do dashboard sem comprometer o negócio:

* Primeira letra maiúscula, demais minúsculas

* Preservação de siglas em caixa alta (ex: **RH**, **TI**)

* Tratamento correto de delimitadores (ex: "Limpeza/Conservação")

### Integridade e Saneamento de Dados

* Registros com **IDs nulos na origem** foram identificados como causa raiz de duplicidades

* Esses registros foram descartados ainda na View (WHERE id IS NOT NULL)

* Validação cruzada garantiu que **toda categoria possua um Centro de Custo válido** antes da carga na Silver

## 🧩 Modelo Dimensional (Silver)

O modelo foi construído seguindo o padrão Star Schema, com foco em performance e clareza analítica.

### Dimensões implementadas

* **dim_centro_custo** — centros responsáveis pelo orçamento

* **dim_categoria** — natureza das despesas (com FK para centro de custo)

* **dim_camp_marketing** — campanhas e referência temporal

* **dim_fornecedores** — fornecedores envolvidos nos lançamentos

Todas as tabelas possuem restrições explícitas de PK e FK.

## 📦 Auditoria Final da Carga

Após o carregamento da Silver:

* Carga realizada via INSERT INTO ... SELECT FROM vw_

* Validação de volumetria comparando tabelas através de UNION ALL

* Diferenças de registros foram analisadas e justificadas por filtros de qualidade

**Resultado:** dimensões prontas para consumo analítico, sem inconsistências estruturais.

## 📊 Camada Gold e Análises

A camada Gold é destinada ao consumo final no Power BI, utilizando:

* Tabelas fato de Lançamentos e Orçamento

* Dimensões saneadas como filtros

* Métricas financeiras e orçamentárias

*(Dashboards em evolução)*

## 🛠️ Stack Utilizada

* **SQL Server** — ETL, modelagem dimensional e integridade

* **Python (Pandas)** — ingestão e geração de dados sintéticos

* **Power BI** — visualização e análise

* **Git / GitHub** — versionamento e documentação

## 📌 Objetivo do Projeto

Este projeto tem como objetivo consolidar e demonstrar competências técnicas em análise de dados, BI e engenharia analítica, por meio da construção de um pipeline completo de dados financeiros.

A iniciativa reflete um processo contínuo de desenvolvimento técnico e aprofundamento em boas práticas de mercado, demonstrando:

- Pensamento arquitetural  
- Rigor em qualidade de dados  
- Capacidade de transformar dados brutos em ativos analíticos confiáveis  


## 📎 Próximos Passos

* Evoluir a camada Gold

* Publicar dashboards finais

* Adicionar diagrama visual da arquitetura

📬 Fique à vontade para explorar o repositório e entrar em contato para feedbacks ou sugestões.

