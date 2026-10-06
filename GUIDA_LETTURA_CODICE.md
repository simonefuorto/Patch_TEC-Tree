# Guida Architetturale e Mappa del Codice: TARDIS-TSO Tectree

Questa repository contiene la patch architetturale per il simulatore **gem5**, focalizzata sull'integrazione del protocollo di integrità della memoria **TEC-Tree** all'interno del protocollo di coerenza **Tardis TSO**. 

L'obiettivo primario del progetto di tesi è la valutazione dell'impatto prestazionale, la gestione asincrona degli stati e l'analisi dei compromessi (trade-off) architetturali introdotti dalla gestione hardware dei metadati crittografici (Counter Chunks) nell'Ultimo Livello di Cache (LLC). In particolare, il progetto esplora:
- **Analisi di Sensitività alla Latenza Crittografica:** Confronto prestazionale tra il paradigma AES-CTR (con Latency Hiding) e il paradigma AES-ECB.
- **Impatto Topologico e Arity Dinamica:** Come la variazione del fattore di ramificazione (Arity) influenza la profondità dell'albero crittografico, i Ticks di simulazione e la larghezza di banda (Bandwidth Efficiency).
- **Evizioni Strategiche:** Mitigazione del *Capacity Miss* e del *Thrashing* in LLC tramite l'iniezione sperimentale di politiche MRU per la ritenzione dei metadati crittografici.

Per facilitare l'estrazione incontaminata delle statistiche, tutti i benchmark analizzati includono le **Magic Instructions**, permettendo a gem5 di isolare esclusivamente la *Region of Interest* (ROI) del programma, escludendo le fasi di allocazione del SO.

---

## Struttura della Repository e Automazione Sperimentale

Tutti gli strumenti per validare, compilare ed estrarre i grafici del progetto sono stati riorganizzati logicamente in due cartelle principali: `script_run/` e `python_scripts/`.

### 1. Cartella `script_run/` (Automazione ed Esecuzione)
Questa cartella contiene tutti gli script Bash per inizializzare l'ambiente ed eseguire gli sweep di simulazione citati nella Tesi. Gli script sono eseguiti in rigoroso ordine numerico:

* **Setup e Compilazione:**
  * `1.install_requirements.sh`: Installa le dipendenze di base del sistema necessarie alla compilazione di gem5.
  * `2.install_gem5_tectree.sh`: Applica la patch del TEC-Tree sulla base standard di gem5.
  * `3.build_tectree.sh`: Lancia il compilatore `scons` per buildare il simulatore con il protocollo personalizzato (`TARDISTSO_TECTREE`).

* **Esperimenti (Capitolo 3 della Tesi):**
  * `4.run_crypto_latency_sweep.sh`:  Esegue la suite di test per l'**Analisi di Sensitività alla Latenza Crittografica**, forzando il simulatore nei paradigmi CTR e ECB al variare della latenza hardware.
  * `5.run_radix_arity_sweep.sh`:  Esegue i test per l'**Impatto Topologico**, lanciando il benchmark *Radix Sort* sotto forte stress (16K, 64K, 131K elementi) spazzolando dinamicamente i valori di Arity dell'albero crittografico (15, 31, 63).

*(Gli script obsoleti o di microbenchmarking secondari sono stati conservati all'interno della sottocartella `script_run/archive/` per eventuali run futuri).*

---

### 2. Cartella `python_scripts/` (Estrazione Dati e Grafici)
Questa cartella contiene gli script Python sviluppati ad-hoc per il parsing dei pesantissimi file `stats.txt` di gem5 (estraendo unicamente la ROI) e generare le Tabelle/Grafici presenti nel Capitolo 3.
Gli script sono stati rinominati per ricalcare i nomi dei paragrafi della tesi:

* `1_Analisi_Sensitivita_Latenza_Crittografica.py`: (Ex `plot_ctr_vs_ecb.py`). Genera il grafico comparativo (Figura 3.1) che mostra la divergenza temporale tra il Latency Hiding del paradigma CTR e l'esposizione fatale della latenza nel paradigma ECB.
* `2_Impatto_Topologico_Arieta.py`: (Ex `print_arity_table.py`). Estrae e formatta i dati per le 3 tabelle della Tesi: Ticks della ROI, accessi in lettura ai metadati (Meta Read) e Bandwidth Efficiency (% DRAM su Tot. Mem).
* `3_Strategie_Evizione.py`: (Ex `print_evictions_table.py`). Tabula il traffico in uscita dalla LLC in condizioni estreme (size 131K), differenziando tra Evizioni Pulite, Sporche, e il numero di Stalli dovuti all'Auth Miss crittografico (che dimostrano matematicamente l'efficienza della policy MRU per i metadati).



---

## Mappa Architetturale SLICC (Per Sviluppatori)

Il nucleo delle modifiche C++/SLICC si trova nel file `src/learning_gem5/tardis_tso_tectree/TARDISTSO_TECTREE-dir.sm`. Nel codice sorgente sono stati sparsi dei tag di ricerca (`[REF: NOME_TAG]`) per localizzare rapidamente la logica:

1. **Tree Math & Topologia (`[REF: TREE_MATH]`)**
   Tutta l'aritmetica dei nodi (es. `getParentAddrDynamic(addr, tectree_arity)`) per calcolare istantaneamente le dipendenze padre-figlio.
2. **Root Array Dinamico (`[REF: ROOT_ARRAY_LOGIC]`)**
   Partizionamento spaziale dell'array e gestione degli aggiornamenti in testa all'albero di sicurezza.
3. **State Bouncing (Asincronia) (`[REF: STATE_BOUNCING]`)**
   L'introduzione della tabella delle transazioni pendenti `AuthTBEs` accoppiata a stati di stallo transitori (es. `I_Fetch_Auth`) per prevenire il deadlock durante l'attesa dei contatori dalla RAM principale.
4. **MRU Topology-Aware (`[REF: TECTREE_MRU_POLICY]`)**
   In `src/mem/ruby/structures/CacheMemory.cc`, alterazione logica della priorità di ritenzione per blindare i blocchi contenenti i metadati nell'L2 Cache.

---

## Benchmarking: TARDISTSO-TECTREE vs MESI_TWO_LEVEL VS TARDISTSO

Per fornire un punto di riferimento neutrale e confrontare oggettivamente l'overhead crittografico introdotto dall'hardware TARDISTSO_TECTREE, è stato eseguito il benchmark Radix sul protocollo standard `MESI_Two_Level`.

Il test è stato configurato a parità di risorse architetturali (Memoria Principale: 3GB, LLC: 1MB, Core Logici: 4), disattivando completamente la topologia ad albero e le policy MRU custom.

Di seguito sono riportati i risultati isolati nella *Region of Interest* (ROI), misurati in cicli di clock simulati (`simTicks`):

| Protocollo | 16.384 | 65.536 | 131.072 |
| :--- | :--- | :--- | :--- |
| **MESI_Two_Level** | 1.516.319.000 | 5.702.614.000 | 11.286.742.500 |
| **TARDISTSO** | 1.773.384.000 | 6.698.350.500 | 13.289.184.500 |
| **TARDISTSO_TECTREE** (Pol2, Lat10, Ari15) | 2.356.112.000 | 9.001.348.000 | 17.860.314.000 |

Questi valori "in purezza" (senza crittografia) permettono di quantificare matematicamente il compromesso prestazionale (overhead) introdotto inevitabilmente dall'estrazione asincrona e dalla validazione continua dei counter crittografici nell'architettura blindata.
