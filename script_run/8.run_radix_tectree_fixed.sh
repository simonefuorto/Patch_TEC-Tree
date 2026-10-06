#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
DEST="$SCRIPT_DIR/../../gem5"
ARCH="X86"
WORKLOAD="radix_bm"

# Le dimensioni dell'array da testare
SIZES=(16384 65536 131072)

PROTOCOL="TARDISTSO_TECTREE"
POLICY=2
ARITY=15
CRYPTO_LATENCY=10

if [ ! -d "$DEST" ]; then
  echo "Gem5 directory not found at $DEST!"
  exit 1
fi

cd "$DEST"
mkdir -p results_radix

echo "=========================================================="
echo "Inizio Benchmark Radix su $PROTOCOL"
echo "Configurazione Fissa: Policy $POLICY, Arity $ARITY, Latenza Cripto $CRYPTO_LATENCY, ECB"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato!"
    exit 1
fi

for SIZE in "${SIZES[@]}"; do
    echo "----------------------------------------------------------"
    echo "Avvio Test: Array $SIZE"
    echo "----------------------------------------------------------"
    
    # Lancia gem5 con i flag customizzati richiesti
    $GEM5_EXE \
        configs/deprecated/example/se.py \
        -c tests/test-progs/tardis_tso/${ARCH}/${WORKLOAD}/bin/${WORKLOAD} \
        --options="-p 4 -n $SIZE -t" \
        -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=3GB \
        --mru-policy=$POLICY --tectree-arity=$ARITY --crypto-latency=$CRYPTO_LATENCY --is-ecb
    
    # Cartella per i risultati
    RESULT_DIR="results_radix/stats_${PROTOCOL}_Pol${POLICY}_Arity${ARITY}_Lat${CRYPTO_LATENCY}_${SIZE}"
    mkdir -p "$RESULT_DIR"
    
    # Copia le statistiche
    cp m5out/stats.txt "$RESULT_DIR/"
    
    echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
done

echo "=========================================================="
echo "I 3 test di TARDISTSO_TECTREE sono terminati con successo!"
echo "=========================================================="
