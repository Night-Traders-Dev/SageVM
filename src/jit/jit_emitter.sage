# SageVM RISC-V Code Emitter (JIT)
# Generates native RISC-V instructions for JIT compilation

import jit_memory
import srvm_core
from srvm_core import RVEncoder, OP_REG, OP_IMM, OP_LUI, OP_LOAD, OP_STORE, OP_BRANCH, OP_VMSYS
from srvm_core import F3_ADD, F3_XOR, F3_OR, F3_ADDI, F3_LD, F3_SD, F3_BEQ, F3_BNE, F3_VM_OPS

class CodeEmitter:
    proc init(self, mem_manager):
        self.mem_manager = mem_manager
        self.encoder = RVEncoder()
        self.offset = 0

    proc emit(self, instr):
        # Translate RV64I instruction word to executable memory bytes
        let bytes = [
            instr & 0xFF,
            (instr >> 8) & 0xFF,
            (instr >> 16) & 0xFF,
            (instr >> 24) & 0xFF
        ]
        self.mem_manager.write(self.offset, bytes)
        self.offset = self.offset + 4

    proc emit_add(self, rd, rs1, rs2):
        let instr = self.encoder.encode_r(OP_REG, F3_ADD, 0, rd, rs1, rs2)
        self.emit(instr)

    proc emit_sub(self, rd, rs1, rs2):
        let instr = self.encoder.encode_r(OP_REG, F3_ADD, 0x20, rd, rs1, rs2)
        self.emit(instr)

    proc emit_mul(self, rd, rs1, rs2):
        let instr = self.encoder.encode_r(OP_REG, F3_ADD, 0x01, rd, rs1, rs2)
        self.emit(instr)

    proc emit_addi(self, rd, rs1, imm):
        let instr = self.encoder.encode_i(OP_IMM, F3_ADDI, rd, rs1, imm)
        self.emit(instr)

    proc emit_lui(self, rd, imm):
        let instr = self.encoder.encode_u(OP_LUI, rd, imm)
        self.emit(instr)

    proc emit_load(self, rd, rs1, imm):
        let instr = self.encoder.encode_i(OP_LOAD, F3_LD, rd, rs1, imm)
        self.emit(instr)

    proc emit_store(self, rs1, rs2, imm):
        let instr = self.encoder.encode_s(OP_STORE, F3_SD, rs1, rs2, imm)
        self.emit(instr)

    proc emit_branch(self, f3, rs1, rs2, offset):
        let instr = self.encoder.encode_b(OP_BRANCH, f3, rs1, rs2, offset)
        self.emit(instr)

    proc emit_vmsys(self, f3, f7, rd, op_type, rs1):
        let instr = self.encoder.encode_r(OP_VMSYS, f3, f7, rd, op_type, rs1)
        self.emit(instr)
