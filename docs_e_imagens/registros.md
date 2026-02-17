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
- **Separação semântica entre "Não orçado" e "Orçado = 0":**
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
- Decisão consciente de **não forçar flags sem ocorrência real** (ex.: não orçado ou valor atípico), mantendo a estrutura preparada, mas sem "inventar problema".  
- Implementação de uma **flag de valor atípico** baseada em comparação simples com a média histórica, apenas como apoio exploratório, não como regra de negócio crítica.  

### Boas práticas adotadas:  
- Padronização de aliases e nomes de colunas para facilitar leitura e consumo no Power BI.  
- Identação e organização do código focadas em clareza, não em "SQL rebuscado".  
- Lógica escrita de forma defensiva, priorizando números corretos em vez de métricas "bonitas".  

### Status ao final do dia:  
- `vw_gold_orcamento` **finalizada, revisada e pronta para uso**.  
- Arquitetura Gold **simplificada e mais robusta**.  
- Base sólida criada para a construção da `vw_gold_lancamentos` e do dashboard final.

## [17/01/2026] Refino da Camada Gold e Documentação do Projeto

### O que foi feito:
- **Ajuste fino nas Views Gold:** Revisei a tipagem e os nomes das colunas na `vw_gold_lancamentos` e `vw_gold_orcamento` para garantir uma integração direta com o Power BI.
- **Tratamento de strings para filtros:** Apliquei `COALESCE` e remoção de espaços nos campos de fornecedores e campanhas para evitar inconsistências nos menus de filtro do dashboard.
- **Atualização da documentação:** Revi e atualizei os arquivos README da camada Gold e iniciei a estruturação do README da pasta Dashboard.

### Decisões técnicas:
- **Padronização de nomes:** Alterei nomes de colunas técnicas para termos mais claros e amigáveis. A ideia é resolver a nomenclatura direto na fonte (SQL) para evitar retrabalho de renomeação dentro do Power BI.
- **Consistência nos filtros:** Defini que valores nulos em campos descritivos seriam substituídos por termos como "Sem Informação". Isso melhora a experiência do usuário final, eliminando opções vazias ou irrelevantes nos filtros.
- **Alinhamento da documentação:** Atualizei os READMEs para refletir as mudanças na estrutura da Gold, garantindo que o repositório explique exatamente o que o código atual faz. Isso facilita a manutenção futura e o entendimento do pipeline por outros analistas.

### Resolução de problemas:
- **Ajuste de dependências:** Reorganizei o script `07_Views_golds.sql` para garantir que a criação das views ocorra na ordem correta, evitando erros de referência a tabelas ou colunas durante a execução do pipeline.

### Status ao final do dia:
- Camada Gold revisada, documentada e pronta para o consumo no Power BI.
- Documentação técnica do projeto atualizada com as últimas decisões de arquitetura.

## [20/01/2026] Inteligência de Alerta e Planejamento do Dashboard

### O que foi feito:
- **Finalização da `vw_gold_lancamentos`:** Implementei a lógica de acompanhamento acumulado mensal (MTD) diretamente na view.
- **Criação de benchmark estatístico:** Desenvolvi o cálculo de mediana histórica para validar o ritmo de gasto diário.
- **Planejamento estrutural do Power BI:** Elaborei o README da camada de dashboard, detalhando a separação entre as visões Executiva e Operacional.
- **Atualização da documentação técnica:** Refinei os guias das camadas Gold e Dashboard com as novas definições de métricas e navegação.

### Decisões técnicas:
- **Monitoramento preventivo:** Em vez de focar apenas no fechamento do mês, estruturei uma lógica que compara o gasto atual com o comportamento histórico do mesmo período, permitindo identificar desvios enquanto o mês ainda está em curso.
- **Uso de Mediana vs. Média:** Optei pela mediana para o benchmark histórico por ser uma métrica mais robusta contra outliers. Isso garante que meses com gastos atípicos não distorçam a linha de referência, gerando alertas mais confiáveis.
- **Processamento no SQL (Push-down):** Decidi realizar os cálculos complexos de acumulados e medianas no banco de dados. Isso otimiza a performance do Power BI, que recebe os dados já rotulados com as flags de alerta.
- **Consolidação de arquivo único:** Optei por gerenciar um único arquivo `.pbix` com navegação interna. Essa escolha facilita o controle de versão no repositório e garante que todas as páginas consumam o mesmo modelo semântico.

### Resolução de problemas:
- **Ajuste de granularidade no Join:** Identifiquei uma duplicação de registros causada pelo cruzamento com a lógica de mediana. Resolvi o problema aplicando `DISTINCT` na subquery de referência, garantindo a integridade dos valores financeiros.
- **Estabilidade de cálculos:** Implementei o uso de `NULLIF` para tratar divisões por zero. Isso evita erros de processamento em centros de custo sem histórico de gastos em dias específicos.

### Status ao final do dia:
- Camada Gold concluída, testada e documentada.
- Estratégia de dashboard definida, separando o monitoramento diário da análise executiva mensal.
- Modelo de dados preparado para sinalizar anomalias de orçamento em tempo real.

### Próximos passos:
- [ ] Implementar as medidas DAX conforme as regras de negócio definidas.
- [ ] Construir a interface visual e o sistema de navegação no Power BI.
- [ ] Validar os alertas de risco (semáforo) com os dados da camada Gold.

## [24/01/2026] Planejamento e Estruturação do Dashboard Operacional

### Contexto Geral

O foco do dia foi finalizar o desenho conceitual e visual do Dashboard Operacional, garantindo alinhamento entre arquitetura de dados, objetivo analítico, experiência do usuário (UI/UX) e governança do projeto. Ao final, foi concluído o esqueleto completo das duas abas operacionais em PowerPoint, servindo como mockup definitivo para implementação no Power BI.

### O que foi feito:
- **Validação da arquitetura de dados:** Reforçamos a separação clara de responsabilidades entre SQL (Gold) e Power BI (DAX), confirmando que a mediana histórica acumulada deve permanecer no SQL por ser um benchmark estrutural do negócio.
- **Definição do objetivo analítico:** Estabelecemos que o Dashboard Operacional é **preventivo, não reativo**, atuando como radar de risco e instrumento de priorização de ação.
- **Estruturação das abas operacionais:** Detalhamos as duas abas do dashboard operacional, cada uma com papel e estrutura bem definidos.
- **Design system consolidado:** Adotamos identidade visual SaaS moderna (light mode, cards com sombras, cantos arredondados), ícones semânticos consistentes e títulos dinâmicos em DAX.

### Decisões técnicas:

#### Arquitetura: SQL vs DAX
- **SQL (Camada Gold):** Responsável por cálculos pesados, métricas históricas, agregações complexas e tudo que não depende do contexto de filtro do usuário.
- **Power BI (DAX):** Responsável por cálculos contextuais, projeções dinâmicas e métricas dependentes de período, filtros e interação.
- **Mediana histórica acumulada:** Confirmado que deve permanecer na Gold por ser um benchmark estrutural que não depende de interação do usuário.
- **Projeções e status de risco:** Calculados em DAX por dependerem diretamente do contexto temporal e filtros aplicados pelo usuário.

#### Aba 1 — Operacional (Leitura Rápida / Escaneável)

**Objetivo:** Permitir entendimento em poucos segundos sobre controle orçamentário, ritmo de consumo e principais riscos.

**KPIs (4 cards):**
- Total Orçado do Mês
- Total Realizado até a Data Atual
- % do Orçamento Consumido
- % do Mês Decorrido

**Visual Principal:** Gráfico de linhas com três curvas (Orçamento ideal acumulado, Realizado acumulado, Mediana histórica acumulada) para identificar desvios de ritmo, antecipação de estouros ou consumo abaixo do padrão.

**Visuais Apoiadores:**
1. **Matriz de Risco (Centro de Custo):** % do orçamento consumido, status de risco e semáforo (🔴 Realizado > Orçado | 🟠 ≥ 80% | 🟢 < 80%). Decisão consciente de não detalhar por categoria para manter leitura rápida.
2. **Top 5 Centros de Custo com Maior Risco:** Barras horizontais ordenadas por maior consumo ou projeção de estouro.

**Sistema de Projeção:** Status simples ("Tende a Estourar", "Dentro do Esperado", "Abaixo do Ritmo") como coluna adicional na matriz e base para o Top 5.

#### Aba 2 — Operacional (Detalhamento Controlado)

**Objetivo:** Investigação objetiva sem transformar o dashboard em ERP.

**KPIs (5 cards):**
- Lançamentos totais do período
- Total realizado do período
- Desvio do orçamento (R$)
- Total a pagar (pendentes)
- Previsão de resultado final do mês

**Visual Principal:** Tabela de lançamentos (Centro de custo, Categoria, Fornecedor, Data, Valor, Status do pagamento) para validação e conferência.

**Bloco Lateral:** Filtros adicionais, rankings pontuais e métricas auxiliares para remover excesso de colunas da tabela principal.

#### Design System e UI/UX

**Identidade Visual:**
- Estilo SaaS moderno, light mode como padrão
- Fundo: #F3F4F8 | Cards: #FFFFFF
- Cantos arredondados e sombras suaves

**Sidebar:** Não retrátil (decisão consciente para equilibrar elegância, simplicidade e viabilidade técnica). Uso de tooltips para reforço semântico.

**Home:** Capa/menu de navegação, não um dashboard analítico. Função de orientar e permitir escolha clara entre dashboards.

**Iconografia:** Ícones semânticos, neutros, mesma família visual (Realizado: Check | Desvio: Setas divergentes | Pendentes: Relógio | Previsão: Tendência).

**Títulos Dinâmicos:** Implementados em DAX para contexto dinâmico e melhor storytelling.

### Governança e Boas Práticas:
- **Refatoração pós-entrega:** Planejada etapa futura de limpeza, simplificação e organização do SQL, mantendo legibilidade e facilidade de manutenção.
- **Títulos dinâmicos em DAX:** Permitem contexto dinâmico, clareza e melhor narrativa analítica.

### Status ao final do dia:
- Estrutura conceitual do dashboard operacional fechada
- Duas abas operacionais mockadas em PowerPoint
- Arquitetura, UI e objetivo analítico totalmente alinhados
- Pronto para iniciar a implementação no Power BI

### Próximos passos:
- [ ] Implementar o modelo semântico no Power BI
- [ ] Criar as medidas DAX necessárias
- [ ] Construir as páginas Operacionais no Power BI
- [ ] Validar métricas e alertas com dados reais
- [ ] Implementar sistema de navegação e Home

---

# [26/01/2026] Implementação do Dashboard Operacional e Resolução de Desafios DAX

## O que foi feito

- **Criação da view `vw_gold_lancamentos_diario`**  
  Desenvolvimento de uma estrutura SQL que preenche todos os dias do mês (inclusive dias sem lançamentos) com acumulados MTD por Centro de Custo e Categoria.

- **Implementação das medidas DAX principais**  
  Construção das métricas:
  - Orçado Ideal MTD  
  - Realizado MTD  
  - Projeção Fechamento MTD com lógica de benchmark histórico

- **Resolução de problemas de plotagem**  
  Debug e correção de múltiplos problemas que impediam a visualização correta das curvas no gráfico de linhas.

- **Finalização da primeira aba operacional**  
  Dashboard funcional com KPIs, gráfico de tendências e projeção híbrida.

---

## Decisões Técnicas

### Arquitetura SQL: View com Grid Completo

#### Problema identificado

A view `vw_gold_lancamentos` original tinha granularidade por lançamento (fornecedor, campanha), causando duplicações ao plotar no Power BI.

#### Solução implementada

- Criação de uma view agregada com `CROSS JOIN` entre:
  - `dim_calendario`
  - Todas as combinações existentes de Centro de Custo + Categoria
- Preenchimento de dias sem movimento com:
  ```sql
  valor_dia = 0
  ```
- Uso de Window Function para acumulado:
  ```sql
  SUM() OVER (
      PARTITION BY ano, mes, id_centro_custo, id_categoria
      ORDER BY data
  )
  ```
  Gerando `gasto_MTD_CC_CAT` no SQL, eliminando complexidade no DAX.

#### Tamanho controlado

~50–100k linhas para 2 anos de dados (aceitável para performance).

---

### Projeção de Fechamento: Abordagem Híbrida

#### Método escolhido

Combinação de:
- Projeção Linear (30%)
- Projeção baseada em Benchmark Histórico (70%)

#### Justificativa técnica

- **Projeção Linear**  
  `(Realizado / DiaAtual × DiasNoMes)`  
  Assume ritmo constante, mas ignora sazonalidade.

- **Projeção Histórica**  
  `(Realizado / PesoAtual × PesoFinal)`  
  Respeita padrões históricos, mas pode errar em meses atípicos.

A média ponderada 30/70 equilibra os dois comportamentos.

#### Fórmula implementada

```DAX
ProjeçãoFinal =
    (ProjeçãoLinear * 0.3) + (ProjeçãoHistórica * 0.7)

ProjeçãoNoDia =
    RealizadoAteHoje +
    ((ProjeçãoFinal - RealizadoAteHoje) *
     DIVIDE(PesoGrafico - PesoAtual, PesoFinal - PesoAtual))
```

---

## Resolução de Problemas de Plotagem

### Problema 1: Orçado Ideal plotava apenas 1 ponto (dia 30)

#### Causa

Relacionamento `vw_gold_orcamento[data_orcamento]` (sempre último dia do mês) com `dim_calendario[data]` filtrava apenas o dia 30.

#### Solução

- Criação da coluna `ano_mes` em ambas as tabelas
- Relacionamento muitos-para-muitos
- Uso de:
  ```DAX
  REMOVEFILTERS(dim_calendario[data])
  ```
  Para ignorar o filtro de dia específico.

---

### Problema 2: Realizado MTD plotava “montanha russa” (não acumulava)

#### Causas

1. View original tinha múltiplas linhas por dia (granularidade fina demais).
2. Coluna `gasto_MTD` particionada por fornecedor/campanha, causando múltiplos acumulados por dia.
3. Relacionamentos inativos entre `vw_gold_lancamentos_diario` e dimensões de Centro de Custo/Categoria não propagavam filtros.

#### Solução

- Criação da view `vw_gold_lancamentos_diario` com:
  - Agregação diária
  - Acumulado pré-calculado por CC/Categoria
- Ativação dos relacionamentos no modelo semântico.

---

### Problema 3: Projeção plotava apenas 1 ponto (dia 20)

#### Causa

Variáveis `RealizadoAteHoje` e `PesoAtual` retornavam BLANK no contexto do gráfico devido à propagação de filtros.

#### Solução

Uso de:
```DAX
REMOVEFILTERS(dim_calendario)
REMOVEFILTERS()
```
Para forçar cálculo fora do contexto de linha do visual, garantindo valores estáveis para todos os dias.

---

## Boas práticas adotadas

- **Separação de responsabilidades**
  - SQL calcula acumulados estruturais (independentes de filtro)
  - DAX calcula métricas contextuais (dependentes de filtro)

- **Proteção contra BLANK**
  - Uso sistemático de `NULLIF`
  - `NOT ISBLANK()`
  - Validações antes de divisões

- **Debug incremental**
  - Criação de medidas intermediárias para validar cada variável isoladamente antes de montar a lógica completa.

- **Simplicidade sobre complexidade**
  - Escolha consciente de interpolação linear simples para a projeção ao invés de métodos mais sofisticados que aumentariam a complexidade sem ganho prático.

---

## Aprendizados técnicos

### Contexto de filtro em DAX

Compreensão profunda de:
- Como relacionamentos e filtros visuais propagam para medidas
- Quando usar `REMOVEFILTERS`, `ALL` ou `CALCULATE` para controlar esse comportamento

### Granularidade importa

- Views SQL precisam ter a granularidade correta para o consumo no Power BI.
- Granularidade muito fina causa duplicações.
- Granularidade muito grossa impede drill-down.

### Performance vs Flexibilidade

- Pré-calcular no SQL: mais rápido, menos flexível
- Calcular no DAX: mais lento, mais flexível
- Escolha depende do caso de uso.

---

## Status ao final do dia

- Dashboard Operacional (Aba 1 - Monitoramento) 100% funcional.
- Três curvas plotando corretamente: Orçado Ideal, Realizado e Projeção.
- KPIs principais calculados e exibindo valores corretos.
- Projeção híbrida implementada com lógica defensiva contra valores atípicos.

---

## Próximos passos

- Implementar Aba 2 (Detalhamento) com tabela de lançamentos e filtros auxiliares
- Adicionar matriz de risco por Centro de Custo com semáforo
- Implementar sistema de navegação entre abas
- Refinar identidade visual e UI/UX conforme mockup
- Validar performance com volume real de dados
