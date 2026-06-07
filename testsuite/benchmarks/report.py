import json
import os
import sys

RESULTS_DIR = "testsuite/benchmarks/results"

def load_results():
    results = {}
    if not os.path.exists(RESULTS_DIR):
        return results
    for filename in os.listdir(RESULTS_DIR):
        if filename.endswith(".json"):
            with open(os.path.join(RESULTS_DIR, filename), 'r') as f:
                data = json.load(f)
                key = f"{data['benchmark']}_{data['runtime']}"
                results[key] = data['duration_ms']
    return results

def compare(baseline_file="baseline.json"):
    current = load_results()
    if not os.path.exists(baseline_file):
        print(f"No baseline found at {baseline_file}. Saving current results as baseline.")
        with open(baseline_file, 'w') as f:
            json.dump(current, f, indent=4)
        return

    with open(baseline_file, 'r') as f:
        baseline = json.load(f)

    print(f"{'Benchmark':<30} | {'Baseline (ms)':<15} | {'Current (ms)':<15} | {'Diff (%)':<10}")
    print("-" * 80)
    for key, current_val in current.items():
        if key in baseline:
            base_val = baseline[key]
            diff = ((current_val - base_val) / base_val) * 100
            print(f"{key:<30} | {base_val:<15} | {current_val:<15} | {diff:>+9.2f}%")
        else:
            print(f"{key:<30} | {'N/A':<15} | {current_val:<15} | {'N/A':<10}")

if __name__ == "__main__":
    compare()
