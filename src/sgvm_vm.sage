import io
import math
import thread as host_thread
import std.regex as re
from sgvm_core import SGVMUtils
from sgvm_core import OP_CONSTANT
from sgvm_core import OP_NIL
from sgvm_core import OP_TRUE
from sgvm_core import OP_FALSE
from sgvm_core import OP_POP
from sgvm_core import OP_GET_GLOBAL
from sgvm_core import OP_DEFINE_GLOBAL
from sgvm_core import OP_SET_GLOBAL
from sgvm_core import OP_DEFINE_FUNCTION
from sgvm_core import OP_GET_PROPERTY
from sgvm_core import OP_SET_PROPERTY
from sgvm_core import OP_GET_INDEX
from sgvm_core import OP_SET_INDEX
from sgvm_core import OP_LOAD_FUNCTION
from sgvm_core import OP_SLICE
from sgvm_core import OP_ADD
from sgvm_core import OP_SUB
from sgvm_core import OP_MUL
from sgvm_core import OP_DIV
from sgvm_core import OP_MOD
from sgvm_core import OP_NEGATE
from sgvm_core import OP_EQUAL
from sgvm_core import OP_NOT_EQUAL
from sgvm_core import OP_GREATER
from sgvm_core import OP_GREATER_EQUAL
from sgvm_core import OP_LESS
from sgvm_core import OP_LESS_EQUAL
from sgvm_core import OP_BIT_AND
from sgvm_core import OP_BIT_OR
from sgvm_core import OP_BIT_XOR
from sgvm_core import OP_BIT_NOT
from sgvm_core import OP_SHIFT_LEFT
from sgvm_core import OP_SHIFT_RIGHT
from sgvm_core import OP_NOT
from sgvm_core import OP_TRUTHY
from sgvm_core import OP_JUMP
from sgvm_core import OP_JUMP_IF_FALSE
from sgvm_core import OP_CALL
from sgvm_core import OP_CALL_METHOD
from sgvm_core import OP_ARRAY
from sgvm_core import OP_TUPLE
from sgvm_core import OP_DICT
from sgvm_core import OP_PRINT
from sgvm_core import OP_EXEC_AST_STMT
from sgvm_core import OP_RETURN
from sgvm_core import OP_PUSH_ENV
from sgvm_core import OP_POP_ENV
from sgvm_core import OP_DUP
from sgvm_core import OP_ARRAY_LEN
from sgvm_core import OP_BREAK
from sgvm_core import OP_CONTINUE
from sgvm_core import OP_LOOP_BACK
from sgvm_core import OP_IMPORT
from sgvm_core import OP_CLASS
from sgvm_core import OP_METHOD
from sgvm_core import OP_INHERIT
from sgvm_core import OP_SETUP_TRY
from sgvm_core import OP_END_TRY
from sgvm_core import OP_RAISE
from sgvm_core import OP_HALT

let g_gil = host_thread.mutex()

proc vm_thread_host_entry(td):
    let vm = td["vm"]
    return vm.vm_thread_entry(td)

class MetalVM:
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
        self.trace = false
        self.modules = {}
        self.utils = SGVMUtils()
        self.max_stack_depth = 65536
        self.call_depth = 0
        self.max_call_depth = 1024
        self.return_value = nil
        self.returning = false
        self.frame_bases = [0]
        self.arg_names = ["__arg0", "__arg1", "__arg2", "__arg3", "__arg4", "__arg5", "__arg6", "__arg7", "__arg8", "__arg9"]
        self.setup_builtins()
        
        # Isolation & Resource Limits
        self.safe_mode = false
        self.ffi_enabled = true
        self.max_memory = -1 # No limit
        self.allocated_memory = 0

    proc setup_builtins(self):
        # Math Module
        let math_mod = {"__methods__": {}}
        math_mod["__methods__"]["sqrt"] = {"__native__": true, "__name__": "math.sqrt"}
        math_mod["__methods__"]["sin"] = {"__native__": true, "__name__": "math.sin"}
        math_mod["__methods__"]["cos"] = {"__native__": true, "__name__": "math.cos"}
        math_mod["__methods__"]["tan"] = {"__native__": true, "__name__": "math.tan"}
        math_mod["__methods__"]["floor"] = {"__native__": true, "__name__": "math.floor"}
        math_mod["__methods__"]["ceil"] = {"__native__": true, "__name__": "math.ceil"}
        math_mod["__methods__"]["abs"] = {"__native__": true, "__name__": "math.abs"}
        math_mod["__methods__"]["pow"] = {"__native__": true, "__name__": "math.pow"}
        self.globals["math"] = math_mod
        
        # IO Module
        let io_mod = {"__methods__": {}}
        io_mod["__methods__"]["read"] = {"__native__": true, "__name__": "io.read"}
        io_mod["__methods__"]["write"] = {"__native__": true, "__name__": "io.write"}
        self.globals["io"] = io_mod
        
        # Sys Module
        let sys_mod = {"__methods__": {}}
        sys_mod["__methods__"]["args"] = {"__native__": true, "__name__": "sys.args"}
        sys_mod["__methods__"]["getenv"] = {"__native__": true, "__name__": "sys.getenv"}
        sys_mod["__methods__"]["clock"] = {"__native__": true, "__name__": "sys.clock"}
        sys_mod["__methods__"]["exit"] = {"__native__": true, "__name__": "sys.exit"}
        self.globals["sys"] = sys_mod
        
        # Regex Module
        let re_mod = {"__methods__": {}}
        re_mod["__methods__"]["search"] = {"__native__": true, "__name__": "re.search"}
        re_mod["__methods__"]["match"] = {"__native__": true, "__name__": "re.match"}
        re_mod["__methods__"]["test"] = {"__native__": true, "__name__": "re.test"}
        self.globals["re"] = re_mod

        # FFI Module
        let ffi_mod = {"__methods__": {}}
        ffi_mod["__methods__"]["open"] = {"__native__": true, "__name__": "ffi.open"}
        ffi_mod["__methods__"]["call"] = {"__native__": true, "__name__": "ffi.call"}
        ffi_mod["__methods__"]["close"] = {"__native__": true, "__name__": "ffi.close"}
        self.globals["ffi"] = ffi_mod

        # Memory Module
        let mem_mod = {"__methods__": {}}
        mem_mod["__methods__"]["alloc"] = {"__native__": true, "__name__": "mem.alloc"}
        mem_mod["__methods__"]["free"] = {"__native__": true, "__name__": "mem.free"}
        mem_mod["__methods__"]["read"] = {"__native__": true, "__name__": "mem.read"}
        mem_mod["__methods__"]["write"] = {"__native__": true, "__name__": "mem.write"}
        mem_mod["__methods__"]["size"] = {"__native__": true, "__name__": "mem.size"}
        mem_mod["__methods__"]["usage"] = {"__native__": true, "__name__": "mem.usage"}
        mem_mod["__methods__"]["limit"] = {"__native__": true, "__name__": "mem.limit"}
        self.globals["mem"] = mem_mod

        # Struct Module
        let struct_mod = {"__methods__": {}}
        struct_mod["__methods__"]["def"] = {"__native__": true, "__name__": "struct.def"}
        struct_mod["__methods__"]["new"] = {"__native__": true, "__name__": "struct.new"}
        struct_mod["__methods__"]["get"] = {"__native__": true, "__name__": "struct.get"}
        struct_mod["__methods__"]["set"] = {"__native__": true, "__name__": "struct.set"}
        struct_mod["__methods__"]["size"] = {"__native__": true, "__name__": "struct.size"}
        self.globals["struct"] = struct_mod

        # Thread Module
        let thread_mod = {"__methods__": {}}
        thread_mod["__methods__"]["spawn"] = {"__native__": true, "__name__": "thread.spawn"}
        thread_mod["__methods__"]["join"] = {"__native__": true, "__name__": "thread.join"}
        thread_mod["__methods__"]["mutex"] = {"__native__": true, "__name__": "thread.mutex"}
        thread_mod["__methods__"]["lock"] = {"__native__": true, "__name__": "thread.lock"}
        thread_mod["__methods__"]["unlock"] = {"__native__": true, "__name__": "thread.unlock"}
        thread_mod["__methods__"]["sleep"] = {"__native__": true, "__name__": "thread.sleep"}
        thread_mod["__methods__"]["yield"] = {"__native__": true, "__name__": "thread.yield"}
        thread_mod["__methods__"]["id"] = {"__native__": true, "__name__": "thread.id"}
        self.globals["thread"] = thread_mod

        # GC Control
        let gc_mod = {"__methods__": {}}
        gc_mod["__methods__"]["collect"] = {"__native__": true, "__name__": "gc.collect"}
        gc_mod["__methods__"]["enable"] = {"__native__": true, "__name__": "gc.enable"}
        gc_mod["__methods__"]["disable"] = {"__native__": true, "__name__": "gc.disable"}
        gc_mod["__methods__"]["stats"] = {"__native__": true, "__name__": "gc.stats"}
        self.globals["gc"] = gc_mod
        
        # Atomic Operations
        let atomic_mod = {"__methods__": {}}
        atomic_mod["__methods__"]["new"] = {"__native__": true, "__name__": "atomic.new"}
        atomic_mod["__methods__"]["load"] = {"__native__": true, "__name__": "atomic.load"}
        atomic_mod["__methods__"]["store"] = {"__native__": true, "__name__": "atomic.store"}
        atomic_mod["__methods__"]["add"] = {"__native__": true, "__name__": "atomic.add"}
        atomic_mod["__methods__"]["cas"] = {"__native__": true, "__name__": "atomic.cas"}
        atomic_mod["__methods__"]["exchange"] = {"__native__": true, "__name__": "atomic.exchange"}
        self.globals["atomic"] = atomic_mod

        # Semaphore Module
        let sem_mod = {"__methods__": {}}
        sem_mod["__methods__"]["new"] = {"__native__": true, "__name__": "sem.new"}
        sem_mod["__methods__"]["wait"] = {"__native__": true, "__name__": "sem.wait"}
        sem_mod["__methods__"]["post"] = {"__native__": true, "__name__": "sem.post"}
        sem_mod["__methods__"]["trywait"] = {"__native__": true, "__name__": "sem.trywait"}
        self.globals["sem"] = sem_mod

        # Core builtins
        self.globals["str"] = {"__native__": true, "__name__": "core.str"}
        self.globals["tonumber"] = {"__native__": true, "__name__": "core.tonumber"}
        self.globals["len"] = {"__native__": true, "__name__": "core.len"}

    proc vm_thread_entry(self, td):
        let vm = td["vm"]
        let func = td["func"]
        let args = td["args"]
        return vm.run_func(func, args)

    proc call_native(self, name, obj, args):
        # Safety Checks
        if self.safe_mode:
            if startswith(name, "ffi.") or startswith(name, "mem.") or startswith(name, "struct.") or startswith(name, "atomic.") or startswith(name, "sem."):
                print "Security Error: Native bridge call '" + name + "' denied in safe mode."
                return nil
            if name == "io.write" or name == "io.read" or name == "sys.exit":
                 print "Security Error: I/O or system access denied in safe mode."
                 return nil
        
        if not self.ffi_enabled and startswith(name, "ffi."):
            print "Security Error: FFI is disabled in this VM."
            return nil

        if name == "core.str": return str(args[0])
        elif name == "core.tonumber": return tonumber(args[0])
        elif name == "core.len": return len(args[0])
        elif name == "re.search": return re.search(args[0], args[1])
        elif name == "re.match": return re.full_match(args[0], args[1])
        elif name == "re.test": return re.test(args[0], args[1])
        elif name == "ffi.open": return ffi_open(args[0])
        elif name == "ffi.call":
            if len(args) < 4: return ffi_call(args[0], args[1], args[2])
            return ffi_call(args[0], args[1], args[2], args[3])
        elif name == "ffi.close": return ffi_close(args[0])
        elif name == "mem.alloc":
            let size = args[0]
            if self.max_memory != -1 and self.allocated_memory + size > self.max_memory:
                print "Resource Error: Memory limit exceeded (" + str(self.max_memory) + " bytes)."
                return nil
            self.allocated_memory = self.allocated_memory + size
            return mem_alloc(size)
        elif name == "mem.free": return mem_free(args[0])
        elif name == "mem.read": return mem_read(args[0], args[1], args[2])
        elif name == "mem.write": return mem_write(args[0], args[1], args[2], args[3])
        elif name == "mem.size": return mem_size(args[0])
        elif name == "mem.usage": return self.allocated_memory
        elif name == "mem.limit":
            self.max_memory = args[0]
            return nil
        elif name == "struct.def": return struct_def(args[0])
        elif name == "struct.new": return struct_new(args[0])
        elif name == "struct.get": return struct_get(args[0], args[1], args[2])
        elif name == "struct.set": return struct_set(args[0], args[1], args[2], args[3])
        elif name == "struct.size": return struct_size(args[0])
        elif name == "thread.spawn":
            let func = args[0]
            var thread_args = []
            if len(args) > 1: thread_args = args[1]
            let new_vm = MetalVM()
            new_vm.constants = self.constants
            new_vm.chunks = self.chunks
            new_vm.globals = self.globals
            new_vm.safe_mode = self.safe_mode
            new_vm.ffi_enabled = self.ffi_enabled
            return host_thread.spawn(vm_thread_host_entry, {"vm": new_vm, "func": func, "args": thread_args})
        elif name == "thread.join":
            host_thread.unlock(g_gil)
            let res = host_thread.join(args[0])
            host_thread.lock(g_gil)
            return res
        elif name == "thread.mutex": return host_thread.mutex()
        elif name == "thread.lock":
            host_thread.unlock(g_gil)
            host_thread.lock(args[0])
            host_thread.lock(g_gil)
            return nil
        elif name == "thread.unlock": return host_thread.unlock(args[0])
        elif name == "thread.sleep":
            host_thread.unlock(g_gil)
            host_thread.sleep(args[0])
            host_thread.lock(g_gil)
            return nil
        elif name == "thread.yield":
            host_thread.unlock(g_gil)
            host_thread.sleep(0.0001)
            host_thread.lock(g_gil)
            return nil
        elif name == "thread.id": return host_thread.id()
        elif name == "gc.collect": return gc_collect()
        elif name == "gc.enable": return gc_enable()
        elif name == "gc.disable": return gc_disable()
        elif name == "gc.stats": return gc_stats()
        elif name == "atomic.new": return atomic_new(args[0])
        elif name == "atomic.load": return atomic_load(args[0])
        elif name == "atomic.store": return atomic_store(args[0], args[1])
        elif name == "atomic.add": return atomic_add(args[0], args[1])
        elif name == "atomic.cas": return atomic_cas(args[0], args[1], args[2])
        elif name == "atomic.exchange": return atomic_exchange(args[0], args[1])
        elif name == "sem.new": return sem_new(args[0])
        elif name == "sem.wait":
            host_thread.unlock(g_gil)
            let res = sem_wait(args[0])
            host_thread.lock(g_gil)
            return res
        elif name == "sem.post": return sem_post(args[0])
        elif name == "sem.trywait": return sem_trywait(args[0])
        elif name == "math.sqrt": return math.sqrt(args[0])
        elif name == "math.sin": return math.sin(args[0])
        elif name == "math.cos": return math.cos(args[0])
        elif name == "math.tan": return math.tan(args[0])
        elif name == "math.floor": return math.floor(args[0])
        elif name == "math.ceil": return math.ceil(args[0])
        elif name == "math.abs": return math.abs(args[0])
        elif name == "math.pow": return math.pow(args[0], args[1])
        elif name == "io.read": return io.readfile(args[0])
        elif name == "io.write": return io.writefile(args[0], args[1])
        elif name == "sys.args": return sys.args()
        elif name == "sys.getenv": return sys.getenv(args[0])
        elif name == "sys.clock": return clock()
        elif name == "sys.exit": self.halted = true
        elif name == "string.find":
            # Simple find implementation
            let h = obj
            let n = args[0]
            if len(n) == 0: return 0
            for i in range(len(h) - len(n) + 1):
                        var is_match = true
                        for j in range(len(n)):
                            if h[i+j] != n[j]:
                                is_match = false
                                break
                        if is_match: return i
            return -1
        elif name == "string.replace":
            let s = obj
            let old = args[0]
            let new_s = args[1]
            if len(old) == 0: return s
            # Simple replace
            var res = ""
            var i = 0
            while i < len(s):
                var is_match = true
                if i + len(old) <= len(s):
                    for j in range(len(old)):
                        if s[i+j] != old[j]:
                            is_match = false
                            break
                else:
                    is_match = false
                
                if is_match:
                    res = res + new_s
                    i = i + len(old)
                else:
                    res = res + s[i]
                    i = i + 1
            return res
        return nil

    proc push(self, val):
        if len(self.stack) >= self.max_stack_depth:
            print "Error: Stack overflow (depth " + str(len(self.stack)) + ")"
            self.halted = true
            return
        push(self.stack, val)

    proc pop_stack(self):
        let base = self.frame_bases[len(self.frame_bases) - 1]
        if len(self.stack) <= base:
            return nil
        return pop(self.stack)

    proc peek(self, dist):
        let base = self.frame_bases[len(self.frame_bases) - 1]
        if len(self.stack) - 1 - dist < base:
            return nil
        return self.stack[len(self.stack) - 1 - dist]

    proc format_stack(self):
        var s = "["
        var i = 0
        while i < len(self.stack):
            if i > 0: s = s + ", "
            s = s + str(self.stack[i])
            i = i + 1
        s = s + "]"
        return s

    proc read_u8(self):
        var b = self.code[self.ip]
        self.ip = self.ip + 1
        return b

    proc read_u16(self):
        var hi = self.read_u8()
        var lo = self.read_u8()
        return hi * 256 + lo

    proc get_op_size(self, op):
        if op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_SET_GLOBAL or op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_LOAD_FUNCTION or op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_ARRAY or op == OP_TUPLE or op == OP_DICT or op == OP_EXEC_AST_STMT or op == OP_BREAK or op == OP_CONTINUE or op == OP_LOOP_BACK or op == OP_IMPORT or op == OP_METHOD or op == OP_SETUP_TRY or op == OP_CLASS:
            return 2
        if op == OP_DEFINE_FUNCTION:
            return 4
        if op == OP_CALL or op == OP_DUP:
            return 1
        if op == OP_CALL_METHOD:
            return 3
        return 0

    proc verify(self, code):
        var vip = 0
        while vip < len(code):
            var op = code[vip]
            var opsize = self.get_op_size(op)
            if vip + 1 + opsize > len(code):
                print "Error: Bytecode verification failed: OOB operand for OP " + str(op) + " at IP " + str(vip)
                return false
            
            # Specific checks
            if op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_SET_GLOBAL or op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_IMPORT or op == OP_METHOD or op == OP_CLASS:
                var idx = self.utils.my_int(code[vip+1]) * 256 + self.utils.my_int(code[vip+2])
                if idx >= len(self.constants):
                    print "Error: Bytecode verification failed: OOB constant ref " + str(idx) + " at IP " + str(vip)
                    return false
            
            if op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_BREAK or op == OP_CONTINUE or op == OP_LOOP_BACK:
                var target = self.utils.my_int(code[vip+1]) * 256 + self.utils.my_int(code[vip+2])
                if target < 0 or target >= len(code):
                    print "Error: Bytecode verification failed: OOB jump target " + str(target) + " at IP " + str(vip)
                    return false
            
            vip = vip + 1 + opsize
        return true

    proc run(self, code):
        if not self.verify(code):
            self.halted = true
            return
        
        # Local caching for performance
        let stack = self.stack
        let constants = self.constants
        let globals = self.globals
        let scopes = self.scopes
        let handlers = self.handlers
        let chunks = self.chunks
        let utils = self.utils
        
        self.code = code
        var ip = 0
        self.halted = false
        self.returning = false
        
        host_thread.lock(g_gil)
        
        while not self.halted and not self.returning and ip < len(code):
            let op = utils.my_int(code[ip])
            if self.trace:
                self.ip = ip # Sync for format_stack/print
                print "IP: " + str(ip) + " OP: " + str(op) + " Stack: " + self.format_stack()
            ip = ip + 1
            
            if op == 0: # OP_CONSTANT
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                push(stack, constants[hi * 256 + lo])
            elif op == 1: # OP_NIL
                push(stack, nil)
            elif op == 2: # OP_TRUE
                push(stack, true)
            elif op == 3: # OP_FALSE
                push(stack, false)
            elif op == 4: # OP_POP
                pop(stack)
            elif op == 5: # OP_GET_GLOBAL
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let name = constants[hi * 256 + lo]
                var found = false
                var i = 0
                while i < len(scopes):
                    let s = scopes[len(scopes) - 1 - i]
                    if dict_has(s, name):
                        push(stack, s[name])
                        found = true
                        i = len(scopes)
                    else:
                        i = i + 1
                if not found:
                    if dict_has(globals, name):
                        push(stack, globals[name])
                    else:
                        push(stack, nil)
            elif op == 6: # OP_DEFINE_GLOBAL
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let name = constants[hi * 256 + lo]
                let val = pop(stack)
                scopes[len(scopes)-1][name] = val
            elif op == 7: # OP_SET_GLOBAL
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let name = constants[hi * 256 + lo]
                let val = stack[len(stack) - 1]
                var found = false
                var i = 0
                while i < len(scopes):
                    let s = scopes[len(scopes) - 1 - i]
                    if dict_has(s, name):
                        s[name] = val
                        found = true
                        i = len(scopes)
                    else:
                        i = i + 1
                if not found:
                    globals[name] = val
            elif op == 8: # OP_DEFINE_FUNCTION
                let hi_n = code[ip]
                let lo_n = code[ip + 1]
                let hi_c = code[ip + 2]
                let lo_c = code[ip + 3]
                ip = ip + 4
                let name = constants[hi_n * 256 + lo_n]
                let chunk_idx = hi_c * 256 + lo_c
                let func = {"__name__": name, "__chunks__": []}
                if chunk_idx < len(chunks):
                    push(func["__chunks__"], chunks[chunk_idx])
                scopes[len(scopes)-1][name] = func
            elif op == 9: # OP_GET_PROPERTY
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let name = constants[hi * 256 + lo]
                let obj = pop(stack)
                if type(obj) == "dict":
                    if dict_has(obj, name):
                        push(stack, obj[name])
                    elif dict_has(obj, "__class__"):
                        var curr = obj["__class__"]
                        var method = nil
                        while type(curr) == "dict":
                            if dict_has(curr, "__methods__") and dict_has(curr["__methods__"], name):
                                method = curr["__methods__"][name]
                                break
                            if dict_has(curr, "__parent_obj__"): curr = curr["__parent_obj__"]
                            else: break
                        if method != nil: push(stack, method)
                        else: push(stack, nil)
                    elif dict_has(obj, "__methods__") and dict_has(obj["__methods__"], name):
                        push(stack, obj["__methods__"][name])
                    else: push(stack, nil)
                elif type(obj) == "string":
                    if name == "find" or name == "replace" or name == "split":
                        push(stack, {"__native__": true, "__name__": "string." + name, "__obj__": obj})
                    else: push(stack, nil)
                else: push(stack, nil)
            elif op == 10: # OP_SET_PROPERTY
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let name = constants[hi * 256 + lo]
                let val = pop(stack)
                let obj = pop(stack)
                if type(obj) == "dict": obj[name] = val
                push(stack, val)
            elif op == 11: # OP_GET_INDEX
                let idx = pop(stack)
                let obj = pop(stack)
                push(stack, obj[idx])
            elif op == 12: # OP_SET_INDEX
                let val = pop(stack)
                let idx = pop(stack)
                let obj = pop(stack)
                obj[idx] = val
                push(stack, val)
            elif op == 13: # OP_LOAD_FUNCTION
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let chunk_idx = hi * 256 + lo
                let func = {"__name__": "<anon>", "__chunks__": []}
                if chunk_idx < len(chunks): push(func["__chunks__"], chunks[chunk_idx])
                push(stack, func)
            elif op == 14: # OP_SLICE
                let end_val = pop(stack)
                let start_val = pop(stack)
                let obj = pop(stack)
                let start_i = utils.my_int(start_val)
                let end_i = utils.my_int(end_val)
                if type(obj) == "string":
                    var res = ""
                    var si = start_i
                    while si < end_i and si < len(obj):
                        res = res + obj[si]
                        si = si + 1
                    push(stack, res)
                else:
                    var res = []
                    var si = start_i
                    while si < end_i and si < len(obj):
                        push(res, obj[si])
                        si = si + 1
                    push(stack, res)
            elif op == 15: # OP_ADD
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a + b)
            elif op == 16: # OP_SUB
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a - b)
            elif op == 17: # OP_MUL
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a * b)
            elif op == 18: # OP_DIV
                let b = pop(stack)
                let a = pop(stack)
                if b != 0: push(stack, a / b)
                else: push(stack, nil)
            elif op == 19: # OP_MOD
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a % b)
            elif op == 20: # OP_NEGATE
                push(stack, -pop(stack))
            elif op == 21: # OP_EQUAL
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a == b)
            elif op == 22: # OP_NOT_EQUAL
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a != b)
            elif op == 23: # OP_GREATER
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a > b)
            elif op == 24: # OP_GREATER_EQUAL
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a >= b)
            elif op == 25: # OP_LESS
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a < b)
            elif op == 26: # OP_LESS_EQUAL
                let b = pop(stack)
                let a = pop(stack)
                push(stack, a <= b)
            elif op == 27: # OP_BIT_AND
                let b = utils.my_int(pop(stack))
                let a = utils.my_int(pop(stack))
                push(stack, a & b)
            elif op == 28: # OP_BIT_OR
                let b = utils.my_int(pop(stack))
                let a = utils.my_int(pop(stack))
                push(stack, a | b)
            elif op == 29: # OP_BIT_XOR
                let b = utils.my_int(pop(stack))
                let a = utils.my_int(pop(stack))
                push(stack, a ^ b)
            elif op == 30: # OP_BIT_NOT
                let a = utils.my_int(pop(stack))
                push(stack, ~a)
            elif op == 31: # OP_SHIFT_LEFT
                let b = utils.my_int(pop(stack))
                let a = utils.my_int(pop(stack))
                push(stack, a << b)
            elif op == 32: # OP_SHIFT_RIGHT
                let b = utils.my_int(pop(stack))
                let a = utils.my_int(pop(stack))
                push(stack, a >> b)
            elif op == 33: # OP_NOT
                push(stack, not pop(stack))
            elif op == 34: # OP_TRUTHY
                let val = pop(stack)
                if val == nil or val == false or val == 0 or val == "": push(stack, false)
                else: push(stack, true)
            elif op == 35: # OP_JUMP
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = hi * 256 + lo
            elif op == 36: # OP_JUMP_IF_FALSE
                let hi = code[ip]
                let lo = code[ip + 1]
                let target = hi * 256 + lo
                ip = ip + 2
                if not pop(stack): ip = target
            elif op == 37: # OP_CALL
                let argc = utils.my_int(code[ip])
                ip = ip + 1
                let args = []
                for j in range(argc): push(args, nil)
                for j in range(argc): args[argc - 1 - j] = pop(stack)
                
                let callee = pop(stack)
                if type(callee) == "dict":
                    if dict_has(callee, "__chunks__"):
                        host_thread.unlock(g_gil)
                        self.run_func(callee, args)
                        host_thread.lock(g_gil)
                    elif dict_has(callee, "__native__"):
                        var obj = nil
                        if dict_has(callee, "__obj__"): obj = callee["__obj__"]
                        push(stack, self.call_native(callee["__name__"], obj, args))
                    elif dict_has(callee, "__class_obj__"):
                        # Instance creation
                        let inst = {"__class__": callee}
                        if dict_has(callee["__methods__"], "init"):
                            let init_m = callee["__methods__"]["init"]
                            let constructor_args = [inst]
                            for a in args: push(constructor_args, a)
                            host_thread.unlock(g_gil)
                            self.run_func(init_m, constructor_args)
                            host_thread.lock(g_gil)
                            pop(stack)
                            push(stack, inst)

                    else:
                        print "Warning: Unsupported call target: " + str(callee)
                        push(stack, nil)
                else:
                    print "Warning: Unsupported call target: " + str(callee)
                    push(stack, nil)
            elif op == 38: # OP_CALL_METHOD
                let hi = code[ip]
                let lo = code[ip + 1]
                let argc = utils.my_int(code[ip + 2])
                ip = ip + 3
                let name = constants[hi * 256 + lo]
                let args = []
                for j in range(argc): push(args, nil)
                for j in range(argc): args[argc - 1 - j] = pop(stack)
                
                let obj = pop(stack)
                var method = nil
                if type(obj) == "dict":
                    var curr = nil
                    if dict_has(obj, "__class__"): curr = obj["__class__"]
                    elif dict_has(obj, "__methods__"): curr = obj
                    
                    while type(curr) == "dict":
                        if dict_has(curr, "__methods__") and dict_has(curr["__methods__"], name):
                            method = curr["__methods__"][name]
                            break
                        if dict_has(curr, "__parent_obj__"): curr = curr["__parent_obj__"]
                        else: break
                
                if method != nil:
                    if type(method) == "dict" and dict_has(method, "__native__"):
                        push(stack, self.call_native(method["__name__"], obj, args))
                    else:
                        let method_args = [obj]
                        for a in args: push(method_args, a)
                        host_thread.unlock(g_gil)
                        self.run_func(method, method_args)
                        host_thread.lock(g_gil)
                elif type(obj) == "string":
                    if name == "find" or name == "replace" or name == "split":
                        push(stack, self.call_native("string." + name, obj, args))
                    else:
                        print "Warning: String method '" + name + "' not found"
                        push(stack, nil)
                else:
                    print "Warning: Method '" + name + "' not found on " + str(obj)
                    push(stack, nil)
            elif op == 39: # OP_ARRAY
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let count = hi * 256 + lo
                let arr = []
                var ai = 0
                while ai < count:
                    push(arr, nil)
                    ai = ai + 1
                ai = count - 1
                while ai >= 0:
                    arr[ai] = pop(stack)
                    ai = ai - 1
                push(stack, arr)
            elif op == 40: # OP_TUPLE
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let count = hi * 256 + lo
                let tup = []
                var ti = 0
                while ti < count:
                    push(tup, nil)
                    ti = ti + 1
                ti = count - 1
                while ti >= 0:
                    tup[ti] = pop(stack)
                    ti = ti - 1
                push(stack, tup)
            elif op == 41: # OP_DICT
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let count = hi * 256 + lo
                let d = {}
                var di = 0
                while di < count:
                    let val = pop(stack)
                    let key = pop(stack)
                    d[key] = val
                    di = di + 1
                push(stack, d)
            elif op == 42: # OP_PRINT
                print pop(stack)
            elif op == 43: # OP_EXEC_AST_STMT
                ip = ip + 2
            elif op == 44: # OP_RETURN
                self.return_value = pop(stack)
                self.returning = true
            elif op == 45: # OP_PUSH_ENV
                push(scopes, {})
            elif op == 46: # OP_POP_ENV
                if len(scopes) > 1: pop(scopes)
            elif op == 47: # OP_DUP
                let dist = code[ip]
                ip = ip + 1
                push(stack, stack[len(stack) - 1 - utils.my_int(dist)])
            elif op == 48: # OP_ARRAY_LEN
                push(stack, len(pop(stack)))
            elif op == 49: # OP_BREAK
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = hi * 256 + lo
            elif op == 50: # OP_CONTINUE
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = hi * 256 + lo
            elif op == 51: # OP_LOOP_BACK
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = hi * 256 + lo
            elif op == 52: # OP_IMPORT
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                push(stack, self.load_module(constants[hi * 256 + lo]))
            elif op == 53: # OP_CLASS
                let hi_n = code[ip]
                let lo_n = code[ip + 1]
                ip = ip + 2
                let name = constants[hi_n * 256 + lo_n]
                push(stack, {"__class_obj__": true, "__name__": name, "__methods__": {}, "__parent_obj__": nil})
            elif op == 54: # OP_METHOD
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let name = constants[hi * 256 + lo]
                let func = pop(stack)
                let c = stack[len(stack)-1]
                c["__methods__"][name] = func
            elif op == 55: # OP_INHERIT
                let child = pop(stack)
                let parent = pop(stack)
                child["__parent_obj__"] = parent
                push(stack, child)
            elif op == 56: # OP_SETUP_TRY
                let hi = code[ip]
                let lo = code[ip + 1]
                ip = ip + 2
                let handler = {"handler_ip": hi * 256 + lo, "stack_depth": len(stack), "env_depth": len(scopes)}
                push(handlers, handler)
            elif op == 57: # OP_END_TRY
                if len(handlers) > 0: pop(handlers)
            elif op == 58: # OP_RAISE
                let exc = pop(stack)
                if len(handlers) > 0:
                    let h = pop(handlers)
                    while len(stack) > h["stack_depth"]: pop(stack)
                    while len(scopes) > h["env_depth"]: pop(scopes)
                    ip = utils.my_int(h["handler_ip"])
                    push(stack, exc)
                else:
                    print "Unhandled Exception: " + str(exc)
                    self.halted = true
            elif op == 255: # OP_HALT
                self.halted = true
        
        self.ip = ip # Final sync
        host_thread.unlock(g_gil)

    proc run_func(self, func, args):
        if self.call_depth >= self.max_call_depth:
            print "Error: Call stack overflow (depth " + str(self.call_depth) + ")"
            self.halted = true
            return
        self.call_depth = self.call_depth + 1
        push(self.scopes, {})
        # Bind arguments to the function scope as positional params
        var ai = 0
        while ai < len(args):
            var name = ""
            if ai < len(self.arg_names):
                name = self.arg_names[ai]
            else:
                name = "__arg" + str(ai)
            self.scopes[len(self.scopes)-1][name] = args[ai]
            ai = ai + 1
        var old_ip = self.ip
        var old_code = self.code
        var old_halted = self.halted
        var old_returning = self.returning
        var old_return_val = self.return_value
        
        self.returning = false
        self.return_value = nil
        push(self.frame_bases, len(self.stack))
        
        var chunks = func["__chunks__"]
        var i = 0
        while i < len(chunks) and not self.returning and not self.halted:
            self.halted = false
            self.run(chunks[i])
            i = i + 1
        
        pop(self.frame_bases)
        var res = self.return_value
        
        self.ip = old_ip
        self.code = old_code
        self.halted = old_halted
        self.returning = old_returning
        self.return_value = old_return_val
        
        pop(self.scopes)
        self.call_depth = self.call_depth - 1
        self.push(res)
        return res

    proc load_module(self, name):
        if dict_has(self.modules, name):
            if name == "math" or name == "io" or name == "sys" or name == "re" or name == "thread" or name == "ffi" or name == "mem" or name == "struct" or name == "gc" or name == "atomic" or name == "sem":
                return self.globals[name]
            return true # Or the module object if we tracked it
        # Check if it's a builtin module
        if name == "math" or name == "io" or name == "sys" or name == "re" or name == "thread" or name == "ffi" or name == "mem" or name == "struct" or name == "gc" or name == "atomic" or name == "sem":
            self.modules[name] = true
            return self.globals[name]
        self.modules[name] = true
        var path = name + ".sgvm"
        var data = io.readbytes(path)
        if data == nil:
            print "Error: Could not load module " + name
            return nil
        var off = 0
        if len(data) > 2 and self.utils.my_int(data[0]) == 35 and self.utils.my_int(data[1]) == 33:
            while off < len(data) and self.utils.my_int(data[off]) != 10:
                off = off + 1
            if off < len(data):
                off = off + 1
        if len(data) - off < 4 or self.utils.my_int(data[off]) != 83 or self.utils.my_int(data[off+1]) != 71 or self.utils.my_int(data[off+2]) != 86 or self.utils.my_int(data[off+3]) != 77:
            print "Error: Invalid SGVM header in module " + name
            return nil
        var old_ip = self.ip
        var old_code = self.code
        var old_constants = self.constants
        var old_chunks = self.chunks
        off = off + 6
        var function_count = self.utils.my_int(self.utils.read_be16(data, off))
        off = off + 2
        var const_count = self.utils.my_int(self.utils.read_be16(data, off))
        off = off + 2
        self.constants = []
        var j = 0
        while j < const_count:
            var t = data[off]
            off = off + 1
            if t == 1:
                push(self.constants, self.utils.unpack_double(data, off))
                off = off + 8
            elif t == 3:
                var slen = self.utils.my_int(self.utils.read_be16(data, off))
                off = off + 2
                var s = ""
                var k = 0
                while k < slen:
                    s = s + chr(self.utils.my_int(data[off + k]))
                    k = k + 1
                push(self.constants, s)
                off = off + slen
            j = j + 1
        var chunk_count = self.utils.my_int(self.utils.read_be32(data, off))
        off = off + 4
        self.chunks = []
        var c = 0
        while c < chunk_count:
            var clen = self.utils.my_int(self.utils.read_be32(data, off))
            off = off + 4
            var chunk_code = []
            var k = 0
            while k < clen:
                push(chunk_code, data[off + k])
                k = k + 1
            push(self.chunks, chunk_code)
            off = off + clen
            c = c + 1
        var idx = function_count
        while idx < len(self.chunks):
            self.run(self.chunks[idx])
            idx = idx + 1
        self.ip = old_ip
        self.code = old_code
        self.constants = old_constants
        self.chunks = old_chunks
        return true # TODO: return a proper module object
