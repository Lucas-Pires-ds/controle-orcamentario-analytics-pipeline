-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------- INGESTÃO DE DADOS ---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

USE Financeiro_BI;
GO

DROP TABLE IF EXISTS stg_lancamentos
DROP TABLE IF EXISTS stg_orcamento
DROP TABLE IF EXISTS stg_dim_centro_custo
DROP TABLE IF EXISTS stg_dim_categoria
DROP TABLE IF EXISTS stg_dim_fornecedores
DROP TABLE IF EXISTS stg_dim_campanha


-- 1. Criando as tabelas de Staging

CREATE TABLE stg_lancamentos (
    id_lancamento VARCHAR(MAX), data_lancamento VARCHAR(MAX), id_centro_custo VARCHAR(MAX),
    id_categoria VARCHAR(MAX), id_fornecedor VARCHAR(MAX), id_campanha_marketing VARCHAR(MAX),
    valor_lancamento VARCHAR(MAX), status_pagamento VARCHAR(MAX)
)

CREATE TABLE stg_orcamento (
    id_orcamento VARCHAR(MAX), ano VARCHAR(MAX), mes VARCHAR(MAX),
    id_centro_custo VARCHAR(MAX), id_categoria VARCHAR(MAX), valor_orcado VARCHAR(MAX)
)

CREATE TABLE stg_dim_centro_custo (id_cc VARCHAR(MAX), nome_cc VARCHAR(MAX))

CREATE TABLE stg_dim_categoria (id_cat VARCHAR(MAX), id_cc VARCHAR(MAX), nome_cat VARCHAR(MAX))

CREATE TABLE stg_dim_fornecedores (id_forn VARCHAR(MAX), nome_forn VARCHAR(MAX))

CREATE TABLE stg_dim_campanha (id_camp VARCHAR(MAX), nome_camp VARCHAR(MAX), mes_ref VARCHAR(MAX))

GO

-- 2. Limpando dados antigos 
TRUNCATE TABLE stg_lancamentos
TRUNCATE TABLE stg_orcamento
TRUNCATE TABLE stg_dim_centro_custo
TRUNCATE TABLE stg_dim_categoria
TRUNCATE TABLE stg_dim_fornecedores
TRUNCATE TABLE stg_dim_campanha
GO

-- 3. Importação

-- Ajuste o caminho conforme o seu ambiente
BULK INSERT stg_lancamentos FROM 'C:\Users\Lucas\Desktop\Projeto controle orcamentario\data\raw\fact_lancamentos.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001')
BULK INSERT stg_orcamento FROM 'C:\Users\Lucas\Desktop\Projeto controle orcamentario\data\raw\fact_orcamento.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001')
BULK INSERT stg_dim_centro_custo FROM 'C:\Users\Lucas\Desktop\Projeto controle orcamentario\data\raw\dim_centro_custo.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001')
BULK INSERT stg_dim_categoria FROM 'C:\Users\Lucas\Desktop\Projeto controle orcamentario\data\raw\dim_categoria.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001')
BULK INSERT stg_dim_fornecedores FROM 'C:\Users\Lucas\Desktop\Projeto controle orcamentario\data\raw\dim_fornecedores.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001')
BULK INSERT stg_dim_campanha FROM 'C:\Users\Lucas\Desktop\Projeto controle orcamentario\data\raw\dim_campanha_marketing.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001')
GO

-- 4. Verificação

SELECT 'stg_lancamentos' as Tabela, COUNT(*) as Linhas FROM stg_lancamentos
UNION ALL
SELECT 'stg_orcamento' as Tabela, COUNT(*) as Linhas_Orcamento FROM stg_orcamento
UNION ALL
SELECT 'stg_dim_centro_custo' as Tabela, COUNT(*) as Linhas_Fato FROM stg_dim_centro_custo
UNION ALL
SELECT 'stg_dim_categoria' as Tabela, COUNT(*) as Linhas_Fato FROM stg_dim_categoria
UNION ALL
SELECT 'stg_dim_fornecedores' as Tabela, COUNT(*) as Linhas_Fato FROM stg_dim_fornecedores
UNION ALL
SELECT 'stg_dim_campanha' as Tabela, COUNT(*) as Linhas_Fato FROM stg_dim_campanha

