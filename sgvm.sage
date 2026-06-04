import sys
import io

# Bytecode opcodes
let OP_CONSTANT       = 0
let OP_NIL            = 1
let OP_TRUE           = 2
let OP_FALSE          = 3
let OP_POP            = 4
let OP_GET_GLOBAL     = 5
let OP_DEFINE_GLOBAL  = 6
let OP_SET_GLOBAL     = 7
let OP_DEFINE_FUNCTION = 8
let OP_GET_PROPERTY   = 9
let OP_SET_PROPERTY   = 10
let OP_GET_INDEX      = 11
let OP_SET_INDEX      = 12
let OP_LOAD_FUNCTION  = 13
let OP_SLICE          = 14
let OP_ADD            = 15
let OP_SUB            = 16
let OP_MUL            = 17
let OP_DIV            = 18
let OP_MOD            = 19
let OP_NEGATE         = 20
let OP_EQUAL          = 21
let OP_NOT_EQUAL      = 22
let OP_GREATER        = 23
let OP_GREATER_EQUAL  = 24
let OP_LESS           = 25
let OP_LESS_EQUAL     = 26
let OP_BIT_AND        = 27
let OP_BIT_OR         = 28
let OP_BIT_XOR        = 29
let OP_BIT_NOT        = 30
let OP_SHIFT_LEFT     = 31
let OP_SHIFT_RIGHT    = 32
let OP_NOT            = 33
let OP_TRUTHY         = 34
let OP_JUMP           = 35
let OP_JUMP_IF_FALSE  = 36
let OP_CALL           = 37
let OP_CALL_METHOD    = 38
let OP_ARRAY          = 39
let OP_TUPLE          = 40
let OP_DICT           = 41
let OP_PRINT          = 42
let OP_EXEC_AST_STMT  = 43
let OP_RETURN         = 44
let OP_PUSH_ENV       = 45
let OP_POP_ENV        = 46
let OP_DUP            = 47
let OP_ARRAY_LEN      = 48
let OP_BREAK          = 49
let OP_CONTINUE       = 50
let OP_LOOP_BACK      = 51
let OP_HALT           = 0xFF

class MetalVM:
    proc init(self):
        self.stack = []
        self.constants = []
        self.chunks = []
        self.globals = {}
        self.scopes = [{}]
        self.ip = 0
        self.code = []
        self.halted = false

    proc push(self, val):
        push(self.stack, val)

    proc pop(self):
        if len(self.stack) == 0: return nil
        return pop(self.stack)

    proc peek(self, dist):
        if len(self.stack) <= dist: return nil
        return self.stack[len(self.stack) - 1 - dist]

    proc read_u8(self):
        let b = self.code[self.ip]
        self.ip = self.ip + 1
        return b

    proc read_u16(self):
        let hi = self.read_u8()
        let lo = self.read_u8()
        return (hi << 8) | lo

    proc run(self, code):
        self.code = code
        self.ip = 0
        self.halted = false
        while not self.halted and self.ip < len(self.code):
            let op = self.read_u8()
            if op == OP_CONSTANT:
                let idx = self.read_u16()
                self.push(self.constants[idx])
            elif op == OP_NIL: self.push(nil)
            elif op == OP_TRUE: self.push(true)
            elif op == OP_FALSE: self.push(false)
            elif op == OP_POP: self.pop()
            elif op == OP_GET_GLOBAL:
                let name = self.constants[self.read_u16()]
                # Search scopes from top to bottom
                var found = false
                var i = 0
                while i < len(self.scopes):
                    let s = self.scopes[len(self.scopes) - 1 - i]
                    if dict_has(s, name):
                        self.push(s[name])
                        found = true
                        i = len(self.scopes) # break
                    else:
                        i = i + 1
                if not found:
                    if dict_has(self.globals, name):
                        self.push(self.globals[name])
                    else:
                        print "Runtime Error: Undefined variable"
                        print name
                        self.halted = true
            elif op == OP_DEFINE_GLOBAL:
                let name = self.constants[self.read_u16()]
                let val = self.pop()
                self.scopes[len(self.scopes)-1][name] = val
            elif op == OP_SET_GLOBAL:
                let name = self.constants[self.read_u16()]
                let val = self.peek(0)
                var found = false
                var i = 0
                while i < len(self.scopes):
                    let s = self.scopes[len(self.scopes) - 1 - i]
                    if dict_has(s, name):
                        s[name] = val
                        found = true
                        i = len(self.scopes) # break
                    else:
                        i = i + 1
                if not found:
                    self.globals[name] = val
            elif op == OP_ADD:
                let b = self.pop()
                let a = self.pop()
                self.push(a + b)
            elif op == OP_SUB:
                let b = self.pop()
                let a = self.pop()
                self.push(a - b)
            elif op == OP_MUL:
                let b = self.pop()
                let a = self.pop()
                self.push(a * b)
            elif op == OP_DIV:
                let b = self.pop()
                let a = self.pop()
                self.push(a / b)
            elif op == OP_MOD:
                let b = self.pop()
                let a = self.pop()
                self.push(a % b)
            elif op == OP_NEGATE:
                self.push(-self.pop())
            elif op == OP_EQUAL:
                let b = self.pop()
                let a = self.pop()
                self.push(a == b)
            elif op == OP_NOT_EQUAL:
                let b = self.pop()
                let a = self.pop()
                self.push(a != b)
            elif op == OP_GREATER:
                let b = self.pop()
                let a = self.pop()
                self.push(a > b)
            elif op == OP_GREATER_EQUAL:
                let b = self.pop()
                let a = self.pop()
                self.push(a >= b)
            elif op == OP_LESS:
                let b = self.pop()
                let a = self.pop()
                self.push(a < b)
            elif op == OP_LESS_EQUAL:
                let b = self.pop()
                let a = self.pop()
                self.push(a <= b)
            elif op == OP_BIT_AND:
                let b = self.pop()
                let a = self.pop()
                self.push(a & b)
            elif op == OP_BIT_OR:
                let b = self.pop()
                let a = self.pop()
                self.push(a | b)
            elif op == OP_BIT_XOR:
                let b = self.pop()
                let a = self.pop()
                self.push(a ^ b)
            elif op == OP_BIT_NOT:
                self.push(~self.pop())
            elif op == OP_NOT:
                self.push(not self.pop())
            elif op == OP_TRUTHY:
                if self.pop(): self.push(true)
                else: self.push(false)
            elif op == OP_PRINT:
                print self.pop()
            elif op == OP_GET_INDEX:
                let idx = self.pop()
                let obj = self.pop()
                self.push(obj[idx])
            elif op == OP_SET_INDEX:
                let val = self.pop()
                let idx = self.pop()
                let obj = self.pop()
                obj[idx] = val
                self.push(val)
            elif op == OP_JUMP:
                self.ip = self.read_u16()
            elif op == OP_JUMP_IF_FALSE:
                let off = self.read_u16()
                if not self.pop(): self.ip = off
            elif op == OP_LOOP_BACK:
                self.ip = self.ip - self.read_u16()
            elif op == OP_PUSH_ENV:
                push(self.scopes, {})
            elif op == OP_POP_ENV:
                pop(self.scopes)
            elif op == OP_DUP:
                let dist = self.read_u8()
                self.push(self.peek(dist))
            elif op == OP_ARRAY_LEN:
                self.push(len(self.pop()))
            elif op == OP_HALT:
                self.halted = true
            elif op == 0xFF:
                self.halted = true
            else:
                print "Unknown opcode"
                print op
                self.halted = true

proc read_be16(bs, off):
    return (bs[off] << 8) | bs[off+1]

proc read_be32(bs, off):
    return (bs[off] << 24) | (bs[off+1] << 16) | (bs[off+2] << 8) | bs[off+3]

proc my_readbytes(p):
    let s = io.readfile(p)
    if s == nil: return nil
    let res = []
    var i = 0
    while i < len(s):
        push(res, ord(s[i]))
        i = i + 1
    return res

proc main():
    let args = sys.args()
    var input_file = ""
    var i = 0
    while i < len(args):
        if endswith(args[i], ".sgvm"):
            input_file = args[i]
            i = len(args) # break
        else:
            i = i + 1
    
    if input_file == "":
        print "Usage: sgvm <file.sgvm>"
        return

    let data = my_readbytes(input_file)
    if data == nil:
        print "Error: Could not read file"
        return

    var off = 0
    # Skip shebang if present
    if len(data) > 2 and chr(data[0]) == "#" and chr(data[1]) == "!":
        while off < len(data) and chr(data[off]) != "\n":
            off = off + 1
        if off < len(data):
            off = off + 1 # Skip newline

    if len(data) - off < 4 or chr(data[off]) != "S" or chr(data[off+1]) != "G" or chr(data[off+2]) != "V" or chr(data[off+3]) != "M":
        print "Error: Invalid SGVM header"
        return

    let vm = MetalVM()
    off = off + 6 # Skip SGVM and version
    let const_count = read_be16(data, off)
    off = off + 2

    var j = 0
    while j < const_count:
        let type = data[off]
        off = off + 1
        if type == 1: # Number
            push(vm.constants, 0.0) # FIXME: read double
            off = off + 8
        elif type == 3: # String
            let slen = read_be16(data, off)
            off = off + 2
            var s = ""
            var k = 0
            while k < slen:
                s = s + chr(data[off + k])
                k = k + 1
            push(vm.constants, s)
            off = off + slen
        j = j + 1

    let chunk_count = read_be32(data, off)
    off = off + 4

    var c = 0
    while c < chunk_count:
        let clen = read_be32(data, off)
        off = off + 4
        let chunk_code = []
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
