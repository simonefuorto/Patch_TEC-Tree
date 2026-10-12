#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <pthread.h>
#include <gem5/m5ops.h>

#define NUM_THREADS 4
// 2 MB total array size -> 524288 integers (4 bytes each)
#define ARRAY_SIZE (2 * 1024 * 1024 / sizeof(int))
#define NUM_ACCESSES_PER_THREAD 100000

int data_array[ARRAY_SIZE];
pthread_barrier_t barrier;

// Xorshift PRNG for fast, low-overhead random numbers
uint32_t xorshift32(uint32_t *state) {
    uint32_t x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return *state = x;
}

void* worker(void* arg) {
    int thread_id = *(int*)arg;
    uint32_t rng_state = 123456789 + thread_id; // Seed differenziato
    
    // Inizializza l'array (al di fuori della ROI per evitare traffico spazzatura)
    // Usiamo il thread 0 per l'inizializzazione sequenziale
    if (thread_id == 0) {
        for (int i = 0; i < ARRAY_SIZE; i++) {
            data_array[i] = i;
        }
    }
    
    // Sincronizzazione pre-ROI
    pthread_barrier_wait(&barrier);
    
    if (thread_id == 0) {
        m5_dump_reset_stats(0, 0); // Inizio ROI
    }
    
    pthread_barrier_wait(&barrier);

    // ROI: Accessi casuali in un array da 2MB (Sweet spot della LLC)
    volatile int dummy = 0;
    for (int i = 0; i < NUM_ACCESSES_PER_THREAD; i++) {
        uint32_t idx = xorshift32(&rng_state) % ARRAY_SIZE;
        // Misto letture e scritture (aggiornamento sul posto)
        data_array[idx] += 1;
        dummy += data_array[idx];
    }
    
    // Barriera post-ROI
    pthread_barrier_wait(&barrier);
    
    if (thread_id == 0) {
        printf("Sweet Spot Test Completed. Dummy sum: %d\n", dummy);
        m5_dump_stats(0, 0); // Fine ROI
        fflush(stdout);
        m5_exit(0);
    }
    
    if (thread_id != 0) {
        while(1) { __asm__ volatile("pause" ::: "memory"); }
    }
    
    return NULL;
}

int main() {
    pthread_t threads[NUM_THREADS];
    int thread_ids[NUM_THREADS];
    
    pthread_barrier_init(&barrier, NULL, NUM_THREADS);
    
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_ids[i] = i;
        pthread_create(&threads[i], NULL, worker, &thread_ids[i]);
    }
    
    while(1) { __asm__ volatile("pause" ::: "memory"); }
    
    return 0;
}
