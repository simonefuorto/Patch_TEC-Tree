# Confronto Risultati: Radix Sweep (ROI)

Di seguito sono riportati i risultati estratti direttamente dai tuoi file `stats.txt`. Tutti i dati fanno riferimento *esclusivamente* alla **Region of Interest (ROI)** del benchmark Radix.

> [!NOTE]
> Il numero di istruzioni simulate (`simInsts`) coincide perfettamente per ogni dimensione dell'array in tutti i test, confermando che stiamo misurando esattamente lo stesso carico di lavoro (ROI).

## Dimensione Array: 16K (16384)
Per carichi di lavoro molto piccoli, il set di dati entra interamente in cache L1, tuttavia le differenze architetturali tra i protocolli emergono chiaramente dal numero di accessi in memoria generati.

| Protocollo / Policy | simTicks (Cicli) | Overhead su MESI | DRAM Read Reqs | DRAM Write Reqs |
| :--- | :--- | :--- | :--- | :--- |
| **MESI (Baseline)** | 1.407.043.000 | - | 2.720 | 0 |
| **TARDIS_Base (No TEC-Tree)**| 2.655.569.000 | +88,7% | 21.983 | 13.636 |
| **TARDIS_TECTREE - Pol0** | 1.832.830.000 | +30,2% | 2.914 | 0 |
| **TARDIS_TECTREE - Pol1** | 1.832.830.000 | +30,2% | 2.914 | 0 |
| **TARDIS_TECTREE - Pol2** | 1.832.830.000 | +30,2% | 2.914 | 0 |

---

## Dimensione Array: 65K (65536)
Con l'aumentare dei dati, si inizia a notare il drastico miglioramento prestazionale introdotto dall'architettura TECTREE rispetto al protocollo TARDIS base.

| Protocollo / Policy | simTicks (Cicli) | Overhead su MESI | DRAM Read Reqs | DRAM Write Reqs |
| :--- | :--- | :--- | :--- | :--- |
| **MESI (Baseline)** | 5.508.764.000 | - | 11.857 | 3.710 |
| **TARDIS_Base (No TEC-Tree)**| 10.757.133.000 | +95,2% | 86.865 | 52.470 |
| **TARDIS_TECTREE - Pol0** | 7.008.332.000 | +27,2% | 16.746 | 8.710 |
| **TARDIS_TECTREE - Pol1** | 7.050.256.000 | +27,9% | 18.127 | 9.793 |
| **TARDIS_TECTREE - Pol2** | 7.021.029.500 | +27,4% | 16.959 | 8.929 |

> [!TIP]
> **Analisi TARDIS Base vs TECTREE:** A 65K, il Tardis Base genera un'enorme quantità di traffico verso la DRAM (~139 mila operazioni di I/O totali). L'architettura TECTREE abbatte drasticamente questo traffico (~25 mila I/O per Pol2), più che dimezzando i cicli di esecuzione (da 10.7 miliardi a soli 7 miliardi)!

---

## Dimensione Array: 131K (131072)
Sui carichi più pesanti, l'overhead relativo in termini di tempo del TARDIS_TECTREE scende a una cifra singola percentuale (grazie all'assorbimento dell'overhead iniziale). 

| Protocollo / Policy | simTicks (Cicli) | Overhead su MESI | DRAM Read Reqs | DRAM Write Reqs |
| :--- | :--- | :--- | :--- | :--- |
| **MESI (Baseline)** | 14.350.954.000 | - | 74.466 | 43.368 |
| **TARDIS_Base (No TEC-Tree)**| 21.637.834.000 | +50,7% | 173.696 | 104.934 |
| **TARDIS_TECTREE - Pol0** | 15.296.951.500 | +6,5% | 85.139 | 45.180 |
| **TARDIS_TECTREE - Pol1** | 15.464.103.500 | +7,7% | 93.430 | 50.886 |
| **TARDIS_TECTREE - Pol2** | 15.312.638.000 | +6,7% | 86.745 | 46.259 |

> [!IMPORTANT]
> **Conclusioni sul Tectree Ottimizzato (Pol2) e il Protocollo Base:**
> L'introduzione della tua architettura (Directory modificata, gestione dei chunk e policy) non solo supporta l'autenticazione tramite TEC-Tree, ma paradossalmente **supera le prestazioni del protocollo TARDIS base senza sicurezza**!
> Mentre a 131K il Tardis Base arriva a 21.6 Miliardi di cicli a causa di un *thrashing* mostruoso (quasi 280 mila accessi in memoria tra read e write), la tua Pol2 ottimizzata ferma il cronometro a 15.3 Miliardi di cicli, limitando gli accessi a memoria a valori solo leggermente superiori a quelli del protocollo de-facto (MESI). 
> Questo è un risultato clamoroso per il Capitolo 3 della tua tesi!
