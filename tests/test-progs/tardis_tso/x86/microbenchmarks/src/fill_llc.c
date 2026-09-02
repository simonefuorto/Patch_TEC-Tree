#include <stdio.h>
#include <stdlib.h>
#include "gem5/m5ops.h"

// Ogni blocco cache è 64 byte.
// Selezioniamo 225 blocchi. Perché 225?
// Con un'arità di 15:
// - 225 blocchi dati richiedono esattamente 15 L1 CounterChunks
// - 15 L1 CounterChunks richiedono esattamente 1 L2 CounterChunk
#define NUM_BLOCKS (15 * 15)
#define BLOCK_SIZE 64

int main() {
    volatile char* array = (volatile char*)malloc(NUM_BLOCKS * BLOCK_SIZE);
    if (!array) return -1;

    // Inizializzazione (solo per sicurezza della memoria virtuale)
    for(int i = 0; i < NUM_BLOCKS; i++) {
        array[i * BLOCK_SIZE] = 0;
    }

    printf("Inizio ROI: Scrittura sequenziale per riempire la LLC...\n");
    // Resettiamo le statistiche di gem5 per avere dati pulitissimi sulla ROI
    m5_reset_stats(0, 0);

    // Eseguiamo una scrittura per ogni singolo blocco cache
    for(int i = 0; i < NUM_BLOCKS; i++) {
        array[i * BLOCK_SIZE] = (char)(i % 256);
    }

    // Facciamo un dump delle statistiche per analizzare cosa è entrato in LLC
    m5_dump_stats(0, 0);
    printf("Fine ROI.\n");

    free((void*)array);
    return 0;
}
