import sys
import io

# Accumulator for output bytes
let output_bytes = []

proc write_byte(b):
    push(output_bytes, b & 0xFF)

proc write_string(s):
    var i = 0
    while i < len(s):
        write_byte(ord(s[i]))
        i = i + 1

proc write_be16(v):
    write_byte((v >> 8) & 0xFF)
    write_byte(v & 0xFF)

proc write_be32(v):
    write_byte((v >> 24) & 0xFF)
    write_byte((v >> 16) & 0xFF)
    write_byte((v >> 8) & 0xFF)
    write_byte(v & 0xFF)

proc hex_to_byte(h):
    let chars = "0123456789abcdef"
    var v1 = 0
    var v2 = 0
    var c1 = h[0]
    var c2 = h[1]
    
    if ord(c1) >= 65 and ord(c1) <= 70: c1 = chr(ord(c1) + 32)
    if ord(c2) >= 65 and ord(c2) <= 70: c2 = chr(ord(c2) + 32)

    var i = 0
    while i < 16:
        if chars[i] == c1: v1 = i
        if chars[i] == c2: v2 = i
        i = i + 1
    
    return (v1 << 4) | v2

proc create_const(type, val):
    let c = {}
    c["type"] = type
    if type == 1:
        c["num"] = val
    else:
        c["str"] = val
    return c

let global_consts = []

proc add_const_num(d):
    var i = 0
    while i < len(global_consts):
        if global_consts[i]["type"] == 1 and global_consts[i]["num"] == d:
            return i
        i = i + 1
    push(global_consts, create_const(1, d))
    return len(global_consts) - 1

proc add_const_str(s):
    var i = 0
    while i < len(global_consts):
        if global_consts[i]["type"] == 3 and global_consts[i]["str"] == s:
            return i
        i = i + 1
    push(global_consts, create_const(3, s))
    return len(global_consts) - 1

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
    return slice(s, start, eidx)

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
        if endswith(a, ".sage"): input_file = a
        elif endswith(a, ".sgvm"): output_file = a
        elif a == "--shebang": use_shebang = true
        i = i + 1

    if input_file == "" or output_file == "":
        print "Usage: sgvmc <input.sage> <output.sgvm> [--shebang]"
        return

    let tmp_svm = ".tmp.svm"
    let cmd = "sage --emit-vm " + input_file + " -o " + tmp_svm
    sys.exec(cmd)

    let content = io.readfile(tmp_svm)
    if content == nil:
        print "Error: Could not read intermediate VM file"
        return

    let lines = split_lines(content)
    var chunk_count = 0
    let local_to_global = []
    var current_chunk = -1

    i = 0
    while i < len(lines):
        let line = lines[i]
        if startswith(line, "chunks "):
            chunk_count = tonumber(trim(my_substr(line, 7, len(line))))
        elif line == "chunk":
            current_chunk = current_chunk + 1
            push(local_to_global, [])
            var j = 0
            while j < 256:
                push(local_to_global[current_chunk], 0)
                j = j + 1
        elif startswith(line, "constants "):
            let count = tonumber(trim(my_substr(line, 10, len(line))))
            var j = 0
            while j < count:
                i = i + 1
                let cl = lines[i]
                if startswith(cl, "number "):
                    local_to_global[current_chunk][j] = add_const_num(tonumber(trim(my_substr(cl, 7, len(cl)))))
                elif startswith(cl, "string "):
                    let slen = tonumber(trim(my_substr(cl, 7, len(cl))))
                    i = i + 1
                    let hex = lines[i]
                    var s = ""
                    var k = 0
                    while k < slen:
                        s = s + chr(hex_to_byte(my_substr(hex, k*2, 2)))
                        k = k + 1
                    local_to_global[current_chunk][j] = add_const_str(s)
                j = j + 1
        i = i + 1

    if use_shebang:
        write_string("#!/usr/bin/env sgvm\n")
    write_string("SGVM")
    write_byte(0x01)
    write_byte(0x00)

    write_be16(len(global_consts))
    var cidx = 0
    while cidx < len(global_consts):
        let c = global_consts[cidx]
        write_byte(c["type"])
        if c["type"] == 1:
            var k = 0
            while k < 8:
                write_byte(0) # FIXME: Pack double
                k = k + 1
        else:
            write_be16(len(c["str"]))
            write_string(c["str"])
        cidx = cidx + 1

    write_be32(chunk_count)
    
    current_chunk = -1
    i = 0
    while i < len(lines):
        let line = lines[i]
        if line == "chunk":
            current_chunk = current_chunk + 1
        elif startswith(line, "code "):
            let clen = tonumber(trim(my_substr(line, 5, len(line))))
            write_be32(clen)
            i = i + 1
            let hex = lines[i]
            var j = 0
            while j < clen * 2:
                let op = hex_to_byte(my_substr(hex, j, 2))
                write_byte(op)
                j = j + 2
                if op == 0 or op == 5 or op == 6 or op == 7: # 16-bit constant/name index
                    let local_idx = (hex_to_byte(my_substr(hex, j, 2)) << 8) | hex_to_byte(my_substr(hex, j+2, 2))
                    let g_idx = local_to_global[current_chunk][local_idx]
                    write_byte((g_idx >> 8) & 0xFF)
                    write_byte(g_idx & 0xFF)
                    j = j + 4
                elif op == 8: # DEFINE_FUNCTION (16-bit name, 16-bit function)
                    write_byte(hex_to_byte(my_substr(hex, j, 2)))
                    write_byte(hex_to_byte(my_substr(hex, j+2, 2)))
                    write_byte(hex_to_byte(my_substr(hex, j+4, 2)))
                    write_byte(hex_to_byte(my_substr(hex, j+6, 2)))
                    j = j + 8
                elif op == 9 or op == 10 or op == 13 or op == 35 or op == 36 or op == 39 or op == 40 or op == 41 or op == 43 or op == 49 or op == 50 or op == 51: # 16-bit operand
                    write_byte(hex_to_byte(my_substr(hex, j, 2)))
                    write_byte(hex_to_byte(my_substr(hex, j+2, 2)))
                    j = j + 4
                elif op == 38: # CALL_METHOD (16-bit name, 8-bit count)
                    write_byte(hex_to_byte(my_substr(hex, j, 2)))
                    write_byte(hex_to_byte(my_substr(hex, j+2, 2)))
                    write_byte(hex_to_byte(my_substr(hex, j+4, 2)))
                    j = j + 6
                elif op == 37 or op == 47: # 8-bit operand
                    write_byte(hex_to_byte(my_substr(hex, j, 2)))
                    j = j + 2
        i = i + 1
    
    io.writebytes(output_file, output_bytes)
    print "Compilation complete."

main()
