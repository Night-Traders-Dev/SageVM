# Sage RISC-V Virtual Machine (SRVM)
# Core Interpreter Implementation (RV64I)

import srvm_core
from srvm_core import RVInstruction

class SageVMState:
    proc init(self):
        # 32 x 64-bit registers
        self.x = []
        var i = 0
        while i < 32:
            push(self.x, 0)
            i = i + 1
            
        self.pc = 0
        self.running = true
        
        # Memory segments
        self.bytecode = []
        self.constants = []
        self.stack = [] # 1MB stack (simplified for now)
        i = 0
        while i < 1000: # Smaller stack for now
            push(self.stack, 0)
            i = i + 1
        
        self.heap = {} # Simple object heap for now
        
        # Register x2 is typically stack pointer (sp)
        self.x[2] = len(self.stack)

class SRVM:
    proc init(self):
        self.state = SageVMState()
        self.trace = false

    proc run(self, bytecode):
        self.state.bytecode = bytecode
        self.state.pc = 0
        self.state.running = true
        
        while self.state.running and self.state.pc < len(bytecode):
            # Fetch
            if self.state.pc + 4 > len(bytecode):
                break
            
            # Instructions are 32-bit LE in RISC-V normally, but let's decide
            # Let's use 32-bit big-endian for consistency with existing SGVM if we want,
            # but RV standard is LE. I'll use LE.
            let b0 = bytecode[self.state.pc]
            let b1 = bytecode[self.state.pc+1]
            let b2 = bytecode[self.state.pc+2]
            let b3 = bytecode[self.state.pc+3]
            let raw_instr = int(b0) | (int(b1) << 8) | (int(b2) << 16) | (int(b3) << 24)
            
            let instr = RVInstruction(raw_instr)
            
            if self.trace:
                print "PC: " + str(self.state.pc) + " Op: " + str(instr.opcode) + " rd: " + str(instr.rd)
            
            self.execute(instr)
            
            # x0 is hardwired to zero
            self.state.x[0] = 0

    proc execute(self, instr):
        let op = instr.opcode
        
        if op == srvm_core.OP_LUI:
            self.state.x[instr.rd] = instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == srvm_core.OP_AUIPC:
            self.state.x[instr.rd] = self.state.pc + instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == srvm_core.OP_JAL:
            self.state.x[instr.rd] = self.state.pc + 4
            self.state.pc = self.state.pc + instr.imm_j
        elif op == srvm_core.OP_JALR:
            let target = (self.state.x[instr.rs1] + instr.imm_i) & ~1
            self.state.x[instr.rd] = self.state.pc + 4
            self.state.pc = target
        elif op == srvm_core.OP_BRANCH:
            self.handle_branch(instr)
        elif op == srvm_core.OP_IMM:
            self.handle_imm(instr)
        elif op == srvm_core.OP_REG:
            self.handle_reg(instr)
        elif op == srvm_core.OP_VMSYS:
            self.handle_vmsys(instr)
        else:
            print "Unknown opcode: " + str(op)
            self.state.running = false

    proc handle_branch(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let rs2_val = self.state.x[instr.rs2]
        var take = false
        
        let f3 = instr.funct3
        if f3 == srvm_core.F3_BEQ: take = (rs1_val == rs2_val)
        elif f3 == srvm_core.F3_BNE: take = (rs1_val != rs2_val)
        elif f3 == srvm_core.F3_BLT: take = (rs1_val < rs2_val)
        elif f3 == srvm_core.F3_BGE: take = (rs1_val >= rs2_val)
        
        if take:
            self.state.pc = self.state.pc + instr.imm_b
        else:
            self.state.pc = self.state.pc + 4

    proc handle_imm(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let imm = instr.imm_i
        let f3 = instr.funct3
        
        if f3 == srvm_core.F3_ADDI: self.state.x[instr.rd] = rs1_val + imm
        elif f3 == srvm_core.F3_XORI: self.state.x[instr.rd] = rs1_val ^ imm
        elif f3 == srvm_core.F3_ORI: self.state.x[instr.rd] = rs1_val | imm
        elif f3 == srvm_core.F3_ANDI: self.state.x[instr.rd] = rs1_val & imm
        
        self.state.pc = self.state.pc + 4

    proc handle_reg(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let rs2_val = self.state.x[instr.rs2]
        let f3 = instr.funct3
        let f7 = instr.funct7
        
        if f3 == srvm_core.F3_ADD:
            if f7 == 0x00: self.state.x[instr.rd] = rs1_val + rs2_val
            elif f7 == 0x20: self.state.x[instr.rd] = rs1_val - rs2_val
        elif f3 == srvm_core.F3_XOR: self.state.x[instr.rd] = rs1_val ^ rs2_val
        elif f3 == srvm_core.F3_OR: self.state.x[instr.rd] = rs1_val | rs2_val
        elif f3 == srvm_core.F3_AND: self.state.x[instr.rd] = rs1_val & rs2_val
        
        self.state.pc = self.state.pc + 4

    proc handle_vmsys(self, instr):
        if instr.funct3 == srvm_core.F3_VM_OPS:
            if instr.funct7 == srvm_core.VMO_HALT:
                self.state.running = false
            elif instr.funct7 == srvm_core.VMO_PRINT:
                print str(self.state.x[instr.rs1])
        
        self.state.pc = self.state.pc + 4
