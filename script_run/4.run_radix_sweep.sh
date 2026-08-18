#!/bin/bash


ARCH="X86"
WORKLOAD="radix_bm"

# Le dimensioni dell'array da testare (Piccolo, Medio, Grande)
SIZES=(16384 65536 131072)

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

# I protocolli da testare
PROTOCOLS=("$PROTOCOL")

# Identifica automaticamente la directory dello script e la cartella gem5 (assumendo che siano "gemelli")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$SCRIPT_DIR/../../gem5"

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

cd "$GEM5_DIR"
mkdir -p results_radix

echo "=========================================================="
echo "Inizio Automazione Benchmark Radix: 3 Dimensioni, Protocollo: $PROTOCOL"
echo "=========================================================="

for PROTOCOL in "${PROTOCOLS[@]}"; do
    for SIZE in "${SIZES[@]}"; do
        echo "----------------------------------------------------------"
        echo "Avvio Test: $PROTOCOL con array di dimensione $SIZE"
        echo "----------------------------------------------------------"
        
        GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
        if [ ! -f "$GEM5_EXE" ]; then
            echo "ERRORE: Eseguibile $GEM5_EXE non trovato! (Devi prima compilarlo con scons)"
            echo "Salto questo test..."
            continue
        fi
        
        POLICY_FLAG=""
        if [ "$PROTOCOL" == "TARDISTSO_TECTREE" ]; then
            POLICY_FLAG="--mru-policy=2"
        fi

        # Esegue gem5 per raccogliere le statistiche
        $GEM5_EXE \
            configs/deprecated/example/se.py \
            -c $REPO_ROOT/tests/test-progs/tardis_tso/x86/${WORKLOAD}/bin/${WORKLOAD} \
            --options="$SIZE" \
            -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=3GB $POLICY_FLAG
        
        # Crea una cartella per salvare le statistiche di questa specifica esecuzione
        RESULT_DIR="results_radix/stats_${PROTOCOL}_${SIZE}"
        mkdir -p "$RESULT_DIR"
        
        # Copia il file delle statistiche prima che venga sovrascritto dal test successivo
        cp m5out/stats.txt "$RESULT_DIR/"
        
        echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
    done
done

echo "=========================================================="
echo "Tutti i test sono terminati con successo!"
echo "I risultati si trovano nella cartella gem5/results_radix/"
echo "=========================================================="
