#!/bin/bash

# Script per avviare il microbenchmark di debug Tectree con diverse Arity (Sweep)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$SCRIPT_DIR/../../gem5"
PROTOCOL="TARDISTSO_TECTREE"

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

SRC_FILE="$REPO_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/src/demo_tectree.c"
BIN_DIR="$REPO_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/bin"
BIN_FILE="$BIN_DIR/demo_tectree"

echo "=========================================================="
echo "1. Compilazione del Microbenchmark di Debug"
echo "=========================================================="
mkdir -p "$BIN_DIR"
gcc -static -O0 "$SRC_FILE" -o "$BIN_FILE"

if [ $? -ne 0 ]; then
    echo "ERRORE: Fallita la compilazione di $SRC_FILE"
    exit 1
fi
echo "Compilazione riuscita: $BIN_FILE"

cd "$GEM5_DIR"
mkdir -p results_demo

GEM5_EXE="./build/X86_${PROTOCOL}/gem5.opt"

if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato!"
    exit 1
fi

POLICY_FLAG=""
if [ "$PROTOCOL" == "TARDISTSO_TECTREE" ]; then
    POLICY_FLAG="--mru-policy=2"
fi

ARITIES=(7 8 15 32 64)

echo "=========================================================="
echo "2. Avvio Sweep Arity (Tectree Trace)"
echo "=========================================================="

for A in "${ARITIES[@]}"; do
    LOG_FILE="results_demo/protocol_trace_arity_${A}.txt"
    echo "Esecuzione con Arity = $A... (Salvataggio in $LOG_FILE)"
    
    $GEM5_EXE \
        --debug-flags=Tectree \
        configs/deprecated/example/se.py \
        -c "$BIN_FILE" \
        --cpu-type X86TimingSimpleCPU --ruby --l2_size=8kB --mem-size=3GB $POLICY_FLAG --tectree-arity=$A > "$LOG_FILE" 2>&1
        
    echo "Arity $A completata."
done

echo "=========================================================="
echo "Sweep Completato!"
echo "Tutti i log si trovano nella cartella gem5/results_demo/"
echo "=========================================================="
