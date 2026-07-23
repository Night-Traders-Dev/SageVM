proc sys_exec_cmd(cmd):
    return sys.system(cmd)

# Bytecode opcodes (Sync with bytecode.h and metal_vm.h)
let OP_CONSTANT       = 0
let OP_NIL            = 1
let OP_TRUE           = 2
let OP_FALSE          = 3
let OP_POP            = 4
let OP_GET_GLOBAL     = 5
let OP_DEFINE_GLOBAL  = 6
let OP_SET_GLOBAL     = 7
let OP_DEFINE_FUNCTION = 8
let OP_GET_PROPERTY   = 9
let OP_SET_PROPERTY   = 10
let OP_GET_INDEX      = 11
let OP_SET_INDEX      = 12
let OP_LOAD_FUNCTION  = 13
let OP_SLICE          = 14
let OP_ADD            = 15
let OP_SUB            = 16
let OP_MUL            = 17
let OP_DIV            = 18
let OP_MOD            = 19
let OP_NEGATE         = 20
let OP_EQUAL          = 21
let OP_NOT_EQUAL      = 22
let OP_GREATER        = 23
let OP_GREATER_EQUAL  = 24
let OP_LESS           = 25
let OP_LESS_EQUAL     = 26
let OP_BIT_AND        = 27
let OP_BIT_OR         = 28
let OP_BIT_XOR        = 29
let OP_BIT_NOT        = 30
let OP_SHIFT_LEFT     = 31
let OP_SHIFT_RIGHT    = 32
let OP_NOT            = 33
let OP_TRUTHY         = 34
let OP_JUMP           = 35
let OP_JUMP_IF_FALSE  = 36
let OP_CALL           = 37
let OP_CALL_METHOD    = 38
let OP_ARRAY          = 39
let OP_TUPLE          = 40
let OP_DICT           = 41
let OP_PRINT          = 42
let OP_EXEC_AST_STMT  = 43
let OP_RETURN         = 44
let OP_PUSH_ENV       = 45
let OP_POP_ENV        = 46
let OP_DUP            = 47
let OP_ARRAY_LEN      = 48
let OP_BREAK          = 49
let OP_CONTINUE       = 50
let OP_LOOP_BACK      = 51
let OP_IMPORT         = 52
let OP_CLASS          = 53
let OP_METHOD         = 54
let OP_INHERIT        = 55
let OP_SETUP_TRY      = 56
let OP_END_TRY        = 57
let OP_RAISE          = 58

# GPU hot-path opcodes (Phase 16)
let OP_GPU_POLL_EVENTS         = 59
let OP_GPU_WINDOW_SHOULD_CLOSE = 60
let OP_GPU_GET_TIME            = 61
let OP_GPU_KEY_PRESSED         = 62
let OP_GPU_KEY_DOWN            = 63
let OP_GPU_MOUSE_POS           = 64
let OP_GPU_MOUSE_DELTA         = 65
let OP_GPU_UPDATE_INPUT        = 66
let OP_GPU_BEGIN_COMMANDS      = 67
let OP_GPU_END_COMMANDS        = 68
let OP_GPU_CMD_BEGIN_RP        = 69
let OP_GPU_CMD_END_RP          = 70
let OP_GPU_CMD_DRAW            = 71
let OP_GPU_CMD_BIND_GP         = 72
let OP_GPU_CMD_BIND_DS         = 73
let OP_GPU_CMD_SET_VP          = 74
let OP_GPU_CMD_SET_SC          = 75
let OP_GPU_CMD_BIND_VB         = 76
let OP_GPU_CMD_BIND_IB         = 77
let OP_GPU_CMD_DRAW_IDX        = 78
let OP_GPU_SUBMIT_SYNC         = 79
let OP_GPU_ACQUIRE_IMG         = 80
let OP_GPU_PRESENT             = 81
let OP_GPU_WAIT_FENCE          = 82
let OP_GPU_RESET_FENCE         = 83
let OP_GPU_UPDATE_UNIFORM      = 84
let OP_GPU_CMD_PUSH_CONST      = 85
let OP_GPU_CMD_DISPATCH         = 86

let OP_MATH_PRINTM    = 87
let OP_GET_LOCAL      = 88
let OP_SET_LOCAL      = 89
let OP_YIELD          = 90
let OP_CREATE_GENERATOR = 91
let OP_GENERATOR_NEXT = 92
let OP_HALT           = 255

class SGVMUtils:
    proc my_int(self, x):
        if x == nil:
            return 0
        return int(x)

    proc hex_to_byte(self, h):
        if h == nil or len(h) < 2:
            return 0
        let chars = "0123456789abcdef"
        var v1 = 0
        var v2 = 0
        var c1 = h[0]
        var c2 = h[1]
        if ord(c1) >= 65 and ord(c1) <= 70:
            c1 = chr(ord(c1) + 32)
        if ord(c2) >= 65 and ord(c2) <= 70:
            c2 = chr(ord(c2) + 32)
        var i = 0
        while i < 16:
            if chars[i] == c1:
                v1 = i
            if chars[i] == c2:
                v2 = i
            i = i + 1
        return v1 * 16 + v2

    proc split_lines(self, s):
        if s == nil: return []
        let lines = []
        var current = ""
        let nl = "\n"
        let cr = "\r"
        var i = 0
        let slen = len(s)
        while i < slen:
            let ch = s[i]
            if ch == nl:
                push(lines, current)
                current = ""
            elif ch != cr:
                current = current + ch
            i = i + 1
        if len(current) > 0:
            push(lines, current)
        return lines

    proc my_substr(self, s, start, length):
        var res = ""
        var i = 0
        while i < length:
            if start + i < len(s):
                res = res + s[start + i]
            i = i + 1
        return res

    proc parse_int_field(self, line, offset):
        let sub = self.my_substr(line, offset, len(line))
        let trimmed = self.trim(sub)
        let numval = tonumber(trimmed)
        return self.my_int(numval)

    proc parse_hex_byte(self, hex, offset):
        let sub = self.my_substr(hex, offset, 2)
        let bval = self.hex_to_byte(sub)
        return self.my_int(bval)

    proc trim(self, s):
        if s == nil or type(s) != "string" or len(s) == 0:
            return ""
        var start = 0
        while start < len(s):
            let ch = s[start]
            let o = ord(ch)
            if o <= 32:
                start = start + 1
            else:
                break
        var eidx = len(s)
        while eidx > start:
            let ch = s[eidx-1]
            let o = ord(ch)
            if o <= 32:
                eidx = eidx - 1
            else:
                break
        let res = self.my_substr(s, start, eidx - start)
        return res

    proc strip_comment(self, line):
        # Remove # comments from a line of .svm text
        var i = 0
        while i < len(line):
            if line[i] == "#":
                return self.my_substr(line, 0, i)
            i = i + 1
        return line

    proc read_be16(self, bs, off):
        return self.my_int(bs[off]) * 256 + self.my_int(bs[off+1])

    proc read_be32(self, bs, off):
        return self.my_int(bs[off]) * 16777216 + self.my_int(bs[off+1]) * 65536 + self.my_int(bs[off+2]) * 256 + self.my_int(bs[off+3])

    proc unpack_double(self, bs, off):
        var b0 = self.my_int(bs[off])
        var b1 = self.my_int(bs[off+1])
        var b2 = self.my_int(bs[off+2])
        var b3 = self.my_int(bs[off+3])
        var b4 = self.my_int(bs[off+4])
        var b5 = self.my_int(bs[off+5])
        var b6 = self.my_int(bs[off+6])
        var b7 = self.my_int(bs[off+7])
        var sign = 1.0
        if int(b0 / 128) == 1:
            sign = -1.0
        var exp = (int(b0 % 128) * 16) + int(b1 / 16)
        var mantissa = 1.0
        if exp == 0:
            mantissa = 0.0
            exp = 1
        mantissa = mantissa + (int(b1 % 16) / 16.0)
        mantissa = mantissa + (b2 / 4096.0)
        mantissa = mantissa + (b3 / 1048576.0)
        mantissa = mantissa + (b4 / 268435456.0)
        mantissa = mantissa + (b5 / 68719476736.0)
        mantissa = mantissa + (b6 / 17592186044416.0)
        mantissa = mantissa + (b7 / 4503599627370496.0)
        var p2 = 1.0
        var e = exp - 1023
        if e > 0:
            var i = 0
            while i < e:
                p2 = p2 * 2.0
                i = i + 1
        elif e < 0:
            var i = 0
            while i < -e:
                p2 = p2 / 2.0
                i = i + 1
        return sign * mantissa * p2
import sys
import io

proc sys_exec(cmd):
    return sys_exec_cmd(cmd)

proc io_readfile(path):
    return io.readfile(path)

proc io_writebytes(path, bytes):
    return io.writebytes(path, bytes)


class SGVMCompiler:
    proc init(self):
        print "DEBUG SGVMCompiler.init entry"
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
        print "DEBUG entering first_pass, lines len=" + str(len(lines))
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
                    if op == 0x31: op = 35 # BC_OP_JUMP
                    elif op == 0x32: op = 36 # BC_OP_JUMP_IF_FALSE
                    elif op == 0x34: op = 52 # BC_OP_IMPORT
                    elif op == 0x26: op = 38 # BC_OP_CALL_METHOD
                    elif op == 0x25: op = 37 # BC_OP_CALL
                    elif op == 0x33: op = 51 # BC_OP_LOOP_BACK
                    elif op == 0x35: op = 53 # BC_OP_CLASS
                    elif op == 0x36: op = 54 # BC_OP_METHOD
                    elif op == 0x37: op = 55 # BC_OP_INHERIT
                    elif op == 0x38: op = 56 # BC_OP_SETUP_TRY
                    elif op == 0x39: op = 57 # BC_OP_END_TRY
                    elif op == 0x44: op = 58 # BC_OP_RAISE
                    elif op == 0x08: op = 8  # BC_OP_DEFINE_FUNCTION (aligned)
                    elif op == 0x09: op = 9  # BC_OP_GET_PROPERTY
                    elif op == 0x0a: op = 10 # BC_OP_SET_PROPERTY
                    elif op == 0x0b: op = 11 # BC_OP_GET_INDEX
                    elif op == 0x0c: op = 12 # BC_OP_SET_INDEX
                    elif op == 0x0d: op = 13 # BC_OP_LOAD_FUNCTION
                    elif op == 0x0e: op = 14 # BC_OP_SLICE
                    elif op == 0x45: op = 88 # BC_OP_GET_LOCAL
                    elif op == 0x46: op = 89 # BC_OP_SET_LOCAL
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
                print "DEBUG is_safe_path failed on char='" + str(ch) + "' ord=" + str(ord(ch)) + " path='" + str(path) + "'"
                return false
            i = i + 1
        return true

    proc compile(self, input_file, output_file, use_shebang):
        print "DEBUG SGVMCompiler.compile self.utils=" + str(self.utils) + " input_file=" + str(input_file) + " type=" + str(type(input_file)) + " output_file=" + str(output_file)
        let ut = self.utils
        var in_file = ut.trim(input_file)
        print "DEBUG after trim in_file='" + str(in_file) + "' len=" + str(len(in_file))
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
            var cmd = sage_bin + " --emit-vm " + in_file + " -o " + svm_file
            
            let status = sys_exec(cmd)
            print "DEBUG after sys_exec status=" + str(status)
            if status != 0:
                print "Error: Failed to generate SVM from " + in_file
                return false
        
        let content = io_readfile(svm_file)
        if content == nil:
            print "Error: Could not read SVM file: " + svm_file
            return false
        print "DEBUG after io_readfile content len=" + str(len(content))
        
        let lines = ut.split_lines(content)
        print "DEBUG after split_lines count=" + str(len(lines))
        
        let counts = self.first_pass(lines)
        let function_count = counts[0]
        let chunk_count = counts[1]
        print "DEBUG after first_pass function_count=" + str(function_count) + " chunk_count=" + str(chunk_count)
        
        self.second_pass(lines, function_count, chunk_count, use_shebang)
        print "DEBUG after second_pass output_bytes len=" + str(len(self.output_bytes))
        
        io_writebytes(out_file, self.output_bytes)
        return true
import io
import math
import net
import thread as host_thread
import sys
import gpu
import ml_native


proc gc_collect():
    return nil
proc gc_stats():
    return {"num_objects": 0}
proc gc_enable():
    return nil
proc gc_disable():
    return nil
proc reflect_get_methods(obj):
    return []
proc reflect_get_class(obj):
    return nil

proc is_truthy(val):
    if val == nil or val == false or val == 0:
        return false
    if type(val) == "string" and len(val) == 0:
        return false
    return true

proc str_repeat(s, count):
    if count <= 0:
        return ""
    var res = ""
    var i = 0
    while i < count:
        res = res + s
        i = i + 1
    return res

var g_gil = nil

class MetalVM:
    proc equal_val(self, a, b):
        if type(a) != type(b):
            return false
        if type(a) == "dict":
            let keys_a = dict_keys(a)
            let keys_b = dict_keys(b)
            if len(keys_a) != len(keys_b):
                return false
            var i = 0
            while i < len(keys_a):
                let k = keys_a[i]
                if not dict_has(b, k):
                    return false
                if not self.equal_val(a[k], b[k]):
                    return false
                i = i + 1
            return true
        elif type(a) == "array" or type(a) == "tuple":
            if len(a) != len(b):
                return false
            var i = 0
            while i < len(a):
                if not self.equal_val(a[i], b[i]):
                    return false
                i = i + 1
            return true
        else:
            return a == b

    proc init(self):
        self.stack = []
        self.constants = []
        self.chunks = []
        self.globals = {}
        self.scopes = []
        push(self.scopes, {})
        self.handlers = []
        self.ip = 0
        self.code = []
        self.halted = false
        self.is_throwing = false
        self.exception_value = nil
        self.trace = false
        self.safe_mode = false
        self.ffi_enabled = true
        self.exec_enabled = true
        self.user_args = nil
        self.modules = {}
        self.utils = SGVMUtils()
        # Security: Limits to prevent Denial of Service (DoS) via resource exhaustion
        self.max_stack_depth = 65536
        self.call_depth = 0
        self.max_call_depth = 1024
        self.max_handler_depth = 1024
        self.return_value = nil
        self.returning = false
        self.call_stack = [{"ip": 0, "code": [], "constants": []}]
        # Performance: Cache local_base to avoid dictionary lookups in hot loop
        self.current_local_base = 0

    proc safe_get_constant(self, idx):
        if idx >= 0 and idx < len(self.constants): return self.constants[idx]
        print "Error: Constant pool index out of bounds: " + str(idx)
        self.halted = true
        return nil

    proc safe_get_chunk(self, idx):
        if idx >= 0 and idx < len(self.chunks): return self.chunks[idx]
        print "Error: Chunk index out of bounds: " + str(idx)
        self.halted = true
        return []

    proc setup_builtins(self):
        # Native Bridge: Expose host standard library to guest VM
        self.globals["math"] = {"__host_mod__": math, "printm": "__builtin_math_printm"}
        
        if not self.safe_mode:
            # Security: Only expose sensitive modules to globals if NOT in safe mode
            self.globals["io"] = {"__host_mod__": io}
            self.globals["sys"] = {"__host_mod__": sys}
            self.globals["net"] = {"__host_mod__": net}
            self.globals["thread"] = {"__host_mod__": host_thread}
            self.globals["gpu"] = {"__host_mod__": gpu}
            self.globals["ml_native"] = {"__host_mod__": ml_native}
            self.globals["mem"] = {"__host_mod__": "mem", "alloc": "__builtin_mem_alloc", "free": "__builtin_mem_free", "read": "__builtin_mem_read", "write": "__builtin_mem_write", "size": "__builtin_mem_size"}
            if self.ffi_enabled:
                self.globals["ffi"] = {"__host_mod__": "ffi", "open": "__builtin_ffi_open", "close": "__builtin_ffi_close", "call": "__builtin_ffi_call"}
            self.globals["struct"] = {"__host_mod__": "struct", "def": "__builtin_struct_def", "new": "__builtin_struct_new", "get": "__builtin_struct_get", "set": "__builtin_struct_set", "size": "__builtin_struct_size"}

        self.globals["gc"] = {"__host_mod__": "gc"}
        self.globals["gc"]["collect"] = "__builtin_gc_collect"
        self.globals["gc"]["stats"] = "__builtin_gc_stats"
        self.globals["gc"]["enable"] = "__builtin_gc_enable"
        self.globals["gc"]["disable"] = "__builtin_gc_disable"

        self.globals["reflect"] = {"__host_mod__": "reflect"}
        self.globals["reflect"]["get_methods"] = "__builtin_reflect_get_methods"
        self.globals["reflect"]["get_class"] = "__builtin_reflect_get_class"


        # Core builtins
        self.globals["clock"] = "__builtin_clock"
        self.globals["str"] = "__builtin_str"
        self.globals["int"] = "__builtin_int"
        self.globals["tonumber"] = "__builtin_tonumber"
        self.globals["len"] = "__builtin_len"
        self.globals["print"] = "__builtin_print"
        self.globals["range"] = "__builtin_range"
        self.globals["type"] = "__builtin_type"
        self.globals["slice"] = "__builtin_slice"
        
        # Advanced GC builtins
        self.globals["gc_collect"] = "__builtin_gc_collect"
        self.globals["gc_stats"] = "__builtin_gc_stats"
        self.globals["gc_enable"] = "__builtin_gc_enable"
        self.globals["gc_disable"] = "__builtin_gc_disable"
        
        # Reflection builtins
        self.globals["reflect_get_methods"] = "__builtin_reflect_get_methods"
        self.globals["reflect_get_class"] = "__builtin_reflect_get_class"
        # String/Collection builtins
        self.globals["push"] = "__builtin_push"
        self.globals["pop"] = "__builtin_pop"
        self.globals["chr"] = "__builtin_chr"
        self.globals["ord"] = "__builtin_ord"
        self.globals["startswith"] = "__builtin_startswith"
        self.globals["endswith"] = "__builtin_endswith"
        self.globals["contains"] = "__builtin_contains"
        self.globals["join"] = "__builtin_join"
        self.globals["split"] = "__builtin_split"
        self.globals["replace"] = "__builtin_replace"
        self.globals["upper"] = "__builtin_upper"
        self.globals["lower"] = "__builtin_lower"
        self.globals["strip"] = "__builtin_strip"
        self.globals["dict_has"] = "__builtin_dict_has"
        self.globals["dict_keys"] = "__builtin_dict_keys"
        self.globals["dict_values"] = "__builtin_dict_values"

    proc is_protected(self, obj):
        # Security helper: Check if an object is a protected module or host bridge
        if not self.safe_mode:
            return false

        if type(obj) == "dict":
            if dict_has(obj, "__host_mod__") or (dict_has(obj, "__type__") and obj["__type__"] == "module") or dict_has(obj, "__builtin__"):
                return true
        elif type(obj) == "module":
            return true
        return false

    proc run(self, code):
        self.code = code
        self.ip = 0
        self.halted = false

        # Performance: Cache frequently used properties as local variables
        var ip = 0
        var code_bytes = code
        var halted = false
        let stack = self.stack
        var stack_len = len(stack)
        let max_stack = self.max_stack_depth
        let constants = self.constants
        let scopes = self.scopes
        let globals = self.globals
        let trace = self.trace
        let safe_mode = self.safe_mode
        var local_base = self.current_local_base
        let code_len = len(code_bytes)
        let const_len = len(constants)
        var scopes_len = len(scopes)

        host_thread.lock(g_gil)
        while not halted and ip < code_len:
            let op = code_bytes[ip]
            if trace:
                print "IP: " + str(ip) + " OP: " + str(op) + " Stack: " + str(stack)

            ip = ip + 1

            # Hot-path dispatch: inline most frequent opcodes to avoid function call overhead
            if op == OP_GET_LOCAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if local_base + idx < stack_len:
                    push(stack, stack[local_base + idx])
                else:
                    push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_CONSTANT:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx < const_len:
                    push(stack, constants[idx])
                    stack_len = stack_len + 1
                else:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
            elif op == OP_POP:
                pop(stack)
                stack_len = stack_len - 1
            elif op == OP_GET_GLOBAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx >= const_len:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
                let name = constants[idx]
                if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    push(stack, nil)
                    stack_len = stack_len + 1
                    continue
                # Performance: Fast-path for common scope depths bypassing expensive dict_has where possible
                var found = false
                var si = scopes_len - 1
                while si >= 0:
                    if dict_has(scopes[si], name):
                        push(stack, scopes[si][name])
                        found = true
                        si = -1
                    else:
                        si = si - 1
                if not found:
                    if dict_has(globals, name):
                        push(stack, globals[name])
                    else:
                        push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_SET_LOCAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                let val = stack[stack_len-1]
                while local_base + idx >= stack_len:
                    if stack_len >= max_stack:
                        print "Error: Stack overflow"
                        halted = true
                        break
                    push(stack, nil)
                    stack_len = stack_len + 1
                if halted: break
                stack[local_base + idx] = val
            elif op == OP_ADD:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if type(a) == "string" or type(b) == "string":
                    if a == nil: a = ""
                    if b == nil: b = ""
                    stack[stack_len-1] = str(a) + str(b)
                elif type(a) == "array" and type(b) == "array":
                    let res = []
                    var ai = 0
                    while ai < len(a):
                        push(res, a[ai])
                        ai = ai + 1
                    ai = 0
                    while ai < len(b):
                        push(res, b[ai])
                        ai = ai + 1
                    stack[stack_len-1] = res
                else:
                    if a == nil: a = 0
                    if b == nil: b = 0
                    if type(a) != "number" or type(b) != "number":
                        stack[stack_len-1] = 0
                    else:
                        stack[stack_len-1] = a + b
            elif op == OP_SET_GLOBAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx >= const_len:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
                let name = constants[idx]
                if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    print "Error: Assignment to internal global '" + name + "' is restricted in safe mode"
                    stack[stack_len-1] = nil
                    continue
                let val = stack[stack_len-1]
                # Performance: Fast-path for common scope depths
                if scopes_len == 1:
                    if dict_has(scopes[0], name):
                        scopes[0][name] = val
                    else:
                        globals[name] = val
                elif scopes_len == 2:
                    if dict_has(scopes[1], name):
                        scopes[1][name] = val
                    elif dict_has(scopes[0], name):
                        scopes[0][name] = val
                    else:
                        globals[name] = val
                else:
                    var si = scopes_len - 1
                    var updated = false
                    while si >= 0:
                        if dict_has(scopes[si], name):
                            scopes[si][name] = val
                            updated = true
                            si = -1
                        else:
                            si = si - 1
                    if not updated:
                        globals[name] = val
            elif op == OP_JUMP:
                if stack_len > max_stack:
                    print "Error: Stack overflow"
                    halted = true
                    break
                ip = (code_bytes[ip] << 8) | code_bytes[ip+1]
            elif op == OP_JUMP_IF_FALSE:
                let target = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if not is_truthy(stack[stack_len-1]): ip = target
            elif op == OP_LOOP_BACK:
                if stack_len > max_stack:
                    print "Error: Stack overflow"
                    halted = true
                    break
                ip = ip - ((code_bytes[ip] << 8) | code_bytes[ip+1])
            elif op == OP_LESS:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a < b
                else: stack[stack_len-1] = false
            elif op == OP_MUL:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if type(a) == "string" and type(b) == "number":
                    stack[stack_len-1] = str_repeat(a, int(b))
                elif type(a) == "number" and type(b) == "string":
                    stack[stack_len-1] = str_repeat(b, int(a))
                elif type(a) == "number" and type(b) == "number":
                    stack[stack_len-1] = a * b
                else:
                    stack[stack_len-1] = 0
            elif op == OP_DIV:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if type(a) == "number" and type(b) == "number" and b != 0:
                    stack[stack_len-1] = a / b
                else:
                    stack[stack_len-1] = nil
            elif op == OP_SUB:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if type(a) == "number" and type(b) == "number":
                    stack[stack_len-1] = a - b
                else:
                    stack[stack_len-1] = 0
            elif op == OP_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                stack[stack_len-1] = self.equal_val(stack[stack_len-1], b)
            elif op == OP_NOT_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                stack[stack_len-1] = not self.equal_val(stack[stack_len-1], b)
            elif op == OP_LESS_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                print "DEBUG OP_LESS_EQUAL a=" + str(a) + " (" + str(type(a)) + ") b=" + str(b) + " (" + str(type(b)) + ")"
                if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a <= b
                else: stack[stack_len-1] = false
            elif op == OP_GREATER:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a > b
                else: stack[stack_len-1] = false
            elif op == OP_GREATER_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a >= b
                else: stack[stack_len-1] = false
            elif op == OP_NIL:
                push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_TRUE:
                push(stack, true)
                stack_len = stack_len + 1
            elif op == OP_FALSE:
                push(stack, false)
                stack_len = stack_len + 1
            elif op == OP_DUP:
                let distance = code_bytes[ip]
                ip = ip + 1
                if distance < stack_len:
                    push(stack, stack[stack_len-1-distance])
                else:
                    push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_MOD:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if type(a) == "number" and type(b) == "number" and b != 0:
                    stack[stack_len-1] = a % b
                else:
                    stack[stack_len-1] = nil
            elif op == OP_BIT_AND:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a & b_val
            elif op == OP_BIT_OR:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a | b_val
            elif op == OP_BIT_XOR:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a ^ b_val
            elif op == OP_BIT_NOT:
                if stack[stack_len-1] == nil: stack[stack_len-1] = 0
                else: stack[stack_len-1] = ~stack[stack_len-1]
            elif op == OP_SHIFT_LEFT:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a << b_val
            elif op == OP_SHIFT_RIGHT:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a >> b_val
            elif op == OP_NOT:
                stack[stack_len-1] = not is_truthy(stack[stack_len-1])
            elif op == OP_TRUTHY:
                stack[stack_len-1] = is_truthy(stack[stack_len-1])
            elif op == OP_PRINT:
                print pop(stack)
                stack_len = stack_len - 1
            elif op == OP_NEGATE:
                if stack[stack_len-1] == nil: stack[stack_len-1] = 0
                else: stack[stack_len-1] = -stack[stack_len-1]
            elif op == OP_ARRAY_LEN:
                stack[stack_len-1] = len(stack[stack_len-1])
            elif op == OP_PUSH_ENV:
                if scopes_len >= self.max_call_depth:
                    print "Error: Environment stack depth limit exceeded"
                    halted = true
                    break
                push(scopes, {})
                scopes_len = scopes_len + 1
            elif op == OP_POP_ENV:
                if scopes_len > 1:
                    pop(scopes)
                    scopes_len = scopes_len - 1
                else:
                    print "Error: Environment stack underflow"
                    halted = true
                    break
            elif op == OP_GET_INDEX:
                let idx = stack[stack_len-1]
                let obj = stack[stack_len-2]
                if safe_mode and type(idx) == "string" and startswith(idx, "__") and not startswith(idx, "__arg"):
                    pop(stack)
                    stack[stack_len-2] = nil
                else:
                    pop(stack)
                    if type(obj) == "array" or type(obj) == "tuple":
                        let i_idx = int(idx)
                        if i_idx >= 0 and i_idx < len(obj):
                            stack[stack_len-2] = obj[i_idx]
                        else:
                            stack[stack_len-2] = nil
                    elif type(obj) == "string":
                        let i_idx = int(idx)
                        if i_idx >= 0 and i_idx < len(obj):
                            stack[stack_len-2] = obj[i_idx]
                        else:
                            stack[stack_len-2] = nil
                    elif type(obj) == "dict":
                        if dict_has(obj, idx): stack[stack_len-2] = obj[idx]
                        else: stack[stack_len-2] = nil
                    else:
                        stack[stack_len-2] = nil
                stack_len = stack_len - 1
            elif op == OP_SET_INDEX:
                let val = stack[stack_len-1]
                let idx = stack[stack_len-2]
                let obj = stack[stack_len-3]
                if safe_mode and type(idx) == "string" and startswith(idx, "__") and not startswith(idx, "__arg"):
                    print "Error: Index assignment to internal key '" + idx + "' is restricted in safe mode"
                    pop(stack)
                    pop(stack)
                    stack[stack_len-3] = nil
                elif self.is_protected(obj):
                    print "Error: Index assignment to protected object is restricted in safe mode"
                    pop(stack)
                    pop(stack)
                    stack[stack_len-3] = nil
                else:
                    if type(obj) == "array" or type(obj) == "tuple":
                        let i_idx = int(idx)
                        if i_idx >= 0 and i_idx < len(obj):
                            obj[i_idx] = val
                    elif type(obj) == "dict":
                        obj[idx] = val
                    pop(stack)
                    pop(stack)
                    stack[stack_len-3] = val
                stack_len = stack_len - 2
            elif op == OP_GET_PROPERTY:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx < const_len:
                    let name = constants[idx]
                    let obj = stack[stack_len-1]
                    if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                        stack[stack_len-1] = nil
                    elif type(obj) == "dict":
                        if dict_has(obj, name):
                            stack[stack_len-1] = obj[name]
                        elif dict_has(obj, "__class__") and dict_has(obj["__class__"]["__methods__"], name):
                            stack[stack_len-1] = obj["__class__"]["__methods__"][name]
                        elif dict_has(obj, "__methods__") and dict_has(obj["__methods__"], name):
                            stack[stack_len-1] = obj["__methods__"][name]
                        elif dict_has(obj, "__type__") and obj["__type__"] == "module" and dict_has(scopes[0], name):
                            stack[stack_len-1] = scopes[0][name]
                        else:
                            stack[stack_len-1] = nil
                    else:
                        stack[stack_len-1] = obj[name]
                else:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
            elif op == OP_SET_PROPERTY:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx < const_len:
                    let name = constants[idx]
                    let val = stack[stack_len-1]
                    let obj = stack[stack_len-2]
                    if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                        print "Error: Access to internal property '" + name + "' is restricted in safe mode"
                        pop(stack)
                        stack[stack_len-2] = nil
                    elif self.is_protected(obj):
                        print "Error: Modification of protected object '" + name + "' is restricted in safe mode"
                        pop(stack)
                        stack[stack_len-2] = nil
                    else:
                        obj[name] = val
                        pop(stack)
                        stack[stack_len-2] = val
                    stack_len = stack_len - 1
                else:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
            else:
                # Synchronize local state back to self before calling non-inlined execute_op
                self.ip = ip
                self.halted = halted
                self.current_local_base = local_base
                if not self.execute_op(op):
                    # execute_op may have modified halted/ip/local_base
                    halted = self.halted
                    break
                # Restore local state after execute_op
                ip = self.ip
                code_bytes = self.code
                code_len = len(code_bytes)
                halted = self.halted
                local_base = self.current_local_base
                scopes_len = len(scopes)
                stack_len = len(stack)

        # Final synchronization
        self.ip = ip
        self.halted = halted
        self.current_local_base = local_base
        host_thread.unlock(g_gil)

    proc call_builtin(self, callee, args):
        let argc = len(args)
        if callee == "__builtin_clock":
            return clock()
        elif callee == "__builtin_str":
            return str(args[0])
        elif callee == "__builtin_int":
            if len(args) == 0 or args[0] == nil:
                return 0
            if type(args[0]) == "string":
                let n = tonumber(args[0])
                if n == nil: return 0
                return int(n)
            return int(args[0])
        elif callee == "__builtin_tonumber":
            if len(args) == 0 or args[0] == nil: return nil
            return tonumber(args[0])
        elif callee == "__builtin_len":
            if len(args) == 0 or args[0] == nil: return 0
            return len(args[0])
        elif callee == "__builtin_print":
            print args[0]
            return nil
        elif callee == "__builtin_range":
            return range(args[0])
        elif callee == "__builtin_type":
            return type(args[0])
        elif callee == "__builtin_slice":
            var s0 = args[0]
            var s1 = args[1]
            var s2 = args[2]
            if s0 == nil: return ""
            if s1 == nil: s1 = 0
            if s2 == nil: s2 = len(s0)
            return slice(s0, s1, s2)
        elif callee == "__builtin_startswith":
            if args[0] == nil or args[1] == nil: return false
            return startswith(args[0], args[1])
        elif callee == "__builtin_endswith":
            if args[0] == nil or args[1] == nil: return false
            return endswith(args[0], args[1])
        elif callee == "__builtin_contains":
            if args[0] == nil or args[1] == nil: return false
            return contains(args[0], args[1])
        elif callee == "__builtin_math_printm":
            let matrix = args[0]
            if type(matrix) != "array":
                print "Error: math.printm() expects an array"
            else:
                print "["
                var mi = 0
                while mi < len(matrix):
                    let row = matrix[mi]
                    if type(row) == "array":
                        var parts = []
                        var mj = 0
                        while mj < len(row):
                            push(parts, str(row[mj]))
                            mj = mj + 1
                        print "  [" + join(parts, ", ") + "]"
                    else:
                        print "  " + str(row)
                    mi = mi + 1
                print "]"
            return nil
        elif callee == "__builtin_mem_alloc":
            if self.safe_mode:
                print "Error: mem_alloc is restricted in safe mode"
                return nil
            return mem_alloc(args[0])
        elif callee == "__builtin_mem_free":
            if self.safe_mode:
                print "Error: mem_free is restricted in safe mode"
                return nil
            return mem_free(args[0])
        elif callee == "__builtin_mem_read":
            if self.safe_mode:
                print "Error: mem_read is restricted in safe mode"
                return nil
            return mem_read(args[0], args[1], args[2])
        elif callee == "__builtin_mem_write":
            if self.safe_mode:
                print "Error: mem_write is restricted in safe mode"
                return nil
            return mem_write(args[0], args[1], args[2], args[3])
        elif callee == "__builtin_mem_size":
            if self.safe_mode:
                print "Error: mem_size is restricted in safe mode"
                return nil
            return mem_size(args[0])
        elif callee == "__builtin_ffi_open":
            if self.safe_mode:
                print "Error: ffi_open is restricted in safe mode"
                return nil
            return ffi_open(args[0])
        elif callee == "__builtin_ffi_close":
            if self.safe_mode:
                print "Error: ffi_close is restricted in safe mode"
                return nil
            return ffi_close(args[0])
        elif callee == "__builtin_ffi_call":
            if self.safe_mode:
                print "Error: ffi_call is restricted in safe mode"
                return nil
            # Note: ffi_call might be a stub in some backends
            try:
                if argc == 3: return ffi_call(args[0], args[1], args[2])
                else: return ffi_call(args[0], args[1], args[2], args[3])
            catch e:
                print "Error: ffi_call failed: " + str(e)
                return nil
        elif callee == "__builtin_struct_def":
            if self.safe_mode:
                print "Error: struct_def is restricted in safe mode"
                return nil
            return struct_def(args[0])
        elif callee == "__builtin_struct_new":
            if self.safe_mode:
                print "Error: struct_new is restricted in safe mode"
                return nil
            return struct_new(args[0])
        elif callee == "__builtin_struct_get":
            if self.safe_mode:
                print "Error: struct_get is restricted in safe mode"
                return nil
            return struct_get(args[0], args[1], args[2])
        elif callee == "__builtin_struct_set":
            if self.safe_mode:
                print "Error: struct_set is restricted in safe mode"
                return nil
            return struct_set(args[0], args[1], args[2], args[3])
        elif callee == "__builtin_struct_size":
            if self.safe_mode:
                print "Error: struct_size is restricted in safe mode"
                return nil
            return struct_size(args[0])
        elif callee == "__builtin_sys_exec":
            if self.safe_mode:
                print "Error: sys.exec is restricted in safe mode"
                return nil
            return sys_exec(args[0])
        elif callee == "__builtin_sys_system":
            if self.safe_mode:
                print "Error: sys.system is restricted in safe mode"
                return -1
            return sys.system(args[0])
        elif callee == "__builtin_sys_exit":
            self.halted = true
            return nil
        elif callee == "__builtin_sys_getenv":
            if len(args) > 0 and type(args[0]) == "string":
                return sys.getenv(args[0])
            return nil
        elif callee == "__builtin_io_writebytes":
            if self.safe_mode:
                print "Error: io.writebytes is restricted in safe mode"
                return nil
            if len(args) < 2 or args[0] == nil or args[1] == nil: return false
            return io.writebytes(args[0], args[1])
        elif callee == "__builtin_io_readbytes":
            if self.safe_mode:
                print "Error: io.readbytes is restricted in safe mode"
                return nil
            if len(args) == 0 or args[0] == nil or type(args[0]) != "string": return nil
            return io.readbytes(args[0])
        elif callee == "__builtin_io_readfile":
            if self.safe_mode:
                print "Error: io.readfile is restricted in safe mode"
                return nil
            if len(args) == 0 or args[0] == nil or type(args[0]) != "string": return nil
            return io.readfile(args[0])
        elif callee == "__builtin_thread_mutex":
            return nil
        elif callee == "__builtin_gpu_get_time":
            return 0.0
        elif callee == "__builtin_gpu_poll_events":
            return nil
        elif callee == "__builtin_gpu_mouse_pos":
            return {"x": 0, "y": 0}
        elif callee == "__builtin_gc_collect": return gc_collect()
        elif callee == "__builtin_gc_stats": return gc_stats()
        elif callee == "__builtin_gc_enable": return gc_enable()
        elif callee == "__builtin_gc_disable": return gc_disable()
        elif callee == "__builtin_reflect_get_methods": return reflect_get_methods(args[0])
        elif callee == "__builtin_reflect_get_class": return reflect_get_class(args[0])
        elif callee == "__builtin_push":
            push(args[0], args[1])
            return nil
        elif callee == "__builtin_pop":
            return pop(args[0])
        elif callee == "__builtin_chr":
            if len(args) == 0 or args[0] == nil: return ""
            return chr(int(args[0]))
        elif callee == "__builtin_ord":
            if len(args) == 0 or args[0] == nil or type(args[0]) != "string" or len(args[0]) == 0: return 0
            return ord(args[0])
        elif callee == "__builtin_startswith":
            return startswith(args[0], args[1])
        elif callee == "__builtin_endswith":
            return endswith(args[0], args[1])
        elif callee == "__builtin_contains":
            return contains(args[0], args[1])
        elif callee == "__builtin_join":
            return join(args[0], args[1])
        elif callee == "__builtin_split":
            return split(args[0], args[1])
        elif callee == "__builtin_replace":
            return replace(args[0], args[1], args[2])
        elif callee == "__builtin_upper":
            return upper(args[0])
        elif callee == "__builtin_lower":
            return lower(args[0])
        elif callee == "__builtin_strip":
            return strip(args[0])
        elif callee == "__builtin_dict_has":
            return dict_has(args[0], args[1])
        elif callee == "__builtin_dict_keys":
            return dict_keys(args[0])
        elif callee == "__builtin_dict_values":
            return dict_values(args[0])
        else:
            print "Error: Unknown builtin: " + callee
            return nil

    proc execute_op(self, op):
        let ut = self.utils
        if op == OP_CONSTANT:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            push(self.stack, self.safe_get_constant(idx))
        elif op == OP_NIL:
            push(self.stack, nil)
        elif op == OP_TRUE:
            push(self.stack, true)
        elif op == OP_FALSE:
            push(self.stack, false)
        elif op == OP_POP:
            pop(self.stack)
        elif op == OP_DUP:
            let distance = int(self.code[self.ip])
            self.ip = self.ip + 1
            if distance < len(self.stack):
                push(self.stack, self.stack[len(self.stack)-1-distance])
            else:
                push(self.stack, nil)
        elif op == OP_GET_GLOBAL:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.safe_get_constant(idx)
            if self.halted: return false

            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                push(self.stack, nil)
                return true

            if self.trace: print "DEBUG: GET_GLOBAL " + name
            var found = false
            var si = len(self.scopes) - 1
            while si >= 0:
                if dict_has(self.scopes[si], name):
                    let val = self.scopes[si][name]
                    if self.trace: print "DEBUG: Found " + name + " in scope " + str(si) + ": " + str(val)
                    push(self.stack, val)
                    found = true
                    si = -1
                else:
                    si = si - 1
            if not found:
                if dict_has(self.globals, name):
                    let val = self.globals[name]
                    if self.trace: print "DEBUG: Found " + name + " in globals: " + str(val)
                    push(self.stack, val)
                else:
                    if self.trace: print "DEBUG: Not found " + name
                    push(self.stack, nil)
        elif op == OP_DEFINE_GLOBAL:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            if idx >= len(self.constants):
                print "Error: Constant pool index out of bounds: " + str(idx)
                self.halted = true
                return false
            let name = self.constants[idx]
            let val = pop(self.stack)
            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                 print "Error: Definition of internal global '" + name + "' is restricted in safe mode"
            else:
                 self.scopes[len(self.scopes)-1][name] = val
        elif op == OP_SET_GLOBAL:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.safe_get_constant(idx)
            if self.halted: return false
            let val = pop(self.stack)

            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                print "Error: Assignment to internal global '" + name + "' is restricted in safe mode"
                push(self.stack, nil)
                return true

            var si = len(self.scopes) - 1
            var updated = false
            while si >= 0:
                if dict_has(self.scopes[si], name):
                    self.scopes[si][name] = val
                    updated = true
                    si = -1
                else:
                    si = si - 1
            if not updated:
                self.globals[name] = val
            push(self.stack, val)
        elif op == OP_ADD:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if type(a) == "string" or type(b) == "string":
                if a == nil: a = ""
                if b == nil: b = ""
                push(self.stack, str(a) + str(b))
            elif type(a) == "array" and type(b) == "array":
                let res = []
                var ai = 0
                while ai < len(a):
                    push(res, a[ai])
                    ai = ai + 1
                ai = 0
                while ai < len(b):
                    push(res, b[ai])
                    ai = ai + 1
                push(self.stack, res)
            else:
                if a == nil: a = 0
                if b == nil: b = 0
                if type(a) != "number" or type(b) != "number":
                    push(self.stack, 0)
                else:
                    push(self.stack, a + b)
        elif op == OP_SUB:
            let b = pop(self.stack)
            let a = pop(self.stack)
            push(self.stack, a - b)
        elif op == OP_MUL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "string" and type(b) == "number":
                push(self.stack, str_repeat(a, int(b)))
            elif type(a) == "number" and type(b) == "string":
                push(self.stack, str_repeat(b, int(a)))
            else:
                push(self.stack, a * b)
        elif op == OP_DIV:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if b == 0:
                push(self.stack, nil)
            else:
                push(self.stack, a / b)
        elif op == OP_MOD:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if b == 0:
                push(self.stack, nil)
            else:
                push(self.stack, a % b)
        elif op == OP_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            push(self.stack, self.equal_val(a, b))
        elif op == OP_NOT_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            push(self.stack, not self.equal_val(a, b))
        elif op == OP_GREATER:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a > b)
            else: push(self.stack, false)
        elif op == OP_GREATER_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a >= b)
            else: push(self.stack, false)
        elif op == OP_LESS:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a < b)
            else: push(self.stack, false)
        elif op == OP_LESS_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a <= b)
            else: push(self.stack, false)
        elif op == OP_BIT_AND:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a & b)
        elif op == OP_BIT_OR:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a | b)
        elif op == OP_BIT_XOR:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a ^ b)
        elif op == OP_BIT_NOT:
            push(self.stack, ~pop(self.stack))
        elif op == OP_SHIFT_LEFT:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a << b)
        elif op == OP_SHIFT_RIGHT:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a >> b)
        elif op == OP_TRUTHY:
            push(self.stack, is_truthy(pop(self.stack)))
        elif op == OP_JUMP:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            self.ip = ut.read_be16(self.code, self.ip)
        elif op == OP_JUMP_IF_FALSE:
            let target = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let st = self.stack
            let st_len = len(st)
            let idx = st_len - 1
            let cond = st[idx]
            if not is_truthy(cond): self.ip = target
        elif op == OP_LOOP_BACK:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            self.ip = self.ip - ut.read_be16(self.code, self.ip)
        elif op == OP_PRINT:
            print pop(self.stack)
        elif op == OP_MATH_PRINTM:
            let matrix = pop(self.stack)
            self.call_builtin("__builtin_math_printm", [matrix])
            push(self.stack, nil)
        elif op == OP_ARRAY:
            let count = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let arr = []
            var j = 0
            while j < count:
                push(arr, nil)
                j = j + 1
            j = 0
            while j < count:
                arr[count - 1 - j] = pop(self.stack)
                j = j + 1
            push(self.stack, arr)
        elif op == OP_TUPLE:
            let count = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let t = []
            var j = 0
            while j < count:
                push(t, nil)
                j = j + 1
            j = 0
            while j < count:
                t[count - 1 - j] = pop(self.stack)
                j = j + 1
            push(self.stack, t)
        elif op == OP_DICT:
            let count = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let d = {}
            var j = 0
            while j < count:
                let val = pop(self.stack)
                let key = pop(self.stack)
                d[key] = val
                j = j + 1
            push(self.stack, d)
        elif op == OP_SLICE:
            let end_idx = pop(self.stack)
            let start_idx = pop(self.stack)
            let obj = pop(self.stack)
            push(self.stack, slice(obj, start_idx, end_idx))
        elif op == OP_DEFINE_FUNCTION:
            let name_idx = ut.read_be16(self.code, self.ip)
            let chunk_idx = ut.read_be16(self.code, self.ip + 2)
            self.ip = self.ip + 4
            let name = self.constants[name_idx]
            let func_obj = {"__type__": "function", "__chunk__": chunk_idx, "__name__": name}
            self.scopes[len(self.scopes)-1][name] = func_obj
        elif op == OP_LOAD_FUNCTION:
            let chunk_idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            if chunk_idx < 0 or chunk_idx >= len(self.chunks):
                print "Error: Chunk index out of bounds: " + str(chunk_idx)
                self.halted = true
                return false
            push(self.stack, {"__type__": "function", "__chunk__": chunk_idx})
        elif op == OP_CALL:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            let argc = int(self.code[self.ip])
            self.ip = self.ip + 1
            let args = []
            var j = 0
            while j < argc:
                push(args, nil)
                j = j + 1
            j = 0
            while j < argc:
                args[argc - 1 - j] = pop(self.stack)
                j = j + 1
            let callee = pop(self.stack)
            if type(callee) == "dict":
                if dict_has(callee, "__type__"):
                    let ctype = callee["__type__"]
                    if ctype == "function":
                        # Security: Prevent infinite recursion from exhausting host resources (DoS)
                        if len(self.call_stack) >= self.max_call_depth:
                            print "Error: Call depth limit exceeded"
                            self.halted = true
                            return false
                        let local_base = len(self.stack)
                        push(self.call_stack, {"ip": self.ip, "code": self.code, "local_base": local_base})
                        let c_idx = callee["__chunk__"]
                        if c_idx < 0 or c_idx >= len(self.chunks):
                            print "Error: Chunk index out of bounds: " + str(c_idx)
                            self.halted = true
                            return false
                        self.code = self.chunks[c_idx]
                        self.ip = 0
                        # Performance: Update cached local_base for the new frame
                        self.current_local_base = local_base
                        push(self.scopes, {})
                        j = 0
                        while j < argc:
                            push(self.stack, args[j])
                            let arg_name = "__arg" + str(j)
                            self.scopes[len(self.scopes)-1][arg_name] = args[j]
                            j = j + 1
                    elif ctype == "class":
                        let instance = {"__type__": "instance", "__class__": callee}
                        if dict_has(callee["__methods__"], "init"):
                            let init_func = callee["__methods__"]["init"]
                            # Security: Prevent infinite recursion from exhausting host resources (DoS)
                            if len(self.call_stack) >= self.max_call_depth:
                                print "Error: Call depth limit exceeded"
                                self.halted = true
                                return false
                            let local_base = len(self.stack)
                            push(self.call_stack, {"ip": self.ip, "code": self.code, "local_base": local_base, "__is_constructor__": true, "__instance__": instance})
                            self.code = self.chunks[init_func["__chunk__"]]
                            self.ip = 0
                            # Performance: Update cached local_base for the new frame
                            self.current_local_base = local_base
                            push(self.scopes, {})
                            # Pass self as __arg0
                            push(self.stack, instance)
                            self.scopes[len(self.scopes)-1]["__arg0"] = instance
                            j = 0
                            while j < argc:
                                push(self.stack, args[j])
                                let arg_name = "__arg" + str(j + 1)
                                self.scopes[len(self.scopes)-1][arg_name] = args[j]
                                j = j + 1
                        else:
                            push(self.stack, instance)
                    else:
                        print "Error: Callee dict is not a function or class. callee=" + str(callee) + " type=" + str(ctype)
                else:
                    print "Error: Callee dict has no __type__"
            elif type(callee) == "string":
                push(self.stack, self.call_builtin(callee, args))
                if self.halted: return false
            elif type(callee) == "function" or type(callee) == "native fn":
                if self.safe_mode:
                    print "Error: Direct host function call is restricted in safe mode"
                    push(self.stack, nil)
                else:
                    # Delegation Bridge: using sys.call to avoid AOT tracing issues
                    if argc == 0: push(self.stack, sys.call(callee))
                    elif argc == 1: push(self.stack, sys.call(callee, args[0]))
                    elif argc == 2: push(self.stack, sys.call(callee, args[0], args[1]))
                    elif argc == 3: push(self.stack, sys.call(callee, args[0], args[1], args[2]))
                    elif argc == 4: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3]))
                    elif argc == 5: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4]))
                    elif argc == 6: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4], args[5]))
                    elif argc == 7: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4], args[5], args[6]))
                    elif argc == 8: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
                    else:
                        print "Error: Host call with >8 args not implemented"
                        push(self.stack, nil)
            else:
                print "Error: Callee not a function or builtin name"
        elif op == OP_CALL_METHOD:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            let name_idx = ut.read_be16(self.code, self.ip)
            let argc = int(self.code[self.ip + 2])
            self.ip = self.ip + 3
            let name = self.constants[name_idx]
            let args = []
            var j = 0
            while j < argc:
                push(args, nil)
                j = j + 1
            j = 0
            while j < argc:
                args[argc - 1 - j] = pop(self.stack)
                j = j + 1
            let obj = pop(self.stack)

            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                push(self.stack, nil)
                return true

            var is_class_call = false
            var method = nil
            if dict_has(obj, "__methods__") and dict_has(obj["__methods__"], name):
                method = obj["__methods__"][name]
                is_class_call = true
            elif dict_has(obj, "__class__") and dict_has(obj["__class__"]["__methods__"], name):
                method = obj["__class__"]["__methods__"][name]
            
            if method != nil:
                # Security: Prevent infinite recursion from exhausting host resources (DoS)
                if len(self.call_stack) >= self.max_call_depth:
                    print "Error: Call depth limit exceeded"
                    self.halted = true
                    return false
                let local_base = len(self.stack)
                push(self.call_stack, {"ip": self.ip, "code": self.code, "local_base": local_base})
                self.code = self.chunks[method["__chunk__"]]
                self.ip = 0
                # Performance: Update cached local_base for the new frame
                self.current_local_base = local_base
                push(self.scopes, {})
                
                if is_class_call:
                    # Direct class method call (e.g. Base.init(self, name))
                    j = 0
                    while j < argc:
                        push(self.stack, args[j])
                        let arg_name = "__arg" + str(j)
                        self.scopes[len(self.scopes)-1][arg_name] = args[j]
                        j = j + 1
                else:
                    # Instance method call (e.g. obj.greet())
                    # Pass self as __arg0
                    push(self.stack, obj)
                    self.scopes[len(self.scopes)-1]["__arg0"] = obj
                    j = 0
                    while j < argc:
                        push(self.stack, args[j])
                        let arg_name = "__arg" + str(j + 1)
                        self.scopes[len(self.scopes)-1][arg_name] = args[j]
                        j = j + 1
            elif type(obj) == "module" or (type(obj) == "dict" and dict_has(obj, "__type__") and obj["__type__"] == "module"):
                # Host module method/attribute access
                if dict_has(obj, name):
                    let val = obj[name]
                    if type(val) == "function" or type(val) == "native fn":
                        if argc == 0: push(self.stack, sys.call(val))
                        elif argc == 1: push(self.stack, sys.call(val, args[0]))
                        elif argc == 2: push(self.stack, sys.call(val, args[0], args[1]))
                        elif argc == 3: push(self.stack, sys.call(val, args[0], args[1], args[2]))
                        elif argc == 4: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3]))
                        elif argc == 5: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4]))
                        elif argc == 6: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5]))
                        elif argc == 7: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6]))
                        elif argc == 8: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
                        else:
                            print "Error: Host module call with >8 args not implemented"
                            push(self.stack, nil)
                    elif type(val) == "string" and startswith(val, "__builtin_"):
                        push(self.stack, self.call_builtin(val, args))
                    else:
                        push(self.stack, val)
                else:
                    print "Error: Module attribute " + name + " not found"
            else:
                # Host primitive or object method call bridge
                if dict_has(obj, name):
                    let val = obj[name]
                    if type(val) == "function" or type(val) == "native fn":
                        if argc == 0: push(self.stack, sys.call(val))
                        elif argc == 1: push(self.stack, sys.call(val, args[0]))
                        elif argc == 2: push(self.stack, sys.call(val, args[0], args[1]))
                        elif argc == 3: push(self.stack, sys.call(val, args[0], args[1], args[2]))
                        elif argc == 4: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3]))
                        elif argc == 5: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4]))
                        elif argc == 6: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5]))
                        elif argc == 7: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6]))
                        elif argc == 8: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
                        else:
                            print "Error: Host method call with >8 args not implemented"
                            push(self.stack, nil)
                    elif type(val) == "string" and startswith(val, "__builtin_"):
                        push(self.stack, self.call_builtin(val, args))
                    else:
                        push(self.stack, val)
                else:
                    print "Error: Method " + name + " not found"
        elif op == OP_RETURN:
            let val = pop(self.stack)
            # Security: Pop exception handlers belonging to the current frame to prevent leaks
            while len(self.handlers) > 0:
                let h = self.handlers[len(self.handlers)-1]
                if h["call_depth"] >= len(self.call_stack):
                    pop(self.handlers)
                else:
                    break
            
            if len(self.call_stack) > 0:
                if len(self.scopes) > 1:
                    pop(self.scopes)
                let frame = pop(self.call_stack)
                self.ip = frame["ip"]
                self.code = frame["code"]
                if dict_has(frame, "local_base"):
                    while len(self.stack) > frame["local_base"]:
                        pop(self.stack)

                # Performance: Restore local_base from the parent frame
                if len(self.call_stack) > 0:
                    let top = self.call_stack[len(self.call_stack)-1]
                    if dict_has(top, "local_base"): self.current_local_base = top["local_base"]
                    else: self.current_local_base = 0
                else: self.current_local_base = 0
                if dict_has(frame, "__is_constructor__"):
                    push(self.stack, frame["__instance__"])
                else:
                    push(self.stack, val)
            else:
                self.halted = true
                self.return_value = val
        elif op == OP_HALT:
            self.halted = true
            return false
        elif op == OP_CLASS:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.constants[idx]
            let cls = {"__type__": "class", "__name__": name, "__methods__": {}}
            self.scopes[len(self.scopes)-1][name] = cls
            push(self.stack, cls)
        elif op == OP_METHOD:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.constants[idx]
            let func = pop(self.stack)
            let cls = self.stack[len(self.stack)-1]
            cls["__methods__"][name] = func
        elif op == OP_INHERIT:
            let cls = pop(self.stack)
            let parent = pop(self.stack)
            if type(parent) == "dict":
                if dict_has(parent, "__methods__"):
                    let methods = parent["__methods__"]
                    let keys = dict_keys(methods)
                    var k = 0
                    while k < len(keys):
                        let mname = keys[k]
                        if not dict_has(cls["__methods__"], mname):
                            cls["__methods__"][mname] = methods[mname]
                        k = k + 1
                else:
                    # Host class inheritance bridge (copy host attributes)
                    let keys = dict_keys(parent)
                    var k = 0
                    while k < len(keys):
                        let mname = keys[k]
                        if not dict_has(cls["__methods__"], mname):
                            cls["__methods__"][mname] = parent[mname]
                        k = k + 1
            push(self.stack, cls)
        elif op == OP_IMPORT:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.constants[idx]
            # Delegation Bridge: check host first for native modules
            # Security: Explicitly block 'io' in safe mode blacklist
            if self.safe_mode and (name == "io" or name == "net" or name == "sys" or name == "thread" or name == "gpu" or name == "ml_native" or name == "mem" or name == "ffi" or name == "struct"):
                print "Error: Access to module '" + name + "' is restricted in safe mode"
                push(self.stack, nil)
            elif name == "ffi" and not self.ffi_enabled:
                print "Error: FFI is disabled"
                push(self.stack, nil)
            else:
                try:
                    if name == "math":
                        let m = {"pi": 3.141592653589793, "e": 2.718281828459045}
                        m["__type__"] = "module"
                        m["abs"] = math.abs
                        m["sqrt"] = math.sqrt
                        m["sin"] = math.sin
                        m["cos"] = math.cos
                        m["printm"] = "__builtin_math_printm"
                        push(self.stack, m)
                    elif name == "io":
                        let iom = {}
                        iom["__type__"] = "module"
                        iom["readfile"] = "__builtin_io_readfile"
                        iom["readbytes"] = "__builtin_io_readbytes"
                        iom["writebytes"] = "__builtin_io_writebytes"
                        iom["writefile"] = io.writefile
                        push(self.stack, iom)
                    elif name == "sys":
                        var sys_args_list = sys.args()
                        if self.user_args != nil:
                            sys_args_list = self.user_args
                        let s = {"args": sys_args_list}
                        s["__type__"] = "module"
                        s["exec"] = "__builtin_sys_exec"
                        s["system"] = "__builtin_sys_exec"
                        s["exit"] = "__builtin_sys_exit"
                        s["getenv"] = "__builtin_sys_getenv"
                        push(self.stack, s)
                    elif name == "net": push(self.stack, net)
                    elif name == "gpu":
                        let g = {}
                        g["__type__"] = "module"
                        g["poll_events"] = "__builtin_gpu_poll_events"
                        g["get_time"] = "__builtin_gpu_get_time"
                        g["mouse_pos"] = "__builtin_gpu_mouse_pos"
                        push(self.stack, g)
                    elif name == "ml_native": push(self.stack, ml_native)
                    elif name == "thread":
                        let tm = {}
                        tm["__type__"] = "module"
                        tm["mutex"] = "__builtin_thread_mutex"
                        push(self.stack, tm)
                    elif name == "mem": push(self.stack, self.globals["mem"])
                    elif name == "ffi": push(self.stack, self.globals["ffi"])
                    elif name == "struct": push(self.stack, self.globals["struct"])
                    else:
                        # Dynamic loading of user .sage modules
                        var mod_path = name + ".sage"
                        if io.readbytes(mod_path) == nil:
                            if io.readbytes("src/" + name + ".sage") != nil:
                                mod_path = "src/" + name + ".sage"
                            elif io.readbytes("src/svm/" + name + ".sage") != nil:
                                mod_path = "src/svm/" + name + ".sage"
                            elif io.readbytes("src/srvm/" + name + ".sage") != nil:
                                mod_path = "src/srvm/" + name + ".sage"
                        
                        let mod_bytes = io.readbytes(mod_path)
                        if mod_bytes != nil:
                            let mod_src = io.readfile(mod_path)
                            if mod_src != nil:
                                self.call_builtin("__builtin_sys_exec", [mod_src])
                                push(self.stack, {"__type__": "module", "__name__": name})
                            else:
                                push(self.stack, {"__type__": "module", "__name__": name})
                        else:
                            push(self.stack, {"__type__": "module", "__name__": name})
                catch e:
                    push(self.stack, {"__type__": "module", "__name__": name})
        elif op == OP_SETUP_TRY:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            let handler = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            # Security: Prevent nested handlers from exhausting VM memory (DoS)
            if len(self.handlers) >= self.max_handler_depth:
                print "Error: Handler depth limit exceeded"
                self.halted = true
                return false
            # Store context for unwinding: ip, stack size, call depth, scopes depth, and current code chunk
            push(self.handlers, {
                "ip": handler, 
                "stack_size": len(self.stack),
                "call_depth": len(self.call_stack),
                "scopes_len": len(self.scopes),
                "code": self.code
            })
        elif op == OP_END_TRY:
            pop(self.handlers)
        elif op == OP_RAISE:
            let val = pop(self.stack)
            self.exception_value = val
            self.is_throwing = true
            if len(self.handlers) > 0:
                let h = pop(self.handlers)
                
                # Unwind call stack to the frame where the handler was defined
                while len(self.call_stack) > h["call_depth"]:
                    pop(self.scopes)
                    pop(self.call_stack)
                
                # Unwind local scopes within that frame
                while len(self.scopes) > h["scopes_len"]:
                    pop(self.scopes)
                
                # Restore execution state
                self.code = h["code"]
                self.ip = h["ip"]
                
                # Performance: Update local_base after unwinding
                if len(self.call_stack) > 0:
                    let top = self.call_stack[len(self.call_stack)-1]
                    if dict_has(top, "local_base"): self.current_local_base = top["local_base"]
                    else: self.current_local_base = 0
                else: self.current_local_base = 0

                # Clear operand stack to the state when the handler was established
                while len(self.stack) > h["stack_size"]:
                    pop(self.stack)
                
                # Push the exception value for the catch block
                push(self.stack, self.exception_value)
                self.is_throwing = false
            else:
                print "Unhandled exception: " + str(val)
                self.halted = true
        elif op == OP_EXEC_AST_STMT:
            if self.safe_mode or not self.exec_enabled:
                print "Error: Code execution is restricted"
                self.ip = self.ip + 2
                return true
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let ast_code = self.constants[idx]
            if type(ast_code) == "string":
                # Fallback: Use host execution engine for non-lowered code
                sys.exec(ast_code)
            else:
                print "Error: OP_EXEC_AST_STMT requires a string constant"
        elif op == OP_GET_LOCAL:
            # Performance: Inline BE16 and use cached local_base
            let idx = (int(self.code[self.ip]) << 8) | int(self.code[self.ip+1])
            self.ip = self.ip + 2
            let base = self.current_local_base
            if base + idx < len(self.stack):
                push(self.stack, self.stack[base + idx])
            else: push(self.stack, nil)
        elif op == OP_SET_LOCAL:
            # Performance: Inline BE16 and use cached local_base
            let idx = (int(self.code[self.ip]) << 8) | int(self.code[self.ip+1])
            self.ip = self.ip + 2
            let val = pop(self.stack)
            let base = self.current_local_base
            while base + idx >= len(self.stack):
                if len(self.stack) >= self.max_stack_depth:
                    print "Error: Stack overflow"
                    self.halted = true
                    return false
                push(self.stack, nil)
            self.stack[base + idx] = val
            push(self.stack, val)
        elif op == OP_BREAK:
            print "Error: Unexpected loop break opcode"
            self.halted = true
        elif op == OP_CONTINUE:
            print "Error: Unexpected loop continue opcode"
            self.halted = true
        elif op >= OP_GPU_POLL_EVENTS and op < OP_GET_LOCAL:
            if op == OP_GPU_WINDOW_SHOULD_CLOSE or op == OP_GPU_KEY_PRESSED or op == OP_GPU_KEY_DOWN:
                push(self.stack, false)
            elif op == OP_GPU_GET_TIME:
                push(self.stack, 0.0)
            elif op == OP_GPU_MOUSE_POS or op == OP_GPU_MOUSE_DELTA:
                push(self.stack, {"x": 0, "y": 0})
            return true
        elif op == OP_GPU_BEGIN_COMMANDS: push(self.stack, gpu.begin_commands(pop(self.stack)))
        elif op == OP_GPU_END_COMMANDS: push(self.stack, gpu.end_commands(pop(self.stack)))
        elif op == OP_GPU_CMD_BEGIN_RP:
             let ca = pop(self.stack)
             let h = pop(self.stack)
             let w = pop(self.stack)
             let fb = pop(self.stack)
             let rp = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_begin_render_pass(cmd, rp, fb, w, h, ca)
        elif op == OP_GPU_CMD_END_RP: gpu.cmd_end_render_pass(pop(self.stack))
        elif op == OP_GPU_CMD_DRAW:
             let fi = pop(self.stack)
             let fv = pop(self.stack)
             let inst = pop(self.stack)
             let verts = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_draw(cmd, verts, inst, fv, fi)
        elif op == OP_GPU_CMD_BIND_GP:
             let gp = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_graphics_pipeline(cmd, gp)
        elif op == OP_GPU_CMD_BIND_DS:
             let bp = pop(self.stack)
             let set = pop(self.stack)
             let lay = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_descriptor_set(cmd, lay, set, bp)
        elif op == OP_GPU_CMD_SET_VP:
             let maxd = pop(self.stack)
             let mind = pop(self.stack)
             let vh = pop(self.stack)
             let vw = pop(self.stack)
             let vy = pop(self.stack)
             let vx = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_set_viewport(cmd, vx, vy, vw, vh, mind, maxd)
        elif op == OP_GPU_CMD_SET_SC:
             let sh = pop(self.stack)
             let sw = pop(self.stack)
             let sy = pop(self.stack)
             let sx = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_set_scissor(cmd, sx, sy, sw, sh)
        elif op == OP_GPU_CMD_BIND_VB:
             let buf = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_vertex_buffer(cmd, buf)
        elif op == OP_GPU_CMD_BIND_IB:
             let buf = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_index_buffer(cmd, buf)
        elif op == OP_GPU_CMD_DRAW_IDX:
             let fi = pop(self.stack)
             let vo = pop(self.stack)
             let fidx = pop(self.stack)
             let inst = pop(self.stack)
             let idxc = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_draw_indexed(cmd, idxc, inst, fidx, vo, fi)
        elif op == OP_GPU_SUBMIT_SYNC:
             let f = pop(self.stack)
             let s = pop(self.stack)
             let w = pop(self.stack)
             let cmd = pop(self.stack)
             push(self.stack, gpu.submit_with_sync(cmd, w, s, f))
        elif op == OP_GPU_ACQUIRE_IMG: push(self.stack, gpu.acquire_next_image(pop(self.stack)))
        elif op == OP_GPU_PRESENT:
             let idx = pop(self.stack)
             let s = pop(self.stack)
             gpu.present(s, idx)
        elif op == OP_GPU_WAIT_FENCE:
             let t = pop(self.stack)
             let f = pop(self.stack)
             gpu.wait_fence(f, t)
        elif op == OP_GPU_RESET_FENCE: gpu.reset_fence(pop(self.stack))
        elif op == OP_GPU_UPDATE_UNIFORM:
             let data = pop(self.stack)
             let h = pop(self.stack)
             gpu.update_uniform(h, data)
        elif op == OP_GPU_CMD_PUSH_CONST:
             let data = pop(self.stack)
             let st = pop(self.stack)
             let lay = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_push_constants(cmd, lay, st, data)
        elif op == OP_GPU_CMD_DISPATCH:
             let gz = pop(self.stack)
             let gy = pop(self.stack)
             let gx = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_dispatch(cmd, gx, gy, gz)
        elif op == OP_YIELD:
            print "Error: OP_YIELD is not yet implemented in SVM"
            self.halted = true
        elif op == OP_CREATE_GENERATOR:
            self.ip = self.ip + 4
            print "Error: OP_CREATE_GENERATOR is not yet implemented in SVM"
            self.halted = true
        elif op == OP_GENERATOR_NEXT:
            print "Error: OP_GENERATOR_NEXT is not yet implemented in SVM"
            self.halted = true
        else:
            print "Unknown OP: " + str(op)
            self.halted = true
        
        return true
import sys
import io

class SGVMRunner:
    proc init(self):
        self.utils = SGVMUtils()

    proc run_file(self, input_file, debug, safe_mode=false, ffi_enabled=true, user_args=nil):
        var data = io.readbytes(input_file)
        if data == nil:
            print "❌ Error: Could not read file: " + input_file
            return false
        
        var off = 0
        let core_utils = self.utils
        
        # Skip shebang
        if len(data) > 2 and core_utils.my_int(data[0]) == 35 and core_utils.my_int(data[1]) == 33:
            while off < len(data) and core_utils.my_int(data[off]) != 10:
                off = off + 1
            if off < len(data):
                off = off + 1
        
        if len(data) - off < 4 or core_utils.my_int(data[off]) != 83 or core_utils.my_int(data[off+1]) != 71 or core_utils.my_int(data[off+2]) != 86 or core_utils.my_int(data[off+3]) != 77:
            print "❌ Error: Invalid SGVM header in " + input_file
            return false
            
        var metal_vm = sgvm_vm.MetalVM()
        metal_vm.trace = debug
        metal_vm.safe_mode = safe_mode
        metal_vm.ffi_enabled = ffi_enabled
        metal_vm.user_args = user_args
        metal_vm.setup_builtins()

        off = off + 6 # Skip Magic and Version
        
        if off + 4 > len(data):
            print "❌ Error: Truncated SGVM file header in " + input_file
            return false
            
        var function_count = core_utils.my_int(core_utils.read_be16(data, off))
        off = off + 2
        var const_count = core_utils.my_int(core_utils.read_be16(data, off))
        off = off + 2
        
        var j = 0
        while j < const_count:
            if off >= len(data):
                print "❌ Error: Truncated constant pool in " + input_file
                return false
            var t = data[off]
            off = off + 1
            if t == 1:
                if off + 8 > len(data):
                    print "❌ Error: Truncated double constant"
                    return false
                push(metal_vm.constants, core_utils.unpack_double(data, off))
                off = off + 8
            elif t == 3:
                if off + 2 > len(data):
                    print "❌ Error: Truncated string constant length in " + input_file
                    return false
                var slen = core_utils.my_int(core_utils.read_be16(data, off))
                off = off + 2
                if off + slen > len(data):
                    print "❌ Error: Truncated string constant value in " + input_file
                    return false
                var s = ""
                var k = 0
                while k < slen:
                    s = s + chr(core_utils.my_int(data[off + k]))
                    k = k + 1
                push(metal_vm.constants, s)
                off = off + slen
            else:
                print "❌ Error: Invalid constant type: " + str(t)
                return false
            j = j + 1
            
        if debug:
            print "Constants count: " + str(len(metal_vm.constants))
            var c_idx = 0
            while c_idx < len(metal_vm.constants):
                print "Const " + str(c_idx) + ": " + str(metal_vm.constants[c_idx])
                c_idx = c_idx + 1
            print "data len: " + str(len(data)) + " off: " + str(off)
            
        if off + 4 > len(data):
            print "❌ Error: Truncated chunk count in " + input_file
            return false
            
        var chunk_count = core_utils.my_int(core_utils.read_be32(data, off))
        off = off + 4
        var c = 0
        while c < chunk_count:
            if off + 4 > len(data):
                print "❌ Error: Truncated chunk header in " + input_file
                return false
            var clen = core_utils.my_int(core_utils.read_be32(data, off))
            off = off + 4
            if off + clen > len(data):
                print "❌ Error: Truncated chunk data in " + input_file
                return false
            var chunk_code = []
            var k = 0
            while k < clen:
                push(chunk_code, data[off + k])
                k = k + 1
            push(metal_vm.chunks, chunk_code)
            off = off + clen
            c = c + 1
            
        if debug:
            print "Functions count: " + str(function_count)
            print "Chunks count: " + str(len(metal_vm.chunks))
            
        var idx = function_count
        while idx < len(metal_vm.chunks) and not metal_vm.is_throwing:
            metal_vm.run(metal_vm.chunks[idx])
            idx = idx + 1
            
        return true
import sys
import io

# The Enhanced .sgvm Disassembler
# Supports outputting both .svm (bytecode) and .sage (source reconstruction)

class SGVMDisassembler:
    proc init(self, path):
        self.path = path
        self.ut = SGVMUtils()
        self.data = io.readbytes(path)
        self.pos = 0
        self.func_count = 0
        self.const_count = 0
        self.chunk_total = 0
        self.consts = []
        self.chunks = []
        self.opcode_map = {
            "0": "constant", "1": "nil", "2": "true", "3": "false", "4": "pop()", 
            "5": "get_global()", "6": "define_global()", "7": "set_global()",
            "8": "define_function()", "9": "get_property()", "10": "set_property()",
            "11": "get_index()", "12": "set_index()", "13": "load_function()",
            "14": "slice()", "15": " + ", "16": " - ", "17": " * ", "18": " / ",
            "19": " % ", "20": "negate", "21": " == ", "22": " != ", "23": " > ",
            "24": " >= ", "25": " < ", "26": " <= ", "27": " & ", "28": " | ",
            "29": " ^ ", "30": "~", "31": " << ", "32": " >> ", "33": "not ",
            "34": "truthy", "35": "jump()", "36": "if not", "37": "call()",
            "38": "call_method()", "39": "array()", "40": "tuple()", "41": "dict()",
            "42": "print()", "43": "exec_ast()", "44": "return", "45": "push_env()",
            "46": "pop_env()", "47": "dup()", "48": "len()", "49": "break",
            "50": "continue", "51": "loop_back()", "52": "import()", "53": "class()",
            "54": "method()", "55": "inherit()", "56": "setup_try()", "57": "end_try()",
            "58": "raise()", "255": "halt()"
        }

    proc disassemble(self):
        if self.data == nil:
            print "ERROR: Could not read file " + str(self.path)
            return false
        
        # Skip shebang
        if len(self.data) > 0 and self.ut.my_int(self.data[0]) == 35:
            while self.pos < len(self.data) and self.ut.my_int(self.data[self.pos]) != 10:
                self.pos = self.pos + 1
            if self.pos < len(self.data):
                self.pos = self.pos + 1

        # Magic "SGVM"
        if len(self.data) - self.pos < 4: return false
        var magic = ""
        var mi = 0
        while mi < 4:
            magic = magic + chr(self.ut.my_int(self.data[self.pos + mi]))
            mi = mi + 1
        self.pos = self.pos + 4
        if magic != "SGVM":
            print "ERROR: Bad magic " + magic
            return false

        # Version (2 bytes)
        self.pos = self.pos + 2
        
        # Function count (BE16)
        self.func_count = self.ut.read_be16(self.data, self.pos)
        self.pos = self.pos + 2
        
        # Const count (BE16)
        self.const_count = self.ut.read_be16(self.data, self.pos)
        self.pos = self.pos + 2
        
        # Parse constants
        var ci = 0
        while ci < self.const_count:
            let ctype = self.ut.my_int(self.data[self.pos])
            self.pos = self.pos + 1
            if ctype == 1: # Number
                let val = self.ut.unpack_double(self.data, self.pos)
                self.pos = self.pos + 8
                push(self.consts, {"type": "number", "value": val})
            elif ctype == 3: # String
                let slen = self.ut.read_be16(self.data, self.pos)
                self.pos = self.pos + 2
                var s = ""
                var k = 0
                while k < slen:
                    s = s + chr(self.ut.my_int(self.data[self.pos + k]))
                    k = k + 1
                self.pos = self.pos + slen
                push(self.consts, {"type": "string", "value": s})
            else:
                push(self.consts, {"type": "unknown", "value": nil})
            ci = ci + 1
        
        # Chunk total (BE32)
        self.chunk_total = self.ut.read_be32(self.data, self.pos)
        self.pos = self.pos + 4
        
        # Parse chunks
        var chunk_idx = 0
        while chunk_idx < self.chunk_total:
            let chunk_len = self.ut.read_be32(self.data, self.pos)
            self.pos = self.pos + 4
            let end_pos = self.pos + chunk_len
            let instructions = []
            while self.pos < end_pos:
                let op = self.ut.my_int(self.data[self.pos])
                self.pos = self.pos + 1
                let instr = {"op": op, "operands": []}
                
                # Handle operands
                if op == 0 or op == 5 or op == 6 or op == 7 or op == 9 or op == 10 or op == 52 or op == 53 or op == 54:
                    let idx = self.ut.read_be16(self.data, self.pos)
                    self.pos = self.pos + 2
                    push(instr["operands"], idx)
                elif op == 8: # DEFINE_FUNCTION
                    let name_idx = self.ut.read_be16(self.data, self.pos)
                    let chunk_idx_ref = self.ut.read_be16(self.data, self.pos + 2)
                    self.pos = self.pos + 4
                    push(instr["operands"], name_idx)
                    push(instr["operands"], chunk_idx_ref)
                elif op == 13 or op == 35 or op == 36 or op == 39 or op == 40 or op == 41 or op == 43 or op == 51 or op == 56:
                    let val = self.ut.read_be16(self.data, self.pos)
                    self.pos = self.pos + 2
                    push(instr["operands"], val)
                elif op == 37 or op == 47: # CALL or DUP
                    let val = self.ut.my_int(self.data[self.pos])
                    self.pos = self.pos + 1
                    push(instr["operands"], val)
                elif op == 38: # CALL_METHOD
                    let name_idx = self.ut.read_be16(self.data, self.pos)
                    let argc = self.ut.my_int(self.data[self.pos + 2])
                    self.pos = self.pos + 3
                    push(instr["operands"], name_idx)
                    push(instr["operands"], argc)
                
                push(instructions, instr)
            push(self.chunks, instructions)
            chunk_idx = chunk_idx + 1
        
        return true
        
        return true

    proc generate_svm(self):
        var output = "functions " + str(self.func_count) + "\n"
        output = output + "chunks " + str(self.chunk_total - self.func_count) + "\n\n"
        
        output = output + "constants " + str(len(self.consts)) + "\n"
        for ci in range(len(self.consts)):
            let c = self.consts[ci]
            if c["type"] == "number":
                output = output + "number " + str(c["value"]) + "\n"
            elif c["type"] == "string":
                let s = c["value"]
                var hex = ""
                for i in range(len(s)):
                    hex = hex + self.byte_to_hex(ord(s[i]))
                output = output + "string " + str(len(s)) + "\n"
                output = output + hex + "\n"

        for chunk_idx in range(len(self.chunks)):
            if chunk_idx < self.func_count:
                output = output + "\nfunction\n"
            else:
                output = output + "\nchunk\n"
            
            let instructions = self.chunks[chunk_idx]
            var hex_code = ""
            for instr in instructions:
                let op = instr["op"]
                hex_code = hex_code + self.byte_to_hex(op)
                for val in instr["operands"]:
                    if op == 0 or op == 5 or op == 6 or op == 7 or op == 8 or op == 9 or op == 10 or op == 13 or op == 35 or op == 36 or op == 38 or op == 39 or op == 40 or op == 41 or op == 43 or op == 51 or op == 52 or op == 53 or op == 54 or op == 56:
                        if op == 8:
                            hex_code = hex_code + self.byte_to_hex(int(val / 256))
                            hex_code = hex_code + self.byte_to_hex(val % 256)
                        elif op == 38:
                            if val == instr["operands"][0]: 
                                hex_code = hex_code + self.byte_to_hex(int(val / 256))
                                hex_code = hex_code + self.byte_to_hex(val % 256)
                            else: 
                                hex_code = hex_code + self.byte_to_hex(val)
                        else:
                            hex_code = hex_code + self.byte_to_hex(int(val / 256))
                            hex_code = hex_code + self.byte_to_hex(val % 256)
                    elif op == 37 or op == 47:
                        hex_code = hex_code + self.byte_to_hex(val)
            
            output = output + "code " + str(len(hex_code) / 2) + "\n"
            output = output + hex_code + "\n"

        return output

    proc generate_sage(self):
        var code = "# Disassembled from .sgvm\n\n"
        for chunk_idx in range(len(self.chunks)):
            code = code + "# --- Chunk " + str(chunk_idx) + " ---\n"
            let instructions = self.chunks[chunk_idx]
            for instr in instructions:
                let op = instr["op"]
                let key = str(op)
                var line = "  "
                if dict_has(self.opcode_map, key):
                    line = line + self.opcode_map[key]
                else:
                    line = line + "unknown_" + str(op)
                
                if len(instr["operands"]) > 0:
                    line = line + " ["
                    var op_parts = []
                    for val in instr["operands"]:
                        if op == 0 or op == 5 or op == 6 or op == 7 or op == 9 or op == 10 or op == 52 or op == 53 or op == 54 or (op == 8 and val == instr["operands"][0]) or (op == 38 and val == instr["operands"][0]):
                            if val >= 0 and val < len(self.consts):
                                let c = self.consts[val]
                                if c["type"] == "string": push(op_parts, "'" + c["value"] + "'")
                                else: push(op_parts, str(c["value"]))
                            else:
                                push(op_parts, "@" + str(val))
                        else:
                            push(op_parts, str(val))
                    line = line + join(op_parts, ", ") + "]"
                
                code = code + line + "\n"
            code = code + "\n"

        return code

    proc byte_to_hex(self, val):
        let chars = "0123456789abcdef"
        let high = int(val / 16) % 16
        let low = int(val) % 16
        return chars[high] + chars[low]
import sys
import io

proc byte_to_hex(val):
    let chars = "0123456789abcdef"
    let high = int(val / 16) % 16
    let low = int(val) % 16
    return chars[high] + chars[low]

proc pad_left(s, width, char):
    var res = s
    while len(res) < width:
        res = char + res
    return res

proc pad_right(s, width):
    var res = s
    while len(res) < width:
        res = res + " "
    return res

proc const_label(idx, consts, ut):
    if idx >= 0 and idx < len(consts):
        let c = consts[idx]
        let ct = ut.my_int(c["type"])
        let cv = c["value"]
        if ct == 3:
            return str(idx) + "('" + str(cv) + "')"
        if ct == 1:
            return str(idx) + "(" + str(cv) + ")"
    return str(idx)

proc disassemble(path):
    let data = io.readbytes(path)
    if data == nil:
        print "ERROR: Could not read file " + path
        return
    
    let ut = SGVMUtils()
    var pos = 0

    # Check for shebang
    if len(data) > 0 and ut.my_int(data[0]) == 35: # ord('#') is 35
        while pos < len(data) and ut.my_int(data[pos]) != 10: # ord('\n') is 10
            pos = pos + 1
        if pos < len(data):
            pos = pos + 1

    if len(data) - pos < 4:
        print "ERROR: File too short"
        return

    var magic = ""
    var m_idx = 0
    while m_idx < 4:
        magic = magic + chr(ut.my_int(data[pos + m_idx]))
        m_idx = m_idx + 1
    pos = pos + 4

    if magic != "SGVM":
        print "ERROR: bad magic " + magic
        return
    print "Magic: SGVM"

    let ver_maj = ut.my_int(data[pos])
    let ver_min = ut.my_int(data[pos+1])
    pos = pos + 2
    print "Version: " + str(ver_maj) + "." + str(ver_min)

    let func_count = ut.my_int(ut.read_be16(data, pos))
    pos = pos + 2
    print "Functions: " + str(func_count)

    let const_count = ut.my_int(ut.read_be16(data, pos))
    pos = pos + 2
    print "Constants: " + str(const_count)

    let consts = []
    var ci = 0
    while ci < const_count:
        if pos >= len(data):
            print "ERROR: Truncated constant pool"
            return
        let ctype = ut.my_int(data[pos])
        pos = pos + 1
        if ctype == 1:
            if pos + 8 > len(data):
                print "ERROR: Truncated double constant"
                return
            let val = ut.unpack_double(data, pos)
            pos = pos + 8
            push(consts, {"type": 1, "value": val})
            print "  const[" + str(ci) + "] = NUM " + str(val)
        elif ctype == 3:
            if pos + 2 > len(data):
                print "ERROR: Truncated string constant length"
                return
            let slen = ut.my_int(ut.read_be16(data, pos))
            pos = pos + 2
            if pos + slen > len(data):
                print "ERROR: Truncated string constant value"
                return
            var s = ""
            var k = 0
            while k < slen:
                s = s + chr(ut.my_int(data[pos + k]))
                k = k + 1
            pos = pos + slen
            push(consts, {"type": 3, "value": s})
            print "  const[" + str(ci) + "] = STR '" + s + "'"
        else:
            push(consts, {"type": ctype, "value": nil})
            print "  const[" + str(ci) + "] = UNKNOWN type " + str(ctype)
        ci = ci + 1

    let chunk_total = ut.my_int(ut.read_be32(data, pos))
    pos = pos + 4
    print "Chunks+Functions: " + str(chunk_total)
    print ""

    let op_names = {
        "0": "CONSTANT",
        "1": "NIL",
        "2": "TRUE",
        "3": "FALSE",
        "4": "POP",
        "5": "GET_GLOBAL",
        "6": "DEFINE_GLOBAL",
        "7": "SET_GLOBAL",
        "8": "DEFINE_FUNCTION",
        "9": "GET_PROPERTY",
        "10": "SET_PROPERTY",
        "11": "GET_INDEX",
        "12": "SET_INDEX",
        "13": "LOAD_FUNCTION",
        "14": "SLICE",
        "15": "ADD",
        "16": "SUB",
        "17": "MUL",
        "18": "DIV",
        "19": "MOD",
        "20": "NEGATE",
        "21": "EQUAL",
        "22": "NOT_EQUAL",
        "23": "GREATER",
        "24": "GREATER_EQUAL",
        "25": "LESS",
        "26": "LESS_EQUAL",
        "27": "BIT_AND",
        "28": "BIT_OR",
        "29": "BIT_XOR",
        "30": "BIT_NOT",
        "31": "SHIFT_LEFT",
        "32": "SHIFT_RIGHT",
        "33": "NOT",
        "34": "TRUTHY",
        "35": "JUMP",
        "36": "JUMP_IF_FALSE",
        "37": "CALL",
        "38": "CALL_METHOD",
        "39": "ARRAY",
        "40": "TUPLE",
        "41": "DICT",
        "42": "PRINT",
        "43": "EXEC_AST_STMT",
        "44": "RETURN",
        "45": "PUSH_ENV",
        "46": "POP_ENV",
        "47": "DUP",
        "48": "ARRAY_LEN",
        "49": "BREAK",
        "50": "CONTINUE",
        "51": "LOOP_BACK",
        "52": "IMPORT",
        "53": "CLASS",
        "54": "METHOD",
        "55": "INHERIT",
        "56": "SETUP_TRY",
        "57": "END_TRY",
        "58": "RAISE",
        "59": "GPU_POLL_EVENTS",
        "60": "GPU_WINDOW_SHOULD_CLOSE",
        "61": "GPU_GET_TIME",
        "62": "GPU_KEY_PRESSED",
        "63": "GPU_KEY_DOWN",
        "64": "GPU_MOUSE_POS",
        "65": "GPU_MOUSE_DELTA",
        "66": "GPU_UPDATE_INPUT",
        "67": "GPU_BEGIN_COMMANDS",
        "68": "GPU_END_COMMANDS",
        "69": "GPU_CMD_BEGIN_RP",
        "70": "GPU_CMD_END_RP",
        "71": "GPU_CMD_DRAW",
        "72": "GPU_CMD_BIND_GP",
        "73": "GPU_CMD_BIND_DS",
        "74": "GPU_CMD_SET_VP",
        "75": "GPU_CMD_SET_SC",
        "76": "GPU_CMD_BIND_VB",
        "77": "GPU_CMD_BIND_IB",
        "78": "GPU_CMD_DRAW_IDX",
        "79": "GPU_SUBMIT_SYNC",
        "80": "GPU_ACQUIRE_IMG",
        "81": "GPU_PRESENT",
        "82": "GPU_WAIT_FENCE",
        "83": "GPU_RESET_FENCE",
        "84": "GPU_UPDATE_UNIFORM",
        "85": "GPU_CMD_PUSH_CONST",
        "86": "GPU_CMD_DISPATCH",
        "255": "HALT"
    }

    let op_operands = {
        "0": "const2",
        "5": "const2",
        "6": "const2",
        "7": "const2",
        "8": "defn",
        "9": "raw2",
        "10": "raw2",
        "13": "raw2",
        "35": "raw2",
        "36": "raw2",
        "37": "1",
        "38": "callm",
        "39": "raw2",
        "40": "raw2",
        "41": "raw2",
        "43": "raw2",
        "47": "1",
        "49": "raw2",
        "50": "raw2",
        "51": "raw2",
        "52": "raw2",
        "53": "raw2",
        "54": "raw2",
        "56": "raw2"
    }

    var chunk_idx = 0
    while chunk_idx < chunk_total:
        if pos + 4 > len(data):
            print "ERROR: Truncated chunk header"
            return
        let chunk_len = ut.my_int(ut.read_be32(data, pos))
        pos = pos + 4
        print "--- Chunk " + str(chunk_idx) + " (" + str(chunk_len) + " bytes) ---"
        let chunk_end_pos = pos + chunk_len
        var ip = 0
        while pos < chunk_end_pos:
            let op = ut.my_int(data[pos])
            pos = pos + 1
            ip = ip + 1
            let key = str(op)
            var op_name = "OP_" + key
            if dict_has(op_names, key):
                op_name = op_names[key]
            
            var operand_type = nil
            if dict_has(op_operands, key):
                operand_type = op_operands[key]
            
            let ip_str = pad_left(str(ip - 1), 4, " ")
            let op_str = byte_to_hex(op)
            let name_str = pad_right(op_name, 20)

            if operand_type == nil:
                print "  " + ip_str + "  " + op_str + "  " + name_str
            elif operand_type == "const2":
                let idx = ut.my_int(ut.read_be16(data, pos))
                pos = pos + 2
                ip = ip + 2
                print "  " + ip_str + "  " + op_str + "  " + name_str + " " + const_label(idx, consts, ut)
            elif operand_type == "raw2":
                let val = ut.my_int(ut.read_be16(data, pos))
                pos = pos + 2
                ip = ip + 2
                var label = str(val)
                if op == 52 or op == 53 or op == 54 or op == 9 or op == 10:
                    label = const_label(val, consts, ut)
                print "  " + ip_str + "  " + op_str + "  " + name_str + " " + label
            elif operand_type == "1":
                let val = ut.my_int(data[pos])
                pos = pos + 1
                ip = ip + 1
                print "  " + ip_str + "  " + op_str + "  " + name_str + " " + str(val)
            elif operand_type == "defn":
                let name_idx = ut.my_int(ut.read_be16(data, pos))
                pos = pos + 2
                ip = ip + 2
                let chunk_ref = ut.my_int(ut.read_be16(data, pos))
                pos = pos + 2
                ip = ip + 2
                print "  " + ip_str + "  " + op_str + "  " + name_str + " name=" + const_label(name_idx, consts, ut) + " chunk=" + str(chunk_ref)
            elif operand_type == "callm":
                let name_idx = ut.my_int(ut.read_be16(data, pos))
                pos = pos + 2
                ip = ip + 2
                let argc = ut.my_int(data[pos])
                pos = pos + 1
                ip = ip + 1
                print "  " + ip_str + "  " + op_str + "  " + name_str + " name=" + const_label(name_idx, consts, ut) + " argc=" + str(argc)
        print ""
        chunk_idx = chunk_idx + 1
# SageVM Type Profiler (JIT Optimization)
# Analyzes bytecode to infer speculative types for stack slots and locals


let TYPE_INT    = 1
let TYPE_FLOAT  = 2
let TYPE_STR    = 3
let TYPE_OBJ    = 4
let TYPE_UNKNOWN = 0

class TypeProfiler:
    proc init(self, constants):
        self.stack_types = []
        self.local_types = {}
        self.constants = constants

    proc analyze(self, bytecode):
        var result = []
        var i = 0
        let blen = len(bytecode)
        while i < blen:
            let b0 = int(bytecode[i])
            var hint = TYPE_UNKNOWN
            if b0 == OP_CONSTANT and i + 2 < blen:
                let b1 = int(bytecode[i+1])
                let b2 = int(bytecode[i+2])
                let idx = b1 * 256 + b2
                if self.constants != nil and idx >= 0 and idx < len(self.constants):
                    let c = self.constants[idx]
                    if type(c) == "dict" and dict_has(c, "type"):
                        let ct = int(c["type"])
                        if ct == 1:
                            hint = TYPE_INT
                        elif ct == 3:
                            hint = TYPE_STR
            push(result, hint)
            i = i + 1
        return result
# Sage SVM to SRVM (RISC-V) Translator
# Translates stack-based bytecode to register-based bytecode


class StackToRiscVTranslator:
    proc init(self, constants):
        self.encoder = RVEncoder()
        self.profiler = TypeProfiler(constants)
        self.reg_stack = []
        self.next_reg = 11 # Start from a1 (x11), reserving x10 for VMSYS args
        self.spill_slots = [] # Track spilled registers
        self.spill_offset = 0 # Next available spill slot
        self.output_bytes = []
        self.label_map = {} # SVM IP -> SRVM PC
        self.jump_patches = [] # (SRVM PC to patch, target SVM IP)

    proc emit_32(self, val):
        push(self.output_bytes, val & 0xFF)
        push(self.output_bytes, (val >> 8) & 0xFF)
        push(self.output_bytes, (val >> 16) & 0xFF)
        push(self.output_bytes, (val >> 24) & 0xFF)

    proc emit_load_imm(self, rd, val):
        var v = int(val)
        if v >= -2048 and v <= 2047:
            self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 0, v))
        else:
            var hi = int((v + 2048) / 4096)
            var lo = v - (hi * 4096)
            self.emit_32(self.encoder.encode_u(OP_LUI, rd, hi * 4096))
            self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, rd, lo))

    proc patch_32(self, pc, val):
        self.output_bytes[pc] = val & 0xFF
        self.output_bytes[pc+1] = (val >> 8) & 0xFF
        self.output_bytes[pc+2] = (val >> 16) & 0xFF
        self.output_bytes[pc+3] = (val >> 24) & 0xFF

    
    proc pop_reg(self):
        if self.reg_stack == nil or len(self.reg_stack) == 0:
            return 11
        return pop(self.reg_stack)

    proc alloc_reg(self):
        let r = self.next_reg
        self.next_reg = self.next_reg + 1
        if self.next_reg > 27:
            let spill_reg = 11
            let slot = self.spill_offset
            self.spill_offset = self.spill_offset + 1
            self.emit_32(self.encoder.encode_s(OP_STORE, F3_SD, 2, spill_reg, slot * 8))
            push(self.spill_slots, slot)
            self.next_reg = 12
            return spill_reg
        return r

    proc translate(self, svm_bytecode):
        # Speculative type analysis
        let speculative_types = self.profiler.analyze(svm_bytecode)
        
        self.output_bytes = []
        self.reg_stack = []
        self.next_reg = 11
        self.spill_slots = []
        self.spill_offset = 0
        self.label_map = {}
        self.jump_patches = []
        
        # Pre-scan for catch labels
        var catch_labels = {}
        var j = 0
        while j < len(svm_bytecode):
            let op = int(svm_bytecode[j])
            j = j + 1
            if op == OP_DEFINE_FUNCTION:
                j = j + 4
            elif op == OP_CALL_METHOD:
                j = j + 3
            elif op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_SET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_METHOD or op == OP_ARRAY or op == OP_TUPLE or op == OP_DICT or op == OP_LOOP_BACK or op == OP_IMPORT or op == OP_SETUP_TRY or op == OP_LOAD_FUNCTION or op == OP_CLASS or op == OP_GET_LOCAL or op == OP_SET_LOCAL:
                if op == OP_SETUP_TRY:
                    let target = (int(svm_bytecode[j]) << 8) | int(svm_bytecode[j+1])
                    catch_labels[str(target)] = true
                j = j + 2
            elif op == OP_CALL or op == OP_DUP:
                j = j + 1
        
        var i = 0
        while i < len(svm_bytecode):
            let ip = i
            
            # If this is a catch block start, the VM will have pushed the exception object
            if dict_has(catch_labels, str(ip)):
                self.reg_stack = [10] # Exception is in a0 (x10)
                self.next_reg = 11
            
            self.label_map[str(ip)] = len(self.output_bytes)
            let op = int(svm_bytecode[i])
            print "DEBUG translate op=" + str(op) + " i=" + str(i)
            i = i + 1
            
            if op == OP_CONSTANT:
                print "DEBUG OP_CONSTANT step 1 i=" + str(i)
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                print "DEBUG OP_CONSTANT step 2 idx=" + str(idx)
                i = i + 2
                let rd = self.alloc_reg()
                print "DEBUG OP_CONSTANT step 3 rd=" + str(rd)
                let u_val = self.encoder.encode_u(OP_LDC, rd, idx << 12)
                print "DEBUG OP_CONSTANT step 4 u_val=" + str(u_val)
                self.emit_32(u_val)
                print "DEBUG OP_CONSTANT step 5"
                push(self.reg_stack, rd)
                
            elif op == OP_ADD:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                
                # Check speculative type
                # Simple lookup: use current instruction index to get speculative type
                let t = speculative_types[i-1] 
                if t == TYPE_INT:
                    # Emit integer specialized ADD
                    self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0, rd, rs1, rs2))
                else:
                    # Emit generic/fallback ADD
                    self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0, rd, rs1, rs2))
                
                push(self.reg_stack, rd)

            elif op == OP_SUB:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0x20, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_MUL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0x01, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_DIV:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_XOR, 0x01, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_MOD:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_OR, 0x01, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_AND:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_AND, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_OR:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_OR, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_XOR:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_XOR, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_NOT:
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_XORI, rd, rs1, -1))
                push(self.reg_stack, rd)

            elif op == OP_SHIFT_LEFT:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_SLL, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_SHIFT_RIGHT:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_SRL, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                # ADDI x10, rs1, 0  -> a0 = rs1
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                # ADDI x11, rs2, 0  -> a1 = rs2
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                # VMO_CMP_BINARY with funct7=CMP_EQ
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_EQ, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_NOT_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_NEQ, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_LESS:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_LT, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_GREATER:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_GT, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_GREATER_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_GE, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_LESS_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_LE, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_GET_INDEX:
                let idx = self.pop_reg()
                let obj = self.pop_reg()
                let rd = self.alloc_reg()
                var obj_reg = obj
                if obj == 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                if idx != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, idx, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_GET_INDEX, obj_reg))
                push(self.reg_stack, rd)

            elif op == OP_SET_INDEX:
                let val = self.pop_reg()
                let idx = self.pop_reg()
                let obj = self.pop_reg()
                var obj_reg = obj
                if obj == 10 or obj == 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                if idx != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, idx, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_INDEX, obj_reg))

            elif op == OP_ARRAY:
                let init_val = self.pop_reg()
                let size = self.pop_reg()
                let rd = self.alloc_reg()
                if init_val != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, init_val, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_ARRAY_NEW, size))
                push(self.reg_stack, rd)

            elif op == OP_JUMP:
                let target_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_j(OP_JAL, 0, 0)) 
                push(self.jump_patches, [patch_pc, target_ip])
                
            elif op == OP_GET_PROPERTY:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let obj = self.pop_reg()
                let rd = self.alloc_reg()
                var obj_reg = obj
                if obj == 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, name_idx))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_GET_PROP, obj_reg))
                push(self.reg_stack, rd)

            elif op == OP_SET_PROPERTY:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = self.pop_reg()
                let obj = self.pop_reg()
                var obj_reg = obj
                if obj == 10 or obj == 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, name_idx))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_PROP, obj_reg))

            elif op == OP_POP:
                if len(self.reg_stack) > 0:
                    self.pop_reg()

            elif op == OP_DUP:
                let distance = int(svm_bytecode[i])
                i = i + 1
                if len(self.reg_stack) > distance:
                    let rs = self.reg_stack[len(self.reg_stack)-1-distance]
                    let rd = self.alloc_reg()
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, rs, 0))
                    push(self.reg_stack, rd)

            elif op == OP_CLASS:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_NEW_CLASS, 0))
                push(self.reg_stack, rd)

            elif op == OP_INHERIT:
                let parent = self.pop_reg()
                let child = self.pop_reg()
                var child_reg = child
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, child, 0))
                child_reg = rd
                if parent != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, parent, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_INHERIT, child_reg))
                push(self.reg_stack, rd)

            elif op == OP_METHOD:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let func = self.pop_reg()
                let klass = self.pop_reg()
                var klass_reg = klass
                if klass == 10 or klass == 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, klass, 0))
                    klass_reg = 5
                if func != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, func, 0))
                self.emit_load_imm(10, name_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_METHOD_BIND, klass_reg))

            elif op == OP_DEFINE_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_GLOBAL, 0))

            elif op == OP_NIL:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 0, 0)) 
                push(self.reg_stack, rd)

            elif op == OP_TRUE:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 0, 1))
                push(self.reg_stack, rd)

            elif op == OP_FALSE:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 0, 0))
                push(self.reg_stack, rd)

            elif op == OP_GET_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_GET_GLOBAL, 0))
                push(self.reg_stack, rd)

            elif op == OP_SET_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_GLOBAL, 0))
            
            elif op == OP_IMPORT:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_IMPORT, 0))
                push(self.reg_stack, rd)

            elif op == OP_GET_LOCAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_LOAD, F3_LD, rd, 8, idx * 8))
                push(self.reg_stack, rd)

            elif op == OP_SET_LOCAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rs = self.pop_reg()
                self.emit_32(self.encoder.encode_s(OP_STORE, F3_SD, 8, rs, idx * 8))
                
            elif op == OP_SETUP_TRY:
                let catch_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_i(OP_VMSYS, F3_VM_OPS, 0, VMO_SETUP_TRY, 0)) 
                push(self.jump_patches, [patch_pc, catch_ip])

            elif op == OP_END_TRY:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_END_TRY, 0))

            elif op == OP_RAISE:
                let exc_obj = self.pop_reg()
                if exc_obj != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, exc_obj, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_RAISE, 0))

            elif op == OP_PUSH_ENV:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_PUSH_ENV, 0))

            elif op == OP_POP_ENV:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_POP_ENV, 0))

            elif op == OP_JUMP_IF_FALSE:
                let target_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let cond = self.pop_reg()
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_b(OP_BRANCH, F3_BEQ, cond, 0, 0)) 
                push(self.jump_patches, [patch_pc, target_ip])

            elif op == OP_RETURN:
                self.emit_32(self.encoder.encode_i(OP_JALR, 0, 0, 1, 0))

            elif op == OP_DEFINE_FUNCTION:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let chunk_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                self.emit_load_imm(10, chunk_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 11, OBJ_NEW_FUNC, 0))
                self.emit_load_imm(10, name_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_GLOBAL, 0))

            elif op == OP_CALL:
                let argc = int(svm_bytecode[i])
                i = i + 1
                var args = []
                var k = 0
                while k < argc:
                    push(args, self.pop_reg())
                    k = k + 1
                # Preserve the callee in t0 (x5) BEFORE argument placement,
                # otherwise a callee allocated to x10 is clobbered when arg0
                # is moved into x10 (the a0 slot).
                let callee_reg = self.pop_reg()
                if callee_reg != 5:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, callee_reg, 0))
                k = argc - 1
                while k >= 0:
                    let src = args[argc - 1 - k]
                    let dest = 10 + k
                    if src != dest and src != 5:
                        self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, dest, src, 0))
                    k = k - 1
                # Call via t0 (x5), which holds the preserved callee.
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_CALL, 5))
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 10, 0))
                push(self.reg_stack, rd)

            elif op == OP_CALL_METHOD:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                let argc = int(svm_bytecode[i+2])
                i = i + 3
                var args = []
                var k = 0
                while k < argc:
                    push(args, self.pop_reg())
                    k = k + 1
                let obj = self.pop_reg()
                
                # Move obj to x18
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 18, obj, 0))
                # Move args to x19..
                k = 0
                while k < argc:
                    let src = args[argc - 1 - k]
                    let dest = 19 + k
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, dest, src, 0))
                    k = k + 1
                
                # Load name_idx to x10
                self.emit_load_imm(10, name_idx)
                # Call OBJ_METHOD_BIND on obj (x18), target x29, setting x28 flag
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 29, OBJ_METHOD_BIND, 18))
                
                # Branch if x28 == 0 (class call) to class_call block.
                # Offset is (argc + 3) * 4 bytes.
                self.emit_32(self.encoder.encode_b(OP_BRANCH, F3_BEQ, 28, 0, (argc + 3) * 4))
                
                # Instance call block:
                # Move obj (x18) to x10
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 18, 0))
                # Move args (x19..) to x11..
                k = 0
                while k < argc:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11 + k, 19 + k, 0))
                    k = k + 1
                # JUMP over class_call block.
                # Offset is (argc + 1) * 4 bytes.
                self.emit_32(self.encoder.encode_j(OP_JAL, 0, (argc + 1) * 4))
                
                # Class call block:
                # Move args (x19..) to x10..
                k = 0
                while k < argc:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10 + k, 19 + k, 0))
                    k = k + 1
                
                # Do call: VMO_CALL(x29)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_CALL, 29))
                # Get return value: rd = x10
                let rd_ret = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd_ret, 10, 0))
                push(self.reg_stack, rd_ret)

            elif op == OP_PRINT:
                let rs = self.pop_reg()
                if rs != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_PRINT, 0))
                
            elif op == OP_HALT:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_HALT, 0))

            elif op == 59: # OP_GPU_POLL_EVENTS (halt)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 0, 0))

            elif op == 69: # OP_GPU_CMD_BEGIN_RP (get_trap)
                let rd2 = self.alloc_reg()
                let rd1 = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd1, 10, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd2, 11, 0))
                push(self.reg_stack, rd1)
                push(self.reg_stack, rd2)

            elif op == 70: # OP_GPU_CMD_END_RP (enable_interrupts)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 2, 0))

            elif op == 71: # OP_GPU_CMD_DRAW (set_timer)
                let arg4 = self.pop_reg()
                let arg3 = self.pop_reg()
                let arg2 = self.pop_reg()
                let arg1 = self.pop_reg()
                if arg1 != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, arg1, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 3, 0))

            elif op == 62: # OP_GPU_KEY_PRESSED (peek64)
                let addr = self.pop_reg()
                let rd = self.alloc_reg()
                if addr != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, addr, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, rd, 4, 0))
                push(self.reg_stack, rd)

            elif op == 84: # OP_GPU_UPDATE_UNIFORM (poke64)
                let val = self.pop_reg()
                let addr = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                if addr != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, addr, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 5, 0))

            elif op == 85: # OP_GPU_CMD_PUSH_CONST (poke32)
                let arg4 = self.pop_reg()
                let arg3 = self.pop_reg()
                let val = self.pop_reg()
                let addr = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                if addr != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, addr, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 6, 0))
        
        var p = 0
        while p < len(self.jump_patches):
            let patch = self.jump_patches[p]
            let patch_pc = patch[0]
            let target_ip = patch[1]
            if self.label_map[str(target_ip)] != nil:
                let target_pc = self.label_map[str(target_ip)]
                let offset = target_pc - patch_pc
                let b0 = int(self.output_bytes[patch_pc])
                let opcode = b0 & 0x7F
                var instr = 0
                if opcode == OP_JAL:
                    instr = self.encoder.encode_j(OP_JAL, 0, offset)
                elif opcode == OP_BRANCH:
                    let raw = int(self.output_bytes[patch_pc]) | (int(self.output_bytes[patch_pc+1]) << 8) | (int(self.output_bytes[patch_pc+2]) << 16) | (int(self.output_bytes[patch_pc+3]) << 24)
                    let rs1 = (raw >> 15) & 0x1F
                    let rs2 = (raw >> 20) & 0x1F
                    let f3 = (raw >> 12) & 0x07
                    instr = self.encoder.encode_b(OP_BRANCH, f3, rs1, rs2, offset)
                elif opcode == OP_VMSYS:
                    let raw = int(self.output_bytes[patch_pc]) | (int(self.output_bytes[patch_pc+1]) << 8) | (int(self.output_bytes[patch_pc+2]) << 16) | (int(self.output_bytes[patch_pc+3]) << 24)
                    let rd = (raw >> 7) & 0x1F
                    let sub_op = (raw >> 15) & 0x1F
                    let f3 = (raw >> 12) & 0x07
                    instr = self.encoder.encode_i(OP_VMSYS, f3, rd, sub_op, offset)
                if instr != 0:
                    self.patch_32(patch_pc, instr)
            p = p + 1
            
        return self.output_bytes

class SGRVCompiler:
    proc init(self):
        self.translator = StackToRiscVTranslator(nil)
        self.utils = SRVMUtils()

    proc compile(self, sgvm_data):
        print "DEBUG SGRV compile entry, len=" + str(len(sgvm_data))
        var pos = 0
        if len(sgvm_data) < 4: return nil
        if int(sgvm_data[0]) == 35:
            while pos < len(sgvm_data) and int(sgvm_data[pos]) != 10: pos = pos + 1
            if pos < len(sgvm_data): pos = pos + 1
        
        if int(sgvm_data[pos]) != 83 or int(sgvm_data[pos+1]) != 71 or int(sgvm_data[pos+2]) != 86 or int(sgvm_data[pos+3]) != 77:
            print "DEBUG SGRV magic mismatch!"
            return nil
        pos = pos + 4 + 2 # Skip magic and version
        
        let func_count = (int(sgvm_data[pos]) << 8) | int(sgvm_data[pos+1])
        pos = pos + 2
        let const_count = (int(sgvm_data[pos]) << 8) | int(sgvm_data[pos+1])
        pos = pos + 2
        print "DEBUG SGRV func_count=" + str(func_count) + " const_count=" + str(const_count)
        
        var constants = []
        
        var output = [83, 71, 82, 86, 0, 1]
        let fc_rem = int(func_count) % 256
        push(output, (int(func_count) - fc_rem) / 256)
        push(output, fc_rem)
        let cc_rem = int(const_count) % 256
        push(output, (int(const_count) - cc_rem) / 256)
        push(output, cc_rem)
        
        var ci = 0
        while ci < const_count:
            let t = int(sgvm_data[pos])
            push(output, t)
            pos = pos + 1
            if t == 1: # Number
                var val_bytes = []
                var k = 0
                while k < 8:
                    push(val_bytes, int(sgvm_data[pos + k]))
                    push(output, int(sgvm_data[pos + k]))
                    k = k + 1
                pos = pos + 8
                let numval = self.utils.unpack_double(val_bytes, 0)
                push(constants, {"type": 1, "num": numval})
            elif t == 3: # String
                let slen = (int(sgvm_data[pos]) << 8) | int(sgvm_data[pos+1])
                let slen_rem = int(slen) % 256
                push(output, (int(slen) - slen_rem) / 256)
                push(output, slen_rem)
                pos = pos + 2
                var s = ""
                var k = 0
                while k < slen:
                    let b = int(sgvm_data[pos + k])
                    push(output, b)
                    s = s + chr(b)
                    k = k + 1
                pos = pos + slen
                push(constants, {"type": 3, "str": s})
            ci = ci + 1
            
        # Initialize translator with constants
        self.translator = StackToRiscVTranslator(constants)
            
        let num_chunks = (int(sgvm_data[pos]) << 24) | (int(sgvm_data[pos+1]) << 16) | (int(sgvm_data[pos+2]) << 8) | int(sgvm_data[pos+3])
        pos = pos + 4
        
        var nc_val = int(num_chunks)
        let nc0 = nc_val % 256
        let nc1_v = (nc_val - nc0) / 256
        let nc1 = nc1_v % 256
        let nc2_v = (nc1_v - nc1) / 256
        let nc2 = nc2_v % 256
        let nc3 = (nc2_v - nc2) / 256
        push(output, nc3)
        push(output, nc2)
        push(output, nc1)
        push(output, nc0)
        
        var chunk_idx = 0
        while chunk_idx < num_chunks:
            if chunk_idx % 50 == 0:
                print "DEBUG SGRV compile chunk " + str(chunk_idx) + "/" + str(num_chunks)
            let clen = (int(sgvm_data[pos]) << 24) | (int(sgvm_data[pos+1]) << 16) | (int(sgvm_data[pos+2]) << 8) | int(sgvm_data[pos+3])
            pos = pos + 4
            var svm_bc = []
            var i = 0
            while i < clen:
                push(svm_bc, int(sgvm_data[pos + i]))
                i = i + 1
            pos = pos + clen
            let translated = self.translator.translate(svm_bc)
            let t_len = len(translated)
            
            var tl_val = int(t_len)
            let tl0 = tl_val % 256
            let tl1_v = (tl_val - tl0) / 256
            let tl1 = tl1_v % 256
            let tl2_v = (tl1_v - tl1) / 256
            let tl2 = tl2_v % 256
            let tl3 = (tl2_v - tl2) / 256
            push(output, tl3)
            push(output, tl2)
            push(output, tl1)
            push(output, tl0)
            i = 0
            while i < t_len:
                let b_val = translated[i]
                if b_val == nil or type(b_val) != "number":
                    print "DEBUG SGRVCompiler chunk_idx=" + str(chunk_idx) + " i=" + str(i) + " b_val=" + str(b_val) + " type=" + str(type(b_val))
                push(output, int(b_val))
                i = i + 1
            chunk_idx = chunk_idx + 1
        return output

    proc save(self, path, data, io_mod):
        io_mod.writebytes(path, data)
# Sage RISC-V Virtual Machine (SRVM)
# Core Interpreter Implementation (RV64I)

import io
import math
import net
import thread as host_thread
import sys
import gpu
import ml_native

class SageVMState:
    proc init(self):
        # 32 x 64-bit registers
        self.x = []
        var i = 0
        while i < 32:
            push(self.x, 0)
            i = i + 1
            
        self.pc = 0
        self.running = true
        
        # Memory segments
        self.bytecode = []
        self.constants = []
        self.chunks = []
        self.current_chunk_idx = 0
        self.stack = [] 
        i = 0
        while i < 4096:
            push(self.stack, 0)
            i = i + 1
        self.max_stack_size = 65536
        
        self.heap = {} 
        self.call_stack = [] # Stack of [chunk_idx, pc, ra]
        self.try_stack = [] # Stack of [catch_pc, call_stack_depth]

        # Security: Limits to prevent Denial of Service (DoS) via resource exhaustion
        self.max_call_depth = 1024
        self.max_try_depth = 1024
        self.max_array_size = 1000000
        self.safe_mode = false
        self.ffi_enabled = true
        
        # Register x2 is typically stack pointer (sp)
        self.x[2] = len(self.stack)

class SRVM:
    proc init(self):
        self.state = SageVMState()
        self.trace = false

    proc safe_get_constant(self, idx):
        if idx >= 0 and idx < len(self.state.constants):
            return self.state.constants[idx]
        print "Error: Constant pool index out of bounds: " + str(idx) + " at PC=" + str(self.state.pc)
        self.state.running = false
        return nil

    proc safe_get_chunk(self, idx):
        if idx >= 0 and idx < len(self.state.chunks):
            return self.state.chunks[idx]
        print "Error: Chunk index out of bounds: " + str(idx)
        self.state.running = false
        return []

    proc is_protected(self, obj):
        # Security helper: Check if an object is a protected module or host bridge
        if not self.state.safe_mode:
            return false

        if type(obj) == "dict":
            if dict_has(obj, "__host_mod__") or (dict_has(obj, "__type__") and obj["__type__"] == "module") or dict_has(obj, "__builtin__"):
                return true
        elif type(obj) == "module":
            return true
        return false

    proc run(self, bytecode):
        # Initial chunk (0)
        self.state.bytecode = bytecode
        if len(self.state.chunks) == 0:
            push(self.state.chunks, bytecode)
        
        self.state.pc = 0
        self.state.running = true
        
        while self.state.running and self.state.pc < len(self.state.bytecode):
            # Fetch
            if self.state.pc + 4 > len(self.state.bytecode):
                break
            
            let b0 = self.state.bytecode[self.state.pc]
            let b1 = self.state.bytecode[self.state.pc+1]
            let b2 = self.state.bytecode[self.state.pc+2]
            let b3 = self.state.bytecode[self.state.pc+3]
            let raw_instr = int(b0) | (int(b1) << 8) | (int(b2) << 16) | (int(b3) << 24)
            
            let instr = RVInstruction(raw_instr)
            
            if self.trace:
                print "PC: " + str(self.state.pc) + " Op: " + str(instr.opcode) + " rd: " + str(instr.rd)
            
            self.execute(instr)
            
            # x0 is hardwired to zero
            if instr.rd == 0:
                self.state.x[0] = 0

    proc execute(self, instr):
        let op = instr.opcode
        
        if op == OP_LUI:
            self.state.x[instr.rd] = instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == OP_AUIPC:
            self.state.x[instr.rd] = self.state.pc + instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == OP_JAL:
            self.state.x[instr.rd] = self.state.pc + 4
            self.state.pc = self.state.pc + instr.imm_j
        elif op == OP_JALR:
            let target = (self.state.x[instr.rs1] + instr.imm_i) & ~1
            let rd_val = self.state.pc + 4
            
            # Special case for return: JALR x0, 0(x1)
            if instr.rd == 0 and instr.rs1 == 1 and instr.imm_i == 0:
                if len(self.state.call_stack) > 0:
                    let frame = pop(self.state.call_stack)
                    self.state.current_chunk_idx = frame[0]
                    self.state.bytecode = self.state.chunks[self.state.current_chunk_idx]
                    self.state.pc = frame[1]
                    self.state.x[1] = frame[2]
                    return # Skip standard PC update
                else:
                    self.state.running = false
                    return

            self.state.x[instr.rd] = rd_val
            self.state.pc = target
        elif op == OP_BRANCH:
            self.handle_branch(instr)
        elif op == OP_IMM:
            self.handle_imm(instr)
        elif op == OP_REG:
            self.handle_reg(instr)
        elif op == OP_LUI:
            self.state.x[instr.rd] = instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == OP_LDC:
            self.handle_ldc(instr)
        elif op == OP_LOAD:
            self.handle_load(instr)
        elif op == OP_STORE:
            self.handle_store(instr)
        elif op == OP_VMSYS:
            self.handle_vmsys(instr)
        else:
            if self.trace:
                print "Unknown opcode: " + str(op)
            self.state.running = false

    proc handle_ldc(self, instr):
        let idx = (instr.raw >> 12) & 0xFFFFF
        self.state.x[instr.rd] = self.safe_get_constant(idx)
        self.state.pc = self.state.pc + 4

    proc handle_load(self, instr):
        let addr = self.state.x[instr.rs1] + instr.imm_i
        if addr >= len(self.state.stack) and addr < self.state.max_stack_size:
            while len(self.state.stack) <= addr:
                push(self.state.stack, 0)
        if addr >= 0 and addr < len(self.state.stack):
            self.state.x[instr.rd] = self.state.stack[addr]
        else:
            if self.trace:
                print "Load access violation at " + str(addr)
            self.state.running = false
        self.state.pc = self.state.pc + 4

    proc handle_store(self, instr):
        let addr = self.state.x[instr.rs1] + instr.imm_s
        let val = self.state.x[instr.rs2]
        if addr >= len(self.state.stack) and addr < self.state.max_stack_size:
            while len(self.state.stack) <= addr:
                push(self.state.stack, 0)
        if addr >= 0 and addr < len(self.state.stack):
            self.state.stack[addr] = val
        else:
            if self.trace:
                print "Store access violation at " + str(addr)
            self.state.running = false
        self.state.pc = self.state.pc + 4

    proc handle_branch(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let rs2_val = self.state.x[instr.rs2]
        var take = false
        let f3 = instr.funct3
        if f3 == F3_BEQ: take = (rs1_val == rs2_val)
        elif f3 == F3_BNE: take = (rs1_val != rs2_val)
        elif f3 == F3_BLT: take = (rs1_val < rs2_val)
        elif f3 == F3_BGE: take = (rs1_val >= rs2_val)
        elif f3 == F3_BLTU: take = (rs1_val < rs2_val) # TODO: unsigned comparison
        elif f3 == F3_BGEU: take = (rs1_val >= rs2_val) # TODO: unsigned comparison
        
        if take:
            self.state.pc = self.state.pc + instr.imm_b
        else:
            self.state.pc = self.state.pc + 4

    proc handle_imm(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let imm = instr.imm_i
        let f3 = instr.funct3
        if f3 == F3_ADDI:
            if imm == 0: self.state.x[instr.rd] = rs1_val
            else: self.state.x[instr.rd] = rs1_val + imm
        elif f3 == F3_SLTI:
            if rs1_val < imm: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_SLTIU:
            if rs1_val < imm: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_XORI: self.state.x[instr.rd] = rs1_val ^ imm
        elif f3 == F3_ORI: self.state.x[instr.rd] = rs1_val | imm
        elif f3 == F3_ANDI: self.state.x[instr.rd] = rs1_val & imm
        elif f3 == F3_SLLI: self.state.x[instr.rd] = rs1_val << (imm & 0x3F)
        elif f3 == F3_SRLI:
            let shamt = imm & 0x3F
            if instr.funct7 == 0x20:
                # SRAI: arithmetic right shift (sign-extending)
                self.state.x[instr.rd] = rs1_val >> shamt
            else:
                # SRLI: logical right shift (zero-fill)
                # For non-negative values, >> works as logical shift
                # For negative values, mask to 64-bit unsigned first
                if rs1_val < 0:
                    let unsigned_val = rs1_val + (1 << 64)
                    self.state.x[instr.rd] = unsigned_val >> shamt
                else:
                    self.state.x[instr.rd] = rs1_val >> shamt
        self.state.pc = self.state.pc + 4

    proc handle_reg(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let rs2_val = self.state.x[instr.rs2]
        let f3 = instr.funct3
        let f7 = instr.funct7

        if f7 == 0x01: # M-extension
            if f3 == F3_ADD: # MUL
                self.state.x[instr.rd] = rs1_val * rs2_val
            elif f3 == F3_XOR: # DIV
                if rs2_val != 0: self.state.x[instr.rd] = rs1_val / rs2_val
                else: self.state.x[instr.rd] = 0
            elif f3 == F3_OR: # REM
                if rs2_val != 0: self.state.x[instr.rd] = rs1_val % rs2_val
                else: self.state.x[instr.rd] = 0
            self.state.pc = self.state.pc + 4
            return

        if f3 == F3_ADD:
            if f7 == 0x00: 
                self.state.x[instr.rd] = rs1_val + rs2_val
            elif f7 == 0x20: self.state.x[instr.rd] = rs1_val - rs2_val
        elif f3 == F3_SLL: self.state.x[instr.rd] = rs1_val << (rs2_val & 0x3F)
        elif f3 == F3_SLT:
            if rs1_val < rs2_val: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_SLTU:
            if rs1_val < rs2_val: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_XOR: self.state.x[instr.rd] = rs1_val ^ rs2_val
        elif f3 == F3_SRL:
            let shamt = rs2_val & 0x3F
            if f7 == 0x20:
                # SRA: arithmetic right shift
                self.state.x[instr.rd] = rs1_val >> shamt
            else:
                # SRL: logical right shift
                if rs1_val < 0:
                    let unsigned_val = rs1_val + (1 << 64)
                    self.state.x[instr.rd] = unsigned_val >> shamt
                else:
                    self.state.x[instr.rd] = rs1_val >> shamt
        elif f3 == F3_OR: self.state.x[instr.rd] = rs1_val | rs2_val
        elif f3 == F3_AND: self.state.x[instr.rd] = rs1_val & rs2_val
        self.state.pc = self.state.pc + 4

    proc handle_vmsys(self, instr):
        let f3 = instr.funct3
        let sub_op = instr.rs1
        
        if f3 == F3_VM_OPS:
            if sub_op == VMO_HALT:
                self.state.running = false
            elif sub_op == VMO_IMPORT:
                let idx = int(self.state.x[10]) # a0
                let name = self.safe_get_constant(idx)
                if not self.state.running: return

                # Security: Explicitly block sensitive modules in safe mode
                if self.state.safe_mode and (name == "io" or name == "net" or name == "sys" or name == "thread" or name == "gpu" or name == "ml_native" or name == "mem" or name == "ffi" or name == "struct"):
                    print "Error: Access to module '" + name + "' is restricted in safe mode"
                    self.state.x[instr.rd] = nil
                elif name == "ffi" and not self.state.ffi_enabled:
                    print "Error: FFI is disabled"
                    self.state.x[instr.rd] = nil
                else:
                    try:
                        if name == "math":
                            let m = {"pi": 3.141592653589793, "e": 2.718281828459045}
                            m["__type__"] = "module"
                            m["abs"] = math.abs
                            m["sqrt"] = math.sqrt
                            m["sin"] = math.sin
                            m["cos"] = math.cos
                            m["printm"] = "__builtin_math_printm"
                            self.state.x[instr.rd] = m
                        elif name == "io": self.state.x[instr.rd] = io
                        elif name == "sys":
                            let s = {"args": sys.args()}
                            s["__type__"] = "module"
                            s["exec"] = "__builtin_sys_exec"
                            s["exit"] = sys.exit
                            self.state.x[instr.rd] = s
                        elif name == "net": self.state.x[instr.rd] = net
                        elif name == "gpu":
                            let g = {}
                            g["__type__"] = "module"
                            g["poll_events"] = gpu.poll_events
                            g["get_time"] = gpu.get_time
                            g["mouse_pos"] = gpu.mouse_pos
                            self.state.x[instr.rd] = g
                        elif name == "ml_native": self.state.x[instr.rd] = ml_native
                        elif name == "thread": self.state.x[instr.rd] = host_thread
                        elif name == "mem":
                            let m = {"__host_mod__": "mem", "alloc": "__builtin_mem_alloc", "free": "__builtin_mem_free", "read": "__builtin_mem_read", "write": "__builtin_mem_write", "size": "__builtin_mem_size"}
                            self.state.x[instr.rd] = m
                        elif name == "ffi":
                            let f = {"__host_mod__": "ffi", "open": "__builtin_ffi_open", "close": "__builtin_ffi_close", "call": "__builtin_ffi_call"}
                            self.state.x[instr.rd] = f
                        elif name == "struct":
                            let s = {"__host_mod__": "struct", "def": "__builtin_struct_def", "new": "__builtin_struct_new", "get": "__builtin_struct_get", "set": "__builtin_struct_set", "size": "__builtin_struct_size"}
                            self.state.x[instr.rd] = s
                        else:
                            self.state.x[instr.rd] = {"__type__": "module", "__name__": name}
                    catch e:
                        self.state.x[instr.rd] = {"__type__": "module", "__name__": name}
            elif sub_op == VMO_PRINT:
                print str(self.state.x[10]) # Use a0
            elif sub_op == VMO_PRINTM:
                print str(self.state.x[10])
            elif sub_op == VMO_PUSH_ENV:
                # Security: Prevent environment stack exhaustion (DoS)
                if len(self.state.call_stack) >= self.state.max_call_depth:
                    print "Error: Call depth limit exceeded"
                    self.state.running = false
                    return
                push(self.state.call_stack, self.state.heap)
                self.state.heap = {}
            elif sub_op == VMO_POP_ENV:
                if len(self.state.call_stack) > 0:
                    self.state.heap = pop(self.state.call_stack)
            elif sub_op == VMO_CALL:
                # Security: Prevent infinite recursion from exhausting host resources (DoS)
                if len(self.state.call_stack) >= self.state.max_call_depth:
                    print "Error: Call depth limit exceeded"
                    self.state.running = false
                    return

                let func_obj = self.state.x[instr.rs2] 
                var target_chunk = -1
                if type(func_obj) == "number": target_chunk = int(func_obj)
                elif type(func_obj) == "dict" and dict_has(func_obj, "chunk_idx"): target_chunk = int(func_obj["chunk_idx"])
                elif type(func_obj) == "dict" and dict_has(func_obj, "__builtin__"):
                    let b_name = func_obj["__builtin__"]
                    if b_name == "str":
                        self.state.x[10] = str(self.state.x[10]) # Result in a0
                    elif b_name == "int":
                        self.state.x[10] = int(self.state.x[10])
                    elif b_name == "slice":
                        self.state.x[10] = slice(self.state.x[10], self.state.x[11], self.state.x[12])
                    elif b_name == "len":
                        self.state.x[10] = len(self.state.x[10])
                    elif b_name == "type":
                        self.state.x[10] = type(self.state.x[10])
                    elif b_name == "range":
                        self.state.x[10] = range(self.state.x[10])
                    elif b_name == "clock":
                        self.state.x[10] = clock()
                    elif b_name == "tonumber":
                        self.state.x[10] = tonumber(self.state.x[10])
                    elif b_name == "push":
                        if self.is_protected(self.state.x[10]):
                            print "Error: Modification of protected object is restricted in safe mode"
                            self.state.x[10] = nil
                        else:
                            push(self.state.x[10], self.state.x[11])
                            self.state.x[10] = nil
                    elif b_name == "pop":
                        if self.is_protected(self.state.x[10]):
                            print "Error: Modification of protected object is restricted in safe mode"
                            self.state.x[10] = nil
                        else:
                            self.state.x[10] = pop(self.state.x[10])
                    elif b_name == "chr":
                        self.state.x[10] = chr(self.state.x[10])
                    elif b_name == "ord":
                        self.state.x[10] = ord(self.state.x[10])
                    elif b_name == "dict_has":
                        let obj = self.state.x[10]
                        let key = self.state.x[11]
                        if self.state.safe_mode and type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg"):
                            self.state.x[10] = false
                        else:
                            self.state.x[10] = dict_has(obj, key)
                    elif b_name == "dict_keys":
                        let obj = self.state.x[10]
                        let keys = dict_keys(obj)
                        if self.state.safe_mode:
                            let safe_keys = []
                            var i = 0
                            while i < len(keys):
                                let key = keys[i]
                                if not (type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg")):
                                    push(safe_keys, key)
                                i = i + 1
                            self.state.x[10] = safe_keys
                        else:
                            self.state.x[10] = keys
                    elif b_name == "dict_values":
                        let obj = self.state.x[10]
                        if self.state.safe_mode:
                            let safe_vals = []
                            let keys = dict_keys(obj)
                            var i = 0
                            while i < len(keys):
                                let key = keys[i]
                                if not (type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg")):
                                    push(safe_vals, obj[key])
                                i = i + 1
                            self.state.x[10] = safe_vals
                        else:
                            self.state.x[10] = dict_values(obj)
                    elif b_name == "gc_stats":
                        self.state.x[10] = gc_stats()
                    elif b_name == "gc_collect":
                        gc_collect()
                        self.state.x[10] = nil
                    elif b_name == "gc_enable":
                        gc_enable()
                        self.state.x[10] = nil
                    elif b_name == "gc_disable":
                        gc_disable()
                        self.state.x[10] = nil
                    elif b_name == "startswith":
                        self.state.x[10] = startswith(self.state.x[10], self.state.x[11])
                    elif b_name == "endswith":
                        self.state.x[10] = endswith(self.state.x[10], self.state.x[11])
                    elif b_name == "contains":
                        self.state.x[10] = contains(self.state.x[10], self.state.x[11])
                    elif b_name == "join":
                        self.state.x[10] = join(self.state.x[10], self.state.x[11])
                    elif b_name == "split":
                        self.state.x[10] = split(self.state.x[10], self.state.x[11])
                    elif b_name == "replace":
                        self.state.x[10] = replace(self.state.x[10], self.state.x[11], self.state.x[12])
                    elif b_name == "upper":
                        self.state.x[10] = upper(self.state.x[10])
                    elif b_name == "lower":
                        self.state.x[10] = lower(self.state.x[10])
                    elif b_name == "strip":
                        self.state.x[10] = strip(self.state.x[10])
                    elif b_name == "print":
                        print str(self.state.x[10])
                        self.state.x[10] = nil
                    self.state.pc = self.state.pc + 4
                    return
                
                if target_chunk >= 0:
                    let chunk = self.safe_get_chunk(target_chunk)
                    if not self.state.running: return
                    push(self.state.call_stack, [self.state.current_chunk_idx, self.state.pc + 4, self.state.x[1]])
                    self.state.current_chunk_idx = target_chunk
                    self.state.bytecode = chunk
                    self.state.pc = 0
                    self.state.x[1] = 0
                    return
            elif sub_op == VMO_ARRAY_LEN:
                let obj = self.state.x[instr.rs2]
                if type(obj) == "list": self.state.x[instr.rd] = len(obj)
                elif type(obj) == "dict": self.state.x[instr.rd] = len(obj)
                else: self.state.x[instr.rd] = 0
            elif sub_op == VMO_SETUP_TRY:
                # Security: Prevent nested handlers from exhausting VM memory (DoS)
                if len(self.state.try_stack) >= self.state.max_try_depth:
                    print "Error: Handler depth limit exceeded"
                    self.state.running = false
                    return

                let catch_offset = instr.imm_i
                push(self.state.try_stack, [self.state.pc + catch_offset, len(self.state.call_stack)])
            elif sub_op == VMO_END_TRY:
                if len(self.state.try_stack) > 0:
                    pop(self.state.try_stack)
            elif sub_op == VMO_RAISE:
                let exc_obj = self.state.x[10] # a0
                if len(self.state.try_stack) > 0:
                    let handler = pop(self.state.try_stack)
                    let catch_pc = handler[0]
                    let target_call_depth = handler[1]
                    while len(self.state.call_stack) > target_call_depth:
                        pop(self.state.call_stack)
                    self.state.pc = catch_pc
                    self.state.x[10] = exc_obj
                    return
                else:
                    print "Unhandled exception: " + str(exc_obj)
                    self.state.running = false
                    return
        elif f3 == F3_OBJ_OPS:
            if sub_op == OBJ_GET_GLOBAL:
                let idx = int(self.state.x[10]) # a0
                let name = self.safe_get_constant(idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    self.state.x[instr.rd] = nil
                elif dict_has(self.state.heap, name):
                    self.state.x[instr.rd] = self.state.heap[name]
                elif name == "str" or name == "int" or name == "slice" or name == "len" or name == "type" or name == "range" or name == "clock" or name == "tonumber" or name == "push" or name == "pop" or name == "chr" or name == "ord" or name == "dict_has" or name == "dict_keys" or name == "dict_values" or name == "gc_stats" or name == "gc_collect" or name == "gc_enable" or name == "gc_disable" or name == "startswith" or name == "endswith" or name == "contains" or name == "join" or name == "split" or name == "replace" or name == "upper" or name == "lower" or name == "strip" or name == "print":
                    self.state.x[instr.rd] = {"__builtin__": name}
                else:
                    self.state.x[instr.rd] = nil
            elif sub_op == OBJ_SET_GLOBAL:
                let idx = int(self.state.x[10]) # a0
                let val = self.state.x[11] # a1
                let name = self.safe_get_constant(idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    print "Error: Assignment to internal global '" + name + "' is restricted in safe mode"
                else:
                    self.state.heap[name] = val
            elif sub_op == OBJ_GET_PROP:
                let obj = self.state.x[instr.rs2]
                let name_idx = int(self.state.x[10])
                let name = self.safe_get_constant(name_idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    self.state.x[instr.rd] = nil
                elif type(obj) == "dict": self.state.x[instr.rd] = obj[name]
                else: self.state.x[instr.rd] = nil
            elif sub_op == OBJ_SET_PROP:
                let obj = self.state.x[instr.rs2]
                let name_idx = int(self.state.x[10])
                let val = self.state.x[11]
                let name = self.safe_get_constant(name_idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    print "Error: Access to internal property '" + name + "' is restricted in safe mode"
                elif self.is_protected(obj):
                    print "Error: Modification of protected object '" + name + "' is restricted in safe mode"
                elif type(obj) == "dict":
                    obj[name] = val
            elif sub_op == OBJ_NEW_FUNC:
                let chunk_idx = int(self.state.x[10])
                self.state.x[instr.rd] = {"type": "function", "chunk_idx": chunk_idx}
            elif sub_op == OBJ_ARRAY_NEW:
                let size = int(self.state.x[10])
                # Security: Prevent memory exhaustion via large array allocation (DoS)
                if size < 0 or size > self.state.max_array_size:
                    print "Error: Array size limit exceeded: " + str(size)
                    self.state.running = false
                    return

                let init_val = self.state.x[11]
                var arr = []
                var i = 0
                while i < size:
                    push(arr, init_val)
                    i = i + 1
                self.state.x[instr.rd] = arr
            elif sub_op == OBJ_GET_INDEX:
                let obj = self.state.x[instr.rs2]
                let raw_idx = self.state.x[10]
                if self.state.safe_mode and type(raw_idx) == "string" and startswith(raw_idx, "__") and not startswith(raw_idx, "__arg"):
                    self.state.x[instr.rd] = nil
                elif type(obj) == "dict":
                    self.state.x[instr.rd] = obj[raw_idx]
                elif type(obj) == "list":
                    let idx = int(raw_idx)
                    if idx >= 0 and idx < len(obj):
                        self.state.x[instr.rd] = obj[idx]
                    else: self.state.x[instr.rd] = nil
                else: self.state.x[instr.rd] = nil
            elif sub_op == OBJ_SET_INDEX:
                let obj = self.state.x[instr.rs2]
                let raw_idx = self.state.x[10]
                let val = self.state.x[11]
                if self.state.safe_mode and type(raw_idx) == "string" and startswith(raw_idx, "__") and not startswith(raw_idx, "__arg"):
                    print "Error: Index assignment to internal key '" + raw_idx + "' is restricted in safe mode"
                elif self.is_protected(obj):
                    print "Error: Index assignment to protected object is restricted in safe mode"
                elif type(obj) == "dict":
                    obj[raw_idx] = val
                elif type(obj) == "list":
                    let idx = int(raw_idx)
                    if idx >= 0 and idx < len(obj):
                        obj[idx] = val
        elif f3 == F3_GPU_OPS:
            self.handle_gpu(instr)
        
        self.state.pc = self.state.pc + 4

    proc handle_gpu(self, instr):
        let sub_op = instr.rs1
        # TODO: Implement mapping for 28 GPU opcodes
        if self.trace:
            print "GPU Op: " + str(sub_op)
        return nil

# Sage RISC-V (SRVM) Runner
# Loads and executes .sgrv binary files

import io

class SRVMRunner:
    proc init(self):
        self.vm = srvm_vm.SRVM()

    proc run_file(self, input_file, debug=false, safe_mode=false, ffi_enabled=true):
        print "DEBUG: SRVMRunner.run_file called for " + input_file
        var data = io.readbytes(input_file)
        if data == nil:
            print "DEBUG: data is NIL"
            print "❌ Error: Could not read file: " + input_file
            return false
        print "DEBUG: data len=" + str(len(data))
        print "DEBUG: header=" + str(int(data[0])) + " " + str(int(data[1])) + " " + str(int(data[2])) + " " + str(int(data[3]))
        
        if len(data) < 4 or int(data[0]) != 83 or int(data[1]) != 71 or int(data[2]) != 82 or int(data[3]) != 86:
            print "❌ Error: Invalid SGRV header in " + input_file
            return false
            
        self.vm.trace = debug
        self.vm.state.safe_mode = safe_mode
        self.vm.state.ffi_enabled = ffi_enabled

        var off = 6 # Magic (4) + Version (2)

        # Load Functions Count
        let func_count = (int(data[off]) << 8) | int(data[off+1])
        off = off + 2

        print "DEBUG: loading constants..."
        
        # Load Constants
        let const_count = (int(data[off]) << 8) | int(data[off+1])
        print "DEBUG: loader const_count=" + str(const_count)
        off = off + 2
        
        let ut = srvm_core.SRVMUtils()
        
        var j = 0
        while j < const_count:
            var t = int(data[off])
            off = off + 1
            if t == 1: # Number
                let val = ut.unpack_double(data, off)
                push(self.vm.state.constants, val) 
                off = off + 8
            elif t == 3: # String
                let slen = (int(data[off]) << 8) | int(data[off+1])
                off = off + 2
                var s = ""
                var k = 0
                while k < slen:
                    s = s + chr(int(data[off + k]))
                    k = k + 1
                push(self.vm.state.constants, s)
                off = off + slen
            j = j + 1
            
        # Load Chunks
        let num_chunks = (int(data[off]) << 24) | (int(data[off+1]) << 16) | (int(data[off+2]) << 8) | int(data[off+3])
        off = off + 4
        
        var chunk_idx = 0
        while chunk_idx < num_chunks:
            let clen = (int(data[off]) << 24) | (int(data[off+1]) << 16) | (int(data[off+2]) << 8) | int(data[off+3])
            off = off + 4
            
            var bc = []
            var i = 0
            while i < clen:
                push(bc, int(data[off + i]))
                i = i + 1
            push(self.vm.state.chunks, bc)
            off = off + clen
            chunk_idx = chunk_idx + 1
            
        # Execute all chunks (sequential top-level execution starting from func_count)
        chunk_idx = func_count
        while chunk_idx < num_chunks:
            self.vm.run(self.vm.state.chunks[chunk_idx])
            chunk_idx = chunk_idx + 1
        return true
import sys
import io

# The Sage RISC-V (SRVM) Disassembler
# Decodes .sgrv binaries into readable RISC-V assembly

class SRVMDisassembler:
    proc init(self, path):
        self.path = path
        self.ut = SRVMUtils()
        self.data = io.readbytes(path)
        self.pos = 0
        self.const_count = 0
        self.chunk_total = 0
        self.consts = []
        self.chunks = []

    proc disassemble(self):
        if self.data == nil:
            print "ERROR: Could not read file " + str(self.path)
            return false
        
        # Skip shebang
        if len(self.data) > 0 and int(self.data[0]) == 35:
            while self.pos < len(self.data) and int(self.data[self.pos]) != 10:
                self.pos = self.pos + 1
            if self.pos < len(self.data):
                self.pos = self.pos + 1

        # Magic "SGRV"
        if len(self.data) - self.pos < 4: return false
        var magic = ""
        var mi = 0
        while mi < 4:
            magic = magic + chr(int(self.data[self.pos + mi]))
            mi = mi + 1
        self.pos = self.pos + 4
        if magic != "SGRV":
            print "ERROR: Bad magic " + magic
            return false

        # Version (2 bytes)
        self.pos = self.pos + 2
        
        # Functions count (2 bytes)
        self.pos = self.pos + 2

        # Const count (BE16)
        self.const_count = (int(self.data[self.pos]) << 8) | int(self.data[self.pos + 1])
        self.pos = self.pos + 2
        
        # Parse constants
        var ci = 0
        var c_str = ""
        var c_idx = 0
        while ci < self.const_count:
            let ctype = int(self.data[self.pos])
            self.pos = self.pos + 1
            if ctype == 1: # Number
                let val = self.ut.unpack_double(self.data, self.pos)
                self.pos = self.pos + 8
                push(self.consts, {"type": "number", "value": val})
            elif ctype == 3: # String
                let slen = (int(self.data[self.pos]) << 8) | int(self.data[self.pos + 1])
                self.pos = self.pos + 2
                c_str = ""
                c_idx = 0
                while c_idx < slen:
                    c_str = c_str + chr(int(self.data[self.pos + c_idx]))
                    c_idx = c_idx + 1
                self.pos = self.pos + slen
                push(self.consts, {"type": "string", "value": c_str})
            else:
                push(self.consts, {"type": "unknown", "value": nil})
            ci = ci + 1
        
        # Chunk total (BE32)
        self.chunk_total = (int(self.data[self.pos]) << 24) | (int(self.data[self.pos+1]) << 16) | (int(self.data[self.pos+2]) << 8) | int(self.data[self.pos+3])
        self.pos = self.pos + 4
        
        # Parse chunks
        var chunk_idx = 0
        while chunk_idx < self.chunk_total:
            let chunk_len = (int(self.data[self.pos]) << 24) | (int(self.data[self.pos+1]) << 16) | (int(self.data[self.pos+2]) << 8) | int(self.data[self.pos+3])
            self.pos = self.pos + 4
            let end_pos = self.pos + chunk_len
            let instructions = []
            while self.pos < end_pos:
                let val = self.ut.read_le32(self.data, self.pos)
                self.pos = self.pos + 4
                push(instructions, RVInstruction(val))
            push(self.chunks, instructions)
            chunk_idx = chunk_idx + 1
        
        return true

    proc generate_sage(self):
        print "# Disassembled from .sgrv (Sage RISC-V)"
        print ""
        var chunk_idx = 0
        while chunk_idx < len(self.chunks):
            print "# --- Chunk " + str(chunk_idx) + " ---"
            let instructions = self.chunks[chunk_idx]
            var i = 0
            while i < len(instructions):
                let instr = instructions[i]
                let pc = i * 4
                let d = self.decode_instr(instr)
                var line = "  "
                line = line + self.pad_left(str(pc), 4, " ")
                line = line + ":  "
                line = line + d
                print line
                i = i + 1
            print ""
            chunk_idx = chunk_idx + 1
        return true

    proc decode_instr(self, instr):
        let reg_names = [
            "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
            "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
            "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
            "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
        ]
        let op = instr.opcode
        var res = ""
        if op == srvm_core.OP_LUI:
            res = "lui      " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + str(instr.decode_u_imm() >> 12)
            return res
        elif op == srvm_core.OP_AUIPC:
            res = "auipc    " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + str(instr.decode_u_imm() >> 12)
            return res
        elif op == srvm_core.OP_JAL:
            res = "jal      " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + str(instr.decode_j_imm())
            return res
        elif op == srvm_core.OP_JALR:
            res = "jalr     " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + reg_names[int(instr.rs1)]
            res = res + "("
            res = res + str(instr.decode_i_imm())
            res = res + ")"
            return res
        elif op == srvm_core.OP_BRANCH:
            var bop = "beq"
            let f3 = instr.funct3
            if f3 == srvm_core.F3_BNE: bop = "bne"
            elif f3 == srvm_core.F3_BLT: bop = "blt"
            elif f3 == srvm_core.F3_BGE: bop = "bge"
            elif f3 == srvm_core.F3_BLTU: bop = "bltu"
            elif f3 == srvm_core.F3_BGEU: bop = "bgeu"
            res = self.pad_right(bop, 8) + " " + reg_names[int(instr.rs1)]
            res = res + ", "
            res = res + reg_names[int(instr.rs2)]
            res = res + ", "
            res = res + str(instr.decode_b_imm())
            return res
        elif op == srvm_core.OP_LOAD:
            var lop = "lb"
            let f3 = instr.funct3
            if f3 == srvm_core.F3_LH: lop = "lh"
            elif f3 == srvm_core.F3_LW: lop = "lw"
            elif f3 == srvm_core.F3_LD: lop = "ld"
            elif f3 == srvm_core.F3_LBU: lop = "lbu"
            elif f3 == srvm_core.F3_LHU: lop = "lhu"
            res = self.pad_right(lop, 8) + " " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + str(instr.decode_i_imm())
            res = res + "("
            res = res + reg_names[int(instr.rs1)]
            res = res + ")"
            return res
        elif op == srvm_core.OP_STORE:
            var sop = "sb"
            let f3 = instr.funct3
            if f3 == srvm_core.F3_SH: sop = "sh"
            elif f3 == srvm_core.F3_SW: sop = "sw"
            elif f3 == srvm_core.F3_SD: sop = "sd"
            res = self.pad_right(sop, 8) + " " + reg_names[int(instr.rs2)]
            res = res + ", "
            res = res + str(instr.decode_s_imm())
            res = res + "("
            res = res + reg_names[int(instr.rs1)]
            res = res + ")"
            return res
        elif op == srvm_core.OP_IMM:
            var iop = "addi"
            let f3 = instr.funct3
            if f3 == srvm_core.F3_SLTI: iop = "slti"
            elif f3 == srvm_core.F3_SLTIU: iop = "sltiu"
            elif f3 == srvm_core.F3_XORI: iop = "xori"
            elif f3 == srvm_core.F3_ORI: iop = "ori"
            elif f3 == srvm_core.F3_ANDI: iop = "andi"
            elif f3 == srvm_core.F3_SLLI: iop = "slli"
            elif f3 == srvm_core.F3_SRLI:
                if instr.funct7 == 0x20: iop = "srai"
                else: iop = "srli"
            res = self.pad_right(iop, 8) + " " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + reg_names[int(instr.rs1)]
            res = res + ", "
            res = res + str(instr.decode_i_imm())
            return res
        elif op == srvm_core.OP_REG:
            var rop = "add"
            let f3 = instr.funct3
            let f7 = instr.funct7
            if f3 == srvm_core.F3_ADD:
                if f7 == 0x20: rop = "sub"
                elif f7 == 0x01: rop = "mul"
                else: rop = "add"
            elif f3 == srvm_core.F3_SLL:
                if f7 == 0x01: rop = "mulh"
                else: rop = "sll"
            elif f3 == srvm_core.F3_SLT:
                if f7 == 0x01: rop = "mulhsu"
                else: rop = "slt"
            elif f3 == srvm_core.F3_SLTU:
                if f7 == 0x01: rop = "mulhu"
                else: rop = "sltu"
            elif f3 == srvm_core.F3_XOR:
                if f7 == 0x01: rop = "div"
                else: rop = "xor"
            elif f3 == srvm_core.F3_SRL:
                if f7 == 0x20: rop = "sra"
                elif f7 == 0x01: rop = "divu"
                else: rop = "srl"
            elif f3 == srvm_core.F3_OR:
                if f7 == 0x01: rop = "rem"
                else: rop = "or"
            elif f3 == srvm_core.F3_AND:
                if f7 == 0x01: rop = "remu"
                else: rop = "and"
            res = self.pad_right(rop, 8) + " " + reg_names[int(instr.rd)]
            res = res + ", "
            res = res + reg_names[int(instr.rs1)]
            res = res + ", "
            res = res + reg_names[int(instr.rs2)]
            return res
        elif op == srvm_core.OP_LDC:
            let rd = int(instr.rd)
            let imm = int(instr.decode_u_imm() >> 12)
            var label = str(imm)
            if imm >= 0 and imm < len(self.consts):
                let c = self.consts[imm]
                if c["type"] == "string": label = label + " ('" + c["value"] + "')"
                elif c["type"] == "number": label = label + " (" + str(c["value"]) + ")"
            res = "ldc      " + reg_names[rd]
            res = res + ", "
            res = res + label
            return res
        elif op == srvm_core.OP_VMSYS:
            let f3 = instr.funct3
            if f3 == srvm_core.F3_VM_OPS:
                var vop = "vm_nop"
                let f7 = instr.funct7
                if f7 == srvm_core.VMO_HALT: vop = "halt"
                elif f7 == srvm_core.VMO_PUSH_ENV: vop = "push_env"
                elif f7 == srvm_core.VMO_POP_ENV: vop = "pop_env"
                elif f7 == srvm_core.VMO_CALL: vop = "call"
                elif f7 == srvm_core.VMO_SETUP_TRY: vop = "setup_try"
                elif f7 == srvm_core.VMO_END_TRY: vop = "end_try"
                elif f7 == srvm_core.VMO_RAISE: vop = "raise"
                elif f7 == srvm_core.VMO_IMPORT: vop = "import"
                elif f7 == srvm_core.VMO_PRINT: vop = "print"
                elif f7 == srvm_core.VMO_ARRAY_LEN: vop = "len"
                elif f7 == srvm_core.VMO_PRINTM: vop = "printm"
                elif f7 == srvm_core.VMO_EXEC_AST: vop = "exec_ast"
                res = self.pad_right(vop, 8) + " rd=" + reg_names[int(instr.rd)]
                res = res + " rs1=" + reg_names[int(instr.rs1)]
                res = res + " rs2=" + reg_names[int(instr.rs2)]
                return res
            elif f3 == srvm_core.F3_OBJ_OPS:
                var oop = "obj_op"
                res = self.pad_right(oop, 8) + " f7=" + str(instr.funct7)
                res = res + " rd=" + reg_names[int(instr.rd)]
                return res
            elif f3 == srvm_core.F3_GPU_OPS:
                res = self.pad_right("gpu_op", 8) + " f7=" + str(instr.funct7)
                res = res + " rd=" + reg_names[int(instr.rd)]
                return res
        
        return "unknown  op=" + str(op)

    proc pad_left(self, s, width, char):
        var res = s
        while len(res) < width:
            res = char + res
        return res

    proc pad_right(self, s, width):
        var res = s
        while len(res) < width:
            res = res + " "
        return res
import sys
import io

# Sage RISC-V (SGRV) Low-level Hexdump / Inspector

proc srvm_disassemble(path):
    let data = io.readbytes(path)
    if data == nil:
        print "ERROR: Could not read file " + path
        return
    
    let ut = SRVMUtils()
    var pos = 0

    # Check for shebang
    if len(data) > 0 and int(data[0]) == 35:
        while pos < len(data) and int(data[pos]) != 10:
            pos = pos + 1
        if pos < len(data):
            pos = pos + 1

    if len(data) - pos < 4:
        print "ERROR: File too short"
        return

    var magic = ""
    var m_idx = 0
    while m_idx < 4:
        magic = magic + chr(int(data[pos + m_idx]))
        m_idx = m_idx + 1
    pos = pos + 4

    if magic != "SGRV":
        print "ERROR: bad magic " + magic
        return
    print "Magic: SGRV (Sage RISC-V)"

    let ver_maj = int(data[pos])
    let ver_min = int(data[pos+1])
    pos = pos + 2
    print "Version: " + str(ver_maj) + "." + str(ver_min)

    let func_count = (int(data[pos]) << 8) | int(data[pos+1])
    pos = pos + 2
    print "Functions: " + str(func_count)

    let const_count = (int(data[pos]) << 8) | int(data[pos+1])
    pos = pos + 2
    print "Constants: " + str(const_count)

    let consts = []
    var ci = 0
    while ci < const_count:
        if pos >= len(data):
            print "ERROR: Truncated constant pool"
            return
        let ctype = int(data[pos])
        pos = pos + 1
        if ctype == 1:
            let val = ut.unpack_double(data, pos)
            pos = pos + 8
            push(consts, {"type": "number", "value": val})
            print "  const[" + str(ci) + "] = NUM " + str(val)
        elif ctype == 3:
            let slen = (int(data[pos]) << 8) | int(data[pos+1])
            pos = pos + 2
            var s = ""
            var k = 0
            while k < slen:
                s = s + chr(int(data[pos + k]))
                k = k + 1
            pos = pos + slen
            push(consts, {"type": "string", "value": s})
            print "  const[" + str(ci) + "] = STR '" + s + "'"
        else:
            push(consts, {"type": "unknown", "value": nil})
            print "  const[" + str(ci) + "] = UNKNOWN type " + str(ctype)
        ci = ci + 1

    let chunk_total = (int(data[pos]) << 24) | (int(data[pos+1]) << 16) | (int(data[pos+2]) << 8) | int(data[pos+3])
    pos = pos + 4
    print "Chunks: " + str(chunk_total)
    print ""

    let dis = srvm_disassembler_logic.SRVMDisassembler(path)
    
    var chunk_idx = 0
    while chunk_idx < chunk_total:
        if pos + 4 > len(data):
            print "ERROR: Truncated chunk header"
            return
        let chunk_len = (int(data[pos]) << 24) | (int(data[pos+1]) << 16) | (int(data[pos+2]) << 8) | int(data[pos+3])
        pos = pos + 4
        print "--- Chunk " + str(chunk_idx) + " (" + str(chunk_len) + " bytes) ---"
        let chunk_end_pos = pos + chunk_len
        var pc = 0
        while pos < chunk_end_pos:
            let val = ut.read_le32(data, pos)
            let hex_val = srvm_byte_to_hex((val >> 24) & 0xFF) + srvm_byte_to_hex((val >> 16) & 0xFF) + srvm_byte_to_hex((val >> 8) & 0xFF) + srvm_byte_to_hex(val & 0xFF)
            
            # Setup a temporary disassembler to reuse decode_instr
            let temp_dis = srvm_disassembler_logic.SRVMDisassembler(path)
            temp_dis.consts = consts
            let instr = srvm_core.RVInstruction(val)
            let decoded = temp_dis.decode_instr(instr)
            
            print "  " + srvm_pad_left(str(pc), 4, " ") + "  " + hex_val + "  " + decoded
            pos = pos + 4
            pc = pc + 4
        print ""
        chunk_idx = chunk_idx + 1

proc srvm_byte_to_hex(val):
    let chars = "0123456789abcdef"
    let high = int(val / 16) % 16
    let low = int(val) % 16
    return chars[high] + chars[low]

proc srvm_pad_left(s, width, char):
    var res = s
    while len(res) < width:
        res = char + res
    return res
gc_disable()
import sys
import io

var COLOR_RESET  = ""
var COLOR_BOLD   = ""
var COLOR_RED    = ""
var COLOR_GREEN  = ""
var COLOR_YELLOW = ""
var COLOR_CYAN   = ""

# Check for NO_COLOR or TERM=dumb to disable colors
let env_no_color = sys.getenv("NO_COLOR")
let env_term = sys.getenv("TERM")
if env_no_color == nil and env_term != "dumb":
    COLOR_RESET  = "\x1b[0m"
    COLOR_BOLD   = "\x1b[1m"
    COLOR_RED    = "\x1b[31m"
    COLOR_GREEN  = "\x1b[32m"
    COLOR_YELLOW = "\x1b[33m"
    COLOR_CYAN   = "\x1b[36m"

proc print_help():
    print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.9" + COLOR_RESET + " - The Sage Virtual Machine"
    print "Usage: " + COLOR_BOLD + "sagevm" + COLOR_RESET + " <command> [options]"
    print ""
    print "Documentation: " + COLOR_CYAN + "https://night-traders-dev.github.io/SageVM-Docs/" + COLOR_RESET
    print ""
    print COLOR_BOLD + "Commands:" + COLOR_RESET
    print "  🚀 " + COLOR_CYAN + "run" + COLOR_RESET + " <file.sgvm|sgrv> Execute a compiled binary"
    print "  🛠️  " + COLOR_CYAN + "compile" + COLOR_RESET + " <file.sage>     Compile Sage source to binary"
    print "  🔍 " + COLOR_CYAN + "dis" + COLOR_RESET + " <file.sgvm|sgrv> Disassemble binary"
    print "  📦 " + COLOR_CYAN + "hex" + COLOR_RESET + " <file.sgvm|sgrv> Low-level binary hexdump"
    print "  ℹ️  " + COLOR_CYAN + "version" + COLOR_RESET + "             Show version information"
    print ""
    print "Flags: -h, --help, -v, --version"

class SGVMCLI:
    proc init(self):
        # Dispatcher for SGVM tools
        return nil

    proc verify_input(self, input_file, is_compile):
        let data = io.readbytes(input_file)
        if data == nil:
            print COLOR_RED + "❌ Error: Could not read file: " + COLOR_RESET + input_file

            # Suggest alternative extensions if they exist
            if not endswith(input_file, ".sgvm") and not endswith(input_file, ".sgrv") and not endswith(input_file, ".sage"):
                if io.readbytes(input_file + ".sgvm") != nil:
                    print COLOR_YELLOW + "💡 Tip: Did you mean " + COLOR_CYAN + input_file + ".sgvm" + COLOR_YELLOW + "?" + COLOR_RESET
                elif io.readbytes(input_file + ".sgrv") != nil:
                    print COLOR_YELLOW + "💡 Tip: Did you mean " + COLOR_CYAN + input_file + ".sgrv" + COLOR_YELLOW + "?" + COLOR_RESET
                elif io.readbytes(input_file + ".sage") != nil:
                    print COLOR_YELLOW + "💡 Tip: " + COLOR_CYAN + input_file + ".sage" + COLOR_YELLOW + " exists. Try compiling it first." + COLOR_RESET
            return nil

        if not is_compile and endswith(input_file, ".sage"):
            print COLOR_YELLOW + "💡 Tip: It looks like you're trying to process a Sage source file with a binary tool." + COLOR_RESET
            print "   Try compiling it first: " + COLOR_CYAN + "sagevm compile " + input_file + COLOR_RESET
        elif is_compile:
            var is_bin = false
            if endswith(input_file, ".sgvm") or endswith(input_file, ".sgrv"):
                is_bin = true
            elif len(data) >= 4:
                let m0 = int(data[0])
                let m1 = int(data[1])
                let m2 = int(data[2])
                let m3 = int(data[3])
                if m0 == 83 and m1 == 71 and m2 == 86 and m3 == 77: is_bin = true # SGVM
                if m0 == 83 and m1 == 71 and m2 == 82 and m3 == 86: is_bin = true # SGRV

            if is_bin:
                print COLOR_YELLOW + "💡 Tip: It looks like you're trying to compile a binary file." + COLOR_RESET
                print "   Try running it instead: " + COLOR_CYAN + "sagevm run " + input_file + COLOR_RESET

        return data

    proc run(self):
        # In compiled binary, sys might be shadowed or nil in some scopes
        # Try to use it directly
        let args = sys.args()
        var cmd = ""
        if len(args) >= 2:
            cmd = args[1]
        
        # Handle standard version and help flags before any dispatch
        if cmd == "-v" or cmd == "--version" or cmd == "version":
            print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.9" + COLOR_RESET
            return
        if cmd == "-h" or cmd == "--help" or cmd == "help":
            print_help()
            return
        
        if cmd == "run":
            self.handle_run(args, 2)
            return
        elif cmd == "compile":
            self.handle_compile(args, 2)
            return
        elif cmd == "dis":
            self.handle_dis(args, 2)
            return
        elif cmd == "hex":
            self.handle_hex(args)
            return
        
        # Check if called via symlink (e.g. /usr/local/bin/sgvm or ./sgvm)
        let binary_name = args[0]
        if endswith(binary_name, "/sgvm") or binary_name == "sgvm":
            self.handle_run(args, 1)
            return
        elif endswith(binary_name, "/sgvmc") or binary_name == "sgvmc":
            self.handle_compile(args, 1)
            return
        elif cmd != "":
            print COLOR_RED + "❌ Unknown command: " + COLOR_RESET + cmd

            # Suggest closest match
            let valid_cmds = ["run", "compile", "dis", "hex", "version"]
            var best_match = ""
            var i_cmd = 0
            while i_cmd < len(valid_cmds):
                let v = valid_cmds[i_cmd]
                if startswith(v, cmd) or startswith(cmd, v):
                    best_match = v
                    i_cmd = len(valid_cmds)
                else:
                    i_cmd = i_cmd + 1

            if best_match != "":
                print COLOR_YELLOW + "💡 Tip: Did you mean " + COLOR_CYAN + best_match + COLOR_YELLOW + "?" + COLOR_RESET

            print ""
            print_help()

    proc handle_run(self, args, start_idx):
        var input_file = ""
        var input_file_idx = -1
        var debug = false
        var safe = false
        var no_ffi = false
        var no_exec = false
        var riscv = false
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--debug": debug = true
            elif a == "--safe": safe = true
            elif a == "--no-ffi": no_ffi = true
            elif a == "--no-exec": no_exec = true
            elif a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.9" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "🚀 SageVM Runner" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm run" + COLOR_RESET + " <file.sgvm|sgrv> [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --debug    Enable verbose debug logging"
                print "  --safe     Enable safe mode (restricts sensitive modules)"
                print "  --no-ffi   Disable Foreign Function Interface (FFI)"
                print "  --no-exec  Disable code execution via OP_EXEC_AST_STMT"
                print "  --riscv    Force execution using the RISC-V backend"
                return
            else:
                input_file = a
                input_file_idx = i
                i = len(args)
            i = i + 1
        
        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm run" + COLOR_RESET + " <file.sgvm|sgrv> [--debug] [--safe] [--no-ffi] [--riscv]"
            return

        var guest_args = [input_file]
        if input_file_idx >= 0:
            var gi = input_file_idx + 1
            while gi < len(args):
                push(guest_args, args[gi])
                gi = gi + 1

        # Verify file existence
        let data = self.verify_input(input_file, false)
        if data == nil: return
        if debug:
            print "DEBUG: Running " + input_file
        # Auto-detect RISC-V header
        if len(data) >= 4:
            if int(data[0]) == 83 and int(data[1]) == 71 and int(data[2]) == 82 and int(data[3]) == 86:
                riscv = true

        if riscv:
            let runner = SRVMRunner()
            runner.run_file(input_file, debug, safe, not no_ffi)
        else:
            let runner = SGVMRunner()
            runner.run_file(input_file, debug, safe, not no_ffi, guest_args)

    proc handle_compile(self, args, start_idx):
        var input_file = ""
        var output_file = ""
        var use_shebang = false
        var riscv = false
        var pos_idx = 0
        var iter_idx = start_idx
        while iter_idx < len(args):
            let a = args[iter_idx]
            if a == "--shebang": use_shebang = true
            elif a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.9" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "🛠️  SageVM Compiler" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm compile" + COLOR_RESET + " <input.sage> [output.sgvm|sgrv] [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --shebang  Add #!/usr/bin/env sagevm run to output"
                print "  --riscv    Force compilation to RISC-V binary (.sgrv)"
                return
            else:
                if pos_idx == 0: input_file = a
                elif pos_idx == 1: output_file = a
                pos_idx = pos_idx + 1
            iter_idx = iter_idx + 1
        
        print "DEBUG: input_file=" + str(input_file) + " output_file=" + str(output_file)
        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm compile" + COLOR_RESET + " <input.sage> [output.sgvm|sgrv] [--shebang] [--riscv]"
            return
        
        if self.verify_input(input_file, true) == nil: return

        print COLOR_CYAN + "🛠️  Compiling " + COLOR_BOLD + input_file + COLOR_RESET + "..."

        if output_file == "":
            var base = input_file
            if endswith(input_file, ".sage"):
                base = slice(input_file, 0, len(input_file) - 5)
            if riscv: output_file = base + ".sgrv"
            else: output_file = base + ".sgvm"
        
        let compiler = SGVMCompiler()
        if compiler.compile(input_file, output_file, use_shebang):
            if riscv:
                # Post-process: Translate SVM to SRVM
                let svm_data = io.readbytes(output_file)
                let rv_compiler = SGRVCompiler()
                let sgrv_data = rv_compiler.compile(svm_data)
                if sgrv_data != nil:
                    io_writebytes(output_file, sgrv_data)
                    print COLOR_GREEN + "✨ RISC-V translation complete." + COLOR_RESET
                else:
                    print COLOR_RED + "❌ RISC-V translation failed." + COLOR_RESET
            let out_data = io.readbytes(output_file)
            var size_str = ""
            if out_data != nil:
                let sz = len(out_data)
                if sz < 1024:
                    size_str = " (" + str(sz) + " bytes)"
                else:
                    # Very simple KB calculation
                    let kb = sz / 1024
                    size_str = " (" + str(kb) + " KB)"

            print COLOR_GREEN + "✨ Compilation complete: " + COLOR_RESET + output_file + size_str
            print "   Run with: " + COLOR_CYAN + "sagevm run " + output_file + COLOR_RESET
        else:
            print COLOR_RED + "❌ Compilation failed." + COLOR_RESET

    proc handle_dis(self, args, start_idx):
        var input_file = ""
        var mode = "sage"
        var riscv = false
        var i = start_idx
        while i < len(args):
            let a = args[i]
            if a == "--svm": mode = "svm"
            elif a == "--sage": mode = "sage"
            elif a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.9" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "🔍 SageVM Disassembler" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm dis" + COLOR_RESET + " <file.sgvm|sgrv> [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --sage     Generate readable Sage source code (default)"
                print "  --svm      Generate low-level SVM assembly"
                print "  --riscv    Force disassembly using RISC-V logic"
                return
            else: input_file = a
            i = i + 1
        
        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm dis" + COLOR_RESET + " <file.sgvm> [--sage | --svm] [--riscv]"
            return
        
        # Auto-detect RISC-V header
        let data = self.verify_input(input_file, false)
        if data == nil: return

        if len(data) >= 4:
            if int(data[0]) == 83 and int(data[1]) == 71 and int(data[2]) == 82 and int(data[3]) == 86:
                riscv = true

        if riscv:
            let dis = srvm_disassembler_logic.SRVMDisassembler(input_file)
            if dis.disassemble():
                dis.generate_sage()
        else:
            let dis = sgvm_disassembler_logic.SGVMDisassembler(input_file)
            if dis.disassemble():
                if mode == "svm": print dis.generate_svm()
                else: print dis.generate_sage()

    proc handle_hex(self, args):
        var input_file = ""
        var riscv = false
        var i = 2
        while i < len(args):
            let a = args[i]
            if a == "--riscv": riscv = true
            elif a == "-v" or a == "--version":
                print COLOR_CYAN + COLOR_BOLD + "✨ SageVM v0.9.9" + COLOR_RESET
                return
            elif a == "-h" or a == "--help":
                print COLOR_CYAN + COLOR_BOLD + "📦 SageVM Hexdump Utility" + COLOR_RESET
                print "Usage: " + COLOR_BOLD + "sagevm hex" + COLOR_RESET + " <file.sgvm|sgrv> [options]"
                print ""
                print COLOR_BOLD + "Options:" + COLOR_RESET
                print "  --riscv    Force hexdump using RISC-V logic"
                return
            else: input_file = a
            i = i + 1

        if input_file == "":
            print COLOR_RED + "❌ Error: No input file specified." + COLOR_RESET
            print "Usage: " + COLOR_BOLD + "sagevm hex" + COLOR_RESET + " <file.sgvm|sgrv> [--riscv]"
            return
        
        # Auto-detect RISC-V header
        let data = self.verify_input(input_file, false)
        if data == nil: return

        if len(data) >= 4:
            if int(data[0]) == 83 and int(data[1]) == 71 and int(data[2]) == 82 and int(data[3]) == 86:
                riscv = true

        if riscv:
            srvm_hexdump_logic.srvm_disassemble(input_file)
        else:
            sgvm_hexdump_logic.disassemble(input_file)
import sys

proc main():
    gc_disable()
    let cli = SGVMCLI()
    cli.run()

main()
