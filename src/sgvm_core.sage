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

class SGVMUtils:
    proc my_int(x):
        if x == nil:
            return 0
        return x >> 0

    proc hex_to_byte(h):
        let chars = "0123456789abcdef"
        var v1 = 0
        var v2 = 0
        var c1 = h[0]
        var c2 = h[1]
        if ord(c1) >= 65 and ord(c1) <= 70:
            c1 = chr(ord(c1) + 32)
        if ord(c2) >= 65 and ord(c2) <= 70:
            c2 = chr(ord(c2) + 32)
        var i = 0
        while i < 16:
            if chars[i] == c1:
                v1 = i
            if chars[i] == c2:
                v2 = i
            i = i + 1
        return v1 * 16 + v2

    proc split_lines(s):
        let lines = []
        var current = ""
        let nl = chr(10)
        var i = 0
        while i < len(s):
            if s[i] == nl:
                push(lines, current)
                current = ""
            else:
                if s[i] != chr(13):
                    current = current + s[i]
            i = i + 1
        if len(current) > 0:
            push(lines, current)
        return lines

    proc my_substr(s, start, length):
        var res = ""
        var i = 0
        while i < length:
            if start + i < len(s):
                res = res + s[start + i]
            i = i + 1
        return res

    ## Parse an integer from a line at a given offset.
    ## Decomposed to avoid nested method call compiler bug in C backend.
    proc parse_int_field(self, line, offset):
        let sub = self.my_substr(line, offset, len(line))
        let trimmed = self.trim(sub)
        let numval = tonumber(trimmed)
        return self.my_int(numval)

    ## Parse a hex byte from a hex string at a given offset.
    ## Decomposed to avoid nested method call compiler bug in C backend.
    proc parse_hex_byte(self, hex, offset):
        let sub = self.my_substr(hex, offset, 2)
        let bval = self.hex_to_byte(sub)
        return self.my_int(bval)

    proc trim(s):
        var start = 0
        while start < len(s) and (ord(s[start]) <= 32):
            start = start + 1
        var eidx = len(s)
        while eidx > start and (ord(s[eidx-1]) <= 32):
            eidx = eidx - 1
        return self.my_substr(s, start, eidx - start)

    proc read_be16(bs, off):
        return bs[off] * 256 + bs[off+1]

    proc read_be32(bs, off):
        if type(bs[off]) != "number" or type(bs[off+1]) != "number" or type(bs[off+2]) != "number" or type(bs[off+3]) != "number":
            print "read_be32 error! off: " + str(off) + " types: " + str(type(bs[off])) + ", " + str(type(bs[off+1])) + ", " + str(type(bs[off+2])) + ", " + str(type(bs[off+3]))
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
        if self.my_int(b0 / 128) == 1:
            sign = -1.0
        var exp = (self.my_int(b0 % 128) * 16) + self.my_int(b1 / 16)
        var mantissa = 1.0
        if exp == 0:
            mantissa = 0.0
            exp = 1
        mantissa = mantissa + (self.my_int(b1 % 16) / 16.0)
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
