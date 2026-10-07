import os
import re

base_dir = "/Users/simonefuorto/Desktop/GEM/patch_tectree"
protocols = {
    "MESI_Two_Level": "results_radix[MESI_TWO_LEVEL]/results_radix/stats_MESI_Two_Level_{size}",
    "TARDISTSO": "radix_result[TARDISTSO]/radix_result[TARDISTSO]/stats_TARDISTSO_{size}",
    "TARDISTSO_TECTREE": "results_radix[TARDISTSO_TECTREE]/stats_TARDISTSO_TECTREE_Pol2_Arity15_Lat10_{size}"
}
sizes = ["16384", "65536", "131072"]

data = {}

for proto, path_template in protocols.items():
    data[proto] = {}
    for size in sizes:
        stats_file = os.path.join(base_dir, path_template.format(size=size), "stats.txt")
        
        ticks = 0
        dram_reqs = 0
        llc_reqs = 0
        
        if not os.path.exists(stats_file):
            print(f"Attenzione: File mancante per {proto} size {size} -> {stats_file}")
            data[proto][size] = None
            continue
            
        with open(stats_file, "r") as f:
            block_lines = []
            for line in f:
                if "---------- Begin Simulation Statistics ----------" in line:
                    block_lines = []
                elif "---------- End Simulation Statistics   ----------" in line:
                    is_roi = any("numSyscalls" in b and re.search(r'\b0\b', b) for b in block_lines)
                    has_insts = any("simInsts" in b and not " 0 " in b for b in block_lines)
                    
                    if is_roi or has_insts:
                        for b_line in block_lines:
                            if "simTicks " in b_line and "hostInstRate" not in b_line:
                                ticks = int(re.findall(r'\d+', b_line)[0])
                            elif "system.mem_ctrls.readReqs" in b_line or "system.mem_ctrls.writeReqs" in b_line:
                                val = int(re.findall(r'\d+', b_line.split()[1])[0])
                                dram_reqs += val
                            elif "L2cache.m_demand_accesses" in b_line:
                                val = int(re.findall(r'\d+', b_line.split()[1])[0])
                                llc_reqs += val
                            elif "system.ruby.dir_cntrl0.requestFromCache.m_msg_count" in b_line:
                                val = int(re.findall(r'\d+', b_line.split()[1])[0])
                                # Utilizzato come proxy per gli accessi condivisi/LLC in TARDISTSO
                                llc_reqs += val
                        break 
                else:
                    block_lines.append(line)
        
        data[proto][size] = {
            "ticks": ticks,
            "dram": dram_reqs,
            "llc": llc_reqs
        }

print("\n### Tabella Riepilogativa ROI Benchmark Radix\n")
print("| Protocollo | Array Size | Ticks (ROI) | Richieste DRAM | Richieste LLC/Dir | Overhead Ticks |")
print("| :--- | :--- | :--- | :--- | :--- | :--- |")

for size in sizes:
    # Trova il più veloce (baseline) per questa dimensione
    baseline_ticks = min(data[p][size]["ticks"] for p in protocols if data[p][size] is not None and data[p][size]["ticks"] > 0)
    
    for proto in protocols:
        if data[proto][size] is None:
            continue
            
        d = data[proto][size]
        overhead = ((d["ticks"] - baseline_ticks) / baseline_ticks) * 100
        
        llc_str = f"{d['llc']:,}" if d['llc'] > 0 else "N/A"
        
        print(f"| **{proto}** | {size} | {d['ticks']:,} | {d['dram']:,} | {llc_str} | {overhead:+.2f}% |")

