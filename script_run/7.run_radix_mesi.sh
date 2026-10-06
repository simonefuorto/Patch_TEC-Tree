#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
DEST="$SCRIPT_DIR/../../gem5"
ARCH="X86"
WORKLOAD="radix_bm"

# Le dimensioni dell'array da testare (Piccolo, Medio, Grande)
SIZES=(16384 65536 131072)

PROTOCOL="MESI_Two_Level" # Default per questo script

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

if [ ! -d "$DEST" ]; then
  echo "Gem5 directory not found at $DEST!"
  exit 1
fi

cd "$DEST"
mkdir -p results_radix

echo "=========================================================="
echo "Inizio Automazione Benchmark Radix per il protocollo $PROTOCOL"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato! (Devi prima compilarlo con lo script 3bis)"
    exit 1
fi

for SIZE in "${SIZES[@]}"; do
    echo "----------------------------------------------------------"
    echo "Avvio Test: $PROTOCOL | Array: $SIZE"
    echo "----------------------------------------------------------"
    
    # Lancia gem5 con la dimensione dell'array, protocollo liscio, 3GB RAM e 1MB L2 cache
    $GEM5_EXE \
        configs/deprecated/example/se.py \
        -c tests/test-progs/tardis_tso/${ARCH}/${WORKLOAD}/bin/${WORKLOAD} \
        --options="-p 4 -n $SIZE -t" \
        -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=3GB
    
    # Crea una cartella per salvare le statistiche di questa specifica esecuzione
    RESULT_DIR="results_radix/stats_${PROTOCOL}_${SIZE}"
    mkdir -p "$RESULT_DIR"
    
    # Copia il file delle statistiche prima che venga sovrascritto dal test successivo
    cp m5out/stats.txt "$RESULT_DIR/"
    
    echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
done

echo "=========================================================="
echo "I 3 test di MESI sono terminati con successo!"
echo "I risultati si trovano nella cartella gem5/results_radix/"
echo "=========================================================="
