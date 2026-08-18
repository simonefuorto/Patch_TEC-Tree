#!/bin/bash


ARCH="X86"
PROTOCOL="TARDISTSO_TECTREE"

echo "Questo script è dedicato esclusivamente alla compilazione di TARDISTSO_TECTREE."

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

# Forziamo 2 core al massimo per evitare crash per RAM esaurita su Docker/Windows
CORES=2

scons build/${ARCH}_${PROTOCOL}/gem5.opt -j${CORES} CXXFLAGS="-Wno-error=deprecated-declarations"

echo "Done."
