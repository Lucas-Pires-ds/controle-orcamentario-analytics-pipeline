# Visualização de dados — Power BI

## Responsabilidade

O **Dashboard** é responsável por **consumir as views da camada Gold** e transformar os dados analíticos em **visualizações claras para tomada de decisão**, separando explicitamente visões **executivas (mensais)** e **operacionais (intra-mês)**.

**Objetivo**: Oferecer leitura executiva do desempenho orçamentário e, ao mesmo tempo, permitir acompanhamento operacional do consumo do mês corrente.

---

## 🎯 Princípios de Design Adotados

As decisões abaixo guiam toda a construção dos dashboards:

- **Separação de contextos**: visão executiva ≠ visão operacional
- **Coerência com a camada Gold**: dashboards não recriam lógica já resolvida em SQL
- **Leitura rápida**: poucos visuais centrais, com apoio de análises complementares
- **Rastreabilidade**: decisões analíticas documentadas, não implícitas

---

## 📊 Estrutura Geral do Dashboard

Foi definido **um único arquivo PBIX**, organizado em **múltiplas páginas**, ao invés de múltiplos arquivos.

### Justificativa da decisão

- Facilita versionamento no repositório
- Evita duplicação de modelo semântico
- Garante consistência de métricas entre visões executiva e operacional
- Navegação por páginas resolve a separação de contextos sem custo técnico adicional

---

## 🧭 Navegação

### Menu lateral (fixo)

Presente em todas as páginas, permitindo alternância entre:

- Home (capa do dashboard)
- Dashboard Executivo — Orçado vs Realizado
- Dashboard Executivo — Comparações Temporais
- Dashboard Operacional — Acompanhamento Intra-mês

### Menu superior (contextual)

- Páginas executivas: slicers de **período**, **centro de custo** e **categoria**
- Página operacional: slicers de **centro de custo** e **categoria**

---

## 📈 Dashboard Executivo — Visão Mensal

### Página 1 — Orçado vs Realizado

**Objetivo**: Avaliar desempenho orçamentário em visão consolidada.

**Perguntas de negócio que esta página responde:**
1. O gasto total do ano está dentro do planejamento orçamentário?
2. Quais meses apresentaram maior desvio em relação ao orçado?
3. Quais Centros de Custo e Categorias são os principais responsáveis pelos estouros de orçamento?

**Visual central**:
- Gráfico de linha com **Orçado vs Realizado** ao longo do ano

**KPIs (cards)**:
- Total Orçado
- Total Realizado
- Desvio (R$)
- Desvio (%)

**Padrão dos cards**:
- Valor principal (big number): contexto filtrado
- Valor secundário: consolidado do ano inteiro

**Visuais de apoio**:
- Maiores desvios por **centro de custo**
- Maiores desvios por **categoria**

---

### Página 2 — Comparações Temporais

**Objetivo**: Analisar crescimento e variação de gastos ao longo do tempo.

**Perguntas de negócio que esta página responde:**
1. O gasto atual é maior ou menor do que o gasto no mesmo período do ano passado?
2. Qual é a tendência de crescimento dos gastos mês a mês?
3. Quais áreas tiveram o maior aumento de custo em relação ao ano anterior?

**Visual central**:
- Gráfico de colunas ou linhas comparando **ano atual vs ano anterior**

**KPIs (cards)**:
- Crescimento MoM (R$)
- Crescimento MoM (%)
- Crescimento YoY (R$)
- Crescimento YoY (%)

**Visuais de apoio**:
- Centros de custo com maior crescimento
- Categorias com maior crescimento

---

## 🛠️ Dashboard Operacional — Acompanhamento Intra-mês

**Objetivo**: Permitir **monitoramento diário do consumo do orçamento do mês corrente**, antecipando riscos de estouro.

**Perguntas de negócio que esta página responde:**
1. No ritmo de hoje, vamos terminar o mês acima ou abaixo do orçamento?
2. O gasto acumulado até agora é condizente com o comportamento histórico (mediana) deste Centro de Custo?
3. Quais categorias já consumiram mais de 80% do orçamento antes do fim do mês?
---

### Visual Central — Consumo Acumulado do Mês

Gráfico de linha contendo **três referências simultâneas**:

1. **Realizado acumulado até o dia atual**
2. **Orçado ideal acumulado do mês** (distribuição linear do orçamento mensal)
3. **Linha de referência histórica** baseada na **mediana** do consumo dos meses anteriores, proporcionalizada pelos dias decorridos

---

### 📌 Decisão Analítica: Uso de Mediana (e não Média)

A referência histórica intra-mês utiliza **mediana**, e não média.

**Justificativa**:
- A base possui **outliers relevantes** (meses atípicos já identificados na Silver e sinalizados na Gold)
- A média é sensível a valores extremos e distorceria o padrão esperado
- A mediana representa melhor o **comportamento típico de consumo**

Essa decisão garante que o comparativo intra-mês seja:
- Mais estável
- Mais realista
- Mais confiável como sinal de alerta

---

### KPIs Operacionais (cards)

- Orçamento total do mês
- Realizado até o dia atual
- % do orçamento consumido
- % do mês decorrido

---

### Matriz de Risco Orçamentário

Tabela/matriz destacando **centros de custo e categorias** com risco de estouro.

**Classificação definida**:

- < 80% do orçamento: **Baixo risco**
- 80% – 100%: **Atenção**
- > 100%: **Estouro de orçamento**

O objetivo é permitir **ação preventiva**, não apenas diagnóstico tardio.

---

## 🔗 Integração com a Camada Gold

Os dashboards consomem exclusivamente:

- `vw_gold_orcamento`
- `vw_gold_realizado`
- `vw_gold_lancamentos` 

**Princípios respeitados**:
- Métricas complexas permanecem no SQL
- Power BI foca em relacionamento, contexto e visualização
- Cruzamento Orçado vs Realizado ocorre no BI, conforme decisão arquitetural da Gold


---

## 📖 Próximos Passos

- Implementação do modelo semântico no Power BI
- Criação das medidas DAX necessárias
- Validação das métricas com cenários reais
- Documentação de decisões visuais e técnicas adicionais
