
CREATE OR  ALTER VIEW vw_gold_lancamentos AS 
SELECT 
       FL.id_lancamento,
       FL.data_lancamento,
       CC.id_centro_de_custo AS 'id_centro_de_custo',
       CC.nome_centro_de_custo AS 'centro_de_custo',
       CAT.id_categoria AS 'id_categoria',
       CAT.nome_categoria AS 'categoria',
       DF.id_fornecedor AS 'id_fornecedor',
       DF.nome_fornecedor AS 'fornecedor',
       MKT.id_campanha AS 'id_campanha',
       MKT.nome_campanha AS 'campanha_de_marketing',
       FL.valor,
       FL.valor_original,

       SUM(FL.valor) OVER(
                     PARTITION BY 
                            YEAR(FL.data_lancamento),
                            MONTH(data_lancamento),
                            FL.id_centro_de_custo,
                            FL.id_categoria,
                            FL.id_fornecedor,
                            FL.id_campanha
                     ORDER BY 
                            FL.data_lancamento ASC,
                            FL.id_lancamento
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'gasto_MTD',
       SUM(FL.valor) OVER(
                     PARTITION BY 
                            YEAR(FL.data_lancamento),
                            MONTH(data_lancamento),
                            FL.id_centro_de_custo,
                            FL.id_categoria
                     ORDER BY 
                            FL.data_lancamento ASC,
                            FL.id_lancamento
                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS 'gasto_MTD_CC_CAT',

       REPLACE(FL.status_pagamento, 'Aberto', 'Pendente') AS 'status_pagamento'
FROM 
       fact_lancamentos FL  
LEFT JOIN 
       dim_centro_de_custo CC
              ON CC.id_centro_de_custo = FL.id_centro_de_custo
LEFT JOIN 
       dim_categoria CAT  
              ON CAT.id_categoria = FL.id_categoria
LEFT JOIN 
       dim_fornecedores DF 
              ON DF.id_fornecedor = FL.id_fornecedor
LEFT JOIN 
       dim_camp_marketing MKT 
              ON MKT.id_campanha = FL.id_campanha