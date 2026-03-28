
CREATE OR ALTER VIEW vw_gold_lancamentos_consolidados_dia AS
WITH tb_lancamentos AS (

       SELECT
              *
       FROM
              vw_gold_lancamentos
),
BASE AS (
       SELECT 
       data_lancamento,
       id_centro_de_custo,
       centro_de_custo,
       id_categoria,
       categoria,
       id_fornecedor,
       fornecedor,
       SUM(valor) AS 'total_do_dia',
       status_pagamento
FROM tb_lancamentos
GROUP BY 
       data_lancamento,
       id_centro_de_custo,
       centro_de_custo,
       id_categoria,
       categoria,
       id_fornecedor,
       fornecedor,
       status_pagamento)
SELECT
       *,
       total_do_dia / SUM(total_do_dia) OVER(
              PARTITION BY 
                     YEAR(data_lancamento),
                     MONTH(data_lancamento)
       ) AS 'Participação no mês'
FROM BASE