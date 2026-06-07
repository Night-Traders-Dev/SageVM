#!/usr/bin/env python3
"""diff_bytecode.py - Phase 2 diagnostic tool for SageVM compiler debugging.

Usage:
  # Capture DIAG output from interpreted vs compiled mode:
  sage src/sgvm_compiler_debug.sage testsuite/test_class.sage /tmp/interp.sgvm 2>/tmp/interp.diag
  ./sgvmc_debug testsuite/test_class.sage /tmp/compiled.sgvm 2>/tmp/compiled.diag

  # Diff the DIAG traces:
  python3 tools/diff_bytecode.py /tmp/interp.diag /tmp/compiled.diag

  # Hex-dump and diff the output .sgvm files:
  python3 tools/diff_bytecode.py --hex /tmp/interp.sgvm /tmp/compiled.sgvm
"""
import sys
import argparse


def parse_diag(path):
    """Parse DIAG lines from stderr capture."""
    entries = []
    with open(path) as f:
        for line in f:
            line = line.rstrip()
            if line.startswith("DIAG "):
                entries.append(line)
    return entries


def diff_diag(path_a, path_b):
    a = parse_diag(path_a)
    b = parse_diag(path_b)

    max_len = max(len(a), len(b))
    first_diff = None
    diff_count = 0

    print(f"{'Step':<6} {'INTERPRETED':<60} {'COMPILED':<60} {'MATCH':<5}")
    print("-" * 130)

    for i in range(max_len):
        la = a[i] if i < len(a) else "<MISSING>"
        lb = b[i] if i < len(b) else "<MISSING>"
        match = "OK" if la == lb else "DIFF"
        if match == "DIFF":
            diff_count += 1
            if first_diff is None:
                first_diff = i
        marker = "***" if match == "DIFF" else "   "
        print(f"{marker}{i:<3} {la:<60} {lb:<60} {match:<5}")

    print()
    if diff_count == 0:
        print("[PASS] All DIAG lines match. Compiled and interpreted outputs are identical.")
    else:
        print(f"[FAIL] {diff_count} differences found. First divergence at step {first_diff}.")
        print(f"       Interpreted: {a[first_diff] if first_diff < len(a) else '<MISSING>'}")
        print(f"       Compiled:    {b[first_diff] if first_diff < len(b) else '<MISSING>'}")
        print()
        print("Root cause hint: check the opcode and operand values at the divergence step.")
        print("If j_after differs, the compiled binary is mis-advancing the stream pointer.")
        print("If global_idx differs, the compiled const map lookup produces wrong results.")


def hex_dump(data, width=16):
    lines = []
    for i in range(0, len(data), width):
        chunk = data[i:i+width]
        hex_part = " ".join(f"{b:02x}" for b in chunk)
        ascii_part = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        lines.append(f"  {i:06x}  {hex_part:<{width*3}}  {ascii_part}")
    return lines


def diff_hex(path_a, path_b):
    with open(path_a, "rb") as f:
        data_a = f.read()
    with open(path_b, "rb") as f:
        data_b = f.read()

    lines_a = hex_dump(data_a)
    lines_b = hex_dump(data_b)

    print(f"File A: {path_a} ({len(data_a)} bytes)")
    print(f"File B: {path_b} ({len(data_b)} bytes)")
    print()

    max_lines = max(len(lines_a), len(lines_b))
    diff_count = 0
    first_diff_offset = None

    print(f"{'OFFSET':<10} {'INTERPRETED':<55} {'COMPILED':<55} MATCH")
    print("-" * 130)
    for i in range(max_lines):
        la = lines_a[i] if i < len(lines_a) else "<SHORT>"
        lb = lines_b[i] if i < len(lines_b) else "<SHORT>"
        match = la == lb
        if not match:
            diff_count += 1
            if first_diff_offset is None:
                first_diff_offset = i * 16
        marker = "***" if not match else "   "
        print(f"{marker}  {la}   |   {lb[9:] if len(lb) > 9 else lb}")

    print()
    if diff_count == 0:
        print("[PASS] Bytecode files are identical.")
    else:
        print(f"[FAIL] {diff_count} differing 16-byte rows. First difference at offset 0x{first_diff_offset:04x} ({first_diff_offset}).")
        if len(data_a) != len(data_b):
            print(f"       Size mismatch: A={len(data_a)}, B={len(data_b)} bytes.")


def main():
    parser = argparse.ArgumentParser(description="SageVM compiler diagnostic diff tool")
    parser.add_argument("file_a", help="Interpreted output or DIAG file")
    parser.add_argument("file_b", help="Compiled output or DIAG file")
    parser.add_argument("--hex", action="store_true", help="Compare .sgvm binary files instead of DIAG text")
    args = parser.parse_args()

    if args.hex:
        diff_hex(args.file_a, args.file_b)
    else:
        diff_diag(args.file_a, args.file_b)


if __name__ == "__main__":
    main()
