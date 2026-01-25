# Dashboard — Visualização e Analytics

## Responsabilidade

A camada de Dashboard é responsável por **consumir as views Gold e transformar dados analíticos em visualizações acionáveis** para tomada de decisão estratégica e operacional.

**Objetivo**: Entregar análise executiva do desempenho orçamentário e acompanhamento operacional preventivo do mês corrente, com sistema de alertas e priorização de ações.

---

## 🎯 Características

- Consumo direto das views Gold sem transformações adicionais
- Separação clara entre visões executiva (retrospectiva) e operacional (preventiva)
- Sistema de alertas baseado em benchmark estatístico (mediana histórica)
- Navegação intuitiva entre contextos analíticos
- Arquitetura push-down: cálculos complexos resolvidos no SQL, BI foca em visualização e contexto

---

## 📂 Estrutura de Arquivos
```
dashboard/
├── README.md (este arquivo)
└── controle_orcamentario.pbix
```

---

## 🏗️ Arquitetura do Dashboard

### Decisão: Arquivo Único com Múltiplas Páginas

Estrutura adotada: **um único arquivo PBIX** com navegação interna entre páginas.

**Justificativa:**
- Facilita versionamento (um único arquivo no controle de versão)
- Evita duplicação do modelo semântico
- Garante consistência de métricas entre visões
- Navegação por páginas resolve separação de contextos sem fragmentação técnica
- Permite evolução incremental do dashboard mantendo integridade

---

## 📊 Estrutura de Páginas

### 1. Home
- Capa/menu de navegação
- Orientação sobre o propósito de cada visão analítica
- Entrada intuitiva no relatório

### 2. Operacional — Leitura Rápida
- Monitoramento diário escaneável
- Identificação imediata de riscos
- Priorização de ações corretivas

### 3. Operacional — Detalhamento Controlado
- Investigação objetiva de lançamentos
- Validação e conferência de gastos
- Drill-down sem transformar o dashboard em ERP

### 4. Executivo — Orçado vs Realizado *(planejado)*
- Análise mensal consolidada
- Comparação planejado vs executado
- Identificação de desvios estruturais

### 5. Executivo — Comparações Temporais *(planejado)*
- Análise de crescimento (MoM, YoY)
- Tendências temporais
- Identificação de variações sazonais

---

## 🧭 Sistema de Navegação

### Sidebar Lateral (Fixa)

Implementação: barra lateral não retrátil com ícones e tooltips.

**Decisão consciente:** Evitar sidebar retrátil para:
- Reduzir complexidade técnica desnecessária
- Manter foco na entrega de valor analítico
- Equilibrar elegância com viabilidade no contexto do projeto

**Ícones semânticos:**
- 🏠 Home
- 📊 Operacional — Leitura Rápida
- 🔍 Operacional — Detalhamento
- 📈 Executivo — Orçado vs Realizado
- 📉 Executivo — Comparações Temporais

### Filtros Contextuais

**Páginas Operacionais:**
- Centro de custo
- Categoria
- Período: fixado no mês corrente (comportamento padrão)

**Páginas Executivas:**
- Período (ano/mês)
- Centro de custo
- Categoria

---

## 🛠️ Dashboard Operacional — Leitura Rápida

### Objetivo

Permitir que o usuário entenda, **em poucos segundos**:
- Se o orçamento está sob controle
- Se o ritmo de consumo está saudável
- Onde estão os principais riscos

**Natureza do dashboard:** Preventivo, não reativo. Atua como radar de risco e instrumento de priorização de ação, não como espelho de lançamentos passados.

### Perguntas Respondidas
1. Estamos consumindo o orçamento mais rápido ou mais devagar que o esperado?
2. Quais centros de custo representam maior risco de estouro?
3. O ritmo atual está alinhado com o comportamento histórico da empresa?

### KPIs (Cards)

Leitura imediata dos números essenciais:

- **Total Orçado do Mês**: Planejamento financeiro total
- **Total Realizado até a Data Atual**: Consumo acumulado (MTD)
- **% do Orçamento Consumido**: Percentual de execução
- **% do Mês Decorrido**: Percentual temporal (referência)

**Interpretação:** A comparação entre consumo financeiro e passagem do tempo indica se o ritmo está saudável.

### Visual Principal — Consumo Acumulado

Gráfico de linha com três curvas simultâneas:

1. **Orçado Ideal Acumulado**: Distribuição linear do orçamento mensal (calculado em DAX)
2. **Realizado Acumulado (MTD)**: Gasto real até hoje
3. **Mediana Histórica Acumulada**: Linha de comportamento esperado do consumo ao longo do mês

**Interpretação:**
- Realizado acima do orçado ideal → Risco de estouro
- Realizado abaixo da mediana histórica → Ritmo inferior ao padrão
- Realizado entre mediana e orçado → Dentro do esperado

**Decisão arquitetural:** Mediana histórica calculada no SQL (camada Gold) por ser um benchmark estrutural do negócio que não depende de interação do usuário.

### Visuais de Apoio

#### 1. Matriz de Risco (Centro de Custo)

**Dimensão:** Centro de Custo

**Métricas:**
- % do orçamento consumido
- Status de risco (semáforo)
- Projeção de resultado final

**Semáforo de risco:**
- 🔴 Realizado > Orçado (estouro confirmado)
- 🟠 ≥ 80% do orçamento (atenção)
- 🟢 < 80% do orçamento (baixo risco)

**Decisão consciente:** Não detalhar por categoria nesta aba para manter leitura rápida. O objetivo é **identificar onde agir**, não investigar o porquê.

#### 2. Top 5 Centros de Custo com Maior Risco

Gráfico de barras horizontais ordenado por:
- Maior percentual de consumo OU
- Maior projeção de estouro

**Função:** Complementa a matriz, destacando prioridades e reduzindo esforço cognitivo do usuário.

### Sistema de Projeção

**Status de projeção:**
- "Tende a Estourar"
- "Dentro do Esperado"
- "Abaixo do Ritmo"

**Implementação:** Coluna adicional na matriz de risco e base para o ranking do Top 5.

**Decisão:** Projeção calculada em DAX (camada semântica) por depender diretamente do contexto de filtro e período selecionado pelo usuário.

---

## 🔍 Dashboard Operacional — Detalhamento Controlado

### Objetivo

Permitir **investigação objetiva** de lançamentos, sem transformar o dashboard em um sistema transacional ou substituto de ERP.

### Perguntas Respondidas
1. Quais foram os principais lançamentos do período?
2. Quanto ainda está pendente de pagamento?
3. Qual o resultado financeiro projetado para o fechamento do mês?

### KPIs (Cards)

Métricas mais analíticas para investigação:

- **Lançamentos Totais do Período**: Quantidade de transações
- **Total Realizado do Período**: Soma dos valores lançados
- **Desvio do Orçamento (R$)**: Diferença entre realizado e planejado
- **Total a Pagar (Pendentes)**: Lançamentos abertos
- **Previsão de Resultado Final**: Orçado mensal − (realizado pago + pendente)

### Visual Principal — Tabela de Lançamentos

**Campos:**
- Centro de custo
- Categoria
- Fornecedor
- Data
- Valor
- Status do pagamento

**Função:** Ponto final da análise, serve para validação e conferência, mas não incentiva microgestão excessiva.

### Bloco Lateral de Detalhamento

**Objetivo:** Remover excesso de colunas da tabela principal.

**Conteúdo:**
- Filtros adicionais
- Rankings pontuais
- Métricas auxiliares contextuais

---

## 📈 Dashboard Executivo — Orçado vs Realizado *(planejado)*

### Objetivo
Avaliar desempenho orçamentário mensal consolidado em perspectiva retrospectiva.

### Perguntas Respondidas
1. O gasto total está dentro do planejamento?
2. Quais meses apresentaram maior desvio?
3. Quais áreas são responsáveis pelos estouros?

### Visual Central
Gráfico de linha dupla: Orçado vs Realizado ao longo dos meses.

### KPIs (Cards)
- Total Orçado
- Total Realizado
- Desvio Absoluto (R$)
- Desvio Percentual (%)

**Padrão:** Valor principal (contexto filtrado) + valor secundário (ano completo).

### Visuais de Apoio
- Maiores desvios por centro de custo
- Maiores desvios por categoria

---

## 📉 Dashboard Executivo — Comparações Temporais *(planejado)*

### Objetivo
Analisar crescimento e variação de gastos ao longo do tempo.

### Perguntas Respondidas
1. O gasto atual é maior que o mesmo período do ano passado?
2. Qual a tendência de crescimento mês a mês?
3. Quais áreas tiveram maior aumento de custo?

### Visual Central
Gráfico de colunas agrupadas: ano atual vs ano anterior.

### KPIs (Cards)
- MoM Absoluto (R$)
- MoM Percentual (%)
- YoY Absoluto (R$)
- YoY Percentual (%)

### Visuais de Apoio
- Centros de custo com maior crescimento YoY
- Categorias com maior crescimento YoY

---

## 🚨 Sistema de Alertas Preventivos

### Fundamentação

O gasto acumulado até hoje (MTD) é comparado com a **mediana histórica acumulada** dos gastos até o mesmo dia em meses anteriores.

**Exemplo:** Se hoje é dia 15 e o gasto MTD já representa 120% da mediana histórica do dia 15, indica ritmo acima do padrão esperado.

### Semáforo de Risco

| Status | Condição | Interpretação |
|--------|----------|---------------|
| 🟢 Abaixo | MTD ≤ 80% da mediana | Ritmo inferior ao histórico |
| 🟡 Normal | MTD entre 81% e 100% | Ritmo alinhado ao esperado |
| 🔴 Acima | MTD > 100% | Ritmo superior — atenção necessária |

### Decisão Estatística: Mediana vs Média

**Escolha:** Mediana como métrica de referência histórica.

**Justificativa:**
- Base possui meses com gastos atípicos (outliers) já identificados nas camadas anteriores
- Média é sensível a valores extremos, distorce o padrão esperado
- Mediana é robusta contra outliers, representa comportamento típico
- **Resultado:** Alertas mais estáveis, confiáveis e acionáveis

### Implementação Técnica

**Cálculo da mediana histórica acumulada (SQL — Camada Gold):**
```sql
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Gasto_ate_dia) 
  OVER (PARTITION BY Dia_do_mes, id_centro_custo)
```

**Classificação do alerta (SQL — Camada Gold):**
```sql
CASE 
  WHEN Gasto_MTD / Mediana_MTD_CC <= 0.8  THEN 'Abaixo_do_normal'
  WHEN Gasto_MTD / Mediana_MTD_CC <= 1.0  THEN 'Dentro_do_normal'
  ELSE 'Acima_do_normal'
END
```

**Orçado ideal acumulado (DAX — Camada Semântica):**
```dax
Orçado Ideal Acumulado = 
VAR DiasNoMes = DAY(EOMONTH(MAX(dim_calendario[data]), 0))
VAR OrcamentoMensal = SUM(vw_gold_orcamento[Orcado_mensal])
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
RETURN DIVIDE(OrcamentoMensal, DiasNoMes) * DiaAtual
```

**Formatação condicional (DAX):**
```dax
Cor do Alerta = 
SWITCH(
    [Flag_alerta_gasto],
    "Abaixo_do_normal", "#10B981",
    "Dentro_do_normal", "#F59E0B",
    "Acima_do_normal", "#EF4444",
    "#9CA3AF"
)
```

---

## 🔗 Integração com a Camada Gold

### Arquitetura de Dados: Separação de Responsabilidades

#### SQL (Camada Gold)
**Responsável por:**
- Cálculos pesados e agregações complexas
- Métricas históricas (mediana, YTD, MoM, YoY)
- Benchmarks estruturais do negócio
- Tudo que não depende diretamente do contexto de filtro do usuário

#### Power BI (DAX — Camada Semântica)
**Responsável por:**
- Cálculos contextuais (dependem de filtros)
- Projeções dinâmicas (dependem do período selecionado)
- Métricas que variam com a interação do usuário
- Relacionamentos e cruzamentos entre tabelas Gold

### Views Consumidas

| View | Uso | Granularidade |
|------|-----|---------------|
| `vw_gold_orcamento` | Visão executiva de planejamento | Mensal |
| `vw_gold_lancamentos` | Visão operacional + alertas | Diária |

### Princípios de Integração

- ✅ Métricas estruturais calculadas no SQL (push-down computation)
- ✅ Power BI foca em relacionamentos, contexto e visualização
- ✅ Cruzamento Orçado vs Realizado realizado no BI via relacionamento
- ✅ Sem transformações adicionais no Power Query
- ✅ Modelo leve, performático e alinhado à filosofia de arquitetura em camadas

**Resultado:** Dashboards responsivos, métricas auditáveis e lógica rastreável até a camada de dados.

---

## 🎨 Design System e UI/UX

### Identidade Visual

**Estilo:** SaaS moderno, inspirado em dashboards corporativos maduros.

**Paleta de cores:**
- **Fundo:** #F3F4F8 (light mode)
- **Cards:** #FFFFFF
- **Bordas:** Cantos arredondados
- **Sombras:** Sutis, para sensação de profundidade

**Decisão:** Light mode como padrão para facilitar leitura em ambientes corporativos.

### Iconografia

**Princípio:** Ícones semânticos, coerentes e consistentes.

**Definições:**
- **Realizado / Pagos:** Check / Check-circle
- **Desvio do orçamento:** Setas divergentes
- **Total a pagar:** Relógio
- **Previsão:** Linha de tendência

**Regra geral:**
- Ícones neutros, mesma família visual
- Cor discreta (o número é o protagonista)
- Reforço semântico via tooltips

### Títulos Dinâmicos

**Implementação:** Títulos dos visuais feitos em DAX.

**Benefícios:**
- Contexto dinâmico (ex: "Consumo do Mês de Janeiro/2026")
- Clareza para o usuário
- Melhor storytelling analítico

---

## 🎯 Decisões de Design

### Coerência com a Camada Gold

O dashboard não recria lógica já resolvida na camada de dados. Métricas como YTD, MoM, YoY, mediana e flags de alerta vêm prontas da Gold, garantindo:
- ✅ Dashboards performáticos
- ✅ Métricas consistentes entre consumidores
- ✅ Lógica auditável no SQL
- ✅ Redução de complexidade no modelo semântico

### Separação de Contextos Analíticos

**Páginas Operacionais:**
- Monitoramento preventivo
- Métricas de acumulado diário (MTD)
- Alertas baseados em benchmark
- Foco: identificar onde agir

**Páginas Executivas:**
- Análise retrospectiva consolidada
- Métricas de fechamento mensal
- Comparações temporais fixas (MoM, YoY)
- Foco: entender o que aconteceu

### Princípio de Leitura Rápida

Cada página possui estrutura padronizada:
- **1 visual central:** Responde a pergunta-chave
- **4-5 KPIs:** Números essenciais para contexto
- **2-3 visuais de apoio:** Detalhamentos e rankings

**Decisão consciente:** Evitar excesso de formatação (bullets, headers, bold) nos visuais. Informação clara prevalece sobre elementos decorativos.

---

## 📌 Resultado Final

O dashboard entrega:

- ✅ Visão executiva consolidada de desempenho orçamentário
- ✅ Análise temporal de crescimento e variação (planejada)
- ✅ Monitoramento preventivo intra-mês com alertas estatisticamente confiáveis
- ✅ Identificação de áreas de risco antes do fechamento
- ✅ Rastreabilidade de decisões analíticas até a camada de dados
- ✅ Experiência de usuário otimizada para leitura rápida e investigação controlada

---

## 📖 Status e Próximos Passos

### Concluído
- [x] Arquitetura do dashboard definida
- [x] Estrutura de páginas planejada
- [x] Sistema de alertas especificado
- [x] Design system estabelecido
- [x] Mockups das abas operacionais finalizados

### Em Desenvolvimento
- [ ] Implementação do modelo semântico no Power BI
- [ ] Criação das medidas DAX necessárias
- [ ] Construção da Aba Operacional — Leitura Rápida
- [ ] Construção da Aba Operacional — Detalhamento Controlado

### Planejado
- [ ] Construção da Home (capa/navegação)
- [ ] Implementação das páginas executivas
- [ ] Validação das métricas com cenários reais
- [ ] Ajustes visuais baseados em testes de usabilidade
- [ ] Refatoração pós-entrega (limpeza, simplificação, organização)

---