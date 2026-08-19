from sgvm_core import OP_CONSTANT, OP_GET_GLOBAL, OP_DEFINE_GLOBAL, OP_SET_GLOBAL, OP_DEFINE_FUNCTION, OP_GET_PROPERTY, OP_SET_PROPERTY, OP_LOAD_FUNCTION, OP_JUMP, OP_JUMP_IF_FALSE, OP_ARRAY, OP_TUPLE, OP_DICT, OP_EXEC_AST_STMT, OP_BREAK, OP_CONTINUE, OP_LOOP_BACK, OP_IMPORT, OP_CLASS, OP_METHOD, OP_SETUP_TRY, OP_CALL_METHOD, OP_CALL, OP_DUP, OP_MATH_PRINTM, OP_YIELD, OP_CREATE_GENERATOR, OP_GENERATOR_NEXT, OP_GET_LOCAL, OP_SET_LOCAL
from srvm_core import OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_BRANCH, OP_LOAD, OP_STORE, OP_IMM, OP_REG, OP_LDC, OP_VMSYS
from srvm_core import F3_ADDI, F3_SLTI, F3_SLTIU, F3_XORI, F3_ORI, F3_ANDI, F3_SLLI, F3_SRLI, F3_ADD, F3_SLL, F3_SLT, F3_SLTU, F3_XOR, F3_SRL, F3_OR, F3_AND, F3_VM_OPS, F3_GPU_OPS, F3_OBJ_OPS, F3_LD, F3_SD, F3_BEQ, F3_BNE
from srvm_core import VMO_NOP, VMO_HALT, VMO_PUSH_ENV, VMO_POP_ENV, VMO_CALL, VMO_SETUP_TRY, VMO_END_TRY, VMO_RAISE, VMO_IMPORT, VMO_PRINT, VMO_ARRAY_LEN, VMO_PRINTM, VMO_EXEC_AST, VMO_CMP_BINARY, VMO_NIL, VMO_TRUE, VMO_FALSE, VMO_NOT, VMO_TRUTHY, CMP_EQ, CMP_NEQ, CMP_LT, CMP_GT, CMP_LE, CMP_GE
from srvm_core import OBJ_GET_GLOBAL, OBJ_SET_GLOBAL, OBJ_NEW_CLASS, OBJ_INHERIT, OBJ_METHOD_BIND, OBJ_GET_PROP, OBJ_SET_PROP, OBJ_NEW_FUNC, OBJ_ARRAY_NEW, OBJ_DICT_NEW, OBJ_TUPLE_NEW, OBJ_GET_INDEX, OBJ_SET_INDEX, SRVMUtils, RVEncoder
# Sage SVM to SRVM (RISC-V) Translator
# Translates stack-based bytecode to register-based bytecode

import sgvm_core
import srvm_core
from srvm_core import RVEncoder
import srvm_profiler
from srvm_profiler import TypeProfiler, TYPE_INT

class StackToRiscVTranslator:
    proc init(self, constants):
        self.encoder = RVEncoder()
        self.profiler = TypeProfiler(constants)
        self.reg_stack = []
        self.next_reg = 11 # Start from a1 (x11), reserving x10 for VMSYS args
        self.spill_slots = [] # Track spilled registers
        self.spill_offset = 0 # Next available spill slot
        self.output_bytes = []
        self.label_map = {} # SVM IP -> SRVM PC
        self.jump_patches = [] # (SRVM PC to patch, target SVM IP)
        self.debug = false

    proc emit_32(self, val):
        push(self.output_bytes, val & 0xFF)
        push(self.output_bytes, (val >> 8) & 0xFF)
        push(self.output_bytes, (val >> 16) & 0xFF)
        push(self.output_bytes, (val >> 24) & 0xFF)

    proc emit_load_imm(self, rd, val):
        var v = int(val)
        if v >= -2048 and v <= 2047:
            self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 0, v))
        else:
            var hi = int((v + 2048) / 4096)
            var lo = v - (hi * 4096)
            self.emit_32(self.encoder.encode_u(OP_LUI, rd, hi * 4096))
            self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, rd, lo))

    proc patch_32(self, pc, val):
        self.output_bytes[pc] = val & 0xFF
        self.output_bytes[pc+1] = (val >> 8) & 0xFF
        self.output_bytes[pc+2] = (val >> 16) & 0xFF
        self.output_bytes[pc+3] = (val >> 24) & 0xFF

    
    proc pop_reg(self):
        if self.reg_stack == nil or len(self.reg_stack) == 0:
            return 13
        return pop(self.reg_stack)

    proc alloc_reg(self):
        let r = self.next_reg
        self.next_reg = self.next_reg + 1
        if self.next_reg > 27:
            let spill_reg = 13
            let slot = self.spill_offset
            self.spill_offset = self.spill_offset + 1
            self.emit_32(self.encoder.encode_s(OP_STORE, F3_SD, 2, spill_reg, slot * 8))
            push(self.spill_slots, slot)
            self.next_reg = 13
            return spill_reg
        return r

    proc translate(self, svm_bytecode):
        # Speculative type analysis
        let speculative_types = self.profiler.analyze(svm_bytecode)
        
        self.output_bytes = []
        self.reg_stack = []
        self.next_reg = 13
        self.spill_slots = []
        self.spill_offset = 0
        self.label_map = {}
        self.jump_patches = []
        
        # Pre-scan for catch labels
        var catch_labels = {}
        var j = 0
        while j < len(svm_bytecode):
            let op = int(svm_bytecode[j])
            j = j + 1
            if op == OP_DEFINE_FUNCTION:
                j = j + 4
            elif op == OP_CALL_METHOD:
                j = j + 3
            elif op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_SET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_METHOD or op == OP_ARRAY or op == OP_TUPLE or op == OP_DICT or op == OP_LOOP_BACK or op == OP_IMPORT or op == OP_SETUP_TRY or op == OP_LOAD_FUNCTION or op == OP_CLASS or op == OP_GET_LOCAL or op == OP_SET_LOCAL or op == OP_EXEC_AST_STMT:
                if op == OP_SETUP_TRY:
                    let target = (int(svm_bytecode[j]) << 8) | int(svm_bytecode[j+1])
                    catch_labels[str(target)] = true
                j = j + 2
            elif op == OP_CALL or op == OP_DUP:
                j = j + 1
        
        var i = 0
        while i < len(svm_bytecode):
            let ip = i
            
            # If this is a catch block start, the VM will have pushed the exception object
            if dict_has(catch_labels, str(ip)):
                self.reg_stack = [10] # Exception is in a0 (x10)
                self.next_reg = 11
            
            self.label_map[str(ip)] = len(self.output_bytes)
            let op = int(svm_bytecode[i])
            if self.debug: print "DEBUG translate op=" + str(op) + " i=" + str(i)
            i = i + 1
            
            if op == OP_CONSTANT:
                if self.debug: print "DEBUG OP_CONSTANT step 1 i=" + str(i)
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                if self.debug: print "DEBUG OP_CONSTANT step 2 idx=" + str(idx)
                i = i + 2
                let rd = self.alloc_reg()
                if self.debug: print "DEBUG OP_CONSTANT step 3 rd=" + str(rd)
                let u_val = self.encoder.encode_u(OP_LDC, rd, idx << 12)
                if self.debug: print "DEBUG OP_CONSTANT step 4 u_val=" + str(u_val)
                self.emit_32(u_val)
                if self.debug: print "DEBUG OP_CONSTANT step 5"
                push(self.reg_stack, rd)
                
            elif op == OP_ADD:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                
                # Check speculative type
                # Simple lookup: use current instruction index to get speculative type
                let t = speculative_types[i-1] 
                if t == TYPE_INT:
                    # Emit integer specialized ADD
                    self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0, rd, rs1, rs2))
                else:
                    # Emit generic/fallback ADD
                    self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0, rd, rs1, rs2))
                
                push(self.reg_stack, rd)

            elif op == OP_SUB:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0x20, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_MUL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_ADD, 0x01, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_DIV:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_XOR, 0x01, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_MOD:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_OR, 0x01, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_AND:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_AND, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_OR:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_OR, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_XOR:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_XOR, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_BIT_NOT:
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_XORI, rd, rs1, -1))
                push(self.reg_stack, rd)

            elif op == OP_SHIFT_LEFT:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_SLL, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_SHIFT_RIGHT:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_REG, F3_SRL, 0, rd, rs1, rs2))
                push(self.reg_stack, rd)

            elif op == OP_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                # ADDI x10, rs1, 0  -> a0 = rs1
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                # ADDI x11, rs2, 0  -> a1 = rs2
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                # VMO_CMP_BINARY with funct7=CMP_EQ
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_EQ, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_NOT_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_NEQ, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_LESS:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_LT, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_GREATER:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_GT, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_GREATER_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_GE, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_LESS_EQUAL:
                let rs2 = self.pop_reg()
                let rs1 = self.pop_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, rs2, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, CMP_LE, 0, VMO_CMP_BINARY, 0))
                push(self.reg_stack, 10)

            elif op == OP_GET_INDEX:
                let idx = self.pop_reg()
                let obj = self.pop_reg()
                let rd = self.alloc_reg()
                var obj_reg = obj
                if obj == 10 or obj == 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                if idx != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, idx, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_GET_INDEX, obj_reg))
                push(self.reg_stack, rd)

            elif op == OP_SET_INDEX:
                let val = self.pop_reg()
                let idx = self.pop_reg()
                let obj = self.pop_reg()
                var obj_reg = obj
                if obj == 10 or obj == 11 or obj == 6 or obj == 7:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                if idx != 6:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 6, idx, 0))
                if val != 7:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 7, val, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 6, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, 7, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_INDEX, obj_reg))

            elif op == OP_ARRAY:
                let size = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                var arr_reg = rd
                if rd == 10 or rd == 11 or rd == 6 or rd == 7:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, rd, 0))
                    arr_reg = 5
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, size))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, arr_reg, OBJ_ARRAY_NEW, 0))
                var k = 0
                while k < size:
                    let elem = self.pop_reg()
                    if elem != 7:
                        self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 7, elem, 0))
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, size - 1 - k))
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, 7, 0))
                    self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_INDEX, arr_reg))
                    k = k + 1
                if arr_reg != rd:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, arr_reg, 0))
                push(self.reg_stack, rd)

            elif op == OP_DICT:
                let entry_count = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                var dict_reg = rd
                if rd == 10 or rd == 11 or rd == 6 or rd == 7:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, rd, 0))
                    dict_reg = 5
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, entry_count))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, dict_reg, OBJ_DICT_NEW, 0))
                var k = 0
                while k < entry_count:
                    let val = self.pop_reg()
                    let key = self.pop_reg()
                    if key != 6:
                        self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 6, key, 0))
                    if val != 7:
                        self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 7, val, 0))
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 6, 0))
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, 7, 0))
                    self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_INDEX, dict_reg))
                    k = k + 1
                if dict_reg != rd:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, dict_reg, 0))
                push(self.reg_stack, rd)

            elif op == OP_TUPLE:
                let size = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                var tuple_reg = rd
                if rd == 10 or rd == 11 or rd == 6 or rd == 7:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, rd, 0))
                    tuple_reg = 5
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, size))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, tuple_reg, OBJ_TUPLE_NEW, 0))
                var k = 0
                while k < size:
                    let elem = self.pop_reg()
                    if elem != 7:
                        self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 7, elem, 0))
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, size - 1 - k))
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, 7, 0))
                    self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_INDEX, tuple_reg))
                    k = k + 1
                if tuple_reg != rd:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, tuple_reg, 0))
                push(self.reg_stack, rd)

            elif op == OP_JUMP:
                let target_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_j(OP_JAL, 0, 0)) 
                push(self.jump_patches, [patch_pc, target_ip])
                
            elif op == OP_GET_PROPERTY:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let obj = self.pop_reg()
                let rd = self.alloc_reg()
                var obj_reg = obj
                if obj == 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                self.emit_load_imm(10, name_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_GET_PROP, obj_reg))
                push(self.reg_stack, rd)

            elif op == OP_SET_PROPERTY:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = self.pop_reg()
                let obj = self.pop_reg()
                var obj_reg = obj
                if obj == 10 or obj == 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, obj, 0))
                    obj_reg = 5
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                self.emit_load_imm(10, name_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_PROP, obj_reg))

            elif op == OP_POP:
                if len(self.reg_stack) > 0:
                    self.pop_reg()

            elif op == OP_DUP:
                let distance = int(svm_bytecode[i])
                i = i + 1
                if len(self.reg_stack) > distance:
                    let rs = self.reg_stack[len(self.reg_stack)-1-distance]
                    let rd = self.alloc_reg()
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, rs, 0))
                    push(self.reg_stack, rd)

            elif op == OP_CLASS:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_NEW_CLASS, 0))
                push(self.reg_stack, rd)

            elif op == OP_INHERIT:
                let parent = self.pop_reg()
                let child = self.pop_reg()
                var child_reg = child
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, child, 0))
                child_reg = rd
                if parent != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, parent, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_INHERIT, child_reg))
                push(self.reg_stack, rd)

            elif op == OP_METHOD:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let func = self.pop_reg()
                let klass = self.pop_reg()
                var klass_reg = klass
                if klass == 10 or klass == 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, klass, 0))
                    klass_reg = 5
                if func != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, func, 0))
                self.emit_load_imm(10, name_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_METHOD_BIND, klass_reg))

            elif op == OP_DEFINE_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_GLOBAL, 0))

            elif op == OP_NIL:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_NIL, 0)) 
                push(self.reg_stack, rd)

            elif op == OP_TRUE:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_TRUE, 0))
                push(self.reg_stack, rd)

            elif op == OP_FALSE:
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_FALSE, 0))
                push(self.reg_stack, rd)

            elif op == OP_NOT:
                let rs = self.pop_reg()
                let rd = self.alloc_reg()
                if rs != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_NOT, 0))
                push(self.reg_stack, rd)

            elif op == OP_TRUTHY:
                let rs = self.pop_reg()
                let rd = self.alloc_reg()
                if rs != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_TRUTHY, 0))
                push(self.reg_stack, rd)

            elif op == OP_GET_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_GET_GLOBAL, 0))
                push(self.reg_stack, rd)

            elif op == OP_SET_GLOBAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let val = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_GLOBAL, 0))
            
            elif op == OP_IMPORT:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, rd, VMO_IMPORT, 0))
                push(self.reg_stack, rd)

            elif op == OP_GET_LOCAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_LOAD, F3_LD, rd, 8, idx * 8))
                push(self.reg_stack, rd)

            elif op == OP_SET_LOCAL:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rs = self.pop_reg()
                self.emit_32(self.encoder.encode_s(OP_STORE, F3_SD, 8, rs, idx * 8))
                
            elif op == OP_SETUP_TRY:
                let catch_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_i(OP_VMSYS, F3_VM_OPS, 0, VMO_SETUP_TRY, 0)) 
                push(self.jump_patches, [patch_pc, catch_ip])

            elif op == OP_END_TRY:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_END_TRY, 0))

            elif op == OP_RAISE:
                let exc_obj = self.pop_reg()
                if exc_obj != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, exc_obj, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_RAISE, 0))

            elif op == OP_PUSH_ENV:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_PUSH_ENV, 0))

            elif op == OP_POP_ENV:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_POP_ENV, 0))

            elif op == OP_JUMP_IF_FALSE:
                let target_ip = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let cond = self.pop_reg()
                let patch_pc = len(self.output_bytes)
                self.emit_32(self.encoder.encode_b(OP_BRANCH, F3_BEQ, cond, 0, 0)) 
                push(self.jump_patches, [patch_pc, target_ip])

            elif op == OP_RETURN:
                self.emit_32(self.encoder.encode_i(OP_JALR, 0, 0, 1, 0))

            elif op == OP_DEFINE_FUNCTION:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let chunk_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, chunk_idx))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 11, OBJ_NEW_FUNC, 0))
                self.emit_load_imm(10, name_idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 0, OBJ_SET_GLOBAL, 0))

            elif op == OP_LOAD_FUNCTION:
                let chunk_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 0, chunk_idx))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, rd, OBJ_NEW_FUNC, 0))
                push(self.reg_stack, rd)

            elif op == OP_CALL:
                let argc = int(svm_bytecode[i])
                i = i + 1
                var args = []
                var k = 0
                while k < argc:
                    push(args, self.pop_reg())
                    k = k + 1
                # Preserve the callee in t0 (x5) BEFORE argument placement,
                # otherwise a callee allocated to x10 is clobbered when arg0
                # is moved into x10 (the a0 slot).
                let callee_reg = self.pop_reg()
                if callee_reg != 5:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 5, callee_reg, 0))
                k = argc - 1
                while k >= 0:
                    let src = args[argc - 1 - k]
                    let dest = 10 + k
                    if src != dest and src != 5:
                        self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, dest, src, 0))
                    k = k - 1
                # Call via t0 (x5), which holds the preserved callee.
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_CALL, 5))
                let rd = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd, 10, 0))
                push(self.reg_stack, rd)

            elif op == OP_CALL_METHOD:
                let name_idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                let argc = int(svm_bytecode[i+2])
                i = i + 3
                var args = []
                var k = 0
                while k < argc:
                    push(args, self.pop_reg())
                    k = k + 1
                let obj = self.pop_reg()
                
                # Move obj to x18
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 18, obj, 0))
                # Move args to x19..
                k = 0
                while k < argc:
                    let src = args[argc - 1 - k]
                    let dest = 19 + k
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, dest, src, 0))
                    k = k + 1
                
                # Load name_idx to x10
                self.emit_load_imm(10, name_idx)
                # Call OBJ_METHOD_BIND on obj (x18), target x29, setting x28 flag
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_OBJ_OPS, 0, 29, OBJ_METHOD_BIND, 18))
                
                # Branch if x28 == 0 (class call) to class_call block.
                # Offset is (argc + 4) * 4 bytes.
                self.emit_32(self.encoder.encode_b(OP_BRANCH, F3_BEQ, 28, 0, (argc + 4) * 4))
                
                # Instance call block:
                # Move obj (x18) to x10
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, 18, 0))
                # Move args (x19..) to x11..
                k = 0
                while k < argc:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11 + k, 19 + k, 0))
                    k = k + 1
                # Do call: VMO_CALL(x29)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_CALL, 29))
                # JUMP over class_call block.
                # Offset is (argc + 2) * 4 bytes.
                self.emit_32(self.encoder.encode_j(OP_JAL, 0, (argc + 2) * 4))
                
                # Class call block:
                # Move args (x19..) to x10..
                k = 0
                while k < argc:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10 + k, 19 + k, 0))
                    k = k + 1
                
                # Do call: VMO_CALL(x29)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_CALL, 29))
                # Get return value: rd = x10
                let rd_ret = self.alloc_reg()
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd_ret, 10, 0))
                push(self.reg_stack, rd_ret)

            elif op == OP_PRINT:
                let rs = self.pop_reg()
                if rs != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, rs, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_PRINT, 0))
                
            elif op == OP_EXEC_AST_STMT:
                let idx = (int(svm_bytecode[i]) << 8) | int(svm_bytecode[i+1])
                i = i + 2
                self.emit_load_imm(10, idx)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_EXEC_AST, 0))

            elif op == OP_HALT:
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_VM_OPS, 0, 0, VMO_HALT, 0))

            elif op == 59: # OP_GPU_POLL_EVENTS (halt)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 0, 0))

            elif op == 69: # OP_GPU_CMD_BEGIN_RP (get_trap)
                let rd2 = self.alloc_reg()
                let rd1 = self.alloc_reg()
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 1, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd1, 10, 0))
                self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, rd2, 11, 0))
                push(self.reg_stack, rd1)
                push(self.reg_stack, rd2)

            elif op == 70: # OP_GPU_CMD_END_RP (enable_interrupts)
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 2, 0))

            elif op == 71: # OP_GPU_CMD_DRAW (set_timer)
                let arg4 = self.pop_reg()
                let arg3 = self.pop_reg()
                let arg2 = self.pop_reg()
                let arg1 = self.pop_reg()
                if arg1 != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, arg1, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 3, 0))

            elif op == 62: # OP_GPU_KEY_PRESSED (peek64)
                let addr = self.pop_reg()
                let rd = self.alloc_reg()
                if addr != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, addr, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, rd, 4, 0))
                push(self.reg_stack, rd)

            elif op == 84: # OP_GPU_UPDATE_UNIFORM (poke64)
                let val = self.pop_reg()
                let addr = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                if addr != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, addr, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 5, 0))

            elif op == 85: # OP_GPU_CMD_PUSH_CONST (poke32)
                let arg4 = self.pop_reg()
                let arg3 = self.pop_reg()
                let val = self.pop_reg()
                let addr = self.pop_reg()
                if val != 11:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 11, val, 0))
                if addr != 10:
                    self.emit_32(self.encoder.encode_i(OP_IMM, F3_ADDI, 10, addr, 0))
                self.emit_32(self.encoder.encode_r(OP_VMSYS, F3_GPU_OPS, 0, 0, 6, 0))
        
        var p = 0
        while p < len(self.jump_patches):
            let patch = self.jump_patches[p]
            let patch_pc = patch[0]
            let target_ip = patch[1]
            if self.label_map[str(target_ip)] != nil:
                let target_pc = self.label_map[str(target_ip)]
                let offset = target_pc - patch_pc
                let b0 = int(self.output_bytes[patch_pc])
                let opcode = b0 & 0x7F
                var instr = 0
                if opcode == OP_JAL:
                    instr = self.encoder.encode_j(OP_JAL, 0, offset)
                elif opcode == OP_BRANCH:
                    let raw = int(self.output_bytes[patch_pc]) | (int(self.output_bytes[patch_pc+1]) << 8) | (int(self.output_bytes[patch_pc+2]) << 16) | (int(self.output_bytes[patch_pc+3]) << 24)
                    let rs1 = (raw >> 15) & 0x1F
                    let rs2 = (raw >> 20) & 0x1F
                    let f3 = (raw >> 12) & 0x07
                    instr = self.encoder.encode_b(OP_BRANCH, f3, rs1, rs2, offset)
                elif opcode == OP_VMSYS:
                    let raw = int(self.output_bytes[patch_pc]) | (int(self.output_bytes[patch_pc+1]) << 8) | (int(self.output_bytes[patch_pc+2]) << 16) | (int(self.output_bytes[patch_pc+3]) << 24)
                    let rd = (raw >> 7) & 0x1F
                    let sub_op = (raw >> 15) & 0x1F
                    let f3 = (raw >> 12) & 0x07
                    instr = self.encoder.encode_i(OP_VMSYS, f3, rd, sub_op, offset)
                if instr != 0:
                    self.patch_32(patch_pc, instr)
            p = p + 1
            
        return self.output_bytes

class SGRVCompiler:
    proc init(self):
        self.translator = StackToRiscVTranslator(nil)
        self.utils = SRVMUtils()
        self.debug = false

    proc compile(self, sgvm_data):
        if self.debug: print "DEBUG SGRV compile entry, len=" + str(len(sgvm_data))
        var pos = 0
        if len(sgvm_data) < 4: return nil
        if int(sgvm_data[0]) == 35:
            while pos < len(sgvm_data) and int(sgvm_data[pos]) != 10: pos = pos + 1
            if pos < len(sgvm_data): pos = pos + 1
        
        if int(sgvm_data[pos]) != 83 or int(sgvm_data[pos+1]) != 71 or int(sgvm_data[pos+2]) != 86 or int(sgvm_data[pos+3]) != 77:
            if self.debug: print "DEBUG SGRV magic mismatch!"
            return nil
        pos = pos + 4 + 2 # Skip magic and version
        
        let func_count = (int(sgvm_data[pos]) << 8) | int(sgvm_data[pos+1])
        pos = pos + 2
        let const_count = (int(sgvm_data[pos]) << 8) | int(sgvm_data[pos+1])
        pos = pos + 2
        if self.debug: print "DEBUG SGRV func_count=" + str(func_count) + " const_count=" + str(const_count)
        
        var constants = []
        
        var output = [83, 71, 82, 86, 0, 1]
        let fc_rem = int(func_count) % 256
        push(output, (int(func_count) - fc_rem) / 256)
        push(output, fc_rem)
        let cc_rem = int(const_count) % 256
        push(output, (int(const_count) - cc_rem) / 256)
        push(output, cc_rem)
        
        var ci = 0
        while ci < const_count:
            let t = int(sgvm_data[pos])
            push(output, t)
            pos = pos + 1
            if t == 1: # Number
                var val_bytes = []
                var k = 0
                while k < 8:
                    push(val_bytes, int(sgvm_data[pos + k]))
                    push(output, int(sgvm_data[pos + k]))
                    k = k + 1
                pos = pos + 8
                let numval = self.utils.unpack_double(val_bytes, 0)
                push(constants, {"type": 1, "num": numval})
            elif t == 3: # String
                let slen = (int(sgvm_data[pos]) << 8) | int(sgvm_data[pos+1])
                let slen_rem = int(slen) % 256
                push(output, (int(slen) - slen_rem) / 256)
                push(output, slen_rem)
                pos = pos + 2
                var s = ""
                var k = 0
                while k < slen:
                    let b = int(sgvm_data[pos + k])
                    push(output, b)
                    s = s + chr(b)
                    k = k + 1
                pos = pos + slen
                push(constants, {"type": 3, "str": s})
            else:
                push(constants, nil)
            ci = ci + 1
            
        # Initialize translator with constants
        self.translator = StackToRiscVTranslator(constants)
            
        let num_chunks = (int(sgvm_data[pos]) << 24) | (int(sgvm_data[pos+1]) << 16) | (int(sgvm_data[pos+2]) << 8) | int(sgvm_data[pos+3])
        pos = pos + 4
        
        var nc_val = int(num_chunks)
        let nc0 = nc_val % 256
        let nc1_v = (nc_val - nc0) / 256
        let nc1 = nc1_v % 256
        let nc2_v = (nc1_v - nc1) / 256
        let nc2 = nc2_v % 256
        let nc3 = (nc2_v - nc2) / 256
        push(output, nc3)
        push(output, nc2)
        push(output, nc1)
        push(output, nc0)
        
        var chunk_idx = 0
        while chunk_idx < num_chunks:
            if chunk_idx % 50 == 0:
                if self.debug: print "DEBUG SGRV compile chunk " + str(chunk_idx) + "/" + str(num_chunks)
            let clen = (int(sgvm_data[pos]) << 24) | (int(sgvm_data[pos+1]) << 16) | (int(sgvm_data[pos+2]) << 8) | int(sgvm_data[pos+3])
            pos = pos + 4
            var svm_bc = []
            var i = 0
            while i < clen:
                push(svm_bc, int(sgvm_data[pos + i]))
                i = i + 1
            pos = pos + clen
            let translated = self.translator.translate(svm_bc)
            let t_len = len(translated)
            
            var tl_val = int(t_len)
            let tl0 = tl_val % 256
            let tl1_v = (tl_val - tl0) / 256
            let tl1 = tl1_v % 256
            let tl2_v = (tl1_v - tl1) / 256
            let tl2 = tl2_v % 256
            let tl3 = (tl2_v - tl2) / 256
            push(output, tl3)
            push(output, tl2)
            push(output, tl1)
            push(output, tl0)
            i = 0
            while i < t_len:
                let b_val = translated[i]
                if b_val == nil or type(b_val) != "number":
                    if self.debug: print "DEBUG SGRVCompiler chunk_idx=" + str(chunk_idx) + " i=" + str(i) + " b_val=" + str(b_val) + " type=" + str(type(b_val))
                push(output, int(b_val))
                i = i + 1
            chunk_idx = chunk_idx + 1
        return output

    proc save(self, path, data, io_mod):
        io_mod.writebytes(path, data)
