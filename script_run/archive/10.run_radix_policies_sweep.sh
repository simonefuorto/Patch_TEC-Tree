#!/bin/bash

ARCH="X86"
WORKLOAD="radix_bm"

# Le 3 dimensioni dell'array da testare
SIZES=(16384 65536 131072)

# Le 3 Policy da testare (0=Baseline, 1=Non Ottimizzato, 2=Tectree Ottimizzato)
POLICIES=(0 1 2)

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

# Identifica automaticamente la directory dello script e la cartella gem5
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$SCRIPT_DIR/../../gem5"

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

cd "$GEM5_DIR"
# Cartella dedicata per evitare di sovrascrivere i test precedenti
mkdir -p results_radix_policies_sweep

echo "=========================================================="
echo "Inizio Sweep Radix: 3 Dimensioni & 3 Policy"
echo "Protocollo: $PROTOCOL"
echo "=========================================================="

GEM5_EXE="./build/${ARCH}_${PROTOCOL}/gem5.opt"
if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato! (Devi prima compilarlo con scons)"
    exit 1
fi

# Doppio ciclo: Prima le Policy, poi le Dimensioni
for POLICY in "${POLICIES[@]}"; do
    for SIZE in "${SIZES[@]}"; do
        echo "----------------------------------------------------------"
        echo "Avvio Test: $PROTOCOL | Policy: $POLICY | Array: $SIZE"
        echo "----------------------------------------------------------"
        
        # Imposta la policy solo se stiamo usando TARDIS
        POLICY_FLAG=""
        if [ "$PROTOCOL" == "TARDISTSO_TECTREE" ]; then
            POLICY_FLAG="--mru-policy=$POLICY"
        fi

        # Esegue gem5 (NOTA: Qui usiamo correttamente -n $SIZE)
        $GEM5_EXE \
            configs/deprecated/example/se.py \
            -c $REPO_ROOT/tests/test-progs/tardis_tso/x86/${WORKLOAD}/bin/${WORKLOAD} \
            --options="-p 4 -n $SIZE -t" \
            -n 5 --cpu-type ${ARCH}TimingSimpleCPU --ruby --l2_size=1MB --mem-size=3GB $POLICY_FLAG
        
        # Crea una cartella per salvare le statistiche di QUESTA specifica Policy e Dimensione
        RESULT_DIR="results_radix_policies_sweep/stats_${PROTOCOL}_Pol${POLICY}_${SIZE}"
        mkdir -p "$RESULT_DIR"
        
        # Copia sicura del file stats.txt
        if [ -f m5out/stats.txt ]; then
            cp m5out/stats.txt "$RESULT_DIR/"
            echo "Test completato! Statistiche salvate in: gem5/$RESULT_DIR/stats.txt"
        else
            echo "ATTENZIONE: File delle statistiche non generato per Policy $POLICY, Dimensione $SIZE."
        fi
    done
done

echo "=========================================================="
echo "Tutti i test dello Sweep sono terminati con successo!"
echo "I risultati si trovano in: gem5/results_radix_policies_sweep/"
echo "=========================================================="
