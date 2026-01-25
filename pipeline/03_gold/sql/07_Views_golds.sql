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
       FORMAT(FL.data_lancamento, 'yyyy_MM') AS 'Ano_mes',
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
       FORMAT(FL.data_lancamento, 'yyyy_MM'),
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


-- GOLD LANCAMENTOS

CREATE OR ALTER VIEW vw_gold_lancamentos AS

WITH ACUMULADO_MENSAL AS (

       SELECT
              DATEFROMPARTS(YEAR(data_lancamento), MONTH(data_lancamento), 1) AS 'Mes_ref',
              DAY(data_lancamento) AS Dia_do_mes,
              id_centro_custo,
              SUM(valor) AS 'Valor_do_dia'
       FROM fact_lancamentos
       GROUP BY
              YEAR(data_lancamento),
              MONTH(data_lancamento),
              DAY(data_lancamento),
              id_centro_custo
),
ACUMULADO_FINAL AS (
       SELECT
              Mes_ref,
              Dia_do_mes,
              id_centro_custo,
              SUM(Valor_do_dia) OVER(
                     PARTITION BY
                            Mes_ref,
                            id_centro_custo
                     ORDER BY Dia_do_mes
              ) AS 'Gasto_ate_dia'       
       FROM ACUMULADO_MENSAL
),
MEDIANA AS (
       SELECT DISTINCT
              Dia_do_mes,
              id_centro_custo,
              PERCENTILE_CONT(0.5)
                     WITHIN GROUP (ORDER BY Gasto_ate_dia) OVER(
                                                 PARTITION BY 
                                                        Dia_do_mes,
                                                        id_centro_custo) AS 'Mediana_gasto_ate_dia'
       FROM ACUMULADO_FINAL
       WHERE Mes_ref < DATEFROMPARTS(2024, 12, 1)       -- Exclui o mês atual (dezembro/2024) do cálculo da mediana histórica para evitar viés de dados incompletos.
       )                                                -- Em produção o ideal seria usar Mes_ref < DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)         
                                                       

SELECT 
       YEAR(FL.data_lancamento) AS 'Ano',
       MONTH(FL.data_lancamento) AS 'Mes',
       FORMAT(FL.data_lancamento, 'yyyy_MM') AS 'Ano_mes',
       FL.id_lancamento AS 'ID_Lancamento',
       FL.data_lancamento AS 'Data_lancamento',
       FL.id_centro_custo AS 'ID_Centro_de_custo',
       CC.nome_cc AS 'Centro_de_custo',
       FL.id_categoria AS 'ID_Categoria',
       CAT.nome_categoria AS 'Categoria',
       FL.id_fornecedor AS 'ID_Fornecedor',
       DF.nome_forn AS 'Fornecedor',
       FL.id_campanha AS 'ID_Campanha',
       COALESCE(MKT.nome_campanha, 'Sem_campanha') AS 'Campanha',
       FL.valor AS 'Valor',
       SUM(valor) OVER(
              PARTITION BY 
                     FL.id_centro_custo,
                     FL.id_categoria,
                     FL.id_fornecedor,
                     FL.id_campanha,
                     YEAR(FL.data_lancamento),
                     MONTH(FL.data_lancamento)
              ORDER BY FL.data_lancamento
       ) AS 'Gasto_MTD',
       NULLIF(Mediana_gasto_ate_dia, 0) AS 'Mediana_MTD_CC',
       SUM(valor) OVER(
              PARTITION BY 
                     FL.id_centro_custo,
                     FL.id_categoria,
                     FL.id_fornecedor,
                     FL.id_campanha,
                     YEAR(FL.data_lancamento),
                     MONTH(FL.data_lancamento)
              ORDER BY FL.data_lancamento
       )
       /
       NULLIF(Mediana_gasto_ate_dia, 0) AS 'Perc_desvio_mediana',
       CASE 
              WHEN SUM(valor) OVER(
              PARTITION BY 
                     FL.id_centro_custo,
                     FL.id_categoria,
                     FL.id_fornecedor,
                     FL.id_campanha,
                     YEAR(FL.data_lancamento),
                     MONTH(FL.data_lancamento)
       ) 
       / 
       NULLIF(Mediana_gasto_ate_dia, 0) <= 0.8
              THEN 'Abaixo_do_normal'
              WHEN SUM(valor) OVER(
              PARTITION BY 
                     FL.id_centro_custo,
                     FL.id_categoria,
                     FL.id_fornecedor,
                     FL.id_campanha,
                     YEAR(FL.data_lancamento),
                     MONTH(FL.data_lancamento)
       ) 
       /
       NULLIF(Mediana_gasto_ate_dia, 0) BETWEEN 0.81 AND 1
              THEN 'Dentro_do_normal'
              ELSE 'Acima_do_normal'
              END AS 'Flag_alerta_gasto' ,
       FL.valor_original AS 'Valor_original',      
       REPLACE(FL.status_pagamento,'Aberto', 'Pendente') AS 'Status_pagamento',
       CASE 
              WHEN FL.id_centro_custo = -1 
              THEN 'Sim' ELSE 'Nao' 
              END AS 'Flag_centro_custo_coringa'
FROM fact_lancamentos FL  
       LEFT JOIN dim_centro_custo CC
              ON CC.id_cc = FL.id_centro_custo
       LEFT JOIN dim_categoria CAT  
              ON CAT.id_categoria = FL.id_categoria
       LEFT JOIN dim_fornecedores DF 
              ON DF.id_forn = FL.id_fornecedor
       LEFT JOIN dim_camp_marketing MKT
              ON MKT.id_camp = FL.id_campanha
       LEFT JOIN MEDIANA MED 
              ON MED.Dia_do_mes = DAY(FL.data_lancamento)
              AND MED.id_centro_custo = FL.id_centro_custo

GO