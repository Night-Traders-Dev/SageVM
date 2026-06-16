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
        self.label_map = {} # SVM IP -> SRVM PC
        self.jump_patches = [] # (SRVM PC to patch, target SVM IP)

    proc emit_32(self, val):
        push(self.output_bytes, val & 0xFF)
        push(self.output_bytes, (val >> 8) & 0xFF)
        push(self.output_bytes, (val >> 16) & 0xFF)
        push(self.output_bytes, (val >> 24) & 0xFF)

    proc patch_32(self, pc, val):
        self.output_bytes[pc] = val & 0xFF
        self.output_bytes[pc+1] = (val >> 8) & 0xFF
        self.output_bytes[pc+2] = (val >> 16) & 0xFF
        self.output_bytes[pc+3] = (val >> 24) & 0xFF

    proc alloc_reg(self):
        let r = self.next_reg
        self.next_reg = self.next_reg + 1
        if self.next_reg > 17:
            self.next_reg = 10
        return r

    proc translate(self, svm_bytecode):
        self.output_bytes = []
        self.reg_stack = []
        self.next_reg = 10
        self.label_map = {}
        self.jump_patches = []
        
        var i = 0
        while i < len(svm_bytecode):
            self.label_map[i] = len(self.output_bytes)
            let op = svm_bytecode[i]
            i = i + 1
            
            if op == sgvm_core.OP_CONSTANT:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                # Load constant using OP_LDC (U-type)
                self.emit_32(self.encoder.encode_u(srvm_core.OP_LDC, rd, idx << 12))
                push(self.reg_stack, rd)
                
            elif op == sgvm_core.OP_ADD:
                let rs2 = pop(self.reg_stack)
                let rs1 = pop(self.reg_stack)
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(srvm_core.OP_REG, srvm_core.F3_ADD, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == sgvm_core.OP_JUMP:
                let target_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_j(srvm_core.OP_JAL, 0, 0)) # Placeholder
                push(self.jump_patches, [patch_pc, target_ip])
                
            elif op == sgvm_core.OP_GET_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                # 1. Load index into temp register
                let ri = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(srvm_core.OP_IMM, srvm_core.F3_ADDI, ri, 0, idx))
                # 2. VMSYS OBJ_GET_GLOBAL rd, ri
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_OBJ_OPS, srvm_core.OBJ_GET_GLOBAL, rd, ri, 0))
                push(self.reg_stack, rd)

            elif op == sgvm_core.OP_SET_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = pop(self.reg_stack)
                # 1. Load index into temp register
                let ri = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(srvm_core.OP_IMM, srvm_core.F3_ADDI, ri, 0, idx))
                # 2. VMSYS OBJ_SET_GLOBAL ri, val
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_OBJ_OPS, srvm_core.OBJ_SET_GLOBAL, 0, ri, val))
                
            elif op == sgvm_core.OP_PRINT:
                let rs1 = pop(self.reg_stack)
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_VM_OPS, srvm_core.VMO_PRINT, 0, rs1, 0))
                
            elif op == sgvm_core.OP_HALT:
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_VM_OPS, srvm_core.VMO_HALT, 0, 0, 0))
        
        # Second pass: Patch jumps
        var p = 0
        while p < len(self.jump_patches):
            let patch = self.jump_patches[p]
            let patch_pc = patch[0]
            let target_ip = patch[1]
            if target_ip < len(svm_bytecode) and self.label_map[target_ip] != nil:
                let target_pc = self.label_map[target_ip]
                let offset = target_pc - patch_pc
                let instr = self.encoder.encode_j(srvm_core.OP_JAL, 0, offset)
                self.patch_32(patch_pc, instr)
            p = p + 1
            
        return self.output_bytes
