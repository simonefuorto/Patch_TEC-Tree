#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <gem5/m5ops.h>

#define NUM_THREADS 1
// 4 MB total array size -> 1048576 integers (4 bytes each)
// This slightly exceeds or fills the LLC to cause evictions without overwhelming the network
#define ARRAY_SIZE (4 * 1024 * 1024 / sizeof(int))

int data_array[ARRAY_SIZE];
pthread_barrier_t barrier;

void* worker(void* arg) {
    int thread_id = *(int*)arg;
    
    // Chunk for each thread to avoid interference
    int chunk_size = ARRAY_SIZE / NUM_THREADS;
    int start_idx = thread_id * chunk_size;
    int end_idx = start_idx + chunk_size;
    
    // Inizializza l'array (fuori dalla ROI)
    for (int i = start_idx; i < end_idx; i++) {
        data_array[i] = i;
    }
    
    // Sincronizzazione pre-ROI
    pthread_barrier_wait(&barrier);
    
    if (thread_id == 0) {
        m5_dump_reset_stats(0, 0); // Inizio ROI
    }
    
    pthread_barrier_wait(&barrier);

    // ROI: Streaming sequenziale di dati giganti
    // Questo forza continui rimpiazzi (evictions) nella LLC
    volatile int dummy = 0;
    for (int i = start_idx; i < end_idx; i++) {
        // Legge, modifica e scrive (dirty eviction)
        data_array[i] += 1;
        dummy += data_array[i];
    }
    
    // Barriera post-ROI
    pthread_barrier_wait(&barrier);
    
    if (thread_id == 0) {
        printf("Streaming Test Completed. Dummy sum: %d\n", dummy);
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
