import os
import subprocess
import sys
import re

def run_suite():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sage_dir = os.path.join(repo_root, ".deps", "SageLang", "core")
    os.environ["TEST_ENV_VAR"] = "SageVM-Testing"
    os.environ["PATH"] = sage_dir + os.pathsep + os.environ.get("PATH", "")
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
    skipped = 0

    # Locate sage binary relative to the script
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sage_dir = os.path.join(repo_root, ".deps", "SageLang", "core")

    print("==================================================")
    print(f"  SageVM Coverage Test Suite ({target_label})  ")
    print("==================================================")

    for f in sorted(test_files):
        # Skip srvm specific test in non-RISC-V mode.
        if not use_riscv and f == "test_srvm.sage":
            continue

        # Skip generators.sage on SVM as sage --emit-vm frontend does not emit VM bytecode for yield statements
        if not use_riscv and f == "generators.sage":
            print(f"[SKIP] {f} (sage --emit-vm frontend does not emit VM bytecode for yield statements)")
            skipped += 1
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
            skipped += 1
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

    # The loop above feeds sgvmc pre-emitted .svm files, so it never exercises the
    # branch where sgvmc is handed a .sage source and has to shell out to
    # `sage --emit-vm` itself. That branch was broken for as long as it existed:
    # the command it built quoted its paths, and SageLang's sys.exec() rejects the
    # quote character, so every call failed with "Unsafe characters in command"
    # and "Failed to generate SVM" while all 158 tests stayed green. Check it
    # directly.
    if not use_riscv:
        src_probe = os.path.join(test_dir, "source_compile_probe.sage")
        probe_bin = os.path.join(test_dir, "source_compile_probe.sgvm")
        probe_src = 'print "source compile probe"\n'
        try:
            with open(src_probe, "w") as f:
                f.write(probe_src)
            res = subprocess.run(["./sgvmc", src_probe, probe_bin],
                                 capture_output=True, text=True, env=os.environ)
            produced = os.path.exists(probe_bin) and os.path.getsize(probe_bin) > 0
            if res.returncode == 0 and produced:
                run = subprocess.run(["./sagevm", "run", probe_bin],
                                     capture_output=True, text=True, env=os.environ)
                if "source compile probe" in run.stdout:
                    print("[PASS] source_compile_probe.sage")
                    passed += 1
                else:
                    print("[FAIL] source_compile_probe.sage")
                    print("--- compiled from source but did not run correctly ---")
                    print(ansi_escape.sub("", run.stdout))
                    print(ansi_escape.sub("", run.stderr))
                    failed += 1
            else:
                print("[FAIL] source_compile_probe.sage")
                print("--- sgvmc could not compile a .sage source ---")
                print(ansi_escape.sub("", res.stdout))
                print(ansi_escape.sub("", res.stderr))
                failed += 1
        finally:
            for p in (src_probe, probe_bin, probe_bin + ".svm",
                      src_probe + ".svm"):
                if os.path.exists(p):
                    os.remove(p)

    # Tests under tests/native/ run on the interpreter rather than the VM, because
    # they read whole files from disk and assert on runtime behaviour that VM
    # bytecode does not model. os.listdir above is not recursive, so they are not in
    # the main loop; run them here so they are not orphaned.
    native_dir = os.path.join(test_dir, "native")
    if os.path.isdir(native_dir):
        for nf in sorted(os.listdir(native_dir)):
            if not nf.endswith(".sage"):
                continue
            npath = os.path.join(native_dir, nf)
            nenv = os.environ.copy()
            nenv["SAGE_PATH"] = os.pathsep.join([
                "src", "src/svm", "src/srvm", "src/jit",
                os.path.join(repo_root, ".deps", "SageLang", "core", "lib"),
            ])
            res = subprocess.run(["sage", "--runtime", "bytecode", npath],
                                 capture_output=True, text=True, env=nenv, cwd=repo_root)
            out = ansi_escape.sub("", res.stdout or "")
            if res.returncode == 0 and "SOME TESTS FAILED" not in out:
                print(f"[PASS] native/{nf}")
                passed += 1
            else:
                print(f"[FAIL] native/{nf}")
                print(out)
                print(ansi_escape.sub("", res.stderr or ""))
                failed += 1

    print("==================================================")
    print(f"Summary: {passed} passed, {failed} failed, {skipped} skipped")
    print("==================================================")

    return failed == 0

if __name__ == "__main__":
    if not run_suite():
        sys.exit(1)
