# Camada Gold — Métricas Analíticas
 
## Responsabilidade
 
Preparar os dados da Silver para consumo analítico no Power BI, entregando views com métricas pré-calculadas e estrutura otimizada para visualização.
 
---
 
## 📂 Estrutura de Arquivos
 
```
03_gold/
├── README.md
└── sql/
    └── 07_Views_golds.sql
```
 
---
 
## 📊 Views Implementadas
 
| View | Granularidade | Propósito |
|------|---------------|-----------|
| `vw_gold_orcamento` | Mensal por centro de custo e categoria | Consolidação do orçamento com métricas agregadas |
| `vw_gold_realizado` | Mensal por centro de custo e categoria | Consolidação do realizado com comparativos temporais |
| `vw_gold_lancamentos` | Diária por centro de custo, categoria, fornecedor e campanha | Base transacional para drill-down e KPIs |
| `vw_gold_referencia_mtd` | Dia do mês por centro de custo e categoria | Benchmark histórico de consumo diário |
| `vw_gold_lancamentos_diarios` | Diária por centro de custo, categoria e status | Grid diário completo com acumulado MTD |
 
**Decisão arquitetural**: o cruzamento entre orçado e realizado é feito no Power BI via relacionamentos, não na camada de dados. Cada view tem responsabilidade única, o analista decide como cruzar.
 
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
- Enriquecimento dimensional completo (nomes de CC, categoria, fornecedor, campanha)
 
### vw_gold_referencia_mtd
- `peso_do_dia`: percentual mediano do mês que costuma estar gasto até cada dia
- `valor_mediano_dia`: valor mediano de gasto MTD até cada dia em meses anteriores
 
### vw_gold_lancamentos_diarios
- Grid diário completo incluindo dias sem lançamento (via CROSS JOIN com `dim_calendario`)
- Gasto MTD acumulado por status de pagamento
 
---
 
## 🧠 Decisões Técnicas
 
### Separação entre vw_gold_lancamentos e vw_gold_referencia_mtd
 
Originalmente eram uma view única. O problema: ao consumir no Power BI com filtros de múltiplos centros de custo ou categorias, as medianas históricas eram somadas — o que não tem significado estatístico. Mediana de um conjunto não é igual à soma das medianas das partes.
 
A solução foi separar em duas views com granularidades e propósitos distintos:
 
- `vw_gold_lancamentos` entrega valores transacionais somáveis, com granularidade diária por transação
- `vw_gold_referencia_mtd` entrega benchmarks estatísticos de referência, com granularidade de dia do mês (1 a 31)
 
A segunda **não deve ser usada em somatórios** — serve apenas como linha de referência em gráficos e como base para o cálculo do orçado ideal via DAX.
 
### Corte histórico na vw_gold_referencia_mtd
 
O benchmark é calculado apenas sobre dados anteriores a novembro de 2024. O corte é aplicado depois do cálculo das métricas mensais — se fosse aplicado antes, meses com poucos dias registrados entrariam no cálculo com zeros artificiais, distorcendo as medianas.
 
### Mediana como referência em todas as flags e benchmarks
 
Todas as métricas de referência e flags de anomalia usam mediana em vez de média. Isso vale tanto para o `peso_do_dia` da `vw_gold_referencia_mtd` quanto para as flags de valor atípico da `vw_gold_orcamento` e `vw_gold_realizado`.
 
A razão é a mesma em todos os casos: a média é sensível a outliers e distorceria o benchmark. A mediana reflete o comportamento típico da série independentemente de valores extremos.
 
Na implementação, `PERCENTILE_CONT(0.5)` é calculado com `DISTINCT` em uma CTE separada antes do SELECT final — isso evita que o JOIN multiplique linhas ao cruzar a mediana por partição com os dados mensais.
 
---
 
## 📐 Lógica das Métricas
 
**YTD**: acumulado do início do ano até o mês corrente, particionado por ano, centro de custo e categoria.
 
**MoM**: comparação com o mês imediatamente anterior via `LAG(1)`, particionado por centro de custo e categoria, ordenado por ano e mês. Depende da continuidade temporal garantida pela `dim_calendario`.
 
**YoY**: comparação com o mesmo mês do ano anterior via `LAG(12)`, mesma lógica do MoM.
 
**MTD**: acumulado diário dentro do mês, particionado por mês e combinação de dimensões, ordenado por data.
 
**Pesos relativos**: participação percentual de cada centro de custo ou categoria no total do mês, a fórmula matemática é total da linha / total geral do período.
 
**Flags de anomalia**: valores acima de 2x a mediana histórica ou abaixo de 50% da mediana são sinalizados. A mediana é calculada por ano, centro de custo e categoria via `PERCENTILE_CONT(0.5)` com `DISTINCT` em CTE separada.
 
**Peso do dia**: mediana histórica do percentual acumulado até cada dia do mês, `PERCENTILE_CONT(0.5)` sobre `gasto_MTD / total_do_mes`, particionado por dia, centro de custo e categoria.
 
---
 
## 📖 Próxima etapa
 
**[Dashboards →](../../dashboards/)**