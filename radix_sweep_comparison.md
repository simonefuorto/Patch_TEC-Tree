# Confronto Risultati: Radix Sweep (ROI Multi-Thread)

La seguente tabella unificata mostrerà il confronto prestazionale completo (isolando la sola **Region of Interest (ROI)**) in ambiente Multi-Thread (4 Core) tra i protocolli standard e le tre policy di Tectree.

I risultati attualmente in lavorazione o pianificati per stanotte sono contrassegnati con un trattino (`-`).

---

## Dimensione Array: 131K (131072)

| Protocollo / Policy | ROI simTicks (Cicli) | ROI DRAM Read Reqs | ROI DRAM Write Reqs |
| :--- | :--- | :--- | :--- |
| **MESI_Two_Level** (Standard) | - | - | - |
| **TARDISTSO_Base** (No TEC-Tree) | - | - | - |
| **TARDIS_TECTREE (Pol0: Baseline)** | 4.676.850.000 | 96.539 | 53.841 |
| **TARDIS_TECTREE (Pol1: No Optim)** | - *(Run in loop)* | - | - |
| **TARDIS_TECTREE (Pol2: Ottimizzata)**| 4.716.673.500 | 100.600 | 56.067 |

## Dimensione Array: 65K (65536)

| Protocollo / Policy | ROI simTicks (Cicli) | ROI DRAM Read Reqs | ROI DRAM Write Reqs |
| :--- | :--- | :--- | :--- |
| **MESI_Two_Level** (Standard) | - | - | - |
| **TARDISTSO_Base** (No TEC-Tree) | - | - | - |
| **TARDIS_TECTREE (Pol0: Baseline)** | 2.324.335.500 | 29.572 | 17.897 |
| **TARDIS_TECTREE (Pol1: No Optim)** | 2.348.922.000 | 31.826 | 20.067 |
| **TARDIS_TECTREE (Pol2: Ottimizzata)**| 2.334.010.500 | 30.412 | 18.795 |

## Dimensione Array: 16K (16384)

| Protocollo / Policy | ROI simTicks (Cicli) | ROI DRAM Read Reqs | ROI DRAM Write Reqs |
| :--- | :--- | :--- | :--- |
| **MESI_Two_Level** (Standard) | - | - | - |
| **TARDISTSO_Base** (No TEC-Tree) | - | - | - |
| **TARDIS_TECTREE (Pol0: Baseline)** | 889.424.500 | 5.553 | 0 |
| **TARDIS_TECTREE (Pol1: No Optim)** | 889.424.500 | 5.553 | 0 |
| **TARDIS_TECTREE (Pol2: Ottimizzata)**| 889.424.500 | 5.553 | 0 |

> [!NOTE]
> **Stato Lavori:**
> Questa è la struttura ("scheletro") definitiva per la tesi. I dati mancanti (trattini) verranno riempiti non appena lanceremo l'ultimo script unificato che eseguirà MESI e TARDIS Base alle esatte stesse condizioni Multi-Thread.
