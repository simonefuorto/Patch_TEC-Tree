#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
DEST="$SCRIPT_DIR/../../gem5"
ARCH="X86"
WORKLOAD="radix_bm"

SIZE=16384
ARITY=15
PROTOCOL="TARDISTSO_TECTREE"

POLICY=${1:-0}
MODE=${2:-CTR} # Può essere CTR o ECB

CRYPTO_LATENCIES=(5 10 15 20 30 40 50 60 70 80 90 100)

ECB_FLAG=""
if [ "$MODE" == "ECB" ]; then
    ECB_FLAG="--is-ecb"
fi

if [ ! -d "$DEST" ]; then
  echo "Gem5 directory not found at $DEST!"
  exit 1
fi

cd "$DEST"

echo "=========================================================="
echo "Inizio Automazione Benchmark Radix (Crypto Latency Sweep)"
echo "Protocollo: $PROTOCOL | Policy MRU: $POLICY | Modalità: $MODE"
echo "Array Size: $SIZE | Arity: $ARITY | Threads: 2"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato!"
    exit 1
fi

for CRYPTO in "${CRYPTO_LATENCIES[@]}"; do
    echo "----------------------------------------------------------"
    echo "Avvio Test: Policy: $POLICY | Mode: $MODE | Crypto Latency: $CRYPTO cicli"
    echo "----------------------------------------------------------"
    
    RESULT_DIR="results_crypto_sweep_Pol${POLICY}_${MODE}/stats_crypto_${CRYPTO}"
    mkdir -p "$RESULT_DIR"

    # Esecuzione di Radix a 2 thread
    $GEM5_EXE \
        configs/deprecated/example/se.py \
        -c tests/test-progs/tardis_tso/${ARCH}/${WORKLOAD}/bin/${WORKLOAD} \
        --options="-p 2 -n $SIZE -t" \
        -n 3 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=4GB \
        --mru-policy=$POLICY --tectree-arity=$ARITY --crypto-latency=$CRYPTO $ECB_FLAG
    
    cp m5out/stats.txt "$RESULT_DIR/"
    
    echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
done

echo "=========================================================="
echo "Sweep completato con successo!"
echo "=========================================================="
