import os
import re
import argparse
import matplotlib.pyplot as plt

def extract_roi_ticks(file_path):
    if not os.path.exists(file_path):
        return None
    
    sim_ticks_list = []
    with open(file_path, 'r') as f:
        for line in f:
            if line.startswith('simTicks'):
                match = re.search(r'simTicks\s+(\d+)', line)
                if match:
                    sim_ticks_list.append(int(match.group(1)))
    
    # Ritorna il secondo simTicks (ROI)
    if len(sim_ticks_list) >= 2:
        return sim_ticks_list[1]
    elif len(sim_ticks_list) == 1:
        return sim_ticks_list[0]
    return None

def main():
    parser = argparse.ArgumentParser(description="Plotta i risultati CTR vs ECB")
    parser.add_argument("-p", "--policy", type=int, default=0, help="Policy MRU da analizzare")
    args = parser.parse_args()

    policy = args.policy
    base_dir = "../../gem5"
    latencies = [5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 100]

    modes = ['CTR', 'ECB']
    results = {'CTR': {}, 'ECB': {}}

    print(f"--- Estrazione Dati per Policy {policy} ---")
    for mode in modes:
        for lat in latencies:
            folder_path = os.path.join(base_dir, f"results_crypto_sweep_Pol{policy}_{mode}", f"stats_crypto_{lat}")
            file_path = os.path.join(folder_path, "stats.txt")
            
            ticks = extract_roi_ticks(file_path)
            if ticks is not None:
                results[mode][lat] = ticks
            else:
                print(f"  [Warning] Dati mancanti per {mode} - {lat} cicli")

    if not results['CTR'] and not results['ECB']:
        print("Errore: Nessun dato trovato. Assicurati di aver eseguito entrambi gli sweep.")
        exit(1)

    # Preparazione dati per il plot (in ms)
    x_ctr = sorted(list(results['CTR'].keys()))
    y_ctr = [results['CTR'][lat] / 1e9 for lat in x_ctr]

    x_ecb = sorted(list(results['ECB'].keys()))
    y_ecb = [results['ECB'][lat] / 1e9 for lat in x_ecb]

    # Creazione Plot
    plt.figure(figsize=(8, 6))

    if x_ecb:
        plt.plot(x_ecb, y_ecb, marker='s', linestyle='-', color='#d62728', linewidth=2.5, markersize=8, label=f'AES-ECB (Latenza Esposta)')
    
    if x_ctr:
        plt.plot(x_ctr, y_ctr, marker='o', linestyle='-', color='#1f77b4', linewidth=2.5, markersize=8, label=f'AES-CTR (Latency Hiding)')

    plt.xlim(0, 110)
    plt.xticks([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110])

    # Sfondi Hardware
    all_y = y_ctr + y_ecb
    if all_y:
        y_padding = (max(all_y) - min(all_y)) * 0.15
        min_y = min(all_y) - y_padding
        max_y = max(all_y) + y_padding
        plt.ylim(min_y, max_y)
        
        text_y = min_y + (y_padding * 0.2)
        plt.axvspan(5, 40, color='green', alpha=0.1)
        plt.text(22.5, text_y, 'Hardware AES Ottimizzato\n(10-40 cicli)', color='darkgreen', ha='center', va='bottom', fontsize=10, fontweight='bold')

        plt.axvspan(40, 110, color='gray', alpha=0.1)
        plt.text(70, text_y, 'Hardware Sub-Ottimale\n(>40 cicli)', color='black', ha='center', va='bottom', fontsize=10, fontweight='bold')

    plt.title(f'Confronto Architetturale TEC-Tree: CTR vs ECB\n(Radix 16k, 2 Threads, Policy {policy}, Arity 15)', fontsize=14, fontweight='bold')
    plt.xlabel('Latenza Crittografica Hardware (Cicli)', fontsize=12)
    plt.ylabel('Tempo di esecuzione ROI (Millisecondi)', fontsize=12)

    plt.grid(True, linestyle='--', alpha=0.7)
    plt.legend(loc='upper left', fontsize=11)
    plt.tight_layout()

    # Salva il grafico
    output_file = f"comparison_CTR_vs_ECB_Pol{policy}.png"
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\nGrafico comparativo generato con successo: {output_file}")

if __name__ == "__main__":
    main()
