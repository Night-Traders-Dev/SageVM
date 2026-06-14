import sys
import io
from sgvm_core import SGVMUtils

# The Full .sgvm to .sage Disassembler

class SGVMDisassembler:
    proc init(self, path):
        self.path = path
        self.ut = SGVMUtils()
        self.data = io.readbytes(path)
        self.pos = 0
        self.consts = []
        self.chunks = []
        self.opcode_map = {
            "0": "constant", "4": "pop()", "5": "get_global()", "6": "define_global()",
            "8": "define_function()", "15": " + ", "16": " - ", "17": " * ", "18": " / ",
            "35": "jump()", "36": "if not", "37": "call()", "38": "call_method()",
            "42": "print()", "44": "return", "52": "import()", "56": "setup_try()", "58": "raise()"
        }

    proc disassemble(self):
        if self.data == nil: return nil
        
        # Skip shebang
        if len(self.data) > 0 and self.ut.my_int(self.data[0]) == 35:
            while self.pos < len(self.data) and self.ut.my_int(self.data[self.pos]) != 10:
                self.pos = self.pos + 1
            if self.pos < len(self.data):
                self.pos = self.pos + 1

        # Magic and Header (8 bytes)
        self.pos = self.pos + 8 
        # Read const count (BE16)
        let const_count = self.ut.read_be16(self.data, self.pos)
        self.pos = self.pos + 2
        # Skip constants
        for ci in range(const_count):
            let ctype = self.ut.my_int(self.data[self.pos])
            self.pos = self.pos + 1
            if ctype == 1: self.pos = self.pos + 8
            elif ctype == 3:
                let slen = self.ut.read_be16(self.data, self.pos)
                self.pos = self.pos + 2 + slen
        
        # Parse chunks
        let chunk_total = self.ut.read_be32(self.data, self.pos)
        self.pos = self.pos + 4
        for chunk_idx in range(chunk_total):
            let chunk_len = self.ut.read_be32(self.data, self.pos)
            self.pos = self.pos + 4
            let end_pos = self.pos + chunk_len
            let instructions = []
            while self.pos < end_pos:
                let op = self.ut.my_int(self.data[self.pos])
                self.pos = self.pos + 1
                push(instructions, {"op": op})
            push(self.chunks, instructions)
        
        return self.generate_sage()

    proc generate_sage(self):
        var code = "# Disassembled from .sgvm\n\n"
        for chunk in self.chunks:
            for instr in chunk:
                let op = instr["op"]
                let key = str(op)
                if dict_has(self.opcode_map, key):
                    code = code + self.opcode_map[key] + "\n"
                else:
                    code = code + "// Unknown opcode: " + str(op) + "\n"

        return code

proc main():
    let args = sys.args()
    if len(args) < 2: return
    let dis = SGVMDisassembler()
    dis.init(args[1])
    let code = dis.disassemble()
    if code != nil: print code

main()
