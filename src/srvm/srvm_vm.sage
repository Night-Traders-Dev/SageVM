from srvm_core import OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_BRANCH, OP_LOAD, OP_STORE, OP_IMM, OP_REG, OP_LDC, OP_VMSYS
from srvm_core import F3_ADDI, F3_SLTI, F3_SLTIU, F3_XORI, F3_ORI, F3_ANDI, F3_SLLI, F3_SRLI, F3_ADD, F3_SLL, F3_SLT, F3_SLTU, F3_XOR, F3_SRL, F3_OR, F3_AND, F3_VM_OPS, F3_GPU_OPS, F3_OBJ_OPS, F3_LD, F3_SD, F3_BEQ, F3_BNE
from srvm_core import VMO_NOP, VMO_HALT, VMO_PUSH_ENV, VMO_POP_ENV, VMO_CALL, VMO_SETUP_TRY, VMO_END_TRY, VMO_RAISE, VMO_IMPORT, VMO_PRINT, VMO_ARRAY_LEN, VMO_PRINTM, VMO_EXEC_AST, VMO_CMP_BINARY, VMO_NIL, VMO_TRUE, VMO_FALSE, VMO_NOT, VMO_TRUTHY, CMP_EQ, CMP_NEQ, CMP_LT, CMP_GT, CMP_LE, CMP_GE
from srvm_core import OBJ_GET_GLOBAL, OBJ_SET_GLOBAL, OBJ_NEW_CLASS, OBJ_INHERIT, OBJ_METHOD_BIND, OBJ_GET_PROP, OBJ_SET_PROP, OBJ_NEW_FUNC, OBJ_ARRAY_NEW, OBJ_DICT_NEW, OBJ_TUPLE_NEW, OBJ_GET_INDEX, OBJ_SET_INDEX, SRVMUtils
# Sage RISC-V Virtual Machine (SRVM)
# Core Interpreter Implementation (RV64I)

import srvm_core
from srvm_core import RVInstruction
import io
import math
import net
import thread as host_thread
import sys
import gpu
import ml_native
import jit_engine

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
        self.chunks = []
        self.current_chunk_idx = 0
        self.stack = [] 
        i = 0
        while i < 4096:
            push(self.stack, 0)
            i = i + 1
        self.max_stack_size = 65536
        
        self.heap = {} 
        self.call_stack = [] # Stack of [chunk_idx, pc, ra]
        self.try_stack = [] # Stack of [catch_pc, call_stack_depth]

        # Security: Limits to prevent Denial of Service (DoS) via resource exhaustion
        self.max_call_depth = 1024
        self.max_try_depth = 1024
        self.max_array_size = 1000000
        self.safe_mode = false
        self.ffi_enabled = true
        self.jit_enabled = false
        self.jit_engine = jit_engine.JITEngine()
        
        # Register x2 is typically stack pointer (sp)
        self.x[2] = len(self.stack)

class SRVM:
    proc init(self):
        self.state = SageVMState()
        self.trace = false

    proc is_truthy(self, val):
        if val == nil or val == false or val == 0 or val == "" or val == 0.0:
            return false
        return true

    proc safe_get_constant(self, idx):
        if idx >= 0 and idx < len(self.state.constants):
            return self.state.constants[idx]
        print "Error: Constant pool index out of bounds: " + str(idx) + " at PC=" + str(self.state.pc)
        self.state.running = false
        return nil

    proc safe_get_chunk(self, idx):
        if idx >= 0 and idx < len(self.state.chunks):
            return self.state.chunks[idx]
        print "Error: Chunk index out of bounds: " + str(idx)
        self.state.running = false
        return []

    proc is_protected(self, obj):
        # Security helper: Check if an object is a protected module or host bridge
        if not self.state.safe_mode:
            return false

        if type(obj) == "dict":
            if dict_has(obj, "__host_mod__") or (dict_has(obj, "__type__") and obj["__type__"] == "module") or dict_has(obj, "__builtin__"):
                return true
        elif type(obj) == "module":
            return true
        return false

    proc run(self, bytecode):
        # Initial chunk (0)
        self.state.bytecode = bytecode
        if len(self.state.chunks) == 0:
            push(self.state.chunks, bytecode)
        
        self.state.pc = 0
        self.state.running = true
        
        if self.state.jit_enabled:
            self.state.jit_engine.enabled = true
            let chunk_id = self.state.current_chunk_idx
            if self.state.jit_engine.record_and_check(chunk_id):
                if self.trace: print "⚡ [JIT] Compiling SRVM chunk " + str(chunk_id) + " to RISC-V JIT block"
                self.state.jit_engine.compile_srvm_chunk(chunk_id, bytecode, self.state.constants)
        
        while self.state.running and self.state.pc < len(self.state.bytecode):
            # Fetch
            if self.state.pc + 4 > len(self.state.bytecode):
                break
            
            let b0 = self.state.bytecode[self.state.pc]
            let b1 = self.state.bytecode[self.state.pc+1]
            let b2 = self.state.bytecode[self.state.pc+2]
            let b3 = self.state.bytecode[self.state.pc+3]
            let raw_instr = int(b0) | (int(b1) << 8) | (int(b2) << 16) | (int(b3) << 24)
            
            let instr = RVInstruction(raw_instr)
            
            if self.trace:
                print "PC: " + str(self.state.pc) + " Op: " + str(instr.opcode) + " rd: " + str(instr.rd)
            
            self.execute(instr)
            
            # x0 is hardwired to zero
            if instr.rd == 0:
                self.state.x[0] = 0

    proc execute(self, instr):
        let op = instr.opcode
        
        if op == OP_LUI:
            self.state.x[instr.rd] = instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == OP_AUIPC:
            self.state.x[instr.rd] = self.state.pc + instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == OP_JAL:
            self.state.x[instr.rd] = self.state.pc + 4
            self.state.pc = self.state.pc + instr.imm_j
        elif op == OP_JALR:
            let target = (self.state.x[instr.rs1] + instr.imm_i) & ~1
            let rd_val = self.state.pc + 4
            
            # Special case for return: JALR x0, 0(x1)
            if instr.rd == 0 and instr.rs1 == 1 and instr.imm_i == 0:
                if len(self.state.call_stack) > 0:
                    let frame = pop(self.state.call_stack)
                    self.state.current_chunk_idx = frame[0]
                    self.state.bytecode = self.state.chunks[self.state.current_chunk_idx]
                    self.state.pc = frame[1]
                    self.state.x[1] = frame[2]
                    return # Skip standard PC update
                else:
                    self.state.running = false
                    return

            self.state.x[instr.rd] = rd_val
            self.state.pc = target
        elif op == OP_BRANCH:
            self.handle_branch(instr)
        elif op == OP_IMM:
            self.handle_imm(instr)
        elif op == OP_REG:
            self.handle_reg(instr)
        elif op == OP_LUI:
            self.state.x[instr.rd] = instr.imm_u
            self.state.pc = self.state.pc + 4
        elif op == OP_LDC:
            self.handle_ldc(instr)
        elif op == OP_LOAD:
            self.handle_load(instr)
        elif op == OP_STORE:
            self.handle_store(instr)
        elif op == OP_VMSYS:
            self.handle_vmsys(instr)
        else:
            if self.trace:
                print "Unknown opcode: " + str(op)
            self.state.running = false

    proc handle_ldc(self, instr):
        let idx = (instr.raw >> 12) & 0xFFFFF
        self.state.x[instr.rd] = self.safe_get_constant(idx)
        self.state.pc = self.state.pc + 4

    proc handle_load(self, instr):
        let addr = self.state.x[instr.rs1] + instr.imm_i
        if addr >= len(self.state.stack) and addr < self.state.max_stack_size:
            while len(self.state.stack) <= addr:
                push(self.state.stack, 0)
        if addr >= 0 and addr < len(self.state.stack):
            self.state.x[instr.rd] = self.state.stack[addr]
        else:
            if self.trace:
                print "Load access violation at " + str(addr)
            self.state.running = false
        self.state.pc = self.state.pc + 4

    proc handle_store(self, instr):
        let addr = self.state.x[instr.rs1] + instr.imm_s
        let val = self.state.x[instr.rs2]
        if addr >= len(self.state.stack) and addr < self.state.max_stack_size:
            while len(self.state.stack) <= addr:
                push(self.state.stack, 0)
        if addr >= 0 and addr < len(self.state.stack):
            self.state.stack[addr] = val
        else:
            if self.trace:
                print "Store access violation at " + str(addr)
            self.state.running = false
        self.state.pc = self.state.pc + 4

    proc handle_branch(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let rs2_val = self.state.x[instr.rs2]
        var take = false
        let f3 = instr.funct3
        if f3 == F3_BEQ: take = (rs1_val == rs2_val)
        elif f3 == F3_BNE: take = (rs1_val != rs2_val)
        elif f3 == F3_BLT: take = (rs1_val < rs2_val)
        elif f3 == F3_BGE: take = (rs1_val >= rs2_val)
        elif f3 == F3_BLTU: take = (rs1_val < rs2_val) # TODO: unsigned comparison
        elif f3 == F3_BGEU: take = (rs1_val >= rs2_val) # TODO: unsigned comparison
        
        if take:
            self.state.pc = self.state.pc + instr.imm_b
        else:
            self.state.pc = self.state.pc + 4

    proc handle_imm(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let imm = instr.imm_i
        let f3 = instr.funct3
        if f3 == F3_ADDI:
            if imm == 0: self.state.x[instr.rd] = rs1_val
            else: self.state.x[instr.rd] = rs1_val + imm
        elif f3 == F3_SLTI:
            if rs1_val < imm: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_SLTIU:
            if rs1_val < imm: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_XORI: self.state.x[instr.rd] = rs1_val ^ imm
        elif f3 == F3_ORI: self.state.x[instr.rd] = rs1_val | imm
        elif f3 == F3_ANDI: self.state.x[instr.rd] = rs1_val & imm
        elif f3 == F3_SLLI: self.state.x[instr.rd] = rs1_val << (imm & 0x3F)
        elif f3 == F3_SRLI:
            let shamt = imm & 0x3F
            if instr.funct7 == 0x20:
                # SRAI: arithmetic right shift (sign-extending)
                self.state.x[instr.rd] = rs1_val >> shamt
            else:
                # SRLI: logical right shift (zero-fill)
                # For non-negative values, >> works as logical shift
                # For negative values, mask to 64-bit unsigned first
                if rs1_val < 0:
                    let unsigned_val = rs1_val + (1 << 64)
                    self.state.x[instr.rd] = unsigned_val >> shamt
                else:
                    self.state.x[instr.rd] = rs1_val >> shamt
        self.state.pc = self.state.pc + 4

    proc handle_reg(self, instr):
        let rs1_val = self.state.x[instr.rs1]
        let rs2_val = self.state.x[instr.rs2]
        let f3 = instr.funct3
        let f7 = instr.funct7

        if f7 == 0x01: # M-extension
            if f3 == F3_ADD: # MUL
                self.state.x[instr.rd] = rs1_val * rs2_val
            elif f3 == F3_XOR: # DIV
                if rs2_val != 0: self.state.x[instr.rd] = rs1_val / rs2_val
                else: self.state.x[instr.rd] = 0
            elif f3 == F3_OR: # REM
                if rs2_val != 0: self.state.x[instr.rd] = rs1_val % rs2_val
                else: self.state.x[instr.rd] = 0
            self.state.pc = self.state.pc + 4
            return

        if f3 == F3_ADD:
            if f7 == 0x00: 
                self.state.x[instr.rd] = rs1_val + rs2_val
            elif f7 == 0x20: self.state.x[instr.rd] = rs1_val - rs2_val
        elif f3 == F3_SLL: self.state.x[instr.rd] = rs1_val << (rs2_val & 0x3F)
        elif f3 == F3_SLT:
            if rs1_val < rs2_val: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_SLTU:
            if rs1_val < rs2_val: self.state.x[instr.rd] = 1
            else: self.state.x[instr.rd] = 0
        elif f3 == F3_XOR: self.state.x[instr.rd] = rs1_val ^ rs2_val
        elif f3 == F3_SRL:
            let shamt = rs2_val & 0x3F
            if f7 == 0x20:
                # SRA: arithmetic right shift
                self.state.x[instr.rd] = rs1_val >> shamt
            else:
                # SRL: logical right shift
                if rs1_val < 0:
                    let unsigned_val = rs1_val + (1 << 64)
                    self.state.x[instr.rd] = unsigned_val >> shamt
                else:
                    self.state.x[instr.rd] = rs1_val >> shamt
        elif f3 == F3_OR: self.state.x[instr.rd] = rs1_val | rs2_val
        elif f3 == F3_AND: self.state.x[instr.rd] = rs1_val & rs2_val
        self.state.pc = self.state.pc + 4

    proc handle_vmsys(self, instr):
        let f3 = instr.funct3
        let sub_op = instr.rs1
        
        if f3 == F3_VM_OPS:
            if sub_op == VMO_HALT:
                self.state.running = false
            elif sub_op == VMO_IMPORT:
                let idx = int(self.state.x[10]) # a0
                let name = self.safe_get_constant(idx)
                if not self.state.running: return

                # Security: Explicitly block sensitive modules in safe mode
                if self.state.safe_mode and (name == "io" or name == "net" or name == "sys" or name == "thread" or name == "gpu" or name == "ml_native" or name == "mem" or name == "ffi" or name == "struct"):
                    print "Error: Access to module '" + name + "' is restricted in safe mode"
                    self.state.x[instr.rd] = nil
                elif name == "ffi" and not self.state.ffi_enabled:
                    print "Error: FFI is disabled"
                    self.state.x[instr.rd] = nil
                else:
                    try:
                        if name == "math":
                            let m = {"pi": 3.141592653589793, "e": 2.718281828459045}
                            m["__type__"] = "module"
                            m["abs"] = math.abs
                            m["sqrt"] = math.sqrt
                            m["sin"] = math.sin
                            m["cos"] = math.cos
                            m["printm"] = "__builtin_math_printm"
                            self.state.x[instr.rd] = m
                        elif name == "io": self.state.x[instr.rd] = io
                        elif name == "sys":
                            let s = {"args": sys.args()}
                            s["__type__"] = "module"
                            s["exec"] = "__builtin_sys_exec"
                            s["exit"] = sys.exit
                            self.state.x[instr.rd] = s
                        elif name == "net": self.state.x[instr.rd] = net
                        elif name == "gpu":
                            let g = {}
                            g["__type__"] = "module"
                            g["poll_events"] = gpu.poll_events
                            g["get_time"] = gpu.get_time
                            g["mouse_pos"] = gpu.mouse_pos
                            self.state.x[instr.rd] = g
                        elif name == "ml_native": self.state.x[instr.rd] = ml_native
                        elif name == "thread": self.state.x[instr.rd] = host_thread
                        elif name == "mem":
                            let m = {"__host_mod__": "mem", "alloc": "__builtin_mem_alloc", "free": "__builtin_mem_free", "read": "__builtin_mem_read", "write": "__builtin_mem_write", "size": "__builtin_mem_size"}
                            self.state.x[instr.rd] = m
                        elif name == "ffi":
                            let f = {"__host_mod__": "ffi", "open": "__builtin_ffi_open", "close": "__builtin_ffi_close", "call": "__builtin_ffi_call"}
                            self.state.x[instr.rd] = f
                        elif name == "struct":
                            let s = {"__host_mod__": "struct", "def": "__builtin_struct_def", "new": "__builtin_struct_new", "get": "__builtin_struct_get", "set": "__builtin_struct_set", "size": "__builtin_struct_size"}
                            self.state.x[instr.rd] = s
                        else:
                            self.state.x[instr.rd] = {"__type__": "module", "__name__": name}
                    catch e:
                        self.state.x[instr.rd] = {"__type__": "module", "__name__": name}
            elif sub_op == VMO_PRINT:
                print str(self.state.x[10]) # Use a0
            elif sub_op == VMO_PRINTM:
                print str(self.state.x[10])
            elif sub_op == VMO_CMP_BINARY:
                let val1 = self.state.x[10]
                let val2 = self.state.x[11]
                let cmp_type = instr.funct7
                if cmp_type == CMP_EQ: self.state.x[10] = (val1 == val2)
                elif cmp_type == CMP_NEQ: self.state.x[10] = (val1 != val2)
                elif cmp_type == CMP_LT: self.state.x[10] = (val1 < val2)
                elif cmp_type == CMP_GT: self.state.x[10] = (val1 > val2)
                elif cmp_type == CMP_LE: self.state.x[10] = (val1 <= val2)
                elif cmp_type == CMP_GE: self.state.x[10] = (val1 >= val2)
            elif sub_op == VMO_NIL:
                self.state.x[instr.rd] = nil
            elif sub_op == VMO_TRUE:
                self.state.x[instr.rd] = true
            elif sub_op == VMO_FALSE:
                self.state.x[instr.rd] = false
            elif sub_op == VMO_NOT:
                self.state.x[instr.rd] = not self.is_truthy(self.state.x[10])
            elif sub_op == VMO_TRUTHY:
                self.state.x[instr.rd] = self.is_truthy(self.state.x[10])
            elif sub_op == VMO_PUSH_ENV:
                # Security: Prevent environment stack exhaustion (DoS)
                if len(self.state.call_stack) >= self.state.max_call_depth:
                    print "Error: Call depth limit exceeded"
                    self.state.running = false
                    return
                push(self.state.call_stack, self.state.heap)
                self.state.heap = {}
            elif sub_op == VMO_POP_ENV:
                if len(self.state.call_stack) > 0:
                    self.state.heap = pop(self.state.call_stack)
            elif sub_op == VMO_CALL:
                # Security: Prevent infinite recursion from exhausting host resources (DoS)
                if len(self.state.call_stack) >= self.state.max_call_depth:
                    print "Error: Call depth limit exceeded"
                    self.state.running = false
                    return

                let func_obj = self.state.x[instr.rs2] 
                var target_chunk = -1
                if type(func_obj) == "number": target_chunk = int(func_obj)
                elif type(func_obj) == "dict" and dict_has(func_obj, "chunk_idx"): target_chunk = int(func_obj["chunk_idx"])
                elif type(func_obj) == "dict" and dict_has(func_obj, "__builtin__"):
                    let b_name = func_obj["__builtin__"]
                    if b_name == "str":
                        self.state.x[10] = str(self.state.x[10]) # Result in a0
                    elif b_name == "int":
                        self.state.x[10] = int(self.state.x[10])
                    elif b_name == "slice":
                        self.state.x[10] = slice(self.state.x[10], self.state.x[11], self.state.x[12])
                    elif b_name == "len":
                        self.state.x[10] = len(self.state.x[10])
                    elif b_name == "type":
                        self.state.x[10] = type(self.state.x[10])
                    elif b_name == "range":
                        self.state.x[10] = range(self.state.x[10])
                    elif b_name == "clock":
                        self.state.x[10] = clock()
                    elif b_name == "tonumber":
                        self.state.x[10] = tonumber(self.state.x[10])
                    elif b_name == "push":
                        if self.is_protected(self.state.x[10]):
                            print "Error: Modification of protected object is restricted in safe mode"
                            self.state.x[10] = nil
                        else:
                            push(self.state.x[10], self.state.x[11])
                            self.state.x[10] = nil
                    elif b_name == "pop":
                        if self.is_protected(self.state.x[10]):
                            print "Error: Modification of protected object is restricted in safe mode"
                            self.state.x[10] = nil
                        else:
                            self.state.x[10] = pop(self.state.x[10])
                    elif b_name == "chr":
                        self.state.x[10] = chr(self.state.x[10])
                    elif b_name == "ord":
                        self.state.x[10] = ord(self.state.x[10])
                    elif b_name == "dict_has":
                        let obj = self.state.x[10]
                        let key = self.state.x[11]
                        if self.state.safe_mode and type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg"):
                            self.state.x[10] = false
                        else:
                            self.state.x[10] = dict_has(obj, key)
                    elif b_name == "dict_keys":
                        let obj = self.state.x[10]
                        let keys = dict_keys(obj)
                        if self.state.safe_mode:
                            let safe_keys = []
                            var i = 0
                            while i < len(keys):
                                let key = keys[i]
                                if not (type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg")):
                                    push(safe_keys, key)
                                i = i + 1
                            self.state.x[10] = safe_keys
                        else:
                            self.state.x[10] = keys
                    elif b_name == "dict_values":
                        let obj = self.state.x[10]
                        if self.state.safe_mode:
                            let safe_vals = []
                            let keys = dict_keys(obj)
                            var i = 0
                            while i < len(keys):
                                let key = keys[i]
                                if not (type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg")):
                                    push(safe_vals, obj[key])
                                i = i + 1
                            self.state.x[10] = safe_vals
                        else:
                            self.state.x[10] = dict_values(obj)
                    elif b_name == "gc_stats":
                        self.state.x[10] = gc_stats()
                    elif b_name == "gc_collect":
                        gc_collect()
                        self.state.x[10] = nil
                    elif b_name == "gc_enable":
                        gc_enable()
                        self.state.x[10] = nil
                    elif b_name == "gc_disable":
                        gc_disable()
                        self.state.x[10] = nil
                    elif b_name == "startswith":
                        self.state.x[10] = startswith(self.state.x[10], self.state.x[11])
                    elif b_name == "endswith":
                        self.state.x[10] = endswith(self.state.x[10], self.state.x[11])
                    elif b_name == "contains":
                        self.state.x[10] = contains(self.state.x[10], self.state.x[11])
                    elif b_name == "join":
                        self.state.x[10] = join(self.state.x[10], self.state.x[11])
                    elif b_name == "split":
                        self.state.x[10] = split(self.state.x[10], self.state.x[11])
                    elif b_name == "replace":
                        self.state.x[10] = replace(self.state.x[10], self.state.x[11], self.state.x[12])
                    elif b_name == "upper":
                        self.state.x[10] = upper(self.state.x[10])
                    elif b_name == "lower":
                        self.state.x[10] = lower(self.state.x[10])
                    elif b_name == "strip":
                        self.state.x[10] = strip(self.state.x[10])
                    elif b_name == "print":
                        print str(self.state.x[10])
                        self.state.x[10] = nil
                    self.state.pc = self.state.pc + 4
                    return
                
                if target_chunk >= 0:
                    let chunk = self.safe_get_chunk(target_chunk)
                    if not self.state.running: return
                    push(self.state.call_stack, [self.state.current_chunk_idx, self.state.pc + 4, self.state.x[1]])
                    self.state.current_chunk_idx = target_chunk
                    self.state.bytecode = chunk
                    self.state.pc = 0
                    self.state.x[1] = 0
                    return
            elif sub_op == VMO_ARRAY_LEN:
                let obj = self.state.x[instr.rs2]
                if type(obj) == "list": self.state.x[instr.rd] = len(obj)
                elif type(obj) == "dict": self.state.x[instr.rd] = len(obj)
                else: self.state.x[instr.rd] = 0
            elif sub_op == VMO_SETUP_TRY:
                # Security: Prevent nested handlers from exhausting VM memory (DoS)
                if len(self.state.try_stack) >= self.state.max_try_depth:
                    print "Error: Handler depth limit exceeded"
                    self.state.running = false
                    return

                let catch_offset = instr.imm_i
                push(self.state.try_stack, [self.state.pc + catch_offset, len(self.state.call_stack)])
            elif sub_op == VMO_END_TRY:
                if len(self.state.try_stack) > 0:
                    pop(self.state.try_stack)
            elif sub_op == VMO_RAISE:
                let exc_obj = self.state.x[10] # a0
                if len(self.state.try_stack) > 0:
                    let handler = pop(self.state.try_stack)
                    let catch_pc = handler[0]
                    let target_call_depth = handler[1]
                    while len(self.state.call_stack) > target_call_depth:
                        pop(self.state.call_stack)
                    self.state.pc = catch_pc
                    self.state.x[10] = exc_obj
                    return
                else:
                    print "Unhandled exception: " + str(exc_obj)
                    self.state.running = false
                    return
        elif f3 == F3_OBJ_OPS:
            if sub_op == OBJ_GET_GLOBAL:
                let idx = int(self.state.x[10]) # a0
                let name = self.safe_get_constant(idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    self.state.x[instr.rd] = nil
                elif dict_has(self.state.heap, name):
                    self.state.x[instr.rd] = self.state.heap[name]
                elif name == "str" or name == "int" or name == "slice" or name == "len" or name == "type" or name == "range" or name == "clock" or name == "tonumber" or name == "push" or name == "pop" or name == "chr" or name == "ord" or name == "dict_has" or name == "dict_keys" or name == "dict_values" or name == "gc_stats" or name == "gc_collect" or name == "gc_enable" or name == "gc_disable" or name == "startswith" or name == "endswith" or name == "contains" or name == "join" or name == "split" or name == "replace" or name == "upper" or name == "lower" or name == "strip" or name == "print":
                    self.state.x[instr.rd] = {"__builtin__": name}
                else:
                    self.state.x[instr.rd] = nil
            elif sub_op == OBJ_SET_GLOBAL:
                let idx = int(self.state.x[10]) # a0
                let val = self.state.x[11] # a1
                let name = self.safe_get_constant(idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    print "Error: Assignment to internal global '" + name + "' is restricted in safe mode"
                else:
                    self.state.heap[name] = val
            elif sub_op == OBJ_GET_PROP:
                let obj = self.state.x[instr.rs2]
                let name_idx = int(self.state.x[10])
                let name = self.safe_get_constant(name_idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    self.state.x[instr.rd] = nil
                elif type(obj) == "dict": self.state.x[instr.rd] = obj[name]
                else: self.state.x[instr.rd] = nil
            elif sub_op == OBJ_SET_PROP:
                let obj = self.state.x[instr.rs2]
                let name_idx = int(self.state.x[10])
                let val = self.state.x[11]
                let name = self.safe_get_constant(name_idx)
                if not self.state.running: return
                if self.state.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    print "Error: Access to internal property '" + name + "' is restricted in safe mode"
                elif self.is_protected(obj):
                    print "Error: Modification of protected object '" + name + "' is restricted in safe mode"
                elif type(obj) == "dict":
                    obj[name] = val
            elif sub_op == OBJ_NEW_FUNC:
                let chunk_idx = int(self.state.x[10])
                self.state.x[instr.rd] = {"type": "function", "chunk_idx": chunk_idx}
            elif sub_op == OBJ_ARRAY_NEW:
                let size = int(self.state.x[10])
                # Security: Prevent memory exhaustion via large array allocation (DoS)
                if size < 0 or size > self.state.max_array_size:
                    print "Error: Array size limit exceeded: " + str(size)
                    self.state.running = false
                    return

                let init_val = self.state.x[11]
                var arr = []
                var i = 0
                while i < size:
                    push(arr, init_val)
                    i = i + 1
                self.state.x[instr.rd] = arr
            elif sub_op == OBJ_DICT_NEW:
                self.state.x[instr.rd] = {}
            elif sub_op == OBJ_TUPLE_NEW:
                let size = int(self.state.x[10])
                var t_arr = []
                var i = 0
                while i < size:
                    push(t_arr, nil)
                    i = i + 1
                self.state.x[instr.rd] = t_arr
            elif sub_op == OBJ_GET_INDEX:
                let obj = self.state.x[instr.rs2]
                let raw_idx = self.state.x[10]
                if self.state.safe_mode and type(raw_idx) == "string" and startswith(raw_idx, "__") and not startswith(raw_idx, "__arg"):
                    self.state.x[instr.rd] = nil
                elif type(obj) == "dict":
                    self.state.x[instr.rd] = obj[raw_idx]
                elif type(obj) == "list" or type(obj) == "array":
                    let idx = int(raw_idx)
                    if idx >= 0 and idx < len(obj):
                        self.state.x[instr.rd] = obj[idx]
                    else: self.state.x[instr.rd] = nil
                elif type(obj) == "string":
                    let idx = int(raw_idx)
                    if idx >= 0 and idx < len(obj):
                        self.state.x[instr.rd] = obj[idx]
                    else: self.state.x[instr.rd] = nil
                else: self.state.x[instr.rd] = nil
            elif sub_op == OBJ_SET_INDEX:
                let obj = self.state.x[instr.rs2]
                let raw_idx = self.state.x[10]
                let val = self.state.x[11]
                if self.state.safe_mode and type(raw_idx) == "string" and startswith(raw_idx, "__") and not startswith(raw_idx, "__arg"):
                    print "Error: Index assignment to internal key '" + raw_idx + "' is restricted in safe mode"
                elif self.is_protected(obj):
                    print "Error: Index assignment to protected object is restricted in safe mode"
                elif type(obj) == "dict":
                    obj[raw_idx] = val
                elif type(obj) == "list" or type(obj) == "array":
                    let idx = int(raw_idx)
                    if idx >= 0 and idx < len(obj):
                        obj[idx] = val
        elif f3 == F3_GPU_OPS:
            self.handle_gpu(instr)
        
        self.state.pc = self.state.pc + 4

    proc handle_gpu(self, instr):
        let sub_op = instr.rs1
        # TODO: Implement mapping for 28 GPU opcodes
        if self.trace:
            print "GPU Op: " + str(sub_op)
        return nil

