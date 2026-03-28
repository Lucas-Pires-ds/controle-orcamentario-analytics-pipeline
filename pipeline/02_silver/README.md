# Camada Silver — Limpeza e Modelagem Dimensional

## Responsabilidade

Limpar, tipar e estruturar os dados brutos da Bronze em um modelo dimensional confiável, com integridade referencial garantida.

---

## 📂 Estrutura de Arquivos

```
02_silver/
├── README.md
└── sql/
    ├── 02.1_EDA_dimensoes.sql
    ├── 02.2_EDA_facts.sql
    ├── 03_Criacao_tabelas.sql
    ├── 04_Transform.sql
    └── 05_Load.sql
```

---

## 🧩 Modelo Dimensional

![Modelo Dimensional](../../docs_e_imagens/modelo_dimensional.png)

### Dimensões

| Tabela | Chave Primária | Descrição |
|--------|----------------|-----------|
| `dim_centro_de_custo` | `id_centro_de_custo` | Centros de custo + membro coringa (id -1) |
| `dim_categoria` | `id_categoria` | Categorias de despesa (FK para centro de custo) |
| `dim_fornecedores` | `id_fornecedor` | Cadastro de fornecedores |
| `dim_camp_marketing` | `id_campanha` | Campanhas de marketing |
| `dim_mes` | `ano_mes` | Referência mensal para cruzamento de granularidades |
| `dim_calendario` | `data` | Calendário completo (2023–2024) com agregações temporais |

### Fatos

| Tabela | Chave Primária | Granularidade |
|--------|----------------|---------------|
| `fact_orcamento` | `id_orcamento` | Mensal por centro de custo e categoria |
| `fact_lancamentos` | `id_lancamento` | Diária por transação |

---

## 🔍 Diagnóstico de Dados

Antes de qualquer transformação, foram executadas queries de análise exploratória sobre todas as tabelas de staging. As verificações cobriram espaços extras, nulos e vazios, duplicidade de chaves, integridade referencial, consistência de domínio e tipagem.

Para cada problema identificado, o impacto financeiro foi calculado antes de decidir o tratamento — descarte, correção ou sinalização.

### Problemas identificados e tratamentos

#### Dimensões

| Tabela | Problema | Tratamento |
|--------|----------|------------|
| `dim_centro_de_custo` | 2 nomes com espaços extras, 3 fora do padrão InitCap | `TRIM()` + padronização InitCap |
| `dim_categoria` | 50 IDs no formato float ("101.0") | `CAST(CAST(col AS FLOAT) AS INT)` |
| `dim_categoria` | 1 registro duplicado com ID e FK nulos | Descarte via `WHERE id_cat IS NOT NULL` |
| `dim_fornecedores` | Nenhum problema | Conversão de tipos apenas |
| `dim_camp_marketing` | Nenhum problema | Conversão de tipos apenas |

#### Fatos

| Tabela | Problema | Decisão | Justificativa |
|--------|----------|---------|---------------|
| `fact_lancamentos` | 27 datas nulas (0,19% do valor total) | Descarte | Baixo impacto financeiro vs risco em análises temporais |
| `fact_lancamentos` | 65 registros com centro de custo ID 999 (0,57% do valor total) | Membro coringa ID -1 | Impacto acumulado com os descartes anteriores chegaria a ~1%, então optou-se por preservar |
| `fact_lancamentos` | 51 valores negativos sem flag de estorno | `ABS()` + preservação de `valor_original` | Tratados como erro de sinal; valor original mantido para auditoria |
| `fact_lancamentos` | 5 variações de status ("Pago", "Paga", "PAGO", "Aberto", "Pending") | Normalização para "Pago" e "Aberto" | Inconsistência semântica sem impacto financeiro |
| `fact_orcamento` | 6 outliers com valores ~20x a média | Flag `status_dado` | Possível erro de digitação, decisão de filtrar fica para o analista |

---

## 🔄 Fluxo de Transformação

As transformações são aplicadas via Views sobre as tabelas de staging, não diretamente nos dados físicos. Isso mantém o dado original intacto na Bronze e permite ajustar regras de negócio sem nova ingestão.

```
stg_* (Bronze) → Views de transformação (vw_*) → Tabelas Silver (dim_* / fact_*)
```

1. **Scripts 02.1 e 02.2** — Diagnóstico sobre as tabelas `stg_*`
2. **Script 03** — Criação das tabelas Silver com constraints
3. **Script 04** — Views de limpeza e transformação
4. **Script 05** — Carga a partir das Views

---

## 📅 dim_calendario

Gerada via loop `WHILE` cobrindo 01/01/2023 a 31/12/2024 (731 dias).

Além das colunas básicas de data, inclui agregações temporais pré-calculadas, como trimestre, semestre, bimestre e flags de dia útil, para evitar recálculo no Power BI.

O propósito principal é garantir continuidade temporal nas views Gold: sem ela, `LAG()` compararia meses não consecutivos quando não há lançamentos em algum período.

---

## 🎯 Decisões Técnicas

**Views para transformações**

As transformações ficam em Views e não são aplicadas diretamente sobre os dados da Bronze. Isso mantém rastreabilidade completa — sempre é possível comparar o dado original com o tratado — e permite ajustar regras de negócio sem recarregar dados.

**Membro coringa para IDs inválidos**

Em vez de descartar os 65 lançamentos com centro de custo inexistente, foi criado o registro `-1 (Não identificado)` na `dim_centro_de_custo`. Isso preserva o valor financeiro dos registros, mantém a integridade referencial e permite rastrear a origem do problema.

**Duas colunas de valor em `fact_lancamentos`**

`valor` recebe `ABS()` e é sempre positivo, ele é usado em todos os cálculos. `valor_original` preserva o sinal original para auditoria. A separação permite investigar posteriormente se algum valor negativo era legítimo (estorno, devolução) sem comprometer a consistência das métricas.

---

## 📊 Registros após carga

| Tabela | Registros |
|--------|-----------|
| `dim_centro_de_custo` | 11 (10 originais + 1 coringa) |
| `dim_categoria` | 50 |
| `dim_fornecedores` | 20 |
| `dim_camp_marketing` | 4 |
| `dim_mes` | 24 |
| `dim_calendario` | 731 |
| `fact_orcamento` | ~1.176 |
| `fact_lancamentos` | ~4.973 |

---

## 📖 Próxima etapa

**[Camada Gold →](../03_gold/)**