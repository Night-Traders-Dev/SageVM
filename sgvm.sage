import sys
import io

# Bytecode opcodes (Sync with bytecode.h)
var OP_CONSTANT       = 0.0
var OP_NIL            = 1.0
var OP_TRUE           = 2.0
var OP_FALSE          = 3.0
var OP_POP            = 4.0
var OP_GET_GLOBAL     = 5.0
var OP_DEFINE_GLOBAL  = 6.0
var OP_SET_GLOBAL     = 7.0
var OP_DEFINE_FUNCTION = 8.0
var OP_GET_PROPERTY   = 9.0
var OP_SET_PROPERTY   = 10.0
var OP_GET_INDEX      = 11.0
var OP_SET_INDEX      = 12.0
var OP_LOAD_FUNCTION  = 13.0
var OP_SLICE          = 14.0
var OP_ADD            = 15.0
var OP_SUB            = 16.0
var OP_MUL            = 17.0
var OP_DIV            = 18.0
var OP_MOD            = 19.0
var OP_NEGATE         = 20.0
var OP_EQUAL          = 21.0
var OP_NOT_EQUAL      = 22.0
var OP_GREATER        = 23.0
var OP_GREATER_EQUAL  = 24.0
var OP_LESS           = 25.0
var OP_LESS_EQUAL     = 26.0
var OP_BIT_AND        = 27.0
var OP_BIT_OR         = 28.0
var OP_BIT_XOR        = 29.0
var OP_BIT_NOT        = 30.0
var OP_SHIFT_LEFT     = 31.0
var OP_SHIFT_RIGHT    = 32.0
var OP_NOT            = 33.0
var OP_TRUTHY         = 34.0
var OP_JUMP           = 35.0
var OP_JUMP_IF_FALSE  = 36.0
var OP_CALL           = 37.0
var OP_CALL_METHOD    = 38.0
var OP_ARRAY          = 39.0
var OP_TUPLE          = 40.0
var OP_DICT           = 41.0
var OP_PRINT          = 42.0
var OP_EXEC_AST_STMT  = 43.0
var OP_RETURN         = 44.0
var OP_PUSH_ENV       = 45.0
var OP_POP_ENV        = 46.0
var OP_DUP            = 47.0
var OP_ARRAY_LEN      = 48.0
var OP_BREAK          = 49.0
var OP_CONTINUE       = 50.0
var OP_LOOP_BACK      = 51.0
var OP_IMPORT         = 52.0
var OP_CLASS          = 53.0
var OP_METHOD         = 54.0
var OP_INHERIT        = 55.0
var OP_SETUP_TRY      = 56.0
var OP_END_TRY        = 57.0
var OP_RAISE          = 58.0
var OP_HALT           = 255.0

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

    proc push(self, val):
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

    proc run(self, code):
        self.code = code
        self.ip = 0
        self.halted = false
        while not self.halted and self.ip < len(self.code):
            var current_ip = self.ip
            var op = self.read_u8()
            if self.trace:
                print "IP: " + str(current_ip) + " OP: " + str(op)
            
            if op == OP_CONSTANT:
                var idx = my_int(self.read_u16())
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
                var name = self.constants[my_int(self.read_u16())]
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
                var name = self.constants[my_int(self.read_u16())]
                var val = self.pop()
                self.scopes[len(self.scopes)-1][name] = val
            elif op == OP_SET_GLOBAL:
                var name = self.constants[my_int(self.read_u16())]
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
                self.ip = self.ip + my_int(offset)
            elif op == OP_JUMP_IF_FALSE:
                var offset = self.read_u16()
                if offset > 32767:
                    offset = offset - 65536
                if not self.pop():
                    self.ip = self.ip + my_int(offset)
            elif op == OP_LOOP_BACK:
                self.ip = self.ip - my_int(self.read_u16())
            elif op == OP_PUSH_ENV:
                push(self.scopes, {})
            elif op == OP_POP_ENV:
                if len(self.scopes) > 1:
                    pop(self.scopes)
            elif op == OP_DUP:
                var dist = self.read_u8()
                self.push(self.peek(my_int(dist)))
            elif op == OP_ARRAY_LEN:
                self.push(len(self.pop()))
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
                    self.ip = my_int(h["handler_ip"])
                    self.push(exc)
                else:
                    print "Unhandled Exception"
                    print exc
                    self.halted = true
            elif op == OP_IMPORT:
                var name = self.constants[my_int(self.read_u16())]
                self.load_module(name)
            elif op == OP_CLASS:
                var name = self.constants[my_int(self.read_u16())]
                var mcount = my_int(self.read_u16())
                var pname = self.constants[my_int(self.read_u16())]
                var c = {"__name__": name, "__methods__": {}, "__parent__": pname}
                self.push(c)
            elif op == OP_METHOD:
                var name = self.constants[my_int(self.read_u16())]
                var func = self.pop()
                var c = self.peek(0)
                c["__methods__"][name] = func
            elif op == OP_INHERIT:
                var child = self.pop()
                var parent = self.pop()
                child["__parent_obj__"] = parent
                self.push(child)
            elif op == OP_CALL:
                var argc = my_int(self.read_u8())
                var args = []
                var j = 0
                while j < argc:
                    push(args, self.pop())
                    j = j + 1
                var callee = self.pop()
                # Check if it's a VM function (dict with chunks) or host proc
                if type(callee) == "dict" and dict_has(callee, "__chunks__"):
                    # Execute VM function
                    self.run_func(callee, args)
                else:
                    # Host proc or other
                    print "Warning: Unsupported call"
            elif op == OP_HALT:
                self.halted = true
            elif op == 255.0:
                self.halted = true

    proc run_func(self, func, args):
        # Fresh environment for function
        push(self.scopes, {})
        # Bind args... (compiler handles this usually via DEFINE_GLOBAL)
        # For now, just run it
        var old_ip = self.ip
        var old_code = self.code
        var chunks = func["__chunks__"]
        var i = 0
        while i < len(chunks):
            self.run(chunks[i])
            i = i + 1
        self.ip = old_ip
        self.code = old_code
        pop(self.scopes)

    proc load_module(self, name):
        if dict_has(self.modules, name):
            return
        var path = name + ".sgvm"
        var data = io.readbytes(path)
        if data == nil:
            print "Error: Could not load module " + name
            return
        var off = 0
        if len(data) > 2 and my_int(data[0]) == 35 and my_int(data[1]) == 33:
            while off < len(data) and my_int(data[off]) != 10:
                off = off + 1
            if off < len(data):
                off = off + 1
        if len(data) - off < 4 or my_int(data[off]) != 83 or my_int(data[off+1]) != 71 or my_int(data[off+2]) != 86 or my_int(data[off+3]) != 77:
            return
        var old_ip = self.ip
        var old_code = self.code
        var old_constants = self.constants
        var old_chunks = self.chunks
        off = off + 6
        var const_count = my_int(read_be16(data, off))
        off = off + 2
        self.constants = []
        var j = 0
        while j < const_count:
            var t = data[off]
            off = off + 1
            if t == 1:
                push(self.constants, unpack_double(data, off))
                off = off + 8
            elif t == 3:
                var slen = my_int(read_be16(data, off))
                off = off + 2
                var s = ""
                var k = 0
                while k < slen:
                    s = s + chr(my_int(data[off + k]))
                    k = k + 1
                push(self.constants, s)
                off = off + slen
            j = j + 1
        var chunk_count = my_int(read_be32(data, off))
        off = off + 4
        self.chunks = []
        var c = 0
        while c < chunk_count:
            var clen = my_int(read_be32(data, off))
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

proc my_int(x):
    if x == nil: return 0
    var s = str(x)
    var res = ""
    var i = 0
    while i < len(s) and s[i] != ".":
        res = res + s[i]
        i = i + 1
    if res == "": return 0
    return tonumber(res)

proc read_be16(bs, off):
    return bs[off] * 256 + bs[off+1]

proc read_be32(bs, off):
    return bs[off] * 16777216 + bs[off+1] * 65536 + bs[off+2] * 256 + bs[off+3]

proc unpack_double(bs, off):
    var b0 = bs[off]
    var b1 = bs[off+1]
    var b2 = bs[off+2]
    var b3 = bs[off+3]
    var b4 = bs[off+4]
    var b5 = bs[off+5]
    var b6 = bs[off+6]
    var b7 = bs[off+7]
    var sign = 1.0
    if my_int(b0 / 128) == 1:
        sign = -1.0
    var exp = (my_int(b0 % 128) * 16) + my_int(b1 / 16)
    var mantissa = 1.0
    if exp == 0:
        mantissa = 0.0
        exp = 1
    mantissa = mantissa + (my_int(b1 % 16) / 16.0)
    mantissa = mantissa + (b2 / 4096.0)
    mantissa = mantissa + (b3 / 1048576.0)
    mantissa = mantissa + (b4 / 268435456.0)
    mantissa = mantissa + (b5 / 68719476736.0)
    mantissa = mantissa + (b6 / 17592186044416.0)
    mantissa = mantissa + (b7 / 4503599627370496.0)
    var p2 = 1.0
    var e = exp - 1023
    if e > 0:
        var i = 0
        while i < e:
            p2 = p2 * 2.0
            i = i + 1
    elif e < 0:
        var i = 0
        while i < -e:
            p2 = p2 / 2.0
            i = i + 1
    return sign * mantissa * p2

proc main():
    var args = sys.args()
    var input_file = ""
    var trace = false
    var i = 0
    while i < len(args):
        if endswith(args[i], ".sgvm"):
            input_file = args[i]
        elif args[i] == "--trace":
            trace = true
        i = i + 1
    if input_file == "":
        return
    var data = io.readbytes(input_file)
    if data == nil:
        return
    var off = 0
    if len(data) > 2 and my_int(data[0]) == 35 and my_int(data[1]) == 33:
        while off < len(data) and my_int(data[off]) != 10:
            off = off + 1
        if off < len(data):
            off = off + 1
    if len(data) - off < 4 or my_int(data[off]) != 83 or my_int(data[off+1]) != 71 or my_int(data[off+2]) != 86 or my_int(data[off+3]) != 77:
        return
    var vm = MetalVM()
    vm.trace = trace
    off = off + 6
    var const_count = my_int(read_be16(data, off))
    off = off + 2
    var j = 0
    while j < const_count:
        var t = data[off]
        off = off + 1
        if t == 1:
            push(vm.constants, unpack_double(data, off))
            off = off + 8
        elif t == 3:
            var slen = my_int(read_be16(data, off))
            off = off + 2
            var s = ""
            var k = 0
            while k < slen:
                s = s + chr(my_int(data[off + k]))
                k = k + 1
            push(vm.constants, s)
            off = off + slen
        j = j + 1
    var chunk_count = my_int(read_be32(data, off))
    off = off + 4
    var c = 0
    while c < chunk_count:
        var clen = my_int(read_be32(data, off))
        off = off + 4
        var chunk_code = []
        var k = 0
        while k < clen:
            push(chunk_code, data[off + k])
            k = k + 1
        push(vm.chunks, chunk_code)
        off = off + clen
        c = c + 1
    var idx = 0
    while idx < len(vm.chunks):
        vm.run(vm.chunks[idx])
        idx = idx + 1

main()
