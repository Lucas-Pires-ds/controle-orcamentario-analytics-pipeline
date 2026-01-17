# Camada Bronze — Ingestão de Dados

## Responsabilidade

A camada Bronze é responsável pela **ingestão de dados brutos** sem aplicar nenhuma transformação, validação ou tipagem.

**Objetivo**: Garantir que a carga de dados nunca falhe por incompatibilidade de tipos ou valores inesperados.

---

## 🎯 Características

- Todas as colunas armazenadas como `VARCHAR(MAX)` ou `VARCHAR(200)`
- Nenhuma validação ou constraint aplicada
- Preservação integral dos dados originais
- Nomenclatura padronizada: `stg_*` (staging)

---

## 🔧 Tecnologias Utilizadas

### Python (Pandas)
- Geração de dados sintéticos simulando sistema financeiro
- Exportação para CSV

### SQL Server (BULK INSERT)
- Carga rápida de grandes volumes
- Parametrizável por ambiente

---

## 📂 Estrutura de Arquivos
```
bronze/
├── README.md (este arquivo)
├── scripts_python/
│   ├── 01_geracao_das_dimensoes.py
│   └── 02_geracao_das_facts.py
└── scripts_sql/
    └── 01_ingestao_de_dados.sql
```

---

## 📊 Tabelas Criadas

| Tabela | Descrição |
|--------|-----------|
| `stg_orcamento` | Valores orçados por centro de custo e categoria |
| `stg_lancamentos` | Lançamentos financeiros diários |
| `stg_dim_centro_custo` | Centros de custo da empresa |
| `stg_dim_categoria` | Categorias de despesas |
| `stg_dim_fornecedores` | Cadastro de fornecedores |
| `stg_dim_campanha` | Campanhas de marketing ativas |

---

## 🔄 Processo de Ingestão

### 1. Geração dos Dados Sintéticos

Dois scripts Python geram CSVs simulando dados de um sistema financeiro real:

#### 01_geracao_das_dimensoes.py

Gera as dimensões analíticas com problemas típicos de dados reais:
```python
# Exemplo: Centro de Custo com espaços extras e variações de case
data_cc = {
    'id_centro_custo': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'nome_centro_custo': [
        "Administrativo", " Marketing", "Jurídico", "TI", "RH ", 
        "FINANCEIRO", "Comercial/Vendas", "Operações", "  Facilities", "Projetos Especiais"
    ]
}
```

**Dimensões geradas**:
- `dim_centro_custo.csv`: 10 centros de custo
- `dim_categoria.csv`: 50 categorias (5 por centro de custo, IDs 101-150)
- `dim_fornecedores.csv`: 20 fornecedores
- `dim_campanha_marketing.csv`: 4 campanhas sazonais

**Problemas propositais inseridos**:
- Espaços extras no início/fim de strings
- Variações de capitalização (UPPER, lower, Mixed)
- Um registro com uppercase total ("ALUGUEL/CONDOMÍNIO")

#### 02_geracao_das_facts.py

Gera as tabelas fato com granularidade temporal:

**fact_orcamento (mensal)**:
- Período: 2023-2024 (24 meses)
- ~1.200 linhas
- Valores base variam por centro de custo (RH maior, Marketing médio)
- 0,5% dos registros com valores absurdos (20x o normal)
- 2% dos meses removidos aleatoriamente (simula gaps no orçamento)

**fact_lancamentos (diária)**:
- Período: 01/01/2023 a 31/12/2024
- ~5.000 registros
- Volume diário varia (mais em dias úteis, menos em finais de semana)
- Sazonalidade simulada (Marketing intenso em maio, agosto, novembro, dezembro)
- 13º salário em dezembro (RH)

**Problemas propositais inseridos**:
- 0,5% dos registros sem data (valor `None`)
- 1% dos registros com centro de custo inválido (ID 999)
- 1% dos valores negativos (sem flag de estorno)
- Status de pagamento inconsistentes: "Pago", "Paga", "Aberto", "Pending", "PAGO"

### 2. Criação das Tabelas Staging

Script SQL: `01_ingestao_de_dados.sql`

Todas as tabelas Bronze seguem o mesmo padrão:
```sql
CREATE TABLE stg_lancamentos (
    id_lancamento VARCHAR(MAX),
    data_lancamento VARCHAR(MAX),
    id_centro_custo VARCHAR(MAX),
    id_categoria VARCHAR(MAX),
    id_fornecedor VARCHAR(MAX),
    id_campanha_marketing VARCHAR(MAX),
    valor_lancamento VARCHAR(MAX),
    status_pagamento VARCHAR(MAX)
);
```

**Características**:
- Todos os campos como `VARCHAR(MAX)`
- Nenhuma constraint ou validação
- Estrutura flexível para aceitar qualquer valor

### 3. Carga via BULK INSERT
```sql
BULK INSERT stg_lancamentos 
FROM 'C:\Projeto controle orcamentario\dados\bruto\fact_lancamentos.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
```

> **Nota**: O caminho do arquivo deve ser ajustado conforme o ambiente local

**Parâmetros utilizados**:
- `FIRSTROW = 2`: Ignora o header do CSV
- `CODEPAGE = '65001'`: UTF-8 para suportar caracteres acentuados
- `FIELDTERMINATOR = ','`: Delimitador de colunas
- `ROWTERMINATOR = '\n'`: Delimitador de linhas


---

## 🎯 Decisões Técnicas

### Tipagem Flexível com VARCHAR

Todas as colunas da camada Bronze foram definidas como `VARCHAR(MAX)` para maximizar a robustez da ingestão.

**Justificativa**: 
- Sistemas reais frequentemente enviam dados com tipagem inconsistente
- Evita falhas de carga por incompatibilidade de tipos
- Permite capturar qualquer valor, mesmo que incorreto ou inesperado
- Dados originais preservados integralmente para auditoria

O tratamento e conversão de tipos ocorrem apenas na camada Silver, após diagnóstico completo dos dados.

### Ausência de Validações na Bronze

A camada Bronze não aplica validações, constraints ou regras de negócio durante a ingestão.

**Justificativa**:

Esta decisão segue o princípio de separação de responsabilidades da arquitetura Medallion:

- **Bronze**: Ingestão pura, preservação do estado original
- **Silver**: Limpeza, validação e transformação
- **Gold**: Agregação e métricas analíticas

**Benefícios**:
- Rastreabilidade: Sempre possível consultar o dado original sem alterações
- Reprocessamento: Novas regras podem ser aplicadas sem reingestão
- Diagnóstico: Problemas de origem ficam visíveis para análise

---

---

## 📌 Próxima Etapa

Os dados brutos da camada Bronze são consumidos por **Views de transformação** que aplicam:

- Conversão de tipos (`VARCHAR` → `INT`, `DECIMAL`, `DATE`)
- Validações de integridade (datas nulas, IDs inválidos)
- Limpeza de textos (`TRIM`, normalização de case)
- Normalização de status de pagamento

📖 **[Documentação da camada Silver](../silver/)**

---