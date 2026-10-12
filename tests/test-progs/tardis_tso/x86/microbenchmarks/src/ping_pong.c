#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <gem5/m5ops.h>

#define NUM_THREADS 4
#define NUM_ITERATIONS 100000

volatile int shared_counter = 0;
pthread_barrier_t barrier;

void* worker(void* arg) {
    int thread_id = *(int*)arg;
    
    // Sincronizzazione pre-ROI
    pthread_barrier_wait(&barrier);
    
    if (thread_id == 0) {
        m5_dump_reset_stats(0, 0); // Inizio ROI
    }
    
    // Barriera per garantire che il dump sia fatto prima di partire
    pthread_barrier_wait(&barrier);

    // ROI: Ping Pong sulla stessa variabile
    for (int i = 0; i < NUM_ITERATIONS; i++) {
        __sync_fetch_and_add(&shared_counter, 1);
    }
    
    // Barriera post-ROI
    pthread_barrier_wait(&barrier);
    
    if (thread_id == 0) {
        printf("Ping Pong Test Completed. Final counter: %d\n", shared_counter);
        m5_dump_stats(0, 0); // Fine ROI
        fflush(stdout);
        m5_exit(0);          // Uscita pulita per evitare il teardown
    }
    
    // Gli altri thread restano in spin per evitare l'uscita e i madvise
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
    
    // Il master thread non fa join perché thread 0 chiama m5_exit(0) e gli altri spin-loopano
    while(1) { __asm__ volatile("pause" ::: "memory"); }
    
    return 0;
}
