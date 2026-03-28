# Camada Gold — Métricas Analíticas

## Responsabilidade

Preparar os dados da Silver para consumo analítico no Power BI, entregando views com métricas pré-calculadas e estrutura otimizada para visualização.

---

## 📂 Estrutura de Arquivos

```
03_gold/
├── README.md
└── sql/
    ├── 06_vw_gold_orcamento.sql
    ├── 06_vw_gold_realizado.sql
    ├── 06_vw_gold_lancamentos.sql
    ├── 06_vw_gold_referencia_mtd.sql
    ├── 06_vw_gold_lancamentos_diarios.sql
    └── 06_vw_gold_lancamentos_consolidados_dia.sql
```

---

## 📊 Views Implementadas

| View | Granularidade | Propósito |
|------|---------------|-----------|
| `vw_gold_orcamento` | Mensal por centro de custo e categoria | Consolidação do orçamento com métricas agregadas |
| `vw_gold_realizado` | Mensal por centro de custo e categoria | Consolidação do realizado com comparativos temporais |
| `vw_gold_lancamentos` | Por lançamento individual | Base transacional para KPIs e drill-down |
| `vw_gold_referencia_mtd` | Dia do mês por centro de custo e categoria | Benchmark histórico de consumo diário |
| `vw_gold_lancamentos_diarios` | Diária por centro de custo, categoria e status | Grid diário completo com acumulado MTD |
| `vw_gold_lancamentos_consolidados_dia` | Diária por centro de custo, categoria e fornecedor | Agregação diária para o visual de detalhamento |

**Decisão arquitetural**: o cruzamento entre orçado e realizado é feito no Power BI via relacionamentos, não na camada de dados. 

---

## 🎯 Métricas por View

### vw_gold_orcamento
- Orçado mensal
- Orçado YTD (acumulado no ano)
- Peso relativo por centro de custo e por categoria
- Mediana histórica mensal
- Flag de valor atípico
- Flag de dado suspeito (outliers identificados na Silver)

### vw_gold_realizado
- Realizado mensal
- Realizado YTD
- MoM absoluto e percentual
- YoY absoluto e percentual
- Peso relativo por centro de custo e por categoria
- Mediana histórica mensal
- Flag de valor atípico
- Flag de centro de custo coringa

### vw_gold_lancamentos
- Total do dia por combinação de dimensões
- Gasto MTD acumulado até cada data
- Status de pagamento normalizado
- Enriquecimento dimensional completo (nomes de centro de custo, categoria, fornecedor, campanha)

### vw_gold_referencia_mtd
- `peso_do_dia`: percentual mediano do mês que costuma estar gasto até cada dia
- `valor_mediano_dia`: valor mediano de gasto MTD até cada dia em meses anteriores

### vw_gold_lancamentos_diarios
- Grid diário completo incluindo dias sem lançamento (via CROSS JOIN com `dim_calendario`)
- Gasto MTD acumulado

### vw_gold_lancamentos_consolidados_dia
- Agregação diária por centro de custo, categoria, fornecedor e status de pagamento
- Participação percentual de cada linha no total do mês
- Base do visual de tabela na aba de detalhamento do dashboard

---

## 🧠 Decisões Técnicas

### Separação entre vw_gold_lancamentos e vw_gold_referencia_mtd

Originalmente eram uma view única. O problema era que ao consumir no Power BI com filtros de múltiplos centros de custo ou categorias, as medianas históricas eram somadas, gerando valores incorretos.

A solução foi separar em duas views com granularidades e propósitos distintos:

- `vw_gold_lancamentos` entrega valores transacionais somáveis, com granularidade por lançamento individual
- `vw_gold_referencia_mtd` entrega benchmarks estatísticos de referência, com granularidade de dia do mês (1 a 31)

A segunda **não deve ser usada em somatórios** — serve apenas como linha de referência em gráficos e como base para o cálculo do orçado ideal via DAX.

### Por que três views de lançamentos

As três views de lançamentos têm granularidades e propósitos distintos que justificam a separação:

`vw_gold_lancamentos` opera no nível de lançamento individual, cada linha é uma transação. É a base para KPIs e métricas que precisam do grau máximo de detalhe.

`vw_gold_lancamentos_consolidados_dia` agrega os lançamentos por combinação de centro de custo, categoria, fornecedor e dia. Sem essa agregação, o visual de tabela da aba de detalhamento mostraria múltiplas linhas para o mesmo fornecedor no mesmo dia — o que prejudica a leitura. Só contém dias com movimento.

`vw_gold_lancamentos_diarios` também agrega por dia, mas via CROSS JOIN com a `dim_calendario` garante que todos os dias do período apareçam na série, inclusive os dias sem lançamento, preenchidos com zero. Isso é necessário para o cálculo do MTD ser contínuo, pois sem os dias zerados, o acumulado pularia datas e as curvas do dashboard ficariam incorretas.

A distinção essencial entre as duas últimas: `consolidados_dia` só tem dias com movimento, o que é correto para uma tabela de detalhamento. `lancamentos_diarios` tem todos os dias, o que é necessário para séries temporais contínuas.

### Corte histórico na vw_gold_referencia_mtd

O benchmark é calculado apenas sobre dados anteriores a novembro de 2024. O corte é aplicado depois do cálculo das métricas mensais, pois se fosse aplicado antes, meses com poucos dias registrados entrariam no cálculo com zeros artificiais, distorcendo as medianas.

### Mediana como referência em todas as flags e benchmarks

Todas as métricas de referência e flags de anomalia usam mediana em vez de média. Isso vale tanto para o `peso_do_dia` da `vw_gold_referencia_mtd` quanto para as flags de valor atípico da `vw_gold_orcamento` e `vw_gold_realizado`.

A razão é a mesma em todos os casos: a média é sensível a outliers e distorceria o benchmark. A mediana reflete o comportamento típico da série independentemente de valores extremos.

Na implementação, `PERCENTILE_CONT(0.5)` é calculado com `DISTINCT` em uma CTE separada antes do SELECT final, isso evita que o JOIN multiplique linhas ao cruzar a mediana por partição com os dados mensais.

---

## 📐 Lógica das Métricas

**YTD**: acumulado do início do ano até o mês corrente, particionado por ano, centro de custo e categoria.

**MoM**: comparação com o mês imediatamente anterior via `LAG(1)`, particionado por centro de custo e categoria, ordenado por ano e mês. Obs: Depende da continuidade temporal garantida pela `dim_calendario`.

**YoY**: comparação com o mesmo mês do ano anterior via `LAG(12)`, mesma lógica do MoM.

**MTD**: acumulado diário dentro do mês, particionado por mês e combinação de dimensões, ordenado por data.

**Pesos relativos**: participação percentual de cada centro de custo ou categoria no total do mês, a fórmula matemática é total da linha / total geral do período.

**Flags de anomalia**: valores acima de 2x a mediana histórica ou abaixo de 50% da mediana são sinalizados. A mediana é calculada por ano, centro de custo e categoria via `PERCENTILE_CONT(0.5)` com `DISTINCT` em CTE separada.

**Peso do dia**: mediana histórica do percentual acumulado até cada dia do mês, `PERCENTILE_CONT(0.5)` sobre `gasto_MTD / total_do_mes`, particionado por dia, centro de custo e categoria.

---

## 📖 Próxima etapa

**[Dashboards →](../../dashboards/)**