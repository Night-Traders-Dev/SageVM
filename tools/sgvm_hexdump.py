#!/usr/bin/env python3
"""sgvm_hexdump.py - Human-readable disassembly of .sgvm bytecode files.

Usage:
  python3 tools/sgvm_hexdump.py <file.sgvm>

Prints the SGVM header, constant pool, and disassembled chunk instructions.
"""
import sys
import struct

OP_NAMES = {
    0:  "CONSTANT",
    1:  "NIL",
    2:  "TRUE",
    3:  "FALSE",
    4:  "POP",
    5:  "GET_GLOBAL",
    6:  "DEFINE_GLOBAL",
    7:  "SET_GLOBAL",
    8:  "DEFINE_FUNCTION",
    9:  "GET_PROPERTY",
    10: "SET_PROPERTY",
    11: "ADD",
    12: "SUB",
    13: "LOAD_FUNCTION",
    14: "MUL",
    15: "DIV",
    16: "MOD",
    17: "NEG",
    18: "NOT",
    19: "EQ",
    20: "NEQ",
    21: "LT",
    22: "LTE",
    23: "GT",
    24: "GTE",
    25: "AND",
    26: "OR",
    27: "PRINT",
    28: "RETURN",
    29: "NIL_RETURN",
    30: "LOAD_LOCAL",
    31: "STORE_LOCAL",
    32: "LOAD_UPVALUE",
    33: "STORE_UPVALUE",
    34: "CLOSE_UPVALUE",
    35: "JUMP",
    36: "LOOP_BACK",
    37: "CALL",
    38: "CALL_METHOD",
    39: "JUMP_IF_FALSE",
    40: "ARRAY",
    41: "TUPLE",
    42: "INDEX",
    43: "DICT",
    44: "RETURN_EXPR",
    45: "POWER",
    46: "CONCAT",
    47: "DUP",
    48: "FLOOR_DIV",
    49: "BREAK",
    50: "CONTINUE",
    51: "EXEC_AST_STMT",
    52: "IMPORT",
    53: "CLASS",
    54: "METHOD",
    55: "INHERIT",
    56: "SETUP_TRY",
    57: "END_TRY",
    58: "RAISE",
}

# Operand sizes: (operand_bytes,) or special markers
# 'const2' = 2-byte constant index
# 'raw2'   = 2-byte raw (passthrough)
# '1'      = 1-byte
# 'defn'   = DEFINE_FUNCTION: 2-byte name + 2-byte chunk index
# 'callm'  = CALL_METHOD: 2-byte name + 1-byte argc
OP_OPERANDS = {
    0:  'const2',
    5:  'const2',
    6:  'const2',
    7:  'const2',
    8:  'defn',
    9:  'raw2',
    10: 'raw2',
    13: 'raw2',
    35: 'raw2',
    36: 'raw2',
    37: '1',
    38: 'callm',
    39: 'raw2',
    40: 'raw2',
    41: 'raw2',
    43: 'raw2',
    47: '1',
    49: 'raw2',
    50: 'raw2',
    51: 'raw2',
    52: 'raw2',
    53: 'raw2',
    54: 'raw2',
    56: 'raw2',
}


def read_be16(data, pos):
    return (data[pos] << 8) | data[pos + 1], pos + 2


def read_be32(data, pos):
    v = (data[pos] << 24) | (data[pos+1] << 16) | (data[pos+2] << 8) | data[pos+3]
    return v, pos + 4


def read_double(data, pos):
    return struct.unpack('>d', bytes(data[pos:pos+8]))[0], pos + 8


def disassemble(path):
    with open(path, 'rb') as f:
        raw = f.read()
    data = list(raw)
    pos = 0

    # Check for shebang
    if data[0] == ord('#'):
        while data[pos] != ord('\n'):
            pos += 1
        pos += 1

    magic = bytes(data[pos:pos+4])
    pos += 4
    if magic != b'SGVM':
        print(f"ERROR: bad magic {magic!r}")
        return
    print(f"Magic: SGVM")

    ver_maj = data[pos]; ver_min = data[pos+1]; pos += 2
    print(f"Version: {ver_maj}.{ver_min}")

    func_count, pos = read_be16(data, pos)
    print(f"Functions: {func_count}")

    const_count, pos = read_be16(data, pos)
    print(f"Constants: {const_count}")

    consts = []
    for ci in range(const_count):
        ctype = data[pos]; pos += 1
        if ctype == 1:
            val, pos = read_double(data, pos)
            consts.append((1, val))
            print(f"  const[{ci}] = NUM {val}")
        elif ctype == 3:
            slen, pos = read_be16(data, pos)
            s = bytes(data[pos:pos+slen]).decode('utf-8', errors='replace')
            pos += slen
            consts.append((3, s))
            print(f"  const[{ci}] = STR {s!r}")
        else:
            consts.append((ctype, None))
            print(f"  const[{ci}] = UNKNOWN type {ctype}")

    chunk_total, pos = read_be32(data, pos)
    print(f"Chunks+Functions: {chunk_total}")
    print()

    def const_label(idx):
        if 0 <= idx < len(consts):
            ct, cv = consts[idx]
            if ct == 3: return f"{idx}({cv!r})"
            if ct == 1: return f"{idx}({cv})"
        return str(idx)

    for chunk_idx in range(chunk_total):
        chunk_len, pos = read_be32(data, pos)
        print(f"--- Chunk {chunk_idx} ({chunk_len} bytes) ---")
        chunk_end_pos = pos + chunk_len
        ip = 0
        while pos < chunk_end_pos:
            op = data[pos]; pos += 1; ip += 1
            op_name = OP_NAMES.get(op, f"OP_{op}")
            operand_type = OP_OPERANDS.get(op, None)
            if operand_type is None:
                print(f"  {ip-1:4d}  {op:02x}  {op_name}")
            elif operand_type == 'const2':
                idx, pos = read_be16(data, pos); ip += 2
                print(f"  {ip-3:4d}  {op:02x}  {op_name:<20} {const_label(idx)}")
            elif operand_type == 'raw2':
                val, pos = read_be16(data, pos); ip += 2
                label = const_label(val) if op in (52, 53, 54, 9, 10) else str(val)
                print(f"  {ip-3:4d}  {op:02x}  {op_name:<20} {label}")
            elif operand_type == '1':
                val = data[pos]; pos += 1; ip += 1
                print(f"  {ip-2:4d}  {op:02x}  {op_name:<20} {val}")
            elif operand_type == 'defn':
                name_idx, pos = read_be16(data, pos); ip += 2
                chunk_ref, pos = read_be16(data, pos); ip += 2
                print(f"  {ip-5:4d}  {op:02x}  {op_name:<20} name={const_label(name_idx)} chunk={chunk_ref}")
            elif operand_type == 'callm':
                name_idx, pos = read_be16(data, pos); ip += 2
                argc = data[pos]; pos += 1; ip += 1
                print(f"  {ip-4:4d}  {op:02x}  {op_name:<20} name={const_label(name_idx)} argc={argc}")
        print()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 tools/sgvm_hexdump.py <file.sgvm>")
        sys.exit(1)
    disassemble(sys.argv[1])
