-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- VERIFICAÇÃO DE TRATAMENTOS NECESSÁRIOS --------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------- DIM_CAMPANHA ------------------------------------------------------------------------------

SELECT * FROM stg_dim_campanha -- OVERVIEW

-- VERIFICAÇÃO DE ESPAÇO EXTRAS
SELECT
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_campanha
       WHERE 
              LEN(id_camp) > LEN(TRIM(id_camp))
       ) AS 'espaços_ID',
       (SELECT
              COUNT(*)
       FROM 
              stg_dim_campanha
       WHERE
              LEN(nome_camp) > LEN(TRIM(nome_camp))
       ) AS 'espaços_Nome',
       (SELECT
              COUNT(*)
       FROM 
              stg_dim_campanha
       WHERE
              LEN(mes_ref) > LEN(TRIM(mes_ref))
       ) AS 'espaços_Mes_ref'

-- VERIFICAÇÃO DE NULOS OU VAZIOS

SELECT
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_campanha
       WHERE 
              id_camp IS NULL OR LEN(id_camp) = 0
       ) AS 'ID_nulo',
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_campanha
       WHERE 
              nome_camp IS NULL OR LEN(nome_camp) = 0
       ) AS 'nome_nulo',
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_campanha
       WHERE 
              mes_ref IS NULL OR LEN(mes_ref) = 0
       ) AS 'mes_ref_nulo'

-- VERIFICAÇÃO DE DUPLICIDADE DE CHAVE PRIMARIA

SELECT
       id_camp,
       COUNT(id_camp) AS 'contagem'
FROM
       stg_dim_campanha
GROUP BY
       id_camp
HAVING COUNT(id_camp) > 1

-- VERIFICAÇÃO DE DUPLICIDADE DE NOME DE CAMPANHA

SELECT
       nome_camp,
       COUNT(nome_camp) AS 'contagem'
FROM
       stg_dim_campanha
GROUP BY
       nome_camp
HAVING COUNT(nome_camp) > 1


-- VERIFICAÇÃO DE MESES INVALIDOS

SELECT
       COUNT(*) AS 'meses_invalidos'
FROM
       stg_dim_campanha
WHERE mes_ref < 1 OR mes_ref > 12

-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_dim_campanha'

/* RESULTADO DA VERIFICAÇÃO:
- ESPAÇOS EXTRAS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- NULOS OU VAZIOS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- DUPLICIDADE DE CHAVE PRIMARIA: 0 ENCONTRADAS, NENHUM TRATAMENTO NECESSÁRIO
- DUPLICIDADE DE NOME DE CAMPANHA: 0 ENCONTRADAS, NENHUM TRATAMENTO NECESSÁRIO
- MESES INVALIDOS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- TIPOS DE DADOS: ID E MES_REF ESTÃO COMO VARCHAR AO INVÉS DE INT. TRATAMENTO NECESSÁRIO: CONVERTER EM INT.
*/
------------------------------------- DIM_CENTRO_CUSTO ---------------------------------------------------------------------------------------------------------

SELECT * FROM stg_dim_centro_custo -- OVERVIEW

-- VERIFICAÇÃO DE ESPAÇOS EXTRAS

SELECT
       (SELECT 
              COUNT(*)
       FROM
              stg_dim_centro_custo
       WHERE
              LEN(id_cc) > LEN(TRIM(id_cc))
       ) AS 'espaços_ID',
       (SELECT
              COUNT(*)
       FROM
              stg_dim_centro_custo
       WHERE
              LEN(nome_cc) > LEN(TRIM(nome_cc))
       ) AS 'espaços_nome'

-- VERIFICAÇÃO DE NULOS

SELECT
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_centro_custo
       WHERE 
              id_cc IS NULL OR LEN(id_cc) = 0
       ) AS 'ID_nulo',
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_centro_custo
       WHERE 
              nome_cc IS NULL OR LEN(nome_cc) = 0
       ) AS 'nome_cc_nulo'

-- VERIFICAÇÃO DE DUPLICIDADE DE CHAVE PRIMARIA

SELECT
       id_cc,
       COUNT(id_cc) AS 'contagem'
FROM
       stg_dim_centro_custo
GROUP BY
       id_cc
HAVING COUNT(id_cc) > 1 

-- VERIFICAÇÃO DE DUPLICIDADE NO NOME DO CENTRO DE CUSTO

SELECT
       TRIM(nome_cc) AS 'nome_cc',
       COUNT(TRIM(nome_cc)) AS 'contagem'
FROM
       stg_dim_centro_custo
GROUP BY
       TRIM(nome_cc)
HAVING COUNT(TRIM(nome_cc)) > 1 

-- VERIFICAÇÃO DE PADRONIZAÇÃO DE CAIXA (MAIUSCULAS / MINUSCULAS)

SELECT 
    COUNT(*) AS 'Nomes_fora_do_padrao'
FROM stg_dim_centro_custo
WHERE
       LEN(TRIM(nome_cc)) > 3 -- PARA CASOS EM QUE O NOME É UMA ABREVIAÇÃO
       AND TRIM(nome_cc) COLLATE Latin1_General_CS_AS <> UPPER(LEFT(TRIM(nome_cc), 1)) 
                                                     + LOWER(RIGHT(TRIM(nome_cc), LEN(TRIM(nome_cc)) - 1))

-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_dim_centro_custo'    

/* RESULTADO DA VERIFICAÇÃO:
- ESPAÇOS EXTRAS: FORAM IDENTIFICADOS 2 NOMES DE CENTROS DE CUSTO COM ESPAÇOS EXTRAS NO INICIO E/OU NO FIM. TRATAMENTO NECESSÁRIO: USO DO TRIM() PARA CORRIGIR
- NULOS E VAZIOS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- DUPLICIDADES NA CHAVE PRIMARIA: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- DUPLICIDADES NO NOME DO CENTRO DE CUSTO: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- NOMES DE CENTROS DE CUSTO FORA DO PADRÃO INITCAP: FORAM DETECTADOS 3 CENTROS DE CUSTO FORA DO PADRÃO. TRATAMENTO NECESSÁRIO: UTILIZAÇÃO DE TÉCNICAS DE
FORMATAÇÃO DE STRING (UPPER, LOWER, LEFT, LOWER, TRIM) PARA PADRONIZAÇÃO.
- TIPOS DE DADOS: A COLUNA "ID_CC" ESTÁ CONFIGURADA COMO VARCHAR, MAS DEVERIA SER INT. TRATAMENTO NECESSÁRIO: CONVERTER PARA INT.
*/

------------------------------------- DIM_CATEGORIA -------------------------------------------------------------------------------------------------------

SELECT * FROM stg_dim_categoria -- OVERVIEW

-- VERIFICAÇÃO DE ESPAÇOS EXTRAS

SELECT
       (SELECT 
              COUNT(*)
       FROM
              stg_dim_categoria
       WHERE
              LEN(id_cat) > LEN(TRIM(id_cat))
       ) AS 'espaços_ID_cat',
       (SELECT 
              COUNT(*)
       FROM
              stg_dim_categoria
       WHERE
              LEN(id_cc) > LEN(TRIM(id_cc))
       ) AS 'espaços_ID_cc',
       (SELECT
              COUNT(*)
       FROM
              stg_dim_categoria
       WHERE
              LEN(nome_cat) > LEN(TRIM(nome_cat))
       ) AS 'espaços_nome'

-- VERIFICAÇÃO DE NULOS OU VAZIOS

SELECT
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_categoria
       WHERE 
              id_cat IS NULL OR LEN(id_cat) = 0
       ) AS 'ID_cat_nulo',
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_categoria
       WHERE 
              id_cc IS NULL OR LEN(id_cc) = 0
       ) AS 'ID_cc_nulo',
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_categoria
       WHERE 
              nome_cat IS NULL OR LEN(nome_cat) = 0
       ) AS 'nome_cat_nulo'

-- APÓS IDENTIFICAR QUE HAVIAM 1 ID_CAT E 1 ID_CC NULO, CONSULTEI QUAL ERA O REGISTRO
SELECT * FROM stg_dim_categoria
WHERE id_cat IS NULL OR id_cc IS NULL

-- AO IDENTIFICAR O REGISTRO, INFERI QUE PODERIA SE TRATAR DE UMA DUPLICIDADE DE NOME DE CATEGORIA E PARA TESTAR SE MINHA TEORIA ESTAVA CORRETA, EXECUTEI A SEGUINTE QUERY:
SELECT
       nome_cat,
       COUNT(nome_cat) AS 'contagem'
FROM stg_dim_categoria
GROUP BY nome_cat
HAVING COUNT(nome_cat) > 1

-- VERIFICAÇÃO DE DUPLICIDADE DE CHAVE PRIMARIA

SELECT
       id_cat,
       COUNT(id_cat) AS 'contagem'
FROM stg_dim_categoria
GROUP BY id_cat
HAVING COUNT(id_cat) > 1

-- VERIFICAÇÃO DE PADRONIZAÇÃO DE CAIXA (MAIUSCULAS / MINUSCULAS)

SELECT 
    COUNT(*) AS 'Nomes_fora_do_padrao'
FROM stg_dim_categoria
WHERE
       LEN(TRIM(nome_cat)) > 3 -- PARA CASOS EM QUE O NOME É UMA ABREVIAÇÃO
       AND TRIM(nome_cat) COLLATE Latin1_General_CS_AS = UPPER(TRIM(nome_cat))

-- APÓS IDENTIFICAR QUE EXISTE 1 NOME DE CATEGORIA FORA DO PADRÃO, FIZ A SEGUINTE QUERY PARA IDENTIFICAR QUAL NOME É ESSE:
SELECT
       nome_cat
FROM stg_dim_categoria
WHERE 
       LEN(TRIM(nome_cat)) > 3 
       AND TRIM(nome_cat) COLLATE Latin1_General_CS_AS = UPPER(TRIM(nome_cat))

-- VERIFICAÇÃO DE CHAVES PRIMÁRIAS EM FORMATO INAPROPRIADO

SELECT
       (SELECT 
              COUNT(*)
       FROM stg_dim_categoria
       WHERE
              id_cat LIKE '%.%') AS 'ID_cat_com_ponto_decimal',
       (SELECT 
              COUNT(*)
       FROM stg_dim_categoria
       WHERE
              id_cc LIKE '%.%') AS 'ID_cc_com_ponto_decimal'

-- VERIFICACAO DE INTEGRIDADE REFERENCIAL DA CHAVE ESTRANGEIRA

SELECT
       id_cc
FROM 
       stg_dim_categoria
WHERE 
       CAST(CAST(id_cc AS FLOAT) AS INT) NOT IN (SELECT ID_CC FROM stg_dim_centro_custo)

-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_dim_categoria' 

/* RESULTADO DAS VERIFICAÇÕES:

- ESPAÇOS EXTRAS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO

- NULOS OU VAZIOS: 1 ID_CAT E 1 ID_CC NULO, APÓS IDENTIFICADO O REGISTRO FOI RASTREADO E FOI IDENTIFICADO QUE SE TRATAVA DE UM NOME DE CATEGORIA DUPLICADO. 
TRATAMENTO NECESSÁRIO: DESCARTAR DUPLICADOS NA CARGA DA TABELA TRUSTED, IMPORTANDO APENAS REGISTROS EM QUE ID_CAT E ID_CC NÃO SÃO NULOS.

- DUPLICIDADE DE CHAVE PRIMARIA: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO

- PADRONIZAÇÃO DE CAIXA: FOI IDENTIFICADO QUE O UNICO NOME DE CATEGORIA FORA DO PADRÃO É O QUE ESTÁ EM DUPLICIDADE, PORTANTO SERÁ EXCLUÍDO, LOGO NENHUM TRATAMENTO 
DE PADRONIZAÇÃO DE CAIXA SERÁ NECESSÁRIO.

- CHAVES PRIMÁRIAS EM FORMATO INAPROPRIADO: APÓS IDENTIFICAR VISUALMENTE NO OVERVIEW QUE EXISTIAM CHAVES PRIMARIAS EM FORMATO INAPROPRIADO (COM PONTO DECIMAL), 
FIZ UMA QUERY PARA IDENTIFICAR QUANTAS CHAVES EM FORMATO INAPROPRIADO EXISTIAM. FORAM IDENTIFICADAS 50 CHAVES INAPROPRIADAS. 
TRATAMENTO NECESSÁRIO: UTILIZAR 2 "CASTS" PARA CONVERTER O NUMERO "FLOAT" EM INT, TORNANDO-O APROPRIADO PARA SER UMA CHAVE PRIMARIA. 

- INTEGRIDADE REFERENCIAL DA CHAVE ESTRANGEIRA: 0 CHAVES NÃO REFERENCIADAS ENCONTRADAS, NENHUM TRATAMENTO NECESSÁRIO

- TIPOS DE DADOS: AS COLUNAS " ID_CAT" E "ID_CC" ESTÃO CONFIGURADAS COMO VARCHAR, MAS DEVERIAM SER INT. TRATAMENTO NECESSÁRIO: CONVERTER PARA INT.

*/

------------------------------------- DIM_FORNECEDORES -------------------------------------------------------------------------------------------------------

SELECT * FROM stg_dim_fornecedores

-- VERIFICAÇÃO DE ESPAÇOS EXTRAS

SELECT
       (SELECT 
              COUNT(*)
       FROM
              stg_dim_fornecedores
       WHERE
              LEN(id_forn) > LEN(TRIM(id_forn))
       ) AS 'espaços_ID',
       (SELECT
              COUNT(*)
       FROM
              stg_dim_fornecedores
       WHERE
              LEN(nome_forn) > LEN(TRIM(nome_forn))
       ) AS 'espaços_nome'

-- VERIFICAÇÃO DE NULOS E VAZIOS

SELECT
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_fornecedores
       WHERE 
              id_forn IS NULL OR LEN(id_forn) = 0
       ) AS 'ID_nulo',
       (SELECT
              COUNT(*) 
       FROM
              stg_dim_fornecedores
       WHERE 
              nome_forn IS NULL OR LEN(nome_forn) = 0
       ) AS 'nome_forn_nulo'

-- VERIFICAÇÃO DE DUPLICIDADE DE CHAVE PRIMÁRIA

SELECT
       id_forn,
       COUNT(id_forn) AS contagem
FROM
       stg_dim_fornecedores
GROUP BY id_forn
HAVING COUNT(id_forn) > 1

-- VERIFICAÇÃO DE DUPLICIDADE DE NOME DE FORNECEDOR

SELECT
       nome_forn,
       COUNT(nome_forn) AS contagem
FROM
       stg_dim_fornecedores
GROUP BY nome_forn
HAVING COUNT(nome_forn) > 1

-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_dim_fornecedores' 

/* RESULTADO DA VERIFICAÇÃO:
- ESPAÇOS EXTRAS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- NULOS E VAZIOS: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- DUPLICIDADE DE CHAVE PRIMÁRIA: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- DUPLICIDADE DE NOME DE FORNECEDOR: 0 ENCONTRADOS, NENHUM TRATAMENTO NECESSÁRIO
- TIPOS DE DADOS: A COLUNA "ID_FORN" ESTÁ CONFIGURADA COMO VARCHAR, MAS DEVERIA SER INT. TRATAMENTO NECESSÁRIO: CONVERTER PARA INT.

*/