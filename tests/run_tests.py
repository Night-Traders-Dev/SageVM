import os
import subprocess
import sys
import re

def run_suite():
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    test_dir = "tests"
    if not os.path.exists(test_dir):
        print(f"Error: {test_dir} directory not found.")
        return False

    test_files = [f for f in os.listdir(test_dir) if f.endswith(".sage") and not f.startswith("run_tests")]

    passed = 0
    failed = 0

    # Locate sage binary relative to the script
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sage_dir = os.path.join(repo_root, ".deps", "SageLang", "core")

    print("==================================================")
    print("           SageVM Coverage Test Suite             ")
    print("==================================================")

    for f in sorted(test_files):
        test_path = os.path.join(test_dir, f)
        expected_path = os.path.join(test_dir, f.replace(".sage", ".expected"))
        sgvm_path = os.path.join(test_dir, f.replace(".sage", ".sgvm"))

        # Compile
        env = os.environ.copy()
        env["PATH"] = sage_dir + os.pathsep + env.get("PATH", "")
        res = subprocess.run(["./sgvmc", test_path, sgvm_path], capture_output=True, text=True, env=env)
        if res.returncode != 0:
            print(f"[FAIL] {f} (Compilation failed)")
            print(res.stderr)
            failed += 1
            continue

        # Run
        run_cmd = ["./sgvm"]
        if f.startswith("security_"):
            run_cmd.append("--safe")
        res = subprocess.run(run_cmd + [sgvm_path], capture_output=True, text=True)

        # Filter out VM debug logs, status messages, and strip ANSI codes
        raw_stdout = ansi_escape.sub('', res.stdout)
        actual_lines = []
        for line in raw_stdout.splitlines():
            if line.startswith("DEBUG:"): continue
            if "🚀 Running" in line: continue
            if "🛠️ Compiling" in line: continue
            actual_lines.append(line)
        actual_output = "\n".join(actual_lines).strip()

        if not os.path.exists(expected_path):
            print(f"[SKIP] {f} (No .expected file)")
            if os.path.exists(sgvm_path): os.remove(sgvm_path)
            continue

        with open(expected_path, "r") as exp_file:
            expected_output = exp_file.read().strip()

        if actual_output == expected_output:
            print(f"[PASS] {f}")
            passed += 1
        else:
            print(f"[FAIL] {f}")
            print("--- Expected ---")
            print(expected_output)
            print("--- Actual ---")
            print(actual_output)
            failed += 1

        if os.path.exists(sgvm_path): os.remove(sgvm_path)

    print("==================================================")
    print(f"Summary: {passed} passed, {failed} failed")
    print("==================================================")

    return failed == 0

if __name__ == "__main__":
    if not run_suite():
        sys.exit(1)
