import os
import subprocess
import sys
import re

def run_suite():
    os.environ["TEST_ENV_VAR"] = "SageVM-Testing"
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    test_dir = "tests"
    if not os.path.exists(test_dir):
        print(f"Error: {test_dir} directory not found.")
        return False

    use_riscv = "--riscv" in sys.argv or "--target=srvm" in sys.argv or "srvm" in sys.argv
    use_jit = "--jit" in sys.argv

    ext = ".sgrv" if use_riscv else ".sgvm"
    target_label = "SRVM (RISC-V)" if use_riscv else "SVM (Stack)"
    if use_jit:
        target_label += " [JIT Active]"

    test_files = [f for f in os.listdir(test_dir) if f.endswith(".sage") and not f.startswith("run_tests")]

    passed = 0
    failed = 0

    # Locate sage binary relative to the script
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sage_dir = os.path.join(repo_root, ".deps", "SageLang", "core")

    print("==================================================")
    print(f"  SageVM Coverage Test Suite ({target_label})  ")
    print("==================================================")

    for f in sorted(test_files):
        if not use_riscv and f == "test_srvm.sage":
            continue
        test_path = os.path.join(test_dir, f)
        expected_path = os.path.join(test_dir, f.replace(".sage", ".expected"))
        bin_path = os.path.join(test_dir, f.replace(".sage", ext))

        # Compile
        env = os.environ.copy()
        env["PATH"] = sage_dir + os.pathsep + env.get("PATH", "")

        svm_path = test_path.replace(".sage", ".svm")
        subprocess.run(["sage", "--emit-vm", test_path, "-o", svm_path], env=env, capture_output=True)

        if not os.path.exists(svm_path):
            print(f"[FAIL] {f} (SVM emission failed)")
            failed += 1
            continue

        compile_cmd = ["./sgvmc", svm_path, bin_path]
        if use_riscv:
            compile_cmd.append("--riscv")

        res = subprocess.run(compile_cmd, capture_output=True, text=True, env=env)

        if os.path.exists(svm_path):
            os.remove(svm_path)

        if res.returncode != 0:
            print(f"[FAIL] {f} (Compilation failed)")
            print(res.stderr)
            failed += 1
            continue

        # Run
        run_cmd = ["./sgvm"]
        if use_riscv:
            run_cmd.append("--riscv")
        if use_jit:
            run_cmd.append("--jit")
        if f.startswith("security_"):
            run_cmd.append("--safe")
        if "no_exec" in f:
            run_cmd.append("--no-exec")
        res = subprocess.run(run_cmd + [bin_path], capture_output=True, text=True)

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
            if os.path.exists(bin_path): os.remove(bin_path)
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

        if os.path.exists(bin_path): os.remove(bin_path)

    print("==================================================")
    print(f"Summary: {passed} passed, {failed} failed")
    print("==================================================")

    return failed == 0

if __name__ == "__main__":
    if not run_suite():
        sys.exit(1)
