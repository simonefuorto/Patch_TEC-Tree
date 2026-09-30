import os
import re
import matplotlib.pyplot as plt
import numpy as np

# Parametri dello sweep
SIZES = [131072] # Forzato a 131K
ARITIES = [15, 31, 63]
POLICIES = [0, 1, 2]
PROTOCOL = "TARDISTSO_TECTREE"
RESULTS_DIR = "../../gem5/results_radix"

POLICY_LABELS = {
    0: "Policy 0 (Strict)",
    1: "Policy 1 (Baseline)",
    2: "Policy 2 (Tectree-Opt)"
}

COLORS = {
    0: '#d62728',
    1: '#1f77b4',
    2: '#2ca02c'
}

data = {a: {p: 0 for p in POLICIES} for a in ARITIES}

print("Analisi in corso. Estrazione EVIZIONI TOTALI METADATI della ROI per Array 131K...")

for arity in ARITIES:
    for policy in POLICIES:
        folder_name = f"stats_{PROTOCOL}_Policy{policy}_131072_Arity{arity}"
        stats_file = os.path.join(RESULTS_DIR, folder_name, "stats.txt")
        
        tot_meta_evictions = 0
        
        if os.path.exists(stats_file):
            try:
                with open(stats_file, "r") as f:
                    block_lines = []
                    for line in f:
                        if "---------- Begin Simulation Statistics ----------" in line:
                            block_lines = []
                        elif "---------- End Simulation Statistics   ----------" in line:
                            is_roi = any("numSyscalls" in b and re.search(r'\b0\b', b) for b in block_lines)
                            has_insts = any("simInsts" in b and not " 0 " in b for b in block_lines)
                            
                            if is_roi or has_insts:
                                # Contatori per le evizioni dei metadati (C_V = Clean, C_M = Dirty)
                                evict_cm_dirty = 0
                                evict_cm_auth = 0
                                evict_cv_clean = 0
                                
                                for b_line in block_lines:
                                    if "system.ruby.Directory_Controller.C_M.LLC_Repl_Dirty " in b_line:
                                        evict_cm_dirty = int(re.findall(r'\d+', b_line)[0])
                                    elif "system.ruby.Directory_Controller.C_M.LLC_Repl_Dirty_Auth_Miss " in b_line:
                                        evict_cm_auth = int(re.findall(r'\d+', b_line)[0])
                                    elif "system.ruby.Directory_Controller.C_V.LLC_Repl_Clean " in b_line:
                                        evict_cv_clean = int(re.findall(r'\d+', b_line)[0])
                                        
                                tot_meta_evictions = evict_cm_dirty + evict_cm_auth + evict_cv_clean
                                break 
                        else:
                            block_lines.append(line)
            except Exception as e:
                pass
        
        data[arity][policy] = tot_meta_evictions
        if tot_meta_evictions >= 0:
            print(f"[{folder_name}] -> Evizioni Totali Metadati: {tot_meta_evictions}")
        else:
            print(f"[{folder_name}] -> Dati mancanti")

# Generazione Grafico Singolo
fig, ax = plt.subplots(figsize=(10, 6))
fig.suptitle("Evizioni Totali dei Metadati Dalla LLC - Array Size = 131K", fontsize=16, fontweight='bold', y=0.98)

x = np.arange(len(ARITIES))
width = 0.25

evictions_p0 = [data[a][0] for a in ARITIES]
evictions_p1 = [data[a][1] for a in ARITIES]
evictions_p2 = [data[a][2] for a in ARITIES]

rects1 = ax.bar(x - width, evictions_p0, width, label=POLICY_LABELS[0], color=COLORS[0], edgecolor='black')
rects2 = ax.bar(x,         evictions_p1, width, label=POLICY_LABELS[1], color=COLORS[1], edgecolor='black')
rects3 = ax.bar(x + width, evictions_p2, width, label=POLICY_LABELS[2], color=COLORS[2], edgecolor='black')

ax.set_xlabel("Fattore di Ramificazione (Arity dell'Albero)", fontsize=12)
ax.set_ylabel("Numero Totale Evizioni Metadati", fontsize=12)
ax.set_xticks(x)
ax.set_xticklabels([f"Arity {a}" for a in ARITIES], fontsize=12)


ax.grid(axis='y', linestyle='--', alpha=0.7)

# --- ZOOM DELL'ASSE Y ---
all_vals = evictions_p0 + evictions_p1 + evictions_p2
valid_vals = [v for v in all_vals if v > 0]
if valid_vals:
    min_val = min(valid_vals)
    max_val = max(valid_vals)
    margin = (max_val - min_val) * 0.8
    if margin == 0: margin = max_val * 0.1
    ax.set_ylim(bottom=max(0, min_val - margin), top=max_val + margin)
# ------------------------

ax.legend(loc='upper right', fontsize=11, frameon=True, edgecolor='black')

def autolabel(rects):
    for rect in rects:
        height = rect.get_height()
        ax.annotate(f"{int(height)}",
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),
                    textcoords="offset points",
                    ha='center', va='bottom', fontsize=10, fontweight='bold')

autolabel(rects1)
autolabel(rects2)
autolabel(rects3)

plt.tight_layout()
plt.subplots_adjust(top=0.9)
output_filename = "Grafico_Evizioni_TOTALI_Metadati_131K.png"
plt.savefig(output_filename, dpi=300, bbox_inches='tight')
print(f"\n[SUCCESSO] Grafico salvato come '{output_filename}' nella cartella corrente!")
