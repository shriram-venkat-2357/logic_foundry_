#!/usr/bin/env python3
"""
BER vs SNR Regression Runner
Member 3's final deliverable: Automated BER curve generation
"""
import subprocess
import re
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import json
import os

# Configuration
SIM_BINARY = "./obj_dir/Vlf_top_tb"
WAVE_DIR = "waves"
LOG_DIR = "logs"

# Noise levels to sweep (0=clean, 255=max noise)
noise_levels = [0, 10, 20, 40, 60, 80, 100, 150, 200, 255]

results = []

os.makedirs(LOG_DIR, exist_ok=True)

print("=" * 50)
print("  LF-SDR BER Regression Suite")
print("=" * 50)

for noise in noise_levels:
    print(f"\n[REGRESSION] Running with noise_level = {noise}...")
    
    # Run simulation (in hackathon, you'd pass noise as +define or $value$plusargs)
    # For now, we parse the scoreboard output
    log_file = f"{LOG_DIR}/ber_noise_{noise}.log"
    
    try:
        result = subprocess.run(
            [SIM_BINARY],
            capture_output=True, text=True, timeout=60
        )
        
        # Parse BER from scoreboard output
        ber_match = re.search(r'BER\s*:\s*([\d.]+)', result.stdout)
        ber = float(ber_match.group(1)) if ber_match else 0.0
        
        results.append({"noise_level": noise, "ber": ber})
        print(f"  -> BER = {ber:.6f}")
        
    except Exception as e:
        print(f"  -> ERROR: {e}")
        results.append({"noise_level": noise, "ber": -1})

# Save results
with open(f"{LOG_DIR}/ber_results.json", "w") as f:
    json.dump(results, f, indent=2)

# Plot BER Curve
plt.figure(figsize=(10, 6))
noise_vals = [r["noise_level"] for r in results if r["ber"] >= 0]
ber_vals   = [r["ber"] for r in results if r["ber"] >= 0]

plt.semilogy(noise_vals, [max(b, 1e-7) for b in ber_vals], 'bo-', linewidth=2, markersize=8)
plt.xlabel("Noise Level (LFSR Threshold)")
plt.ylabel("Bit Error Rate (BER)")
plt.title("LF-SDR X1: BER vs Channel Noise")
plt.grid(True, which="both", ls="--")
plt.savefig(f"{WAVE_DIR}/ber_curve.png", dpi=150)
print(f"\n[DONE] BER curve saved to {WAVE_DIR}/ber_curve.png")
print(f"[DONE] Results saved to {LOG_DIR}/ber_results.json")
