print "--- Bitwise Chained Expressions ---"
var a = 240
var b = 15
var c = 85

var res1 = (a | b) & c
print "res1:"
print res1

var res2 = (a ^ c) << 2
print "res2:"
print res2

var res3 = (res2 >> 3) & 63
print "res3:"
print res3

print "--- Bitwise NOT & Zero Boundaries ---"
var z = 0
print "~0:"
print ~z

var n = -1
print "~(-1):"
print ~n

print "--- Bitwise Operations with Nil & Invalid Operands ---"
var nil_val = nil
print "nil & 15:"
print nil_val & 15

print "15 | nil:"
print 15 | nil_val

print "nil << 2:"
print nil_val << 2
