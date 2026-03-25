-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- VERIFICAÇÃO DE TRATAMENTOS NECESSÁRIOS --------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------- FACT_LANCAMENTOS --------------------------------------------------------------------------

SELECT * FROM stg_lancamentos -- OVERVIEW

-- VERIFICACAO DE ESPAÇOS EXTRAS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_lancamento) > LEN(TRIM(id_lancamento))
    ) AS 'espacos_ID_lancamento',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(data_lancamento) > LEN(TRIM(data_lancamento))
    ) AS 'espacos_data',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_centro_custo) > LEN(TRIM(id_centro_custo))
    ) AS 'espacos_ID_centro_custo',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_categoria) > LEN(TRIM(id_categoria))
    ) AS 'espacos_ID_categoria',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_fornecedor) > LEN(TRIM(id_fornecedor))
    ) AS 'espacos_ID_fornecedor',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_campanha_marketing) > LEN(TRIM(id_campanha_marketing))
    ) AS 'espacos_ID_campanha',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(valor_lancamento) > LEN(TRIM(valor_lancamento))
    ) AS 'espacos_valor_lancamento',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(status_pagamento) > LEN(TRIM(status_pagamento))
    ) AS 'espacos_status_pagamento'

-- VERIFICACAO DE NULOS E VAZIOS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_lancamento IS NULL OR LEN(id_lancamento) = 0 
    ) AS 'ID_lancamento_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        data_lancamento IS NULL OR LEN(data_lancamento) = 0
    ) AS 'data_nulas',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_centro_custo IS NULL OR LEN(id_centro_custo) = 0
    ) AS 'id_centro_custo_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_categoria IS NULL OR LEN(id_categoria) = 0
    ) AS 'id_categoria_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_fornecedor IS NULL OR LEN(id_fornecedor) = 0
    ) AS 'id_fornecedor_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        valor_lancamento IS NULL OR LEN(valor_lancamento) = 0
    ) AS 'valor_lancamento_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        status_pagamento IS NULL OR LEN(status_pagamento) = 0
    ) AS 'status_pagamento_nulos'

-- UMA VEZ IDENTIFICADO 27 REGISTROS COM DATAS NULAS, RODAREI UMA QUERY PARA VISUALIZAR O IMPACTO FINANCEIRO DESSES DADOS:
SELECT
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), 'C')AS 'valor_total', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE data_lancamento IS NULL), 'C') AS 'sem_data', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE data_lancamento IS NULL) / (SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), '0.00%') AS 'impacto_(%)'

-- IMPACTO IDENTIFICADO = 0,19%.

-- VERIFICACAO DE INTEGRIDADE REFERENCIAL DE CHAVES ESTRANGEIRAS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_centro_custo NOT IN (SELECT
                                     id_cc 
                                FROM
                                    dim_centro_custo)
    ) AS 'ID_centro_custo_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_categoria NOT IN (SELECT 
                                id_categoria 
                            FROM
                                dim_categoria)
    ) AS 'ID_categoria_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_fornecedor NOT IN (SELECT
                                id_forn 
                            FROM 
                                dim_fornecedores)
    ) AS 'id_fornecedor_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        CAST(CAST(id_campanha_marketing AS FLOAT) AS INT) NOT IN (SELECT
                                                                    id_camp 
                                                                FROM 
                                                                    dim_camp_marketing)
    ) AS 'id_campanha_invalido'


-- IDENTIFICANDO QUANTOS CENTROS DE CUSTOS INVÁLIDOS EXISTEM NA TABELA FACT_LANCAMENTOS

SELECT DISTINCT 
    id_centro_custo
FROM stg_lancamentos WHERE id_centro_custo NOT IN (SELECT id_cc FROM dim_centro_custo)


-- UMA VEZ IDENTIFICADO 65 REGISTROS COM UM CENTRO DE CUSTO INVÁLIDO, RODAREI UMA QUERY PARA VISUALIZAR O IMPACTO FINANCEIRO DESSES REGISTROS:

SELECT
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), 'C')AS 'valor_total', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE id_centro_custo NOT IN (SELECT ID_CC FROM dim_centro_custo)), 'C') AS 'centro_custo_invalido', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE id_centro_custo NOT IN (SELECT ID_CC FROM dim_centro_custo)) / (SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), '0.00%') AS 'impacto_(%)'

-- IMPACTO IDENTIFICADO = 0,57%

-- VERIFICACAO DE VALORES NEGATIVOS

SELECT
    status_pagamento,
    COUNT(CAST(valor_lancamento as DECIMAL(18,2))) AS 'qtd_registros',
    SUM(CAST(valor_lancamento as DECIMAL(18,2))) AS 'valor_por_status'
FROM
    stg_lancamentos
WHERE 
    CAST(valor_lancamento as DECIMAL(18,2)) LIKE '-%'
GROUP BY status_pagamento

-- VERIFICACAO DE STATUS DE PAGAMENTO DUPLICADOS

SELECT
    DISTINCT
        status_pagamento COLLATE Latin1_General_CS_AS AS 'status_pagamento'
FROM stg_lancamentos


-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_lancamentos' 

/* RESULTADO DAS VERIFICAÇÕES:

ESPACOS EXTRAS: 0 ENCONTRADOS. NENHUM TRATAMENTO NECESSÁRIO.

NULOS OU VAZIOS: 27 REGISTROS COM DATAS NULAS ENCONTRADOS. IMPACTO FINANCEIRO IDENTIFICADO DE 0,15%. TRATAMENTO: DADOS SERÃO DESCARTADOS POR TEREM BAIXO 
IMPACTO FINANCEIRO, FRENTE O RISCO DE CORROMPIMENTO DE ANALISES TEMPORAIS.

INTEGRIDADE REFERENCIAL DE CHAVES ESTRANGEIRAS: IDENTIFIQUEI 62 REGISTROS COM CENTRO DE CUSTO NÃO CADASTRADO, SENDO QUE TODOS OS REGISTROS FORAM REALIZADOS COM UM UNICO CENTRO DE CUSTO: O 999.
ESSES REGISTROS REPRESENTAM 0,57% DE IMPACTO FINANCEIRO DO MONTANTE TOTAL.
DADO QUE JÁ DESCARTEI 0,19% REFERENTE AOS REGISTROS SEM DATA, OPTO POR NÃO DESCARTAR ESSES 0,57% QUE TOTALIZARIAM JUNTO AOS REGISTROS ANTERIORMENTE DESCARTADOS, PRATICAMENTE 1%
DE UM MONTANTE DE 60,8 MILHOES. TRATAMENTO: ADICIONAREI NA TABELA "DIM_CENTRO_CUSTO" UM CENTRO DE CUSTO CORINGA PARA LANCAMENTOS COM CENTROS DE CUSTO INVÁLIDOS.

VALORES NEGATIVOS: IDENTIFIQUEI 48 REGISTROS COM VALORES NEGATIVOS. COMO NÃO ESTÃO ATRELADOS A UM STATUS ESPECÍFICO (EX: "CANCELADO" OU "ESTORNADO"), 
TRATEI COMO INCONSISTÊNCIA DE SINAL. POR PRECAUÇÃO, MANTIVE A COLUNA COM O VALOR ORIGINAL PARA AUDITORIA, MAS CRIEI UMA COLUNA DE VALOR TRATADO UTILIZANDO A FUNÇÃO ABS(), 
GARANTINDO A INTEGRIDADE DOS CÁLCULOS NO DASHBOARD.

STATUS DE PAGAMENTO: FORAM INDENTIFICADAS DUPLICIDADES NOS TERMOS UTILIZADOS PARA STATUS DE PAGAMENTO, SENDO ELAS (Paga, Pago, PAGO) E (Aberto, Pending). 
TRATAMENTO: PADRONIZAÇÃO DE STATUS PARA 2 OPÇÕES: "Pago" e "Aberto". 

TIPOS DE DADOS: TODOS OS DADOS ESTÃO COM TIPO VARCHAR. TRATAMENTO: CONVETEREI OS IDS EM INT, DATA_LANCAMENTO EM DATETIME E VALOR EM DECIMAL (16,2).
*/

----------------------------------------------------- FACT_ORCAMENTO --------------------------------------------------------------------------

SELECT * FROM stg_orcamento -- OVERVIEW

-- VERIFICACAO DE ESPAÇOS EXTRAS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        LEN(id_orcamento) > LEN(TRIM(id_orcamento))
    ) AS 'espacos_id_orcamento',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        LEN(ano) > LEN(TRIM(ano))
    ) AS 'espacos_ano',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        LEN(mes) > LEN(TRIM(mes))
    ) AS 'espacos_mes',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        LEN(id_centro_custo) > LEN(TRIM(id_centro_custo))
    ) AS 'espacos_id_centro_custo',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        LEN(id_categoria) > LEN(TRIM(id_categoria))
    ) AS 'espacos_id_categoria',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        LEN(valor_orcado) > LEN(TRIM(valor_orcado))
    ) AS 'espacos_valor'


-- VERIFICACAO DE NULOS E VAZIOS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        id_orcamento IS NULL OR LEN(id_orcamento) = 0
    ) AS 'nulos_vazios_id_orcamento',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        ano IS NULL OR LEN(ano) = 0
    ) AS 'nulos_vazios_ano',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        mes IS NULL OR LEN(mes) = 0
    ) AS 'nulos_vazios_mes',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        id_centro_custo IS NULL OR LEN(id_centro_custo) = 0
    ) AS 'nulos_vazios_id_centro_custo',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        id_categoria IS NULL OR LEN(id_categoria) = 0
    ) AS 'nulos_vazios_id_categoria',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        valor_orcado IS NULL OR LEN(valor_orcado) = 0
    ) AS 'nulos_vazios_valor'


-- VERIFICACAO DE DUPLICIDADES DE CHAVES PRIMARIAS

SELECT
    id_orcamento,
    COUNT(id_orcamento) AS 'id_duplicado'
FROM 
    stg_orcamento
GROUP BY id_orcamento
HAVING COUNT(id_orcamento) > 1

-- VERIFICACAO DE INTEGRIDADE DOS MESES

SELECT
    COUNT(*) AS 'meses_invalidos'
FROM
    stg_orcamento
WHERE mes < 1 OR mes > 12


-- VERIFICACAO DE INTEGRIDADE DOS ANOS

SELECT
    COUNT(*) AS 'anos_invalidos'
FROM
    stg_orcamento
WHERE ano < 2023 OR ano> 2024

-- VERIFICACAO DE INTEGRIDADE REFERENCIAL DE CHAVES ESTRANGEIRAS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        id_centro_custo NOT IN (SELECT
                                    id_cc
                                FROM
                                    dim_centro_custo)
    ) AS 'id_cc_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_orcamento
    WHERE
        id_categoria NOT IN (SELECT
                                    id_categoria
                                FROM
                                    dim_categoria)
    ) AS 'id_categoria_invalido'
    

-- VERIFICACAO DE VALORES NEGATIVOS

SELECT
    COUNT(*) AS 'valores_negativos'
FROM
    stg_orcamento
WHERE
    CAST(valor_orcado AS FLOAT) < 0


-- VERIFICACAO DE INTEGRIDADE DOS VALORES

WITH 
    BASE AS (
SELECT 
    id_orcamento, ano, mes, id_centro_custo, id_categoria, 
    CAST(valor_orcado AS DECIMAL(18,2)) AS 'valor_tipado'
FROM stg_orcamento),

    MEDIA_INCLUSA AS (
SELECT
    *,
    AVG(valor_tipado) OVER (PARTITION BY id_centro_custo, id_categoria) AS 'media'
    FROM BASE
    ),

    VARIACAO_INCLUSA AS(
SELECT
    *, 
    valor_tipado / NULLIF(media,0) - 1 AS 'variacao'
FROM MEDIA_INCLUSA
),

    FINAL AS (
SELECT
        *,
        CASE 
            WHEN variacao > 10 THEN '1. 1000%+'
            WHEN variacao BETWEEN 9 AND 10 THEN '2. 900~1000%'
            WHEN variacao BETWEEN 1 AND 9 THEN '3. 100~900%'
            WHEN variacao BETWEEN 0.1 AND 0.2 THEN '4. 10 ~ 20%'
            WHEN variacao BETWEEN 0 AND 0.1 THEN '5. 0 ~ 10%'
            WHEN variacao BETWEEN -0.1 AND 0 THEN '6. -10~0%'
            WHEN variacao BETWEEN -0.2 AND -0.1 THEN '7. -20~-10%'
            WHEN variacao BETWEEN -0.3 AND -0.2 THEN '8. -30~-20%'
            WHEN variacao < -0.3 THEN '9. -30%-'
        END AS 'faixas'
    FROM VARIACAO_INCLUSA
),

    LISTA_FAIXAS AS(
        SELECT * FROM (
            VALUES
            ('1. 1000%+'),
            ('2. 900~1000%'),
            ('3. 100~900%'),
            ('4. 10 ~ 20%'),
            ('5. 0 ~ 10%'),
            ('6. -10~0%'),
            ('7. -20~-10%'),
            ('8. -30~-20%'),
            ('9. -30%-')
        ) AS Lista(faixa_nome)
    )
SELECT
    L.faixa_nome,
    FORMAT(COALESCE(SUM(F.valor_tipado), 0),'C') AS 'Valor_concentrado',
    COUNT(F.faixas) AS 'Registros'
FROM 
    LISTA_FAIXAS L
LEFT JOIN 
    FINAL F
        ON L.faixa_nome = F.faixas
GROUP BY L.faixa_nome
ORDER BY L.faixa_nome


-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_orcamento' 


/* RESULTADO DAS VERIFICAÇÕES:

- ESPAÇOS EXTRAS: 0 ENCONTRADOS. NENHUM TRATAMENTO NECESSÁRIO.

- NULOS E VAZIOS: 0 ENCONTRADOS. NENHUM TRATAMENTO NECESSÁRIO.

- DUPLICIDADES DE CHAVES PRIMARIAS: 0 ENCONTRADOS. NENHUM TRATAMENTO NECESSÁRIO.

- INTEGRIDADE DOS MESES: NENHUM MES FORA DO RANGE (1 - 12) ENCONTRADO, NENHUM TRATAMENTO NECESSÁRIO.

- INTEGRIDADE DOS ANOS: NENHUM ANO FORA DO RANGE ANALISADO (2023 - 2024) ENCONTRADO, NENHUM TRATAMENTO NECESSÁRIO.

- INTEGRIDADE REFERENCIAL DE CHAVES ESTRANGEIRAS: NENHUMA CHAVE REFERENCIADA INCORRETAMENTE. NENHUM TRATAMENTO NECESSÁRIO.

- VALORES NEGATIVOS: 0 ENCONTRADOS. NENHUM TRATAMENTO NECESSÁRIO.

- INTEGRIDADE DOS VALORES: 6 OUTLIERS ABSURDOS ENCONTRADOS, ACUMULANDO R$ 5,6 MI, SUSPEITA DE ERRO DE DIGITAÇÃO. TRATAMENTO: SERÁ CRIADA UMA COLUNA DE FLAG PARA 
IDENTIFICAR ESSES VALORES QUANDO IMPORTARMOS PARA A TABELA SILVER.

- TIPOS DE DADOS: TODOS OS DADOS ESTÃO COMO VARCHAR. TRATAMENTO: SERÁ NECESSÁRIA A CONVERSÃO DAS TABELAS DE ID, ANO E MES PARA INT E VALOR PARA DECIMAL(18,2)

*/
