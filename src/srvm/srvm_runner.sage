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
        
        # Simple loader for now: everything after header is bytecode
        # In a real implementation, we'd parse sections (.text, .rodata, etc.)
        var bytecode = []
        var i = 6 # Skip Magic (4) and Version (2)
        while i < len(data):
            push(bytecode, data[i])
            i = i + 1
            
        self.vm.run(bytecode)
        return true
