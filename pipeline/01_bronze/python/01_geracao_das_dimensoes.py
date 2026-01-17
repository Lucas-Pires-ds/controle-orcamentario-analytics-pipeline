import pandas as pd

# 1. Dimensão: Centro de Custo
# Aplicando sujeiras como espaços extras e variações de Case
data_cc = {
    'id_centro_custo': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'nome_centro_custo': [
        "Administrativo", " Marketing", "Jurídico", "TI", "RH ", 
        "FINANCEIRO", "Comercial/Vendas", "Operações", "  Facilities", "Projetos Especiais"
    ]
}
df_cc = pd.DataFrame(data_cc)

# 2. Dimensão: Categorias (Contas)
# Relacionada ao id_centro_custo
categorias_raw = [
    (1, "Manutenção predial"), (1, "Aluguel/Condomínio"), (1, "Energia/Água/Utilidades"), (1, "Materiais de escritório"), (1, "Serviços administrativos terceirizados"),
    (2, "Endomarketing"), (2, "Campanhas sazonais"), (2, "Propaganda e publicidade"), (2, "Produção de conteúdo"), (2, "Ferramentas digitais"),
    (3, "Despesas processuais"), (3, "Honorários advocatícios"), (3, "Licenças e registros legais"), (3, "Consultoria jurídica"), (3, "Custas cartoriais"),
    (4, "Licenças de software"), (4, "Infraestrutura/Servidores"), (4, "Suporte técnico"), (4, "Equipamentos de TI"), (4, "Segurança da informação"),
    (5, "Benefícios"), (5, "Treinamento"), (5, "Recrutamento e seleção"), (5, "Eventos internos"), (5, "Folha de pagamento"),
    (6, "Tarifas bancárias"), (6, "Serviços contábeis"), (6, "Auditoria externa"), (6, "Sistemas/ERP"), (6, "Meios de pagamento"),
    (7, "Comissões"), (7, "Ferramentas de CRM"), (7, "Despesas de prospecção"), (7, "Viagens comerciais"), (7, "Eventos/Feiras"),
    (8, "Insumos operacionais"), (8, "Serviços terceirizados"), (8, "Logística/Transporte"), (8, "Manutenção operacional"), (8, "Custos variáveis"),
    (9, "Limpeza/Conservação"), (9, "Segurança patrimonial"), (9, "Manutenção preventiva"), (9, "Jardinagem"), (9, "Gestão de contratos"),
    (10, "Projetos estratégicos"), (10, "Consultorias pontuais"), (10, "Implementação de sistemas"), (10, "Reestruturações internas"), (10, "Despesas extraordinárias")
]

df_cat = pd.DataFrame(categorias_raw, columns=['id_centro_custo', 'nome_categoria'])
df_cat.insert(0, 'id_categoria', range(101, 101 + len(df_cat)))
# Sujeira proposital em algumas categorias
df_cat.loc[101, 'nome_categoria'] = "ALUGUEL/CONDOMÍNIO" # Upper case

# 3. Dimensão: Fornecedores
fornecedores_list = [
    "Alpha Serviços", "Beta TI", "Gamma Consultoria", "Delta Publicidade", "Épsilon Advocacia",
    "Zeta RH", "Eta Transportes", "Theta Logística", "Iota Energia", "Kappa Materiais",
    "Lambda Equipamentos", "Mu Limpeza", "Nu Eventos", "Xi Segurança", "Omicron Marketing Digital",
    "Pi Tecnologia", "Rho Auditoria", "Sigma Alimentos", "Tau Design", "Upsilon Serviços Gerais"
]
df_forn = pd.DataFrame({
    'id_fornecedor': range(1, 21),
    'nome_fornecedor': fornecedores_list
})

# 4. Dimensão: Campanhas de Marketing
df_camp = pd.DataFrame({
    'id_campanha': [1, 2, 3, 4],
    'nome_campanha': ["Dia das Mães", "Dia dos Pais", "Black Friday", "Natal / Fim de Ano"],
    'mes_referencia': [5, 8, 11, 12]
})

# Exportação
df_cc.to_csv('dim_centro_custo.csv', index=False, encoding='utf-8-sig')
df_cat.to_csv('dim_categoria.csv', index=False, encoding='utf-8-sig')
df_forn.to_csv('dim_fornecedores.csv', index=False, encoding='utf-8-sig')
df_camp.to_csv('dim_campanha_marketing.csv', index=False, encoding='utf-8-sig')

print("Tabelas dimensionais geradas com sucesso!")