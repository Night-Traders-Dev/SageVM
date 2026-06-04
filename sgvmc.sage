import sys
import io

class SGVMCompiler:
    proc init(self):
        self.output_bytes = []
        self.global_consts = []
        self.local_to_global = []
        self.current_chunk = -1

    proc write_byte(self, b):
        push(self.output_bytes, my_int(b))

    proc write_string(self, s):
        var i = 0
        while i < len(s):
            self.write_byte(ord(s[i]))
            i = i + 1

    proc write_be16(self, v):
        var val = my_int(v)
        self.write_byte(my_int(val / 256))
        self.write_byte(val % 256)

    proc write_be32(self, v):
        var val = my_int(v)
        self.write_byte(my_int(val / 16777216) % 256)
        self.write_byte(my_int(val / 65536) % 256)
        self.write_byte(my_int(val / 256) % 256)
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
        var b0 = sign * 128.0 + my_int(e_field / 16)
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
        var i = 0
        while i < len(self.global_consts):
            if self.global_consts[i]["type"] == 1 and self.global_consts[i]["num"] == d:
                return i
            i = i + 1
        let c = {"type": 1, "num": d}
        push(self.global_consts, c)
        return len(self.global_consts) - 1

    proc add_const_str(self, s):
        var i = 0
        while i < len(self.global_consts):
            if self.global_consts[i]["type"] == 3 and self.global_consts[i]["str"] == s:
                return i
            i = i + 1
        let c = {"type": 3, "str": s}
        push(self.global_consts, c)
        return len(self.global_consts) - 1

proc my_int(x):
    if x == nil: return 0
    return tonumber(str(x))

proc hex_to_byte(h):
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

proc split_lines(s):
    let lines = []
    var current = ""
    let nl = chr(10)
    var i = 0
    while i < len(s):
        if s[i] == nl:
            push(lines, current)
            current = ""
        else:
            if s[i] != chr(13):
                current = current + s[i]
        i = i + 1
    if len(current) > 0:
        push(lines, current)
    return lines

proc trim(s):
    var start = 0
    while start < len(s) and (ord(s[start]) <= 32):
        start = start + 1
    var eidx = len(s)
    while eidx > start and (ord(s[eidx-1]) <= 32):
        eidx = eidx - 1
    return my_substr(s, start, eidx - start)

proc my_substr(s, start, length):
    var res = ""
    var i = 0
    while i < length:
        if start + i < len(s):
            res = res + s[start + i]
        i = i + 1
    return res

proc main():
    let args = sys.args()
    var input_file = ""
    var output_file = ""
    var use_shebang = false
    var i = 0
    while i < len(args):
        let a = args[i]
        if endswith(a, ".sage"):
            input_file = a
        elif endswith(a, ".sgvm"):
            output_file = a
        elif a == "--shebang":
            use_shebang = true
        i = i + 1
    if input_file == "" or output_file == "":
        print "Usage: sgvmc <input.sage> <output.sgvm> [--shebang]"
        return
    let tmp_svm = ".tmp.svm"
    let cmd = "sage --emit-vm " + input_file + " -o " + tmp_svm
    sys.exec(cmd)
    let content = io.readfile(tmp_svm)
    if content == nil:
        return
    let lines = split_lines(content)
    let compiler = SGVMCompiler()
    
    # First pass: parse constants
    i = 0
    var chunk_count = 0
    while i < len(lines):
        let line = trim(lines[i])
        if startswith(line, "chunks "):
            chunk_count = my_int(tonumber(trim(my_substr(line, 7, len(line)))))
        elif line == "chunk":
            compiler.current_chunk = compiler.current_chunk + 1
            push(compiler.local_to_global, [])
            var j = 0
            while j < 256:
                push(compiler.local_to_global[compiler.current_chunk], 0)
                j = j + 1
        elif startswith(line, "constants "):
            let count = my_int(tonumber(trim(my_substr(line, 10, len(line)))))
            var j = 0
            while j < count:
                i = i + 1
                let cl = trim(lines[i])
                if startswith(cl, "number "):
                    compiler.local_to_global[compiler.current_chunk][j] = compiler.add_const_num(tonumber(trim(my_substr(cl, 7, len(cl)))))
                elif startswith(cl, "string "):
                    let slen = my_int(tonumber(trim(my_substr(cl, 7, len(cl)))))
                    i = i + 1
                    let hex = trim(lines[i])
                    var s = ""
                    var k = 0
                    while k < slen:
                        s = s + chr(my_int(hex_to_byte(my_substr(hex, k*2, 2))))
                        k = k + 1
                    compiler.local_to_global[compiler.current_chunk][j] = compiler.add_const_str(s)
                j = j + 1
        i = i + 1

    if use_shebang:
        compiler.write_string("#!/usr/bin/env sgvm\n")
    compiler.write_string("SGVM")
    compiler.write_byte(0x01)
    compiler.write_byte(0x00)
    compiler.write_be16(len(compiler.global_consts))
    var cidx = 0
    while cidx < len(compiler.global_consts):
        let c = compiler.global_consts[cidx]
        compiler.write_byte(c["type"])
        if c["type"] == 1:
            compiler.write_double(c["num"])
        else:
            compiler.write_be16(len(c["str"]))
            compiler.write_string(c["str"])
        cidx = cidx + 1
    compiler.write_be32(chunk_count)
    
    # Second pass: parse code
    compiler.current_chunk = -1
    i = 0
    while i < len(lines):
        let line = trim(lines[i])
        if line == "chunk":
            compiler.current_chunk = compiler.current_chunk + 1
        elif startswith(line, "code "):
            let clen = my_int(tonumber(trim(my_substr(line, 5, len(line)))))
            compiler.write_be32(clen)
            i = i + 1
            let hex = trim(lines[i])
            var j = 0
            while j < clen * 2:
                let op = hex_to_byte(my_substr(hex, j, 2))
                compiler.write_byte(op)
                j = j + 2
                if op == 0 or op == 5 or op == 6 or op == 7: 
                    let v1 = hex_to_byte(my_substr(hex, j, 2))
                    let v2 = hex_to_byte(my_substr(hex, j+2, 2))
                    compiler.write_be16(compiler.local_to_global[compiler.current_chunk][v1 * 256 + v2])
                    j = j + 4
                elif op == 8:
                    compiler.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                    compiler.write_be16(hex_to_byte(my_substr(hex, j+4, 2)) * 256 + hex_to_byte(my_substr(hex, j+6, 2)))
                    j = j + 8
                elif op == 53:
                    compiler.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                    compiler.write_be16(hex_to_byte(my_substr(hex, j+4, 2)) * 256 + hex_to_byte(my_substr(hex, j+6, 2)))
                    compiler.write_be16(hex_to_byte(my_substr(hex, j+8, 2)) * 256 + hex_to_byte(my_substr(hex, j+10, 2)))
                    j = j + 12
                elif op == 9 or op == 10 or op == 13 or op == 35 or op == 36 or op == 39 or op == 40 or op == 41 or op == 43 or op == 49 or op == 50 or op == 51 or op == 52 or op == 54 or op == 56:
                    compiler.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                    j = j + 4
                elif op == 38:
                    compiler.write_be16(hex_to_byte(my_substr(hex, j, 2)) * 256 + hex_to_byte(my_substr(hex, j+2, 2)))
                    compiler.write_byte(hex_to_byte(my_substr(hex, j+4, 2)))
                    j = j + 6
                elif op == 37 or op == 47:
                    compiler.write_byte(hex_to_byte(my_substr(hex, j, 2)))
                    j = j + 2
        i = i + 1
    io.writebytes(output_file, compiler.output_bytes)
    print "Compilation complete."

main()
