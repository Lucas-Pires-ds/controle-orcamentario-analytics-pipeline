-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------- CAMADA GOLD ---------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------


GO


-- GOLD_ORCAMENTO


CREATE OR ALTER VIEW vw_gold_orcamento AS 

WITH BASE AS (
              SELECT 
                     FO.ano AS 'Ano',
                     FO.mes AS 'Mes',
                     CC.id_cc AS 'ID_Centro_de_custo',
                     CC.nome_cc AS 'Centro_de_custo',
                     FO.id_categoria AS 'ID_Categoria',
                     CAT.nome_categoria AS 'Categoria',
                     SUM(FO.valor) AS 'Orcado',
                     FO.status_dado AS 'Status_dado'
              FROM
              fact_orcamento FO
                     LEFT JOIN dim_centro_custo CC  
                            ON CC.id_cc = FO.id_centro_custo
                     LEFT JOIN dim_categoria CAT  
                            ON CAT.id_categoria = FO.id_categoria
              GROUP BY 
                     FO.ano, 
                     FO.mes, 
                     CC.id_cc, 
                     CC.nome_cc, 
                     FO.id_categoria, 
                     CAT.nome_categoria, 
                     FO.status_dado
              )
SELECT 
       EOMONTH(DATEFROMPARTS(Ano, Mes, 1)) AS 'Data_de_orcamento',
       (Ano * 100) + Mes AS 'Ano_mes',
       Ano,
       Mes,
       ID_centro_de_custo,
       Centro_de_custo,
       ID_categoria,
       Categoria,

       NULLIF(Orcado, 0) AS 'Orcado_mensal',

       SUM(Orcado) OVER (
                     PARTITION BY 
                            Ano, 
                            ID_centro_de_custo, 
                            ID_categoria, 
                            status_dado 
                     ORDER BY 
                            Mes
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'Orcado_YTD',

       NULLIF(SUM(Orcado) OVER (
                            PARTITION BY 
                                   Ano, 
                                   ID_centro_de_custo, 
                                   Mes, 
                                   status_dado)
              , 0
       ) 
       / 
       NULLIF(
              SUM(Orcado) OVER(
                            PARTITION BY 
                                   Ano, 
                                   Mes, 
                                   status_dado)
              , 0
       ) AS 'Peso_centro_custo',

       NULLIF(SUM(Orcado) OVER (
                            PARTITION BY 
                                   Ano, 
                                   ID_categoria, 
                                   Mes, 
                                   status_dado)
              , 0
       ) 
       / 
       NULLIF(SUM(Orcado) OVER(
                            PARTITION BY 
                                   Ano, 
                                   Mes, 
                                   status_dado)
              , 0
       ) AS 'Peso_categoria',

       AVG(NULLIF(Orcado, 0)) OVER (
                            PARTITION BY 
                                   Ano, 
                                   ID_centro_de_custo, 
                                   ID_categoria, 
                                   status_dado
       ) AS 'Media_mensal',

       CASE 
              WHEN 
                     NULLIF(Orcado, 0) 
                     > 2 * AVG(NULLIF(Orcado, 0)) OVER (
                            PARTITION BY 
                                   Ano, 
                                   ID_centro_de_custo, 
                                   ID_categoria, status_dado
                            ) 
                     OR 
                     NULLIF(Orcado, 0) 
                     < 0.5 * AVG(NULLIF(Orcado, 0)) OVER (
                                   PARTITION BY 
                                          Ano, 
                                          ID_centro_de_custo, 
                                          ID_categoria, 
                                          status_dado
                            )
                     THEN 'Valor_atipico' ELSE 'Valor_normal' 
       END AS 'Flag_valor_atipico_orcamento',

       Status_dado
FROM 
       BASE



GO

-- GOLD REALIZADO

CREATE OR ALTER VIEW vw_gold_realizado AS 

WITH BASE AS (

SELECT
       YEAR(FL.data_lancamento) AS 'Ano',
       MONTH(FL.data_lancamento) AS 'Mes',
       (YEAR(FL.data_lancamento) * 100) + MONTH(FL.data_lancamento) AS 'Ano_mes',
       FL.id_centro_custo AS 'ID_Centro_de_custo',
       CC.nome_cc AS 'Centro_de_custo',
       CAT.id_categoria AS 'ID_Categoria',
       CAT.nome_categoria AS 'Categoria',
       SUM(FL.valor) AS 'Realizado',
       CASE 
              WHEN FL.id_centro_custo = -1 THEN 'Sim' 
              ELSE 'Nao' 
              END AS 'Flag_centro_custo_coringa'       
FROM fact_lancamentos FL
       LEFT JOIN dim_centro_custo CC
              ON CC.id_cc = FL.id_centro_custo
       LEFT JOIN dim_categoria CAT  
              ON CAT.id_categoria = FL.id_categoria
GROUP BY
       YEAR(FL.data_lancamento),
       MONTH(FL.data_lancamento),
       (YEAR(FL.data_lancamento) * 100) + MONTH(FL.data_lancamento),
       FL.id_centro_custo,
       CC.nome_cc,
       CAT.id_categoria,
       CAT.nome_categoria
)

SELECT
       EOMONTH(DATEFROMPARTS(B.Ano, B.Mes, 1)) AS 'Data_realizacao',
       B.Ano,
       B.Mes,
       B.Ano_mes,
       ID_Centro_de_custo,
       Centro_de_custo,
       ID_Categoria,
       Categoria,
       Realizado,

       SUM(Realizado) OVER(
                     PARTITION BY
                            B.Ano,
                            ID_Centro_de_custo,
                            ID_Categoria
                     ORDER BY 
                            B.Ano,
                            B.Mes
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'Realizado YTD',

       Realizado - NULLIF(LAG(Realizado , 1) OVER (
                     PARTITION BY
                            ID_Centro_de_custo,
                            ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) AS 'MoM_abs',

       Realizado / NULLIF(LAG(Realizado , 1) OVER (
                     PARTITION BY
                            ID_Centro_de_custo,
                            ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) - 1 AS 'MoM_perc',

       Realizado - NULLIF(LAG(Realizado , 12) OVER (
                     PARTITION BY
                            ID_Centro_de_custo,
                            ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) AS 'YoY_abs',

       Realizado / NULLIF(LAG(Realizado , 12) OVER (
                     PARTITION BY
                            ID_Centro_de_custo,
                            ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) - 1 AS 'YoY_perc',

       AVG(Realizado) OVER (
                     PARTITION BY
                            B.Ano,
                            ID_Centro_de_custo,
                            ID_Categoria
       ) AS 'Média_mensal',

       SUM(Realizado) OVER(
                     PARTITION BY 
                            ID_Centro_de_custo,
                            B.Ano,
                            B.Mes
       ) 
       / 
       NULLIF(SUM(Realizado) OVER (
                     PARTITION BY
                            B.Ano,
                            B.Mes
                     )
              , 0
       ) AS 'Peso_centro_custo',

       SUM(Realizado) OVER(
                     PARTITION BY 
                            ID_Categoria,
                            B.Ano,
                            B.Mes
       ) 
       / 
       NULLIF(SUM(Realizado) OVER (
                     PARTITION BY
                            B.Ano,
                            B.Mes
                     )
              , 0
       ) AS 'Peso_categoria',

       CASE 
              WHEN Realizado 
                     > 2 * AVG(NULLIF(Realizado, 0)) OVER (
                                   PARTITION BY
                                          B.Ano,
                                          ID_Centro_de_custo,
                                          ID_Categoria )
              THEN 'Valor_acima_do_normal'
              WHEN 
                     Realizado 
                     < 0.5 * AVG(NULLIF(Realizado, 0)) OVER (
                                   PARTITION BY
                                          B.Ano,
                                          ID_Centro_de_custo,
                                          ID_Categoria )
              THEN 'Valor_abaixo_do_normal'
              ELSE 'Valor_normal'
       END AS 'Flag_valor_atipico_realizado',

       Flag_centro_custo_coringa
FROM
       BASE B  
       RIGHT JOIN
              (SELECT                                          -- USO DA DIM_CALENDARIO COMO BASE TEMPORAL PARA GARANTIR CONTINUIDADE MENSAL.
                     DISTINCT                                  -- SEM ISSO, LAG (MOM / YOY) PODERIA COMPARAR MESES NÃO CONSECUTIVOS
                            ano,                               -- CASO NÃO EXISTAM LANÇAMENTOS EM DETERMINADO MÊS.
                            mes                                
              FROM                                             
                     dim_calendario) CAL                       
                            ON B.Ano = CAL.ano 
                            AND B.Mes = CAL.mes

GO

--  VW_GOLD_LANCAMENTOS

GO

CREATE OR  ALTER VIEW vw_gold_lancamentos AS 
SELECT 
       FL.id_lancamento,
       FL.data_lancamento,
       CC.id_cc AS 'id_centro_de_custo',
       CC.nome_cc AS 'centro_de_custo',
       CAT.id_categoria AS 'id_categoria',
       CAT.nome_categoria AS 'categoria',
       DF.id_forn AS 'id_fornecedor',
       DF.nome_forn AS 'fornecedor',
       MKT.id_camp AS 'id_campanha',
       MKT.nome_campanha AS 'campanha_de_marketing',
       FL.valor,
       FL.valor_original,

       SUM(FL.valor) OVER(
                     PARTITION BY 
                            YEAR(FL.data_lancamento),
                            MONTH(data_lancamento),
                            FL.id_centro_custo,
                            FL.id_categoria,
                            FL.id_fornecedor,
                            FL.id_campanha
                     ORDER BY 
                            FL.data_lancamento ASC,
                            FL.id_lancamento
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'gasto_MTD',

       REPLACE(FL.status_pagamento, 'Aberto', 'Pendente') AS 'status_pagamento'
FROM 
       fact_lancamentos FL  
LEFT JOIN 
       dim_centro_custo CC
              ON CC.id_cc = FL.id_centro_custo
LEFT JOIN 
       dim_categoria CAT  
              ON CAT.id_categoria = FL.id_categoria
LEFT JOIN 
       dim_fornecedores DF 
              ON DF.id_forn = FL.id_fornecedor
LEFT JOIN 
       dim_camp_marketing MKT 
              ON MKT.id_camp = FL.id_campanha

-- VW_GOLD_REFERENCIA_MTD

GO

CREATE OR ALTER VIEW vw_gold_referencia_mtd AS

WITH FACT_DIARIA AS (
       SELECT
              data_lancamento,
              id_centro_custo,
              id_categoria,
              SUM(valor) AS 'total_do_dia'
       FROM fact_lancamentos
       GROUP BY 
              data_lancamento,
              id_centro_custo,
              id_categoria
       
),
LISTA_CC_CAT AS (
       SELECT DISTINCT 
              id_centro_custo,
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
              L.id_centro_custo,
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
              AND FD.id_centro_custo = BC.id_centro_custo
              AND FD.id_categoria = BC.id_categoria
),
ACUMULADOS AS (
       SELECT
       *,
       SUM(total_do_dia) OVER(
                     PARTITION BY
                            ano,
                            mes,
                            id_centro_custo,
                            id_categoria
                     ORDER BY
                            data_lancamento
       ) AS 'gasto_MTD',
       SUM(total_do_dia) OVER(
                     PARTITION BY
                            ano,
                            mes,
                            id_centro_custo,
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
       id_centro_custo,
       id_categoria,
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY perc_gasto_mes) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_custo,
                                   id_categoria
              ) AS 'peso_do_dia',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY gasto_MTD) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_custo,
                                   id_categoria
              ) AS 'valor_mediano_dia'
FROM FINAL
UNION ALL

SELECT DISTINCT
       dia,
       id_centro_custo,
       -999 AS 'id_categoria',  -- Valor especial para indicar "todas as categorias"
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY perc_gasto_mes) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_custo
              ) AS 'peso_do_dia',
       PERCENTILE_CONT(0.5)
              WITHIN GROUP (ORDER BY gasto_MTD) OVER(
                            PARTITION BY 
                                   dia,
                                   id_centro_custo
              ) AS 'valor_mediano_dia'
FROM FINAL

UNION ALL

-- PESO AGREGADO POR CATEGORIA (SEM CENTRO DE CUSTO)
SELECT DISTINCT
       dia,
       -999 AS 'id_centro_custo',  -- VALOR ESPECIAL PARA INDICAR "TODOS OS CENTROS"
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
       -999 AS 'id_centro_custo',
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

