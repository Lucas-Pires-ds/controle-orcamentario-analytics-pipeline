
CREATE OR ALTER VIEW vw_gold_orcamento AS 

WITH BASE AS (
              SELECT 
                     FO.ano AS 'Ano',
                     FO.mes AS 'Mes',
                     CC.id_centro_de_custo AS 'ID_Centro_de_custo',
                     CC.nome_centro_de_custo AS 'Centro_de_custo',
                     FO.id_categoria AS 'ID_Categoria',
                     CAT.nome_categoria AS 'Categoria',
                     SUM(FO.valor) AS 'Orcado',
                     FO.status_dado AS 'Status_dado'
              FROM
              fact_orcamento FO
                     LEFT JOIN dim_centro_de_custo CC  
                            ON CC.id_centro_de_custo = FO.id_centro_de_custo
                     LEFT JOIN dim_categoria CAT  
                            ON CAT.id_categoria = FO.id_categoria
              GROUP BY 
                     FO.ano, 
                     FO.mes, 
                     CC.id_centro_de_custo, 
                     CC.nome_centro_de_custo, 
                     FO.id_categoria, 
                     CAT.nome_categoria, 
                     FO.status_dado
              ),
MEDIANAS AS (
    SELECT DISTINCT
        Ano,
        ID_Centro_de_custo,
        ID_Categoria,
        Status_dado,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY NULLIF(Orcado, 0)) 
            OVER (PARTITION BY Ano, ID_Centro_de_custo, ID_Categoria, Status_dado) 
            AS 'Mediana'
    FROM BASE
)
SELECT 
       EOMONTH(DATEFROMPARTS(B.Ano, B.Mes, 1)) AS 'Data_de_orcamento',
       (B.Ano * 100) + Mes AS 'Ano_mes',
       B.Ano,
       B.Mes,
       B.ID_centro_de_custo,
       B.Centro_de_custo,
       B.ID_categoria,
       B.Categoria,

       NULLIF(Orcado, 0) AS 'Orcado_mensal',

       SUM(Orcado) OVER (
                     PARTITION BY 
                            B.Ano, 
                            B.ID_centro_de_custo, 
                            B.ID_categoria, 
                            B.status_dado 
                     ORDER BY 
                            Mes
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'Orcado_YTD',

       NULLIF(SUM(Orcado) OVER (
                            PARTITION BY 
                                   B.Ano, 
                                   B.ID_centro_de_custo, 
                                   B.Mes, 
                                   B.status_dado)
              , 0
       ) 
       / 
       NULLIF(
              SUM(Orcado) OVER(
                            PARTITION BY 
                                   B.Ano, 
                                   B.Mes, 
                                   B.status_dado)
              , 0
       ) AS 'Peso_centro_custo',

       NULLIF(SUM(Orcado) OVER (
                            PARTITION BY 
                                   B.Ano, 
                                   B.ID_categoria, 
                                   B.Mes, 
                                   B.status_dado)
              , 0
       ) 
       / 
       NULLIF(SUM(Orcado) OVER(
                            PARTITION BY 
                                   B.Ano, 
                                   B.Mes, 
                                   B.status_dado)
              , 0
       ) AS 'Peso_categoria',

       M.Mediana,

       CASE 
        WHEN NULLIF(B.Orcado, 0) > 2 * M.Mediana
          OR NULLIF(B.Orcado, 0) < 0.5 * M.Mediana
        THEN 'Valor_atipico' 
        ELSE 'Valor_normal' 
    END AS 'Flag_valor_atipico_orcamento',

       B.Status_dado
FROM 
       BASE B
LEFT JOIN MEDIANAS M 
    ON  M.Ano = B.Ano
    AND M.ID_Centro_de_custo = B.ID_Centro_de_custo
    AND M.ID_Categoria = B.ID_Categoria
    AND M.Status_dado = B.Status_dado