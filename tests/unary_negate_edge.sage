# Test unary negation operator (OP_NEGATE / -x) across normal and edge types

print "--- Unary negation on positive and negative integers ---"
var a = 42
print -a
print -(-a)

print "--- Unary negation on floating point numbers ---"
var f = 3.14159
print -f
print -(-f)

print "--- Unary negation on zero ---"
var z = 0
print -z

print "--- Unary negation on arithmetic expressions ---"
print -(10 + 20)
print -(-(-5))

print "--- Unary negation on non-numeric types (SVM fallback to 0) ---"
var n = nil
print -n

var b = true
print -b

var s = "hello"
print -s

var arr = [1, 2]
print -arr
