import os
import subprocess
import sys

def run_tests():
    test_dir = "tests"
    if not os.path.exists(test_dir):
        print(f"Error: {test_dir} directory not found.")
        return False

    test_files = [f for f in os.listdir(test_dir) if f.endswith(".sage")]
    if not test_files:
        print("No tests found.")
        return True

    passed = 0
    failed = 0

    print("==================================================")
    print("            SageVM Automated Test Suite            ")
    print("==================================================")
    print(f"Found {len(test_files)} tests to execute.\n")

    for f in sorted(test_files):
        test_path = os.path.join(test_dir, f)
        expected_path = os.path.join(test_dir, f.replace(".sage", ".expected"))
        sgvm_path = os.path.join(test_dir, f.replace(".sage", ".sgvm"))

        if not os.path.exists(expected_path):
            print(f"  [SKIP] {f} (Missing .expected file)")
            continue

        # 1. Compile
        try:
            subprocess.run(["./sgvmc", test_path, sgvm_path], check=True, capture_output=True)
        except subprocess.CalledProcessError as e:
            print(f"  [FAIL] {f} (Compilation failed)")
            print(e.stderr.decode())
            failed += 1
            continue

        # 2. Run
        try:
            result = subprocess.run(["./sgvm", sgvm_path], capture_output=True, text=True)
            actual_output = result.stdout
            actual_exit_code = result.returncode

            # Remove DEBUG lines from actual output
            filtered_output = "\n".join([line for line in actual_output.splitlines() if not line.startswith("DEBUG:")])
            if filtered_output and not filtered_output.endswith("\n"):
                filtered_output += "\n"

            with open(expected_path, "r") as exp_file:
                expected_lines = exp_file.readlines()

            # Expected exit code is on the first line if it starts with EXIT_CODE:
            expected_exit_code = 0
            expected_output = ""
            if expected_lines and expected_lines[0].startswith("EXIT_CODE:"):
                expected_exit_code = int(expected_lines[0].split(":")[1].strip())
                expected_output = "".join(expected_lines[1:])
            else:
                expected_output = "".join(expected_lines)

            if filtered_output == expected_output and actual_exit_code == expected_exit_code:
                print(f"  [PASS] {f}")
                passed += 1
            else:
                print(f"  [FAIL] {f}")
                if filtered_output != expected_output:
                    print("    --- Expected Output ---")
                    print(expected_output)
                    print("    --- Actual Output ---")
                    print(filtered_output)
                if actual_exit_code != expected_exit_code:
                    print(f"    --- Expected Exit Code: {expected_exit_code} ---")
                    print(f"    --- Actual Exit Code: {actual_exit_code} ---")
                print("    ----------------")
                failed += 1
        except Exception as e:
            print(f"  [FAIL] {f} (Execution error: {str(e)})")
            failed += 1
        finally:
            if os.path.exists(sgvm_path):
                os.remove(sgvm_path)

    print("\n==================================================")
    print("Test Summary:")
    print(f"  Passed: {passed}")
    print(f"  Failed: {failed}")
    print("==================================================")

    return failed == 0

if __name__ == "__main__":
    success = run_tests()
    if not success:
        sys.exit(1)
