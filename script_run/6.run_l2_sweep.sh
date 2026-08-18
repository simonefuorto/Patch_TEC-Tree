#!/bin/bash

# Identifica automaticamente la directory dello script e la cartella gem5 (assumendo che siano "gemelli")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$SCRIPT_DIR/../../gem5"

ARCH="X86"
# Aggiornato al microbenchmark personalizzato dell'utente
WORKLOAD="thrashing"

# Dimensioni della cache L2 da testare per verificare il Thrashing
L2_SIZES=("64kB" "128kB" "256kB" "512kB" "1MB")

# Le 3 Policy da testare
POLICIES=(0 1 2)

PROTOCOL="TARDISTSO_TECTREE"

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -p|--protocol)
            PROTOCOL="$2"
            shift 2
            ;;
        *)
            echo "Opzione sconosciuta: $1"
            echo "Uso: $0 [-p PROTOCOL]"
            exit 1
            ;;
    esac
done

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

cd "$GEM5_DIR"
mkdir -p results_l2_sweep

echo "=========================================================="
echo "Inizio Automazione L2 Sweep: 3 Policy, 5 Dimensioni Cache"
echo "Microbenchmark: $WORKLOAD (64MB Array, Stride 512B)"
echo "Protocollo: $PROTOCOL"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato! (Devi prima compilarlo con scons)"
    exit 1
fi

for POLICY in "${POLICIES[@]}"; do
    for L2_SIZE in "${L2_SIZES[@]}"; do
        echo "----------------------------------------------------------"
        echo "Avvio Test: $PROTOCOL - Policy $POLICY - L2 Size $L2_SIZE"
        echo "----------------------------------------------------------"
        
        POLICY_FLAG=""
        if [ "$PROTOCOL" == "TARDISTSO_TECTREE" ]; then
            POLICY_FLAG="--mru-policy=$POLICY"
        fi

        # Esegue gem5 per raccogliere le statistiche
        $GEM5_EXE \
            configs/deprecated/example/se.py \
            -c $REPO_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/bin/${WORKLOAD} \
            --options="67108864" \
            -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=$L2_SIZE --mem-size=3GB $POLICY_FLAG
        
        RESULT_DIR="results_l2_sweep/stats_Policy${POLICY}_${L2_SIZE}"
        mkdir -p "$RESULT_DIR"
        
        cp m5out/stats.txt "$RESULT_DIR/"
        
        echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
    done
done

echo "=========================================================="
echo "Tutti i test (15 Simulazioni) sono terminati con successo!"
echo "I risultati si trovano nella cartella gem5/results_l2_sweep/"
echo "Puoi ora lanciare lo script Python plot_l2_thrashing.py"
echo "=========================================================="
