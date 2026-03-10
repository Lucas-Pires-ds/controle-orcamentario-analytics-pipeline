# 📊 Dashboard — Visualização e Analytics

> Camada de consumo final do pipeline. Transforma as views Gold em inteligência acionável para gestão orçamentária da Sage.

---

## Visão Geral

O dashboard é o ponto de entrega do projeto — onde os dados que passaram por Bronze, Silver e Gold se tornam decisões.

Construído em **Power BI**, consome diretamente as views da camada Gold sem transformações adicionais no Power Query. A lógica pesada já foi resolvida no SQL: agregações diárias, medianas históricas, YTD, MoM e YoY chegam prontos. O Power BI foca em relacionamentos, contexto de filtro e visualização.

O relatório está organizado em **quatro páginas funcionais**, separadas por contexto analítico: monitoramento preventivo intra-mês e análise executiva retrospectiva.

---

## Estrutura do Arquivo

```
dashboards/
├── README.md
└── controle_orcamentario.pbix
```

Arquivo único com navegação interna por páginas. Essa decisão evita duplicação do modelo semântico, simplifica o versionamento e garante consistência de métricas entre as visões.

---

## Páginas

### 1. Operacional — Monitoramento

Radar de risco do mês corrente. Permite identificar em segundos se o orçamento está sob controle e onde estão os maiores riscos — antes do fechamento.

![Operacional — Monitoramento](../docs_e_imagens/dash_operacional_monitoramento.png)
*Monitoramento preventivo intra-mês: ritmo de consumo vs orçado ideal (baseado em benchmark histórico) e semáforo de risco por centro de custo*

**O que responde:**
- Estamos consumindo o orçamento mais rápido ou mais devagar que o esperado?
- Quais centros de custo representam maior risco de estouro?
- O ritmo atual está alinhado com o comportamento histórico da empresa?

**Destaques técnicos:**
- Gráfico de linhas com quatro séries: Orçado Ideal MTD, Realizado MTD, Mediana Histórica MTD e Projeção de Fechamento
- Orçado Ideal calculado em DAX usando `peso_do_dia` (percentual mediano acumulado histórico), distribuindo o orçamento mensal conforme o ritmo real de gastos — não de forma linear
- Tabela de indicadores de risco por centro de custo com semáforo: estouro confirmado, atenção e dentro do esperado
- Projeção de fechamento baseada na taxa de gasto diária atual

**Views consumidas:** `vw_gold_lancamentos`, `vw_gold_orcamento`, `vw_gold_referencia_mtd`

---

### 2. Operacional — Detalhamento



![Operacional — Detalhamento](../docs_e_imagens/dash_operacional_detalhamento.png)
*Investigação de lançamentos: tabela diária com status de pagamento, pendências financeiras e ranking por categoria e fornecedor*

**O que responde:**
- Quais foram os principais lançamentos do período?
- Quanto ainda está pendente de pagamento?
- Quais categorias e fornecedores concentram mais gasto?

**Destaques técnicos:**
- Tabela de lançamentos por dia com status de pagamento e % do período acumulado
- KPIs de pendências: total pendente e % ainda pendente
- Top 5 categorias e Top 5 fornecedores por volume — painéis laterais contextuais
- Dados consumidos da `vw_gold_lancamentos` (granularidade diária, corretamente somável)

**Views consumidas:** `vw_gold_lancamentos`, `vw_gold_orcamento`

---

### 3. Analytics — Performance Orçamentária



![Analytics — Performance Orçamentária](../docs_e_imagens/dash_analytics_performance.png)
*Visão executiva retrospectiva: orçado vs realizado com linha de desvio e matriz de performance por centro de custo × mês*

**O que responde:**
- O gasto total está dentro do planejamento?
- Quais meses apresentaram maior desvio?
- Quais centros de custo são responsáveis pelos estouros?

**Destaques técnicos:**
- Gráfico combinado: barras agrupadas (Orçado vs Realizado) com linha de desvio sobreposta
- KPIs anuais: Orçado YTD, Realizado YTD, Desvio Absoluto (R$) e Desvio Percentual (%)
- Matriz de desvio por centro de custo × mês com formatação condicional por intensidade
- Métricas pré-calculadas na camada Gold via `vw_gold_realizado`

**Views consumidas:** `vw_gold_orcamento`, `vw_gold_realizado`

---

### 4. Analytics — Evolução e Tendências

Análise de crescimento e sazonalidade de gastos ao longo do tempo.

![Analytics — Evolução e Tendências](../docs_e_imagens/dash_analytics_tendencias.png)
*Análise de crescimento: comparativo YoY, ranking de crescimento estrutural e top 5 centros de custo com maior variação*

**O que responde:**
- O gasto atual é maior que o mesmo período do ano passado?
- Qual a tendência de crescimento mês a mês?
- Quais áreas tiveram maior aumento de custo?

**Destaques técnicos:**
- Gráfico de linhas comparando anos (2023 vs 2024) para leitura de sazonalidade
- KPIs de variação: YoY (%), MoM (%), Acumulado vs LY (% e R$)
- Scatter plot de crescimento estrutural: YoY % × YoY Absoluto por centro de custo
- Top 5 centros de custo com maior crescimento YoY
- Todas as métricas temporais (MoM, YoY) chegam prontas da Gold via `LAG()` — calculadas uma vez no SQL, sem risco de distorção por meses sem lançamentos

**Views consumidas:** `vw_gold_realizado`

---

## Decisões de Arquitetura

### Push-down computation

Cálculos estruturais são resolvidos no SQL Server (camada Gold) e chegam prontos para consumo. O Power BI fica responsável por relacionamentos, contexto de filtro e visualização — sem recalcular o que já foi feito na origem.

### Separação de views somáveis vs. de referência

A `vw_gold_referencia_mtd` não é agregada via `SUM()`. É consultada pontualmente via `CALCULATE(..., dia = DiaAtual)`, evitando a distorção de benchmarks ao filtrar múltiplos centros de custo simultaneamente — problema identificado e corrigido na refatoração v1.0 → v2.0.

### Orçado Ideal não-linear

Em vez de distribuir o orçamento uniformemente ao longo do mês, o cálculo usa o `peso_do_dia`: percentual mediano acumulado histórico por dia. O resultado reflete o ritmo real de consumo da empresa, tornando o benchmark estatisticamente mais robusto.

### Medida DAX central

```dax
Orçado Ideal MTD =
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
VAR PesoHistorico =
    CALCULATE(
        MAX(vw_gold_referencia_mtd[peso_do_dia]),
        vw_gold_referencia_mtd[dia] = DiaAtual,
        ALLEXCEPT(vw_gold_referencia_mtd, vw_gold_referencia_mtd[id_centro_custo], vw_gold_referencia_mtd[id_categoria])
    )
VAR OrcamentoMensal = [Total Orçado]
RETURN
    IF(
        NOT ISBLANK(OrcamentoMensal) && NOT ISBLANK(PesoHistorico),
        OrcamentoMensal * PesoHistorico,
        BLANK()
    )
```

---

## Modelo de Dados

| View | Tipo | Granularidade | Somável? | Uso principal |
|---|---|---|---|---|
| `vw_gold_orcamento` | Fato | Mensal | ✅ Sim | Planejamento financeiro |
| `vw_gold_realizado` | Fato | Mensal | ✅ Sim | Análise executiva retrospectiva |
| `vw_gold_lancamentos` | Fato | Diária | ✅ Sim | KPIs operacionais, tabela de lançamentos |
| `vw_gold_referencia_mtd` | Referência | Dia do mês | ❌ Não | Linhas de benchmark e orçado ideal |

Relacionamentos via `dim_calendario` (data), `id_centro_custo` e `id_categoria`. A `vw_gold_referencia_mtd` não possui relacionamento direto com a dimensão de datas — é filtrada pelo campo `dia` de forma independente.
