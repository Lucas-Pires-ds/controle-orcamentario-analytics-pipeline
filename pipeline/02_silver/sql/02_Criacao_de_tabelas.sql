-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------- CRIAÇÃO DE TABELAS --------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
GO

CREATE TABLE dim_camp_marketing(
       id_camp INT,
       nome_campanha VARCHAR(200),
       mes_referente INT,
       CONSTRAINT dim_camp_marketing_id_camp_pk PRIMARY KEY(id_camp)
)
GO

CREATE TABLE dim_centro_custo(
       id_cc INT,
       nome_cc VARCHAR(200),
       CONSTRAINT dim_centro_custo_id_cc_pk PRIMARY KEY(id_cc)
)
GO

CREATE TABLE dim_categoria(
       id_categoria INT,
       id_cc INT,
       nome_categoria VARCHAR(200)
       CONSTRAINT dim_categoria_id_categoria_pk PRIMARY KEY(id_categoria)
       CONSTRAINT dim_categoria_id_cc_fk FOREIGN KEY (id_cc) REFERENCES dim_centro_custo(id_cc)
)      
GO

CREATE TABLE dim_fornecedores(
       id_forn INT,
       nome_forn VARCHAR(200),
       CONSTRAINT dim_fornecedores_id_forn_pk PRIMARY KEY(id_forn)
)
GO

CREATE TABLE dim_calendario(
    data DATETIME NOT NULL,
    dia_da_semana VARCHAR(50) NOT NULL,
    dia_util VARCHAR(50),
    ano INT NOT NULL,
    mes INT NOT NULL,
    nome_do_mes VARCHAR(50) NOT NULL,
    mes_ano VARCHAR(50) NOT NULL,
    ano_mes INT NOT NULL,
    semestre INT NOT NULL,
    semestre_ano VARCHAR(50) NOT NULL,
    ano_semestre INT NOT NULL,
    trimestre INT NOT NULL,
    trimestre_ano VARCHAR(50) NOT NULL,
    ano_trimestre INT NOT NULL,
    bimestre INT NOT NULL,
    bimestre_ano VARCHAR(50) NOT NULL,
    ano_bimestre INT NOT NULL,

    CONSTRAINT dim_calendario_data_pk PRIMARY KEY (data),
    CONSTRAINT dim_calendario_data_ck CHECK (data BETWEEN '20230101' AND '20241231'),
    CONSTRAINT dim_calendario_dia_util_ck CHECK (dia_util in ('sim', 'nao')),
    CONSTRAINT dim_calendario_ano_ck CHECK (ano in (2023, 2024)),
    CONSTRAINT dim_calendario_mes_ck CHECK (mes BETWEEN 1 AND 12), 
    CONSTRAINT dim_calendario_semestre_ck CHECK (semestre IN (1,2)),
    CONSTRAINT dim_calendario_trimestre_ck CHECK (trimestre IN (1,2,3,4)),
    CONSTRAINT dim_calendario_bimestre_ck CHECK (bimestre IN (1,2,3,4,5,6))
)

GO

CREATE TABLE fact_lancamentos(
       id_lancamento INT NOT NULL,
       data_lancamento DATETIME NOT NULL,
       id_centro_custo INT NOT NULL,
       id_categoria INT NOT NULL,
       id_fornecedor INT NOT NULL,
       id_campanha INT,
       valor DECIMAL(16,2) NOT NULL,
       valor_original DECIMAL(16,2) NOT NULL,
       status_pagamento VARCHAR(20) NOT NULL,
       CONSTRAINT fact_lancamentos_id_lancamento_pk PRIMARY KEY(id_lancamento),
       CONSTRAINT fact_lancamentos_data_lancamento_ck CHECK(data_lancamento <= GETDATE() AND data_lancamento > '1991-01-01'),
       CONSTRAINT fact_lancamentos_id_centro_custo_fk FOREIGN KEY(id_centro_custo) REFERENCES dim_centro_custo(id_cc),
       CONSTRAINT fact_lancamentos_id_categoria_fk FOREIGN KEY(id_categoria) REFERENCES dim_categoria(id_categoria),
       CONSTRAINT fact_lancamentos_id_fornecedor_fk FOREIGN KEY(id_fornecedor) REFERENCES dim_fornecedores(id_forn),
       CONSTRAINT fact_lancamentos_id_campanha_fk FOREIGN KEY(id_campanha) REFERENCES dim_camp_marketing(id_camp),
       CONSTRAINT fact_lancamentos_valor_ck CHECK(valor > 0),
       CONSTRAINT fact_lancamentos_status_pagamento_ck CHECK(status_pagamento in ('Pago', 'Aberto'))
)
GO

CREATE TABLE fact_orcamento(
       id_orcamento INT NOT NULL,
       data_orcamento DATETIME NOT NULL,
       ano INT NOT NULL,
       mes INT NOT NULL,
       id_centro_custo INT NOT NULL,
       id_categoria INT NOT NULL,
       valor DECIMAL(18,2) NOT NULL,
       status_dado VARCHAR(50) NOT NULL
       CONSTRAINT fact_orcamento_id_orcamento_pk PRIMARY KEY(id_orcamento),
       CONSTRAINT fact_orcamento_data_ck CHECK(data_orcamento BETWEEN '20230101' AND '20241231'),
       CONSTRAINT fact_orcamento_ano_ck CHECK(ano <= YEAR(GETDATE()) AND ano >= 2000),
       CONSTRAINT fact_orcamento_mes_ck CHECK(mes BETWEEN 1 AND 12),
       CONSTRAINT fact_orcamento_id_centro_custo_fk FOREIGN KEY(id_centro_custo) REFERENCES dim_centro_custo(id_cc),
       CONSTRAINT fact_orcamento_id_categoria_fk FOREIGN KEY(id_categoria) REFERENCES dim_categoria(id_categoria),
       CONSTRAINT fact_orcamento_valor_ck CHECK(valor > 0),
       CONSTRAINT fact_orcamento_status_dado_ck CHECK(status_dado in ('Dado suspeito', 'Dado confiavel'))
)

GO


