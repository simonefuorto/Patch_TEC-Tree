import os
import re

SIZES = [16384, 65536, 131072]
POLICIES = [0, 1, 2]
RESULTS_DIR = "../gem5/results_radix"

print("="*85)
print(f"{'DIMENSIONE ARRAY':<20} | {'POLICY 0 (Strict)':<20} | {'POLICY 1 (Std)':<20} | {'POLICY 2 (Opt)':<20}")
print("="*85)

for size in SIZES:
    evictions = {}
    for policy in POLICIES:
        stats_file = os.path.join(RESULTS_DIR, f"stats_TARDISTSO_TECTREE_Policy{policy}_{size}", "stats.txt")
        meta_dirty = "N/A"
        
        if os.path.exists(stats_file):
            try:
                with open(stats_file, "r") as f:
                    block_lines = []
                    for line in f:
                        if "---------- Begin Simulation Statistics ----------" in line:
                            block_lines = []
                        elif "---------- End Simulation Statistics   ----------" in line:
                            is_roi = any("numSyscalls" in b and " 0 " in b for b in block_lines)
                            if is_roi:
                                for b_line in block_lines:
                                    if "m_prefetch_misses" in b_line:
                                        meta_dirty = int(re.findall(r'\d+', b_line)[-1])
                                break 
                        else:
                            block_lines.append(line)
            except Exception:
                pass
        evictions[policy] = str(meta_dirty)
        
    print(f"{size:<20} | {evictions[0]:<20} | {evictions[1]:<20} | {evictions[2]:<20}")
    
print("="*85)
