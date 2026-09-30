import os
import re
import matplotlib.pyplot as plt
import numpy as np

# Parametri dello sweep
SIZES = [131072] # Forzato a 131K per stress test massimo
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
    0: '#d62728',  # Rosso per Strict
    1: '#1f77b4',  # Blu per Baseline
    2: '#2ca02c'   # Verde per Tectree-Opt
}

# Struttura dati: data[arity][policy] = ticks (fissando size a 131K)
data = {a: {p: 0 for p in POLICIES} for a in ARITIES}

print("Analisi in corso. Estrazione Ticks della ROI per Array 131K...")

for arity in ARITIES:
    for policy in POLICIES:
        folder_name = f"stats_{PROTOCOL}_Policy{policy}_131072_Arity{arity}"
        stats_file = os.path.join(RESULTS_DIR, folder_name, "stats.txt")
        
        roi_ticks = 0
        
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
                                for b_line in block_lines:
                                    if "simTicks" in b_line:
                                        roi_ticks = int(re.findall(r'\d+', b_line)[0])
                                        break
                                break 
                        else:
                            block_lines.append(line)
            except Exception as e:
                pass
        
        data[arity][policy] = roi_ticks
        if roi_ticks > 0:
            print(f"[{folder_name}] -> ROI Ticks: {roi_ticks}")
        else:
            print(f"[{folder_name}] -> Dati mancanti o Simulazione Incompleta")

# Generazione Grafico Singolo
fig, ax = plt.subplots(figsize=(10, 6))
fig.suptitle("Impatto Prestazionale delle Policy MRU (Array Size = 131K)", fontsize=16, fontweight='bold', y=0.98)

x = np.arange(len(ARITIES))
width = 0.25

ticks_p0 = [data[a][0] for a in ARITIES]
ticks_p1 = [data[a][1] for a in ARITIES]
ticks_p2 = [data[a][2] for a in ARITIES]

# Plot delle tre barre raggruppate per ogni Arity (Verticali)
rects1 = ax.bar(x - width, ticks_p0, width, label=POLICY_LABELS[0], color=COLORS[0], edgecolor='black')
rects2 = ax.bar(x,         ticks_p1, width, label=POLICY_LABELS[1], color=COLORS[1], edgecolor='black')
rects3 = ax.bar(x + width, ticks_p2, width, label=POLICY_LABELS[2], color=COLORS[2], edgecolor='black')

# Zoom dinamico dell'asse Y per enfatizzare le differenze
all_ticks = ticks_p0 + ticks_p1 + ticks_p2
min_ticks = min(all_ticks)
max_ticks = max(all_ticks)
tick_range = max_ticks - min_ticks
if tick_range > 0:
    # Lasciamo molto spazio in alto per far entrare il testo ruotato senza sbavature
    ax.set_ylim(min_ticks - tick_range * 0.5, max_ticks + tick_range * 2.0)
else:
    ax.set_ylim(min_ticks * 0.99, max_ticks * 1.05)

# Funzione per aggiungere il tempo di esecuzione in simTicks
def autolabel(rects):
    for rect in rects:
        height = rect.get_height()
        text = f"{int(height)}"
            
        ax.annotate(text,
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 5),  # 5 punti offset verticale verso l'alto
                    textcoords="offset points",
                    ha='center', va='bottom', fontsize=9, fontweight='bold', rotation=45)

autolabel(rects1)
autolabel(rects2)
autolabel(rects3)

ax.set_xlabel("Fattore di Ramificazione (Arity dell'Albero)", fontsize=12)
ax.set_ylabel("Tempo di Esecuzione della ROI (simTicks)", fontsize=12)
ax.set_xticks(x)
ax.set_xticklabels([f"Arity {a}" for a in ARITIES], fontsize=12)

ax.grid(axis='y', linestyle='--', alpha=0.7)
ax.legend(loc='upper right', fontsize=11, frameon=True, edgecolor='black')

plt.tight_layout()
plt.subplots_adjust(top=0.9) # Lascia un po' di respiro al titolo
output_filename = "Confronto_Policy_Arity_131K.png"
plt.savefig(output_filename, dpi=300, bbox_inches='tight')
print(f"\n[SUCCESSO] Grafico salvato come '{output_filename}' nella cartella corrente!")
