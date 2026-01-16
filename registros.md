# Diário de Desenvolvimento - Projeto BI Financeiro

## [28/12/2025] Início do Projeto e Ingestão de Dados
### O que foi feito:
- Definição do escopo: Controle Orçamentário e Lançamentos.
- Geração de dados sintéticos: 5000+ linhas usando Python para simular cenários reais com sazonalidade e erros.
- Configuração do ambiente: SQL Server no VS Code e criação do banco de dados `Financeiro_BI`.
- Estruturação inicial: Implementação da **Camada Bronze (stg_)**.

### Decisões técnicas:
- **Realismo de Dados:** Apliquei regras de sazonalidade (13º salário, marketing) e inserção de erros propositais (espaços, nulos, chaves órfãs) para testar o pipeline no limite.
- **Arquitetura de Camadas (Medallion):** Optei pelo padrão Bronze e Silver para garantir rastreabilidade. A Camada Bronze foi configurada em VARCHAR para garantir que a importação aterrissasse sem erros de conversão, permitindo tratar a "sujeira" via código depois.
- **Uso Consultivo de IA:** Utilização de Gemini e ChatGPT para validação de lógica SQL e refinamento da arquitetura.

---

## [03/01/2026] Analytics Engineering e Camada de Data Quality
### O que foi feito:
- **Refatoração Estrutural:** Reorganizei o script SQL em blocos lógicos: DDL, Diagnóstico, Transformação, Carga e Auditoria.
- **Finalização das Dimensões:** Concluí o diagnóstico e a carga das tabelas na **Camada Silver** (`dim_camp_marketing`, `dim_centro_custo`, `dim_categoria` e `dim_fornecedores`).
- **Implementação de Data Quality:** Criei uma camada de auditoria pré-transformação para garantir a saúde dos dados.

### Decisões técnicas:
- **Metodologia de Diagnóstico Automático:**
  - **Espaços Extras:** Substituí a análise visual pela lógica `LEN(col) > LEN(TRIM(col))`.
  - **Padrão de IDs:** Tratei chaves em formato decimal (`101.0`) via conversão aninhada `CAST(CAST(col AS FLOAT) AS INT)`.
  - **Auditoria de Unicidade:** Usei `GROUP BY` com `HAVING COUNT > 1` para validar as chaves primárias.
- **Saneamento Seletivo de Strings:**
  - Implementei lógica autoral para o formato *InitCap*.
  - **Exceções de Negócio:** Ajustei o código para ignorar siglas (RH, TI) e termos compostos (Limpeza/Conservação), mantendo a semântica original.
- **Investigação de Causa Raiz:** Detectei duplicidade na categoria "ALUGUEL/CONDOMÍNIO" causada por registros nulos, resolvendo com filtros de integridade na View.
- **Integridade Referencial:** Validação via `NOT IN` para garantir que toda categoria esteja vinculada a um centro de custo existente.

### Resolução de problemas:
- **Saneamento de Campos Numéricos:** Corrigi erros na função `LEN` em colunas numéricas usando `CAST(col AS VARCHAR)` na validação.
- **Validação de Tipagem:** Usei o `INFORMATION_SCHEMA.COLUMNS` para auditar se a tipagem das Views batia com o DDL das tabelas finais.
- **Soberania da Lógica:** Escolhi usar `RIGHT` e `LEN-1` em vez de funções prontas para manter o domínio total da lógica e facilitar a defesa técnica do código.

### Status Final das Dimensões:
- **Carga Concluída:** Todas as dimensões foram povoadas na Silver seguindo a hierarquia de chaves estrangeiras.
- **Relatório de Auditoria:** Usei `UNION ALL` no final para conferir a volumetria entre as camadas Bronze e Silver.

---

## [04/01/2026] Engenharia Analítica na Tabela Fato — Silver Layer
### O que foi feito:
- **Data Profiling aprofundado:** Auditoria completa na tabela `stg_lancamentos` antes da carga na Silver, avaliando impacto financeiro real das inconsistências.
- **Criação da tabela fato `fact_lancamentos`:** Implementação da camada Silver para dados transacionais financeiros.
- **Centralização da lógica de limpeza:** Desenvolvimento da `vw_lancamentos` como camada única de transformação antes da persistência física.

### Diagnóstico de Qualidade de Dados:
- **Integridade Temporal:** Identificados 27 registros com data nula (~0,6% do montante financeiro).
- **Integridade Referencial:** Detectados 65 registros (~1,3% do montante) com Centros de Custo inexistentes na dimensão.
- **Anomalias de Sinal:** Identificados lançamentos com valores negativos sem correspondência a estorno ou cancelamento.
- **Inconsistência Semântica:** Duplicidade de status de pagamento causada por variações de case e gênero (ex: "Paga", "PAGO", "pago", "Pending").

### Decisões técnicas:
- **Descarte Estratégico Orientado a Impacto:**
  - Registros sem data foram removidos por apresentarem alto risco analítico e baixo impacto financeiro (~0,6%).
- **Membro Coringa (Default Member):**
  - Criação do registro `-1 (NÃO IDENTIFICADO)` na `dim_centro_custo` para preservar dados financeiros sem violar integridade referencial.
- **Redundância Defensiva de Dados Financeiros:**
  - `valor`: valor tratado com `ABS()`, protegido por `CHECK CONSTRAINT (> 0)` para consumo analítico.
  - `valor_original`: preservação do dado bruto para fins de auditoria e rastreabilidade.
- **Normalização Semântica de Status:**
  - Padronização dos status para apenas duas categorias: `Pago` e `Aberto`, utilizando `CASE WHEN` com `UPPER()` e `TRIM()`.

### Status Final da fact_lancamentos:
- **Carga Concluída com Sucesso**
- **100% dos registros** respeitando regras de negócio e integridade referencial.
- Dados prontos para consumo analítico no Power BI.

---

## [10/01/2026] Consolidação do Modelo Analítico e Camada Gold Inicial
### O que foi feito:
- **Correção de bug crítico de infraestrutura:** Resolução do erro `Msg 242 (Data out-of-range)` durante a carga de orçamentos.
- **Refatoração da camada Silver de Orçamentos:** Otimização da lógica da `vw_orcamento` para maior escalabilidade e menor acoplamento manual.
- **Criação da `dim_calendario`:** Desenvolvimento completo de uma dimensão de tempo robusta, com granularidade diária.
- **Implementação da tabela fato `fact_orcamento`:** Estruturação do planejamento financeiro mensal com regras de integridade física.
- **Consolidação da Camada Gold:** Desenvolvimento da query analítica de confronto **Orçado vs. Realizado**.

### Decisões técnicas:
- **Engenharia da Dimensão Calendário:**
  - Geração de 731 dias via `WHILE`.
  - Pareamento entre colunas de exibição (`mes_ano`, `trimestre_ano`) e colunas numéricas de ordenação (`ano_mes`, `ano_trimestre`).
  - Flags de negócio: dia útil, bimestre, trimestre e semestre.
- **Ancoragem Temporal do Orçamento:**
  - Orçamentos mensais projetados para o último dia do mês (`EOMONTH`), permitindo join consistente com lançamentos diários.
- **Join de Granularidades Diferentes:**
  - Uso da `dim_calendario` como ponte entre `fact_lancamentos` (diária) e `fact_orcamento` (mensal).
- **Tratamento de Exceções Analíticas:**
  - Identificação explícita de gastos sem planejamento via `LEFT JOIN` + `COALESCE`.

### Resultado:
O projeto evoluiu de um pipeline de carga e saneamento para um **modelo dimensional completo**, capaz de responder perguntas reais de negócio sobre execução orçamentária, desvios e performance financeira.

### Próximos passos:
- [ ] Evoluir métricas da camada Gold
- [ ] Construir o dashboard final no Power BI

## [11/01/2026] Consolidação da Gold Mensal e Decisões Analíticas de Negócio

### O que foi feito:
- **Definição final da arquitetura da Camada Gold:** decisão explícita pela existência de **duas views Gold**:
  - `vw_gold_mensal`: visão executiva e financeira (Orçado vs Realizado).
  - `vw_gold_diaria` (a ser construída): acompanhamento intramês de consumo.
- **Finalização da `vw_gold_mensal`:** consolidação mensal com métricas financeiras, percentuais, flags de negócio e acumulados YTD.
- **Refino das métricas analíticas:** validação e ajuste de indicadores como desvio, percentual de atingimento e pesos relativos.
- **Discussão e definição do tratamento de valores nulos para consumo no Power BI.**

### Decisões técnicas:
- **Tratamento consciente de NULL vs 0:**
  - Decisão de **não converter ausência de orçamento em zero**, preservando `NULL` para evitar interpretações analíticas incorretas.
  - Uso sistemático de `NULLIF` em divisões para evitar *divide by zero* e manter estabilidade do modelo.
- **Separação semântica entre “Não orçado” e “Orçado = 0”:**
  - Criação da flag `Flag_houve_orcamento` para distinguir ausência de planejamento de valores válidos.
- **Cálculo de métricas percentuais:**
  - Indicadores como `%_Atingimento` e `Percentual_desvio` retornam `NULL` quando não há orçamento, delegando a decisão visual ao Power BI.
- **Pesos Analíticos (Share):**
  - Implementação de `Peso_centro_custo` e `Peso_categoria` via Window Functions, sempre protegidas por `NULLIF` no denominador.
- **Acumulados YTD:**
  - Cálculo de Orçado, Realizado e Desvio acumulados por Ano, Centro de Custo e Categoria, respeitando ordenação temporal por mês.

### Regras de negócio consolidadas na Gold Mensal:
- **Orçado:** soma mensal do planejamento financeiro.
- **Realizado:** soma mensal dos lançamentos financeiros.
- **Desvio:** diferença entre realizado e orçado.
- **Percentuais:** calculados apenas quando existe orçamento válido.
- **Gastos sem orçamento:** mantidos no modelo com flags explícitas, sem mascaramento via `COALESCE`.

### Status ao final do dia:
- `vw_gold_mensal` **finalizada e validada**.
- Arquitetura Gold definida e documentada conceitualmente.
- Projeto pronto para evolução da **Gold Diária** e início do dashboard no Power BI.

### Próximos passos:
- [ ] Construção da `vw_gold_diaria` (consumo intramês)
- [ ] Integração da Gold com Power BI
- [ ] Revisão final do README com decisões arquiteturais consolidadas


## [15/01/2026] Redefinição da Camada Gold e Consolidação da View de Orçamento  

### O que foi feito:  
- **Revisão da arquitetura da Camada Gold:** após discussão e validação técnica, foi tomada a decisão de **abandonar a Gold mensal e a Gold diária**.  
- **Nova abordagem definida:** a Camada Gold passa a ser composta por **duas views distintas e complementares**:  
  - `vw_gold_orcamento`: visão do planejamento financeiro (orçado).  
  - `vw_gold_lancamentos`: visão dos gastos realizados (transacional).  
- O confronto **Orçado vs Realizado** ficará **exclusivamente no Power BI**, evitando complexidade excessiva e riscos de erro no SQL.  

### Motivo da decisão:  
- Misturar orçamento (mensal) e lançamentos (diários) na mesma view aumentava muito a complexidade e o risco de duplicações ou leituras incorretas.  
- Separar as responsabilidades deixa o modelo mais simples, mais confiável e mais fácil de manter.  
- Essa abordagem reflete melhor um cenário real de BI, onde a camada de dados entrega fatos claros e o BI faz a combinação final.  

### Desenvolvimento da `vw_gold_orcamento`:  
- Criação de uma view Gold dedicada apenas ao **orçamento mensal**, agregada por:  
  - Ano  
  - Mês  
  - Centro de custo  
  - Categoria  
- Implementação das principais métricas analíticas:  
  - **Orcado_mensal:** valor mensal do orçamento (tratando zero como ausência de informação).  
  - **Orcado_YTD:** orçamento acumulado no ano, respeitando a ordem dos meses.  
  - **Peso_centro_custo:** participação do centro de custo no orçamento total do mês.  
  - **Peso_categoria:** participação da categoria no orçamento total do mês.  
  - **Media_mensal:** média histórica do orçamento por centro de custo e categoria.  

### Tratamento de qualidade e estabilidade:  
- Uso consistente de `NULLIF` para evitar divisões por zero e leituras enganosas.  
- Decisão consciente de **não forçar flags sem ocorrência real** (ex.: não orçado ou valor atípico), mantendo a estrutura preparada, mas sem “inventar problema”.  
- Implementação de uma **flag de valor atípico** baseada em comparação simples com a média histórica, apenas como apoio exploratório, não como regra de negócio crítica.  

### Boas práticas adotadas:  
- Padronização de aliases e nomes de colunas para facilitar leitura e consumo no Power BI.  
- Identação e organização do código focadas em clareza, não em “SQL rebuscado”.  
- Lógica escrita de forma defensiva, priorizando números corretos em vez de métricas “bonitas”.  

### Status ao final do dia:  
- `vw_gold_orcamento` **finalizada, revisada e pronta para uso**.  
- Arquitetura Gold **simplificada e mais robusta**.  
- Base sólida criada para a construção da `vw_gold_lancamentos` e do dashboard final.