import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

seed = 42
random.seed(seed)
np.random.seed(seed)

centros_custo = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

categorias_por_cc = {
    1: list(range(101, 106)), 2: list(range(106, 111)), 3: list(range(111, 116)),
    4: list(range(116, 121)), 5: list(range(121, 126)), 6: list(range(126, 131)),
    7: list(range(131, 136)), 8: list(range(136, 141)), 9: list(range(141, 146)),
    10: list(range(146, 151))
}

valores_por_categoria = {
    101: (500, 2000), 102: (8000, 12000), 103: (2000, 3500), 104: (50, 800), 105: (1500, 4500),
    106: (300, 1800), 107: (1500, 12000), 108: (2500, 25000), 109: (800, 4500), 110: (200, 2500),
    111: (600, 8000), 112: (2500, 15000), 113: (100, 1200), 114: (1500, 9000), 115: (50, 500),
    116: (300, 4000), 117: (1500, 8000), 118: (800, 3500), 119: (1000, 6000), 120: (1000, 5000),
    121: (600, 2500), 122: (400, 2800), 123: (800, 4500), 124: (300, 1800), 125: (25000, 40000),
    126: (10, 350), 127: (4000, 7000), 128: (8000, 18000), 129: (2500, 9000), 130: (400, 2000),
    131: (1500, 12000), 132: (800, 3500), 133: (300, 2000), 134: (400, 2500), 135: (1500, 9000),
    136: (600, 3500), 137: (1500, 6500), 138: (1000, 5000), 139: (400, 2200), 140: (300, 2000),
    141: (2500, 4000), 142: (4500, 7000), 143: (800, 3500), 144: (350, 1000), 145: (600, 2200),
    146: (5000, 25000), 147: (2500, 12000), 148: (4000, 20000), 149: (8000, 30000), 150: (1500, 10000)
}

categorias_recorrentes_fixas = {
    102: 10, 103: 12, 125: 5, 127: 8, 141: 15, 142: 15
}

categorias_recorrentes_variaveis = {
    116: (5, 10), 132: (8, 12)
}

# --- GERAÇÃO FACT_ORCAMENTO ---
orcamento_list = []
id_orc = 1

for ano in [2023, 2024]:
    for mes in range(1, 13):
        for cc in centros_custo:
            for cat in categorias_por_cc[cc]:
                min_val, max_val = valores_por_categoria[cat]
                valor_medio = (min_val + max_val) / 2
                
                if cat in categorias_recorrentes_fixas or cat in categorias_recorrentes_variaveis:
                    valor_orcado = valor_medio * random.uniform(1.0, 1.1)
                else:
                    valor_orcado = valor_medio * random.uniform(0.8, 1.3) * random.uniform(8, 12)
                
                if cc == 2 and mes in [5, 8, 11, 12]:
                    if cat in [107, 108, 109]:
                        valor_orcado *= 1.5
                
                if cc == 5 and cat == 125:
                    if mes in [11, 12]:
                        valor_orcado *= 1.5
                
                if random.random() < 0.005:
                    valor_orcado *= 20
                
                orcamento_list.append({
                    'id_orcamento': id_orc,
                    'ano': ano,
                    'mes': mes,
                    'id_centro_custo': cc,
                    'id_categoria': cat,
                    'valor_orcado': round(valor_orcado, 2)
                })
                id_orc += 1

df_orcamento = pd.DataFrame(orcamento_list)
df_orcamento = df_orcamento.drop(df_orcamento.sample(frac=0.02).index)

cat_recorrentes = list(categorias_recorrentes_fixas.keys())
df_recorrentes = df_orcamento[df_orcamento['id_categoria'].isin(cat_recorrentes)]
if len(df_recorrentes) >= 6:
    indices_outliers = df_recorrentes.sample(n=6).index
    for idx in indices_outliers:
        valor_atual = df_orcamento.at[idx, 'valor_orcado']
        df_orcamento.at[idx, 'valor_orcado'] = round(valor_atual * random.uniform(18, 22), 2)

# --- GERAÇÃO FACT_LANCAMENTOS ---
lancamentos_list = []
data_atual = datetime(2023, 1, 1)
data_fim = datetime(2024, 12, 31)
id_lan = 1
status_opcoes = ["Pago", "Paga", "Aberto", "Pending", "PAGO"]
lancamentos_recorrentes_mes = {}

indices_sujeira = {
    'cc_invalido': random.sample(range(1, 12000), 65),
    'valor_negativo': random.sample(range(1, 12000), 51),
    'data_nula': random.sample(range(1, 12000), 27)
}

contador_lancamentos = 0

while data_atual <= data_fim:
    if data_atual.day == 1:
        lancamentos_recorrentes_mes = {}
    
    for cat, dia_vencimento in categorias_recorrentes_fixas.items():
        if data_atual.day == dia_vencimento:
            chave = f"{data_atual.year}-{data_atual.month}-{cat}"
            if chave not in lancamentos_recorrentes_mes:
                cc = next(k for k, v in categorias_por_cc.items() if cat in v)
                min_val, max_val = valores_por_categoria[cat]
                valor = random.uniform(min_val, max_val)
                
                if cat == 125:
                    if data_atual.month == 11 and data_atual.day >= 25:
                        contador_lancamentos += 1
                        valor_13 = valor * 0.5
                        lancamentos_list.append({
                            'id_lancamento': id_lan,
                            'data_lancamento': data_atual.strftime('%Y-%m-%d') if contador_lancamentos not in indices_sujeira['data_nula'] else None,
                            'id_centro_custo': 999 if contador_lancamentos in indices_sujeira['cc_invalido'] else cc,
                            'id_categoria': cat,
                            'id_fornecedor': 6,
                            'id_campanha_marketing': None,
                            'valor_lancamento': round(valor_13 * (-1 if contador_lancamentos in indices_sujeira['valor_negativo'] else 1), 2),
                            'status_pagamento': "Pago"
                        })
                        id_lan += 1
                    
                    elif data_atual.month == 12 and data_atual.day >= 18 and data_atual.day <= 20:
                        contador_lancamentos += 1
                        valor_13 = valor * 0.5
                        lancamentos_list.append({
                            'id_lancamento': id_lan,
                            'data_lancamento': data_atual.strftime('%Y-%m-%d') if contador_lancamentos not in indices_sujeira['data_nula'] else None,
                            'id_centro_custo': 999 if contador_lancamentos in indices_sujeira['cc_invalido'] else cc,
                            'id_categoria': cat,
                            'id_fornecedor': 6,
                            'id_campanha_marketing': None,
                            'valor_lancamento': round(valor_13 * (-1 if contador_lancamentos in indices_sujeira['valor_negativo'] else 1), 2),
                            'status_pagamento': "Pago"
                        })
                        id_lan += 1
                
                contador_lancamentos += 1
                lancamentos_list.append({
                    'id_lancamento': id_lan,
                    'data_lancamento': data_atual.strftime('%Y-%m-%d') if contador_lancamentos not in indices_sujeira['data_nula'] else None,
                    'id_centro_custo': 999 if contador_lancamentos in indices_sujeira['cc_invalido'] else cc,
                    'id_categoria': cat,
                    'id_fornecedor': random.randint(1, 20),
                    'id_campanha_marketing': None,
                    'valor_lancamento': round(valor * (-1 if contador_lancamentos in indices_sujeira['valor_negativo'] else 1), 2),
                    'status_pagamento': "Pago"
                })
                id_lan += 1
                lancamentos_recorrentes_mes[chave] = True
    
    for cat, (dia_min, dia_max) in categorias_recorrentes_variaveis.items():
        if dia_min <= data_atual.day <= dia_max:
            chave = f"{data_atual.year}-{data_atual.month}-{cat}"
            if chave not in lancamentos_recorrentes_mes and random.random() < 0.3:
                cc = next(k for k, v in categorias_por_cc.items() if cat in v)
                min_val, max_val = valores_por_categoria[cat]
                valor = random.uniform(min_val, max_val)
                
                contador_lancamentos += 1
                lancamentos_list.append({
                    'id_lancamento': id_lan,
                    'data_lancamento': data_atual.strftime('%Y-%m-%d') if contador_lancamentos not in indices_sujeira['data_nula'] else None,
                    'id_centro_custo': 999 if contador_lancamentos in indices_sujeira['cc_invalido'] else cc,
                    'id_categoria': cat,
                    'id_fornecedor': random.randint(1, 20),
                    'id_campanha_marketing': None,
                    'valor_lancamento': round(valor * (-1 if contador_lancamentos in indices_sujeira['valor_negativo'] else 1), 2),
                    'status_pagamento': "Pago"
                })
                id_lan += 1
                lancamentos_recorrentes_mes[chave] = True
    
    if data_atual.weekday() < 5:
        num_lancamentos = random.randint(16, 24)
    else:
        num_lancamentos = random.randint(3, 8)
    
    for _ in range(num_lancamentos):
        cc = random.choice(centros_custo)
        cat = random.choice(categorias_por_cc[cc])
        min_val, max_val = valores_por_categoria[cat]
        valor = random.uniform(min_val, max_val)
        
        campanha = None
        if cc == 2:
            if data_atual.month == 5:
                campanha = 1
                if cat in [107, 108]:
                    valor *= random.uniform(2.0, 3.5)
                elif cat == 109:
                    valor *= random.uniform(1.3, 1.8)
            elif data_atual.month == 4 and cat in [108, 109]:
                valor *= random.uniform(1.2, 1.5)
            elif data_atual.month == 8:
                campanha = 2
                if cat in [107, 108]:
                    valor *= random.uniform(2.0, 3.2)
                elif cat == 109:
                    valor *= random.uniform(1.3, 1.7)
            elif data_atual.month == 7 and cat in [108, 109]:
                valor *= random.uniform(1.2, 1.5)
            elif data_atual.month == 11:
                campanha = 3
                if cat in [107, 108]:
                    valor *= random.uniform(2.5, 4.0)
                elif cat == 109:
                    valor *= random.uniform(1.5, 2.0)
                elif cat == 110:
                    valor *= random.uniform(1.3, 1.6)
            elif data_atual.month == 10 and cat in [107, 108, 109]:
                valor *= random.uniform(1.4, 1.8)
            elif data_atual.month == 9 and cat == 109:
                valor *= random.uniform(1.2, 1.4)
            elif data_atual.month == 12:
                campanha = 4
                if cat in [107, 108]:
                    valor *= random.uniform(2.2, 3.8)
                elif cat == 109:
                    valor *= random.uniform(1.4, 1.9)
        
        if data_atual > datetime(2024, 11, 1):
            status = random.choice(status_opcoes)
        else:
            status = random.choice(["Pago", "Paga", "PAGO"])
        
        contador_lancamentos += 1
        lancamentos_list.append({
            'id_lancamento': id_lan,
            'data_lancamento': data_atual.strftime('%Y-%m-%d') if contador_lancamentos not in indices_sujeira['data_nula'] else None,
            'id_centro_custo': 999 if contador_lancamentos in indices_sujeira['cc_invalido'] else cc,
            'id_categoria': cat,
            'id_fornecedor': random.randint(1, 20),
            'id_campanha_marketing': campanha,
            'valor_lancamento': round(valor * (-1 if contador_lancamentos in indices_sujeira['valor_negativo'] else 1), 2),
            'status_pagamento': status
        })
        id_lan += 1
    
    data_atual += timedelta(days=1)

df_lancamentos = pd.DataFrame(lancamentos_list)

df_orcamento.to_csv('fact_orcamento.csv', index=False, encoding='utf-8-sig')
df_lancamentos.to_csv('fact_lancamentos.csv', index=False, encoding='utf-8-sig')

print(f"Sucesso! Gerados {len(df_lancamentos)} lançamentos e {len(df_orcamento)} linhas de orçamento.")
