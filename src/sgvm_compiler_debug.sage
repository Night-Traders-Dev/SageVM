# sgvm_compiler_debug.sage
# Instrumented version of sgvm_compiler.sage for Phase 2 diagnosis.
# Adds DIAG traces to stderr in the second-pass code-emission loop.
# Run both modes and diff their DIAG output:
#   sage sgvm_compiler_debug.sage input.sage out.sgvm 2>interp.diag
#   ./sgvmc_debug input.sage out.sgvm 2>compiled.diag
#   python3 tools/diff_bytecode.py interp.diag compiled.diag
import sys
import io

proc sys_exec(cmd):
    return sys.exec(cmd)

proc io_readfile(path):
    return io.readfile(path)

proc io_writebytes(path, bytes):
    return io.writebytes(path, bytes)

proc diag_write(msg):
    sys.write_stderr(msg + "\n")

import sgvm_core
from sgvm_core import SGVMUtils
from sgvm_core import OP_CONSTANT
from sgvm_core import OP_GET_GLOBAL
from sgvm_core import OP_DEFINE_GLOBAL
from sgvm_core import OP_SET_GLOBAL
from sgvm_core import OP_DEFINE_FUNCTION
from sgvm_core import OP_GET_PROPERTY
from sgvm_core import OP_SET_PROPERTY
from sgvm_core import OP_LOAD_FUNCTION
from sgvm_core import OP_JUMP
from sgvm_core import OP_JUMP_IF_FALSE
from sgvm_core import OP_ARRAY
from sgvm_core import OP_TUPLE
from sgvm_core import OP_DICT
from sgvm_core import OP_EXEC_AST_STMT
from sgvm_core import OP_BREAK
from sgvm_core import OP_CONTINUE
from sgvm_core import OP_LOOP_BACK
from sgvm_core import OP_IMPORT
from sgvm_core import OP_CLASS
from sgvm_core import OP_METHOD
from sgvm_core import OP_SETUP_TRY
from sgvm_core import OP_CALL_METHOD
from sgvm_core import OP_CALL
from sgvm_core import OP_DUP

class SGVMCompilerDebug:
    proc init(self):
        self.output_bytes = []
        self.global_consts = []
        self.const_map = {}
        self.local_to_global = []
        self.local_to_global_raw = []
        self.chunk_params = []
        self.current_chunk = -1
        self.utils = SGVMUtils()
        self.diag_step = 0

    proc write_byte(self, b):
        push(self.output_bytes, self.utils.my_int(b))

    proc write_string(self, s):
        var i = 0
        while i < len(s):
            self.write_byte(ord(s[i]))
            i = i + 1

    proc write_be16(self, v):
        var val = self.utils.my_int(v)
        self.write_byte(self.utils.my_int(val / 256))
        self.write_byte(val % 256)

    proc write_be32(self, v):
        var val = self.utils.my_int(v)
        self.write_byte(self.utils.my_int(val / 16777216) % 256)
        self.write_byte(self.utils.my_int(val / 65536) % 256)
        self.write_byte(self.utils.my_int(val / 256) % 256)
        self.write_byte(val % 256)

    proc write_double(self, v):
        if v == nil: return
        if v == 0.0:
            var i = 0
            while i < 8:
                self.write_byte(0)
                i = i + 1
            return
        var sign = 0.0
        var val = v
        if val < 0.0:
            sign = 1.0
            val = -val
        var exp = 0
        if val >= 1.0:
            while val >= 2.0:
                val = val / 2.0
                exp = exp + 1
        else:
            while val < 1.0:
                val = val * 2.0
                exp = exp - 1
        var mantissa = val - 1.0
        var e_field = exp + 1023
        var b0 = sign * 128.0 + self.utils.my_int(e_field / 16)
        var b1 = (e_field % 16) * 16
        var f = mantissa
        var bits = []
        var i = 0
        while i < 52:
            f = f * 2.0
            if f >= 1.0:
                push(bits, 1.0)
                f = f - 1.0
            else:
                push(bits, 0.0)
            i = i + 1
        var b1_low = 0.0
        var k = 0
        while k < 4:
            b1_low = b1_low * 2.0 + bits[k]
            k = k + 1
        self.write_byte(b0)
        self.write_byte(b1 + b1_low)
        var byte_idx = 2
        while byte_idx < 8:
            var bv = 0.0
            var bit_idx = 0
            while bit_idx < 8:
                bv = bv * 2.0 + bits[4 + (byte_idx-2)*8 + bit_idx]
                bit_idx = bit_idx + 1
            self.write_byte(bv)
            byte_idx = byte_idx + 1

    proc add_const_num(self, d):
        let key = "n" + str(d)
        if dict_has(self.const_map, key):
            return self.const_map[key]
        let c = {"type": 1, "num": d}
        push(self.global_consts, c)
        let idx = len(self.global_consts) - 1
        self.const_map[key] = idx
        return idx

    proc add_const_str(self, s):
        let key = "s" + s
        if dict_has(self.const_map, key):
            return self.const_map[key]
        let c = {"type": 3, "str": s}
        push(self.global_consts, c)
        let idx = len(self.global_consts) - 1
        self.const_map[key] = idx
        return idx

    proc compile(self, input_file, output_file, use_shebang):
        let ut = self.utils
        let tmp_svm = ".tmp.svm"
        let cmd = "sage --emit-vm " + input_file + " -o " + tmp_svm
        sys_exec(cmd)
        let content = io_readfile(tmp_svm)
        if content == nil: return
        let lines = ut.split_lines(content)

        # First pass: parse constants (identical to production compiler)
        var i = 0
        var chunk_count = 0
        var function_count = 0
        while i < len(lines):
            let line = ut.trim(lines[i])
            if startswith(line, "functions "):
                function_count = ut.parse_int_field(line, 10)
            elif startswith(line, "chunks "):
                chunk_count = ut.parse_int_field(line, 7)
            elif line == "chunk":
                self.current_chunk = self.current_chunk + 1
                push(self.local_to_global, [])
                push(self.local_to_global_raw, [])
                push(self.chunk_params, [])
            elif line == "function":
                self.current_chunk = self.current_chunk + 1
                push(self.local_to_global, [])
                push(self.local_to_global_raw, [])
                push(self.chunk_params, [])
                i = i + 1
                let pline = ut.trim(lines[i])
                let pcount = ut.parse_int_field(pline, 7)
                var pidx = 0
                while pidx < pcount:
                    i = i + 1
                    let param_len_line = ut.trim(lines[i])
                    let plen = ut.parse_int_field(param_len_line, 6)
                    i = i + 1
                    let hex = ut.trim(lines[i])
                    var p_name = ""
                    var k = 0
                    while k < plen:
                        let k_times_2 = k * 2
                        let byte_val = ut.parse_hex_byte(hex, k_times_2)
                        p_name = p_name + chr(byte_val)
                        k = k + 1
                    let params_arr = self.chunk_params[self.current_chunk]
                    push(params_arr, p_name)
                    pidx = pidx + 1
            elif startswith(line, "constants "):
                let count = ut.parse_int_field(line, 10)
                let ltg_chunk = self.local_to_global[self.current_chunk]
                let ltg_raw_chunk = self.local_to_global_raw[self.current_chunk]
                var j = 0
                while j < count:
                    push(ltg_chunk, 0)
                    push(ltg_raw_chunk, 0)
                    j = j + 1
                j = 0
                while j < count:
                    i = i + 1
                    let cl = ut.trim(lines[i])
                    if startswith(cl, "number "):
                        let num_sub = ut.my_substr(cl, 7, len(cl))
                        let num_trimmed = ut.trim(num_sub)
                        let num_idx = self.add_const_num(tonumber(num_trimmed))
                        ltg_chunk[j] = num_idx
                        ltg_raw_chunk[j] = num_idx
                    elif startswith(cl, "string "):
                        let slen = ut.parse_int_field(cl, 7)
                        i = i + 1
                        let hex = ut.trim(lines[i])
                        var s = ""
                        var k = 0
                        while k < slen:
                            let k_times_2 = k * 2
                            let byte_val = ut.parse_hex_byte(hex, k_times_2)
                            s = s + chr(byte_val)
                            k = k + 1
                        let raw_idx = self.add_const_str(s)
                        ltg_raw_chunk[j] = raw_idx
                        var param_idx = -1
                        var pi = 0
                        let params_list = self.chunk_params[self.current_chunk]
                        while pi < len(params_list):
                            if params_list[pi] == s:
                                param_idx = pi
                                pi = len(params_list)
                            else:
                                pi = pi + 1
                        if param_idx >= 0:
                            let arg_name = "__arg" + str(param_idx)
                            let arg_idx = self.add_const_str(arg_name)
                            ltg_chunk[j] = arg_idx
                        else:
                            ltg_chunk[j] = raw_idx
                    j = j + 1
            i = i + 1

        if use_shebang: self.write_string("#!/usr/bin/env sgvm\n")
        self.write_string("SGVM")
        self.write_byte(0x01)
        self.write_byte(0x00)
        self.write_be16(function_count)
        self.write_be16(len(self.global_consts))
        var cidx = 0
        while cidx < len(self.global_consts):
            let c = self.global_consts[cidx]
            self.write_byte(c["type"])
            if c["type"] == 1: self.write_double(c["num"])
            else:
                self.write_be16(len(c["str"]))
                self.write_string(c["str"])
            cidx = cidx + 1
        self.write_be32(chunk_count + function_count)

        # Second pass: instrumented code emission
        self.current_chunk = -1
        i = 0
        while i < len(lines):
            let line = ut.trim(lines[i])
            if line == "chunk" or line == "function":
                self.current_chunk = self.current_chunk + 1
                diag_write("DIAG chunk=" + str(self.current_chunk))
            elif startswith(line, "code "):
                let clen = ut.parse_int_field(line, 5)
                self.write_be32(clen)
                i = i + 1
                let hex = ut.trim(lines[i])
                diag_write("DIAG code_hex=" + hex)
                var j = 0
                while j < clen * 2:
                    let op = ut.parse_hex_byte(hex, j)
                    let j_before = j
                    self.write_byte(op)
                    j = j + 2
                    if op == 0 or op == 5 or op == 6 or op == 7:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let v2 = ut.parse_hex_byte(hex, j_plus_2)
                        let local_idx = v1 * 256 + v2
                        let chunk_map = self.local_to_global[self.current_chunk]
                        let global_idx = chunk_map[local_idx]
                        self.write_be16(global_idx)
                        j = j + 4
                        diag_write("DIAG op=" + str(op) + " j_before=" + str(j_before) + " local_idx=" + str(local_idx) + " global_idx=" + str(global_idx) + " j_after=" + str(j))
                    elif op == 8:
                        let n1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let n2 = ut.parse_hex_byte(hex, j_plus_2)
                        let local_idx = n1 * 256 + n2
                        let chunk_map_raw = self.local_to_global_raw[self.current_chunk]
                        let global_idx = chunk_map_raw[local_idx]
                        self.write_be16(global_idx)
                        let j_plus_4 = j + 4
                        let f1 = ut.parse_hex_byte(hex, j_plus_4)
                        let j_plus_6 = j + 6
                        let f2 = ut.parse_hex_byte(hex, j_plus_6)
                        self.write_be16(f1 * 256 + f2)
                        j = j + 8
                        diag_write("DIAG op=8(DEFINE_FUNCTION) j_before=" + str(j_before) + " local_idx=" + str(local_idx) + " global_idx=" + str(global_idx) + " chunk_ref=" + str(f1 * 256 + f2) + " j_after=" + str(j))
                    elif op == 13:
                        let f1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let f2 = ut.parse_hex_byte(hex, j_plus_2)
                        self.write_be16(f1 * 256 + f2)
                        j = j + 4
                        diag_write("DIAG op=13(LOAD_FUNCTION) j_before=" + str(j_before) + " chunk_ref=" + str(f1 * 256 + f2) + " j_after=" + str(j))
                    elif op == 53:
                        let n1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let n2 = ut.parse_hex_byte(hex, j_plus_2)
                        let local_idx = n1 * 256 + n2
                        let chunk_map_raw = self.local_to_global_raw[self.current_chunk]
                        let global_idx = chunk_map_raw[local_idx]
                        self.write_be16(global_idx)
                        j = j + 4
                        diag_write("DIAG op=53(CLASS) j_before=" + str(j_before) + " local_idx=" + str(local_idx) + " global_idx=" + str(global_idx) + " j_after=" + str(j))
                    elif op == 9 or op == 10 or op == 54:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let v2 = ut.parse_hex_byte(hex, j_plus_2)
                        let local_idx = v1 * 256 + v2
                        let chunk_map_raw = self.local_to_global_raw[self.current_chunk]
                        let global_idx = chunk_map_raw[local_idx]
                        self.write_be16(global_idx)
                        j = j + 4
                        diag_write("DIAG op=" + str(op) + "(GET/SET_PROP or METHOD) j_before=" + str(j_before) + " local_idx=" + str(local_idx) + " global_idx=" + str(global_idx) + " j_after=" + str(j))
                    elif op == 52:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let v2 = ut.parse_hex_byte(hex, j_plus_2)
                        let local_idx = v1 * 256 + v2
                        let chunk_map_raw = self.local_to_global_raw[self.current_chunk]
                        let global_idx = chunk_map_raw[local_idx]
                        self.write_be16(global_idx)
                        j = j + 4
                        diag_write("DIAG op=52(IMPORT) j_before=" + str(j_before) + " local_idx=" + str(local_idx) + " global_idx=" + str(global_idx) + " j_after=" + str(j))
                    elif op == 35 or op == 36 or op == 39 or op == 40 or op == 41 or op == 43 or op == 49 or op == 50 or op == 51 or op == 56:
                        let j1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let j2 = ut.parse_hex_byte(hex, j_plus_2)
                        self.write_be16(j1 * 256 + j2)
                        j = j + 4
                        diag_write("DIAG op=" + str(op) + "(JUMP/COLL) j_before=" + str(j_before) + " operand=" + str(j1 * 256 + j2) + " j_after=" + str(j))
                    elif op == 38:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let j_plus_2 = j + 2
                        let v2 = ut.parse_hex_byte(hex, j_plus_2)
                        let local_idx = v1 * 256 + v2
                        let chunk_map_raw = self.local_to_global_raw[self.current_chunk]
                        let global_idx = chunk_map_raw[local_idx]
                        self.write_be16(global_idx)
                        let j_plus_4 = j + 4
                        self.write_byte(ut.parse_hex_byte(hex, j_plus_4))
                        j = j + 6
                        diag_write("DIAG op=38(CALL_METHOD) j_before=" + str(j_before) + " local_idx=" + str(local_idx) + " global_idx=" + str(global_idx) + " j_after=" + str(j))
                    elif op == 37 or op == 47:
                        self.write_byte(ut.parse_hex_byte(hex, j))
                        j = j + 2
                        diag_write("DIAG op=" + str(op) + "(CALL/DUP) j_before=" + str(j_before) + " j_after=" + str(j))
                    else:
                        # 0-operand opcode: just fell through
                        diag_write("DIAG op=" + str(op) + "(0-operand) j_before=" + str(j_before) + " j_after=" + str(j))
            i = i + 1
        io_writebytes(output_file, self.output_bytes)

var args = sys.args()
var input_file = ""
var output_file = "out.sgvm"
var use_shebang = false
var ai = 1
while ai < len(args):
    if args[ai] == "--shebang":
        use_shebang = true
    elif input_file == "":
        input_file = args[ai]
    else:
        output_file = args[ai]
    ai = ai + 1
if input_file == "":
    sys.write_stderr("Usage: sage sgvm_compiler_debug.sage <input.sage> [output.sgvm] [--shebang]\n")
else:
    let compiler = SGVMCompilerDebug()
    compiler.compile(input_file, output_file, use_shebang)
