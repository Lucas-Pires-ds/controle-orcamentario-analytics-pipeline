-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------- INGESTÃO DE DADOS ---------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

USE Financeiro_BI;
GO

-- 1. Criando as tabelas de Staging
IF OBJECT_ID('stg_lancamentos', 'U') IS NULL
CREATE TABLE stg_lancamentos (
    id_lancamento VARCHAR(MAX), data_lancamento VARCHAR(MAX), id_centro_custo VARCHAR(MAX),
    id_categoria VARCHAR(MAX), id_fornecedor VARCHAR(MAX), id_campanha_marketing VARCHAR(MAX),
    valor_lancamento VARCHAR(MAX), status_pagamento VARCHAR(MAX)
);

IF OBJECT_ID('stg_orcamento', 'U') IS NULL
CREATE TABLE stg_orcamento (
    id_orcamento VARCHAR(MAX), ano VARCHAR(MAX), mes VARCHAR(MAX),
    id_centro_custo VARCHAR(MAX), id_categoria VARCHAR(MAX), valor_orcado VARCHAR(MAX)
);

IF OBJECT_ID('stg_dim_centro_custo', 'U') IS NULL
CREATE TABLE stg_dim_centro_custo (id_cc VARCHAR(MAX), nome_cc VARCHAR(MAX));

IF OBJECT_ID('stg_dim_categoria', 'U') IS NULL
CREATE TABLE stg_dim_categoria (id_cat VARCHAR(MAX), id_cc VARCHAR(MAX), nome_cat VARCHAR(MAX));

IF OBJECT_ID('stg_dim_fornecedores', 'U') IS NULL
CREATE TABLE stg_dim_fornecedores (id_forn VARCHAR(MAX), nome_forn VARCHAR(MAX));

IF OBJECT_ID('stg_dim_campanha', 'U') IS NULL
CREATE TABLE stg_dim_campanha (id_camp VARCHAR(MAX), nome_camp VARCHAR(MAX), mes_ref VARCHAR(MAX));
GO

-- 2. Limpando dados antigos 
TRUNCATE TABLE stg_lancamentos;
TRUNCATE TABLE stg_orcamento;
TRUNCATE TABLE stg_dim_centro_custo;
TRUNCATE TABLE stg_dim_categoria;
TRUNCATE TABLE stg_dim_fornecedores;
TRUNCATE TABLE stg_dim_campanha;
GO

-- 3. Importação

-- Ajuste o caminho conforme o seu ambiente
BULK INSERT stg_lancamentos FROM 'C:\Projeto controle orcamentario\dados\bruto\fact_lancamentos.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT stg_orcamento FROM 'C:\Projeto controle orcamentario\dados\bruto\fact_orcamento.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT stg_dim_centro_custo FROM 'C:\Projeto controle orcamentario\dados\bruto\dim_centro_custo.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT stg_dim_categoria FROM 'C:\Projeto controle orcamentario\dados\bruto\dim_categoria.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT stg_dim_fornecedores FROM 'C:\Projeto controle orcamentario\dados\bruto\dim_fornecedores.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
BULK INSERT stg_dim_campanha FROM 'C:\Projeto controle orcamentario\dados\bruto\dim_campanha_marketing.csv' WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO

-- 4. Verificação
SELECT 'Sucesso!' as Status, COUNT(*) as Linhas_Fato FROM stg_lancamentos;