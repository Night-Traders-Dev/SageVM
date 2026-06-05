import sys
import io

# Bytecode opcodes (Sync with bytecode.h)
var OP_CONSTANT       = 0.0
var OP_NIL            = 1.0
var OP_TRUE           = 2.0
var OP_FALSE          = 3.0
var OP_POP            = 4.0
var OP_GET_GLOBAL     = 5.0
var OP_DEFINE_GLOBAL  = 6.0
var OP_SET_GLOBAL     = 7.0
var OP_DEFINE_FUNCTION = 8.0
var OP_GET_PROPERTY   = 9.0
var OP_SET_PROPERTY   = 10.0
var OP_GET_INDEX      = 11.0
var OP_SET_INDEX      = 12.0
var OP_LOAD_FUNCTION  = 13.0
var OP_SLICE          = 14.0
var OP_ADD            = 15.0
var OP_SUB            = 16.0
var OP_MUL            = 17.0
var OP_DIV            = 18.0
var OP_MOD            = 19.0
var OP_NEGATE         = 20.0
var OP_EQUAL          = 21.0
var OP_NOT_EQUAL      = 22.0
var OP_GREATER        = 23.0
var OP_GREATER_EQUAL  = 24.0
var OP_LESS           = 25.0
var OP_LESS_EQUAL     = 26.0
var OP_BIT_AND        = 27.0
var OP_BIT_OR         = 28.0
var OP_BIT_XOR        = 29.0
var OP_BIT_NOT        = 30.0
var OP_SHIFT_LEFT     = 31.0
var OP_SHIFT_RIGHT    = 32.0
var OP_NOT            = 33.0
var OP_TRUTHY         = 34.0
var OP_JUMP           = 35.0
var OP_JUMP_IF_FALSE  = 36.0
var OP_CALL           = 37.0
var OP_CALL_METHOD    = 38.0
var OP_ARRAY          = 39.0
var OP_TUPLE          = 40.0
var OP_DICT           = 41.0
var OP_PRINT          = 42.0
var OP_EXEC_AST_STMT  = 43.0
var OP_RETURN         = 44.0
var OP_PUSH_ENV       = 45.0
var OP_POP_ENV        = 46.0
var OP_DUP            = 47.0
var OP_ARRAY_LEN      = 48.0
var OP_BREAK          = 49.0
var OP_CONTINUE       = 50.0
var OP_LOOP_BACK      = 51.0
var OP_IMPORT         = 52.0
var OP_CLASS          = 53.0
var OP_METHOD         = 54.0
var OP_INHERIT        = 55.0
var OP_SETUP_TRY      = 56.0
var OP_END_TRY        = 57.0
var OP_RAISE          = 58.0
var OP_HALT           = 255.0

class MetalVM:
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
        self.trace = false
        self.modules = {}

    proc push(self, val):
        push(self.stack, val)

    proc pop(self):
        if len(self.stack) == 0: return nil
        return pop(self.stack)

    proc peek(self, dist):
        if len(self.stack) <= dist: return nil
        return self.stack[len(self.stack) - 1 - dist]

    proc read_u8(self):
        var b = self.code[self.ip]
        self.ip = self.ip + 1
        return b

    proc read_u16(self):
        var hi = self.read_u8()
        var lo = self.read_u8()
        return hi * 256 + lo

    proc run(self, code):
        self.code = code
        self.ip = 0
        self.halted = false
        while not self.halted and self.ip < len(self.code):
            var current_ip = self.ip
            var op = self.read_u8()
            if self.trace:
                print "IP: " + str(current_ip) + " OP: " + str(op)
            
            if op == OP_CONSTANT:
                var idx = tonumber(str(self.read_u16()))
                self.push(self.constants[idx])
            elif op == OP_NIL: self.push(nil)
            elif op == OP_TRUE: self.push(true)
            elif op == OP_FALSE: self.push(false)
            elif op == OP_POP: self.pop()
            elif op == OP_GET_GLOBAL:
                var name = self.constants[tonumber(str(self.read_u16()))]
                var found = false
                var i = 0
                while i < len(self.scopes):
                    var s = self.scopes[len(self.scopes) - 1 - i]
                    if dict_has(s, name):
                        self.push(s[name])
                        found = true
                        i = len(self.scopes)
                    else:
                        i = i + 1
                if not found:
                    if dict_has(self.globals, name):
                        self.push(self.globals[name])
                    else:
                        self.push(nil)
            elif op == OP_DEFINE_GLOBAL:
                var name = self.constants[tonumber(str(self.read_u16()))]
                var val = self.pop()
                self.scopes[len(self.scopes)-1][name] = val
            elif op == OP_SET_GLOBAL:
                var name = self.constants[tonumber(str(self.read_u16()))]
                var val = self.peek(0)
                var found = false
                var i = 0
                while i < len(self.scopes):
                    var s = self.scopes[len(self.scopes) - 1 - i]
                    if dict_has(s, name):
                        s[name] = val
                        found = true
                        i = len(self.scopes)
                    else:
                        i = i + 1
                if not found:
                    self.globals[name] = val
            elif op == OP_ADD:
                var b = self.pop()
                var a = self.pop()
                self.push(a + b)
            elif op == OP_SUB:
                var b = self.pop()
                var a = self.pop()
                self.push(a - b)
            elif op == OP_MUL:
                var b = self.pop()
                var a = self.pop()
                self.push(a * b)
            elif op == OP_DIV:
                var b = self.pop()
                var a = self.pop()
                if b != 0: self.push(a / b)
                else: self.push(nil)
            elif op == OP_MOD:
                var b = self.pop()
                var a = self.pop()
                self.push(a % b)
            elif op == OP_NEGATE:
                self.push(-self.pop())
            elif op == OP_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a == b)
            elif op == OP_NOT_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a != b)
            elif op == OP_GREATER:
                var b = self.pop()
                var a = self.pop()
                self.push(a > b)
            elif op == OP_GREATER_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a >= b)
            elif op == OP_LESS:
                var b = self.pop()
                var a = self.pop()
                self.push(a < b)
            elif op == OP_LESS_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a <= b)
            elif op == OP_PRINT:
                print self.pop()
            elif op == OP_GET_INDEX:
                var idx = self.pop()
                var obj = self.pop()
                self.push(obj[idx])
            elif op == OP_SET_INDEX:
                var val = self.pop()
                var idx = self.pop()
                var obj = self.pop()
                obj[idx] = val
                self.push(val)
            elif op == OP_JUMP:
                var offset = self.read_u16()
                if offset > 32767: offset = offset - 65536
                self.ip = self.ip + tonumber(str(offset))
            elif op == OP_JUMP_IF_FALSE:
                var offset = self.read_u16()
                if offset > 32767: offset = offset - 65536
                if not self.pop(): self.ip = self.ip + tonumber(str(offset))
            elif op == OP_LOOP_BACK:
                self.ip = self.ip - tonumber(str(self.read_u16()))
            elif op == OP_PUSH_ENV:
                push(self.scopes, {})
            elif op == OP_POP_ENV:
                if len(self.scopes) > 1: pop(self.scopes)
            elif op == OP_DUP:
                var dist = self.read_u8()
                self.push(self.peek(tonumber(str(dist))))
            elif op == OP_ARRAY_LEN:
                self.push(len(self.pop()))
            elif op == OP_SETUP_TRY:
                var handler = {}
                handler["handler_ip"] = self.read_u16()
                handler["stack_depth"] = len(self.stack)
                handler["env_depth"] = len(self.scopes)
                push(self.handlers, handler)
            elif op == OP_END_TRY:
                if len(self.handlers) > 0: pop(self.handlers)
            elif op == OP_RAISE:
                var exc = self.pop()
                if len(self.handlers) > 0:
                    var h = pop(self.handlers)
                    while len(self.stack) > h["stack_depth"]: pop(self.stack)
                    while len(self.scopes) > h["env_depth"]: pop(self.scopes)
                    self.ip = tonumber(str(h["handler_ip"]))
                    self.push(exc)
                else:
                    print "Unhandled Exception"
                    print exc
                    self.halted = true
            elif op == OP_IMPORT:
                var name = self.constants[tonumber(str(self.read_u16()))]
                self.load_module(name)
            elif op == OP_CLASS:
                var name = self.constants[tonumber(str(self.read_u16()))]
                var mcount = tonumber(str(self.read_u16()))
                var pname = self.constants[tonumber(str(self.read_u16()))]
                var c = {"__name__": name, "__methods__": {}, "__parent__": pname}
                self.push(c)
            elif op == OP_METHOD:
                var name = self.constants[tonumber(str(self.read_u16()))]
                var func = self.pop()
                var c = self.peek(0)
                c["__methods__"][name] = func
            elif op == OP_INHERIT:
                var child = self.pop()
                var parent = self.pop()
                child["__parent_obj__"] = parent
                self.push(child)
            elif op == OP_CALL:
                var argc = tonumber(str(self.read_u8()))
                var args = []
                var j = 0
                while j < argc: push(args, self.pop()); j = j + 1
                var callee = self.pop()
                if type(callee) == "dict" and dict_has(callee, "__chunks__"):
                    self.run_func(callee, args)
                else: print "Warning: Unsupported call"
            elif op == OP_HALT:
                self.halted = true
            elif op == 255.0:
                self.halted = true

    proc run_func(self, func, args):
        push(self.scopes, {})
        var old_ip = self.ip
        var old_code = self.code
        var chunks = func["__chunks__"]
        var i = 0
        while i < len(chunks): self.run(chunks[i]); i = i + 1
        self.ip = old_ip
        self.code = old_code
        pop(self.scopes)

    proc load_module(self, name):
        if dict_has(self.modules, name): return
        var path = name + ".sgvm"
        var data = io.readbytes(path)
        if data == nil: print "Error: Could not load module " + name; return
        var off = 0
        if len(data) > 2 and tonumber(str(data[0])) == 35 and tonumber(str(data[1])) == 33:
            while off < len(data) and tonumber(str(data[off])) != 10: off = off + 1
            if off < len(data): off = off + 1
        if len(data) - off < 4 or tonumber(str(data[off])) != 83 or tonumber(str(data[off+1])) != 71 or tonumber(str(data[off+2])) != 86 or tonumber(str(data[off+3])) != 77: return
        var old_ip = self.ip; var old_code = self.code
        var old_constants = self.constants; var old_chunks = self.chunks
        off = off + 6
        var const_count = tonumber(str(read_be16(data, off)))
        off = off + 2
        self.constants = []
        var j = 0
        while j < const_count:
            var t = data[off]; off = off + 1
            if t == 1: push(self.constants, unpack_double(data, off)); off = off + 8
            elif t == 3:
                var slen = tonumber(str(read_be16(data, off))); off = off + 2
                var s = ""; var k = 0
                while k < slen: s = s + chr(tonumber(str(data[off + k]))); k = k + 1
                push(self.constants, s); off = off + slen
            j = j + 1
        var chunk_count = tonumber(str(read_be32(data, off))); off = off + 4
        self.chunks = []
        var c = 0
        while c < chunk_count:
            var clen = tonumber(str(read_be32(data, off))); off = off + 4
            var chunk_code = []; var k = 0
            while k < clen: push(chunk_code, data[off + k]); k = k + 1
            push(self.chunks, chunk_code); off = off + clen
            c = c + 1
        var idx = 0
        while idx < len(self.chunks): self.run(self.chunks[idx]); idx = idx + 1
        self.ip = old_ip; self.code = old_code
        self.constants = old_constants; self.chunks = old_chunks

class SGVMCompiler:
    proc init(self):
        self.output_bytes = []
        self.global_consts = []
        self.local_to_global = []
        self.current_chunk = -1

    proc write_byte(self, b): push(self.output_bytes, tonumber(str(b)))

    proc write_string(self, s):
        var i = 0
        while i < len(s): self.write_byte(ord(s[i])); i = i + 1

    proc write_be16(self, v):
        var val = tonumber(str(v))
        self.write_byte(tonumber(str(val / 256))); self.write_byte(val % 256)

    proc write_be32(self, v):
        var val = tonumber(str(v))
        self.write_byte(tonumber(str(val / 16777216)) % 256)
        self.write_byte(tonumber(str(val / 65536)) % 256)
        self.write_byte(tonumber(str(val / 256)) % 256)
        self.write_byte(val % 256)

    proc write_double(self, v):
        if v == nil: return
        if v == 0.0:
            var i = 0
            while i < 8: self.write_byte(0); i = i + 1
            return
        var sign = 0.0; var val = v
        if val < 0.0: sign = 1.0; val = -val
        var exp = 0
        if val >= 1.0:
            while val >= 2.0: val = val / 2.0; exp = exp + 1
        else:
            while val < 1.0: val = val * 2.0; exp = exp - 1
        var mantissa = val - 1.0; var e_field = exp + 1023
        var b0 = sign * 128.0 + tonumber(str(e_field / 16))
        var b1 = (e_field % 16) * 16
        var f = mantissa; var bits = []; var i = 0
        while i < 52:
            f = f * 2.0
            if f >= 1.0: push(bits, 1.0); f = f - 1.0
            else: push(bits, 0.0)
            i = i + 1
        var b1_low = 0.0; var k = 0
        while k < 4: b1_low = b1_low * 2.0 + bits[k]; k = k + 1
        self.write_byte(b0); self.write_byte(b1 + b1_low)
        var byte_idx = 2
        while byte_idx < 8:
            var bv = 0.0; var bit_idx = 0
            while bit_idx < 8: bv = bv * 2.0 + bits[4 + (byte_idx-2)*8 + bit_idx]; bit_idx = bit_idx + 1
            self.write_byte(bv); byte_idx = byte_idx + 1

    proc add_const_num(self, d):
        var i = 0
        while i < len(self.global_consts):
            if self.global_consts[i]["type"] == 1 and self.global_consts[i]["num"] == d: return i
            i = i + 1
        push(self.global_consts, {"type": 1, "num": d})
        return len(self.global_consts) - 1

    proc add_const_str(self, s):
        var i = 0
        while i < len(self.global_consts):
            if self.global_consts[i]["type"] == 3 and self.global_consts[i]["str"] == s: return i
            i = i + 1
        push(self.global_consts, {"type": 3, "str": s})
        return len(self.global_consts) - 1

    proc compile(self, input_file, output_file, use_shebang):
        let tmp_svm = ".tmp.svm"
        sys.exec("sage --emit-vm " + input_file + " -o " + tmp_svm)
        let content = io.readfile(tmp_svm)
        if content == nil: return
        let lines = split_lines(content); var i = 0; var chunk_count = 0
        while i < len(lines):
            let line = trim(lines[i])
            if startswith(line, "chunks "): chunk_count = tonumber(str(tonumber(trim(my_substr(line, 7, len(line))))))
            elif line == "chunk":
                self.current_chunk = self.current_chunk + 1
                push(self.local_to_global, [])
                var j = 0
                while j < 512: push(self.local_to_global[self.current_chunk], 0); j = j + 1
            elif startswith(line, "constants "):
                let count = tonumber(str(tonumber(trim(my_substr(line, 10, len(line))))))
                var j = 0
                while j < count:
                    i = i + 1; let cl = trim(lines[i])
                    if startswith(cl, "number "): self.local_to_global[self.current_chunk][j] = self.add_const_num(tonumber(trim(my_substr(cl, 7, len(cl)))))
                    elif startswith(cl, "string "):
                        let slen = tonumber(str(tonumber(trim(my_substr(cl, 7, len(cl)))))); i = i + 1
                        let hex = trim(lines[i]); var s = ""; var k = 0
                        while k < slen: s = s + chr(tonumber(str(hex_to_byte(my_substr(hex, k*2, 2))))); k = k + 1
                        self.local_to_global[self.current_chunk][j] = self.add_const_str(s)
                    j = j + 1
            i = i + 1
        if use_shebang: self.write_string("#!/usr/bin/env sgvm\n")
        self.write_string("SGVM"); self.write_byte(0x01); self.write_byte(0x00)
        self.write_be16(len(self.global_consts))
        var cidx = 0
        while cidx < len(self.global_consts):
            let c = self.global_consts[cidx]; self.write_byte(c["type"])
            if c["type"] == 1: self.write_double(c["num"])
            else: self.write_be16(len(c["str"])); self.write_string(c["str"])
            cidx = cidx + 1
        self.write_be32(chunk_count); self.current_chunk = -1; i = 0
        while i < len(lines):
            let line = trim(lines[i])
            if line == "chunk": self.current_chunk = self.current_chunk + 1
            elif startswith(line, "code "):
                let clen = tonumber(str(tonumber(trim(my_substr(line, 5, len(line)))))); self.write_be32(clen)
                i = i + 1; let hex = trim(lines[i]); var j = 0
                while j < clen * 2:
                    let op = hex_to_byte(my_substr(hex, j, 2)); self.write_byte(op); j = j + 2
                    if op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_SET_GLOBAL: 
                        let v1 = hex_to_byte(my_substr(hex, j, 2)); let v2 = hex_to_byte(my_substr(hex, j+2, 2))
                        self.write_be16(self.local_to_global[self.current_chunk][v1 * 256 + v2]); j = j + 4
                    elif op == OP_DEFINE_FUNCTION:
                        self.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                        self.write_be16(hex_to_byte(my_substr(hex, j+4, 2)) * 256 + hex_to_byte(my_substr(hex, j+6, 2))); j = j + 8
                    elif op == OP_CLASS:
                        self.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                        self.write_be16(hex_to_byte(my_substr(hex, j+4, 2)) * 256 + hex_to_byte(my_substr(hex, j+6, 2)))
                        self.write_be16(hex_to_byte(my_substr(hex, j+8, 2)) * 256 + hex_to_byte(my_substr(hex, j+10, 2))); j = j + 12
                    elif op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_LOAD_FUNCTION or op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_ARRAY or op == OP_TUPLE or op == OP_DICT or op == OP_EXEC_AST_STMT or op == OP_BREAK or op == OP_CONTINUE or op == OP_LOOP_BACK or op == OP_IMPORT or op == OP_METHOD or op == OP_SETUP_TRY:
                        self.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2))); j = j + 4
                    elif op == OP_CALL_METHOD:
                        self.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                        self.write_byte(hex_to_byte(my_substr(hex, j+4, 2))); j = j + 6
                    elif op == OP_CALL or op == OP_DUP: self.write_byte(hex_to_byte(my_substr(hex, j, 2))); j = j + 2
            i = i + 1
        io.writebytes(output_file, self.output_bytes)

proc read_be16(bs, off): return bs[off] * 256 + bs[off+1]
proc read_be32(bs, off): return bs[off] * 16777216 + bs[off+1] * 65536 + bs[off+2] * 256 + bs[off+3]
proc unpack_double(bs, off):
    var b0 = bs[off]; var b1 = bs[off+1]; var b2 = bs[off+2]; var b3 = bs[off+3]; var b4 = bs[off+4]; var b5 = bs[off+5]; var b6 = bs[off+6]; var b7 = bs[off+7]
    var sign = 1.0; if tonumber(str(b0 / 128)) == 1: sign = -1.0
    var exp = (tonumber(str(b0 % 128)) * 16) + tonumber(str(b1 / 16))
    var mantissa = 1.0; if exp == 0: mantissa = 0.0; exp = 1
    mantissa = mantissa + (tonumber(str(b1 % 16)) / 16.0) + (b2 / 4096.0) + (b3 / 1048576.0) + (b4 / 268435456.0) + (b5 / 68719476736.0) + (b6 / 17592186044416.0) + (b7 / 4503599627370496.0)
    var p2 = 1.0; var e = exp - 1023
    if e > 0:
        var i = 0
        while i < e: p2 = p2 * 2.0; i = i + 1
    elif e < 0:
        var i = 0
        while i < -e: p2 = p2 / 2.0; i = i + 1
    return sign * mantissa * p2

proc hex_to_byte(h):
    let chars = "0123456789abcdef"; var v1 = 0; var v2 = 0
    var c1 = h[0]; var c2 = h[1]
    if ord(c1) >= 65 and ord(c1) <= 70: c1 = chr(ord(c1) + 32)
    if ord(c2) >= 65 and ord(c2) <= 70: c2 = chr(ord(c2) + 32)
    var i = 0
    while i < 16:
        if chars[i] == c1: v1 = i
        if chars[i] == c2: v2 = i
        i = i + 1
    return v1 * 16 + v2

proc split_lines(s):
    let lines = []; var current = ""; let nl = chr(10); var i = 0
    while i < len(s):
        if s[i] == nl: push(lines, current); current = ""
        else:
            if s[i] != chr(13): current = current + s[i]
        i = i + 1
    if len(current) > 0: push(lines, current)
    return lines

proc trim(s):
    var start = 0; while start < len(s) and (ord(s[start]) <= 32): start = start + 1
    var eidx = len(s); while eidx > start and (ord(s[eidx-1]) <= 32): eidx = eidx - 1
    return string_substr(s, start, eidx - start)

proc my_substr(s, start, length):
    var res = ""; var i = 0
    while i < length:
        if start + i < len(s): res = res + s[start + i]
        i = i + 1
    return res
