import os
import argparse
import matplotlib.pyplot as plt
import numpy as np

# Parser per gli argomenti
parser = argparse.ArgumentParser(description='Genera grafico Sensitività Crypto Latency.')
parser.add_argument('-p', '--policy', type=int, default=0, help='La MRU Policy analizzata (es. 0, 1, 2)')
args = parser.parse_args()

policy = args.policy
base_dir = f"../../gem5/results_crypto_sweep_Pol{policy}"
latencies = [5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 100]

def extract_roi_ticks(file_path):
    values = []
    with open(file_path, 'r') as f:
        for line in f:
            if "simTicks" in line:
                parts = line.split()
                if len(parts) >= 2:
                    try:
                        values.append(int(float(parts[1])))
                    except ValueError:
                        pass
    # In radix (ROI), ci aspettiamo almeno 2 "simTicks", il secondo e' la ROI
    if len(values) >= 2:
        return values[1]
    elif len(values) == 1:
        return values[0]
    return 0

results = {}

for lat in latencies:
    folder = f"stats_crypto_{lat}"
    stat_file = os.path.join(base_dir, folder, "stats.txt")
    if os.path.exists(stat_file):
        ticks = extract_roi_ticks(stat_file)
        if ticks > 0:
            results[lat] = ticks

if not results:
    print(f"Nessun risultato trovato in {base_dir}")
    exit(1)

# Estrazione X e Y
x = list(results.keys())
y = list(results.values())
x.sort()
y = [results[lat] for lat in x]

# Normalizziamo su millisecondi per rendere i numeri piu leggibili (opzionale)
y_ms = [val / 1e9 for val in y] # assumendo 1000000000000 ticks/sec, 1e9 ticks = 1 ms

# Creazione del Plot con aspect ratio modificato per enfatizzare la pendenza
plt.figure(figsize=(7, 6))

plt.plot(x, y_ms, marker='o', linestyle='-', color='#1f77b4', linewidth=2.5, markersize=8, label=f'Policy {policy} (Arity 15)')

plt.xlim(0, 110)
plt.xticks([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110])

# Imposto il limite Y per zoomare sulla curva ed enfatizzare la pendenza
y_padding = (max(y_ms) - min(y_ms)) * 0.15

# Calcolo una posizione Y per le etichette in basso nel grafico
text_y = min(y_ms) - (y_padding * 0.8)

# Zone di Latenza Hardware
plt.axvspan(5, 40, color='green', alpha=0.1)
plt.text(22.5, text_y, 'Hardware AES Ottimizzato\n(10-40 cicli)', color='darkgreen', ha='center', va='bottom', fontsize=10, fontweight='bold')

plt.axvspan(40, 110, color='gray', alpha=0.1)
plt.text(70, text_y, 'Hardware Sub-Ottimale\n(>40 cicli)', color='black', ha='center', va='bottom', fontsize=10, fontweight='bold')

plt.ylim(min(y_ms) - y_padding, max(y_ms) + y_padding)

plt.title(f'Tectree Crypto-Latency Sensitivity Analysis\n(Radix 16k, 2 Threads, Policy {policy}, Arity 15)', fontsize=14, fontweight='bold')
plt.xlabel('Crypto Latency introdotta per pacchetto (Cicli)', fontsize=12)
plt.ylabel('Tempo di esecuzione ROI (Millisecondi)', fontsize=12)

plt.grid(True, linestyle='--', alpha=0.7)
plt.legend(loc='upper left', fontsize=11)
plt.tight_layout()

# Salva il grafico
output_file = f"crypto_sensitivity_Pol{policy}.png"
plt.savefig(output_file, dpi=300, bbox_inches='tight')
print(f"Grafico generato con successo e salvato come: {output_file}")
