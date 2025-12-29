# Projeto Controle Orçamentário Corporativo: ETL e Dashboard Analítico

> **Status do Projeto:** 🚧 Em Desenvolvimento (Fase de ETL e Modelagem SQL)

Este projeto visa a criação de uma solução completa de Business Intelligence para análise financeira, abrangendo desde a geração de dados sintéticos até a visualização em dashboards de alto impacto.

## 🏗️ Arquitetura de Dados

O projeto segue o padrão de medalhão simplificado, utilizando camadas para garantir a integridade e rastreabilidade:

1.  **Staging (Raw):** Dados brutos importados via `BULK INSERT` em formato `VARCHAR(MAX)`.
2.  **Transformation (Views):** Camada lógica onde ocorre o *Data Cleansing* (limpeza), tipagem e aplicação de regras de negócio.
3.  **Trusted (Dimension/Fact):** Tabelas finais otimizadas em modelo **Star Schema** para consumo do Power BI.

## 🛠️ Tecnologias Utilizadas

* **Python:** Geração de 5.000+ linhas de dados sintéticos com regras de sazonalidade (13º salário, campanhas de marketing) e erros propositais para teste de robustez.
* **SQL Server:** Armazenamento, modelagem dimensional e processamento ETL.
* **VS Code:** Ambiente de desenvolvimento principal.
* **IA Consultiva:** Utilização de modelos de linguagem para auxílio em *Pair Programming* e otimização de queries.

## 📈 O que já foi implementado:

- [x] Definição de escopo e regras de negócio.
- [x] Script Python para geração de bases financeiras realistas.
- [x] Configuração do banco de dados e ingestão na camada Staging.
- [x] Desenvolvimento de Views de transformação com tratamento de:
    - Duplicidades críticas.
    - Padronização de texto (InitCap).
    - Tratamento de nulos e conversão de tipos (Casting).
- [x] Criação e carga das tabelas de Dimensão (`d_campanha`, `d_centro_custo`, `d_categoria`).

## 🚀 Próximos Passos

- [ ] Modelagem e carga da Tabela Fato (`f_lancamentos` e `f_orcamento`).
- [ ] Implementação de chaves substitutas (Surrogate Keys).
- [ ] Integração e modelagem de dados no Power BI.
- [ ] Criação de Dashboard interativo.

---
*Este é um projeto de portfólio para demonstrar habilidades em Engenharia e Análise de Dados.*