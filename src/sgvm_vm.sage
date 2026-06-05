import io
import io_ext
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

    proc push(self, val):
        if len(self.stack) >= self.max_stack_depth:
            print "Error: Stack overflow (depth " + str(len(self.stack)) + ")"
            self.halted = true
            return
        push(self.stack, val)

    proc pop(self):
        if len(self.stack) == 0:
            return nil
        return pop(self.stack)

    proc peek(self, dist):
        if len(self.stack) <= dist:
            return nil
        return self.stack[len(self.stack) - 1 - dist]

    proc read_u8(self):
        var b = self.code[self.ip]
        self.ip = self.ip + 1
        return b

    proc read_u16(self):
        var hi = self.read_u8()
        var lo = self.read_u8()
        return hi * 256 + lo

    proc get_op_size(self, op):
        if op == OP_CONSTANT or op == OP_GET_GLOBAL or op == OP_DEFINE_GLOBAL or op == OP_SET_GLOBAL or op == OP_GET_PROPERTY or op == OP_SET_PROPERTY or op == OP_LOAD_FUNCTION or op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_ARRAY or op == OP_TUPLE or op == OP_DICT or op == OP_EXEC_AST_STMT or op == OP_BREAK or op == OP_CONTINUE or op == OP_LOOP_BACK or op == OP_IMPORT or op == OP_METHOD or op == OP_SETUP_TRY:
            return 2
        if op == OP_DEFINE_FUNCTION:
            return 4
        if op == OP_CALL or op == OP_DUP:
            return 1
        if op == OP_CALL_METHOD:
            return 3
        if op == OP_CLASS:
            return 6
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
            
            if op == OP_JUMP or op == OP_JUMP_IF_FALSE or op == OP_BREAK or op == OP_CONTINUE:
                var offset = self.utils.my_int(code[vip+1]) * 256 + self.utils.my_int(code[vip+2])
                if offset > 32767: offset = offset - 65536
                var target = vip + 3 + offset
                if target < 0 or target >= len(code):
                    print "Error: Bytecode verification failed: OOB jump target " + str(target) + " at IP " + str(vip)
                    return false
            
            if op == OP_LOOP_BACK:
                var offset = self.utils.my_int(code[vip+1]) * 256 + self.utils.my_int(code[vip+2])
                var target = vip + 3 - offset
                if target < 0 or target >= len(code):
                    print "Error: Bytecode verification failed: OOB loop back target " + str(target) + " at IP " + str(vip)
                    return false
            
            vip = vip + 1 + opsize
        return true

    proc run(self, code):
        if not self.verify(code):
            self.halted = true
            return
        self.code = code
        self.ip = 0
        self.halted = false
        while not self.halted and not self.returning and self.ip < len(self.code):
            var current_ip = self.ip
            var op = self.read_u8()
            if self.trace:
                print "IP: " + str(current_ip) + " OP: " + str(op)
            
            if op == OP_CONSTANT:
                var idx = self.utils.my_int(self.read_u16())
                self.push(self.constants[idx])
            elif op == OP_NIL:
                self.push(nil)
            elif op == OP_TRUE:
                self.push(true)
            elif op == OP_FALSE:
                self.push(false)
            elif op == OP_POP:
                self.pop()
            elif op == OP_GET_GLOBAL:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var found = false
                var i = 0
                while i < len(self.scopes):
                    var s = self.scopes[len(self.scopes) - 1 - i]
                    if dict_has(s, name):
                        self.push(s[name])
                        found = true
                        i = len(self.scopes)
                    else:
                        i = i + 1
                if not found:
                    if dict_has(self.globals, name):
                        self.push(self.globals[name])
                    else:
                        self.push(nil)
            elif op == OP_DEFINE_GLOBAL:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var val = self.pop()
                self.scopes[len(self.scopes)-1][name] = val
            elif op == OP_SET_GLOBAL:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var val = self.peek(0)
                var found = false
                var i = 0
                while i < len(self.scopes):
                    var s = self.scopes[len(self.scopes) - 1 - i]
                    if dict_has(s, name):
                        s[name] = val
                        found = true
                        i = len(self.scopes)
                    else:
                        i = i + 1
                if not found:
                    self.globals[name] = val
            elif op == OP_DEFINE_FUNCTION:
                var name_idx = self.utils.my_int(self.read_u16())
                var chunk_idx = self.utils.my_int(self.read_u16())
                var name = self.constants[name_idx]
                var func = {"__name__": name, "__chunks__": []}
                if chunk_idx < len(self.chunks):
                    push(func["__chunks__"], self.chunks[chunk_idx])
                self.scopes[len(self.scopes)-1][name] = func
            elif op == OP_GET_PROPERTY:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var obj = self.pop()
                if type(obj) == "dict" and dict_has(obj, name):
                    self.push(obj[name])
                elif type(obj) == "dict" and dict_has(obj, "__methods__") and dict_has(obj["__methods__"], name):
                    self.push(obj["__methods__"][name])
                else:
                    self.push(nil)
            elif op == OP_SET_PROPERTY:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var val = self.pop()
                var obj = self.pop()
                if type(obj) == "dict":
                    obj[name] = val
                self.push(val)
            elif op == OP_LOAD_FUNCTION:
                var chunk_idx = self.utils.my_int(self.read_u16())
                var func = {"__name__": "<anon>", "__chunks__": []}
                if chunk_idx < len(self.chunks):
                    push(func["__chunks__"], self.chunks[chunk_idx])
                self.push(func)
            elif op == OP_SLICE:
                var end_val = self.pop()
                var start_val = self.pop()
                var obj = self.pop()
                var start_i = self.utils.my_int(start_val)
                var end_i = self.utils.my_int(end_val)
                if type(obj) == "string":
                    var res = ""
                    var si = start_i
                    while si < end_i and si < len(obj):
                        res = res + obj[si]
                        si = si + 1
                    self.push(res)
                else:
                    var res = []
                    var si = start_i
                    while si < end_i and si < len(obj):
                        push(res, obj[si])
                        si = si + 1
                    self.push(res)
            elif op == OP_ADD:
                var b = self.pop()
                var a = self.pop()
                self.push(a + b)
            elif op == OP_SUB:
                var b = self.pop()
                var a = self.pop()
                self.push(a - b)
            elif op == OP_MUL:
                var b = self.pop()
                var a = self.pop()
                self.push(a * b)
            elif op == OP_DIV:
                var b = self.pop()
                var a = self.pop()
                if b != 0:
                    self.push(a / b)
                else:
                    self.push(nil)
            elif op == OP_MOD:
                var b = self.pop()
                var a = self.pop()
                self.push(a % b)
            elif op == OP_NEGATE:
                self.push(-self.pop())
            elif op == OP_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a == b)
            elif op == OP_NOT_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a != b)
            elif op == OP_GREATER:
                var b = self.pop()
                var a = self.pop()
                self.push(a > b)
            elif op == OP_GREATER_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a >= b)
            elif op == OP_LESS:
                var b = self.pop()
                var a = self.pop()
                self.push(a < b)
            elif op == OP_LESS_EQUAL:
                var b = self.pop()
                var a = self.pop()
                self.push(a <= b)
            elif op == OP_BIT_AND:
                var b = self.utils.my_int(self.pop())
                var a = self.utils.my_int(self.pop())
                self.push(a & b)
            elif op == OP_BIT_OR:
                var b = self.utils.my_int(self.pop())
                var a = self.utils.my_int(self.pop())
                self.push(a | b)
            elif op == OP_BIT_XOR:
                var b = self.utils.my_int(self.pop())
                var a = self.utils.my_int(self.pop())
                self.push(a ^ b)
            elif op == OP_BIT_NOT:
                var a = self.utils.my_int(self.pop())
                self.push(~a)
            elif op == OP_SHIFT_LEFT:
                var b = self.utils.my_int(self.pop())
                var a = self.utils.my_int(self.pop())
                self.push(a << b)
            elif op == OP_SHIFT_RIGHT:
                var b = self.utils.my_int(self.pop())
                var a = self.utils.my_int(self.pop())
                self.push(a >> b)
            elif op == OP_NOT:
                self.push(not self.pop())
            elif op == OP_TRUTHY:
                var val = self.pop()
                if val == nil or val == false or val == 0 or val == "":
                    self.push(false)
                else:
                    self.push(true)
            elif op == OP_PRINT:
                print self.pop()
            elif op == OP_GET_INDEX:
                var idx = self.pop()
                var obj = self.pop()
                self.push(obj[idx])
            elif op == OP_SET_INDEX:
                var val = self.pop()
                var idx = self.pop()
                var obj = self.pop()
                obj[idx] = val
                self.push(val)
            elif op == OP_JUMP:
                var offset = self.read_u16()
                if offset > 32767:
                    offset = offset - 65536
                self.ip = self.ip + self.utils.my_int(offset)
            elif op == OP_JUMP_IF_FALSE:
                var offset = self.read_u16()
                if offset > 32767:
                    offset = offset - 65536
                if not self.pop():
                    self.ip = self.ip + self.utils.my_int(offset)
            elif op == OP_LOOP_BACK:
                self.ip = self.ip - self.utils.my_int(self.read_u16())
            elif op == OP_ARRAY:
                var count = self.utils.my_int(self.read_u16())
                var arr = []
                var ai = 0
                while ai < count:
                    push(arr, nil)
                    ai = ai + 1
                ai = count - 1
                while ai >= 0:
                    arr[ai] = self.pop()
                    ai = ai - 1
                self.push(arr)
            elif op == OP_TUPLE:
                var count = self.utils.my_int(self.read_u16())
                var tup = []
                var ti = 0
                while ti < count:
                    push(tup, nil)
                    ti = ti + 1
                ti = count - 1
                while ti >= 0:
                    tup[ti] = self.pop()
                    ti = ti - 1
                self.push(tup)
            elif op == OP_DICT:
                var count = self.utils.my_int(self.read_u16())
                var d = {}
                var di = 0
                while di < count:
                    var val = self.pop()
                    var key = self.pop()
                    d[key] = val
                    di = di + 1
                self.push(d)
            elif op == OP_EXEC_AST_STMT:
                # Fallback opcode — skip the operand
                self.read_u16()
            elif op == OP_RETURN:
                self.return_value = self.pop()
                self.returning = true
            elif op == OP_PUSH_ENV:
                push(self.scopes, {})
            elif op == OP_POP_ENV:
                if len(self.scopes) > 1:
                    pop(self.scopes)
            elif op == OP_DUP:
                var dist = self.read_u8()
                self.push(self.peek(self.utils.my_int(dist)))
            elif op == OP_ARRAY_LEN:
                self.push(len(self.pop()))
            elif op == OP_BREAK:
                # Loop break — skip to end via offset
                var offset = self.utils.my_int(self.read_u16())
                self.ip = self.ip + offset
            elif op == OP_CONTINUE:
                # Loop continue — skip to loop back via offset
                var offset = self.utils.my_int(self.read_u16())
                self.ip = self.ip + offset
            elif op == OP_SETUP_TRY:
                var handler = {}
                handler["handler_ip"] = self.read_u16()
                handler["stack_depth"] = len(self.stack)
                handler["env_depth"] = len(self.scopes)
                push(self.handlers, handler)
            elif op == OP_END_TRY:
                if len(self.handlers) > 0:
                    pop(self.handlers)
            elif op == OP_RAISE:
                var exc = self.pop()
                if len(self.handlers) > 0:
                    var h = pop(self.handlers)
                    while len(self.stack) > h["stack_depth"]:
                        pop(self.stack)
                    while len(self.scopes) > h["env_depth"]:
                        pop(self.scopes)
                    self.ip = self.utils.my_int(h["handler_ip"])
                    self.push(exc)
                else:
                    print "Unhandled Exception"
                    print exc
                    self.halted = true
            elif op == OP_IMPORT:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                self.load_module(name)
            elif op == OP_CLASS:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var mcount = self.utils.my_int(self.read_u16())
                var pname = self.constants[self.utils.my_int(self.read_u16())]
                var c = {"__name__": name, "__methods__": {}, "__parent__": pname}
                self.push(c)
            elif op == OP_METHOD:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var func = self.pop()
                var c = self.peek(0)
                c["__methods__"][name] = func
            elif op == OP_INHERIT:
                var child = self.pop()
                var parent = self.pop()
                child["__parent_obj__"] = parent
                self.push(child)
            elif op == OP_CALL:
                var argc = self.utils.my_int(self.read_u8())
                var args = []
                var j = 0
                while j < argc:
                    push(args, self.pop())
                    j = j + 1
                var callee = self.pop()
                if type(callee) == "dict" and dict_has(callee, "__chunks__"):
                    self.run_func(callee, args)
                else:
                    print "Warning: Unsupported call target: " + str(callee)
                    self.push(nil)
            elif op == OP_CALL_METHOD:
                var name = self.constants[self.utils.my_int(self.read_u16())]
                var argc = self.utils.my_int(self.read_u8())
                var args = []
                var j = 0
                while j < argc:
                    push(args, self.pop())
                    j = j + 1
                var obj = self.pop()
                var curr = obj
                var method = nil
                while type(curr) == "dict":
                    if dict_has(curr, "__methods__") and dict_has(curr["__methods__"], name):
                        method = curr["__methods__"][name]
                        break
                    if dict_has(curr, "__parent_obj__"):
                        curr = curr["__parent_obj__"]
                    else:
                        break
                if method != nil:
                    push(args, obj)
                    self.run_func(method, args)
                else:
                    print "Warning: Method '" + name + "' not found"
                    self.push(nil)
            elif op == OP_HALT:
                self.halted = true

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
            self.scopes[len(self.scopes)-1]["__arg" + str(ai)] = args[ai]
            ai = ai + 1
        var old_ip = self.ip
        var old_code = self.code
        var old_halted = self.halted
        var old_returning = self.returning
        var old_return_val = self.return_value
        
        self.returning = false
        self.return_value = nil
        
        var chunks = func["__chunks__"]
        var i = 0
        while i < len(chunks) and not self.returning and not self.halted:
            self.halted = false
            self.run(chunks[i])
            i = i + 1
        
        var res = self.return_value
        
        self.ip = old_ip
        self.code = old_code
        self.halted = old_halted
        self.returning = old_returning
        self.return_value = old_return_val
        
        pop(self.scopes)
        self.call_depth = self.call_depth - 1
        self.push(res)

    proc load_module(self, name):
        if dict_has(self.modules, name):
            return
        self.modules[name] = true
        var path = name + ".sgvm"
        var data = io.readbytes(path)
        if data == nil:
            print "Error: Could not load module " + name
            return
        var off = 0
        if len(data) > 2 and self.utils.my_int(data[0]) == 35 and self.utils.my_int(data[1]) == 33:
            while off < len(data) and self.utils.my_int(data[off]) != 10:
                off = off + 1
            if off < len(data):
                off = off + 1
        if len(data) - off < 4 or self.utils.my_int(data[off]) != 83 or self.utils.my_int(data[off+1]) != 71 or self.utils.my_int(data[off+2]) != 86 or self.utils.my_int(data[off+3]) != 77:
            print "Error: Invalid SGVM header in module " + name
            return
        var old_ip = self.ip
        var old_code = self.code
        var old_constants = self.constants
        var old_chunks = self.chunks
        off = off + 6
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
        var idx = 0
        while idx < len(self.chunks):
            self.run(self.chunks[idx])
            idx = idx + 1
        self.ip = old_ip
        self.code = old_code
        self.constants = old_constants
        self.chunks = old_chunks
