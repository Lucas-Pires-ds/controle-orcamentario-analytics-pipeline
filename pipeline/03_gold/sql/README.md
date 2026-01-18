# Camada Gold — Métricas Analíticas

## Responsabilidade

A camada Gold é responsável por **preparar dados para consumo analítico**, criando views especializadas com métricas pré-calculadas e prontas para uso no Power BI.

**Objetivo**: Reduzir lógica no BI e entregar bases otimizadas para análise de negócio.

---

## 🎯 Características

- 3 views independentes com responsabilidades bem definidas
- Métricas avançadas pré-calculadas (YTD, MoM, YoY)
- Proteção contra erros comuns (divisão por zero, nulos)
- Flags de anomalias e valores atípicos
- Cruzamento Orçado vs Realizado realizado no Power BI

---

## 📂 Estrutura de Arquivos
```
gold/
├── README.md (este arquivo)
└── sql/
    └── 07_Views_golds.sql
```

---

## 📊 Views Implementadas

### 🎯 vw_gold_orcamento

**Propósito**: Consolidação mensal do orçamento com métricas agregadas

**Granularidade**: Mensal por centro de custo e categoria

**Campos principais**:
- Dimensões: Ano, Mês, Centro de custo, Categoria
- **Data_de_orcamento** (último dia do mês via `EOMONTH` - para relacionamento no BI)
- Valor orçado mensal
- Orçado YTD (acumulado no ano)
- Peso relativo por centro de custo
- Peso relativo por categoria
- Média mensal histórica
- Flag de valor atípico
- Status do dado (confiável ou suspeito)

**Exemplo de uso**:
```sql
SELECT 
    Ano, Mes,
    Centro_de_custo,
    Categoria,
    Orcado_mensal,
    Orcado_YTD,
    Peso_centro_custo,
    Flag_valor_atipico_orcamento
FROM vw_gold_orcamento
WHERE Ano = 2024 AND Status_dado = 'Dado confiavel'
ORDER BY Orcado_mensal DESC
```

---

### 📈 vw_gold_realizado

**Propósito**: Consolidação mensal do realizado com métricas avançadas de análise temporal

**Granularidade**: Mensal por centro de custo e categoria

**Campos principais**:
- Dimensões: Ano, Mês, Centro de custo, Categoria
- **Data_realizacao** (último dia do mês via `EOMONTH` - para relacionamento no BI)
- Valor realizado mensal
- Realizado YTD (acumulado no ano)
- MoM absoluto e percentual (Month over Month)
- YoY absoluto e percentual (Year over Year)
- Média mensal histórica
- Peso relativo por centro de custo
- Peso relativo por categoria
- Flag de valor atípico
- Flag de centro de custo coringa

**Decisão técnica crítica**: 

Uso da `dim_calendario` como base temporal via `RIGHT JOIN`:
```sql
FROM BASE B  
RIGHT JOIN (
    SELECT DISTINCT ano, mes FROM dim_calendario
) CAL ON B.Ano = CAL.ano AND B.Mes = CAL.mes
```

**Justificativa**: Garante continuidade temporal mesmo em meses sem lançamentos. Sem isso, `LAG()` poderia comparar meses não consecutivos, corrompendo cálculos de MoM e YoY.

**Exemplo de uso**:
```sql
SELECT 
    Ano_mes,
    Centro_de_custo,
    Categoria,
    Realizado,
    [Realizado YTD],
    MoM_abs,
    MoM_perc,
    YoY_perc,
    Flag_valor_atipico_realizado
FROM vw_gold_realizado
WHERE Ano = 2024
  AND Flag_centro_custo_coringa = 'Nao'
ORDER BY Realizado DESC
```

---


### 📄 vw_gold_lancamentos

**Propósito**: Base detalhada auditável para drill-down e investigação

**Granularidade**: Transação (diária)

**Campos principais**:
- Ano, Mês, Ano_mes, Data do lançamento
- Centro de custo, Categoria (IDs e nomes)
- Fornecedor, Campanha (IDs e nomes, com tratamento de nulos)
- Valor tratado e valor original
- Status de pagamento
- Flag de centro de custo coringa

**Características**:
- Preserva granularidade original da `fact_lancamentos`
- Enriquecimento dimensional completo via LEFT JOINs
- Nenhuma agregação aplicada (permite drill-down total)
- Tratamento de campanhas nulas: `COALESCE(nome_campanha, 'Sem_campanha')`

**Exemplo de uso**:
```sql
SELECT 
    Data_lancamento,
    Centro_de_custo,
    Categoria,
    Fornecedor,
    Campanha,
    Valor,
    Status_pagamento,
    Flag_centro_custo_coringa
FROM vw_gold_lancamentos
WHERE Ano = 2024 AND Mes = 12
  AND Flag_centro_custo_coringa = 'Nao'
ORDER BY Valor DESC
```

---

## 🎯 Decisões de Arquitetura

### Separação em 3 Views Independentes

A camada Gold foi dividida em views especializadas (Orçamento, Realizado e Lançamentos) ao invés de uma view consolidada.

**Justificativa**:

- Cada view tem responsabilidade única e clara
- Evita redundância de dados pré-calculados
- Facilita manutenção (mudanças em uma view não afetam outras)
- Permite consumo flexível no Power BI (analista decide como cruzar)

**Custo aceito**: Power BI precisa relacionar as views. Esse custo é baixo e compensa pela clareza organizacional.

### Cruzamento Orçado vs Realizado no Power BI

O cruzamento entre orçamento e realizado não é feito na camada Gold.

**Justificativa**:

- Diferentes análises podem requerer cruzamentos diferentes
- Evita criar dados pré-agregados que podem não ser usados
- Mantém separação de responsabilidades (SQL prepara, BI analisa)
- Regras de cruzamento podem mudar sem reprocessar dados

**Implementação no Power BI**: Relacionamentos entre tabelas via campos de granularidade comum (Ano, Mês, Centro de custo, Categoria).

---

## 📊 Métricas Calculadas

### YTD (Year-to-Date)

Acumulado do início do ano até o mês corrente:
```sql
SUM(valor) OVER (
    PARTITION BY Ano, ID_centro_de_custo, ID_categoria 
    ORDER BY Mes
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**Partição**: Por ano, centro de custo e categoria  
**Ordenação**: Por mês  
**Janela**: Do início do ano até o mês atual

---

### MoM (Month over Month)

Comparação com o mês anterior (absoluto e percentual):
```sql
-- Valor do mês anterior
LAG(Realizado, 1) OVER (
    PARTITION BY ID_Centro_de_custo, ID_Categoria 
    ORDER BY Ano, Mes
)

-- MoM Absoluto
Realizado - valor_mes_anterior

-- MoM Percentual
Realizado / NULLIF(valor_mes_anterior, 0) - 1
```

**Uso do LAG**: Busca o valor 1 mês antes na partição  
**NULLIF**: Protege contra divisão por zero  
**Retorno**: Percentual de crescimento/queda

---

### YoY (Year over Year)

Comparação com o mesmo mês do ano anterior:
```sql
-- Valor do mesmo mês no ano anterior
LAG(Realizado, 12) OVER (
    PARTITION BY ID_Centro_de_custo, ID_Categoria 
    ORDER BY Ano, Mes
)

-- YoY Absoluto
Realizado - valor_mesmo_mes_ano_anterior

-- YoY Percentual  
Realizado / NULLIF(valor_mesmo_mes_ano_anterior, 0) - 1
```

**Uso do LAG(12)**: Busca o valor 12 meses antes  
**Importância da continuidade temporal**: dim_calendario garante que LAG(12) sempre pega o mesmo mês do ano anterior

---

### Pesos Relativos

Percentual que cada linha representa do total do mês:
```sql
-- Peso do centro de custo
SUM(Realizado) OVER(
    PARTITION BY ID_Centro_de_custo, Ano, Mes
) 
/ 
NULLIF(SUM(Realizado) OVER (PARTITION BY Ano, Mes), 0)

-- Peso da categoria
SUM(Realizado) OVER(
    PARTITION BY ID_Categoria, Ano, Mes
) 
/ 
NULLIF(SUM(Realizado) OVER (PARTITION BY Ano, Mes), 0)
```

**Numerador**: Total do centro/categoria no mês  
**Denominador**: Total geral do mês  
**Resultado**: Concentração percentual de gastos

---

### Flags de Anomalia

Identifica valores que desviam significativamente da média:
```sql
CASE 
    WHEN Realizado > 2 * AVG(NULLIF(Realizado, 0)) OVER (...) 
    THEN 'Valor_acima_do_normal'
    
    WHEN Realizado < 0.5 * AVG(NULLIF(Realizado, 0)) OVER (...) 
    THEN 'Valor_abaixo_do_normal'
    
    ELSE 'Valor_normal'
END
```

**Critério**: Valores 2x acima ou 50% abaixo da média histórica  
**Partição**: Por ano, centro de custo e categoria  
**Uso**: Alertas visuais no dashboard

---

## ⚠️ Proteções Implementadas

### Divisão por Zero

Todas as divisões utilizam `NULLIF` para evitar erros:
```sql
valor / NULLIF(total, 0)  -- Retorna NULL se total = 0
```

**Alternativa ao CASE**: Mais conciso que `CASE WHEN total = 0 THEN NULL ELSE valor/total END`

### Valores Nulos em Window Functions

Uso de `NULLIF` para excluir zeros de médias:
```sql
AVG(NULLIF(valor, 0)) OVER (...)  -- Ignora zeros no cálculo da média
```

### Continuidade Temporal

`dim_calendario` garante que todos os meses apareçam via `RIGHT JOIN`:
```sql
FROM BASE B
RIGHT JOIN (SELECT DISTINCT ano, mes FROM dim_calendario) CAL
    ON B.Ano = CAL.ano AND B.Mes = CAL.mes
```

**Efeito**: Meses sem lançamentos aparecem com `NULL` (tratado como 0 no BI)  
**Importância**: LAG(1) e LAG(12) sempre comparam meses consecutivos/equivalentes

---

## 📌 Resultado Final

As views Gold entregam:

- ✅ Métricas prontas para consumo no Power BI
- ✅ Cálculos complexos resolvidos na camada de dados
- ✅ Proteções contra erros comuns (divisão por zero, nulos)
- ✅ Flags de qualidade e anomalias
- ✅ Rastreabilidade mantida (flags de centro de custo coringa)

**Métricas disponíveis**:
- 2 métricas básicas (Orçado, Realizado)
- 2 acumulados (YTD para orçado e realizado)
- 4 comparativos temporais (MoM abs/%, YoY abs/%)
- 4 pesos relativos (centro de custo e categoria, para orçado e realizado)
- 2 médias históricas
- 2 flags de anomalia

**Total**: 16+ métricas pré-calculadas

---

## 📖 Próxima Etapa

As views Gold são consumidas no **Power BI**, onde:

- Relacionamentos entre views são criados no modelo de dados
- Cruzamento Orçado vs Realizado é realizado via relacionamentos ou medidas DAX
- Visualizações e KPIs são construídos sobre esta base confiável
- Filtros e slicers permitem análise interativa

📖 **[Documentação dos Dashboards](../../dashboards/)**

---