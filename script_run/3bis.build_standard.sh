#!/bin/bash

ARCH="X86"
PROTOCOL=""

VALID_ARCH=("X86" "ARM")

usage() {
    echo "Usage: $0 [-p PROTOCOL]"
    echo "Example: $0 -p MESI_Two_Level"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
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

if [ -z "$PROTOCOL" ]; then
    echo "Error: Devi specificare il protocollo con -p (es: -p MESI_Two_Level)"
    usage
fi

echo "Questo script è dedicato alla compilazione di protocolli standard (es. $PROTOCOL)."

# Identifica automaticamente la directory dello script e la cartella gem5 (assumendo che siano "gemelli")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
GEM5_DIR="$SCRIPT_DIR/../../gem5"

if [ ! -d "$GEM5_DIR" ]; then
  echo "ERRORE: Cartella gem5 non trovata al percorso previsto ($GEM5_DIR)!"
  exit 1
fi

echo "[1/2] Configurazione ambiente per la compilazione in $GEM5_DIR..."
cd "$GEM5_DIR"

# Assicuriamoci che la cartella build_opts esista
mkdir -p build_opts

echo "[2/2] Avvio compilazione (scons) per $ARCH con protocollo $PROTOCOL..."

# Metodo infallibile per generare build_opts forzando il protocollo
grep -v -E "PROTOCOL|RUBY_PROTOCOL_" build_opts/${ARCH} > build_opts/${ARCH}_${PROTOCOL}
PROTOCOL_UPPER=$(echo $PROTOCOL | tr '[:lower:]' '[:upper:]')
echo "RUBY_PROTOCOL_${PROTOCOL_UPPER}=y" >> build_opts/${ARCH}_${PROTOCOL}
# Il file Ruby.py prenderà il protocollo dall'ambiente di build.
# Forziamo PROTOCOL da linea di comando scons per ignorare la cache!

# Forziamo 2 core al massimo per evitare crash per RAM esaurita su Docker/Windows
CORES=2

echo "[2.5/2] Pulizia cache di Scons per forzare il nuovo protocollo..."
# QUESTO È FONDAMENTALE: Cancella la cache delle variabili di scons per impedire che usi vecchi protocolli
rm -f build/${ARCH}_${PROTOCOL}/gem5.build/variables.global

scons build/${ARCH}_${PROTOCOL}/gem5.opt -j${CORES} CXXFLAGS="-Wno-error=deprecated-declarations" PROTOCOL=${PROTOCOL}

echo "Done."
