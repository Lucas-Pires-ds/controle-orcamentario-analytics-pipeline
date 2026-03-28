
CREATE OR ALTER VIEW vw_gold_realizado AS 

WITH BASE AS (

SELECT
       YEAR(FL.data_lancamento) AS 'Ano',
       MONTH(FL.data_lancamento) AS 'Mes',
       (YEAR(FL.data_lancamento) * 100) + MONTH(FL.data_lancamento) AS 'Ano_mes',
       FL.id_centro_de_custo AS 'ID_Centro_de_custo',
       CC.nome_centro_de_custo AS 'Centro_de_custo',
       CAT.id_categoria AS 'ID_Categoria',
       CAT.nome_categoria AS 'Categoria',
       SUM(FL.valor) AS 'Realizado',
       CASE 
              WHEN FL.id_centro_de_custo = -1 THEN 'Sim' 
              ELSE 'Nao' 
              END AS 'Flag_centro_custo_coringa'       
FROM fact_lancamentos FL
       LEFT JOIN dim_centro_de_custo CC
              ON CC.id_centro_de_custo = FL.id_centro_de_custo
       LEFT JOIN dim_categoria CAT  
              ON CAT.id_categoria = FL.id_categoria
GROUP BY
       YEAR(FL.data_lancamento),
       MONTH(FL.data_lancamento),
       (YEAR(FL.data_lancamento) * 100) + MONTH(FL.data_lancamento),
       FL.id_centro_de_custo,
       CC.nome_centro_de_custo,
       CAT.id_categoria,
       CAT.nome_categoria
),
MEDIANA AS (
       SELECT DISTINCT
              Ano,
              ID_Centro_de_custo,
              ID_Categoria,
              PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY NULLIF(Realizado, 0))
                     OVER (PARTITION BY Ano, ID_Centro_de_custo, ID_Categoria)
                     AS 'Mediana'
       FROM BASE
)

SELECT
       EOMONTH(DATEFROMPARTS(B.Ano, B.Mes, 1)) AS 'Data_realizacao',
       B.Ano,
       B.Mes,
       B.Ano_mes,
       B.ID_Centro_de_custo,
       B.Centro_de_custo,
       B.ID_Categoria,
       B.Categoria,
       B.Realizado,

       SUM(Realizado) OVER(
                     PARTITION BY
                            B.Ano,
                            B.ID_Centro_de_custo,
                            B.ID_Categoria
                     ORDER BY 
                            B.Ano,
                            B.Mes
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'Realizado YTD',

       Realizado - NULLIF(LAG(Realizado , 1) OVER (
                     PARTITION BY
                            B.ID_Centro_de_custo,
                            B.ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) AS 'MoM_abs',

       Realizado / NULLIF(LAG(Realizado , 1) OVER (
                     PARTITION BY
                            B.ID_Centro_de_custo,
                            B.ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) - 1 AS 'MoM_perc',

       Realizado - NULLIF(LAG(Realizado , 12) OVER (
                     PARTITION BY
                            B.ID_Centro_de_custo,
                            B.ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) AS 'YoY_abs',

       Realizado / NULLIF(LAG(Realizado , 12) OVER (
                     PARTITION BY
                            B.ID_Centro_de_custo,
                            B.ID_Categoria
                     ORDER BY 
                            CAL.Ano,
                            CAL.Mes
       ), 0) - 1 AS 'YoY_perc',

       SUM(Realizado) OVER(
                     PARTITION BY 
                            B.ID_Centro_de_custo,
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
                            B.ID_Categoria,
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
       M.Mediana,

       CASE 
        WHEN NULLIF(B.Realizado, 0) > 2 * M.Mediana
          OR NULLIF(B.Realizado, 0) < 0.5 * M.Mediana
        THEN 'Valor_atipico' 
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
       LEFT JOIN MEDIANA M 
       ON  M.Ano = B.Ano
       AND M.ID_Centro_de_custo = B.ID_Centro_de_custo
       AND M.ID_Categoria = B.ID_Categoria