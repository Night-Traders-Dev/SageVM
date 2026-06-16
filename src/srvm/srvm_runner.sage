# Sage RISC-V (SRVM) Runner
# Loads and executes .sgrv binary files

import io
import srvm_vm
import srvm_core

class SRVMRunner:
    proc init(self):
        self.vm = srvm_vm.SRVM()

    proc run_file(self, input_file, debug=false):
        var data = io.readbytes(input_file)
        if data == nil:
            print "❌ Error: Could not read file: " + input_file
            return false
        
        if len(data) < 4 or int(data[0]) != 83 or int(data[1]) != 71 or int(data[2]) != 82 or int(data[3]) != 86:
            print "❌ Error: Invalid SGRV header in " + input_file
            return false
            
        self.vm.trace = debug
        var off = 6 # Magic (4) + Version (2)
        
        # Load Constants
        let const_count = (int(data[off]) << 8) | int(data[off+1])
        off = off + 2
        
        var j = 0
        while j < const_count:
            var t = data[off]
            off = off + 1
            if t == 1: # Number
                # For simplicity in prototype, we'll use a placeholder or read 8 bytes
                # Real implementation should use unpack_double
                off = off + 8
                push(self.vm.state.constants, 0.0)
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
            
        # Bytecode Length
        let bc_len = (int(data[off]) << 24) | (int(data[off+1]) << 16) | (int(data[off+2]) << 8) | int(data[off+3])
        off = off + 4
        
        var bytecode = []
        var i = 0
        while i < bc_len:
            push(bytecode, data[off + i])
            i = i + 1
            
        self.vm.run(bytecode)
        return true
