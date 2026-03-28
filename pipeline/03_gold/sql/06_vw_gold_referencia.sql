
CREATE OR ALTER VIEW vw_gold_referencia_mtd AS

WITH FACT_DIARIA AS (
       SELECT
              data_lancamento,
              id_centro_de_custo,
              id_categoria,
              SUM(valor) AS 'total_do_dia'
       FROM fact_lancamentos
       GROUP BY 
              data_lancamento,
              id_centro_de_custo,
              id_categoria
       
),
LISTA_CC_CAT AS (
       SELECT DISTINCT 
              id_centro_de_custo,
              id_categoria
       FROM fact_lancamentos
),
BASE_CALENDARIO AS (
       SELECT
              CAL.ano,
              CAL.mes,
              CAL.dia,
              CAL.[data] AS 'data_lancamento',
              DATEFROMPARTS(CAL.ano, CAL.mes, 1) AS 'mes_ref',
              L.id_centro_de_custo,
              L.id_categoria
       FROM dim_calendario CAL 
       CROSS JOIN LISTA_CC_CAT L  

),
HISTORICO AS (
       SELECT 
              BC.*,
              COALESCE(FD.total_do_dia, 0) AS 'total_do_dia'
       FROM BASE_CALENDARIO BC  
       LEFT JOIN FACT_DIARIA FD  
              ON FD.data_lancamento = BC.data_lancamento
              AND FD.id_centro_de_custo = BC.id_centro_de_custo
              AND FD.id_categoria = BC.id_categoria
),
ACUMULADOS AS (
       SELECT
       *,
       SUM(total_do_dia) OVER(
                     PARTITION BY
                            ano,
                            mes,
                            id_centro_de_custo,
                            id_categoria
                     ORDER BY
                            data_lancamento
       ) AS 'gasto_MTD',
       SUM(total_do_dia) OVER(
                     PARTITION BY
                            ano,
                            mes,
                            id_centro_de_custo,
                            id_categoria
       ) AS 'total_do_mes' 
FROM HISTORICO),
FINAL AS (
       SELECT 
              *,
              gasto_MTD / NULLIF(total_do_mes,0) AS 'perc_gasto_mes'
       FROM ACUMULADOS
       WHERE data_lancamento < DATEFROMPARTS(2024, 11, 1)
)
SELECT DISTINCT
       dia,
       id_centro_de_custo,
       id_categoria,
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY perc_gasto_mes) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_de_custo,
                                   id_categoria
              ) AS 'peso_do_dia',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY gasto_MTD) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_de_custo,
                                   id_categoria
              ) AS 'valor_mediano_dia'
FROM FINAL
UNION ALL

SELECT DISTINCT
       dia,
       id_centro_de_custo,
       -999 AS 'id_categoria',  -- VALOR ESPECIAL PARA INDICAR "TODAS AS CATEGORIAS"
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY perc_gasto_mes) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_de_custo
              ) AS 'peso_do_dia',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY gasto_MTD) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_de_custo
              ) AS 'valor_mediano_dia'
FROM FINAL

UNION ALL

-- PESO AGREGADO POR CATEGORIA (SEM CENTRO DE CUSTO)
SELECT DISTINCT
       dia,
       -999 AS 'id_centro_de_custo',  -- VALOR ESPECIAL PARA INDICAR "TODOS OS CENTROS"
       id_categoria,
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY perc_gasto_mes) OVER(
                            PARTITION BY 
                                   dia,
                                   id_categoria
              ) AS 'peso_do_dia',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY gasto_MTD) OVER(
                            PARTITION BY 
                                   dia,
                                   id_categoria
              ) AS 'valor_mediano_dia'
FROM FINAL

UNION ALL

-- PESO GERAL (SEM FILTRO NENHUM)
SELECT DISTINCT
       dia,
       -999 AS 'id_centro_de_custo',
       -999 AS 'id_categoria',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY perc_gasto_mes) OVER(
                            PARTITION BY dia
              ) AS 'peso_do_dia',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY gasto_MTD) OVER(
                            PARTITION BY dia
              ) AS 'valor_mediano_dia'
FROM FINAL
