-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- CARGA DE DADOS --------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

TRUNCATE TABLE dim_camp_marketing
TRUNCATE TABLE dim_centro_custo
TRUNCATE TABLE dim_fornecedores
TRUNCATE TABLE dim_calendario
TRUNCATE TABLE dim_categoria
TRUNCATE TABLE fact_lancamentos
TRUNCATE TABLE fact_orcamento


-- dim_camp_marketing

INSERT INTO dim_camp_marketing(
    id_camp, 
    nome_campanha, 
    mes_referente)
SELECT 
    ID_camp, 
    nome_camp, 
    mes_ref 
FROM 
    vw_campanhas

-- dim_centro_custo

INSERT INTO dim_centro_custo(
    id_cc, 
    nome_cc)
SELECT 
    id_cc, 
    nome_cc 
FROM 
    vw_centro_custo

INSERT INTO dim_centro_custo(id_cc, nome_cc) VALUES
(-1, 'Não identificado')

-- dim_categoria

INSERT INTO dim_categoria(
    id_categoria, 
    id_cc, 
    nome_categoria)
SELECT 
    id_cat, 
    id_cc, 
    nome_cat 
FROM
    vw_categoria



-- dim_fornecedores

INSERT INTO dim_fornecedores(
    id_forn, 
    nome_forn)
SELECT 
    id_forn, 
    nome_forn 
FROM 
    vw_fornecedores


-- dim_calendario

DECLARE @DATA DATETIME 
SET @DATA = '20230101'
    WHILE @DATA < '20250101'
    BEGIN
INSERT INTO dim_calendario(
    [data],
    dia_da_semana,
    dia_util,
    ano,
    mes,
    dia,
    nome_do_mes,
    mes_ano,
    ano_mes,
    semestre,
    semestre_ano,
    ano_semestre,
    trimestre,
    trimestre_ano,
    ano_trimestre,
    bimestre,
    bimestre_ano,
    ano_bimestre
) VALUES(
@DATA,
DATENAME(WEEKDAY, @DATA),
CASE WHEN DATENAME(WEEKDAY,@DATA) IN ('Sábado', 'Domingo') THEN 'nao' ELSE 'sim' END,
YEAR(@DATA),
MONTH(@DATA),
DAY(@DATA),
DATENAME(MONTH, @DATA),
FORMAT(@DATA, 'MMM/yy'),
CAST((YEAR(@DATA) * 100) + MONTH(@DATA) AS INT),
CASE WHEN MONTH(@DATA) BETWEEN 1 AND 6 THEN 1 ELSE 2 END,
CONCAT(CASE WHEN MONTH(@DATA) BETWEEN 1 AND 6 THEN 1 ELSE 2 END,'/',YEAR(@DATA)),
CAST(CONCAT(YEAR(@DATA),CASE WHEN MONTH(@DATA) BETWEEN 1 AND 6 THEN 1 ELSE 2 END ) AS INT),
DATEPART(QUARTER, @DATA),
CONCAT(DATEPART(QUARTER, @DATA), '/', YEAR(@DATA)),
CAST(CONCAT(YEAR(@DATA), DATEPART(QUARTER, @DATA)) AS INT),
CASE 
    WHEN MONTH(@DATA) BETWEEN 1 AND 2 THEN 1
    WHEN MONTH(@DATA) BETWEEN 3 AND 4 THEN 2
    WHEN MONTH(@DATA) BETWEEN 5 AND 6 THEN 3
    WHEN MONTH(@DATA) BETWEEN 7 AND 8 THEN 4
    WHEN MONTH(@DATA) BETWEEN 9 AND 10 THEN 5
    WHEN MONTH(@DATA) BETWEEN 11 AND 12 THEN 6 
END,
CONCAT(CASE 
    WHEN MONTH(@DATA) BETWEEN 1 AND 2 THEN 1
    WHEN MONTH(@DATA) BETWEEN 3 AND 4 THEN 2
    WHEN MONTH(@DATA) BETWEEN 5 AND 6 THEN 3
    WHEN MONTH(@DATA) BETWEEN 7 AND 8 THEN 4
    WHEN MONTH(@DATA) BETWEEN 9 AND 10 THEN 5
    WHEN MONTH(@DATA) BETWEEN 11 AND 12 THEN 6 
END, '/', YEAR(@DATA)),
CAST(CONCAT(YEAR(@DATA), CASE 
    WHEN MONTH(@DATA) BETWEEN 1 AND 2 THEN 1
    WHEN MONTH(@DATA) BETWEEN 3 AND 4 THEN 2
    WHEN MONTH(@DATA) BETWEEN 5 AND 6 THEN 3
    WHEN MONTH(@DATA) BETWEEN 7 AND 8 THEN 4
    WHEN MONTH(@DATA) BETWEEN 9 AND 10 THEN 5
    WHEN MONTH(@DATA) BETWEEN 11 AND 12 THEN 6 
END) AS INT) 
)
SET @DATA +=1
END

-- dim_mes

INSERT INTO dim_mes (ano_mes, ano, mes, primeiro_dia, ultimo_dia)
SELECT DISTINCT
    YEAR(data) * 100 + MONTH(data) AS id_mes,
    YEAR(data) AS ano,
    MONTH(data) AS mes,
    DATEFROMPARTS(YEAR(data), MONTH(data), 1) AS primeiro_dia,
    EOMONTH(data) AS ultimo_dia
FROM dim_calendario


-- fact_lancamentos

INSERT INTO  fact_lancamentos(
    id_lancamento, 
    data_lancamento, 
    id_centro_custo, 
    id_categoria, 
    id_fornecedor, 
    id_campanha,
    valor,
    valor_original,
    status_pagamento)
SELECT
    id_lancamento,
    data_lancamento,
    id_cc,
    id_categoria,
    id_fornecedor,
    id_campanha,
    valor_absoluto,
    valor_original,
    status_pagamento
FROM 
    vw_lancamentos

-- fact_orcamento

INSERT INTO fact_orcamento(
    id_orcamento,
    data_orcamento,
    ano,
    mes,
    id_centro_custo,
    id_categoria,
    valor,
    status_dado
)
SELECT
    id_orcamento,
    [data],
    ano,
    mes,
    id_centro_custo,
    id_categoria,
    valor_orcado,
    status_dado
FROM vw_orcamento


-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- AUDITORIA FINAL -------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 'dim_camp_marketing' AS Tabela, COUNT(*) AS Total_Registros FROM dim_camp_marketing
UNION ALL
SELECT 'dim_centro_custo' AS Tabela, COUNT(*) AS Total_Registros FROM dim_centro_custo
UNION ALL
SELECT 'dim_categoria' AS Tabela, COUNT(*) AS Total_Registros FROM dim_categoria
UNION ALL
SELECT 'dim_fornecedores' AS Tabela, COUNT(*) AS Total_Registros FROM dim_fornecedores
UNION ALL
SELECT 'dim_calendario' AS Tabela, COUNT(*) AS Total_Registros FROM dim_calendario
UNION ALL
SELECT 'fact_lancamentos' AS Tabela, COUNT(*) AS Total_Registros FROM fact_lancamentos
UNION ALL
SELECT 'fact_orcamento' AS Tabela, COUNT(*) AS Total_Registros FROM fact_orcamento
