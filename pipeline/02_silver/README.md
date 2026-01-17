# Camada Silver — Limpeza e Modelagem Dimensional

## Responsabilidade

A camada Silver é responsável por **limpar, tipar e estruturar** os dados brutos da Bronze em um **modelo dimensional** confiável.

**Objetivo**: Criar uma base de dados com integridade referencial garantida e qualidade validada.

---

## 🎯 Características

- Dados corretamente tipados (`INT`, `DECIMAL`, `DATE`, `VARCHAR`)
- Modelo dimensional em **Star Schema**
- Integridade referencial via `PRIMARY KEY` e `FOREIGN KEY`
- Transformações via **Views** (auditáveis e reversíveis)
- Framework completo de validação de qualidade

---

## 📂 Estrutura de Arquivos
```
silver/
├── README.md (este arquivo)
└── sql/
    ├── 02_Criacao_de_tabelas.sql
    ├── 03_Diagnostico_de_dados_dimensoes.sql
    ├── 04_Diagnostico_de_dados_facts.sql
    ├── 05_Views_e_Transformacoes.sql
    └── 06_Carga_de_dados.sql
```

---

## 🧩 Modelo Dimensional

O modelo implementado segue o padrão **Star Schema** com as seguintes entidades:

### Dimensões

| Tabela | Chave Primária | Descrição |
|--------|----------------|-----------|
| `dim_centro_custo` | `id_cc` | Centros de custo da empresa + membro coringa (-1) |
| `dim_categoria` | `id_categoria` | Categorias de despesas (com FK para centro de custo) |
| `dim_fornecedores` | `id_forn` | Cadastro de fornecedores |
| `dim_camp_marketing` | `id_camp` | Campanhas de marketing |
| `dim_calendario` | `data` | Calendário completo (2023-2024) com agregações temporais |

### Fatos

| Tabela | Chave Primária | Descrição |
|--------|----------------|-----------|
| `fact_orcamento` | `id_orcamento` | Valores orçados mensais por centro de custo e categoria |
| `fact_lancamentos` | `id_lancamento` | Lançamentos financeiros diários |

---

## 🔍 Processo de Diagnóstico

Após a ingestão na Bronze, foi realizado **Data Profiling** sistemático por meio de queries SQL de análise exploratória.

### Metodologia de Diagnóstico

O profiling foi estruturado em **validações padronizadas** aplicadas a todas as tabelas:

1. **Auditoria de espaços extras**: `LEN(col) > LEN(TRIM(col))`
2. **Detecção de nulos e vazios**: `col IS NULL OR LEN(col) = 0`
3. **Verificação de duplicidades**: `GROUP BY col HAVING COUNT(*) > 1`
4. **Validação de domínio**: Ranges válidos (ex: mês entre 1 e 12)
5. **Integridade referencial**: Verificação de FKs inválidas
6. **Análise de tipagem**: Identificação de conversões necessárias
7. **Detecção de outliers**: Análise estatística de valores extremos

### Exemplo de Query de Diagnóstico
```sql
-- Verificação de integridade referencial em fact_lancamentos
SELECT
    (SELECT COUNT(*) FROM stg_lancamentos
     WHERE id_centro_custo NOT IN (SELECT id_cc FROM dim_centro_custo)
    ) AS 'ID_centro_custo_invalido',
    
    (SELECT COUNT(*) FROM stg_lancamentos
     WHERE id_categoria NOT IN (SELECT id_categoria FROM dim_categoria)
    ) AS 'ID_categoria_invalido'
```

### Análise de Impacto Financeiro

Antes de decidir descartar ou tratar registros problemáticos, foi calculado o impacto financeiro:
```sql
-- Avaliação do impacto de registros sem data
SELECT
    FORMAT(SUM(CAST(valor_lancamento AS DECIMAL(18,2))), 'C') AS 'valor_total',
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) 
            FROM stg_lancamentos WHERE data_lancamento IS NULL), 'C') AS 'sem_data',
    FORMAT(
        (SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) 
         FROM stg_lancamentos WHERE data_lancamento IS NULL) 
        / SUM(CAST(valor_lancamento AS DECIMAL(18,2))), '0.00%'
    ) AS 'impacto_(%)'
FROM stg_lancamentos
```

Essa abordagem permitiu decisões técnicas baseadas em dados, não em suposições.

---

## 🧪 Principais Problemas Identificados e Tratamentos

### Dimensões

#### dim_centro_custo
- **Espaços extras**: 3 registros (" Marketing", "RH ", "  Facilities")
- **Inconsistência de case**: "FINANCEIRO" em uppercase
- **Tratamento**: `TRIM()` + padronização InitCap

#### dim_categoria
- **IDs decimais**: Todos os 50 IDs no formato "101.0", "102.0"
- **Registro duplicado**: 1 categoria com ID e FK nulos
- **Nome em uppercase**: "ALUGUEL/CONDOMÍNIO"
- **Tratamento**: Conversão `CAST(CAST(col AS FLOAT) AS INT)` + descarte de nulos

#### dim_fornecedores e dim_camp_marketing
- **Nenhum problema identificado**
- **Tratamento**: Conversão de tipos apenas

### Fatos

#### fact_lancamentos
- **Datas nulas**: 27 registros (0,6% do valor total)
- **Centro de custo inválido**: 65 registros com ID 999 (1,3% do valor total)
- **Valores negativos**: 51 registros sem flag de estorno
- **Status duplicados**: 5 variações ("Pago", "Paga", "PAGO", "Aberto", "Pending")

**Decisões tomadas**:
- Registros sem data: **descartados** (baixo impacto financeiro vs risco analítico)
- Centro de custo inválido: **membro coringa criado** (ID -1 "Não identificado")
- Valores negativos: **tratados com ABS()** + preservação de `valor_original`
- Status: **normalizados** para "Pago" e "Aberto"

#### fact_orcamento
- **Outliers extremos**: 6 registros com valores 20x acima da média (~R$ 1M)
- **IDs decimais**: Conversão necessária
- **Tratamento**: Flag `status_dado` criada ("Dado suspeito" / "Dado confiavel")

---

## 🔄 Fluxo de Transformação

### 1. Diagnóstico (Scripts 03 e 04)

Queries de profiling executadas sobre as tabelas `stg_*` identificam problemas e quantificam impactos.

### 2. Views de Transformação (Script 05)

As transformações são aplicadas via **Views**, não diretamente nas tabelas físicas:
```sql
CREATE OR ALTER VIEW vw_lancamentos AS 
SELECT  
    CAST(id_lancamento AS INT) AS 'id_lancamento',
    CAST(CAST(data_lancamento AS DATE) AS DATETIME) AS 'data_lancamento',
    CAST(CASE 
        WHEN id_centro_custo NOT IN (SELECT id_cc FROM dim_centro_custo)
        THEN -1 
        ELSE id_centro_custo 
    END AS INT) AS 'id_cc',
    ABS(CAST(valor_lancamento AS DECIMAL(16,2))) AS 'valor_absoluto',
    CAST(valor_lancamento AS DECIMAL(16,2)) AS 'valor_original',
    CASE 
        WHEN status_pagamento IN ('PAGO', 'Paga', 'Pago') THEN 'Pago'
        WHEN status_pagamento IN ('Pending', 'Aberto') THEN 'Aberto'
    END AS 'status_pagamento'
FROM stg_lancamentos
WHERE data_lancamento IS NOT NULL
```

### 3. Criação de Tabelas (Script 02)

Tabelas Silver criadas com constraints completas:
```sql
CREATE TABLE fact_lancamentos(
    id_lancamento INT NOT NULL,
    data_lancamento DATETIME NOT NULL,
    id_centro_custo INT NOT NULL,
    valor DECIMAL(16,2) NOT NULL,
    valor_original DECIMAL(16,2) NOT NULL,
    
    CONSTRAINT fact_lancamentos_id_lancamento_pk PRIMARY KEY(id_lancamento),
    CONSTRAINT fact_lancamentos_valor_ck CHECK(valor > 0),
    CONSTRAINT fact_lancamentos_id_centro_custo_fk 
        FOREIGN KEY(id_centro_custo) REFERENCES dim_centro_custo(id_cc)
)
```

### 4. Carga de Dados (Script 06)

Dados são persistidos a partir das Views:
```sql
INSERT INTO fact_lancamentos
SELECT * FROM vw_lancamentos
```

**Carga programática da dim_calendario**:
```sql
DECLARE @DATA DATETIME 
SET @DATA = '20230101'
WHILE @DATA < '20250101'
BEGIN
    INSERT INTO dim_calendario (...) VALUES (...)
    SET @DATA += 1
END
```

---

## 📊 Detalhamento das Tabelas Fato

### fact_orcamento

**Granularidade**: Mensal por centro de custo e categoria

**Campos principais**:
- `id_orcamento` (PK)
- `data_orcamento` (último dia do mês via `EOMONTH`)
- `ano`, `mes`
- `id_centro_custo`, `id_categoria` (FKs)
- `valor` (sempre positivo via CHECK)
- `status_dado` ('Dado confiavel' ou 'Dado suspeito')

**Lógica de detecção de outliers**:
```sql
CASE
    WHEN CAST(valor_orcado AS DECIMAL(18,2)) / 
         AVG(CAST(valor_orcado AS DECIMAL(18,2))) 
         OVER (PARTITION BY id_centro_custo, id_categoria) - 1 > 9 
    THEN 'Dado suspeito' 
    ELSE 'Dado confiavel'
END
```

Valores 10x acima da média são sinalizados, mas não removidos.

### fact_lancamentos

**Granularidade**: Diária por transação

**Campos principais**:
- `id_lancamento` (PK)
- `data_lancamento`
- `id_centro_custo` (FK, aceita -1 para dados não identificados)
- `id_categoria`, `id_fornecedor`, `id_campanha` (FKs)
- `valor` (tratado com `ABS()`)
- `valor_original` (preservado para auditoria)
- `status_pagamento` ('Pago' ou 'Aberto')

**Redundância defensiva**: 
- `valor`: Sempre positivo, usado em cálculos
- `valor_original`: Preserva sinal original para investigação

---

## 📅 Dimensão Temporal — dim_calendario

A `dim_calendario` foi gerada programaticamente via loop `WHILE`, cobrindo todo o período de análise.

**Período**: 01/01/2023 a 31/12/2024 (731 dias)

**Agregações temporais incluídas**:
- Dias úteis (flag 'sim'/'nao' baseado em dia da semana)
- Mês, nome do mês, ano/mês
- Trimestre, ano/trimestre
- Semestre, ano/semestre  
- Bimestre, ano/bimestre

**Constraints aplicadas**:
```sql
CONSTRAINT dim_calendario_data_ck CHECK (data BETWEEN '20230101' AND '20241231'),
CONSTRAINT dim_calendario_mes_ck CHECK (mes BETWEEN 1 AND 12),
CONSTRAINT dim_calendario_semestre_ck CHECK (semestre IN (1,2)),
CONSTRAINT dim_calendario_trimestre_ck CHECK (trimestre IN (1,2,3,4))
```

**Propósito**: Garantir continuidade temporal nas análises, especialmente para cálculos de MoM e YoY na camada Gold.

---

## 🎯 Decisões Técnicas

### Uso de Views para Transformações

Views foram adotadas ao invés de processar diretamente na Bronze devido a:

- **Auditoria**: Transformações visíveis e versionáveis no código SQL
- **Rastreabilidade**: Sempre possível comparar dado original vs transformado
- **Flexibilidade**: Ajustes em regras não requerem nova ingestão
- **Separação de responsabilidades**: Bronze preserva dado bruto, Views aplicam lógica

### Membro Coringa para Referências Inválidas

Foi criado o registro `-1 (Não identificado)` em `dim_centro_custo` para:

- Preservar valores financeiros que seriam perdidos
- Manter integridade referencial (não viola FK)
- Permitir análise de "dados não classificados"
- Facilitar rastreamento de problemas na origem

### Preservação de Valores Originais

A tabela `fact_lancamentos` mantém duas colunas de valor:

- `valor`: Tratado com `ABS()`, sempre positivo, usado em cálculos
- `valor_original`: Preserva sinal original para auditoria

Essa decisão permite investigar posteriormente se valores negativos eram legítimos.

### Sinalização ao Invés de Remoção de Outliers

Outliers no orçamento recebem flag `status_dado = 'Dado suspeito'` mas não são removidos:

- Valores extremos podem ser legítimos
- Decisão de filtrar deve ser do analista, não da engenharia
- Preserva integridade dos dados
- Permite auditoria e correção posterior se necessário

---

## 📌 Resultado Final

Após todos os tratamentos:

- ✅ **100% dos registros** respeitam tipagem correta
- ✅ **Integridade referencial** garantida via constraints
- ✅ **Modelo dimensional** pronto para consumo
- ✅ **Dados confiáveis** e rastreáveis
- ✅ **Continuidade temporal** garantida via dim_calendario

**Registros processados**:
- dim_centro_custo: 11 registros (10 originais + 1 coringa)
- dim_categoria: 50 registros
- dim_fornecedores: 20 registros
- dim_camp_marketing: 4 registros
- dim_calendario: 731 registros
- fact_orcamento: ~1.176 registros (24 meses × 10 CCs × 5 categorias - 2% removidos)
- fact_lancamentos: ~4.973 registros (~5.000 originais - 27 sem data)

---

## 📖 Próxima Etapa

Os dados da camada Silver são consumidos pela **camada Gold**, que cria views analíticas especializadas com métricas pré-calculadas para consumo no Power BI.

📖 **[Documentação da camada Gold](../gold/)**

---