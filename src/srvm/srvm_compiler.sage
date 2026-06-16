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
                
            elif op == sgvm_core.OP_JUMP_IF_FALSE:
                let target_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let cond = pop(self.reg_stack)
                let patch_pc = len(self.output_bytes)
                # BEQ rs1, x0, offset
                self.emit_32(self.encoder.encode_b(srvm_core.OP_BRANCH, srvm_core.F3_BEQ, cond, 0, 0)) # Placeholder
                push(self.jump_patches, [patch_pc, target_ip])

            elif op == sgvm_core.OP_RETURN:
                # JALR x0, 0(x1) -- Return using ra
                self.emit_32(self.encoder.encode_i(srvm_core.OP_JALR, 0, 0, 1, 0))

            elif op == sgvm_core.OP_DEFINE_FUNCTION:
                let chunk_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                # 1. Load chunk index into temp register
                let ri = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(srvm_core.OP_IMM, srvm_core.F3_ADDI, ri, 0, chunk_idx))
                # 2. VMSYS OBJ_NEW_FUNC rd, ri
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_OBJ_OPS, srvm_core.OBJ_NEW_FUNC, rd, ri, 0))
                push(self.reg_stack, rd)

            elif op == sgvm_core.OP_CALL:
                let argc = int(svm_bytecode[i])
                i = i + 1
                # Arguments are on the virtual register stack
                # RISC-V convention: arguments in a0-a7 (x10-x17)
                var args = []
                var j = 0
                while j < argc:
                    push(args, pop(self.reg_stack))
                    j = j + 1
                
                # Reverse args to move to correct registers
                # (Last pushed is last arg in SVM, so pop gives last arg first)
                j = argc - 1
                while j >= 0:
                    let src = args[argc - 1 - j]
                    let dest = 10 + j # x10 + j
                    if src != dest:
                        # ADDI dest, src, 0 (Move)
                        self.emit_32(self.encoder.encode_i(srvm_core.OP_IMM, srvm_core.F3_ADDI, dest, src, 0))
                    j = j - 1
                
                # Function object is now at the top of reg_stack
                let func_reg = pop(self.reg_stack)
                # VMSYS VMO_CALL, func_reg
                self.emit_32(self.encoder.encode_r(srvm_core.OP_VMSYS, srvm_core.F3_VM_OPS, srvm_core.VMO_CALL, 0, func_reg, 0))
                
                # Result in a0 (x10)
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(srvm_core.OP_IMM, srvm_core.F3_ADDI, rd, 10, 0))
                push(self.reg_stack, rd)

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
                
                # Check instruction type at patch_pc to use correct encoder
                let b0 = self.output_bytes[patch_pc]
                let opcode = b0 & 0x7F
                
                var instr = 0
                if opcode == srvm_core.OP_JAL:
                    instr = self.encoder.encode_j(srvm_core.OP_JAL, 0, offset)
                elif opcode == srvm_core.OP_BRANCH:
                    # Need to extract rs1, rs2, and f3 from existing (partially encoded) instruction
                    # rs2 is typically 0 (x0) for JUMP_IF_FALSE
                    # Let's simplify and re-encode BEQ
                    # (In a better design, we'd store instruction metadata in jump_patches)
                    let raw = int(self.output_bytes[patch_pc]) | (int(self.output_bytes[patch_pc+1]) << 8) | (int(self.output_bytes[patch_pc+2]) << 16) | (int(self.output_bytes[patch_pc+3]) << 24)
                    let rs1 = (raw >> 15) & 0x1F
                    let rs2 = (raw >> 20) & 0x1F
                    let f3 = (raw >> 12) & 0x07
                    instr = self.encoder.encode_b(srvm_core.OP_BRANCH, f3, rs1, rs2, offset)
                
                if instr != 0:
                    self.patch_32(patch_pc, instr)
            p = p + 1
            
        return self.output_bytes
