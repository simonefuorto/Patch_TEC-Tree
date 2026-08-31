# Risultati Radix Sweep: Arity Dinamica (Policy 0 - Baseline)

Questi dati mostrano esclusivamente la performance della **Region of Interest (ROI)** per il benchmark Radix, isolandola dalle fasi di inizializzazione e verifica dell'array in C.

I test sono stati condotti con la **Policy 0 (Baseline del Tectree, senza ottimizzazioni MRU per i counter)** e con un carico di lavoro Multi-Thread a 4 Core. L'obiettivo è osservare come il variare dell'Arity (figli per nodo) influenzi il traffico verso la DRAM e il tempo di esecuzione complessivo.

## Confronto per Dimensione Array e Arity

| Dimensione Array | Arity (Figli per Nodo) | ROI simTicks (Cicli) | ROI DRAM Read Reqs | ROI DRAM Write Reqs |
| :--- | :--- | :--- | :--- | :--- |
| **16K (16384)** | 7 | 892.818.000 | 6.055 | 0 |
| | 15 | 880.002.000 | 5.554 | 0 |
| | 31 | 882.960.500 | 5.353 | 0 |
| | 63 | 888.131.500 | 5.265 | 0 |
| | | | | |
| **65K (65536)** | 7 | 2.423.388.500 | 37.566 | 23.430 |
| | 15 | 2.317.718.500 | 29.407 | 17.840 |
| | 31 | 2.287.121.000 | 26.382 | 15.614 |
| | 63 | 2.259.185.500 | 25.062 | 14.663 |
| | | | | |
| **131K (131072)** | 7 | 4.945.538.500 | 114.663 | 60.096 |
| | 15 | 4.677.220.500 | 96.467 | 53.788 |
| | 31 | 4.607.962.000 | 90.662 | 51.370 |
| | 63 | 4.560.740.500 | 87.958 | 50.036 |

> [!TIP]
> **Analisi Scaling dell'Arity:**
> Sui set di dati grandi (es. 131K), si osserva un fortissimo calo dei colli di bottiglia (DRAM requests) all'aumentare dell'arity.
> - **Arity 7:** L'albero è molto profondo (raggiunge molti più livelli per arrivare alla Root). La CPU fatica ad attraversare i livelli, causando ben **114.663** richieste di lettura alla DRAM e una latenza vicina a 4.95 Miliardi di tick.
> - **Arity 63:** Massimizza la *spatial locality* impacchettando ben 63 counter per linea di cache, rendendo l'albero bassissimo. Questo abbatte le letture DRAM a **87.958** (una riduzione netta del 23% rispetto ad Arity 7) e riduce il tempo di esecuzione a 4.56 Miliardi di tick.
> 
> L'allargamento dell'Arity è la chiave architetturale per abbattere in modo nativo il traffico generato dalla sicurezza.
