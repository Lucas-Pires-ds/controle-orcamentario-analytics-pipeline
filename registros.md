# Diário de Desenvolvimento - Projeto BI Financeiro

## [28/12/2025] Início do Projeto e Ingestão de Dados
### O que foi feito:
- Definição do escopo: Controle Orçamentário e Lançamentos.
- Geração de dados sintéticos (5000+ linhas) usando Python para simular cenários reais com sazonalidade e erros.
- Configuração do ambiente SQL Server no VS Code.
- Criação do banco de dados `Financeiro_BI`.
- Implementação da Camada de Staging (`stg_`) para garantir a integridade da importação.

### Decisões técnicas:
**- Realismo de Dados:**
Fiz um script python para gerar uma base de dados o mais próximo da realidade possível, para isso apliquei:
- Regras de sazonalidade como: campanhas de marketing condizentes com o calendário real, gastos com folha aumentados em epoca de 13° salario, centros de custos que gastam mais em determinada epoca do ano, etc.
- Erros propositais nos dados como espaços extras desnecessários, dados faltantes, chaves estrangeiras que não batem com chaves primárias, etc.

**- Arquiterura:**
Arquitetura: Optei pelo padrão de camadas (Staging e Trusted) para garantir que o processo de ETL seja rastreável e que erros de importação não interrompam o fluxo de carga.



