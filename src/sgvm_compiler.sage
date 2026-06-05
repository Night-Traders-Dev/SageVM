import io
import sys
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

class SGVMCompiler:
    proc init(self):
        self.output_bytes = []
        self.global_consts = []
        self.const_map = {} # New: Map of value to index for O(1) lookup
        self.local_to_global = []
        self.chunk_params = []
        self.current_chunk = -1
        self.utils = SGVMUtils()

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
        let tmp_svm = ".tmp.svm"
        sys.exec("sage --emit-vm " + input_file + " -o " + tmp_svm)
        let content = io.readfile(tmp_svm)
        if content == nil: return
        let lines = self.utils.split_lines(content)
        
        # First pass: parse constants
        var i = 0
        var chunk_count = 0
        var function_count = 0
        while i < len(lines):
            let line = self.utils.trim(lines[i])
            if startswith(line, "functions "):
                function_count = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(line, 10, len(line)))))
            elif startswith(line, "chunks "):
                chunk_count = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(line, 7, len(line)))))
            elif line == "chunk":
                self.current_chunk = self.current_chunk + 1
                push(self.local_to_global, [])
                push(self.chunk_params, [])
            elif line == "function":
                self.current_chunk = self.current_chunk + 1
                push(self.local_to_global, [])
                push(self.chunk_params, [])
                # Read params line
                i = i + 1
                let pline = self.utils.trim(lines[i])
                let pcount = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(pline, 7, len(pline)))))
                var pidx = 0
                while pidx < pcount:
                    i = i + 1 # param <len>
                    let param_len_line = self.utils.trim(lines[i])
                    let plen = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(param_len_line, 6, len(param_len_line)))))
                    i = i + 1 # hex string
                    let hex = self.utils.trim(lines[i])
                    var p_name = ""
                    var k = 0
                    while k < plen:
                        p_name = p_name + chr(self.utils.my_int(self.utils.hex_to_byte(self.utils.my_substr(hex, k*2, 2))))
                        k = k + 1
                    push(self.chunk_params[self.current_chunk], p_name)
                    pidx = pidx + 1
            elif startswith(line, "constants "):
                let count = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(line, 10, len(line)))))
                # Dynamically size the local_to_global table for this chunk
                var j = 0
                while j < count:
                    push(self.local_to_global[self.current_chunk], 0)
                    j = j + 1
                j = 0
                while j < count:
                    i = i + 1
                    let cl = self.utils.trim(lines[i])
                    if startswith(cl, "number "):
                        self.local_to_global[self.current_chunk][j] = self.add_const_num(tonumber(self.utils.trim(self.utils.my_substr(cl, 7, len(cl)))))
                    elif startswith(cl, "string "):
                        let slen = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(cl, 7, len(cl)))))
                        i = i + 1
                        let hex = self.utils.trim(lines[i])
                        var s = ""
                        var k = 0
                        while k < slen:
                            s = s + chr(self.utils.my_int(self.utils.hex_to_byte(self.utils.my_substr(hex, k*2, 2))))
                            k = k + 1
                        # Check if this string matches a parameter name for current_chunk
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
                            s = "__arg" + str(param_idx)
                        # print "Debug: Chunk " + str(self.current_chunk) + " Const " + str(j) + " mapped to: " + s
                        self.local_to_global[self.current_chunk][j] = self.add_const_str(s)
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
        
        # Second pass: parse code
        self.current_chunk = -1
        i = 0
        while i < len(lines):
            let line = self.utils.trim(lines[i])
            if line == "chunk" or line == "function": self.current_chunk = self.current_chunk + 1
            elif startswith(line, "code "):
                let clen = self.utils.my_int(tonumber(self.utils.trim(self.utils.my_substr(line, 5, len(line)))))
                print "Chunk " + str(self.current_chunk) + " clen line: '" + line + "' clen: " + str(clen)
                self.write_be32(clen)
                i = i + 1
                let hex = self.utils.trim(lines[i])
                var j = 0
                while j < clen * 2:
                    let op = self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2))
                    self.write_byte(op)
                    j = j + 2
                    if op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_SET_GLOBAL: 
                        let v1 = self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2))
                        let v2 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+2, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][v1 * 256 + v2])
                        j = j + 4
                    elif op == OP_DEFINE_FUNCTION:
                        let v1 = self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2))
                        let v2 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+2, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][v1 * 256 + v2])
                        self.write_be16(self.utils.hex_to_byte(self.utils.my_substr(hex, j+4, 2)) * 256 + self.utils.hex_to_byte(self.utils.my_substr(hex, j+6, 2)))
                        j = j + 8
                    elif op == OP_CLASS:
                        let n1 = self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2))
                        let n2 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+2, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][n1 * 256 + n2])
                        self.write_be16(self.utils.hex_to_byte(self.utils.my_substr(hex, j+4, 2)) * 256 + self.utils.hex_to_byte(self.utils.my_substr(hex, j+6, 2)))
                        let p1 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+8, 2))
                        let p2 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+10, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][p1 * 256 + p2])
                        j = j + 12
                    elif op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_LOAD_FUNCTION or op == OP_IMPORT or op == OP_METHOD:
                        let v1 = self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2))
                        let v2 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+2, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][v1 * 256 + v2])
                        j = j + 4
                    elif op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_ARRAY or op == OP_TUPLE or op == OP_DICT or op == OP_EXEC_AST_STMT or op == OP_BREAK or op == OP_CONTINUE or op == OP_LOOP_BACK or op == OP_SETUP_TRY:
                        self.write_be16(self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2)) * 256 + self.utils.hex_to_byte(self.utils.my_substr(hex, j+2, 2)))
                        j = j + 4
                    elif op == OP_CALL_METHOD:
                        let v1 = self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2))
                        let v2 = self.utils.hex_to_byte(self.utils.my_substr(hex, j+2, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][v1 * 256 + v2])
                        self.write_byte(self.utils.hex_to_byte(self.utils.my_substr(hex, j+4, 2)))
                        j = j + 6
                    elif op == OP_CALL or op == OP_DUP:
                        self.write_byte(self.utils.hex_to_byte(self.utils.my_substr(hex, j, 2)))
                        j = j + 2
            i = i + 1
        io.writebytes(output_file, self.output_bytes)
