#include <stdint.h>

#define CACHE_LINE_SIZE 64
#define L2_ASSOC 8
#define L2_SETS 16 
#define ALIAS_STRIDE (L2_SETS * CACHE_LINE_SIZE)

// Allocazione statica nel segmento BSS (nessuna syscall malloc necessaria)
// Usiamo volatile per impedire al compilatore di ottimizzare via gli accessi
volatile uint8_t shared_array[8192];

int main() {
    // FASE 1: Allocazione Counter a freddo (C_V)
    // Lettura a freddo
    uint8_t a = shared_array[0];

    // FASE 2: Scrittura e Sporcatura (C_M)
    // Scrittura (Dirty)
    shared_array[0] = 42; 

    // FASE 3: Evizione Selettiva (Policy 2)
    // Sfratto Dati, Ritenzione Counter
    // Riempiamo il Set per causare sfratto
    for(int i = 1; i <= 16; i++) {
        shared_array[i * ALIAS_STRIDE] = (uint8_t)i;
    }

    // FASE 4: Counter Hit / Data Miss
    // Rileggiamo il dato originale
    uint8_t b = shared_array[0]; 

    // Senza pthreads e OS, non possiamo testare l'MSHR Bouncing asincrono multi-core,
    // ma le prime 4 fasi produrranno un trace SLICC purissimo.
    
    // Scrittura fittizia per usare le variabili ed evitare warning
    shared_array[1] = a + b;

    return 0;
}
