import os
import re
import matplotlib.pyplot as plt
import csv

# Configurazione
L2_SIZES = ["64kB", "128kB", "256kB", "512kB", "1MB"]
POLICIES = [0, 1, 2]
RESULTS_DIR = "../gem5/results_l2_sweep"
WORKLOAD_NAME = "64MB Thrashing Benchmark (512B Stride)"

# data[policy][l2_size] = metadata_evictions
data = {p: {s: 0 for s in L2_SIZES} for p in POLICIES}

print(f"Analizzo i risultati del Thrashing per le 3 Policy ({WORKLOAD_NAME})...\n")

for policy in POLICIES:
    for size in L2_SIZES:
        stats_file = os.path.join(RESULTS_DIR, f"stats_Policy{policy}_{size}", "stats.txt")
        
        meta_dirty = 0
        
        if not os.path.exists(stats_file):
            print(f"[ATTENZIONE] File mancante per Policy {policy} L2_Size {size}: {stats_file}")
            continue

        try:
            with open(stats_file, "r") as f:
                block_lines = []
                for line in f:
                    if "---------- Begin Simulation Statistics ----------" in line:
                        block_lines = []
                    elif "---------- End Simulation Statistics   ----------" in line:
                        is_roi = any("numSyscalls" in b and " 0 " in b for b in block_lines)
                        if is_roi:
                            for b_line in block_lines:
                                if "m_prefetch_misses" in b_line:
                                    meta_dirty = int(re.findall(r'\d+', b_line)[-1])
                            break 
                    else:
                        block_lines.append(line)
        except Exception as e:
            print(f"Errore lettura {stats_file}: {e}")
            
        data[policy][size] = meta_dirty

print("Dati estratti con successo! Generazione del grafico e della tabella in corso...")

os.makedirs("thesis_graphs", exist_ok=True)

# ----------------- FUNZIONE DI PLOTTING (LINE GRAPH) -----------------
fig, ax = plt.subplots(figsize=(10, 6))

colors = {0: '#ff9999', 1: '#66b3ff', 2: '#99ff99'}
labels = {0: 'Policy 0 (Strict MRU)', 1: 'Policy 1 (Standard LRU)', 2: 'Policy 2 (Tectree Optimized)'}
markers = {0: 'o', 1: 's', 2: '^'}

for policy in POLICIES:
    y_vals = [data[policy][s] for s in L2_SIZES]
    ax.plot(L2_SIZES, y_vals, label=labels[policy], color=colors[policy], marker=markers[policy], linewidth=2, markersize=8)

ax.set_xlabel('Dimensione Cache L2 (Spazio Disponibile)')
ax.set_ylabel('Numero di Sfratti Metadati (Thrashing)')
ax.set_title(f'Impatto della Dimensione L2 sul Thrashing dei Metadati\n({WORKLOAD_NAME})')
ax.legend()
ax.grid(axis='y', linestyle='--', alpha=0.7)
ax.grid(axis='x', linestyle=':', alpha=0.5)

# Usa scala logaritmica se i valori divergono troppo (cosa probabile con 131k accessi distruttivi)
ax.set_yscale('log')

fig.tight_layout()
graph_filename = 'thesis_graphs/4_L2_Thrashing.png'
plt.savefig(graph_filename, dpi=300)
plt.close()
print(f"Salvato grafico: {graph_filename}")

# ----------------- STAMPA TABELLA NEL TERMINALE -----------------
print("\n" + "="*85)
print(f"{'L2 Size':<12} | {'Policy 0 (Strict MRU)':<22} | {'Policy 1 (Standard LRU)':<24} | {'Policy 2 (Tectree)':<18}")
print("-" * 85)
for size in L2_SIZES:
    print(f"{size:<12} | {data[0][size]:<22} | {data[1][size]:<24} | {data[2][size]:<18}")
print("="*85 + "\n")

# ----------------- SALVATAGGIO TABELLA CSV -----------------
csv_filename = 'thesis_graphs/4_L2_Thrashing_Table.csv'
with open(csv_filename, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['L2_Size', 'Policy_0_Strict_MRU', 'Policy_1_Standard', 'Policy_2_Tectree_Optimized'])
    
    for size in L2_SIZES:
        writer.writerow([size, data[0][size], data[1][size], data[2][size]])

print(f"Salvata tabella riassuntiva: {csv_filename}")
print("Tutto completato con successo!")
