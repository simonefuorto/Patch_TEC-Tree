#!/bin/bash

# Identifica automaticamente la directory dello script e la cartella gem5 (assumendo che siano "gemelli")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$SCRIPT_DIR/../../gem5"

ARCH="X86"
WORKLOAD="radix_bm"

# Le dimensioni dell'array da testare (Piccolo, Medio, Grande)
SIZES=(16384 65536 131072)

# Le 3 Policy da testare
# 0 = MRU Assoluto (Baseline)
# 1 = (Non ottimizzato)
# 2 = Randomizzato Intelligente (Tectree Ottimizzato)
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
mkdir -p results_radix

echo "=========================================================="
echo "Inizio Automazione Sweep Totale: 3 Policy, 3 Dimensioni"
echo "Protocollo: $PROTOCOL"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato! (Devi prima compilarlo con scons)"
    exit 1
fi

for POLICY in "${POLICIES[@]}"; do
    for SIZE in "${SIZES[@]}"; do
        echo "----------------------------------------------------------"
        echo "Avvio Test: $PROTOCOL - Policy $POLICY - Array $SIZE"
        echo "----------------------------------------------------------"
        
        # Lancia gem5 con la dimensione dell'array e la policy specifica
        $GEM5_EXE \
            configs/deprecated/example/se.py \
            -c $REPO_ROOT/tests/test-progs/tardis_tso/x86/${WORKLOAD}/bin/${WORKLOAD} \
            --options="-p 4 -n $SIZE -t" \
            -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=3GB --mru-policy=$POLICY
        
        # Crea una cartella per salvare le statistiche di questa specifica esecuzione
        RESULT_DIR="results_radix/stats_${PROTOCOL}_Policy${POLICY}_${SIZE}"
        mkdir -p "$RESULT_DIR"
        
        # Copia il file delle statistiche prima che venga sovrascritto dal test successivo
        cp m5out/stats.txt "$RESULT_DIR/"
        
        echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
    done
done

echo "=========================================================="
echo "Tutti i test (9 Simulazioni) sono terminati con successo!"
echo "I risultati si trovano nella cartella gem5/results_radix/"
echo "Puoi ora lanciare lo script Python per generare i grafici!"
echo "=========================================================="
