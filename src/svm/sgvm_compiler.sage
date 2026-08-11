import sys
import io

proc sys_exec(cmd):
    return sys_exec_cmd(cmd)

proc io_readfile(path):
    return io.readfile(path)

proc io_writebytes(path, bytes):
    return io.writebytes(path, bytes)

import sgvm_core
from sgvm_core import SGVMUtils
from sgvm_core import OP_CONSTANT, OP_GET_GLOBAL, OP_DEFINE_GLOBAL, OP_SET_GLOBAL
from sgvm_core import OP_DEFINE_FUNCTION, OP_GET_PROPERTY, OP_SET_PROPERTY, OP_LOAD_FUNCTION
from sgvm_core import OP_JUMP, OP_JUMP_IF_FALSE, OP_ARRAY, OP_TUPLE, OP_DICT
from sgvm_core import OP_EXEC_AST_STMT, OP_BREAK, OP_CONTINUE, OP_LOOP_BACK
from sgvm_core import OP_IMPORT, OP_CLASS, OP_METHOD, OP_SETUP_TRY
from sgvm_core import OP_CALL_METHOD, OP_CALL, OP_DUP, OP_MATH_PRINTM
from sgvm_core import OP_YIELD, OP_CREATE_GENERATOR, OP_GENERATOR_NEXT, OP_GET_LOCAL, OP_SET_LOCAL

class SGVMCompiler:
    proc init(self):
        self.debug = false
        self.output_bytes = []
        self.global_consts = []
        self.const_map = {} 
        self.local_to_global = []
        self.local_to_global_raw = [] 
        self.chunk_params = []
        self.current_chunk = -1
        self.utils = SGVMUtils()

    proc write_byte(self, b):
        if b == nil:
            push(self.output_bytes, 0)
        elif type(b) == "string":
            if len(b) > 0: push(self.output_bytes, ord(b))
            else: push(self.output_bytes, 0)
        else:
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
        if v == nil:
            return
        
        if v == 0.0:
            var i = 0
            while i < 8:
                self.write_byte(0)
                i = i + 1
            return
        
        var sign = 1.0
        var val = v
        if val < 0.0:
            sign = -1.0
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
        var b0 = 0.0
        if sign < 0.0:
            b0 = 128.0
        b0 = b0 + self.utils.my_int(e_field / 16)
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
        # Standardize number key
        let s_val = str(d)
        let key = "n" + s_val
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

    proc first_pass(self, lines):
        if self.debug: print "DEBUG entering first_pass, lines len=" + str(len(lines))
        let ut = self.utils
        var i = 0
        var chunk_count = 0
        var function_count = 0
        while i < len(lines):
            let line = ut.trim(ut.strip_comment(lines[i]))
            if startswith(line, "functions "):
                function_count = ut.parse_int_field(line, 10)
            elif startswith(line, "chunks "):
                chunk_count = ut.parse_int_field(line, 7)
            elif line == "chunk":
                self.current_chunk = self.current_chunk + 1
                let ltg = self.local_to_global
                let empty_ltg = []
                push(ltg, empty_ltg)
                
                let ltg_raw = self.local_to_global_raw
                let empty_raw = []
                push(ltg_raw, empty_raw)
                
                let params = self.chunk_params
                let empty_params = []
                push(params, empty_params)
            elif line == "function":
                self.current_chunk = self.current_chunk + 1
                let ltg = self.local_to_global
                let empty_ltg = []
                push(ltg, empty_ltg)
                
                let ltg_raw = self.local_to_global_raw
                let empty_raw = []
                push(ltg_raw, empty_raw)
                
                let params = self.chunk_params
                let empty_params = []
                push(params, empty_params)
                
                i = i + 1
                let pline = ut.trim(ut.strip_comment(lines[i]))
                let pcount = ut.parse_int_field(pline, 7)
                var pidx = 0
                while pidx < pcount:
                    i = i + 1
                    let param_len_line = ut.trim(ut.strip_comment(lines[i]))
                    let plen = ut.parse_int_field(param_len_line, 6)
                    i = i + 1
                    let hex = ut.trim(lines[i])
                    var p_name = ""
                    var k = 0
                    while k < plen:
                        let byte_val = ut.parse_hex_byte(hex, k * 2)
                        let ch = chr(byte_val)
                        p_name = p_name + ch
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
                    let cl = ut.trim(ut.strip_comment(lines[i]))
                    if startswith(cl, "number "):
                        let cl_len = len(cl)
                        let num_sub = ut.my_substr(cl, 7, cl_len)
                        let num_trimmed = ut.trim(num_sub)
                        let num_val = tonumber(num_trimmed)
                        let num_idx = self.add_const_num(num_val)
                        ltg_chunk[j] = num_idx
                        ltg_raw_chunk[j] = num_idx
                    elif startswith(cl, "string "):
                        let slen = ut.parse_int_field(cl, 7)
                        i = i + 1
                        let hex = ut.trim(lines[i])
                        var s = ""
                        var k = 0
                        while k < slen:
                            let byte_val = ut.parse_hex_byte(hex, k * 2)
                            let ch = chr(byte_val)
                            s = s + ch
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
                            let idx_str = str(param_idx + 1)
                            let arg_name = "__arg" + idx_str
                            let arg_idx = self.add_const_str(arg_name)
                            ltg_chunk[j] = arg_idx
                        else:
                            ltg_chunk[j] = raw_idx
                    j = j + 1
            i = i + 1
        return [function_count, chunk_count]

    proc second_pass(self, lines, function_count, chunk_count, use_shebang):
        let ut = self.utils
        if use_shebang:
            self.write_string("#!/usr/bin/env sgvm\n")
        
        self.write_string("SGVM")
        self.write_byte(0x01)
        self.write_byte(0x00)
        self.write_be16(function_count)
        let const_count = len(self.global_consts)
        self.write_be16(const_count)
        var cidx = 0
        while cidx < len(self.global_consts):
            let c = self.global_consts[cidx]
            self.write_byte(c["type"])
            if c["type"] == 1:
                self.write_double(c["num"])
            else:
                let s_val = c["str"]
                let s_len = len(s_val)
                self.write_be16(s_len)
                self.write_string(c["str"])
            cidx = cidx + 1
        
        self.write_be32(chunk_count + function_count)
        
        self.current_chunk = -1
        var i = 0
        while i < len(lines):
            let line = ut.trim(ut.strip_comment(lines[i]))
            if line == "chunk" or line == "function":
                self.current_chunk = self.current_chunk + 1
            elif startswith(line, "code "):
                let clen = ut.parse_int_field(line, 5)
                # print "DEBUG: Chunk " + str(self.current_chunk) + " code len " + str(clen)
                self.write_be32(clen)
                i = i + 1
                let hex = ut.trim(lines[i])
                var j = 0
                while j < clen * 2:
                    var op = ut.parse_hex_byte(hex, j)
                    # Mapping host opcodes (0-based) to VM opcodes
                    if op == 0x23: op = 35 # BC_OP_JUMP
                    elif op == 0x24: op = 36 # BC_OP_JUMP_IF_FALSE
                    elif op == 0x25: op = 37 # BC_OP_CALL
                    elif op == 0x26: op = 38 # BC_OP_CALL_METHOD
                    elif op == 0x31: op = 49 # BC_OP_BREAK
                    elif op == 0x32: op = 50 # BC_OP_CONTINUE
                    elif op == 0x33: op = 51 # BC_OP_LOOP_BACK
                    elif op == 0x34: op = 52 # BC_OP_IMPORT
                    elif op == 0x35: op = 53 # BC_OP_CLASS
                    elif op == 0x36: op = 54 # BC_OP_METHOD
                    elif op == 0x37: op = 55 # BC_OP_INHERIT
                    elif op == 0x38: op = 56 # BC_OP_SETUP_TRY
                    elif op == 0x39: op = 57 # BC_OP_END_TRY
                    elif op == 0x3a: op = 58 # BC_OP_RAISE
                    elif op == 0x08: op = 8  # BC_OP_DEFINE_FUNCTION
                    elif op == 0x09: op = 9  # BC_OP_GET_PROPERTY
                    elif op == 0x0a: op = 10 # BC_OP_SET_PROPERTY
                    elif op == 0x0b: op = 11 # BC_OP_GET_INDEX
                    elif op == 0x0c: op = 12 # BC_OP_SET_INDEX
                    elif op == 0x0d: op = 13 # BC_OP_LOAD_FUNCTION
                    elif op == 0x0e: op = 14 # BC_OP_SLICE
                    elif op == 0x3b: op = 88 # BC_OP_GET_LOCAL
                    elif op == 0x3c: op = 89 # BC_OP_SET_LOCAL
                    elif op == 0x3d: op = 90 # BC_OP_YIELD
                    elif op == 0x3e: op = 91 # BC_OP_CREATE_GENERATOR
                    elif op == 0x3f: op = 92 # BC_OP_GENERATOR_NEXT
                    
                    self.write_byte(op)
                    j = j + 2
                    if op == 0 or op == 5 or op == 6 or op == 7:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        let local_idx = v1 * 256 + v2
                        let ltg = self.local_to_global[self.current_chunk]
                        var val = 0
                        if local_idx >= 0 and local_idx < len(ltg): val = ltg[local_idx]
                        self.write_be16(val)
                        j = j + 4
                    elif op == 8: # DEFINE_FUNCTION
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        let local_idx = v1 * 256 + v2
                        let ltg_raw = self.local_to_global_raw[self.current_chunk]
                        var val = 0
                        if local_idx >= 0 and local_idx < len(ltg_raw): val = ltg_raw[local_idx]
                        self.write_be16(val)
                        let f1 = ut.parse_hex_byte(hex, j + 4)
                        let f2 = ut.parse_hex_byte(hex, j + 6)
                        self.write_be16(f1 * 256 + f2)
                        j = j + 8
                    elif op == 9 or op == 10 or op == 52 or op == 53 or op == 54:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        let local_idx = v1 * 256 + v2
                        let ltg_raw = self.local_to_global_raw[self.current_chunk]
                        var val = 0
                        if local_idx >= 0 and local_idx < len(ltg_raw): val = ltg_raw[local_idx]
                        self.write_be16(val)
                        j = j + 4
                    elif op == 13 or op == 35 or op == 36 or op == 39 or op == 40 or op == 41 or op == 43 or op == 51 or op == 56 or op == 88 or op == 89:
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        self.write_be16(v1 * 256 + v2)
                        j = j + 4
                    elif op == 37 or op == 47: # CALL or DUP
                        let val = ut.parse_hex_byte(hex, j)
                        self.write_byte(val)
                        j = j + 2
                    elif op == 91: # CREATE_GENERATOR
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        let local_idx = v1 * 256 + v2
                        let ltg_raw = self.local_to_global_raw[self.current_chunk]
                        var val = 0
                        if local_idx >= 0 and local_idx < len(ltg_raw): val = ltg_raw[local_idx]
                        self.write_be16(val)
                        let f1 = ut.parse_hex_byte(hex, j + 4)
                        let f2 = ut.parse_hex_byte(hex, j + 6)
                        self.write_be16(f1 * 256 + f2)
                        j = j + 8
                    elif op == 88 or op == 89: # GET_LOCAL or SET_LOCAL
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        self.write_be16(v1 * 256 + v2)
                        j = j + 4
                    elif op == 38: # CALL_METHOD
                        let v1 = ut.parse_hex_byte(hex, j)
                        let v2 = ut.parse_hex_byte(hex, j + 2)
                        let local_idx = v1 * 256 + v2
                        let ltg_raw = self.local_to_global_raw[self.current_chunk]
                        var val = 0
                        if local_idx >= 0 and local_idx < len(ltg_raw): val = ltg_raw[local_idx]
                        self.write_be16(val)
                        let call_arg = ut.parse_hex_byte(hex, j + 4)
                        self.write_byte(call_arg)
                        j = j + 6
            i = i + 1

    proc is_safe_path(self, path):
        if path == nil or len(path) == 0:
            return false
        if startswith(path, "-"):
            return false

        # Security: Whitelist approach for path validation (CWE-78)
        let safe_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/._- "
        var i = 0
        while i < len(path):
            let ch = path[i]
            let res = contains(safe_chars, ch)
            if not res:
                if self.debug: print "DEBUG is_safe_path failed on char='" + str(ch) + "' ord=" + str(ord(ch)) + " path='" + str(path) + "'"
                return false
            i = i + 1
        return true

    proc compile(self, input_file, output_file, use_shebang):
        if self.debug: print "DEBUG SGVMCompiler.compile self.utils=" + str(self.utils) + " input_file=" + str(input_file) + " type=" + str(type(input_file)) + " output_file=" + str(output_file)
        let ut = self.utils
        var in_file = ut.trim(input_file)
        if self.debug: print "DEBUG after trim in_file='" + str(in_file) + "' len=" + str(len(in_file))
        var out_file = ut.trim(output_file)

        # Security: Prevent command injection and flag injection via robust path validation
        if not self.is_safe_path(in_file):
            print "Error: Illegal characters or format in input path: " + str(in_file)
            return false
        if not self.is_safe_path(out_file):
            print "Error: Illegal characters or format in output path: " + str(out_file)
            return false

        var svm_file = in_file
        if endswith(in_file, ".sage"):
            let ext = ".svm"
            svm_file = in_file + ext
            var sage_bin = ".deps/SageLang/core/sage"
            if io_readfile(sage_bin) == nil: sage_bin = "sage"
            var cmd = sage_bin + " --emit-vm '" + in_file + "' -o '" + svm_file + "'"
            
            let status = sys_exec(cmd)
            if self.debug: print "DEBUG after sys_exec status=" + str(status)
            if status != 0:
                print "Error: Failed to generate SVM from " + in_file
                return false
        
        let content = io_readfile(svm_file)
        if content == nil:
            print "Error: Could not read SVM file: " + svm_file
            return false
        if self.debug: print "DEBUG after io_readfile content len=" + str(len(content))
        
        let lines = ut.split_lines(content)
        if self.debug: print "DEBUG after split_lines count=" + str(len(lines))
        
        let counts = self.first_pass(lines)
        let function_count = counts[0]
        let chunk_count = counts[1]
        if self.debug: print "DEBUG after first_pass function_count=" + str(function_count) + " chunk_count=" + str(chunk_count)
        
        self.second_pass(lines, function_count, chunk_count, use_shebang)
        if self.debug: print "DEBUG after second_pass output_bytes len=" + str(len(self.output_bytes))
        
        io_writebytes(out_file, self.output_bytes)
        return true
