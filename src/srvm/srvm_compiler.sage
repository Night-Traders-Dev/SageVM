# Sage SVM to SRVM (RISC-V) Translator
# Translates stack-based bytecode to register-based bytecode

import sgvm_core
import srvm_core
from srvm_core import RVEncoder

class StackToRiscVTranslator:
    proc init(self):
        self.encoder = RVEncoder()
        self.reg_stack = []
        self.next_reg = 10 # Start from a0 (x10)
        self.output_bytes = []

    proc emit_32(self, val):
        # Little-endian 32-bit
        push(self.output_bytes, val & 0xFF)
        push(self.output_bytes, (val >> 8) & 0xFF)
        push(self.output_bytes, (val >> 16) & 0xFF)
        push(self.output_bytes, (val >> 24) & 0xFF)

    proc alloc_reg(self):
        let r = self.next_reg
        self.next_reg = self.next_reg + 1
        if self.next_reg > 17: # a7
            self.next_reg = 10 # Wrap around for simple demo (spilling not implemented yet)
        return r

    proc translate(self, svm_bytecode):
        # Simple linear translation
        var i = 0
        while i < len(svm_bytecode):
            let op = svm_bytecode[i]
            i = i + 1
            
            if op == sgvm_core.OP_CONSTANT:
                # OP_CONSTANT index (2 bytes BE)
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                
                let rd = self.alloc_reg()
                # For now, let's use a custom pseudo-op or sequence
                # LUI + ADDI to load an address or value
                # Since we don't have the constant pool resolved yet, let's use LUI rd, idx
                # (This is just a placeholder for now)
                self.emit_32(self.encoder.encode_u(srvm_core.OP_LUI, rd, idx << 12))
                push(self.reg_stack, rd)
                
            elif op == sgvm_core.OP_ADD:
                let rs2 = pop(self.reg_stack)
                let rs1 = pop(self.reg_stack)
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(srvm_core.OP_REG, srvm_core.F3_ADD, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)
                
            elif op == sgvm_core.OP_PRINT:
                let rs1 = pop(self.reg_stack)
                # VMSYS VMO_PRINT, rs1
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_VM_OPS, srvm_core.VMO_PRINT, 0, rs1, 0))
                
            elif op == sgvm_core.OP_HALT:
                # VMSYS VMO_HALT
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_VM_OPS, srvm_core.VMO_HALT, 0, 0, 0))
                
            # ... handle more opcodes
            
        return self.output_bytes
