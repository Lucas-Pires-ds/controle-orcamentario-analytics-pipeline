
CREATE OR ALTER VIEW vw_gold_lancamentos_diarios AS

WITH LANCAMENTOS_BASE AS (
    SELECT 
        FL.data_lancamento,
        CC.id_centro_de_custo AS id_centro_de_custo,
        CAT.id_categoria,
        REPLACE(FL.status_pagamento, 'Aberto', 'Pendente') AS status_pagamento,
        SUM(FL.valor) AS valor_dia
    FROM fact_lancamentos FL
    LEFT JOIN dim_centro_de_custo CC ON CC.id_centro_de_custo = FL.id_centro_de_custo
    LEFT JOIN dim_categoria CAT ON CAT.id_categoria = FL.id_categoria
    GROUP BY FL.data_lancamento, CC.id_centro_de_custo, CAT.id_categoria, REPLACE(FL.status_pagamento, 'Aberto', 'Pendente')
),
COMBINACOES AS (
    SELECT DISTINCT 
        id_centro_de_custo,
        id_categoria,
        status_pagamento
    FROM LANCAMENTOS_BASE
),
GRID_COMPLETO AS (
    SELECT 
        C.data,
        YEAR(C.data) AS ano,
        MONTH(C.data) AS mes,
        DAY(C.data) AS dia,
        CB.id_centro_de_custo,
        CB.id_categoria,
        CB.status_pagamento
    FROM dim_calendario C
    CROSS JOIN COMBINACOES CB
    WHERE C.data <= (SELECT MAX(data_lancamento) FROM fact_lancamentos)
),
DADOS_COMPLETOS AS (
    SELECT 
        G.data,
        G.ano,
        G.mes,
        G.dia,
        G.id_centro_de_custo,
        G.id_categoria,
        G.status_pagamento,
        COALESCE(L.valor_dia, 0) AS valor_dia
    FROM GRID_COMPLETO G
    LEFT JOIN LANCAMENTOS_BASE L 
        ON L.data_lancamento = G.data
        AND L.id_centro_de_custo = G.id_centro_de_custo
        AND L.id_categoria = G.id_categoria
        AND L.status_pagamento = G.status_pagamento
),
ACUMULADOS AS (
    SELECT 
        data AS data_lancamento,
        ano,
        mes,
        dia,
        id_centro_de_custo,
        id_categoria,
        status_pagamento,
        valor_dia,
        SUM(valor_dia) OVER (
            PARTITION BY ano, mes, id_centro_de_custo, id_categoria, status_pagamento
            ORDER BY data
            ROWS UNBOUNDED PRECEDING
        ) AS gasto_MTD_CC_CAT
    FROM DADOS_COMPLETOS
)
SELECT 
    data_lancamento,
    ano,
    mes,
    dia,
    id_centro_de_custo,
    id_categoria,
    status_pagamento,
    SUM(gasto_MTD_CC_CAT) AS gasto_MTD_agregado
FROM ACUMULADOS
GROUP BY data_lancamento, ano, mes, dia, id_centro_de_custo, id_categoria, status_pagamento