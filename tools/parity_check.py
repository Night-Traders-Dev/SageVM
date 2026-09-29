#!/usr/bin/env python3
"""Parity checking tool for Sage backends.

Usage:
    python3 parity_check.py <source.sage>
    python3 parity_check.py --expected <expected_output_file> <source.sage>

Runs a Sage source file through all available backends and
compares the outputs for consistency.
"""

import subprocess
import sys
import os
import argparse
import difflib

_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# The host SageLang is a submodule at .deps/SageLang, and this binary is at the
# repo root. These defaults used to point at <repo>/../core and <repo>/../sgvm,
# which assume SageVM is vendored inside a SageLang checkout -- in this layout
# neither path exists, so the ast and bytecode backends died with FileNotFound
# before running anything, and the sgvm backends looked for binaries that are
# not there. Both are overridable for the embedded arrangement.
SAGE_DIR = os.environ.get("SAGE_DIR", os.path.join(_REPO_ROOT, ".deps", "SageLang", "core"))
SAGE_EXECUTABLE = os.environ.get("SAGE_EXEC", "./sage")
SAGEVM_DIR = os.environ.get("SAGEVM_DIR", _REPO_ROOT)


def run_backend(source_file: str, backend: str) -> str:
    cmd = [os.path.join(SAGE_DIR, SAGE_EXECUTABLE), f"--runtime", backend, source_file]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    stdout = result.stdout
    stderr = result.stderr
    if result.returncode != 0 and not stdout:
        return f"ERROR({backend}): {stderr.strip()}"
    return stdout.strip()


def run_sgvm(source_file: str) -> str:
    out = "/tmp/_parity_out.sgvm"
    cmd = [os.path.join(SAGEVM_DIR, "sagevm"), "compile", source_file]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        return f"ERROR(sgvm-compile): {result.stderr.strip()}"
    # sagevm derives the artifact name from the source name, not from -o
    derived = os.path.splitext(source_file)[0] + ".sgvm"
    cmd2 = [os.path.join(SAGEVM_DIR, "sagevm"), "run", derived]
    result2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=30)
    if result2.returncode != 0 and not result2.stdout:
        return f"ERROR(sgvm-run): {result2.stderr.strip()}"
    return result2.stdout.strip()


def run_sgvmc(source_file: str) -> str:
    cmd = [os.path.join(SAGEVM_DIR, "sgvmc"), source_file, "/tmp/_parity_sgvmc_out.sgvm"]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        return f"ERROR(sgvmc-compile): {result.stderr.strip()}"
    cmd2 = [os.path.join(SAGEVM_DIR, "sagevm"), "run", "/tmp/_parity_sgvmc_out.sgvm"]
    result2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=30)
    if result2.returncode != 0 and not result2.stdout:
        return f"ERROR(sgvmc-run): {result2.stderr.strip()}"
    return result2.stdout.strip()


BACKENDS = {
    "ast": run_backend,
    "bytecode": run_backend,
}


def main():
    parser = argparse.ArgumentParser(description="Parity check across Sage backends")
    parser.add_argument("source", help="Sage source file to test")
    parser.add_argument("--expected", "-e", help="File containing expected output")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all outputs")
    parser.add_argument("--backends", "-b", nargs="+", default=list(BACKENDS.keys()),
                        choices=list(BACKENDS.keys()) + ["sgvm", "sgvmc"],
                        help="Backends to test (default: all)")
    args = parser.parse_args()

    if not os.path.isfile(args.source):
        print(f"Error: source file '{args.source}' not found", file=sys.stderr)
        sys.exit(1)

    expected = None
    if args.expected:
        if not os.path.isfile(args.expected):
            print(f"Error: expected output file '{args.expected}' not found", file=sys.stderr)
            sys.exit(1)
        with open(args.expected) as f:
            expected = f.read().strip()

    results = {}
    for backend in args.backends:
        if backend in BACKENDS:
            results[backend] = BACKENDS[backend](args.source, backend)
        elif backend == "sgvm":
            results[backend] = run_sgvm(args.source)
        elif backend == "sgvmc":
            results[backend] = run_sgvmc(args.source)

    if expected is not None:
        print(f"Expected output:\n{expected}\n")
        for backend, output in results.items():
            status = "OK" if output == expected else "DIFF"
            print(f"[{status}] {backend}")
            if output != expected:
                for line in difflib.unified_diff(
                    expected.splitlines(), output.splitlines(),
                    fromfile="expected", tofile=backend, lineterm=""
                ):
                    print(f"  {line}")
            if args.verbose:
                print(f"  Output:\n{output}\n")

    else:
        # No expected output: use first backend as reference
        ref_backend = args.backends[0]
        ref_output = results.get(ref_backend, "")
        print(f"Reference ({ref_backend}):\n{ref_output}\n")
        all_ok = True
        for backend, output in results.items():
            if backend == ref_backend:
                continue
            status = "OK" if output == ref_output else "DIFF"
            if status == "DIFF":
                all_ok = False
            print(f"[{status}] {backend} vs {ref_backend}")
            if output != ref_output:
                for line in difflib.unified_diff(
                    ref_output.splitlines(), output.splitlines(),
                    fromfile=ref_backend, tofile=backend, lineterm=""
                ):
                    print(f"  {line}")
            if args.verbose:
                print(f"  Output:\n{output}\n")

        if all_ok:
            print("All backends produce identical output.")
        else:
            print("WARNING: Some backends differ!")
            sys.exit(1)


if __name__ == "__main__":
    main()
