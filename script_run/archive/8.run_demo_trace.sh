#!/bin/bash

# Script per avviare il microbenchmark di debug Tectree e catturare un log di protocollo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GEM5_DIR="$SCRIPT_DIR/../../gem5"
ARCH="x86"
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
WORKLOAD="demo_tectree"

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

# Percorsi dei file C
SRC_FILE="$REPO_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/src/demo_tectree.c"
BIN_DIR="$REPO_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/bin"
BIN_FILE="$BIN_DIR/demo_tectree"

echo "=========================================================="
echo "1. Compilazione del Microbenchmark di Debug"
echo "=========================================================="
mkdir -p "$BIN_DIR"
# Compilazione statica bare-metal (nessuna dipendenza da librerie dinamiche)
gcc -static -O0 "$SRC_FILE" -o "$BIN_FILE"

if [ $? -ne 0 ]; then
    echo "ERRORE: Fallita la compilazione di $SRC_FILE"
    exit 1
fi
echo "Compilazione riuscita: $BIN_FILE"

cd "$GEM5_DIR"
mkdir -p results_demo

echo "=========================================================="
echo "2. Avvio Simulazione con TRACCIATURA SLICC"
echo "=========================================================="
GEM5_EXE="./build/X86_${PROTOCOL}/gem5.opt"

if [ ! -f "$GEM5_EXE" ]; then
    echo "ERRORE: Eseguibile $GEM5_EXE non trovato!"
    exit 1
fi

LOG_FILE="results_demo/protocol_trace.txt"
echo "Esecuzione in corso... (Questo potrebbe impiegare un minuto, la tracciatura è pesante)"

# Lanciamo gem5:
# - '--debug-flags=ProtocolTrace' per stampare i log delle transizioni della Cache (Hit, Miss, Eviction)
# - Cache L2 impostata deliberatamente minuscola (8kB) per forzare gli sfratti previsti dalla Fase 3
POLICY_FLAG=""
if [ "$PROTOCOL" == "TARDISTSO_TECTREE" ]; then
    POLICY_FLAG="--mru-policy=2"
fi

$GEM5_EXE \
    --debug-flags=Tectree \
    configs/deprecated/example/se.py \
    -c "$BIN_FILE" \
    --cpu-type X86TimingSimpleCPU --ruby --l2_size=8kB --mem-size=3GB $POLICY_FLAG --tectree-arity=15 --crypto-latency=15 > "$LOG_FILE" 2>&1

echo "=========================================================="
echo "Test Completato!"
echo "Apri il file per ispezionare le transizioni SLICC:"
echo "gem5/$LOG_FILE"
echo "Cerca nel file le stringhe 'FASE' (es: grep FASE gem5/$LOG_FILE) per mappare il codice C agli eventi hardware!"
echo "=========================================================="
