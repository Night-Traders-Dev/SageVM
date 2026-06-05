import sys
import io
from sgvm_vm import MetalVM
from sgvm_core import SGVMUtils

proc main():
    var args = sys.args()
    var input_file = ""
    var trace = false
    var i = 0
    while i < len(args):
        if endswith(args[i], ".sgvm"):
            input_file = args[i]
        elif args[i] == "--trace":
            trace = true
        i = i + 1
    if input_file == "":
        print "Usage: sgvm <file.sgvm> [--trace]"
        return
    var data = io.readbytes(input_file)
    if data == nil:
        print "Error: Could not read file"
        return
    var off = 0
    let core_utils = SGVMUtils()
    if len(data) > 2 and core_utils.my_int(data[0]) == 35 and core_utils.my_int(data[1]) == 33:
        while off < len(data) and core_utils.my_int(data[off]) != 10:
            off = off + 1
        if off < len(data):
            off = off + 1
    if len(data) - off < 4 or core_utils.my_int(data[off]) != 83 or core_utils.my_int(data[off+1]) != 71 or core_utils.my_int(data[off+2]) != 86 or core_utils.my_int(data[off+3]) != 77:
        print "Error: Invalid SGVM header"
        return
    var metal_vm = MetalVM()
    metal_vm.trace = trace
    off = off + 6
    var function_count = core_utils.my_int(core_utils.read_be16(data, off))
    off = off + 2
    var const_count = core_utils.my_int(core_utils.read_be16(data, off))
    off = off + 2
    var j = 0
    while j < const_count:
        var t = data[off]
        off = off + 1
        if t == 1:
            push(metal_vm.constants, core_utils.unpack_double(data, off))
            off = off + 8
        elif t == 3:
            var slen = core_utils.my_int(core_utils.read_be16(data, off))
            off = off + 2
            var s = ""
            var k = 0
            while k < slen:
                s = s + chr(core_utils.my_int(data[off + k]))
                k = k + 1
            push(metal_vm.constants, s)
            off = off + slen
        j = j + 1
    var chunk_count = core_utils.my_int(core_utils.read_be32(data, off))
    off = off + 4
    var c = 0
    while c < chunk_count:
        var clen = core_utils.my_int(core_utils.read_be32(data, off))
        off = off + 4
        var chunk_code = []
        var k = 0
        while k < clen:
            push(chunk_code, data[off + k])
            k = k + 1
        push(metal_vm.chunks, chunk_code)
        off = off + clen
        c = c + 1
    var idx = function_count
    while idx < len(metal_vm.chunks):
        metal_vm.run(metal_vm.chunks[idx])
        idx = idx + 1

main()
