import io
import math
import net
import thread as host_thread
import sys
import gpu
import ml_native
import jit_engine

from sgvm_core import SGVMUtils
from sgvm_core import OP_CONSTANT, OP_NIL, OP_TRUE, OP_FALSE, OP_POP, OP_GET_GLOBAL, OP_DEFINE_GLOBAL, OP_SET_GLOBAL, OP_DEFINE_FUNCTION, OP_GET_PROPERTY, OP_SET_PROPERTY, OP_GET_INDEX, OP_SET_INDEX, OP_LOAD_FUNCTION, OP_SLICE, OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_MOD, OP_NEGATE, OP_EQUAL, OP_NOT_EQUAL, OP_GREATER, OP_GREATER_EQUAL, OP_LESS, OP_LESS_EQUAL, OP_BIT_AND, OP_BIT_OR, OP_BIT_XOR, OP_BIT_NOT, OP_SHIFT_LEFT, OP_SHIFT_RIGHT, OP_NOT, OP_TRUTHY, OP_JUMP, OP_JUMP_IF_FALSE, OP_CALL, OP_CALL_METHOD, OP_ARRAY, OP_TUPLE, OP_DICT, OP_PRINT, OP_EXEC_AST_STMT, OP_RETURN, OP_MATH_PRINTM, OP_PUSH_ENV, OP_POP_ENV, OP_DUP, OP_ARRAY_LEN, OP_BREAK, OP_CONTINUE, OP_LOOP_BACK, OP_IMPORT, OP_CLASS, OP_METHOD, OP_INHERIT, OP_SETUP_TRY, OP_END_TRY, OP_RAISE, OP_GET_LOCAL, OP_SET_LOCAL, OP_YIELD, OP_CREATE_GENERATOR, OP_GENERATOR_NEXT, OP_HALT
from sgvm_core import OP_GPU_POLL_EVENTS, OP_GPU_WINDOW_SHOULD_CLOSE, OP_GPU_GET_TIME, OP_GPU_KEY_PRESSED, OP_GPU_KEY_DOWN, OP_GPU_MOUSE_POS, OP_GPU_MOUSE_DELTA, OP_GPU_UPDATE_INPUT, OP_GPU_BEGIN_COMMANDS, OP_GPU_END_COMMANDS, OP_GPU_CMD_BEGIN_RP, OP_GPU_CMD_END_RP, OP_GPU_CMD_DRAW, OP_GPU_CMD_BIND_GP, OP_GPU_CMD_BIND_DS, OP_GPU_CMD_SET_VP, OP_GPU_CMD_SET_SC, OP_GPU_CMD_BIND_VB, OP_GPU_CMD_BIND_IB, OP_GPU_CMD_DRAW_IDX, OP_GPU_SUBMIT_SYNC, OP_GPU_ACQUIRE_IMG, OP_GPU_PRESENT, OP_GPU_WAIT_FENCE, OP_GPU_RESET_FENCE, OP_GPU_UPDATE_UNIFORM, OP_GPU_CMD_PUSH_CONST, OP_GPU_CMD_DISPATCH

proc gc_collect():
    return nil
proc gc_stats():
    return {"num_objects": 0}
proc gc_enable():
    return nil
proc gc_disable():
    return nil
proc reflect_get_methods(obj):
    return []
proc reflect_get_class(obj):
    return nil

proc is_truthy(val):
    if val == nil or val == false or val == 0:
        return false
    if type(val) == "string" and len(val) == 0:
        return false
    return true

proc str_repeat(s, count):
    if count <= 0:
        return ""
    var res = ""
    var i = 0
    while i < count:
        res = res + s
        i = i + 1
    return res

var g_gil = nil

class MetalVM:
    proc equal_val(self, a, b):
        if type(a) != type(b):
            return false
        if type(a) == "dict":
            let keys_a = dict_keys(a)
            let keys_b = dict_keys(b)
            if len(keys_a) != len(keys_b):
                return false
            var i = 0
            while i < len(keys_a):
                let k = keys_a[i]
                if not dict_has(b, k):
                    return false
                if not self.equal_val(a[k], b[k]):
                    return false
                i = i + 1
            return true
        elif type(a) == "array" or type(a) == "tuple":
            if len(a) != len(b):
                return false
            var i = 0
            while i < len(a):
                if not self.equal_val(a[i], b[i]):
                    return false
                i = i + 1
            return true
        else:
            return a == b

    proc init(self):
        self.stack = []
        self.constants = []
        self.chunks = []
        self.globals = {}
        self.scopes = []
        push(self.scopes, {})
        self.handlers = []
        self.ip = 0
        self.code = []
        self.halted = false
        self.exit_requested = false
        self.is_throwing = false
        self.exception_value = nil
        self.trace = false
        self.safe_mode = false
        self.ffi_enabled = true
        self.exec_enabled = true
        self.user_args = nil
        self.modules = {}
        self.utils = SGVMUtils()
        # Security: Limits to prevent Denial of Service (DoS) via resource exhaustion
        self.max_stack_depth = 65536
        self.call_depth = 0
        self.max_call_depth = 1024
        self.max_handler_depth = 1024
        self.return_value = nil
        self.returning = false
        self.call_stack = [{"ip": 0, "code": [], "constants": []}]
        # Performance: Cache local_base to avoid dictionary lookups in hot loop
        self.current_local_base = 0
        self.active_generator = nil
        self.gen_caller_stack = []
        self.jit_enabled = false
        self.jit_engine = jit_engine.JITEngine()

    proc safe_get_constant(self, idx):
        if idx >= 0 and idx < len(self.constants): return self.constants[idx]
        print "Error: Constant pool index out of bounds: " + str(idx)
        self.halted = true
        return nil

    proc safe_get_chunk(self, idx):
        if idx >= 0 and idx < len(self.chunks): return self.chunks[idx]
        print "Error: Chunk index out of bounds: " + str(idx)
        self.halted = true
        return []

    proc setup_builtins(self):
        # Native Bridge: Expose host standard library to guest VM
        self.globals["math"] = {"__host_mod__": math, "printm": "__builtin_math_printm"}
        
        if not self.safe_mode:
            # Security: Only expose sensitive modules to globals if NOT in safe mode
            self.globals["io"] = {"__host_mod__": io}
            self.globals["sys"] = {"__host_mod__": sys}
            self.globals["net"] = {"__host_mod__": net}
            self.globals["thread"] = {"__host_mod__": host_thread}
            self.globals["gpu"] = {"__host_mod__": gpu}
            self.globals["ml_native"] = {"__host_mod__": ml_native}
            self.globals["mem"] = {"__host_mod__": "mem", "alloc": "__builtin_mem_alloc", "free": "__builtin_mem_free", "read": "__builtin_mem_read", "write": "__builtin_mem_write", "size": "__builtin_mem_size"}
            if self.ffi_enabled:
                self.globals["ffi"] = {"__host_mod__": "ffi", "open": "__builtin_ffi_open", "close": "__builtin_ffi_close", "call": "__builtin_ffi_call"}
            self.globals["struct"] = {"__host_mod__": "struct", "def": "__builtin_struct_def", "new": "__builtin_struct_new", "get": "__builtin_struct_get", "set": "__builtin_struct_set", "size": "__builtin_struct_size"}

        self.globals["gc"] = {"__host_mod__": "gc"}
        self.globals["gc"]["collect"] = "__builtin_gc_collect"
        self.globals["gc"]["stats"] = "__builtin_gc_stats"
        self.globals["gc"]["enable"] = "__builtin_gc_enable"
        self.globals["gc"]["disable"] = "__builtin_gc_disable"

        self.globals["reflect"] = {"__host_mod__": "reflect"}
        self.globals["reflect"]["get_methods"] = "__builtin_reflect_get_methods"
        self.globals["reflect"]["get_class"] = "__builtin_reflect_get_class"


        # Core builtins
        self.globals["clock"] = "__builtin_clock"
        self.globals["str"] = "__builtin_str"
        self.globals["int"] = "__builtin_int"
        self.globals["tonumber"] = "__builtin_tonumber"
        self.globals["len"] = "__builtin_len"
        self.globals["print"] = "__builtin_print"
        self.globals["range"] = "__builtin_range"
        self.globals["type"] = "__builtin_type"
        self.globals["slice"] = "__builtin_slice"
        
        # Advanced GC builtins
        self.globals["gc_collect"] = "__builtin_gc_collect"
        self.globals["gc_stats"] = "__builtin_gc_stats"
        self.globals["gc_enable"] = "__builtin_gc_enable"
        self.globals["gc_disable"] = "__builtin_gc_disable"
        
        # Reflection builtins
        self.globals["reflect_get_methods"] = "__builtin_reflect_get_methods"
        self.globals["reflect_get_class"] = "__builtin_reflect_get_class"
        # String/Collection builtins
        self.globals["push"] = "__builtin_push"
        self.globals["pop"] = "__builtin_pop"
        self.globals["next"] = "__builtin_next"
        self.globals["chr"] = "__builtin_chr"
        self.globals["ord"] = "__builtin_ord"
        self.globals["startswith"] = "__builtin_startswith"
        self.globals["endswith"] = "__builtin_endswith"
        self.globals["contains"] = "__builtin_contains"
        self.globals["join"] = "__builtin_join"
        self.globals["split"] = "__builtin_split"
        self.globals["replace"] = "__builtin_replace"
        self.globals["upper"] = "__builtin_upper"
        self.globals["lower"] = "__builtin_lower"
        self.globals["strip"] = "__builtin_strip"
        self.globals["dict_has"] = "__builtin_dict_has"
        self.globals["dict_keys"] = "__builtin_dict_keys"
        self.globals["dict_values"] = "__builtin_dict_values"

    proc is_protected(self, obj):
        # Security helper: Check if an object is a protected module or host bridge
        if not self.safe_mode:
            return false

        if type(obj) == "dict":
            if dict_has(obj, "__host_mod__") or (dict_has(obj, "__type__") and obj["__type__"] == "module") or dict_has(obj, "__builtin__"):
                return true
        elif type(obj) == "module":
            return true
        return false

    proc run(self, code):
        self.code = code
        self.ip = 0
        self.halted = false

        if self.jit_enabled:
            self.jit_engine.enabled = true
            let chunk_id = len(self.call_stack)
            if self.jit_engine.record_and_check(chunk_id):
                if self.trace: print "⚡ [JIT] Compiling SVM chunk " + str(chunk_id) + " to JIT block"
                self.jit_engine.compile_svm_chunk(chunk_id, code, self.constants)

        # Performance: Cache frequently used properties as local variables
        var ip = 0
        var code_bytes = code
        var halted = false
        let stack = self.stack
        var stack_len = len(stack)
        let max_stack = self.max_stack_depth
        let constants = self.constants
        var scopes = self.scopes
        var global_scope = scopes[0]
        let globals = self.globals
        let trace = self.trace
        let safe_mode = self.safe_mode
        var local_base = self.current_local_base
        let code_len = len(code_bytes)
        let const_len = len(constants)
        var scopes_len = len(scopes)

        # Performance: Inline cache for global lookup and assignment
        var global_cache_dict = []
        var ci = 0
        while ci < const_len:
            push(global_cache_dict, nil)
            ci = ci + 1

        host_thread.lock(g_gil)
        while not halted and ip < code_len:
            let op = code_bytes[ip]
            if trace:
                print "IP: " + str(ip) + " OP: " + str(op) + " Stack: " + str(stack)

            ip = ip + 1

            # Hot-path dispatch: inline most frequent opcodes to avoid function call overhead
            if op == OP_GET_LOCAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if local_base + idx < stack_len:
                    push(stack, stack[local_base + idx])
                else:
                    push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_CONSTANT:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx < const_len:
                    push(stack, constants[idx])
                    stack_len = stack_len + 1
                else:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
            elif op == OP_POP:
                pop(stack)
                stack_len = stack_len - 1
            elif op == OP_GET_GLOBAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                # Check inline cache
                let cached_dict = global_cache_dict[idx]
                if cached_dict != nil:
                    push(stack, cached_dict[constants[idx]])
                    stack_len = stack_len + 1
                    continue

                if idx >= const_len:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
                let name = constants[idx]

                if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    push(stack, nil)
                    stack_len = stack_len + 1
                    continue
                # Performance: Bypassing dict_has for direct lookup where possible
                var found = false
                var resolved_dict = nil
                if scopes_len == 1:
                    let val = global_scope[name]
                    if val != nil:
                        push(stack, val)
                        found = true
                        resolved_dict = global_scope
                    elif dict_has(global_scope, name):
                        push(stack, nil)
                        found = true
                        resolved_dict = global_scope
                elif scopes_len == 2:
                    let val1 = scopes[1][name]
                    if val1 != nil:
                        push(stack, val1)
                        found = true
                        resolved_dict = scopes[1]
                    elif dict_has(scopes[1], name):
                        push(stack, nil)
                        found = true
                        resolved_dict = scopes[1]
                    else:
                        let val0 = global_scope[name]
                        if val0 != nil:
                            push(stack, val0)
                            found = true
                            resolved_dict = global_scope
                        elif dict_has(global_scope, name):
                            push(stack, nil)
                            found = true
                            resolved_dict = global_scope
                else:
                    var si = scopes_len - 1
                    while si >= 0:
                        let val = scopes[si][name]
                        if val != nil:
                            push(stack, val)
                            found = true
                            resolved_dict = scopes[si]
                            si = -1
                        elif dict_has(scopes[si], name):
                            push(stack, nil)
                            found = true
                            resolved_dict = scopes[si]
                            si = -1
                        else:
                            si = si - 1
                if not found:
                    let val = globals[name]
                    push(stack, val)
                    resolved_dict = globals

                if resolved_dict != nil:
                    global_cache_dict[idx] = resolved_dict
                stack_len = stack_len + 1
            elif op == OP_SET_LOCAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                let val = stack[stack_len-1]
                let target_idx = local_base + idx
                if target_idx < stack_len:
                    stack[target_idx] = val
                else:
                    while target_idx >= stack_len:
                        if stack_len >= max_stack:
                            print "Error: Stack overflow"
                            halted = true
                            break
                        push(stack, nil)
                        stack_len = stack_len + 1
                    if halted: break
                    stack[target_idx] = val
            elif op == OP_ADD:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                # Performance: fast-path non-allocating check for numerical addition
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a + b
                else:
                    let type_a = type(a)
                    let type_b = type(b)
                    if type_a == "number" and type_b == "number":
                        stack[stack_len-1] = a + b
                    elif type_a == "string" or type_b == "string":
                        if a == nil: a = ""
                        if b == nil: b = ""
                        stack[stack_len-1] = str(a) + str(b)
                    elif type_a == "array" and type_b == "array":
                        let res = []
                        var ai = 0
                        while ai < len(a):
                            push(res, a[ai])
                            ai = ai + 1
                        ai = 0
                        while ai < len(b):
                            push(res, b[ai])
                            ai = ai + 1
                        stack[stack_len-1] = res
                    else:
                        if a == nil: a = 0
                        if b == nil: b = 0
                        if type(a) != "number" or type(b) != "number":
                            stack[stack_len-1] = 0
                        else:
                            stack[stack_len-1] = a + b
            elif op == OP_SET_GLOBAL:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                let cached_dict = global_cache_dict[idx]
                if cached_dict != nil:
                    cached_dict[constants[idx]] = stack[stack_len-1]
                    continue

                if idx >= const_len:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
                let val = stack[stack_len-1]

                let name = constants[idx]
                if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                    print "Error: Assignment to internal global '" + name + "' is restricted in safe mode"
                    stack[stack_len-1] = nil
                    continue
                # Performance: Fast-path for common scope depths bypassing dict_has
                var resolved_dict = nil
                if scopes_len == 1:
                    if global_scope[name] != nil:
                        global_scope[name] = val
                        resolved_dict = global_scope
                    elif dict_has(global_scope, name):
                        global_scope[name] = val
                        resolved_dict = global_scope
                    else:
                        globals[name] = val
                        resolved_dict = globals
                elif scopes_len == 2:
                    if scopes[1][name] != nil:
                        scopes[1][name] = val
                        resolved_dict = scopes[1]
                    elif dict_has(scopes[1], name):
                        scopes[1][name] = val
                        resolved_dict = scopes[1]
                    elif global_scope[name] != nil:
                        global_scope[name] = val
                        resolved_dict = global_scope
                    elif dict_has(global_scope, name):
                        global_scope[name] = val
                        resolved_dict = global_scope
                    else:
                        globals[name] = val
                        resolved_dict = globals
                else:
                    var si = scopes_len - 1
                    var updated = false
                    while si >= 0:
                        if scopes[si][name] != nil:
                            scopes[si][name] = val
                            updated = true
                            resolved_dict = scopes[si]
                            si = -1
                        elif dict_has(scopes[si], name):
                            scopes[si][name] = val
                            updated = true
                            resolved_dict = scopes[si]
                            si = -1
                        else:
                            si = si - 1
                    if not updated:
                        globals[name] = val
                        resolved_dict = globals

                if resolved_dict != nil:
                    global_cache_dict[idx] = resolved_dict
            elif op == OP_JUMP:
                ip = (code_bytes[ip] << 8) | code_bytes[ip+1]
            elif op == OP_JUMP_IF_FALSE:
                let target = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                let cond = stack[stack_len-1]
                # Performance: Inline truthiness evaluation to bypass is_truthy function call overhead
                if cond == nil or cond == false or cond == 0 or cond == "": ip = target
            elif op == OP_LOOP_BACK:
                # Performance: Backward control flow jumps do not grow the stack; stack overflow check removed
                ip = ip - ((code_bytes[ip] << 8) | code_bytes[ip+1])
            elif op == OP_LESS:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a < b
                else:
                    if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a < b
                    else: stack[stack_len-1] = false
            elif op == OP_MUL:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a * b
                else:
                    let type_a = type(a)
                    let type_b = type(b)
                    if type_a == "number" and type_b == "number":
                        stack[stack_len-1] = a * b
                    elif type_a == "string" and type_b == "number":
                        stack[stack_len-1] = str_repeat(a, int(b))
                    elif type_a == "number" and type_b == "string":
                        stack[stack_len-1] = str_repeat(b, int(a))
                    else:
                        stack[stack_len-1] = 0
            elif op == OP_DIV:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b and b != 0:
                    stack[stack_len-1] = a / b
                else:
                    if type(a) == "number" and type(b) == "number" and b != 0:
                        stack[stack_len-1] = a / b
                    else:
                        stack[stack_len-1] = nil
            elif op == OP_SUB:
                var b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a - b
                else:
                    if type(a) == "number" and type(b) == "number":
                        stack[stack_len-1] = a - b
                    else:
                        stack[stack_len-1] = 0
            elif op == OP_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                # Performance: Fast-path primitive & reference equality to bypass self.equal_val and heap type() calls
                if a == b:
                    stack[stack_len-1] = true
                elif a == nil or b == nil or a == true or a == false or b == true or b == false:
                    stack[stack_len-1] = false
                elif tonumber(a) == a or tonumber(b) == b:
                    stack[stack_len-1] = false
                else:
                    let type_a = type(a)
                    if type_a == "dict" or type_a == "array" or type_a == "tuple":
                        stack[stack_len-1] = self.equal_val(a, b)
                    else:
                        stack[stack_len-1] = false
            elif op == OP_NOT_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                # Performance: Fast-path primitive & reference inequality to bypass self.equal_val and heap type() calls
                if a == b:
                    stack[stack_len-1] = false
                elif a == nil or b == nil or a == true or a == false or b == true or b == false:
                    stack[stack_len-1] = true
                elif tonumber(a) == a or tonumber(b) == b:
                    stack[stack_len-1] = true
                else:
                    let type_a = type(a)
                    if type_a == "dict" or type_a == "array" or type_a == "tuple":
                        stack[stack_len-1] = not self.equal_val(a, b)
                    else:
                        stack[stack_len-1] = true
            elif op == OP_LESS_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a <= b
                else:
                    if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a <= b
                    else: stack[stack_len-1] = false
            elif op == OP_GREATER:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a > b
                else:
                    if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a > b
                    else: stack[stack_len-1] = false
            elif op == OP_GREATER_EQUAL:
                let b = pop(stack)
                stack_len = stack_len - 1
                let a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b:
                    stack[stack_len-1] = a >= b
                else:
                    if type(a) == "number" and type(b) == "number": stack[stack_len-1] = a >= b
                    else: stack[stack_len-1] = false
            elif op == OP_NIL:
                push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_TRUE:
                push(stack, true)
                stack_len = stack_len + 1
            elif op == OP_FALSE:
                push(stack, false)
                stack_len = stack_len + 1
            elif op == OP_DUP:
                let distance = code_bytes[ip]
                ip = ip + 1
                if distance < stack_len:
                    push(stack, stack[stack_len-1-distance])
                else:
                    push(stack, nil)
                stack_len = stack_len + 1
            elif op == OP_MOD:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                if a != nil and b != nil and tonumber(a) == a and tonumber(b) == b and b != 0:
                    stack[stack_len-1] = a % b
                else:
                    if type(a) == "number" and type(b) == "number" and b != 0:
                        stack[stack_len-1] = a % b
                    else:
                        stack[stack_len-1] = nil
            elif op == OP_BIT_AND:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a & b_val
            elif op == OP_BIT_OR:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a | b_val
            elif op == OP_BIT_XOR:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a ^ b_val
            elif op == OP_BIT_NOT:
                if stack[stack_len-1] == nil: stack[stack_len-1] = 0
                else: stack[stack_len-1] = ~stack[stack_len-1]
            elif op == OP_SHIFT_LEFT:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a << b_val
            elif op == OP_SHIFT_RIGHT:
                let b = pop(stack)
                stack_len = stack_len - 1
                var a = stack[stack_len-1]
                var b_val = b
                if a == nil: a = 0
                if b_val == nil: b_val = 0
                stack[stack_len-1] = a >> b_val
            elif op == OP_NOT:
                let cond = stack[stack_len-1]
                # Performance: Inline truthiness evaluation to bypass is_truthy function call overhead
                if cond == nil or cond == false or cond == 0 or cond == "":
                    stack[stack_len-1] = true
                else:
                    stack[stack_len-1] = false
            elif op == OP_TRUTHY:
                let cond = stack[stack_len-1]
                # Performance: Inline truthiness evaluation to bypass is_truthy function call overhead
                if cond == nil or cond == false or cond == 0 or cond == "":
                    stack[stack_len-1] = false
                else:
                    stack[stack_len-1] = true
            elif op == OP_PRINT:
                print pop(stack)
                stack_len = stack_len - 1
            elif op == OP_NEGATE:
                if stack[stack_len-1] == nil: stack[stack_len-1] = 0
                else: stack[stack_len-1] = -stack[stack_len-1]
            elif op == OP_ARRAY_LEN:
                stack[stack_len-1] = len(stack[stack_len-1])
            elif op == OP_PUSH_ENV:
                if scopes_len >= self.max_call_depth:
                    print "Error: Environment stack depth limit exceeded"
                    halted = true
                    break
                push(scopes, {})
                scopes_len = scopes_len + 1
                var ci = 0
                while ci < const_len:
                    global_cache_dict[ci] = nil
                    ci = ci + 1
            elif op == OP_POP_ENV:
                if scopes_len > 1:
                    pop(scopes)
                    scopes_len = scopes_len - 1
                else:
                    print "Error: Environment stack underflow"
                    halted = true
                    break
                var ci = 0
                while ci < const_len:
                    global_cache_dict[ci] = nil
                    ci = ci + 1
            elif op == OP_GET_INDEX:
                # Performance: Optimize OP_GET_INDEX in hot loop.
                # Note: In SageLang, querying a missing key from a dictionary natively evaluates to nil
                # instead of raising a KeyError or panicking. This allows us to bypass the expensive
                # dict_has check entirely, and safely index directly. Delay type(idx) check so it only
                # evaluates in safe_mode to avoid heap string allocations in default mode.
                let idx = stack[stack_len-1]
                let obj = stack[stack_len-2]
                let type_idx = type(idx)
                if safe_mode and type_idx == "string" and startswith(idx, "__") and not startswith(idx, "__arg"):
                    pop(stack)
                    stack[stack_len-2] = nil
                else:
                    pop(stack)
                    let type_obj = type(obj)
                    if type_obj == "dict":
                        # Performance: direct key lookup bypassing dict_has and type overhead
                        stack[stack_len-2] = obj[idx]
                    elif type_obj == "array" or type_obj == "tuple":
                        let i_idx = int(idx)
                        if i_idx >= 0 and i_idx < len(obj):
                            stack[stack_len-2] = obj[i_idx]
                        else:
                            stack[stack_len-2] = nil
                    elif type_obj == "string":
                        let i_idx = int(idx)
                        if i_idx >= 0 and i_idx < len(obj):
                            stack[stack_len-2] = obj[i_idx]
                        else:
                            stack[stack_len-2] = nil
                    else:
                        stack[stack_len-2] = nil
                stack_len = stack_len - 1
            elif op == OP_SET_INDEX:
                let val = stack[stack_len-1]
                let idx = stack[stack_len-2]
                let obj = stack[stack_len-3]
                let type_idx = type(idx)
                if safe_mode and type_idx == "string" and startswith(idx, "__") and not startswith(idx, "__arg"):
                    print "Error: Index assignment to internal key '" + idx + "' is restricted in safe mode"
                    pop(stack)
                    pop(stack)
                    stack[stack_len-3] = nil
                elif self.is_protected(obj):
                    print "Error: Index assignment to protected object is restricted in safe mode"
                    pop(stack)
                    pop(stack)
                    stack[stack_len-3] = nil
                else:
                    let type_obj = type(obj)
                    if type_obj == "dict":
                        obj[idx] = val
                    elif type_obj == "array" or type_obj == "tuple":
                        let i_idx = int(idx)
                        if i_idx >= 0 and i_idx < len(obj):
                            obj[i_idx] = val
                    pop(stack)
                    pop(stack)
                    stack[stack_len-3] = val
                stack_len = stack_len - 2
            elif op == OP_GET_PROPERTY:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx < const_len:
                    let name = constants[idx]
                    let obj = stack[stack_len-1]
                    if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                        stack[stack_len-1] = nil
                    elif type(obj) == "dict":
                        # Performance: direct key lookup fast-path bypassing dict_has
                        let val = obj[name]
                        if val != nil:
                            stack[stack_len-1] = val
                        elif dict_has(obj, name):
                            stack[stack_len-1] = nil
                        elif dict_has(obj, "__class__") and dict_has(obj["__class__"]["__methods__"], name):
                            stack[stack_len-1] = obj["__class__"]["__methods__"][name]
                        elif dict_has(obj, "__methods__") and dict_has(obj["__methods__"], name):
                            stack[stack_len-1] = obj["__methods__"][name]
                        elif dict_has(obj, "__type__") and obj["__type__"] == "module" and dict_has(global_scope, name):
                            stack[stack_len-1] = global_scope[name]
                        else:
                            stack[stack_len-1] = nil
                    else:
                        stack[stack_len-1] = obj[name]
                else:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
            elif op == OP_SET_PROPERTY:
                let idx = (code_bytes[ip] << 8) | code_bytes[ip+1]
                ip = ip + 2
                if idx < const_len:
                    let name = constants[idx]
                    let val = stack[stack_len-1]
                    let obj = stack[stack_len-2]
                    if safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                        print "Error: Access to internal property '" + name + "' is restricted in safe mode"
                        pop(stack)
                        stack[stack_len-2] = nil
                    elif self.is_protected(obj):
                        print "Error: Modification of protected object '" + name + "' is restricted in safe mode"
                        pop(stack)
                        stack[stack_len-2] = nil
                    else:
                        obj[name] = val
                        pop(stack)
                        stack[stack_len-2] = val
                    stack_len = stack_len - 1
                else:
                    print "Error: Constant pool index out of bounds: " + str(idx)
                    halted = true
                    break
            else:
                # Synchronize local state back to self before calling non-inlined execute_op
                self.ip = ip
                self.halted = halted
                self.current_local_base = local_base
                if not self.execute_op(op):
                    # execute_op may have modified halted/ip/local_base
                    halted = self.halted
                    break
                # Restore local state after execute_op
                ip = self.ip
                code_bytes = self.code
                code_len = len(code_bytes)
                halted = self.halted
                local_base = self.current_local_base
                scopes = self.scopes
                global_scope = scopes[0]
                scopes_len = len(scopes)
                stack_len = len(stack)
                # Reset global cache because scopes might have changed inside execute_op (e.g. call/return)
                var ci = 0
                while ci < const_len:
                    global_cache_dict[ci] = nil
                    ci = ci + 1

        # Final synchronization
        self.ip = ip
        self.halted = halted
        self.current_local_base = local_base
        host_thread.unlock(g_gil)

    proc call_builtin(self, callee, args):
        let argc = len(args)
        if callee == "__builtin_clock":
            return clock()
        elif callee == "__builtin_str":
            return str(args[0])
        elif callee == "__builtin_int":
            if len(args) == 0 or args[0] == nil:
                return 0
            if type(args[0]) == "string":
                let n = tonumber(args[0])
                if n == nil: return 0
                return int(n)
            return int(args[0])
        elif callee == "__builtin_tonumber":
            if len(args) == 0 or args[0] == nil: return nil
            return tonumber(args[0])
        elif callee == "__builtin_len":
            if len(args) == 0 or args[0] == nil: return nil
            return len(args[0])
        elif callee == "__builtin_print":
            print args[0]
            return nil
        elif callee == "__builtin_range":
            return range(args[0])
        elif callee == "__builtin_type":
            return type(args[0])
        elif callee == "__builtin_slice":
            var s0 = args[0]
            var s1 = args[1]
            var s2 = args[2]
            if s0 == nil: return ""
            if s1 == nil: s1 = 0
            if s2 == nil: s2 = len(s0)
            return slice(s0, s1, s2)
        elif callee == "__builtin_startswith":
            if args[0] == nil or args[1] == nil: return false
            return startswith(args[0], args[1])
        elif callee == "__builtin_endswith":
            if args[0] == nil or args[1] == nil: return false
            return endswith(args[0], args[1])
        elif callee == "__builtin_contains":
            if args[0] == nil or args[1] == nil: return false
            return contains(args[0], args[1])
        elif callee == "__builtin_math_printm":
            let matrix = args[0]
            if type(matrix) != "array":
                print "Error: math.printm() expects an array"
            else:
                print "["
                var mi = 0
                while mi < len(matrix):
                    let row = matrix[mi]
                    if type(row) == "array":
                        var parts = []
                        var mj = 0
                        while mj < len(row):
                            push(parts, str(row[mj]))
                            mj = mj + 1
                        print "  [" + join(parts, ", ") + "]"
                    else:
                        print "  " + str(row)
                    mi = mi + 1
                print "]"
            return nil
        elif callee == "__builtin_mem_alloc":
            if self.safe_mode:
                print "Error: mem_alloc is restricted in safe mode"
                return nil
            return mem_alloc(args[0])
        elif callee == "__builtin_mem_free":
            if self.safe_mode:
                print "Error: mem_free is restricted in safe mode"
                return nil
            return mem_free(args[0])
        elif callee == "__builtin_mem_read":
            if self.safe_mode:
                print "Error: mem_read is restricted in safe mode"
                return nil
            return mem_read(args[0], args[1], args[2])
        elif callee == "__builtin_mem_write":
            if self.safe_mode:
                print "Error: mem_write is restricted in safe mode"
                return nil
            return mem_write(args[0], args[1], args[2], args[3])
        elif callee == "__builtin_mem_size":
            if self.safe_mode:
                print "Error: mem_size is restricted in safe mode"
                return nil
            return mem_size(args[0])
        elif callee == "__builtin_ffi_open":
            if not self.ffi_enabled:
                print "Error: FFI is disabled"
                return nil
            if self.safe_mode:
                print "Error: ffi_open is restricted in safe mode"
                return nil
            return ffi_open(args[0])
        elif callee == "__builtin_ffi_close":
            if not self.ffi_enabled:
                print "Error: FFI is disabled"
                return nil
            if self.safe_mode:
                print "Error: ffi_close is restricted in safe mode"
                return nil
            return ffi_close(args[0])
        elif callee == "__builtin_ffi_call":
            if not self.ffi_enabled:
                print "Error: FFI is disabled"
                return nil
            if self.safe_mode:
                print "Error: ffi_call is restricted in safe mode"
                return nil
            # Note: ffi_call might be a stub in some backends
            try:
                if argc == 3: return ffi_call(args[0], args[1], args[2])
                else: return ffi_call(args[0], args[1], args[2], args[3])
            catch e:
                print "Error: ffi_call failed: " + str(e)
                return nil
        elif callee == "__builtin_struct_def":
            if self.safe_mode:
                print "Error: struct_def is restricted in safe mode"
                return nil
            return struct_def(args[0])
        elif callee == "__builtin_struct_new":
            if self.safe_mode:
                print "Error: struct_new is restricted in safe mode"
                return nil
            return struct_new(args[0])
        elif callee == "__builtin_struct_get":
            if self.safe_mode:
                print "Error: struct_get is restricted in safe mode"
                return nil
            return struct_get(args[0], args[1], args[2])
        elif callee == "__builtin_struct_set":
            if self.safe_mode:
                print "Error: struct_set is restricted in safe mode"
                return nil
            return struct_set(args[0], args[1], args[2], args[3])
        elif callee == "__builtin_struct_size":
            if self.safe_mode:
                print "Error: struct_size is restricted in safe mode"
                return nil
            return struct_size(args[0])
        elif callee == "__builtin_sys_exec":
            if self.safe_mode or not self.exec_enabled:
                print "Error: sys.exec is restricted"
                return nil
            return sys_exec(args[0])
        elif callee == "__builtin_sys_system":
            if self.safe_mode or not self.exec_enabled:
                print "Error: sys.exec is restricted"
                return nil
            return sys_exec(args[0])
        elif callee == "__builtin_sys_exit":
            self.exit_requested = true
            self.halted = true
            return nil
        elif callee == "__builtin_sys_getenv":
            if self.safe_mode:
                print "Error: sys.getenv is restricted in safe mode"
                return nil
            if len(args) > 0 and type(args[0]) == "string":
                return sys.getenv(args[0])
            return nil
        elif callee == "__builtin_io_writebytes":
            if self.safe_mode:
                print "Error: io.writebytes is restricted in safe mode"
                return nil
            if len(args) < 2 or args[0] == nil or args[1] == nil: return false
            return io.writebytes(args[0], args[1])
        elif callee == "__builtin_io_writefile":
            if self.safe_mode:
                print "Error: io.writefile is restricted in safe mode"
                return nil
            if len(args) < 2 or args[0] == nil or args[1] == nil: return false
            return io.writefile(args[0], args[1])
        elif callee == "__builtin_io_readbytes":
            if self.safe_mode:
                print "Error: io.readbytes is restricted in safe mode"
                return nil
            if len(args) == 0 or args[0] == nil or type(args[0]) != "string": return nil
            return io.readbytes(args[0])
        elif callee == "__builtin_io_readfile":
            if self.safe_mode:
                print "Error: io.readfile is restricted in safe mode"
                return nil
            if len(args) == 0 or args[0] == nil or type(args[0]) != "string": return nil
            return io.readfile(args[0])
        elif callee == "__builtin_thread_mutex":
            return nil
        elif callee == "__builtin_gpu_get_time":
            return 0.0
        elif callee == "__builtin_gpu_poll_events":
            return nil
        elif callee == "__builtin_gpu_mouse_pos":
            return {"x": 0, "y": 0}
        elif callee == "__builtin_gc_collect": return gc_collect()
        elif callee == "__builtin_gc_stats": return gc_stats()
        elif callee == "__builtin_gc_enable": return gc_enable()
        elif callee == "__builtin_gc_disable": return gc_disable()
        elif callee == "__builtin_reflect_get_methods": return reflect_get_methods(args[0])
        elif callee == "__builtin_reflect_get_class": return reflect_get_class(args[0])
        elif callee == "__builtin_push":
            if len(args) > 0 and self.is_protected(args[0]):
                print "Error: Modification of protected object is restricted in safe mode"
                return nil
            if len(args) > 1:
                push(args[0], args[1])
            return nil
        elif callee == "__builtin_pop":
            if len(args) > 0 and self.is_protected(args[0]):
                print "Error: Modification of protected object is restricted in safe mode"
                return nil
            if len(args) > 0:
                return pop(args[0])
            return nil
        elif callee == "__builtin_next":
            if len(args) > 0 and type(args[0]) == "dict" and dict_has(args[0], "__type__") and args[0]["__type__"] == "generator":
                let gen = args[0]
                if gen["completed"]: return nil
                let caller_info = {
                    "ip": self.ip,
                    "code": self.code,
                    "stack": self.stack,
                    "scopes": self.scopes,
                    "call_stack": self.call_stack,
                    "local_base": self.current_local_base,
                    "active_generator": self.active_generator
                }
                push(self.gen_caller_stack, caller_info)
                self.active_generator = gen
                self.code = self.chunks[gen["__chunk__"]]
                self.ip = gen["__ip__"]
                self.stack = gen["__stack__"]
                self.scopes = gen["__scopes__"]
                self.call_stack = gen["__call_stack__"]
                self.current_local_base = 0

                let target_gen = self.active_generator
                while not self.halted and self.active_generator == target_gen and self.ip < len(self.code):
                    let g_op = int(self.code[self.ip])
                    self.ip = self.ip + 1
                    self.execute_op(g_op)
                
                if len(self.stack) > 0:
                    return pop(self.stack)
                return nil
            return nil
        elif callee == "__builtin_chr":
            if len(args) == 0 or args[0] == nil: return ""
            return chr(int(args[0]))
        elif callee == "__builtin_ord":
            if len(args) == 0 or args[0] == nil or type(args[0]) != "string" or len(args[0]) == 0: return 0
            return ord(args[0])
        elif callee == "__builtin_startswith":
            return startswith(args[0], args[1])
        elif callee == "__builtin_endswith":
            return endswith(args[0], args[1])
        elif callee == "__builtin_contains":
            return contains(args[0], args[1])
        elif callee == "__builtin_join":
            return join(args[0], args[1])
        elif callee == "__builtin_split":
            return split(args[0], args[1])
        elif callee == "__builtin_replace":
            return replace(args[0], args[1], args[2])
        elif callee == "__builtin_upper":
            return upper(args[0])
        elif callee == "__builtin_lower":
            return lower(args[0])
        elif callee == "__builtin_strip":
            return strip(args[0])
        elif callee == "__builtin_dict_has":
            if len(args) < 2: return false
            let key = args[1]
            if self.safe_mode and type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg"):
                return false
            return dict_has(args[0], key)
        elif callee == "__builtin_dict_keys":
            if len(args) == 0 or args[0] == nil: return []
            let keys = dict_keys(args[0])
            if self.safe_mode:
                let safe_keys = []
                var i = 0
                while i < len(keys):
                    let key = keys[i]
                    if not (type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg")):
                        push(safe_keys, key)
                    i = i + 1
                return safe_keys
            return keys
        elif callee == "__builtin_dict_values":
            if len(args) == 0 or args[0] == nil: return []
            let obj = args[0]
            if self.safe_mode:
                let safe_vals = []
                let keys = dict_keys(obj)
                var i = 0
                while i < len(keys):
                    let key = keys[i]
                    if not (type(key) == "string" and startswith(key, "__") and not startswith(key, "__arg")):
                        push(safe_vals, obj[key])
                    i = i + 1
                return safe_vals
            return dict_values(obj)
        else:
            print "Error: Unknown builtin: " + callee
            return nil

    proc execute_op(self, op):
        let ut = self.utils
        if op == OP_CONSTANT:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            push(self.stack, self.safe_get_constant(idx))
        elif op == OP_NIL:
            push(self.stack, nil)
        elif op == OP_TRUE:
            push(self.stack, true)
        elif op == OP_FALSE:
            push(self.stack, false)
        elif op == OP_POP:
            pop(self.stack)
        elif op == OP_DUP:
            let distance = int(self.code[self.ip])
            self.ip = self.ip + 1
            if distance < len(self.stack):
                push(self.stack, self.stack[len(self.stack)-1-distance])
            else:
                push(self.stack, nil)
        elif op == OP_GET_GLOBAL:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.safe_get_constant(idx)
            if self.halted: return false

            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                push(self.stack, nil)
                return true

            if self.trace: print "DEBUG: GET_GLOBAL " + name
            var found = false
            var si = len(self.scopes) - 1
            while si >= 0:
                let val = self.scopes[si][name]
                if val != nil:
                    if self.trace: print "DEBUG: Found " + name + " in scope " + str(si) + ": " + str(val)
                    push(self.stack, val)
                    found = true
                    si = -1
                elif dict_has(self.scopes[si], name):
                    if self.trace: print "DEBUG: Found " + name + " in scope " + str(si) + ": nil"
                    push(self.stack, nil)
                    found = true
                    si = -1
                else:
                    si = si - 1
            if not found:
                let val = self.globals[name]
                if self.trace: print "DEBUG: Found " + name + " in globals: " + str(val)
                push(self.stack, val)
        elif op == OP_DEFINE_GLOBAL:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            if idx >= len(self.constants):
                print "Error: Constant pool index out of bounds: " + str(idx)
                self.halted = true
                return false
            let name = self.constants[idx]
            let val = pop(self.stack)
            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                 print "Error: Definition of internal global '" + name + "' is restricted in safe mode"
            else:
                 self.scopes[len(self.scopes)-1][name] = val
        elif op == OP_SET_GLOBAL:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.safe_get_constant(idx)
            if self.halted: return false
            let val = pop(self.stack)

            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                print "Error: Assignment to internal global '" + name + "' is restricted in safe mode"
                push(self.stack, nil)
                return true

            var si = len(self.scopes) - 1
            var updated = false
            while si >= 0:
                if self.scopes[si][name] != nil:
                    self.scopes[si][name] = val
                    updated = true
                    si = -1
                elif dict_has(self.scopes[si], name):
                    self.scopes[si][name] = val
                    updated = true
                    si = -1
                else:
                    si = si - 1
            if not updated:
                self.globals[name] = val
            push(self.stack, val)
        elif op == OP_ADD:
            var b = pop(self.stack)
            var a = pop(self.stack)
            let type_a = type(a)
            let type_b = type(b)
            if type_a == "number" and type_b == "number":
                push(self.stack, a + b)
            elif type_a == "string" or type_b == "string":
                if a == nil: a = ""
                if b == nil: b = ""
                push(self.stack, str(a) + str(b))
            elif type_a == "array" and type_b == "array":
                let res = []
                var ai = 0
                while ai < len(a):
                    push(res, a[ai])
                    ai = ai + 1
                ai = 0
                while ai < len(b):
                    push(res, b[ai])
                    ai = ai + 1
                push(self.stack, res)
            else:
                if a == nil: a = 0
                if b == nil: b = 0
                if type(a) != "number" or type(b) != "number":
                    push(self.stack, 0)
                else:
                    push(self.stack, a + b)
        elif op == OP_SUB:
            let b = pop(self.stack)
            let a = pop(self.stack)
            push(self.stack, a - b)
        elif op == OP_MUL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            let type_a = type(a)
            let type_b = type(b)
            if type_a == "number" and type_b == "number":
                push(self.stack, a * b)
            elif type_a == "string" and type_b == "number":
                push(self.stack, str_repeat(a, int(b)))
            elif type_a == "number" and type_b == "string":
                push(self.stack, str_repeat(b, int(a)))
            else:
                push(self.stack, 0)
        elif op == OP_DIV:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if b == 0:
                push(self.stack, nil)
            else:
                push(self.stack, a / b)
        elif op == OP_MOD:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if b == 0:
                push(self.stack, nil)
            else:
                push(self.stack, a % b)
        elif op == OP_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            push(self.stack, self.equal_val(a, b))
        elif op == OP_NOT_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            push(self.stack, not self.equal_val(a, b))
        elif op == OP_GREATER:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a > b)
            else: push(self.stack, false)
        elif op == OP_GREATER_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a >= b)
            else: push(self.stack, false)
        elif op == OP_LESS:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a < b)
            else: push(self.stack, false)
        elif op == OP_LESS_EQUAL:
            let b = pop(self.stack)
            let a = pop(self.stack)
            if type(a) == "number" and type(b) == "number": push(self.stack, a <= b)
            else: push(self.stack, false)
        elif op == OP_BIT_AND:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a & b)
        elif op == OP_BIT_OR:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a | b)
        elif op == OP_BIT_XOR:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a ^ b)
        elif op == OP_BIT_NOT:
            push(self.stack, ~pop(self.stack))
        elif op == OP_SHIFT_LEFT:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a << b)
        elif op == OP_SHIFT_RIGHT:
            var b = pop(self.stack)
            var a = pop(self.stack)
            if a == nil: a = 0
            if b == nil: b = 0
            push(self.stack, a >> b)
        elif op == OP_TRUTHY:
            push(self.stack, is_truthy(pop(self.stack)))
        elif op == OP_JUMP:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            self.ip = ut.read_be16(self.code, self.ip)
        elif op == OP_JUMP_IF_FALSE:
            let target = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let st = self.stack
            let st_len = len(st)
            let idx = st_len - 1
            let cond = st[idx]
            if not is_truthy(cond): self.ip = target
        elif op == OP_LOOP_BACK:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            self.ip = self.ip - ut.read_be16(self.code, self.ip)
        elif op == OP_PRINT:
            print pop(self.stack)
        elif op == OP_MATH_PRINTM:
            let matrix = pop(self.stack)
            self.call_builtin("__builtin_math_printm", [matrix])
            push(self.stack, nil)
        elif op == OP_ARRAY:
            let count = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let arr = []
            var j = 0
            while j < count:
                push(arr, nil)
                j = j + 1
            j = 0
            while j < count:
                arr[count - 1 - j] = pop(self.stack)
                j = j + 1
            push(self.stack, arr)
        elif op == OP_TUPLE:
            let count = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let t = []
            var j = 0
            while j < count:
                push(t, nil)
                j = j + 1
            j = 0
            while j < count:
                t[count - 1 - j] = pop(self.stack)
                j = j + 1
            push(self.stack, t)
        elif op == OP_DICT:
            let count = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let d = {}
            var j = 0
            while j < count:
                let val = pop(self.stack)
                let key = pop(self.stack)
                d[key] = val
                j = j + 1
            push(self.stack, d)
        elif op == OP_SLICE:
            let end_idx = pop(self.stack)
            let start_idx = pop(self.stack)
            let obj = pop(self.stack)
            push(self.stack, slice(obj, start_idx, end_idx))
        elif op == OP_DEFINE_FUNCTION:
            let name_idx = ut.read_be16(self.code, self.ip)
            let chunk_idx = ut.read_be16(self.code, self.ip + 2)
            self.ip = self.ip + 4
            let name = self.constants[name_idx]
            let func_obj = {"__type__": "function", "__chunk__": chunk_idx, "__name__": name}
            self.scopes[len(self.scopes)-1][name] = func_obj
        elif op == OP_LOAD_FUNCTION:
            let chunk_idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            if chunk_idx < 0 or chunk_idx >= len(self.chunks):
                print "Error: Chunk index out of bounds: " + str(chunk_idx)
                self.halted = true
                return false
            push(self.stack, {"__type__": "function", "__chunk__": chunk_idx})
        elif op == OP_CALL:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            let argc = int(self.code[self.ip])
            self.ip = self.ip + 1
            let args = []
            var j = 0
            while j < argc:
                push(args, nil)
                j = j + 1
            j = 0
            while j < argc:
                args[argc - 1 - j] = pop(self.stack)
                j = j + 1
            let callee = pop(self.stack)
            if type(callee) == "dict":
                if dict_has(callee, "__type__"):
                    let ctype = callee["__type__"]
                    if ctype == "function":
                        # Security: Prevent infinite recursion from exhausting host resources (DoS)
                        if len(self.call_stack) >= self.max_call_depth:
                            print "Error: Call depth limit exceeded"
                            self.halted = true
                            return false
                        let local_base = len(self.stack)
                        push(self.call_stack, {"ip": self.ip, "code": self.code, "local_base": local_base})
                        let c_idx = callee["__chunk__"]
                        if c_idx < 0 or c_idx >= len(self.chunks):
                            print "Error: Chunk index out of bounds: " + str(c_idx)
                            self.halted = true
                            return false
                        self.code = self.chunks[c_idx]
                        self.ip = 0
                        # Performance: Update cached local_base for the new frame
                        self.current_local_base = local_base
                        push(self.scopes, {})
                        j = 0
                        while j < argc:
                            push(self.stack, args[j])
                            let arg_name = "__arg" + str(j)
                            self.scopes[len(self.scopes)-1][arg_name] = args[j]
                            j = j + 1
                    elif ctype == "generator_fn":
                        let gen_obj = {
                            "__type__": "generator",
                            "__chunk__": callee["__chunk__"],
                            "__ip__": 0,
                            "__stack__": [],
                            "__scopes__": [{}],
                            "__call_stack__": [],
                            "completed": false
                        }
                        j = 0
                        while j < argc:
                            push(gen_obj["__stack__"], args[j])
                            let arg_name = "__arg" + str(j)
                            gen_obj["__scopes__"][0][arg_name] = args[j]
                            j = j + 1
                        push(self.stack, gen_obj)
                    elif ctype == "class":
                        let instance = {"__type__": "instance", "__class__": callee}
                        if dict_has(callee["__methods__"], "init"):
                            let init_func = callee["__methods__"]["init"]
                            # Security: Prevent infinite recursion from exhausting host resources (DoS)
                            if len(self.call_stack) >= self.max_call_depth:
                                print "Error: Call depth limit exceeded"
                                self.halted = true
                                return false
                            let local_base = len(self.stack)
                            push(self.call_stack, {"ip": self.ip, "code": self.code, "local_base": local_base, "__is_constructor__": true, "__instance__": instance})
                            self.code = self.chunks[init_func["__chunk__"]]
                            self.ip = 0
                            # Performance: Update cached local_base for the new frame
                            self.current_local_base = local_base
                            push(self.scopes, {})
                            # Pass self as __arg0
                            push(self.stack, instance)
                            self.scopes[len(self.scopes)-1]["__arg0"] = instance
                            j = 0
                            while j < argc:
                                push(self.stack, args[j])
                                let arg_name = "__arg" + str(j + 1)
                                self.scopes[len(self.scopes)-1][arg_name] = args[j]
                                j = j + 1
                        else:
                            push(self.stack, instance)
                    else:
                        print "Error: Callee dict is not a function or class. callee=" + str(callee) + " type=" + str(ctype)
                else:
                    print "Error: Callee dict has no __type__"
            elif type(callee) == "string":
                push(self.stack, self.call_builtin(callee, args))
                if self.halted: return false
            elif type(callee) == "function" or type(callee) == "native fn":
                if self.safe_mode:
                    print "Error: Direct host function call is restricted in safe mode"
                    push(self.stack, nil)
                else:
                    # Delegation Bridge: using sys.call to avoid AOT tracing issues
                    if argc == 0: push(self.stack, sys.call(callee))
                    elif argc == 1: push(self.stack, sys.call(callee, args[0]))
                    elif argc == 2: push(self.stack, sys.call(callee, args[0], args[1]))
                    elif argc == 3: push(self.stack, sys.call(callee, args[0], args[1], args[2]))
                    elif argc == 4: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3]))
                    elif argc == 5: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4]))
                    elif argc == 6: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4], args[5]))
                    elif argc == 7: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4], args[5], args[6]))
                    elif argc == 8: push(self.stack, sys.call(callee, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
                    else:
                        print "Error: Host call with >8 args not implemented"
                        push(self.stack, nil)
            else:
                print "Error: Callee not a function or builtin name"
        elif op == OP_CALL_METHOD:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            let name_idx = ut.read_be16(self.code, self.ip)
            let argc = int(self.code[self.ip + 2])
            self.ip = self.ip + 3
            let name = self.constants[name_idx]
            let args = []
            var j = 0
            while j < argc:
                push(args, nil)
                j = j + 1
            j = 0
            while j < argc:
                args[argc - 1 - j] = pop(self.stack)
                j = j + 1
            let obj = pop(self.stack)

            if self.safe_mode and type(name) == "string" and startswith(name, "__") and not startswith(name, "__arg"):
                push(self.stack, nil)
                return true

            var is_class_call = false
            var method = nil
            if dict_has(obj, "__methods__") and dict_has(obj["__methods__"], name):
                method = obj["__methods__"][name]
                is_class_call = true
            elif dict_has(obj, "__class__") and dict_has(obj["__class__"]["__methods__"], name):
                method = obj["__class__"]["__methods__"][name]
            
            if method != nil:
                # Security: Prevent infinite recursion from exhausting host resources (DoS)
                if len(self.call_stack) >= self.max_call_depth:
                    print "Error: Call depth limit exceeded"
                    self.halted = true
                    return false
                let local_base = len(self.stack)
                push(self.call_stack, {"ip": self.ip, "code": self.code, "local_base": local_base})
                self.code = self.chunks[method["__chunk__"]]
                self.ip = 0
                # Performance: Update cached local_base for the new frame
                self.current_local_base = local_base
                push(self.scopes, {})
                
                if is_class_call:
                    # Direct class method call (e.g. Base.init(self, name))
                    j = 0
                    while j < argc:
                        push(self.stack, args[j])
                        let arg_name = "__arg" + str(j)
                        self.scopes[len(self.scopes)-1][arg_name] = args[j]
                        j = j + 1
                else:
                    # Instance method call (e.g. obj.greet())
                    # Pass self as __arg0
                    push(self.stack, obj)
                    self.scopes[len(self.scopes)-1]["__arg0"] = obj
                    j = 0
                    while j < argc:
                        push(self.stack, args[j])
                        let arg_name = "__arg" + str(j + 1)
                        self.scopes[len(self.scopes)-1][arg_name] = args[j]
                        j = j + 1
            elif type(obj) == "module" or (type(obj) == "dict" and dict_has(obj, "__type__") and obj["__type__"] == "module"):
                # Host module method/attribute access
                if dict_has(obj, name):
                    let val = obj[name]
                    if type(val) == "function" or type(val) == "native fn":
                        if argc == 0: push(self.stack, sys.call(val))
                        elif argc == 1: push(self.stack, sys.call(val, args[0]))
                        elif argc == 2: push(self.stack, sys.call(val, args[0], args[1]))
                        elif argc == 3: push(self.stack, sys.call(val, args[0], args[1], args[2]))
                        elif argc == 4: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3]))
                        elif argc == 5: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4]))
                        elif argc == 6: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5]))
                        elif argc == 7: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6]))
                        elif argc == 8: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
                        else:
                            print "Error: Host module call with >8 args not implemented"
                            push(self.stack, nil)
                    elif type(val) == "string" and startswith(val, "__builtin_"):
                        push(self.stack, self.call_builtin(val, args))
                    else:
                        push(self.stack, val)
                else:
                    print "Error: Module attribute " + name + " not found"
            else:
                # Host primitive or object method call bridge
                if dict_has(obj, name):
                    let val = obj[name]
                    if type(val) == "function" or type(val) == "native fn":
                        if argc == 0: push(self.stack, sys.call(val))
                        elif argc == 1: push(self.stack, sys.call(val, args[0]))
                        elif argc == 2: push(self.stack, sys.call(val, args[0], args[1]))
                        elif argc == 3: push(self.stack, sys.call(val, args[0], args[1], args[2]))
                        elif argc == 4: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3]))
                        elif argc == 5: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4]))
                        elif argc == 6: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5]))
                        elif argc == 7: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6]))
                        elif argc == 8: push(self.stack, sys.call(val, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]))
                        else:
                            print "Error: Host method call with >8 args not implemented"
                            push(self.stack, nil)
                    elif type(val) == "string" and startswith(val, "__builtin_"):
                        push(self.stack, self.call_builtin(val, args))
                    else:
                        push(self.stack, val)
                else:
                    print "Error: Method " + name + " not found"
        elif op == OP_RETURN:
            let val = pop(self.stack)
            # Security: Pop exception handlers belonging to the current frame to prevent leaks
            while len(self.handlers) > 0:
                let h = self.handlers[len(self.handlers)-1]
                if h["call_depth"] >= len(self.call_stack):
                    pop(self.handlers)
                else:
                    break
            
            if len(self.call_stack) > 0:
                if len(self.scopes) > 1:
                    pop(self.scopes)
                let frame = pop(self.call_stack)
                self.ip = frame["ip"]
                self.code = frame["code"]
                if dict_has(frame, "local_base"):
                    while len(self.stack) > frame["local_base"]:
                        pop(self.stack)

                # Performance: Restore local_base from the parent frame
                if len(self.call_stack) > 0:
                    let top = self.call_stack[len(self.call_stack)-1]
                    if dict_has(top, "local_base"): self.current_local_base = top["local_base"]
                    else: self.current_local_base = 0
                else: self.current_local_base = 0
                if dict_has(frame, "__is_constructor__"):
                    push(self.stack, frame["__instance__"])
                else:
                    push(self.stack, val)
            elif self.active_generator != nil:
                let gen = self.active_generator
                gen["completed"] = true
                let caller = pop(self.gen_caller_stack)
                self.ip = caller["ip"]
                self.code = caller["code"]
                self.stack = caller["stack"]
                self.scopes = caller["scopes"]
                self.call_stack = caller["call_stack"]
                self.current_local_base = caller["local_base"]
                self.active_generator = caller["active_generator"]
                push(self.stack, val)
            else:
                self.halted = true
                self.return_value = val
        elif op == OP_HALT:
            self.halted = true
            return false
        elif op == OP_CLASS:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.constants[idx]
            let cls = {"__type__": "class", "__name__": name, "__methods__": {}}
            self.scopes[len(self.scopes)-1][name] = cls
            push(self.stack, cls)
        elif op == OP_METHOD:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.constants[idx]
            let func = pop(self.stack)
            let cls = self.stack[len(self.stack)-1]
            cls["__methods__"][name] = func
        elif op == OP_INHERIT:
            let cls = pop(self.stack)
            let parent = pop(self.stack)
            if type(parent) == "dict":
                if dict_has(parent, "__methods__"):
                    let methods = parent["__methods__"]
                    let keys = dict_keys(methods)
                    var k = 0
                    while k < len(keys):
                        let mname = keys[k]
                        if not dict_has(cls["__methods__"], mname):
                            cls["__methods__"][mname] = methods[mname]
                        k = k + 1
                else:
                    # Host class inheritance bridge (copy host attributes)
                    let keys = dict_keys(parent)
                    var k = 0
                    while k < len(keys):
                        let mname = keys[k]
                        if not dict_has(cls["__methods__"], mname):
                            cls["__methods__"][mname] = parent[mname]
                        k = k + 1
            push(self.stack, cls)
        elif op == OP_IMPORT:
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let name = self.constants[idx]
            # Delegation Bridge: check host first for native modules
            # Security: Explicitly block 'io' in safe mode blacklist
            if self.safe_mode and (name == "io" or name == "net" or name == "sys" or name == "thread" or name == "gpu" or name == "ml_native" or name == "mem" or name == "ffi" or name == "struct"):
                print "Error: Access to module '" + name + "' is restricted in safe mode"
                push(self.stack, nil)
            elif name == "ffi" and not self.ffi_enabled:
                print "Error: FFI is disabled"
                push(self.stack, nil)
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
                        push(self.stack, m)
                    elif name == "io":
                        let iom = {}
                        iom["__type__"] = "module"
                        iom["readfile"] = "__builtin_io_readfile"
                        iom["readbytes"] = "__builtin_io_readbytes"
                        iom["writebytes"] = "__builtin_io_writebytes"
                        iom["writefile"] = "__builtin_io_writefile"
                        push(self.stack, iom)
                    elif name == "sys":
                        var sys_args_list = sys.args()
                        if self.user_args != nil:
                            sys_args_list = self.user_args
                        let s = {"args": sys_args_list}
                        s["__type__"] = "module"
                        s["exec"] = "__builtin_sys_exec"
                        s["system"] = "__builtin_sys_system"
                        s["exit"] = "__builtin_sys_exit"
                        s["getenv"] = "__builtin_sys_getenv"
                        push(self.stack, s)
                    elif name == "net": push(self.stack, net)
                    elif name == "gpu":
                        let g = {}
                        g["__type__"] = "module"
                        g["poll_events"] = "__builtin_gpu_poll_events"
                        g["get_time"] = "__builtin_gpu_get_time"
                        g["mouse_pos"] = "__builtin_gpu_mouse_pos"
                        push(self.stack, g)
                    elif name == "ml_native": push(self.stack, ml_native)
                    elif name == "thread":
                        let tm = {}
                        tm["__type__"] = "module"
                        tm["mutex"] = "__builtin_thread_mutex"
                        push(self.stack, tm)
                    elif name == "mem": push(self.stack, self.globals["mem"])
                    elif name == "ffi": push(self.stack, self.globals["ffi"])
                    elif name == "struct": push(self.stack, self.globals["struct"])
                    else:
                        # Dynamic loading of user .sage modules
                        var mod_path = name + ".sage"
                        if io.readbytes(mod_path) == nil:
                            if io.readbytes("src/" + name + ".sage") != nil:
                                mod_path = "src/" + name + ".sage"
                            elif io.readbytes("src/svm/" + name + ".sage") != nil:
                                mod_path = "src/svm/" + name + ".sage"
                            elif io.readbytes("src/srvm/" + name + ".sage") != nil:
                                mod_path = "src/srvm/" + name + ".sage"
                        
                        let mod_bytes = io.readbytes(mod_path)
                        if mod_bytes != nil:
                            let mod_src = io.readfile(mod_path)
                            if mod_src != nil:
                                self.call_builtin("__builtin_sys_exec", [mod_src])
                                push(self.stack, {"__type__": "module", "__name__": name})
                            else:
                                push(self.stack, {"__type__": "module", "__name__": name})
                        else:
                            push(self.stack, {"__type__": "module", "__name__": name})
                catch e:
                    push(self.stack, {"__type__": "module", "__name__": name})
        elif op == OP_SETUP_TRY:
            if len(self.stack) > self.max_stack_depth:
                print "Error: Stack overflow"
                self.halted = true
                return false
            let handler = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            # Security: Prevent nested handlers from exhausting VM memory (DoS)
            if len(self.handlers) >= self.max_handler_depth:
                print "Error: Handler depth limit exceeded"
                self.halted = true
                return false
            # Store context for unwinding: ip, stack size, call depth, scopes depth, and current code chunk
            push(self.handlers, {
                "ip": handler, 
                "stack_size": len(self.stack),
                "call_depth": len(self.call_stack),
                "scopes_len": len(self.scopes),
                "code": self.code
            })
        elif op == OP_END_TRY:
            pop(self.handlers)
        elif op == OP_RAISE:
            let val = pop(self.stack)
            self.exception_value = val
            self.is_throwing = true
            if len(self.handlers) > 0:
                let h = pop(self.handlers)
                
                # Unwind call stack to the frame where the handler was defined
                while len(self.call_stack) > h["call_depth"]:
                    pop(self.scopes)
                    pop(self.call_stack)
                
                # Unwind local scopes within that frame
                while len(self.scopes) > h["scopes_len"]:
                    pop(self.scopes)
                
                # Restore execution state
                self.code = h["code"]
                self.ip = h["ip"]
                
                # Performance: Update local_base after unwinding
                if len(self.call_stack) > 0:
                    let top = self.call_stack[len(self.call_stack)-1]
                    if dict_has(top, "local_base"): self.current_local_base = top["local_base"]
                    else: self.current_local_base = 0
                else: self.current_local_base = 0

                # Clear operand stack to the state when the handler was established
                while len(self.stack) > h["stack_size"]:
                    pop(self.stack)
                
                # Push the exception value for the catch block
                push(self.stack, self.exception_value)
                self.is_throwing = false
            else:
                print "Unhandled exception: " + str(val)
                self.halted = true
        elif op == OP_EXEC_AST_STMT:
            if self.safe_mode or not self.exec_enabled:
                print "Error: Code execution is restricted"
                self.ip = self.ip + 2
                return true
            let idx = ut.read_be16(self.code, self.ip)
            self.ip = self.ip + 2
            let ast_code = self.constants[idx]
            if type(ast_code) == "string":
                # Fallback: Use host execution engine for non-lowered code
                sys.exec(ast_code)
            else:
                print "Error: OP_EXEC_AST_STMT requires a string constant"
        elif op == OP_GET_LOCAL:
            # Performance: Inline BE16 and use cached local_base
            let idx = (int(self.code[self.ip]) << 8) | int(self.code[self.ip+1])
            self.ip = self.ip + 2
            let base = self.current_local_base
            if base + idx < len(self.stack):
                push(self.stack, self.stack[base + idx])
            else: push(self.stack, nil)
        elif op == OP_SET_LOCAL:
            # Performance: Inline BE16 and use cached local_base
            let idx = (int(self.code[self.ip]) << 8) | int(self.code[self.ip+1])
            self.ip = self.ip + 2
            let val = pop(self.stack)
            let base = self.current_local_base
            let target_idx = base + idx
            if target_idx < len(self.stack):
                self.stack[target_idx] = val
            else:
                while target_idx >= len(self.stack):
                    if len(self.stack) >= self.max_stack_depth:
                        print "Error: Stack overflow"
                        self.halted = true
                        return false
                    push(self.stack, nil)
                self.stack[target_idx] = val
            push(self.stack, val)
        elif op == OP_BREAK:
            print "Error: Unexpected loop break opcode"
            self.halted = true
        elif op == OP_CONTINUE:
            print "Error: Unexpected loop continue opcode"
            self.halted = true
        elif op >= OP_GPU_POLL_EVENTS and op < OP_GET_LOCAL:
            if op == OP_GPU_WINDOW_SHOULD_CLOSE or op == OP_GPU_KEY_PRESSED or op == OP_GPU_KEY_DOWN:
                push(self.stack, false)
            elif op == OP_GPU_GET_TIME:
                push(self.stack, 0.0)
            elif op == OP_GPU_MOUSE_POS or op == OP_GPU_MOUSE_DELTA:
                push(self.stack, {"x": 0, "y": 0})
            return true
        elif op == OP_GPU_BEGIN_COMMANDS: push(self.stack, gpu.begin_commands(pop(self.stack)))
        elif op == OP_GPU_END_COMMANDS: push(self.stack, gpu.end_commands(pop(self.stack)))
        elif op == OP_GPU_CMD_BEGIN_RP:
             let ca = pop(self.stack)
             let h = pop(self.stack)
             let w = pop(self.stack)
             let fb = pop(self.stack)
             let rp = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_begin_render_pass(cmd, rp, fb, w, h, ca)
        elif op == OP_GPU_CMD_END_RP: gpu.cmd_end_render_pass(pop(self.stack))
        elif op == OP_GPU_CMD_DRAW:
             let fi = pop(self.stack)
             let fv = pop(self.stack)
             let inst = pop(self.stack)
             let verts = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_draw(cmd, verts, inst, fv, fi)
        elif op == OP_GPU_CMD_BIND_GP:
             let gp = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_graphics_pipeline(cmd, gp)
        elif op == OP_GPU_CMD_BIND_DS:
             let bp = pop(self.stack)
             let set = pop(self.stack)
             let lay = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_descriptor_set(cmd, lay, set, bp)
        elif op == OP_GPU_CMD_SET_VP:
             let maxd = pop(self.stack)
             let mind = pop(self.stack)
             let vh = pop(self.stack)
             let vw = pop(self.stack)
             let vy = pop(self.stack)
             let vx = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_set_viewport(cmd, vx, vy, vw, vh, mind, maxd)
        elif op == OP_GPU_CMD_SET_SC:
             let sh = pop(self.stack)
             let sw = pop(self.stack)
             let sy = pop(self.stack)
             let sx = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_set_scissor(cmd, sx, sy, sw, sh)
        elif op == OP_GPU_CMD_BIND_VB:
             let buf = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_vertex_buffer(cmd, buf)
        elif op == OP_GPU_CMD_BIND_IB:
             let buf = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_bind_index_buffer(cmd, buf)
        elif op == OP_GPU_CMD_DRAW_IDX:
             let fi = pop(self.stack)
             let vo = pop(self.stack)
             let fidx = pop(self.stack)
             let inst = pop(self.stack)
             let idxc = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_draw_indexed(cmd, idxc, inst, fidx, vo, fi)
        elif op == OP_GPU_SUBMIT_SYNC:
             let f = pop(self.stack)
             let s = pop(self.stack)
             let w = pop(self.stack)
             let cmd = pop(self.stack)
             push(self.stack, gpu.submit_with_sync(cmd, w, s, f))
        elif op == OP_GPU_ACQUIRE_IMG: push(self.stack, gpu.acquire_next_image(pop(self.stack)))
        elif op == OP_GPU_PRESENT:
             let idx = pop(self.stack)
             let s = pop(self.stack)
             gpu.present(s, idx)
        elif op == OP_GPU_WAIT_FENCE:
             let t = pop(self.stack)
             let f = pop(self.stack)
             gpu.wait_fence(f, t)
        elif op == OP_GPU_RESET_FENCE: gpu.reset_fence(pop(self.stack))
        elif op == OP_GPU_UPDATE_UNIFORM:
             let data = pop(self.stack)
             let h = pop(self.stack)
             gpu.update_uniform(h, data)
        elif op == OP_GPU_CMD_PUSH_CONST:
             let data = pop(self.stack)
             let st = pop(self.stack)
             let lay = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_push_constants(cmd, lay, st, data)
        elif op == OP_GPU_CMD_DISPATCH:
             let gz = pop(self.stack)
             let gy = pop(self.stack)
             let gx = pop(self.stack)
             let cmd = pop(self.stack)
             gpu.cmd_dispatch(cmd, gx, gy, gz)
        elif op == OP_YIELD:
            let val = pop(self.stack)
            if self.active_generator != nil:
                let gen = self.active_generator
                gen["__ip__"] = self.ip
                gen["__stack__"] = self.stack
                gen["__scopes__"] = self.scopes
                gen["__call_stack__"] = self.call_stack
                
                let caller = pop(self.gen_caller_stack)
                self.ip = caller["ip"]
                self.code = caller["code"]
                self.stack = caller["stack"]
                self.scopes = caller["scopes"]
                self.call_stack = caller["call_stack"]
                self.current_local_base = caller["local_base"]
                self.active_generator = caller["active_generator"]
                push(self.stack, val)
            else:
                push(self.stack, val)
        elif op == OP_CREATE_GENERATOR:
            let name_idx = ut.read_be16(self.code, self.ip)
            let chunk_idx = ut.read_be16(self.code, self.ip + 2)
            self.ip = self.ip + 4
            let name = self.constants[name_idx]
            let gen_fn = {"__type__": "generator_fn", "__chunk__": chunk_idx, "__name__": name}
            self.scopes[len(self.scopes)-1][name] = gen_fn
        elif op == OP_GENERATOR_NEXT:
            let gen = pop(self.stack)
            if type(gen) == "dict" and dict_has(gen, "__type__") and gen["__type__"] == "generator":
                if gen["completed"]:
                    push(self.stack, nil)
                else:
                    let caller_info = {
                        "ip": self.ip,
                        "code": self.code,
                        "stack": self.stack,
                        "scopes": self.scopes,
                        "call_stack": self.call_stack,
                        "local_base": self.current_local_base,
                        "active_generator": self.active_generator
                    }
                    push(self.gen_caller_stack, caller_info)
                    self.active_generator = gen
                    self.code = self.chunks[gen["__chunk__"]]
                    self.ip = gen["__ip__"]
                    self.stack = gen["__stack__"]
                    self.scopes = gen["__scopes__"]
                    self.call_stack = gen["__call_stack__"]
                    self.current_local_base = 0
            else:
                push(self.stack, nil)
        else:
            print "Unknown OP: " + str(op)
            self.halted = true
        
        return true
