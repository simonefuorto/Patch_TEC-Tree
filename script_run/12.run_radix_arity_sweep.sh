#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
DEST="$SCRIPT_DIR/../../gem5"
ARCH="X86"
WORKLOAD="radix_bm"

# Le dimensioni dell'array da testare (Piccolo, Medio, Grande)
SIZES=(16384 65536 131072)

# Le Arity da testare per la configurazione dinamica di Tectree
ARITIES=(7 15 31 63)

PROTOCOL="TARDISTSO_TECTREE" # Default

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
echo "Inizio Automazione Benchmark Radix (Sweep Arity & Sizes)"
echo "Protocollo: $PROTOCOL"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato! (Devi prima compilarlo con scons)"
    exit 1
fi

for ARITY in "${ARITIES[@]}"; do
    for SIZE in "${SIZES[@]}"; do
        echo "----------------------------------------------------------"
        echo "Avvio Test: $PROTOCOL | Arity: $ARITY | Array: $SIZE"
        echo "----------------------------------------------------------"
        
        # Lancia gem5 con la dimensione dell'array e l'arity personalizzata
        $GEM5_EXE \
            configs/deprecated/example/se.py \
            -c tests/test-progs/tardis_tso/${ARCH}/${WORKLOAD}/bin/${WORKLOAD} \
            --options="-p 4 -n $SIZE -t" \
            -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=4GB --mru-policy=0 --tectree-arity=$ARITY
        
        # Crea una cartella per salvare le statistiche di questa specifica esecuzione
        RESULT_DIR="results_radix/stats_${PROTOCOL}_Pol0_arity_${ARITY}_size_${SIZE}"
        mkdir -p "$RESULT_DIR"
        
        # Copia il file delle statistiche prima che venga sovrascritto dal test successivo
        cp m5out/stats.txt "$RESULT_DIR/"
        
        echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
    done
done

echo "=========================================================="
echo "Tutti i test del Radix Arity Sweep sono terminati con successo!"
echo "I risultati si trovano nella cartella gem5/results_radix/"
echo "=========================================================="
