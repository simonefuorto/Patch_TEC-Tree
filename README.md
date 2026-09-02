# TARDISTSO_TECTREE: Implementazione in gem5

Questo repository contiene la patch architetturale per il simulatore **gem5** volta all'integrazione del protocollo di integrità della memoria **TEC-Tree** all'interno del protocollo di coerenza **Tardis TSO**.
L'obiettivo primario è la valutazione dell'impatto prestazionale, la gestione asincrona degli stati e l'analisi dei trade-off architetturali (Capacity Misses vs MSHR Bouncing) indotti dall'inserimento dei CounterChunks in LLC.

## Progress Tracker e Checklist di Implementazione

### FASE 1: Architettura Base e Bouncing Asincrono (COMPLETATA)
- [x] **STEP 1: Architettura CounterChunk in SLICC**
  - [x] Modifica dei tipi base e gestione della granularità di memoria (Chunk da 64 byte).
  - [x] Estensione delle strutture `CacheMemory` in `TARDISTSO_TECTREE-dir.sm`.
  - [x] Implementazione dell'azione `allocateCounterLLC` per il bypass dell'allocazione in L1.
- [x] **STEP 2: Valutazione Prestazionale (Baseline)**
  - [x] Esecuzione dei microbenchmark: `ping_pong`, `sweet_spot`, `streaming`.
  - [x] Estrazione delle metriche e profilazione rispetto al protocollo Tardis standard.
  - [x] Analisi architetturale: quantificazione del degrado dell'Hit Rate in LLC causato dai *Capacity Misses* per la contesa spaziale tra Dati e CounterChunks.
- [x] **STEP 3: Gestione Asincrona e Non-Bloccante (State Bouncing)**
  - [x] Progettazione della struttura di supporto temporanea (`AuthTBE` / `AuthTBETable`) per mappare le letture di memoria asincrone prevenendo lo stallo della LLC.
  - [x] Definizione degli stati transitori di coerenza (`I_Fetch_Auth`, `S_Fetch_Auth`, `E_Fetch_Auth`).
  - [x] Implementazione della logica "State Bouncing": integrazione di `wakeUpAll` e `recycleRequestQueue` per il coalescing dei duplicati e lo svuotamento deadlock-free delle code MSHR.

### FASE 2: Writeback e Compressione (IN CORSO)
- [x] **STEP 4: Cascading Writebacks (Evictions)**
  - [x] 4.1: Formalizzazione Stati Counter (`C_V` e `C_M`) per tracciare validità e sporcizia in LLC.
  - [x] 4.2: Intercettazione eventi `LLC_Replacement` per i Counter e logica di sfratto verso la RAM.
  - [x] 4.3: Sfratto di Dati in LLC con Counter-Hit.
  - [x] 4.4: Write-Allocate dei Counter: su sfratto Dati, se il Counter manca (`I`), sospensione (es. `M_Evict_Auth`), fetch dalla RAM, allocazione MRU e successivo sblocco del Writeback.
- [x] **STEP 5: Estensione alla Ricorsione Multilivello (L1->L2->L3)**
  - [x] 5.1: Estensione multilivello letture
  - [x] 5.2: Estensione multilivello scrittura
  - [x] 5.3: Estensione multilivello eviction

### FASE 3: Verifica e Convalida Finale (PIANIFICATA)
- [x] **STEP 6: Analisi di Sensibilità alla Latenza Crittografica**
  - [x] 6.1: Implementazione flag dinamico `is_ctr_mode` (ECB vs CTR) nel configuration layer (Python).
  - [x] 6.2: Iniezione asimmetrica delle latenze crittografiche per Dati vs Metadati nell'automa SLICC.
  - [x] 6.3: Automazione degli sweep (`13.run_crypto_latency_sweep.sh`) e generazione script Python per il plotting comparativo.
- [ ] **STEP 7: Esecuzione conclusiva dei benchmark**
