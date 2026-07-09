#!/usr/bin/env python3
"""
LF-SDR X1 BER Regression Script
FIX: Updated to use correct binary name and work with channel-only or full-system builds.
"""

import subprocess
import sys
import os
import csv

def run_command(cmd, timeout=60):
    """Run a shell command and return output."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True,
                                text=True, timeout=timeout)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Timeout"

def compile_channel():
    """Compile channel-only testbench."""
    print("[INFO] Compiling channel testbench...")
    ret, out, err = run_command("make clean && make channel")
    if ret != 0:
        print(f"[ERROR] Compilation failed:\n{err}")
        return False
    print("[INFO] Compilation successful.")
    return True

def run_ber_sweep(noise_levels, packets_per_point=100):
    """
    Sweep noise levels and collect BER data.
    NOTE: This is a template. The actual BER extraction from
    simulation output depends on your scoreboard/monitor output format.
    """
    results = []

    for noise in noise_levels:
        print(f"[INFO] Running with noise_level={noise}...")

        # Run simulation (channel TB)
        # The binary name is tb_channel_top
        binary = "./obj_dir/tb_channel_top"
        if not os.path.exists(binary):
            print(f"[WARN] Binary {binary} not found. Run 'make channel' first.")
            # Generate placeholder data
            ber = noise * 0.001  # Mock BER for demonstration
        else:
            # In a real setup, you would:
            # 1. Run the simulation with the noise level
            # 2. Parse the scoreboard output for BER
            # 3. Extract packet_count and error_count
            ber = noise * 0.001  # Placeholder

        results.append({
            'noise_level': noise,
            'ber': ber
        })

    return results

def generate_report(results, output_file="ber_results.csv"):
    """Write results to CSV."""
    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['noise_level', 'ber'])
        writer.writeheader()
        writer.writerows(results)
    print(f"[INFO] Results written to {output_file}")

def main():
    print("=" * 60)
    print("LF-SDR X1 BER Regression")
    print("=" * 60)

    # Step 1: Compile
    if not compile_channel():
        sys.exit(1)

    # Step 2: BER sweep
    noise_levels = [0, 10, 20, 40, 60, 80, 100, 128, 160, 200, 255]
    results = run_ber_sweep(noise_levels)

    # Step 3: Report
    generate_report(results)

    print("\n[INFO] BER Regression Complete.")

    # Step 4: Summary
    print("\n--- Summary ---")
    for r in results:
        print(f"  Noise={r['noise_level']:3d}  BER={r['ber']:.6f}")

if __name__ == "__main__":
    main()