#!/bin/bash
# ==============================================================================
# Script di esecuzione Microbenchmarks (lanciabile da script_run/ o da root)
# Microbenchmarks: ping_pong, sweet_spot, streaming
# ==============================================================================

set -e

# Rilevamento automatico della root del repository e di gem5
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/../../gem5" ]; then
    ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
    GEM5_ROOT="$ROOT_DIR/gem5"
elif [ -d "$SCRIPT_DIR/../gem5" ]; then
    ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    GEM5_ROOT="$ROOT_DIR/gem5"
elif [ -d "$SCRIPT_DIR/gem5" ]; then
    ROOT_DIR="$SCRIPT_DIR"
    GEM5_ROOT="$ROOT_DIR/gem5"
else
    echo "[-] Errore: Cartella gem5 non trovata né in $SCRIPT_DIR né nelle cartelle superiori!"
    exit 1
fi

ARCH="X86"
PROTOCOL="TARDISTSO_TECTREE"
VALID_BENCHMARKS=("ping_pong" "sweet_spot" "streaming")

echo "========================================================================"
echo "    ESECUZIONE DEI MICROBENCHMARK TARDISTSO-TECTREE (gem5)"
echo "========================================================================"
echo " Directory gem5 : $GEM5_ROOT"
echo " Protocollo     : $PROTOCOL"
echo "========================================================================"

GEM5_EXE="$GEM5_ROOT/build/${ARCH}_${PROTOCOL}/gem5.opt"

if [ ! -f "$GEM5_EXE" ]; then
    echo "[-] Errore: Eseguibile $GEM5_EXE non trovato!"
    echo "    Compila prima il simulatore con lo script di build."
    exit 1
fi

# Sincronizzazione binari
BENCH_SRC_DIR="$ROOT_DIR/microbenchmarks"
BENCH_BIN_DIR="$GEM5_ROOT/tests/test-progs/tardis_tso/x86/microbenchmarks/bin"
mkdir -p "$BENCH_BIN_DIR"

for b in "${VALID_BENCHMARKS[@]}"; do
    if [ ! -f "$BENCH_BIN_DIR/$b" ]; then
        if [ -f "$BENCH_SRC_DIR/bin/$b" ]; then
            cp "$BENCH_SRC_DIR/bin/$b" "$BENCH_BIN_DIR/$b"
        elif [ -f "$BENCH_SRC_DIR/$b" ]; then
            cp "$BENCH_SRC_DIR/$b" "$BENCH_BIN_DIR/$b"
        elif [ -f "$ROOT_DIR/patch_tectree/tests/test-progs/tardis_tso/x86/microbenchmarks/bin/$b" ]; then
            cp "$ROOT_DIR/patch_tectree/tests/test-progs/tardis_tso/x86/microbenchmarks/bin/$b" "$BENCH_BIN_DIR/$b"
        fi
    fi
done

RESULTS_DIR="$GEM5_ROOT/results_microbench"
mkdir -p "$RESULTS_DIR"

for BENCHMARK in "${VALID_BENCHMARKS[@]}"; do
    echo ""
    echo ">>> Esecuzione: $BENCHMARK"
    echo "------------------------------------------------------------------------"

    if [ "$BENCHMARK" == "streaming" ]; then
        OPTIONS_FLAG="-p 1"
        N_CORES=2
    else
        OPTIONS_FLAG="-p 4"
        N_CORES=5
    fi

    OUTPUT_FOLDER="${RESULTS_DIR}/stats_${BENCHMARK}_${PROTOCOL}"
    mkdir -p "$OUTPUT_FOLDER"

    CMD="./build/${ARCH}_${PROTOCOL}/gem5.opt \
        configs/deprecated/example/se.py \
        -c tests/test-progs/tardis_tso/x86/microbenchmarks/bin/${BENCHMARK} \
        --options='$OPTIONS_FLAG' \
        -n $N_CORES \
        --cpu-type ${ARCH}TimingSimpleCPU \
        --ruby --l2_size=2MB --mem-size=4GB --mru-policy=1"

    (cd "$GEM5_ROOT" && eval "$CMD")

    if [ -f "$GEM5_ROOT/m5out/stats.txt" ]; then
        cp "$GEM5_ROOT/m5out/stats.txt" "$OUTPUT_FOLDER/stats.txt"
        echo "[+] Completato! Statistiche salvate in: $OUTPUT_FOLDER/stats.txt"
    fi
done

echo ""
echo "========================================================================"
echo "                     RIASSUNTO RISULTATI (ROI)"
echo "========================================================================"
printf "%-15s | %-15s | %-12s | %-12s\n" "Benchmark" "simTicks (Cicli)" "DRAM Reads" "DRAM Writes"
echo "------------------------------------------------------------------------"

for BENCHMARK in "${VALID_BENCHMARKS[@]}"; do
    STATS_FILE="${RESULTS_DIR}/stats_${BENCHMARK}_${PROTOCOL}/stats.txt"
    if [ -f "$STATS_FILE" ]; then
        TICKS=$(grep "simTicks" "$STATS_FILE" | head -n 1 | awk '{print $2}')
        DRAM_READS=$(grep "system.mem_ctrls.dram.numReads::total" "$STATS_FILE" | head -n 1 | awk '{print $2}')
        DRAM_WRITES=$(grep "system.mem_ctrls.dram.numWrites::total" "$STATS_FILE" | head -n 1 | awk '{print $2}')
        printf "%-15s | %-15s | %-12s | %-12s\n" "$BENCHMARK" "${TICKS:-N/A}" "${DRAM_READS:-N/A}" "${DRAM_WRITES:-N/A}"
    fi
done
echo "========================================================================"
