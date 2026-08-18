#!/bin/bash

# Identifica automaticamente la directory dello script e la root del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$REPO_ROOT/../gem5"

ARCH="X86"
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
BENCHMARKS=("ping_pong" "sweet_spot" "streaming")

echo "=========================================================="
echo "Compilazione dei Microbenchmarks"
echo "=========================================================="
# NOTA: I binari sono presi direttamente dalla cartella tests della repo Tectree
# cd microbenchmarks
# make clean
# make
# cd ..

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"

cd "$GEM5_DIR"
mkdir -p results_microbench

echo "=========================================================="
echo "Inizio Esecuzione Microbenchmarks per $PROTOCOL"
echo "=========================================================="

for BENCHMARK in "${BENCHMARKS[@]}"; do
    echo "----------------------------------------------------------"
    echo "Avvio Test: $BENCHMARK"
    echo "----------------------------------------------------------"
    
    if [ ! -f "$GEM5_EXE" ]; then
        echo "ERRORE: Eseguibile $GEM5_EXE non trovato!"
        exit 1
    fi
    
    if [ "$BENCHMARK" == "streaming" ]; then
        OPTIONS_FLAG="-p 1"
        N_FLAG="2"
    else
        OPTIONS_FLAG="-p 4"
        N_FLAG="5"
    fi
    
    POLICY_FLAG=""
    if [ "$PROTOCOL" == "TARDISTSO_TECTREE" ]; then
        POLICY_FLAG="--mru-policy=1"
    fi
    
    # Esegue gem5
    $GEM5_EXE \
        configs/deprecated/example/se.py \
        -c $REPO_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/bin/${BENCHMARK} \
        --options="$OPTIONS_FLAG" \
        -n $N_FLAG --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=2MB --mem-size=3GB $POLICY_FLAG
    
    # Salva i risultati
    RESULT_DIR="results_microbench/stats_${BENCHMARK}"
    mkdir -p "$RESULT_DIR"
    cp m5out/stats.txt "$RESULT_DIR/"
    cp m5out/system.pc.com_1.device "$RESULT_DIR/output.log" 2>/dev/null || true
    
    echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
done

echo "=========================================================="
echo "Tutti i microbenchmarks sono terminati con successo!"
echo "I risultati si trovano nella cartella gem5/results_microbench/"
echo "=========================================================="
