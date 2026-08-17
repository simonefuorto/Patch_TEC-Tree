#!/bin/bash


ARCH=""
PROTOCOL="TARDISTSO_TECTREE"

VALID_ARCH=("X86" "ARM")

usage() {
    echo "Usage: $0 -a ARCH [-p PROTOCOL]"
    echo "Valid ARCH values: ${VALID_ARCH[*]}"
    echo "Default PROTOCOL: TARDISTSO_TECTREE (e.g. use -p MOESI_hammer or -p MESI_Two_Level for others)"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -p|--protocol)
            PROTOCOL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ ! " ${VALID_ARCH[@]} " =~ " $ARCH " ]]; then
    echo "Error: Invalid ARCH value. Must be one of: ${VALID_ARCH[*]}"
    usage
fi

# Identifica automaticamente la directory dello script e la cartella gem5 (assumendo che siano "gemelli")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GEM5_DIR="$SCRIPT_DIR/../../gem5"

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

cd "$GEM5_DIR"

echo "Building gem5 project with $PROTOCOL on $ARCH..."

# Clean old build se esiste per evitare bug di cache di scons
# rm -rf build/${ARCH}_${PROTOCOL}

# Metodo infallibile per generare build_opts forzando il protocollo
grep -v -E "PROTOCOL|RUBY_PROTOCOL_" build_opts/${ARCH} > build_opts/${ARCH}_${PROTOCOL}
echo "RUBY_PROTOCOL_${PROTOCOL}=y" >> build_opts/${ARCH}_${PROTOCOL}
echo "PROTOCOL = '${PROTOCOL}'" >> build_opts/${ARCH}_${PROTOCOL}

CORES=$(nproc 2>/dev/null || echo 4)

scons build/${ARCH}_${PROTOCOL}/gem5.opt -j${CORES}

echo "Done."
