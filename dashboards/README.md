# Dashboard — Visualização e Analytics

## Responsabilidade

Camada de consumo final do pipeline. Consome diretamente as views da camada Gold sem transformações adicionais no Power Query, agregações diárias, medianas históricas, YTD, MoM e YoY chegam prontos do SQL. O Power BI foca em relacionamentos, contexto de filtro e visualização.

O relatório está organizado em quatro páginas com contextos analíticos distintos: monitoramento preventivo intra-mês e análise executiva retrospectiva. A navegação entre páginas é feita pelo menu lateral com botões dedicados.

Publicado no **Power BI Service**.

---

## 📂 Estrutura de Arquivos

```
dashboards/
├── README.md
└── controle_orcamentario.pbix
```

Foi trabalhado um arquivo único com navegação interna por páginas para evitar duplicação do modelo semântico, simplificar o versionamento e garantir consistência de métricas entre as visões.

---

## 📊 Páginas

### 1. Operacional — Monitoramento

Monitoramento preventivo intra-mês: ritmo de consumo vs orçado ideal e semáforo de risco por centro de custo.

![Operacional — Monitoramento](../docs_e_imagens/dash_operacional_monitoramento.png)

**Destaques:**
- Gráfico de linhas com quatro séries: Orçado Ideal MTD, Realizado MTD, Mediana Histórica MTD e Projeção de Fechamento
- Orçado Ideal calculado em DAX usando `peso_do_dia` — distribuição não-linear do orçamento mensal conforme ritmo real histórico de gastos
- Projeção de fechamento baseada na taxa de gasto diária atual
- Tabela de indicadores de risco por centro de custo com semáforo: estouro confirmado, atenção e dentro do esperado

**Views consumidas:** `vw_gold_lancamentos`, `vw_gold_orcamento`, `vw_gold_referencia_mtd`

---

### 2. Operacional — Detalhamento

Detalhamento transacional do período com visão de pendências financeiras e ranking por categoria e fornecedor.

![Operacional — Detalhamento](../docs_e_imagens/dash_operacional_detalhamento.png)

**Destaques:**
- Tabela de lançamentos agregados por dia, centro de custo, categoria e fornecedor com status de pagamento e % do período acumulado
- KPIs de pendências: total pendente e % ainda pendente
- Top 5 categorias e Top 5 fornecedores por volume

**View consumida:** `vw_gold_lancamentos_consolidados_dia`

---

### 3. Analytics — Performance Orçamentária

Visão executiva retrospectiva sobre a aderência ao orçamento por mês e por centro de custo.

![Analytics — Performance Orçamentária](../docs_e_imagens/dash_analytics_performance.png)

![Analytics — Performance Orçamentária](../docs_e_imagens/dash_analytics_performance_tooltip.png)

**Destaques:**
- Gráfico combinado: barras agrupadas (Orçado vs Realizado) com linha de desvio sobreposta
- KPIs anuais: Orçado YTD, Realizado YTD, Desvio Absoluto e Desvio Percentual
- Matriz de desvio por centro de custo × mês com formatação condicional por intensidade
- Tooltip por mês: orçado, realizado, desvio do mês, desvio acumulado YTD — cor indica estouro ou aderência

**Views consumidas:** `vw_gold_orcamento`, `vw_gold_realizado`

---

### 4. Analytics — Evolução e Tendências

Análise de crescimento e sazonalidade de gastos com comparativo entre anos.

![Analytics — Evolução e Tendências](../docs_e_imagens/dash_analytics_tendencias.png)

![Analytics — Evolução e Tendências](../docs_e_imagens/dash_analytics_tendencias_tooltip.png)

**Destaques:**
- Gráfico de área comparando 2023 vs 2024 para leitura de sazonalidade
- Gráfico de colunas com realizado mensal e YoY % mensal como rótulo — variação em relação ao mesmo mês do ano anterior
- KPIs de variação: YoY (%), MoM (%), Acumulado vs LY
- Top 5 centros de custo com maior crescimento YoY e Top 5 com maior crescimento MoM
- Tooltip por mês: realizado, orçado, YoY, MoM e desvio vs orçado — cor indica estouro ou aderência
- Métricas temporais chegam prontas da Gold via `LAG()` — calculadas no SQL, sem risco de distorção por meses sem lançamentos

**Views consumidas:** `vw_gold_realizado`

---

## 🎯 Decisões Técnicas

### Cálculos no SQL, não no Power BI

Cálculos estruturais são resolvidos no SQL Server (camada Gold) e chegam prontos para consumo. O Power BI foca em relacionamentos, contexto de filtro e visualização.

### Separação de views somáveis vs. de referência

A `vw_gold_referencia_mtd` não é agregada via `SUM()`. É consultada pontualmente via `CALCULATE(..., dia = DiaAtual)`, evitando distorção de benchmarks ao filtrar múltiplos centros de custo simultaneamente.

### Orçado Ideal não-linear

O orçamento mensal é distribuído conforme o `peso_do_dia` (percentual mediano acumulado histórico por dia) em vez de distribuição linear. Reflete o ritmo real de consumo da empresa.

### Medida DAX central

```dax
Orçado Ideal MTD = 
VAR DataAtual = [DATA_ATUAL]

VAR IdMesAtual =
    YEAR(DataAtual) * 100 + MONTH(DataAtual)

RETURN
SUMX(
    SUMMARIZE(
        vw_gold_orcamento,
        dim_centro_de_custo[id_centro_de_custo],
        dim_categoria[id_categoria]
    ),
    VAR OrcamentoMensal =
        CALCULATE(
            SUM(vw_gold_orcamento[Orcado_mensal]),
            dim_mes[ano_mes] = IdMesAtual
        )

    VAR PesoHistorico =
        CALCULATE(
            MAX(vw_gold_referencia_mtd[peso_do_dia])
        )

    RETURN
        OrcamentoMensal * PesoHistorico
)
```

---

## 📋 Modelo de Dados

| View | Tipo | Granularidade | Somável? | Uso principal |
|---|---|---|---|---|
| `vw_gold_orcamento` | Fato | Mensal | ✅ Sim | Planejamento financeiro |
| `vw_gold_realizado` | Fato | Mensal | ✅ Sim | Análise executiva retrospectiva |
| `vw_gold_lancamentos` | Fato | Por lançamento | ✅ Sim | KPIs operacionais |
| `vw_gold_lancamentos_consolidados_dia` | Fato | Diária agregada | ✅ Sim | Tabela de detalhamento |
| `vw_gold_lancamentos_diarios` | Fato | Diária completa | ✅ Sim | Grid diário com acumulado MTD |
| `vw_gold_referencia_mtd` | Referência | Dia do mês | ❌ Não | Linhas de benchmark e orçado ideal |

Relacionamentos via `dim_calendario` (data), `id_centro_de_custo` e `id_categoria`. A `vw_gold_referencia_mtd` não possui relacionamento direto com a dimensão de datas, ela é filtrada pelo campo `dia` de forma independente.

---

O dashboard fecha o ciclo do pipeline: dados que chegaram brutos, inconsistentes e dispersos na Bronze são entregues aqui como informação confiável e pronta para decisão. Do monitoramento intra-mês à análise retrospectiva, cada visual consome uma base que já passou por diagnóstico, limpeza e modelagem.