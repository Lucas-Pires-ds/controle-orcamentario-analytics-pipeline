import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# --- 1. CONFIGURAÇÕES E DICIONÁRIOS ---
seed = 42
random.seed(seed)
np.random.seed(seed)

centros_custo = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# Mapeamento de Categorias conforme gerado no script anterior (ID 101 a 150)
categorias_por_cc = {
    1: list(range(101, 106)), 2: list(range(106, 111)), 3: list(range(111, 116)),
    4: list(range(116, 121)), 5: list(range(121, 126)), 6: list(range(126, 131)),
    7: list(range(131, 136)), 8: list(range(136, 141)), 9: list(range(141, 146)),
    10: list(range(146, 151))
}

# --- 2. GERAÇÃO DA FATO ORÇAMENTO (Mensal) ---
orcamento_list = []
id_orc = 1
for ano in [2023, 2024]:
    for mes in range(1, 13):
        for cc in centros_custo:
            for cat in categorias_por_cc[cc]:
                # Valor base varia por Centro de Custo
                valor_base = 50000 if cc == 5 else 8000 # RH (Folha) é maior
                if cc == 2: valor_base = 15000 # Marketing
                
                # Erro proposital: valor absurdo em 0.5% dos casos
                if random.random() < 0.005:
                    valor_base *= 20
                
                orcamento_list.append({
                    'id_orcamento': id_orc,
                    'ano': ano,
                    'mes': mes,
                    'id_centro_custo': cc,
                    'id_categoria': cat,
                    'valor_orcado': round(valor_base * random.uniform(0.85, 1.15), 2)
                })
                id_orc += 1

df_orcamento = pd.DataFrame(orcamento_list)
# Inconsistência: Remover alguns meses de orçamento para testar JOINS
df_orcamento = df_orcamento.drop(df_orcamento.sample(frac=0.02).index)

# --- 3. GERAÇÃO DA FATO LANÇAMENTOS (Diária) ---
lancamentos_list = []
data_atual = datetime(2023, 1, 1)
data_fim = datetime(2024, 12, 31)
id_lan = 1

status_opcoes = ["Pago", "Paga", "Aberto", "Pending", "PAGO"]

while data_atual <= data_fim:
    # Volume diário: mais lançamentos em dias de semana
    num_lancamentos = random.randint(5, 12) if data_atual.weekday() < 5 else random.randint(1, 4)
    
    for _ in range(num_lancamentos):
        cc = random.choice(centros_custo)
        cat = random.choice(categorias_por_cc[cc])
        
        # Lógica de Valor com Sazonalidade
        valor = random.uniform(200, 4000)
        if cc == 2 and data_atual.month in [5, 8, 11, 12]: # Sazonalidade Marketing
            valor *= random.uniform(2, 4)
        if cc == 5 and data_atual.month == 12: # 13º Salário
            valor *= 1.8

        # Regra de Status de Pagamento (Apenas últimos 2 meses podem estar abertos)
        if data_atual > datetime(2024, 11, 1):
            status = random.choice(status_opcoes)
        else:
            status = random.choice(["Pago", "Paga", "PAGO"])

        # Inserção de "Sujeira" para ETL
        id_cc_final = cc
        if random.random() < 0.01: id_cc_final = 999 # ID Inexistente
        if random.random() < 0.01: valor = valor * -1 # Valor Negativo
        
        campanha = None
        if cc == 2:
            if data_atual.month == 5: campanha = 1
            elif data_atual.month == 8: campanha = 2
            elif data_atual.month == 11: campanha = 3
            elif data_atual.month == 12: campanha = 4

        lancamentos_list.append({
            'id_lancamento': id_lan,
            'data_lancamento': data_atual.strftime('%Y-%m-%d') if random.random() > 0.005 else None,
            'id_centro_custo': id_cc_final,
            'id_categoria': cat,
            'id_fornecedor': random.randint(1, 20),
            'id_campanha_marketing': campanha,
            'valor_lancamento': round(valor, 2),
            'status_pagamento': status
        })
        id_lan += 1
    data_atual += timedelta(days=1)

df_lancamentos = pd.DataFrame(lancamentos_list)

# --- 4. EXPORTAÇÃO ---
df_orcamento.to_csv('fact_orcamento.csv', index=False, encoding='utf-8-sig')
df_lancamentos.to_csv('fact_lancamentos.csv', index=False, encoding='utf-8-sig')

print(f"Sucesso! Gerados {len(df_lancamentos)} lançamentos e {len(df_orcamento)} linhas de orçamento.")