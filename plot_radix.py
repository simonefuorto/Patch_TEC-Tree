import os
import re
import matplotlib.pyplot as plt
import numpy as np

# Configurazione
SIZES = [16384, 65536, 131072]
POLICIES = [0, 1, 2]
RESULTS_DIR = "../gem5/results_radix"

# Strutture dati per raccogliere i risultati
# policy_data[metric][size] = [val_policy0, val_policy1, val_policy2]
metrics = ['performance', 'metadata', 'root_updates']
data = {m: {s: [0, 0, 0] for s in SIZES} for m in metrics}

print("Analizzo i risultati per le 3 Policy e le 3 Dimensioni...\n")

for size in SIZES:
    for policy in POLICIES:
        stats_file = os.path.join(RESULTS_DIR, f"stats_TARDISTSO_TECTREE_Policy{policy}_{size}", "stats.txt")
        
        roi_ticks = 0
        meta_dirty = 0
        root_updates = 0
        
        if not os.path.exists(stats_file):
            print(f"[ATTENZIONE] File mancante per Policy {policy} Size {size}: {stats_file}")
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
                                if "simTicks" in b_line and "system" not in b_line:
                                    roi_ticks = int(re.findall(r'\d+', b_line)[-1])
                                elif "m_prefetch_misses" in b_line:
                                    meta_dirty = int(re.findall(r'\d+', b_line)[-1])
                                elif "dir_cntrl0.LLC.m_demand_hits" in b_line:
                                    root_updates = int(re.findall(r'\d+', b_line)[-1])
                            break 
                    else:
                        block_lines.append(line)
        except Exception as e:
            print(f"Errore lettura {stats_file}: {e}")
            
        data['performance'][size][policy] = roi_ticks
        data['metadata'][size][policy] = meta_dirty
        data['root_updates'][size][policy] = root_updates

print("Dati estratti con successo! Generazione dei grafici in corso...")

# ----------------- FUNZIONE DI PLOTTING -----------------
def plot_grouped_bar(metric_key, title, ylabel, filename, log_scale=False):
    fig, ax = plt.subplots(figsize=(10, 6))
    
    x = np.arange(len(SIZES))
    width = 0.25  # Larghezza delle barre
    
    # Estraiamo i valori per ogni policy
    p0_vals = [data[metric_key][s][0] for s in SIZES]
    p1_vals = [data[metric_key][s][1] for s in SIZES]
    p2_vals = [data[metric_key][s][2] for s in SIZES]
    
    rects1 = ax.bar(x - width, p0_vals, width, label='Policy 0 (Strict MRU)', color='#ff9999')
    rects2 = ax.bar(x, p1_vals, width, label='Policy 1 (Standard)', color='#66b3ff')
    rects3 = ax.bar(x + width, p2_vals, width, label='Policy 2 (Tectree Optimized)', color='#99ff99')
    
    ax.set_xlabel('Dimensione Array')
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.set_xticks(x)
    ax.set_xticklabels([str(s) for s in SIZES])
    ax.legend()
    
    if log_scale:
        ax.set_yscale('log')
        
    ax.grid(axis='y', linestyle='--', alpha=0.7)
    
    fig.tight_layout()
    plt.savefig(filename, dpi=300)
    plt.close()
    print(f"Salvato grafico: {filename}")

# Creazione cartella per i grafici se non esiste
os.makedirs("thesis_graphs", exist_ok=True)

# Generazione dei 3 grafici
plot_grouped_bar('performance', 'Performance (ROI Ticks) al variare della Policy', 'Ticks (Più basso è meglio)', 'thesis_graphs/1_Performance.png')
plot_grouped_bar('metadata', 'Sfratti dei Metadati Dalla LLC (Dirty Miss)', 'Numero di Sfratti (Più basso è meglio)', 'thesis_graphs/2_Metadata_Evictions.png')
plot_grouped_bar('root_updates', 'Root Updates (Scritture Dati In RAM)', 'Numero di Root Updates', 'thesis_graphs/3_Root_Updates.png')

print("\nTutti i grafici sono stati creati con successo nella cartella 'patch_tectree/thesis_graphs/'!")
