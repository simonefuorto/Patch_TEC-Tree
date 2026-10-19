# TARDISTSO_TECTREE: Implementazione e Valutazione in gem5

Repository ufficiale contenente la patch architetturale per il simulatore **gem5 (v23.1)** che integra l'albero crittografico di integrità e confidenzialità **TECTREE** all'interno del protocollo di coerenza ad affitti logici temporali **Tardis-TSO**.

Il progetto valuta l'impatto prestazionale, la contesa spaziale in LLC tra dati e metadati di sicurezza, la gestione asincrona degli stalli mediante *State Bouncing* e i benefici architetturali di diverse topologie ad arità dinamica e politiche di rimpiazzo MRU topology-aware.

---

## Indice
1. [Ambiente Portabile Docker (Ready-to-Run)](#1-ambiente-portabile-docker-ready-to-run)
2. [Guida Completa agli Script di Esecuzione (`script_run/`)](#2-guida-completa-agli-script-di-esecuzione-script_run)
   * [10.run_microbenchmarks.sh (Suite Microbenchmark)](#10run_microbenchmarkssh)
   * [8.run_radix_tectree_fixed.sh (Radix TECTREE Baseline)](#8run_radix_tectree_fixedsh)
   * [4.run_crypto_latency_sweep.sh (Sensibilità Latenza Crittografica)](#4run_crypto_latency_sweepsh)
   * [5.run_radix_arity_sweep.sh (Impatto Topologico dell'Arità)](#5run_radix_arity_sweepsh)
   * [6.run_radix_policy_arity_sweep.sh (Sweep Arità e Politiche MRU)](#6run_radix_policy_arity_sweepsh)
   * [7.run_radix_mesi.sh (Confronto con MESI Two-Level)](#7run_radix_mesish)
   * [9.run_radix_tardistso.sh (Confronto con Tardis-TSO Puro)](#9run_radix_tardistsosh)
3. [Script Python di Analisi e Plotting (`python_scripts/`)](#3-script-python-di-analisi-e-plotting-python_scripts)
4. [Compilazione Manuale da Host (Opzionale / No Docker)](#4-compilazione-manuale-da-host-opzionale--no-docker)
5. [Architettura Tecnica e Checklist di Implementazione](#5-architettura-tecnica-e-checklist-di-implementazione)

---

## 1. Ambiente Portabile Docker (Ready-to-Run)

Per evitare ore di configurazione delle dipendenze e di compilazione di gem5, l'intero ambiente è disponibile precompilato come immagine Docker sul **GitHub Container Registry (GHCR)**:
* **Immagine ufficiale:** `ghcr.io/simonefuorto/gem5-tectree:latest`
* **Contenuto:** Ubuntu 22.04, compilatore, librerie, binario `gem5.opt` (X86_TARDISTSO_TECTREE da 786 MB), sorgenti, patch TECTREE e tutti gli script pronti.
* **Working Directory predefinita:** `/workspace/GEM`

### Comandi di Avvio Universali (Linux, macOS, Windows PowerShell)

1. **Scaricare l'immagine:**
   ```bash
   docker pull ghcr.io/simonefuorto/gem5-tectree:latest
   ```

2. **Avviare il container interattivo:**
   ```bash
   docker run -it --name gem5_eval ghcr.io/simonefuorto/gem5-tectree:latest
   ```
   *(All'avvio atterrerai direttamente nella cartella `/workspace/GEM` con tutti i file).*

3. **Verificare la presenza dei componenti:**
   ```bash
   ls -la
   # Mostra: gem5/  patch_tectree/  microbenchmarks/  script di esecuzione
   ```

---

## 2. Guida Completa agli Script di Esecuzione (`script_run/`)

Tutti gli script di benchmarking ed esplorazione parametrica si trovano nella cartella:
```bash
cd patch_tectree/script_run
```

Di seguito la definizione puntuale di ogni esperimento, l'obiettivo architetturale, il comando da eseguire e i parametri testati.

---

### `10.run_microbenchmarks.sh`
* **Definizione dell'Esperimento:** Suite di validazione architetturale composta da tre microbenchmark sintetici progettati ad-hoc in C per testare isolatamente i singoli comportamenti del protocollo:
  1. **`ping_pong` (4 Thread):** 100.000 incrementi atomici concorrenti (`__sync_fetch_and_add`) su una singola riga di cache condivisa. Valida la coerenza basata su lease temporali di Tardis-TSO, l'assenza di deadlock e garantisce il 100% di **Auth Hit** in LLC.
  2. **`sweet_spot` (4 Thread):** 100.000 accessi pseudo-casuali (PRNG Xorshift) su un array da **2 MB** (pari all'esatta capacità della LLC). Quantifica la **contesa spaziale** (*Capacity Contention*): i contatori di sicurezza allocati in LLC sottraggono spazio utile ai dati, innescando miss di capacità.
  3. **`streaming` (1 Thread):** Scansione sequenziale in lettura e scrittura di un array da **4 MB** ($2 \times \text{LLC}$). Forza continui rimpiazzi in LLC, stressando le **Dirty Evictions** e il meccanismo ricorsivo di **Write-Allocate** dei contatori verso la DRAM negli stati `*_Evict_Auth`.
* **Comando:**
  ```bash
  ./10.run_microbenchmarks.sh
  ```
* **Parametri Configurabili da CLI:**
  * `-b <nome>`: esegue un solo test (`ping_pong`, `sweet_spot`, `streaming`).
  * `-p <protocol>`: specifica il protocollo (default `TARDISTSO_TECTREE`, confrontabile con `TARDISTSO`).
* **Output:** Stampa a video una tabella riepilogativa formattata con cicli `simTicks`, `DRAM Reads` e `DRAM Writes`. Salva le statistiche in:
  `gem5/results_microbench/stats_<benchmark>_<protocol>/stats.txt`

---

### `8.run_radix_tectree_fixed.sh`
* **Definizione dell'Esperimento:** Esecuzione del kernel di calcolo parallelo **Radix** (SPLASH-2) nella **configurazione di riferimento (Baseline TECTREE)** descritta nella tesi, valutando il comportamento al crescere della dimensione del problema.
* **Obiettivo:** Misurare il tempo di esecuzione (`ROI simTicks`) e il traffico verso la memoria DRAM in condizioni operative standard.
* **Parametri Fissi:**
  * Protocollo: `TARDISTSO_TECTREE`
  * Politica MRU: `Policy 2` (Topology-Aware Dinamica)
  * Arità dell'albero: `Arity 15`
  * Latenza crittografica: `10 cicli`
  * Modalità: `ECB` (`--is-ecb`)
  * Cache LLC (L2): `1 MB`, Memoria: `4 GB`, Thread: `4` (5 core totali)
  * Array Sizes testati: **16.384 (16K)**, **65.536 (65K)**, **131.072 (131K)**
* **Comando:**
  ```bash
  ./8.run_radix_tectree_fixed.sh
  ```
* **Output:** Genera le statistiche per ciascuna dimensione in:
  `gem5/results_radix/stats_TARDISTSO_TECTREE_Pol2_Arity15_Lat10_<SIZE>/stats.txt`

---

### `4.run_crypto_latency_sweep.sh`
* **Definizione dell'Esperimento:** Analisi di sensibilità alla latenza introdotta dai motori crittografici dedicati (AES Engine). Valuta la robustezza del sistema variando il ritardo dell'operazione crittografica e confronta i due modelli fondamentali:
  * **AES-CTR (Counter Mode):** Sfrutta il *Latency Hiding*. In caso di Auth-Hit, il keystream crittografico viene generato in parallelo al recupero del blocco dati dalla DRAM, azzerando la latenza crittografica sul cammino critico di lettura.
  * **AES-ECB (Electronic Codebook):** Latenza completamente esposta; la decifratura deve attendere l'intero blocco cifrato prima di iniziare.
* **Obiettivo:** Dimostrare che in modalità CTR le prestazioni rimangono stabili anche con pipeline crittografiche lente, mentre in ECB il sistema degrada proporzionalmente alla latenza.
* **Parametri Testati:**
  * Latenze crittografiche: `5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 100 cicli`
  * Array Size: `16384`, Arity: `15`, Thread: `2`
* **Comando:**
  ```bash
  # Esecuzione in modalità CTR (default, Policy 0):
  ./4.run_crypto_latency_sweep.sh 0 CTR

  # Esecuzione in modalità ECB (Policy 0):
  ./4.run_crypto_latency_sweep.sh 0 ECB

  # Con Policy 2 (Topology-Aware):
  ./4.run_crypto_latency_sweep.sh 2 CTR
  ```
* **Output:** Statistiche salvate in:
  `gem5/results_crypto_sweep_Pol<POLICY>_<MODE>/stats_crypto_<LATENZA>/stats.txt`

---

### `5.run_radix_arity_sweep.sh`
* **Definizione dell'Esperimento:** Studio dell'impatto topologico dell'**Arità dei nodi** ($A$, numero di contatori figli raggruppati per chunk di memoria da 64 Byte).
  * Con $A=15$: l'albero per 2 GB di RAM è profondo 6 livelli ($L_1 \rightarrow L_6$).
  * Con $A=31$: l'albero si appiattisce a 5 livelli.
  * Con $A=63$: l'albero collassa a soli 4 livelli.
* **Obiettivo:** Dimostrare il concetto di **Bandwidth Efficiency**: aumentando l'arità, un singolo trasferimento DRAM da 64 Byte autentica fino a 63 blocchi dati (circa 4 KB, un'intera pagina OS), riducendo drasticamente il numero di accessi DRAM ausiliari per la sicurezza.
* **Parametri Testati:**
  * Arità: `15`, `31`, `63`
  * Array Sizes: `16384 (16K)`, `65536 (65K)`, `131072 (131K)`
  * Policy: `Policy 0 (Baseline)`, Thread: `4`
* **Comando:**
  ```bash
  ./5.run_radix_arity_sweep.sh
  ```
* **Output:** Statistiche salvate in:
  `gem5/results_radix/stats_TARDISTSO_TECTREE_Pol0_arity_<ARITY>_size_<SIZE>/stats.txt`

---

### `6.run_radix_policy_arity_sweep.sh`
* **Definizione dell'Esperimento:** Sweep combinatorio completo tra le tre diverse **politiche di rimpiazzo MRU** in LLC e le diverse arità topologiche.
  * **Policy 0 (Baseline):** Gestione LRU/MRU standard uniforme; dati e metadati competono sulle stesse posizioni senza distinzione.
  * **Policy 1 (No-Optimization / Negative Control):** I nodi contatore non vengono marcati come MRU in lettura. Mostra il degrado causato dallo sfratto prematuro dei contatori caldi.
  * **Policy 2 (Topology-Aware Retention):** Politica dinamica avanzata in cui la probabilità di mantenere un contatore in MRU è proporzionale alla sua altezza nell'albero crittografico ($P \propto 3 + \text{level}$). I nodi superiori (più condivisi) restano blindati in LLC.
* **Parametri Testati:**
  * Combinazioni: 3 Politiche ($0, 1, 2$) $\times$ 3 Arità ($15, 31, 63$) $\times$ 3 Taglie Array ($16K, 65K, 131K$) = **27 configurazioni totali**.
* **Comando:**
  ```bash
  ./6.run_radix_policy_arity_sweep.sh
  ```
* **Output:** Statistiche salvate in:
  `gem5/results_radix/stats_TARDISTSO_TECTREE_Pol<POLICY>_arity_<ARITY>_size_<SIZE>/stats.txt`

---

### `7.run_radix_mesi.sh`
* **Definizione dell'Esperimento:** Esecuzione di Radix sul protocollo standard **MESI Two-Level** (coerenza basata su snooping/invalidazione tradizionale).
* **Obiettivo:** Fornire il termine di paragone dello stato dell'arte industriale per il confronto prestazionale della coerenza.
* **Comando:**
  ```bash
  ./7.run_radix_mesi.sh
  ```
  *(Richiede il binario `build/X86_MESI_Two_Level/gem5.opt`, compilabile tramite `3bis.build_standard.sh -p MESI_Two_Level`)*.
* **Output:** `gem5/results_radix/stats_MESI_Two_Level_<SIZE>/stats.txt`

---

### `9.run_radix_tardistso.sh`
* **Definizione dell'Esperimento:** Esecuzione di Radix sul protocollo **Tardis-TSO puro** (senza albero crittografico TECTREE e senza contatori di integrità).
* **Obiettivo:** Isolare l'**overhead puro della sicurezza**, calcolando esattamente quanti cicli e quanta banda DRAM aggiuntiva costa la protezione crittografica rispetto al protocollo di coerenza nativo.
* **Comando:**
  ```bash
  ./9.run_radix_tardistso.sh
  ```
* **Output:** `gem5/results_radix/stats_TARDISTSO_<SIZE>/stats.txt`

---

## 3. Script Python di Analisi e Plotting (`python_scripts/`)

All'interno della cartella `patch_tectree/python_scripts/` sono presenti gli script automatici per parsare i file `stats.txt` e generare le tabelle e i grafici pubblicati nella tesi:

```bash
cd patch_tectree/python_scripts
```

| Script Python | Descrizione e Dati Estratti |
| :--- | :--- |
| `1_Analisi_Sensitivita_Latenza_Crittografica.py` | Estrae e confronta i cicli di esecuzione tra CTR ed ECB al variare della latenza (da `results_crypto_sweep_*`). |
| `2_Impatto_Topologico_Arieta.py` | Calcola la *Bandwidth Efficiency*, il rapporto tra richieste DRAM per dati e metadati, e i cicli ROI per Arity 15, 31, 63. |
| `3_Strategie_Evizione.py` | Analizza l'efficacia di Policy 0 vs 1 vs 2 sul contenimento degli sfratti in LLC. |
| `3.4_benchmarking.py` | Tabella comparativa complessiva tra **MESI**, **Tardis-TSO standard** e **Tardis-TSO TECTREE**. |
| `4_Grafico_...` fino a `7_Grafico_...` | Genera i grafici a barre e a linee delle evizioni dirty, totali e dei dati per il dataset da 131K elementi. |

Per eseguire qualsiasi script di analisi:
```bash
python3 2_Impatto_Topologico_Arieta.py
```

---

## 4. Compilazione Manuale da Host (Opzionale / No Docker)

Se si desidera compilare gem5 direttamente sulla macchina host (richiede Ubuntu 22.04 x86_64, SCons, Python 3, g++ e le librerie di sviluppo):

1. **Installazione dipendenze:**
   ```bash
   ./script_run/1.install_requirements.sh
   ```
2. **Download e applicazione della patch su gem5:**
   ```bash
   ./script_run/2.install_gem5_tectree.sh
   ```
3. **Compilazione del protocollo TECTREE:**
   ```bash
   ./script_run/3.build_tectree.sh
   ```
   *(Compila `build/X86_TARDISTSO_TECTREE/gem5.opt` con supporto ai flag di sicurezza)*.
4. **Compilazione dei protocolli alternativi (per i confronti):**
   ```bash
   ./script_run/3bis.build_standard.sh -p TARDISTSO
   ./script_run/3bis.build_standard.sh -p MESI_Two_Level
   ```

---

## 5. Architettura Tecnica e Checklist di Implementazione

La patch estende il controller Directory/LLC di gem5 (`TARDISTSO_TECTREE-dir.sm`, circa 5.300 righe di codice SLICC) integrando:
* **Struttura Dati AuthTBE:** Tabella MSHR dedicata con 128 slot di attesa per coordinare le risalite asincrone dell'albero di autenticazione.
* **Stati di State Bouncing:** Nuovi stati transitori (`I_Fetch_Auth`, `S_Fetch_Auth`, `E_Fetch_Auth`, `M_Evict_Auth`) che consentono il coalescing delle richieste duplicate senza bloccare l'infrastruttura di coerenza.
* **Mappatura Dinamica in C++ (`RubySlicc_Util.hh`):** Calcolo dinamico degli indirizzi genitore `getParentAddrDynamic(addr, arity)` compatibile con qualsiasi arità senza sovrapposizione nello spazio indirizzi.

### Checklist di Avanzamento
- [x] **FASE 1: Architettura Base e Bouncing Asincrono**
  - [x] Strutture `CacheMemory` in Directory per ospitare CounterChunks (64 Byte).
  - [x] Transizioni non-bloccanti con `AuthTBE` e State Bouncing deadlock-free.
  - [x] Validazione con la suite di microbenchmark (`ping_pong`, `sweet_spot`, `streaming`).
- [x] **FASE 2: Writeback e Ricorsione Multilivello**
  - [x] Stati di tracciamento `C_V` (Valid) e `C_M` (Modified) per i nodi dell'albero.
  - [x] Intercettazione `LLC_Replacement` e Write-Allocate a cascata durante le evizioni dirty.
  - [x] Supporto alla risalita ricorsiva dell'albero ($L_1 \rightarrow L_6$).
- [x] **FASE 3: Modelli Crittografici ed Esplorazione Topologica**
  - [x] Flag configurabile `is_ctr_mode` (AES-CTR con Latency Hiding vs AES-ECB esposto).
  - [x] Supporto all'arità parametrica ($A=15, 31, 63$).
  - [x] Politiche di ritenzione cache MRU Topology-Aware (Policy 0, 1, 2).
  - [x] Automazione completa degli sweep di benchmark e benchmarking comparativo (MESI vs Tardis vs TECTREE).
- [x] **FASE 4: Portabilità e Rilascio**
  - [x] Containerizzazione Docker ufficiale su GitHub Container Registry (`ghcr.io/simonefuorto/gem5-tectree:latest`).
  - [x] Suite di microbenchmark con script di reportistica integrato (`10.run_microbenchmarks.sh`).
