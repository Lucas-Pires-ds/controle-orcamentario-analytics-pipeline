# Camada Bronze — Ingestão de Dados
 
## Responsabilidade
 
Receber os dados brutos e armazená-los sem aplicar nenhuma transformação, validação ou tipagem. Todas as colunas chegam como `VARCHAR(MAX)`, pois o tratamento é responsabilidade da Silver.
 
---
 
## 📂 Estrutura de Arquivos
 
```
01_bronze/
├── README.md
├── python/
│   ├── 01_geracao_das_dimensoes.py
│   └── 02_geracao_das_facts.py
└── sql/
    └── 01_ingestao_de_dados.sql
```
 
---
 
## 📊 Tabelas de Staging
 
| Tabela | Descrição |
|--------|-----------|
| `stg_lancamentos` | Lançamentos financeiros diários |
| `stg_orcamento` | Valores orçados por centro de custo e categoria |
| `stg_dim_centro_custo` | Centros de custo da empresa |
| `stg_dim_categoria` | Categorias de despesa por centro de custo |
| `stg_dim_fornecedores` | Cadastro de fornecedores |
| `stg_dim_campanha` | Campanhas de marketing |
 
---
 
## 🔄 Ingestão
 
Os CSVs em `data/raw/` são carregados nas tabelas de staging via `BULK INSERT`:
 
```sql
BULK INSERT stg_lancamentos 
FROM 'C:\seu_caminho\data\raw\fact_lancamentos.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
)
```
 
| Parâmetro | Valor | Motivo |
|-----------|-------|--------|
| `FIRSTROW` | 2 | Ignora o header do CSV |
| `CODEPAGE` | 65001 | UTF-8 para caracteres acentuados |
| `FIELDTERMINATOR` | `,` | Delimitador de colunas |
| `ROWTERMINATOR` | `\n` | Delimitador de linhas |
 
> Ajuste o caminho dos arquivos conforme seu ambiente antes de executar.
 
---
 
## 📖 Próxima etapa
 
**[Camada Silver →](../02_silver/)**